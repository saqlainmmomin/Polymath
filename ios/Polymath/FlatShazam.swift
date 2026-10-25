import SwiftUI
import AVFoundation

// Shazam topic: six flat Canvas scenes. First draft v2, 2026-10-25.
// One made-up "song" drives cards 3-6, so the stars, codes and lookups all come from the same picture.
// Cards 2, 3 and 5 are hands-on (note pads with real sound, a noise cutoff slider, a search-mode toggle) and play a demo when untouched.

private func cl(_ x: Double) -> Double { min(1, max(0, x)) }
private func pr(_ t: Double, _ a: Double, _ b: Double) -> Double { cl((t - a) / (b - a)) }
private func eo(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
private func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
private func pop(_ x: Double) -> Double { let c1 = 1.70158, c3 = c1 + 1; return x <= 0 ? 0 : 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }

private let deep: [UInt32] = [0x060A20, 0x0A1132, 0x0D1640]

// MARK: - The song (cards 3-6)

private enum Song {
    static let rows = 24
    static let melody = [4, 9, 6, 12, 10, 5, 14, 8]

    /// Repeatable 0...1 noise for a cell.
    static func h(_ a: Int, _ b: Int) -> Double {
        var x = UInt32(truncatingIfNeeded: a &* 374_761_393 &+ b &* 668_265_263 &+ 1_442_695_041)
        x = (x ^ (x >> 13)) &* 1_274_126_177
        x ^= x >> 16
        return Double(x & 0xFFFF) / 65535
    }

    /// Loudness of pitch row `r` (0 = lowest) at time column `c`.
    static func amp(_ c: Int, _ r: Int, chord: Bool, noise: Double) -> Double {
        let n = melody[(c / 5) % melody.count]
        let env = 1 - 0.45 * Double(c % 5) / 5
        var v = 0.0
        func band(_ row: Int, _ g: Double) { let d = Double(r - row); v = max(v, g * exp(-d * d / 0.45)) }
        band(n, env)
        band(n + 8, 0.55 * env)
        if chord { band(n + 3, 0.8 * env); band(n + 6, 0.65 * env) }
        return min(1, v + noise * h(c, r))
    }

    // A noisy bar: 30 columns, chords on every other note, lots of faint speckle.
    static let cols = 30
    static let grid: [[Double]] = (0..<cols).map { c in (0..<rows).map { r in amp(c, r, chord: (c / 5) % 2 == 1, noise: 0.42) } }
    static let pw = 5, ph = 6   // patch size in cells

    /// The brightest cell in each patch, if it is bright enough: the "stars".
    static let stars: [(c: Int, r: Int)] = {
        var out: [(c: Int, r: Int)] = []
        for pc in stride(from: 0, to: cols, by: pw) {
            for prow in stride(from: 0, to: rows, by: ph) {
                var best = (c: pc, r: prow), bv = -1.0
                for c in pc..<min(cols, pc + pw) { for r in prow..<min(rows, prow + ph) where grid[c][r] > bv { bv = grid[c][r]; best = (c, r) } }
                if bv > 0.62 { out.append(best) }
            }
        }
        return out
    }()
    static func isStar(_ c: Int, _ r: Int) -> Bool { stars.contains { $0.c == c && $0.r == r } }
    static func seconds(_ c: Int) -> String { String(format: "%.1fs", Double(c) * 0.1) }
    /// The frequency a pitch row stands for, rounded to 10 Hz (row 0 = 200 Hz, doubling every 6 rows).
    static func hz(_ r: Int) -> Int { Int((200 * pow(2, Double(r) / 6) / 10).rounded()) * 10 }
}

/// Dark plum → raspberry → orange → cream: warm, so the charts read cheerful rather than cold.
private func heat(_ a: Double) -> Color {
    let stops: [(Double, (Double, Double, Double))] = [(0, (0.14, 0.07, 0.22)), (0.35, (0.78, 0.24, 0.47)), (0.7, (1.0, 0.62, 0.30)), (1, (1.0, 0.95, 0.78))]
    let x = cl(a)
    for i in 1..<stops.count where x <= stops[i].0 {
        let (a0, c0) = stops[i - 1], (a1, c1) = stops[i]
        let k = (x - a0) / (a1 - a0)
        return Color(red: c0.0 + (c1.0 - c0.0) * k, green: c0.1 + (c1.1 - c0.1) * k, blue: c0.2 + (c1.2 - c0.2) * k)
    }
    return .white
}

private func star(_ ctx: inout GraphicsContext, _ p: CGPoint, _ r: Double, _ color: Color = Pal.signal, alpha: Double = 1) {
    guard alpha > 0.01, r > 0.1 else { return }
    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r * 3, y: p.y - r * 3, width: r * 6, height: r * 6)),
             with: .radialGradient(Gradient(colors: [color.opacity(0.45 * alpha), .clear]), center: p, startRadius: 0, endRadius: r * 3))
    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(alpha)))
    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r * 0.45, y: p.y - r * 0.45, width: r * 0.9, height: r * 0.9)), with: .color(.white.opacity(alpha)))
}

private func cellRect(_ box: CGRect, _ c: Int, _ r: Int) -> CGRect {
    let cw = box.width / Double(Song.cols), ch = box.height / Double(Song.rows)
    return CGRect(x: box.minX + Double(c) * cw, y: box.maxY - Double(r + 1) * ch, width: cw, height: ch)
}
private func cellCentre(_ box: CGRect, _ c: Int, _ r: Int) -> CGPoint { let q = cellRect(box, c, r); return CGPoint(x: q.midX, y: q.midY) }

private func caption(_ ctx: inout GraphicsContext, _ s: CGSize, _ text: String, _ a: Double, color: Color = .white, y: Double? = nil) {
    Kit.chip(&ctx, text, CGPoint(x: s.width / 2, y: y ?? (s.height - 12)), anchor: .bottom, color: color, size: 10, alpha: a)
}

