import SwiftUI

// Scenes: pictures as data (tasks/scene-format.md, 2026-11-03). A scene file (`Scenes/<id>.json`) describes each narrated card's
// picture as kit parts, SVG paths, labels and groups, and moves that start on a spoken word rather than at a picture second. The word
// times come from the topic's `voice-<id>.json`, so a scene topic's script needs no `{t}` markers. Parts are Swift drawing code in the
// style's kit, registered by name in `SceneParts`. A card without a scene keeps its hand-written Swift picture (`Pictures.swift`).

/// One topic's scenes, one per narrated card.
struct SceneFile: Decodable { let scenes: [PictureScene] }

struct PictureScene: Decodable {
    let card: Int                 // 0-based card index, as in Pictures.swift
    let label: String             // what the picture shows, for VoiceOver
    let elements: [SceneElement]
    var moves: [SceneMove]? = nil

    /// `--no-scenes` draws the hand-written Swift pictures instead, to compare the two.
    static var enabled: Bool { !ProcessInfo.processInfo.arguments.contains("--no-scenes") }
    private static var cache: [String: SceneFile?] = [:]

    /// The scene for this topic's card, if the topic ships `Scenes/<id>.json` and it has one for the card.
    static func find(_ id: String, card: Int) -> PictureScene? {
        guard enabled else { return nil }
        if cache[id] == nil {
            cache[id] = Bundle.main.url(forResource: id, withExtension: "json", subdirectory: "Scenes")
                .flatMap { try? Data(contentsOf: $0) }
                .flatMap { data in
                    do { return try JSONDecoder().decode(SceneFile.self, from: data) }
                    catch { print("Scene \(id): \(error)"); return nil }
                }
        }
        return cache[id]??.scenes.first { $0.card == card }
    }
}

/// One thing drawn. Exactly one of part, path, circle, rect, label, text or group says what it is; the rest are options.
struct SceneElement: Decodable {
    var id: String? = nil
    // what it is
    var part: String? = nil              // a kit part by name (SceneParts)
    var path: String? = nil              // SVG path data, absolute or relative: M L H V C S Q T Z
    var circle: [Double]? = nil          // cx, cy, r
    var rect: [Double]? = nil            // x, y, w, h, corner radius (optional)
    var label: String? = nil             // a label with a leader line (DR.label); "\n" breaks the line
    var text: String? = nil              // plain text, no leader
    var group: [SceneElement]? = nil
    // where
    var at: [Double]? = nil              // moves the element's own frame: x, y
    var anchor: [Double]? = nil          // label: the dot on the part
    var align: String? = nil             // label: leading (default), center, trailing
    var scale: Double? = nil
    var rotate: Double? = nil            // degrees
    var mirror: Bool? = nil              // flip left to right about x = 0 of its frame
    var clip: SceneShape? = nil          // group: only draw children inside this shape
    // how
    var stroke: String? = nil            // colour name, "ink@0.4" for alpha; "none" for no outline (default ink)
    var fill: String? = nil              // colour name; none by default
    var width: Double? = nil             // line width (default DR.line)
    var dash: [Double]? = nil
    var hatch: SceneHatch? = nil         // shade inside the shape
    var size: Double? = nil              // text: point size
    var weight: String? = nil            // text: regular, semibold, bold
    var params: [String: Double]? = nil  // a part's own numbers
    // when
    var hidden: Bool? = nil              // starts at opacity 0; a move brings it in
    var word: String? = nil              // draws on when this word is said (default: at the start of the beat)
    var delay: Double? = nil             // seconds after that word
    var draw: Double? = nil              // seconds the draw-on takes (default 0.8, labels 0.5)
    var wobble: [SceneWobble]? = nil     // gentle loops: a prop rocking on a sine wave
}

struct SceneShape: Decodable { var circle: [Double]? = nil; var rect: [Double]? = nil; var path: String? = nil }
struct SceneHatch: Decodable { var band: [Double]? = nil; var spacing: Double? = nil; var alpha: Double? = nil }   // band: x, y, w, h (default: the whole shape)
struct SceneWobble: Decodable { let prop: String; let amp: Double; var speed: Double? = nil; var phase: Double? = nil }

