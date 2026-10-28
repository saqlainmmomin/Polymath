import SwiftUI

// Blueprint style: a small shared picture engine. Pictures are drawn as technical illustrations in one ink colour (plus at most one accent),
// thin even lines, flat tints only. Everything draws in a 343 x 320 design space; keep clear of the bottom-right corner (x > 288, y > 235).

/// Blueprint paper behind a topic, the same in light and dark: deep navy (darker reads better than cobalt), with a bright major grid,
/// a fainter minor grid four to a square, and dotted half-lines inside each minor square. Fills the whole screen.
struct PaperGrid: View {
    static let line = Color(hex: 0x6EA4EC)

    var body: some View {
        Canvas { c, size in
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(BP.paper))
            func grid(_ step: Double, _ offset: Double = 0) -> Path {
                var g = Path()
                var x = offset
                while x <= size.width { g.move(to: CGPoint(x: x, y: 0)); g.addLine(to: CGPoint(x: x, y: size.height)); x += step }
                var y = offset
                while y <= size.height { g.move(to: CGPoint(x: 0, y: y)); g.addLine(to: CGPoint(x: size.width, y: y)); y += step }
                return g
            }
            c.stroke(grid(12, 6), with: .color(Self.line.opacity(0.035)), style: StrokeStyle(lineWidth: 0.5, dash: [1, 2]))
            c.stroke(grid(12), with: .color(Self.line.opacity(0.07)), lineWidth: 0.5)
            c.stroke(grid(48), with: .color(Self.line.opacity(0.13)), lineWidth: 0.6)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// Shell for blueprint pictures: waits 0.4 s after the card settles, plays one action of `length` seconds, then holds; tap replays,
/// Reduce Motion shows the end state, one optional light haptic at `tick`, and it rewinds once off screen.
struct BlueprintStage: View {
    let active: Bool
    let length: Double            // seconds the action takes
    var tick: Double? = nil       // when the key moment lands (one light haptic)
    let label: String
    /// Draws in the 343 x 320 design space: seconds into the action (0...length) and the topic's palette.
    /// `clock` keeps counting after the action ends (for waves that loop); with Reduce Motion it holds still at 2.2 s.
    let draw: (inout GraphicsContext, Double, StagePalette, Double) -> Void
    var size = CGSize(width: 343, height: 320)     // design space; the picture is scaled to fit the stage

    @Environment(\.accessibilityReduceMotion) private var reduce
    @Environment(\.stage) private var pal
    @State private var start: Date?
    @State private var run = 0

    /// Wait after the card settles, so the page spring is over before anything moves.
    private static let settle = 0.4

    var body: some View {
        // Paused until `start` is set: a timeline that was live from the app's very first frame never ticked, freezing the first card.
        TimelineView(.animation(paused: !active || reduce || start == nil)) { tl in
            Canvas { ctx, size in
                let t = reduce ? length : (start.map { min(length, max(0, tl.date.timeIntervalSince($0) - Self.settle)) } ?? 0)
                let u = min(size.width / self.size.width, size.height / self.size.height)
                var c = ctx
                c.translateBy(x: (size.width - self.size.width * u) / 2, y: (size.height - self.size.height * u) / 2)
                c.scaleBy(x: u, y: u)
                let clock = reduce ? 2.2 : (start.map { max(0, tl.date.timeIntervalSince($0) - Self.settle) } ?? 0)
                draw(&c, t, pal, clock)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: "\(active)-\(run)") {
            if active {
                start = Date()
                guard let tick, !reduce else { return }
                try? await Task.sleep(nanoseconds: UInt64((Self.settle + tick) * 1e9))
                if !Task.isCancelled { Haptic.fire(.light) }
            } else {
                try? await Task.sleep(nanoseconds: 700_000_000)    // once the card is off screen, rewind it for next time
                if !Task.isCancelled { start = nil }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint("Tap to replay")
    }
}

// MARK: - Small helpers (BP namespace so they never clash with other files' private helpers)

enum BP {
    static func cl(_ x: Double) -> Double { min(1, max(0, x)) }
    /// 0...1 progress of `t` between `a` and `b`.
    static func pr(_ t: Double, _ a: Double, _ b: Double) -> Double { cl((t - a) / (b - a)) }
    static func eout(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
    static func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
    static func mix(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }
    static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
    static func mixp(_ a: CGPoint, _ b: CGPoint, _ k: Double) -> CGPoint { pt(mix(a.x, b.x, k), mix(a.y, b.y, k)) }
    static let edge = 1.4, hair = 1.0
    /// The page colour, opaque, so a solid part hides what is behind it.
    static let paper = Color(hex: 0x0F1E46)      // the paper's navy, also the fill of parts that hide what is behind them
}

/// Standard 30-degree isometric projection: world x runs down-right, y down-left, z up. `scale` is points per world unit.
struct Iso {
    var origin: CGPoint
    var scale: Double
    func p(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
        CGPoint(x: origin.x + (x - y) * 0.8660254 * scale, y: origin.y + (x + y) * 0.5 * scale - z * scale)
    }
}

// MARK: - Primitives

/// Strokes `path` drawn on from its start: `p` 0...1 trims it.
func bpTrace(_ c: inout GraphicsContext, _ path: Path, p: Double, color: Color, width: Double = BP.edge, dash: [CGFloat] = []) {
    guard p > 0.001 else { return }
    c.stroke(path.trimmedPath(from: 0, to: BP.cl(p)), with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
}

/// A dashed guide line from `a` to `b`, drawn on by `p`.
func bpGuide(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, p: Double = 1, color: Color) {
    var path = Path(); path.move(to: a); path.addLine(to: b)
    bpTrace(&c, path, p: p, color: color, width: BP.hair, dash: [4, 4])
}

/// A box with its corner at world (x, y, z) and size (w, d, h): very light top face, two darker side faces, every edge stroked in ink.
/// `p` draws it on: edges trim in, tints fade in over the second half.
func bpSlab(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, z: Double, w: Double, d: Double, h: Double, ink: Color, p: Double = 1) {
    guard p > 0.001 else { return }
    let top = [iso.p(x, y, z + h), iso.p(x + w, y, z + h), iso.p(x + w, y + d, z + h), iso.p(x, y + d, z + h)]
    let left = [iso.p(x, y + d, z + h), iso.p(x + w, y + d, z + h), iso.p(x + w, y + d, z), iso.p(x, y + d, z)]     // faces front-left
    let right = [iso.p(x + w, y + d, z + h), iso.p(x + w, y, z + h), iso.p(x + w, y, z), iso.p(x + w, y + d, z)]    // faces front-right
    func poly(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }
    let f = BP.pr(p, 0.4, 1), under = BP.pr(p, 0.25, 0.5)
    for face in [top, left, right] { c.fill(poly(face), with: .color(BP.paper.opacity(under))) }
    c.fill(poly(top), with: .color(ink.opacity(0.08 * f)))
    c.fill(poly(left), with: .color(ink.opacity(0.14 * f)))
    c.fill(poly(right), with: .color(ink.opacity(0.20 * f)))
    var e = poly(top)
    e.move(to: iso.p(x, y + d, z + h)); e.addLine(to: iso.p(x, y + d, z)); e.addLine(to: iso.p(x + w, y + d, z)); e.addLine(to: iso.p(x + w, y, z))
    e.move(to: iso.p(x + w, y + d, z + h)); e.addLine(to: iso.p(x + w, y + d, z))
    bpTrace(&c, e, p: p, color: ink)
}

/// A rounded rectangle lying on a face of the isometric world: starts at world `o`, runs `u` units along unit vector `ux` and `v` along `vx`.
/// With `r` = half the size it is a circle (an ellipse once projected).
func bpFacePath(_ iso: Iso, o: SIMD3<Double>, ux: SIMD3<Double>, vx: SIMD3<Double>, u: Double, v: Double, w: Double, h: Double, r: Double) -> Path {
    var pts: [CGPoint] = []
    let corners = [(u + w - r, v + r, -90.0), (u + w - r, v + h - r, 0.0), (u + r, v + h - r, 90.0), (u + r, v + r, 180.0)]
    for (cu, cv, a0) in corners {
        for i in 0...8 {
            let a = (a0 + 90 * Double(i) / 8) * .pi / 180
            let pu = cu + r * cos(a), pv = cv + r * sin(a)
            let q = o + ux * pu + vx * pv
            pts.append(iso.p(q.x, q.y, q.z))
        }
    }
    var path = Path(); path.addLines(pts); path.closeSubpath()
    return path
}

/// A leader label: a thin line from `anchor` (a dot on the part) to `elbow`, a short horizontal tail of `tail` points (negative goes left),
/// then the label in small uppercase mono type. The line draws on first (`p` 0...0.6), then the text fades in (0.6...1).
func bpLeader(_ c: inout GraphicsContext, anchor: CGPoint, elbow: CGPoint, tail: Double, text: String, ink: Color, p: Double) {
    guard p > 0.001 else { return }
    var path = Path(); path.move(to: anchor); path.addLine(to: elbow); path.addLine(to: BP.pt(elbow.x + tail, elbow.y))
    bpTrace(&c, path, p: BP.pr(p, 0, 0.6), color: ink, width: BP.hair)
    c.fill(Path(ellipseIn: CGRect(x: anchor.x - 2.2, y: anchor.y - 2.2, width: 4.4, height: 4.4)), with: .color(ink.opacity(BP.pr(p, 0, 0.1))))
    let a = BP.pr(p, 0.6, 1)
    guard a > 0.01 else { return }
    let at = BP.pt(elbow.x + tail + (tail >= 0 ? 4 : -4), elbow.y)
    let lines = text.components(separatedBy: "\n")
    for (i, l) in lines.enumerated() {
        c.draw(c.resolve(Text(l).font(T.mono(10)).tracking(0.9).foregroundColor(ink.opacity(a))), at: BP.pt(at.x, at.y + (Double(i) - Double(lines.count - 1) / 2) * 13), anchor: tail >= 0 ? .leading : .trailing)
    }
}

/// Small uppercase mono text at `at`.
func bpText(_ c: inout GraphicsContext, _ text: String, _ at: CGPoint, ink: Color, alpha: Double = 1, anchor: UnitPoint = .center) {
    guard alpha > 0.01 else { return }
    c.draw(c.resolve(Text(text).font(T.mono(10)).tracking(0.9).foregroundColor(ink.opacity(alpha))), at: at, anchor: anchor)
}

/// A dimension line from `a` to `b` growing by `p`: end ticks drawn along `tick` (a vector), arrowheads on the growing end, and the label centred
/// on the line over a gap in it. The label shows once the line is nearly complete.
func bpDimension(_ c: inout GraphicsContext, from a: CGPoint, to b: CGPoint, tick: CGPoint, text: String, labelWidth: Double, ink: Color, p: Double) {
    guard p > 0.001 else { return }
    let e = BP.mixp(a, b, p)
    let len = hypot(b.x - a.x, b.y - a.y), ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    let gapA = (len - labelWidth) / 2 / len, gapB = (len + labelWidth) / 2 / len        // gap as fractions of the full line
    var path = Path()
    path.move(to: a); path.addLine(to: BP.mixp(a, b, min(p, gapA)))
    if p > gapB { path.move(to: BP.mixp(a, b, gapB)); path.addLine(to: e) }
    for q in [a, e] where q == a || p > 0.98 {
        path.move(to: BP.pt(q.x - tick.x, q.y - tick.y)); path.addLine(to: BP.pt(q.x + tick.x, q.y + tick.y))
    }
    // small arrowheads pointing outward at both ends
    let ah = 5.0
    func head(_ q: CGPoint, _ dir: Double) {
        let hx = ux * dir, hy = uy * dir
        path.move(to: BP.pt(q.x - hx * ah - hy * 2.2, q.y - hy * ah + hx * 2.2)); path.addLine(to: q)
        path.addLine(to: BP.pt(q.x - hx * ah + hy * 2.2, q.y - hy * ah - hx * 2.2))
    }
    head(a, -1)
    if p > 0.98 { head(b, 1) }
    c.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round))
    let ta = BP.pr(p, 0.92, 1)
    if ta > 0.01 {
        c.draw(c.resolve(Text(text).font(T.mono(10)).tracking(0.9).foregroundColor(ink.opacity(ta))), at: BP.mixp(a, b, 0.5), anchor: .center)
    }
}

// MARK: - Cartoon people (screen space, drawn at a seat)

/// Runs `body` with everything drawn at `alpha` (for fading a group of parts in).
func bpGroup(_ c: inout GraphicsContext, alpha: Double, _ body: (inout GraphicsContext) -> Void) {
    guard alpha > 0.01 else { return }
    var g = c; g.opacity = alpha; body(&g)
}

/// A music note drawn as a path (head, stem, flag) with its head at `p`; `s` is the stem height.
func bpNote(_ c: inout GraphicsContext, _ p: CGPoint, s: Double, color: Color) {
    c.fill(Path(ellipseIn: CGRect(x: p.x - 3.4, y: p.y - 2.4, width: 6.8, height: 4.8)), with: .color(color))
    var st = Path(); st.move(to: BP.pt(p.x + 3.1, p.y - 0.5)); st.addLine(to: BP.pt(p.x + 3.1, p.y - s))
    st.addQuadCurve(to: BP.pt(p.x + 7.4, p.y - s * 0.45), control: BP.pt(p.x + 4.2, p.y - s * 0.7))
    c.stroke(st, with: .color(color), style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
}

/// An outlined arm: shoulder, bent through `elbow`, to a hand.
func bpArm(_ c: inout GraphicsContext, from s: CGPoint, elbow e: CGPoint, to h: CGPoint, ink: Color) {
    var a = Path(); a.move(to: s); a.addQuadCurve(to: h, control: e)
    c.stroke(a, with: .color(ink), style: StrokeStyle(lineWidth: 5.6, lineCap: .round))
    c.stroke(a, with: .color(BP.paper), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
    c.fill(Path(ellipseIn: CGRect(x: h.x - 2.8, y: h.y - 2.8, width: 5.6, height: 5.6)), with: .color(BP.paper))
    c.stroke(Path(ellipseIn: CGRect(x: h.x - 2.8, y: h.y - 2.8, width: 5.6, height: 5.6)), with: .color(ink), lineWidth: 1.2)
}

/// A seated person's legs, shoes, torso and head, with `b` the middle of the seat. `f` is 0 facing us, +1 or -1 in profile.
/// Solid ink hair and shoes; `hair` 0 short, 1 with a bun; `talk` opens the mouth. Arms are drawn separately, after the table.
func bpPerson(_ c: inout GraphicsContext, base b: CGPoint, facing f: Double, ink: Color, shirt: Double, hair: Int, talk: Bool) {
    let hw = f == 0 ? 12.5 : 9.0, hx = b.x + f * 1.5, hy = b.y - 39.5, r = 8.8
    for s in [-1.0, 1.0] {
        let lx = f == 0 ? b.x + s * 5.5 : b.x + f * (s > 0 ? 6.0 : 1.5)
        var leg = Path(); leg.move(to: BP.pt(lx, b.y - 2)); leg.addLine(to: BP.pt(lx, b.y + 19))
        c.stroke(leg, with: .color(ink), style: StrokeStyle(lineWidth: 6.2, lineCap: .round))
        c.stroke(leg, with: .color(BP.paper), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        c.fill(Path(ellipseIn: CGRect(x: lx - 4.5 + f * 2, y: b.y + 18.5, width: 9, height: 4.4)), with: .color(ink))
    }
    var t = Path()
    t.move(to: BP.pt(b.x - hw + 4, b.y - 28)); t.addLine(to: BP.pt(b.x + hw - 4, b.y - 28))
    t.addQuadCurve(to: BP.pt(b.x + hw, b.y - 23), control: BP.pt(b.x + hw, b.y - 28))
    t.addLine(to: BP.pt(b.x + hw - 3, b.y - 1)); t.addLine(to: BP.pt(b.x - hw + 3, b.y - 1)); t.addLine(to: BP.pt(b.x - hw, b.y - 23))
    t.addQuadCurve(to: BP.pt(b.x - hw + 4, b.y - 28), control: BP.pt(b.x - hw, b.y - 28))
    c.fill(t, with: .color(BP.paper)); c.fill(t, with: .color(ink.opacity(shirt)))
    c.stroke(t, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
    var neck = Path(); neck.move(to: BP.pt(hx - 3, hy + r - 1)); neck.addLine(to: BP.pt(hx - 3, b.y - 28)); neck.move(to: BP.pt(hx + 3, hy + r - 1)); neck.addLine(to: BP.pt(hx + 3, b.y - 28))
    c.stroke(neck, with: .color(ink), lineWidth: BP.hair)
    let head = Path(ellipseIn: CGRect(x: hx - r, y: hy - r, width: 2 * r, height: 2 * r))
    c.fill(head, with: .color(BP.paper)); c.stroke(head, with: .color(ink), lineWidth: BP.edge)
    // hair: a solid cap, longer down the back of the head when seen in profile
    var h = Path(); let R = r + 0.9
    for i in 0...16 { let a = Double.pi + Double.pi * Double(i) / 16; let q = BP.pt(hx + R * cos(a), hy + R * sin(a)); if i == 0 { h.move(to: q) } else { h.addLine(to: q) } }
    h.addQuadCurve(to: BP.pt(hx - R, hy), control: BP.pt(hx + f * 2, hy + R * 0.12))
    c.fill(h, with: .color(ink))
    if f != 0 { c.fill(Path(ellipseIn: CGRect(x: hx - f * R * 0.62 - R * 0.45, y: hy - R * 0.6, width: R * 0.9, height: R * 1.5)), with: .color(ink)) }
    if hair == 1 { c.fill(Path(ellipseIn: CGRect(x: hx - f * R * 0.5 - 3.6, y: hy - R - 5.5, width: 7.2, height: 7.2)), with: .color(ink)) }
    // face
    if f == 0 {
        for s in [-1.0, 1.0] { c.fill(Path(ellipseIn: CGRect(x: hx + s * 3.3 - 1.1, y: hy - 0.2, width: 2.2, height: 2.4)), with: .color(ink)) }
    } else {
        c.fill(Path(ellipseIn: CGRect(x: hx + f * 3.6 - 1.1, y: hy - 0.2, width: 2.2, height: 2.4)), with: .color(ink))
        var nose = Path(); nose.move(to: BP.pt(hx + f * r, hy + 0.5)); nose.addLine(to: BP.pt(hx + f * (r + 2.3), hy + 2.6)); nose.addLine(to: BP.pt(hx + f * r, hy + 3))
        c.stroke(nose, with: .color(ink), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
    }
    let mx = hx + f * 2.2
    if talk { c.fill(Path(ellipseIn: CGRect(x: mx - 1.7, y: hy + 3.6, width: 3.4, height: 3.2)), with: .color(ink)) }
    else { var m = Path(); m.move(to: BP.pt(mx - 2.4, hy + 4.6)); m.addQuadCurve(to: BP.pt(mx + 2.4, hy + 4.6), control: BP.pt(mx, hy + 6.6)); c.stroke(m, with: .color(ink), style: StrokeStyle(lineWidth: 1.2, lineCap: .round)) }
}

/// A code written as note, gap, note: two dots (their heights are the pitches `a` and `b`, as fractions of `width`) and the gap between them.
func bpCode(_ c: inout GraphicsContext, _ at: CGPoint, width w: Double, a: Double, b: Double, r: Double, color: Color, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    let p1 = BP.pt(at.x - w / 2, at.y + a * w), p2 = BP.pt(at.x + w / 2, at.y + b * w)
    var gap = Path()
    gap.move(to: BP.pt(p1.x + r + 2, at.y)); gap.addLine(to: BP.pt(p2.x - r - 2, at.y))
    for x in [p1.x + r + 2, p2.x - r - 2] { gap.move(to: BP.pt(x, at.y - r)); gap.addLine(to: BP.pt(x, at.y + r)) }
    c.stroke(gap, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: max(1, r * 0.5), lineCap: .round))
    for p in [p1, p2] { c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(alpha))) }
}