/// Axis hints for the star map: PITCH up the left, TIME along the bottom.
private func axes(_ ctx: inout GraphicsContext, _ box: CGRect, alpha: Double = 0.8) {
    var p = Path()
    p.move(to: CGPoint(x: box.minX - 4, y: box.maxY + 4)); p.addLine(to: CGPoint(x: box.minX - 4, y: box.minY))
    p.move(to: CGPoint(x: box.minX - 4, y: box.maxY + 4)); p.addLine(to: CGPoint(x: box.maxX, y: box.maxY + 4))
    ctx.stroke(p, with: .color(.white.opacity(0.3 * alpha)), lineWidth: 1)
    Kit.chip(&ctx, "FREQUENCY ↑", CGPoint(x: box.minX, y: box.minY - 2), anchor: .bottomLeading, size: 7, alpha: alpha)
    Kit.chip(&ctx, "TIME →", CGPoint(x: box.maxX, y: box.maxY + 6), anchor: .topTrailing, size: 7, alpha: alpha)
}

/// The panel every hands-on card sits in: same look as FlatPicture.
private struct Panel<C: View>: View {
    @ViewBuilder var content: C
    var body: some View {
        content
            .background(LinearGradient(colors: deep.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
    }
}

/// Dark pill button used on the pictures.
private struct Pill: View {
    let label: String
    let on: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(T.mono(10)).tracking(0.8)
                .foregroundStyle(on ? Color(hex: 0x0A1132) : .white)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(on ? Pal.signal : Pal.night.opacity(0.7)))
                .overlay(Capsule().stroke(.white.opacity(on ? 0 : 0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card 1: the feat (no trick revealed)

struct ShazamHear: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 10, still: 7.5, cues: [Cue(5.4, .success)], replayOnTap: true, sky: deep, onStart: playScene,
                    label: "Music and loud chatter pour into a phone. Its screen races through millions of songs, then stops on one: song found, in seconds.") { ctx, s, t, _ in
            let fade = 1 - pr(t, 9.5, 10)
            let ph = CGRect(x: s.width * 0.5 - s.height * 0.2, y: s.height * 0.13, width: s.height * 0.4, height: s.height * 0.64)
            // music from the left (warm arcs), chatter from the right (grey squiggles)
            for i in 0..<5 {
                let k = ((t * 0.55 + Double(i) / 5).truncatingRemainder(dividingBy: 1))
                let rad = 10 + k * (ph.minX - 10)
                var arc = Path(); arc.addArc(center: CGPoint(x: 0, y: ph.midY), radius: rad, startAngle: .degrees(-38), endAngle: .degrees(38), clockwise: false)
                ctx.stroke(arc, with: .color(Pal.signal.opacity((1 - k) * 0.9 * fade)), lineWidth: 2.2)
            }
            Kit.chip(&ctx, "MUSIC", CGPoint(x: 8, y: ph.minY), anchor: .leading, color: Pal.signal, size: 7, alpha: 0.9 * fade)
            for i in 0..<7 {
                let k = ((t * 0.7 + Double(i) / 7).truncatingRemainder(dividingBy: 1))
                let x = s.width - k * (s.width - ph.maxX) - 6, y = s.height * (0.2 + 0.09 * Double(i))
                var sq = Path(); sq.move(to: CGPoint(x: x, y: y))
                for j in 1...6 { sq.addLine(to: CGPoint(x: x - Double(j) * 4, y: y + (j % 2 == 0 ? -3 : 3))) }
                ctx.stroke(sq, with: .color(Color(hex: 0x9AA3C7).opacity((1 - k) * 0.65 * fade)), lineWidth: 1.3)
            }
            Kit.chip(&ctx, "CHATTER", CGPoint(x: s.width - 8, y: ph.minY), anchor: .trailing, color: Color(hex: 0x9AA3C7), size: 7, alpha: 0.9 * fade)
            // the phone
            ctx.fill(Path(roundedRect: ph, cornerRadius: ph.width * 0.16), with: .color(Color(hex: 0x1A2148)))
            ctx.stroke(Path(roundedRect: ph, cornerRadius: ph.width * 0.16), with: .color(Color(hex: 0xC9D2F5).opacity(0.7)), lineWidth: 1.6)
            let scr = ph.insetBy(dx: ph.width * 0.1, dy: ph.height * 0.09)
            // racing list of songs, slowing to a stop on one
            let stopAt = 5.2
            let sp = t < stopAt ? t : stopAt
            let travel = 70 * sp - 6.7 * sp * sp     // decelerates to zero at stopAt
            let rowH = scr.height / 5
            ctx.drawLayer { l in
                l.clip(to: Path(roundedRect: scr, cornerRadius: 6))
                let first = Int(floor(travel))
                for k in first..<(first + 7) {
                    let y = scr.minY + (Double(k) - travel) * rowH + rowH * 2
                    let r = CGRect(x: scr.minX + 4, y: y + 3, width: scr.width - 8, height: rowH - 6)
                    let isHit = t >= stopAt && abs(r.midY - scr.midY) < rowH / 2
                    l.fill(Path(roundedRect: r, cornerRadius: 4), with: .color(isHit ? Pal.coral.opacity(0.85) : Color(hex: 0x2B3570)))
                    l.fill(Path(roundedRect: CGRect(x: r.minX + 6, y: r.midY - 6, width: 12, height: 12), cornerRadius: 2), with: .color(.white.opacity(isHit ? 0.9 : 0.3)))
                    l.fill(Path(roundedRect: CGRect(x: r.minX + 24, y: r.midY - 5, width: r.width * (0.35 + 0.3 * Song.h(k, 3)), height: 3), cornerRadius: 1.5), with: .color(.white.opacity(isHit ? 0.9 : 0.35)))
                    l.fill(Path(roundedRect: CGRect(x: r.minX + 24, y: r.midY + 2, width: r.width * (0.2 + 0.25 * Song.h(k, 9)), height: 3), cornerRadius: 1.5), with: .color(.white.opacity(isHit ? 0.7 : 0.22)))
                }
            }
            let count = Int(pow(min(t, stopAt) / stopAt, 2.2) * 48_000_000)
            if t > 0.4 && t < stopAt { Kit.chip(&ctx, "SEARCHED \(count.formatted())", CGPoint(x: ph.midX, y: ph.minY - 8), anchor: .bottom, size: 8, alpha: pr(t, 0.4, 0.8)) }
            let found = pop(pr(t, stopAt, stopAt + 0.5))
            if found > 0 { Kit.chip(&ctx, "SONG FOUND", CGPoint(x: ph.midX, y: ph.minY - 8), anchor: .bottom, color: Pal.coral, size: 10 * max(0.6, found), alpha: min(1, found) * fade) }
            if t < 2.4 { caption(&ctx, s, "A NOISY CAFÉ. A FEW SECONDS.", pr(t, 0.2, 0.6) * (1 - pr(t, 2.1, 2.4))) }
            else if t < stopAt { caption(&ctx, s, "MILLIONS OF SONGS TO CHECK", pr(t, 2.5, 2.9) * (1 - pr(t, stopAt - 0.3, stopAt))) }
            else { caption(&ctx, s, "FOUND. BUT HOW?", pr(t, stopAt + 0.2, stopAt + 0.6) * fade, color: Pal.coral) }
        }
        .onChange(of: active) { _, a in if !a { Synth.shared.stop() } }
    }
}

extension ShazamHear {
    /// About five seconds of a made-up tune in a noisy room, then a bright chime as the song is found.
    func playScene() {
        let syn = Synth.shared
        syn.stop()
        let A4 = 440.0, C5 = 523.25, D5 = 587.33, E5 = 659.25, G4 = 392.0, G5 = 783.99
        let tune = [A4, C5, E5, D5, C5, A4, G4, A4, C5, E5, G5, E5, D5, C5, D5, E5]
        let bass = [220.0, 174.61, 261.63, 196.0]
        for (i, f) in tune.enumerated() { syn.play([f], after: 0.25 + Double(i) * 0.31) }
        for (i, f) in bass.enumerated() { syn.play([f], after: 0.25 + Double(i) * 1.24) }
        syn.chatter(5.2)
        for (i, f) in [1046.5, 1318.5, 1568.0].enumerated() { syn.play([f], after: 5.25 + Double(i) * 0.09) }
    }
}

// MARK: - Card 2: play notes and chords, watch the wave and the pitches

/// Tiny sine synth for the note pads: each note is a pitch plus two quieter overtones, plucked and fading.
private final class Synth {
    static let shared = Synth()
    private let engine = AVAudioEngine()
    private var node: AVAudioSourceNode?
    private let lock = NSLock()
    private var voices: [(f: Double, start: Double)] = []
    private var noiseFrom = 0.0, noiseTo = 0.0
    private var sampleTime: Double = 0
    private var sr: Double = 44_100

    /// Pluck `freqs` together, `after` seconds from now.
    func play(_ freqs: [Double], after: Double = 0) {
        if node == nil { start() }
        lock.lock()
        let now = sampleTime / sr
        voices = voices.filter { now - $0.start < 2.5 } + freqs.map { (f: $0, start: now + after) }
        lock.unlock()
    }

    /// A muffled crowd murmur for `seconds`.
    func chatter(_ seconds: Double) {
        if node == nil { start() }
        lock.lock(); noiseFrom = sampleTime / sr; noiseTo = noiseFrom + seconds; lock.unlock()
    }

    func stop() {
        lock.lock(); voices = []; noiseTo = 0; lock.unlock()
    }

    private func start() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        sr = engine.outputNode.outputFormat(forBus: 0).sampleRate
        if sr <= 0 { sr = 44_100 }
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1) else { return }
        var seed: UInt32 = 22_695_477, lp = 0.0, lp2 = 0.0
        let n = AVAudioSourceNode { [unowned self] _, _, frameCount, abl -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            self.lock.lock()
            let vs = self.voices
            let nf = self.noiseFrom, nt = self.noiseTo
            var st = self.sampleTime
            self.lock.unlock()
            for frame in 0..<Int(frameCount) {
                let t = st / self.sr
                var v = 0.0
                for voice in vs {
                    let d = t - voice.start
                    guard d >= 0, d < 2.5 else { continue }
                    let env = min(1, d / 0.008) * exp(-d * 1.8)
                    let w = 2 * Double.pi * voice.f * d
                    v += env * (sin(w) + 0.4 * sin(2 * w) + 0.18 * sin(3 * w))
                }
                if t >= nf && t < nt {
                    seed = seed &* 1_664_525 &+ 1_013_904_223
                    let x = Double(seed >> 8) / Double(1 << 24) - 0.5
                    lp += 0.06 * (x - lp); lp2 += 0.06 * (lp - lp2)          // two low-pass passes: murmur, not hiss
                    let swell = 0.6 + 0.4 * sin(2 * Double.pi * 1.7 * t) * sin(2 * Double.pi * 0.43 * t)
                    let edge = min(1, (t - nf) / 0.4, (nt - t) / 0.4)
                    v += lp2 * 9 * swell * edge
                }
                let sample = Float(v * 0.14)
                for b in buffers { b.mData?.assumingMemoryBound(to: Float.self)[frame] = sample }
                st += 1
            }
            self.lock.lock(); self.sampleTime = st; self.lock.unlock()
            return noErr
        }
        engine.attach(n)
        engine.connect(n, to: engine.mainMixerNode, format: fmt)
        node = n
        try? engine.start()
    }
}