/// A change to one number on one element, starting on a spoken word.
struct SceneMove: Decodable {
    let move: String          // the element's id
    let prop: String          // x, y, opacity, scale, rotate, draw (0...1 outline), fill (0...1), or a part param
    let to: Double
    var word: String? = nil   // "hard", or "hard#2" for its second time in the paragraph
    var at: Double? = nil     // or seconds into the beat
    var delay: Double? = nil
    var dur: Double? = nil    // default 0.5
    var ease: String? = nil   // eio (default), eout, snap, fall, linear
}

// MARK: - Drawing

/// Draws a scene from the narration's clock. Without one (the Cards version), it shows the end state.
struct SceneStage: View {
    let topic: Topic
    let scene: PictureScene
    let active: Bool
    var size = CGSize(width: 343, height: 320)
    @Environment(\.pictureClock) private var narrated
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        let words = Self.beatWords(topic.id, card: scene.card)
        let t = reduce || narrated == nil ? 999 : max(0, narrated!.clock)
        return Canvas { ctx, size in
            let u = min(size.width / self.size.width, size.height / self.size.height)
            var c = ctx
            c.translateBy(x: (size.width - self.size.width * u) / 2, y: (size.height - self.size.height * u) / 2)
            c.scaleBy(x: u, y: u)
            SceneRenderer(scene: scene, words: words, t: t, clock: reduce ? 2.2 : t).draw(&c)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scene.label)
    }

    /// The beat's words, lower-cased letters and digits only, with their start in seconds from the beat's start.
    static func beatWords(_ id: String, card: Int) -> [(String, Double)] {
        guard let n = Narration.load(id)?.0, card < n.beats.count else { return [] }
        let a = n.beats[card], b = card + 1 < n.beats.count ? n.beats[card + 1] : .infinity
        return n.words.filter { $0.start >= a - 0.01 && $0.start < b - 0.01 }.map { (SceneRenderer.norm($0.text), $0.start - a) }
    }
}

struct SceneRenderer {
    let scene: PictureScene
    let words: [(String, Double)]
    let t: Double          // seconds into the beat
    let clock: Double

