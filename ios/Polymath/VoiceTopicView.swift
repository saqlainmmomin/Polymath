import SwiftUI
import AVFoundation

// Voice prototype, 2026-10-30: one screen per topic, no sideways swipe. A narrated spine plays, the topic's pictures change on each beat,
// and a caption lights up each word as it is spoken. Opt-in with the `--voice` launch argument, and only for topics that ship
// `voice-<id>.json` and `voice-<id>.m4a` (rendered offline by tools/voice/render.py).

/// Word timings and beat starts for one topic's narration.
struct Narration: Decodable {
    struct Word: Decodable { let text: String; let start: Double; let end: Double }
    let duration: Double
    let beats: [Double]      // second each beat starts; beat i plays picture i
    let words: [Word]

    static var enabled: Bool { ProcessInfo.processInfo.arguments.contains("--voice") }

    /// Read once per topic: the feed asks on every frame of a drag.
    private static var cache: [String: (Narration, URL)?] = [:]
    static func load(_ id: String) -> (Narration, URL)? {
        guard enabled else { return nil }
        if let hit = cache[id] { return hit }
        var found: (Narration, URL)?
        if let json = Bundle.main.url(forResource: "voice-\(id)", withExtension: "json"),
           let audio = Bundle.main.url(forResource: "voice-\(id)", withExtension: "m4a"),
           let n = try? JSONDecoder().decode(Narration.self, from: Data(contentsOf: json)) { found = (n, audio) }
        cache[id] = found
        return found
    }

    func beat(at t: Double) -> Int { beats.lastIndex { $0 <= t + 0.05 } ?? 0 }
    /// The last word that has started by `t`.
    func word(at t: Double) -> Int { words.lastIndex { $0.start <= t } ?? 0 }

    /// Words grouped into captions: one sentence each, and a long sentence cut into even pieces of at most 12 words,
    /// each cut moved to a comma when one is within two words, so no caption is a two-word scrap.
    func lines() -> [Range<Int>] {
        var out: [Range<Int>] = [], from = 0
        for (i, w) in words.enumerated() where ".?!".contains(w.text.last ?? " ") || i == words.count - 1 {
            let n = i + 1 - from, k = Int((Double(n) / 12).rounded(.up))
            var a = from
            for p in 1..<k {
                let even = from + n * p / k
                let comma = (even - 2...even + 2).first { $0 > a && $0 <= i && words[$0 - 1].text.hasSuffix(",") }
                out.append(a..<(comma ?? even)); a = comma ?? even
            }
            out.append(a..<(i + 1)); from = i + 1
        }
        return out
    }
}

/// AVAudioPlayer with the state the screen draws from.
@Observable final class NarrationPlayer: NSObject, AVAudioPlayerDelegate {
    private let player: AVAudioPlayer
    private(set) var playing = false
    private(set) var finished = false
    private var seeks = 0     // bumped on each seek, so a paused screen still redraws where the finger put it

    init?(url: URL) {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player = p
        super.init()
        p.delegate = self
        p.prepareToPlay()
    }

    /// Seconds into the narration; holds at the end once it has finished.
    var time: Double { _ = seeks; return finished ? player.duration : player.currentTime }
    var duration: Double { player.duration }

    func play() {
        if finished { player.currentTime = 0; finished = false }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)   // plays with the ringer switch off, like other shorts apps
        try? AVAudioSession.sharedInstance().setActive(true)
        player.play(); playing = true
    }
    func pause() { player.pause(); playing = false }
    func rewind() { player.stop(); player.currentTime = 0; playing = false; finished = false }
    func seek(_ t: Double) { player.currentTime = min(max(0, t), player.duration - 0.05); finished = false; seeks += 1 }

    func audioPlayerDidFinishPlaying(_ p: AVAudioPlayer, successfully: Bool) { playing = false; finished = true }
}

struct VoiceTopicView: View {
    @Environment(Store.self) private var store
    let topic: Topic
    let narration: Narration
    let isCurrent: Bool
    @State private var player: NarrationPlayer?
    @State private var beat = 0
    private let lines: [Range<Int>]

    init(topic: Topic, narration: Narration, audio: URL, isCurrent: Bool) {
        self.topic = topic
        self.narration = narration
        self.isCurrent = isCurrent
        _player = State(initialValue: NarrationPlayer(url: audio))
        lines = narration.lines()
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 42)   // under the feed's avatar
            Text(topic.title)
                .font(S.rounded(24, .bold)).lineSpacing(2).foregroundStyle(S.text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 21).padding(.top, 4)
            ZStack {
                Pictures.view(topic: topic, index: beat, active: isCurrent)
                    .id(beat)
                    .transition(.opacity)
            }
            .environment(\.stage, S.stage(store.shade(topic)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8).padding(.vertical, 8)
            TimelineView(.animation(paused: !(player?.playing ?? false))) { _ in
                let t = player?.time ?? 0
                VStack(spacing: 14) {
                    caption(t)
                    controls(t)
                }
                .onChange(of: narration.beat(at: t)) { _, b in withAnimation(.easeInOut(duration: 0.45)) { beat = b } }
            }
            .padding(.horizontal, 21).padding(.bottom, 18)
        }
        .task(id: isCurrent) {
            guard let player else { return }
            if isCurrent {
                try? await Task.sleep(for: .milliseconds(500))   // let the feed's spring finish before the voice starts
                if !Task.isCancelled { player.play() }
            } else {
                player.rewind(); beat = 0
            }
        }
    }

    /// The line being spoken: words already said in full colour, the rest faint.
    private func caption(_ t: Double) -> some View {
        let w = narration.word(at: t)
        let line = lines.first { $0.contains(w) } ?? lines.first ?? 0..<0
        let text = line.reduce(Text("")) { acc, i in
            let said = narration.words[i].start <= t
            return acc + Text((i == line.lowerBound ? "" : " ") + narration.words[i].text).foregroundColor(said ? S.text : S.text.opacity(0.32))
        }
        return text
            .font(S.rounded(22, .semibold)).lineSpacing(4)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .center)
            .animation(nil, value: w)
    }

    /// Play or pause, and a bar with a notch at each beat; drag along it to jump.
    private func controls(_ t: Double) -> some View {
        let playing = player?.playing ?? false
        let total = max(narration.duration, 1)
        return HStack(spacing: 14) {
            Button {
                guard let player else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                playing ? player.pause() : player.play()
            } label: {
                Image(systemName: playing ? "pause.fill" : (player?.finished ?? false) ? "arrow.counterclockwise" : "play.fill")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(S.text)
                    .frame(width: 40, height: 40)
            }
            .glass()
            .accessibilityLabel(playing ? "Pause" : "Play")
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(S.text.opacity(0.18)).frame(height: 4)
                    Capsule().fill(S.text).frame(width: w * min(1, t / total), height: 4)
                    ForEach(narration.beats.dropFirst(), id: \.self) { b in
                        Circle().fill(S.text.opacity(0.7)).frame(width: 6, height: 6).offset(x: w * b / total - 3)
                    }
                }
                .frame(height: 40)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in player?.seek(Double(v.location.x / w) * total) })
            }
            .frame(height: 40)
        }
    }
}