private struct Sound { let name: String; let detail: String; let freqs: [Double] }
private let pads: [Sound] = [
    Sound(name: "A", detail: "1 NOTE = 1 LINE", freqs: [220.0]),
    Sound(name: "C", detail: "1 NOTE = 1 LINE", freqs: [261.63]),
    Sound(name: "E", detail: "1 NOTE = 1 LINE", freqs: [329.63]),
    Sound(name: "A MINOR", detail: "3 NOTES = 3 LINES", freqs: [220.0, 261.63, 329.63]),
    Sound(name: "B MINOR", detail: "3 NOTES = 3 LINES", freqs: [246.94, 293.66, 369.99]),
    Sound(name: "C MAJOR", detail: "3 NOTES = 3 LINES", freqs: [261.63, 329.63, 392.0])
]

struct ShazamStack: View {
    let active: Bool
    @State private var ref = Date()
    @State private var played: [(t: Double, pad: Int)] = []
    @State private var touched = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    private let demoGap = 2.6
    private let demoOrder = [0, 3, 1, 5, 2, 4]

    private func events(_ now: Double) -> [(t: Double, pad: Int)] {
        if touched { return played }
        let k = Int(now / demoGap)
        return (max(0, k - 2)...k).map { (t: Double($0) * demoGap, pad: demoOrder[$0 % demoOrder.count]) }
    }

