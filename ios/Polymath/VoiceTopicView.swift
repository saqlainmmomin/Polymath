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
    /// Per beat, [seconds into the beat, picture time] pairs, anchored to words when rendered. Empty: the picture plays at its own pace.
    var keys: [[[Double]]]? = nil

    /// `--voice-variant bulbul` plays `voice-<id>-bulbul.*` instead, to compare voices; falls back to the default narration if missing.
    static var variant: String? {
        let a = ProcessInfo.processInfo.arguments
        return a.firstIndex(of: "--voice-variant").flatMap { $0 + 1 < a.count ? a[$0 + 1] : nil }
    }

    /// Read once per topic: the feed asks on every frame of a drag.
    private static var cache: [String: (Narration, URL)?] = [:]
    static func load(_ id: String) -> (Narration, URL)? {
        if let hit = cache[id] { return hit }
        var found: (Narration, URL)?
        for name in [variant.map { "voice-\(id)-\($0)" }, "voice-\(id)"].compactMap({ $0 }) where found == nil {
            if let json = Bundle.main.url(forResource: name, withExtension: "json"),
               let audio = Bundle.main.url(forResource: name, withExtension: "m4a"),
               let n = try? JSONDecoder().decode(Narration.self, from: Data(contentsOf: json)) { found = (n, audio) }
        }
        cache[id] = found
        return found
    }

    /// Picture time for beat `b` at narration time `t`: straight lines between the beat's keyframes from (0, 0), holding after the last.
    func pictureClock(beat b: Int, at t: Double) -> PictureClock {
        let s = t - beats[b]
        let pts = [[0.0, 0.0]] + (keys.flatMap { b < $0.count ? $0[b] : nil } ?? [])
        guard pts.count > 1 else { return PictureClock(t: s, clock: s) }
        guard let i = pts.firstIndex(where: { $0[0] > s }) else { return PictureClock(t: pts.last![1], clock: s) }
        guard i > 0 else { return PictureClock(t: 0, clock: s) }
        let (a, z) = (pts[i - 1], pts[i])
        return PictureClock(t: a[1] + (z[1] - a[1]) * (s - a[0]) / max(z[0] - a[0], 0.001), clock: s)
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
        p.enableRate = true   // must be set before prepareToPlay for speed changes to work
        p.prepareToPlay()
    }

    /// Seconds into the narration; holds at the end once it has finished.
    var time: Double { _ = seeks; return finished ? player.duration : player.currentTime }
    var duration: Double { player.duration }

    /// Playback speed, stepped through by the speed button.
    private(set) var rate: Float = 1
    func nextRate() {
        let steps: [Float] = [1, 1.25, 1.5, 2]
        rate = steps[((steps.firstIndex(of: rate) ?? 0) + 1) % steps.count]
        player.rate = rate
    }
    var muted = false { didSet { player.volume = muted ? 0 : 1 } }

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
    let audio: URL
    @State private var player: NarrationPlayer?   // made once, on first appearance: building it in init redid it on every redraw of the feed
    @State private var beat = 0
    @State private var chrome = true   // the player bar and its buttons; tapping the picture hides and shows them, as on X
    private let lines: [Range<Int>]

    init(topic: Topic, narration: Narration, audio: URL, isCurrent: Bool) {
        self.topic = topic
        self.narration = narration
        self.isCurrent = isCurrent
        self.audio = audio
        lines = narration.lines()
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 42)   // under the feed's avatar
            Text(topic.title)
                .font(S.rounded(24, .bold)).lineSpacing(2).foregroundStyle(S.text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 21).padding(.top, 16)   // 12pt more than the cards, so the title clears the top bar
            // One clock for everything: the picture, caption and bar all read the voice's time, so pausing or seeking moves them together.
            TimelineView(.animation(paused: !(player?.playing ?? false))) { _ in
                let t = player?.time ?? 0
                VStack(spacing: 0) {
                    ZStack {
                        ForEach([beat], id: \.self) { b in
                            Pictures.view(topic: topic, index: b, active: isCurrent)
                                .environment(\.pictureClock, narration.pictureClock(beat: b, at: t))
                                .transition(.opacity)
                        }
                    }
                    .environment(\.stage, topic.look.stage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {   // tap the picture to hide or show the player, as on X; a layer on top so the picture's own replay tap can't take it
                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { chrome.toggle() } }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 8)
                    VStack(spacing: 14) {
                        caption(t)
                        controls(t)
                            .opacity(chrome ? 1 : 0).allowsHitTesting(chrome)   // hidden in place, so the picture and caption don't jump
                    }
                    .padding(.horizontal, 21).padding(.bottom, 18)
                }
                .onChange(of: narration.beat(at: t)) { _, b in withAnimation(.easeInOut(duration: 0.45)) { beat = b } }
            }
        }
        .onDisappear { player?.rewind(); beat = 0 }   // switching to the text version must stop the voice
        .task(id: isCurrent) {
            if player == nil { player = NarrationPlayer(url: audio) }
            guard let player else { return }
            if isCurrent, let s = Launch.seek {
                withAnimation(nil) { beat = narration.beat(at: s) }
                player.seek(s); chrome = false
            } else if isCurrent {
                try? await Task.sleep(for: .milliseconds(500))   // let the feed's spring finish before the voice starts
                if !Task.isCancelled { player.play() }
            } else {
                player.rewind(); beat = 0
            }
        }
    }

    private func togglePlay() {
        guard let player else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        player.playing ? player.pause() : player.play()
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

    /// Laid out like X's video player: a full-width bar with a notch at each beat (drag along it to jump), and under it
    /// play or pause with the time left, then speed and mute on the right.
    private func controls(_ t: Double) -> some View {
        let playing = player?.playing ?? false
        let total = max(narration.duration, 1)
        return VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(S.text.opacity(0.18)).frame(height: 4)
                    Capsule().fill(S.text).frame(width: w * min(1, t / total), height: 4)
                    ForEach(narration.beats.dropFirst(), id: \.self) { b in
                        Circle().fill(S.text.opacity(0.7)).frame(width: 6, height: 6).offset(x: w * b / total - 3)
                    }
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in player?.seek(Double(v.location.x / w) * total) })
            }
            .frame(height: 24)
            HStack(spacing: 18) {
                Button { togglePlay() } label: {
                    Image(systemName: playing ? "pause.fill" : (player?.finished ?? false) ? "arrow.counterclockwise" : "play.fill")
                        .font(.system(size: 20, weight: .semibold)).frame(width: 32, height: 36)
                }
                .accessibilityLabel(playing ? "Pause" : "Play")
                Text("-" + clock(max(0, total - t))).font(.system(size: 15, weight: .medium).monospacedDigit()).foregroundStyle(S.text2)
                Spacer()
                Button { player?.nextRate() } label: {
                    Text(rateLabel).font(.system(size: 17, weight: .semibold)).frame(minWidth: 36, minHeight: 36)
                }
                .accessibilityLabel("Speed \(rateLabel)")
                Button { player?.muted.toggle() } label: {
                    Image(systemName: (player?.muted ?? false) ? "speaker.slash" : "speaker.wave.2")
                        .font(.system(size: 18, weight: .medium)).frame(width: 36, height: 36)
                }
                .accessibilityLabel((player?.muted ?? false) ? "Unmute" : "Mute")
            }
            .buttonStyle(.plain).foregroundStyle(S.text)
        }
    }

    private var rateLabel: String {
        let r = player?.rate ?? 1
        return (r == r.rounded() ? String(Int(r)) : String(r)) + "x"
    }

    /// "1:05" from seconds.
    private func clock(_ s: Double) -> String { let n = Int(s.rounded(.up)); return "\(n / 60):" + String(format: "%02d", n % 60) }

}