    static func norm(_ s: String) -> String { String(s.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }) }

    /// When `word` ("hard" or "hard#2") starts, in seconds into the beat; 0 if it is not said (the checker reports that).
    func time(of word: String?) -> Double {
        guard let word else { return 0 }
        let bits = word.split(separator: "#")
        let w = Self.norm(String(bits[0])), n = bits.count > 1 ? Int(bits[1]) ?? 1 : 1
        let hits = words.filter { $0.0 == w }
        return hits.count >= n ? hits[n - 1].1 : 0
    }

    static func ease(_ name: String?, _ x: Double) -> Double {
        switch name {
        case "linear": return x
        case "eout": return BP.eout(x)
        case "snap": return DR.snap(x)
        case "fall": return x * x
        default: return BP.eio(x)
        }
    }

    func draw(_ c: inout GraphicsContext) {
        for e in scene.elements { draw(e, &c) }
    }

    /// The value of `prop` on `e` now: its base, then every move on it in start order.
    private func value(_ e: SceneElement, _ prop: String, base: Double) -> Double {
        var v = base
        if let id = e.id, let moves = scene.moves {
            let mine = moves.filter { $0.move == id && $0.prop == prop }
                .map { m in (m, (m.at ?? time(of: m.word)) + (m.delay ?? 0)) }
                .sorted { $0.1 < $1.1 }
            for (m, start) in mine {
                let k = Self.ease(m.ease, BP.pr(t, start, start + max(m.dur ?? 0.5, 0.001)))
                v += (m.to - v) * k
            }
        }
        for w in e.wobble ?? [] where w.prop == prop { v += w.amp * sin(clock * (w.speed ?? 2) + (w.phase ?? 0)) }
        return v
    }

    private func draw(_ e: SceneElement, _ c: inout GraphicsContext) {
        let opacity = value(e, "opacity", base: e.hidden == true ? 0 : 1)
        guard opacity > 0.005 else { return }
        let start = time(of: e.word) + (e.delay ?? 0)
        let span = e.draw ?? (e.label != nil ? 0.5 : 0.8)
        let on = value(e, "draw", base: BP.pr(t, start, start + span))
        let fillIn = value(e, "fill", base: BP.pr(t, start + span * 0.3, start + span * 0.9))
        guard on > 0 else { return }

        var g = c
        g.opacity *= opacity
        let frame = e.label == nil ? e.at : nil            // a label's `at` is where its text sits, not a move of its frame
        g.translateBy(x: value(e, "x", base: frame?[0] ?? 0), y: value(e, "y", base: frame?[1] ?? 0))
        let r = value(e, "rotate", base: e.rotate ?? 0)
        if r != 0 { g.rotate(by: .degrees(r)) }
        let s = value(e, "scale", base: e.scale ?? 1)
        if s != 1 { g.scaleBy(x: s, y: s) }
        if e.mirror == true { g.scaleBy(x: -1, y: 1) }

        if let kids = e.group {
            if let clip = e.clip, let shape = Self.shape(clip.circle, clip.rect, clip.path) { g.clip(to: shape) }
            for k in kids { draw(k, &g) }
        } else if let name = e.part {
            var p = e.params ?? [:]
            for key in p.keys { p[key] = value(e, key, base: p[key]!) }
            SceneParts.draw(name, &g, ScenePart(p: p, on: on, fill: fillIn, clock: clock))
        } else if let text = e.label {
            let a = e.anchor ?? [0, 0], to = e.at ?? a
            DR.label(&g, text, anchor: CGPoint(x: a[0], y: a[1]), at: CGPoint(x: to[0], y: to[1]),
                     align: e.align == "center" ? .center : e.align == "trailing" ? .trailing : .leading, p: on)
        } else if let text = e.text {
            let w: Font.Weight = e.weight == "bold" ? .bold : e.weight == "regular" ? .regular : .semibold
            let col = Self.color(e.stroke == nil || e.stroke == "none" ? "ink" : e.stroke!) ?? DR.ink
            let r = g.resolve(Text(text).font(.system(size: e.size ?? 8.5, weight: w, design: .rounded)).tracking(0.6).foregroundColor(col))
            var tg = g; tg.opacity *= on
            tg.draw(r, at: .zero, anchor: e.align == "leading" ? .leading : e.align == "trailing" ? .trailing : .center)
        } else if let shape = Self.shape(e.circle, e.rect, e.path) {
            if let f = e.fill.flatMap(Self.color) {
                var fg = g; fg.opacity *= fillIn
                fg.fill(shape, with: .color(f))
                if let h = e.hatch { Self.hatch(&fg, shape, h) }
            } else if let h = e.hatch {
                var fg = g; fg.opacity *= fillIn; Self.hatch(&fg, shape, h)
            }
            if e.stroke != "none" {
                DR.draw(&g, shape, p: on, width: e.width ?? DR.line, color: Self.color(e.stroke ?? "ink") ?? DR.ink, dash: (e.dash ?? []).map { CGFloat($0) })
            }
        }
    }

    private static func hatch(_ g: inout GraphicsContext, _ shape: Path, _ h: SceneHatch) {
        let r = h.band.map { CGRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]) } ?? shape.boundingRect
        DR.hatch(&g, shape, in: r, spacing: h.spacing ?? 4, alpha: h.alpha ?? 0.35)
    }

    static func shape(_ circle: [Double]?, _ rect: [Double]?, _ path: String?) -> Path? {
        if let c = circle, c.count >= 3 { return Path(ellipseIn: CGRect(x: c[0] - c[2], y: c[1] - c[2], width: 2 * c[2], height: 2 * c[2])) }
        if let r = rect, r.count >= 4 { return Path(roundedRect: CGRect(x: r[0], y: r[1], width: r[2], height: r[3]), cornerRadius: r.count > 4 ? r[4] : 0) }
        if let p = path { return SVGPath.parse(p) }
        return nil
    }

    /// Kit colours by name, with an optional alpha: "ink", "ink@0.4", "accent", "accentSide", "face", "side", "paper", "white".
    static func color(_ name: String) -> Color? {
        let bits = name.split(separator: "@"), a = bits.count > 1 ? Double(bits[1]) ?? 1 : 1
        let base: Color
        switch bits.first ?? "" {
        case "ink": base = DR.ink
        case "accent": base = DR.accent
        case "accentSide": base = DR.accentSide
        case "face": base = DR.face
        case "side": base = DR.side
        case "paper": base = DR.paper
        case "white": base = .white
        default: return nil
        }
        return a == 1 ? base : base.opacity(a)
    }
}