    var body: some View {
        Panel {
            VStack(spacing: 8) {
                TimelineView(.animation(paused: !active || reduce)) { tl in
                    Canvas { ctx, s in draw(&ctx, s, now: reduce ? demoGap * 3.4 : tl.date.timeIntervalSince(ref)) }
                }
                VStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { col in
                                let i = row * 3 + col
                                Pill(label: pads[i].name, on: last == i) { tap(i) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10).padding(.bottom, 10)
            }
        }
        .onChange(of: active) { _, a in if a && !touched { ref = Date() } }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Note pads. Tap a note or a chord to hear it and see its wave and its pitches. A single note draws one bright line with fainter overtones above it; a chord draws several.")
    }

    private var last: Int? { touched ? played.last?.pad : nil }

    private func tap(_ i: Int) {
        if !touched { touched = true; played = [] }
        played.append((t: Date().timeIntervalSince(ref), pad: i))
        if played.count > 12 { played.removeFirst(played.count - 12) }
        Synth.shared.play(pads[i].freqs)
        Haptic.fire(.light)
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, now: Double) {
        let evs = events(now)
        let env: (Double) -> Double = { d in d < 0 ? 0 : min(1, d / 0.03) * exp(-d * 1.1) }
        let rowsN = 30
        func row(_ f: Double) -> Double { log2(f / 150) / log2(1300.0 / 150) * Double(rowsN) }
        // wave
        let W = CGRect(x: 14, y: 22, width: s.width - 28, height: s.height * 0.26)
        let S = CGRect(x: 40, y: W.maxY + 26, width: s.width - 54, height: s.height - W.maxY - 34)
        var wave = Path()
        let live = evs.filter { env(now - $0.t) > 0.02 }
        let norm = max(1.0, Double(live.reduce(0) { $0 + pads[$1.pad].freqs.count }) * 0.9)
        for i in 0...160 {
            let x = Double(i) / 160
            let tt = x * 0.022 + now * 0.0004
            var v = 0.0
            for e in live {
                let a = env(now - e.t)
                for f in pads[e.pad].freqs { let w = 2 * Double.pi * f * tt; v += a * (sin(w) + 0.4 * sin(2 * w) + 0.18 * sin(3 * w)) / 1.58 }
            }
            let p = CGPoint(x: W.minX + x * W.width, y: W.midY - v / norm * W.height * 0.46)
            if i == 0 { wave.move(to: p) } else { wave.addLine(to: p) }
        }
        ctx.stroke(Path(CGRect(x: W.minX, y: W.midY, width: W.width, height: 0)), with: .color(.white.opacity(0.12)), lineWidth: 1)
        ctx.stroke(wave, with: .color(Pal.ice), lineWidth: 1.8)
        Kit.chip(&ctx, "WHAT THE MIC HEARS", CGPoint(x: W.minX, y: W.minY - 6), anchor: .leading, color: Pal.ice, size: 7)
        if let e = evs.last, env(now - e.t) > 0.05 {
            Kit.chip(&ctx, "\(pads[e.pad].name): \(pads[e.pad].detail)", CGPoint(x: W.maxX, y: W.minY - 6), anchor: .trailing, color: Pal.signal, size: 8, alpha: pr(now - e.t, 0, 0.15))
        }
        // pitches over time
        let window = 4.0, colsN = 48
        let cw = S.width / Double(colsN), ch = S.height / Double(rowsN)
        ctx.fill(Path(S), with: .color(Pal.night.opacity(0.6)))
        for ci in 0..<colsN {
            let tau = now - window + (Double(ci) + 0.5) * (window / Double(colsN))
            for r in 0..<rowsN {
                var v = 0.0
                for e in evs where tau >= e.t {
                    let a = env(tau - e.t)
                    guard a > 0.02 else { continue }
                    for f in pads[e.pad].freqs {
                        for (hk, ha) in [(1.0, 1.0), (2.0, 0.5), (3.0, 0.28)] { let d = Double(r) + 0.5 - row(f * hk); v += a * ha * exp(-d * d / 0.35) }
                    }
                }
                v = min(1, v + 0.05 * Song.h(ci + Int(now / (window / Double(colsN))), r))
                guard v > 0.07 else { continue }
                ctx.fill(Path(CGRect(x: S.minX + Double(ci) * cw, y: S.maxY - Double(r + 1) * ch, width: cw + 0.5, height: ch + 0.5)), with: .color(heat(v)))
            }
        }
        ctx.stroke(Path(S), with: .color(.white.opacity(0.22)), lineWidth: 1)
        Kit.chip(&ctx, "EACH NOTE = A LINE · BRIGHTER = LOUDER", CGPoint(x: S.minX, y: S.minY - 6), anchor: .leading, color: Pal.signal, size: 7)
        Kit.chip(&ctx, "FREQUENCY ↑", CGPoint(x: S.minX + 4, y: S.minY + 14), anchor: .leading, size: 7, alpha: 0.85)
        Kit.chip(&ctx, "TIME →", CGPoint(x: S.maxX - 2, y: S.maxY - 8), anchor: .trailing, size: 7, alpha: 0.85)
        if !touched { Kit.chip(&ctx, "TAP A NOTE OR CHORD", CGPoint(x: S.midX, y: S.midY), color: .white, size: 9, alpha: 0.55 + 0.25 * sin(now * 2)) }
    }
}

// MARK: - Card 3: your clip, played and drawn as the same chart card 4 then strips down

struct ShazamClip: View {
    let active: Bool
    @State private var ref = Date()
    @State private var touched = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    private let len = Double(Song.cols) * 0.1     // 3 s: one column per tenth of a second
    private let loop = 6.0                         // untouched: draw silently, hold, repeat

    var body: some View {
        Panel {
            VStack(spacing: 8) {
                TimelineView(.animation(paused: !active || reduce)) { tl in
                    Canvas { ctx, s in
                        let el = tl.date.timeIntervalSince(ref)
                        draw(&ctx, s, t: reduce ? len : touched ? el : el.truncatingRemainder(dividingBy: loop))
                    }
                }
                Pill(label: touched ? "▶  PLAY AGAIN" : "▶  PLAY THE CLIP", on: !touched) { play() }
                    .padding(.horizontal, 60).padding(.bottom, 10)
            }
        }
        .onChange(of: active) { _, a in if a { ref = Date() } else { Synth.shared.stop() } }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("A three-second recording of a café: a tune with people talking over it. As it plays, it is drawn as a chart. The tune makes bright lines, the chatter makes faint speckle everywhere.")
    }

    private func play() {
        touched = true
        ref = Date()
        let syn = Synth.shared
        syn.stop()
        // the same notes the chart shows: one note per half second, a chord on every other one
        for k in 0..<(Song.cols / 5) {
            let n = Song.melody[k % Song.melody.count]
            let rows = k % 2 == 1 ? [n, n + 3, n + 6] : [n]
            syn.play(rows.map { Double(Song.hz($0)) }, after: Double(k) * 0.5)
        }
        syn.chatter(len)
        Haptic.fire(.light)
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, t: Double) {
        let shown = min(Double(Song.cols), t / 0.1)
        let fade = touched ? 1 : 1 - pr(t, loop - 0.4, loop)
        // what the mic picked up: a jagged wave, loud where the notes start
        let W = CGRect(x: 30, y: 22, width: s.width - 44, height: s.height * 0.16)
        var wave = Path()
        let steps = 180
        for i in 0...steps {
            let x = Double(i) / Double(steps)
            let c = x * Double(Song.cols)
            guard c <= shown else { break }
            let env = 0.25 + 0.75 * exp(-(c.truncatingRemainder(dividingBy: 5)) * 0.45)
            let v = env * sin(x * 260) * 0.7 + (Song.h(i, 7) - 0.5) * 0.6
            let p = CGPoint(x: W.minX + x * W.width, y: W.midY - v * W.height * 0.5)
            if i == 0 { wave.move(to: p) } else { wave.addLine(to: p) }
        }
        ctx.stroke(Path(CGRect(x: W.minX, y: W.midY, width: W.width, height: 0)), with: .color(.white.opacity(0.12)), lineWidth: 1)
        ctx.stroke(wave, with: .color(Pal.ice.opacity(fade)), lineWidth: 1.4)
        Kit.chip(&ctx, "YOUR PHONE'S RECORDING", CGPoint(x: W.minX, y: W.minY - 6), anchor: .leading, color: Pal.ice, size: 7)
        // the same recording as a chart
        let box = CGRect(x: 30, y: W.maxY + 34, width: s.width - 44, height: s.height - W.maxY - 88)
        ctx.fill(Path(box), with: .color(Pal.night.opacity(0.5)))
        for c in 0..<Song.cols where Double(c) < shown {
            let a = cl(shown - Double(c)) * fade
            for r in 0..<Song.rows {
                let v = Song.grid[c][r]
                guard v > 0.08 else { continue }
                ctx.fill(Path(cellRect(box, c, r).insetBy(dx: -0.3, dy: -0.3)), with: .color(heat(v).opacity(a)))
            }
        }
        if shown < Double(Song.cols) && t > 0 {
            let x = box.minX + box.width * shown / Double(Song.cols)
            var head = Path(); head.move(to: CGPoint(x: x, y: W.minY)); head.addLine(to: CGPoint(x: x, y: box.maxY))
            ctx.stroke(head, with: .color(Pal.coral.opacity(0.8)), lineWidth: 1.5)
        }
        axes(&ctx, box)
        let done = shown >= Double(Song.cols)
        let cap = done ? "MUSIC = BRIGHT LINES · CHATTER = FAINT SPECKLE" : "THE SAME SOUND, AS A CHART"
        caption(&ctx, s, cap, (done ? pr(t, len + 0.1, len + 0.4) : pr(t, 0.1, 0.4)) * fade, color: done ? Pal.signal : .white, y: box.maxY + 44)
    }
}

// MARK: - Card 4: raise the cutoff until only the peaks are left

struct ShazamPeaks: View {
    let active: Bool
    @State private var level = 0.0
    @State private var touched = false
    @State private var t0 = Date()
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        Panel {
            VStack(spacing: 4) {
                Canvas { ctx, s in draw(&ctx, s) }
                HStack(spacing: 8) {
                    Text("EVERYTHING").font(T.mono(9)).foregroundStyle(.white.opacity(0.75))
                    Slider(value: Binding(get: { level }, set: { level = $0; if !touched { touched = true; Haptic.fire(.soft) } }), in: 0...1)
                        .tint(Pal.signal)
                    Text("PEAKS ONLY").font(T.mono(9)).foregroundStyle(Pal.signal)
                }
                .padding(.horizontal, 12).padding(.bottom, 8)
            }
        }
        .task(id: "\(active)-\(touched)-\(reduce)") {
            guard active, !touched else { return }
            if reduce { level = 1; return }
            t0 = Date()
            while !Task.isCancelled && !touched {
                let t = Date().timeIntervalSince(t0).truncatingRemainder(dividingBy: 10)
                level = eio(pr(t, 1.2, 6.5)) * (1 - pr(t, 9.3, 10))
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("The sound picture of a noisy bar, full of faint speckle. A slider raises a cutoff: faint noise disappears first, then fainter music, until only the loudest points, the peaks, are left.")
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize) {
        let box = CGRect(x: 30, y: 22, width: s.width - 44, height: s.height - 52)
        let thr = level * 1.02
        let morph = pr(level, 0.6, 0.9)
        for c in 0..<Song.cols {
            for r in 0..<Song.rows {
                let a = Song.grid[c][r]
                if Song.isStar(c, r) {
                    if morph < 1 { ctx.fill(Path(cellRect(box, c, r).insetBy(dx: -0.3, dy: -0.3)), with: .color(heat(a).opacity(1 - morph))) }
                    continue
                }
                let alpha = cl((a - thr) / 0.06)
                guard alpha > 0.02 else { continue }
                ctx.fill(Path(cellRect(box, c, r).insetBy(dx: -0.3, dy: -0.3)), with: .color(heat(a).opacity(alpha)))
            }
        }
        for st in Song.stars { star(&ctx, cellCentre(box, st.c, st.r), 3.4 * pop(morph), alpha: min(1, morph * 1.6)) }
        axes(&ctx, box)
        let (txt, col): (String, Color) = level < 0.25 ? ("EVERY SOUND, LOUD OR FAINT", .white)
            : level < 0.55 ? ("FAINT SOUNDS DISAPPEAR", .white)
            : level < 0.85 ? ("ONLY THE LOUDEST PEAKS LEFT", Pal.signal)
            : ("KEEP THE PEAKS, THROW THE REST AWAY", Pal.signal)
        Kit.chip(&ctx, txt, CGPoint(x: box.midX + 10, y: box.minY + 8), anchor: .top, color: col, size: 9)
    }
}

// MARK: - Card 4: two stars and their gap make a code

private enum Pairs {
    static let zoneC = 12, zoneR = 10   // partners: 3-12 columns after the anchor, 3-10 rows away, so the two labels never collide
    static func partners(_ a: (c: Int, r: Int)) -> [(c: Int, r: Int)] {
        Array(Song.stars.filter { $0.c >= a.c + 3 && $0.c <= a.c + zoneC && abs($0.r - a.r) >= 3 && abs($0.r - a.r) <= zoneR }.sorted { $0.c < $1.c }.prefix(2))
    }
    static let anchors: [(c: Int, r: Int)] = {
        var out: [(c: Int, r: Int)] = []
        for s in Song.stars.sorted(by: { $0.c < $1.c }) where partners(s).count >= 1 {
            if let last = out.last, s.c - last.c < 5 { continue }
            out.append(s)
            if out.count == 4 { break }
        }
        return out
    }()
    static func code(_ a: (c: Int, r: Int), _ p: (c: Int, r: Int)) -> String { "\(Song.hz(a.r))·\(Song.hz(p.r))·\(Song.seconds(p.c - a.c))" }
    static func spoken(_ a: (c: Int, r: Int), _ p: (c: Int, r: Int)) -> String { "\(Song.hz(a.r)) HZ · \(Song.hz(p.r)) HZ · \(Song.seconds(p.c - a.c))" }
    /// Every (anchor, partner) pair used on cards 4 and 5, in order.
    static let all: [(a: (c: Int, r: Int), p: (c: Int, r: Int))] = Array(anchors.flatMap { a in partners(a).map { (a: a, p: $0) } }.prefix(5))
    /// One pair per anchor, so every code on card 5 comes from a different moment of the clip.
    static let lookup: [(a: (c: Int, r: Int), p: (c: Int, r: Int))] = anchors.compactMap { a in partners(a).first.map { (a: a, p: $0) } }
}

struct ShazamPairs: View {
    let active: Bool
    var body: some View {
        let beat = 3.4
        let n = max(1, Pairs.all.count)
        let period = beat * Double(n) + 1.0
        return FlatPicture(active: active, period: period, still: beat * 0.85, cues: (0..<n).map { Cue(Double($0) * beat + 0.5, .soft) }, replayOnTap: true, sky: deep,
                    label: "The peaks on the chart, frequency going up and time going across. Two peaks are picked. Each has a frequency and a time. Together they make a code of three numbers: the first frequency, the second frequency, and the seconds between them.") { ctx, s, t, _ in
            let fade = 1 - pr(t, period - 0.6, period)
            let box = CGRect(x: 30, y: 26, width: s.width - 44, height: s.height - 78)
            for (i, st) in Song.stars.enumerated() {
                star(&ctx, cellCentre(box, st.c, st.r), 2.4 * (0.85 + 0.15 * sin(t * 2 + Double(i))), alpha: 0.6 * fade)
            }
            axes(&ctx, box, alpha: fade)
            guard !Pairs.all.isEmpty else { return }
            let k = min(Int(t / beat), Pairs.all.count - 1)
            let lt = t - Double(k) * beat
            // earlier pairs stay as faint lines
            for j in 0..<k {
                let q = Pairs.all[j]
                var p = Path(); p.move(to: cellCentre(box, q.a.c, q.a.r)); p.addLine(to: cellCentre(box, q.p.c, q.p.r))
                ctx.stroke(p, with: .color(Pal.coral.opacity(0.3 * fade)), lineWidth: 1)
            }
            let q = Pairs.all[k]
            let ap = cellCentre(box, q.a.c, q.a.r), pp = cellCentre(box, q.p.c, q.p.r)
            let out = 1 - pr(lt, beat - 0.3, beat)
            // note 1
            let g1 = pop(pr(lt, 0.1, 0.5))
            Kit.ring(&ctx, ap, 8, Pal.coral, alpha: min(1, g1) * out * fade, width: 1.5)
            star(&ctx, ap, 3.4 * g1, Pal.coral, alpha: fade)
            let up = pp.y < ap.y
            Kit.chip(&ctx, "\(Song.hz(q.a.r)) HZ, AT \(Song.seconds(q.a.c))", CGPoint(x: min(max(ap.x, box.minX + 58), box.maxX - 58), y: up ? ap.y + 12 : ap.y - 12), anchor: up ? .top : .bottom, color: Pal.coral, size: 7, alpha: pr(lt, 0.3, 0.6) * out * fade)
            // note 2
            let g2 = pop(pr(lt, 0.9, 1.3))
            Kit.ring(&ctx, pp, 8, Pal.signal, alpha: min(1, g2) * out * fade, width: 1.5)
            star(&ctx, pp, 3.2 * max(1, g2), Pal.signal, alpha: fade)
            Kit.chip(&ctx, "\(Song.hz(q.p.r)) HZ, AT \(Song.seconds(q.p.c))", CGPoint(x: min(max(pp.x, box.minX + 58), box.maxX - 58), y: up ? pp.y - 12 : pp.y + 12), anchor: up ? .bottom : .top, color: Pal.signal, size: 7, alpha: pr(lt, 1.1, 1.4) * out * fade)
            // the gap between them, along the time axis
            let gw = eo(pr(lt, 1.5, 2.0))
            if gw > 0 {
                let y = box.maxY + 4
                var gap = Path(); gap.move(to: CGPoint(x: ap.x, y: y)); gap.addLine(to: CGPoint(x: ap.x + (pp.x - ap.x) * gw, y: y))
                ctx.stroke(gap, with: .color(.white.opacity(0.9 * out * fade)), lineWidth: 2.5)
                for x in [ap.x, pp.x] { var d = Path(); d.move(to: CGPoint(x: x, y: y)); d.addLine(to: CGPoint(x: x, y: (x == ap.x ? ap.y : pp.y))); ctx.stroke(d, with: .color(.white.opacity(0.25 * out * fade)), style: StrokeStyle(lineWidth: 1, dash: [2, 3])) }
                var link = Path(); link.move(to: ap); link.addLine(to: CGPoint(x: ap.x + (pp.x - ap.x) * gw, y: ap.y + (pp.y - ap.y) * gw))
                ctx.stroke(link, with: .color(Pal.coral.opacity(0.9 * fade)), lineWidth: 1.6)
                Kit.chip(&ctx, "TIME BETWEEN: \(Song.seconds(q.p.c - q.a.c))", CGPoint(x: (ap.x + pp.x) / 2, y: y + 4), anchor: .top, size: 7, alpha: pr(lt, 1.8, 2.1) * out * fade)
            }
            let codeA = pr(lt, 2.1, 2.4) * out
            caption(&ctx, s, codeA > 0 ? "CODE:  \(Pairs.spoken(q.a, q.p))" : "PICK TWO PEAKS", codeA > 0 ? codeA * fade : pr(lt, 0, 0.3) * (1 - pr(lt, 0.8, 1.0)) * fade, color: codeA > 0 ? Pal.coral : .white)
        }
    }
}

// MARK: - Card 5: one song at a time vs an index

struct ShazamLookup: View {
    let active: Bool
    @State private var mode = 0          // 0 = one by one, 1 = index
    @State private var t0 = Date()
    @State private var touched = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    private let runLen = [8.0, 8.5]