// MARK: - SVG path data

enum SVGPath {
    /// Path data as in SVG's `d` attribute: M L H V C S Q T Z, upper case absolute, lower case relative. No arcs.
    static func parse(_ d: String) -> Path {
        var tokens: [String] = []
        var cur = ""
        for ch in d {
            if ch.isLetter && ch != "e" && ch != "E" { if !cur.isEmpty { tokens.append(cur); cur = "" }; tokens.append(String(ch)) }
            else if ch == "," || ch == " " || ch == "\n" || ch == "\t" { if !cur.isEmpty { tokens.append(cur); cur = "" } }
            else if ch == "-" && !cur.isEmpty && !cur.hasSuffix("e") { tokens.append(cur); cur = "-" }
            else { cur.append(ch) }
        }
        if !cur.isEmpty { tokens.append(cur) }

        var p = Path(), i = 0, cmd: Character = "M"
        var pos = CGPoint.zero, startPt = CGPoint.zero, lastCtrl: CGPoint?
        func num() -> Double { defer { i += 1 }; return i < tokens.count ? Double(tokens[i]) ?? 0 : 0 }
        func point(_ rel: Bool) -> CGPoint { let x = num(), y = num(); return rel ? CGPoint(x: pos.x + x, y: pos.y + y) : CGPoint(x: x, y: y) }
        while i < tokens.count {
            if let ch = tokens[i].first, ch.isLetter { cmd = ch; i += 1 }
            let rel = cmd.isLowercase
            switch cmd.uppercased() {
            case "M":
                pos = point(rel); startPt = pos; p.move(to: pos); lastCtrl = nil
                cmd = rel ? "l" : "L"                          // further pairs are lines
            case "L": pos = point(rel); p.addLine(to: pos); lastCtrl = nil
            case "H": let x = num(); pos = CGPoint(x: rel ? pos.x + x : x, y: pos.y); p.addLine(to: pos); lastCtrl = nil
            case "V": let y = num(); pos = CGPoint(x: pos.x, y: rel ? pos.y + y : y); p.addLine(to: pos); lastCtrl = nil
            case "C":
                let c1 = point(rel), c2 = point(rel), e = point(rel)
                p.addCurve(to: e, control1: c1, control2: c2); lastCtrl = c2; pos = e
            case "S":
                let c1 = lastCtrl.map { CGPoint(x: 2 * pos.x - $0.x, y: 2 * pos.y - $0.y) } ?? pos
                let c2 = point(rel), e = point(rel)
                p.addCurve(to: e, control1: c1, control2: c2); lastCtrl = c2; pos = e
            case "Q":
                let c1 = point(rel), e = point(rel)
                p.addQuadCurve(to: e, control: c1); lastCtrl = c1; pos = e
            case "T":
                let c1 = lastCtrl.map { CGPoint(x: 2 * pos.x - $0.x, y: 2 * pos.y - $0.y) } ?? pos
                let e = point(rel)
                p.addQuadCurve(to: e, control: c1); lastCtrl = c1; pos = e
            case "Z": p.closeSubpath(); pos = startPt; lastCtrl = nil
            default: i += 1
            }
        }
        return p
    }
}