    var body: some View {
        Panel {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Pill(label: "ONE BY ONE", on: mode == 0) { pick(0) }
                    Pill(label: "INDEX", on: mode == 1) { pick(1) }
                }
                .padding(.horizontal, 12).padding(.top, 10)
                TimelineView(.animation(paused: !active || reduce)) { tl in
                    Canvas { ctx, s in
                        let el = tl.date.timeIntervalSince(t0)
                        let t = reduce ? runLen[mode] - 0.5 : min(el, runLen[mode] - 0.01)
                        draw(&ctx, s, t)
                    }
                }
            }
        }
        .onChange(of: active) { _, a in if a { t0 = Date(); if !touched { mode = 0 } } }
        .task(id: "\(active)-\(touched)-\(mode)") {
            // untouched: run one by one, then the index, then repeat
            guard active, !touched, !reduce else { return }
            try? await Task.sleep(for: .seconds(runLen[mode] + 1.2))
            if !Task.isCancelled && !touched { mode = 1 - mode; t0 = Date() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your clip's codes on the left. One by one: each song is checked against every code in turn, far too slowly for millions of songs. Index: each code is looked up and lists every song that contains it, with the time. One song, song E, appears for every code, and its times minus the clip's times all give the same offset, so it is the match.")
    }

    private func pick(_ m: Int) {
        touched = true
        mode = m
        t0 = Date()
        Haptic.fire(.light)
    }

    private var codes: [String] { Array(Pairs.lookup.prefix(4)).map { Pairs.code($0.a, $0.p) } }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ t: Double) {
        let cs = codes
        let leftX = 12.0, colW = s.width * 0.36
        let top = 30.0
        let rowH = min(30.0, (s.height - top - 44) / 6.5)
        if mode == 0 { Kit.chip(&ctx, "YOUR CODES", CGPoint(x: leftX + 4, y: top - 14), anchor: .leading, color: Pal.coral, size: 7) }
        func codeRect(_ i: Int) -> CGRect { CGRect(x: leftX, y: top + Double(i) * (rowH + 6), width: colW, height: rowH) }
        let rightX = leftX + colW + 18, rightW = s.width - rightX - 12
        func rightRect(_ i: Int) -> CGRect { CGRect(x: rightX, y: top + Double(i) * (rowH + 4), width: rightW, height: rowH) }

        if mode == 0 {
            // ONE BY ONE: walk every song, comparing it with every code
            let perSong = 1.25, perCode = perSong / Double(max(1, cs.count) + 1)
            let si = min(5, Int(t / perSong))
            let ci = Int((t - Double(si) * perSong) / perCode)
            for i in 0..<cs.count {
                let r = codeRect(i)
                let lit = t < 6 * perSong && i == ci
                ctx.fill(Path(roundedRect: r, cornerRadius: 5), with: .color(lit ? Pal.coral.opacity(0.35) : Pal.night.opacity(0.7)))
                ctx.stroke(Path(roundedRect: r, cornerRadius: 5), with: .color(Pal.coral.opacity(0.6)), lineWidth: 1)
                ctx.draw(ctx.resolve(Text(cs[i]).font(T.mono(9)).foregroundColor(.white)), at: CGPoint(x: r.midX, y: r.midY))
            }
            Kit.chip(&ctx, "EVERY SONG", CGPoint(x: rightX + 4, y: top - 14), anchor: .leading, size: 7)
            for i in 0..<6 {
                let r = rightRect(i)
                let cur = i == si && t < 6 * perSong
                let done = i < si || t >= 6 * perSong
                ctx.fill(Path(roundedRect: r, cornerRadius: 5), with: .color(Color(hex: 0x1A2148).opacity(0.9)))
                ctx.stroke(Path(roundedRect: r, cornerRadius: 5), with: .color(cur ? Pal.signal : Color(hex: 0xC9D2F5).opacity(0.3)), lineWidth: cur ? 2 : 1)
                ctx.draw(ctx.resolve(Text("SONG \(i + 1)").font(T.mono(9)).foregroundColor(.white.opacity(0.85))), at: CGPoint(x: r.minX + 8, y: r.midY), anchor: .leading)
                // one little box per code: checked, no match
                for k in 0..<cs.count {
                    let bx = CGRect(x: r.maxX - 10 - Double(cs.count - k) * 11, y: r.midY - 4, width: 8, height: 8)
                    let checked = done || (cur && k < ci)
                    ctx.fill(Path(roundedRect: bx, cornerRadius: 1.5), with: .color(checked ? Pal.coral : .white.opacity(0.12)))
                }
                if cur && ci < cs.count {
                    var p = Path(); p.move(to: CGPoint(x: codeRect(ci).maxX, y: codeRect(ci).midY)); p.addLine(to: CGPoint(x: r.minX, y: r.midY))
                    ctx.stroke(p, with: .color(Pal.signal.opacity(0.8)), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                }
            }
            let checked = min(6, si + (t >= 6 * perSong ? 1 : 0))
            Kit.chip(&ctx, "CHECKED \(checked) OF 50,000,000…", CGPoint(x: rightX + rightW / 2, y: rightRect(5).maxY + 14), size: 7, alpha: 0.85)
            caption(&ctx, s, t < 6 * perSong ? "SONG BY SONG, CODE BY CODE" : "THIS WOULD TAKE DAYS", t < 6 * perSong ? pr(t, 0.1, 0.4) : 1, color: t < 6 * perSong ? .white : Pal.coral)
        } else {
            // INDEX (modelled on Per Thirty Six's explainer): each code's line lists every song that has it, and when.
            // One song keeps turning up (green), and its times minus the clip's times all give the same offset.
            let match = Color(hex: 0x7CE0C3)
            let pairs = Array(Pairs.lookup.prefix(4))
            let base = 47.0
            let decoys = [["H @ 1:45", "L @ 1:49"], ["F @ 2:35", "J @ 0:04"], ["C @ 1:43", "B @ 0:49"], ["K @ 2:58", "H @ 2:08"]]
            let greenSlot = [2, 1, 0, 1]
            func mmss(_ x: Double) -> String { let m = Int(x) / 60; return String(format: "%d:%04.1f", m, x - Double(m * 60)) }
            let gap = 5.0, rowsTop = 8.0
            let offH = 22.0 + Double(pairs.count) * 17
            let rowH = min(54.0, (s.height - rowsTop - offH - 40 - gap * Double(pairs.count)) / Double(max(1, pairs.count)))
            let per = 1.0
            for (i, q) in pairs.enumerated() {
                let r = CGRect(x: 10, y: rowsTop + Double(i) * (rowH + gap), width: s.width - 20, height: rowH)
                let on = pr(t, 0.3 + Double(i) * per, 0.6 + Double(i) * per)
                ctx.fill(Path(roundedRect: r, cornerRadius: 6), with: .color(Pal.night.opacity(0.55)))
                ctx.stroke(Path(roundedRect: r, cornerRadius: 6), with: .color(match.opacity(0.2 + 0.35 * on)), lineWidth: 1)
                let cr = CGRect(x: r.minX + 6, y: r.midY - 13, width: s.width * 0.25, height: 26)
                ctx.fill(Path(roundedRect: cr, cornerRadius: 4), with: .color(Color(hex: 0x05070F)))
                ctx.draw(ctx.resolve(Text(Pairs.code(q.a, q.p)).font(T.mono(7.5)).foregroundColor(on > 0 ? match : .white.opacity(0.7))), at: CGPoint(x: cr.midX, y: cr.midY))
                ctx.draw(ctx.resolve(Text("→").font(T.mono(9)).foregroundColor(.white.opacity(0.4 + 0.4 * on))), at: CGPoint(x: cr.maxX + 8, y: cr.midY))
                let clipT = Double(q.a.c) * 0.1
                let hit = "E @ " + mmss(base + clipT)
                var chips = decoys[i % decoys.count]
                chips.insert(hit, at: min(greenSlot[i % greenSlot.count], chips.count))
                let ax = cr.maxX + 14, aw = r.maxX - 4 - ax
                let w = (aw - 6) / 3
                for (k, c) in chips.enumerated() {
                    let appear = pr(t, 0.45 + Double(i) * per + Double(k) * 0.08, 0.7 + Double(i) * per + Double(k) * 0.08)
                    guard appear > 0 else { continue }
                    let isHit = c == hit && t > 0.85 + Double(i) * per
                    let chip = CGRect(x: ax + Double(k) * (w + 3), y: r.midY - 12, width: w, height: 24)
                    var l = ctx
                    l.opacity = appear
                    l.fill(Path(roundedRect: chip, cornerRadius: 4), with: .color(isHit ? match.opacity(0.25) : .white.opacity(0.06)))
                    if isHit { l.stroke(Path(roundedRect: chip, cornerRadius: 4), with: .color(match), lineWidth: 1.2) }
                    l.draw(l.resolve(Text("SONG " + c).font(T.mono(6.5)).foregroundColor(isHit ? match : .white.opacity(0.55))), at: CGPoint(x: chip.midX, y: chip.midY))
                }
            }
            // time offsets: the song's time minus the clip's time
            let ob = CGRect(x: 10, y: rowsTop + Double(pairs.count) * (rowH + gap) + 2, width: s.width - 20, height: offH)
            let offStart = 0.4 + Double(pairs.count) * per
            let oa = pr(t, offStart - 0.3, offStart)
            if oa > 0 {
                var l = ctx
                l.opacity = oa
                l.fill(Path(roundedRect: ob, cornerRadius: 6), with: .color(.white.opacity(0.05)))
                l.draw(l.resolve(Text("TIMING CHECK: SONG TIME − CLIP TIME").font(T.mono(7)).tracking(0.8).foregroundColor(.white.opacity(0.6))), at: CGPoint(x: ob.minX + 8, y: ob.minY + 11), anchor: .leading)
            }
            for (i, q) in pairs.enumerated() {
                let la = pr(t, offStart + Double(i) * 0.45, offStart + Double(i) * 0.45 + 0.3)
                guard la > 0 else { continue }
                let clipT = Double(q.a.c) * 0.1
                let y = ob.minY + 26 + Double(i) * 17
                var l = ctx
                l.opacity = la
                l.draw(l.resolve(Text("SONG E @ \(mmss(base + clipT))  −  CLIP @ \(String(format: "%.1f", clipT))s").font(T.mono(8.5)).foregroundColor(.white.opacity(0.8))), at: CGPoint(x: ob.minX + 8, y: y), anchor: .leading)
                l.draw(l.resolve(Text("= 47s").font(T.mono(8.5)).foregroundColor(match)), at: CGPoint(x: ob.maxX - 8, y: y), anchor: .trailing)
            }
            let done = offStart + Double(pairs.count) * 0.45 + 0.3
            let (cap, ca, cc): (String, Double, Color) = t < offStart ? ("EACH CODE LISTS EVERY SONG THAT HAS IT", pr(t, 0.1, 0.4), .white)
                : t < done ? ("DO THE TIMES AGREE?", pr(t, offStart, offStart + 0.3), .white)
                : ("ALL CODES: SONG E, SAME OFFSET ✓", pr(t, done, done + 0.3), match)
            caption(&ctx, s, cap, ca, color: cc)
        }
    }
}
