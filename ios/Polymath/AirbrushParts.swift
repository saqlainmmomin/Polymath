import SwiftUI

// Airbrush parts for scene topics (2026-11-04). A thin hand line whose colour sits a little off the outline, sprayed clouds, soft glows,
// round simple figures. Standing parts have their feet or bottom centre at the origin; the rest are centred on it unless they say so.
// `on` draws the lines (and sprays the clouds in), `fill` fades the colour in.

enum ABParts {
    static let names = ["ground", "sun", "skinCut", "nerve", "brain", "finger", "tub", "molecule", "scatter", "eye", "earthLimb", "drop",
                        "spray", "glow", "person"]

    private static func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
    private static let off = CGSize(width: -3, height: -2.5)

    /// Paints `pts` in `fill` (faded in by the part's `fill`), then inks its outline a little off the colour.
    private static func piece(_ c: inout GraphicsContext, _ q: ScenePart, _ pts: [CGPoint], k: Int, fill: GraphicsContext.Shading?, closed: Bool = true,
                              offset: CGSize = off, width: Double? = nil, color: Color = AB.ink, amp: Double = 0.6) {
        if let fill { AB.paint(&c, pts, closed: closed, clock: q.clock, seed: q.seed &+ k &* 13, p: q.fill, with: fill, amp: amp) }
        AB.stroke(&c, pts, closed: closed, clock: q.clock, seed: q.seed &+ k &* 13, p: q.on, width: width ?? 1.9, color: color, offset: offset, amp: amp)
    }

    static func draw(_ name: String, _ c: inout GraphicsContext, _ q: ScenePart) {
        switch name {
        case "ground":       // `w` wide, centred on the origin: a sprayed salmon wash under a wobbly line, with a few tufts
            let w = q["w", default: 280]
            AB.spray(&c, at: P(0, 17), rx: w * 0.42, ry: 13, color: AB.salmon, alpha: 0.85, grow: BP.eout(q.on), seed: q.seed &+ 3)
            AB.stroke(&c, [P(-w / 2, 0), P(-w / 4, -1.5), P(0, 0.8), P(w / 4, -1.2), P(w / 2, 0)], clock: q.clock, seed: q.seed, p: q.on, width: 2.2)
            var x = -w / 2 + 18
            var i = 0
            while x < w / 2 - 10 {
                AB.stroke(&c, [P(x, 0), P(x + 2, -6), P(x + 4.5, 0)], clock: q.clock, seed: q.seed &+ 20 &+ i, p: q.on, width: 1.3, amp: 0.2)
                x += 34 + Sketch.rnd(q.seed &+ i) * 26; i += 1
            }
        case "sun":          // centred; r the disc's radius; rays 0...1 draws the strokes round it
            let r = q["r", default: 26], k = BP.eout(q.on)
            AB.glow(&c, at: .zero, r: r * 2.3 * k, inner: AB.yellow, outer: AB.orange, alpha: 0.95)
            let disc = Sketch.oval(.zero, r, r, n: 24)
            piece(&c, q, disc, k: 1, fill: .color(AB.yellow), offset: CGSize(width: 2.5, height: -2.5))
            let rays = q["rays", default: 1]
            if rays > 0.01 {
                for i in 0..<12 {
                    let a = Double(i) / 12 * 2 * .pi, r0 = r * 1.35, r1 = r * (i % 2 == 0 ? 1.85 : 1.6)
                    AB.stroke(&c, [P(r0 * cos(a), r0 * sin(a)), P(r1 * cos(a), r1 * sin(a))], clock: q.clock, seed: q.seed &+ 30 &+ i, p: rays * q.on, width: 1.8, amp: 0.3)
                }
            }
        case "skinCut": skinCut(&c, q)
        case "nerve": nerve(&c, q)
        case "brain": brain(&c, q)
        case "finger": finger(&c, q)
        case "tub": tub(&c, q)
        case "molecule":     // centred; r the size of each atom; glow 0...1 a yellow flash behind it
            let r = q["r", default: 8]
            let glow = q["glow", default: 0]
            if glow > 0.01 { AB.glow(&c, at: .zero, r: r * 3.4, inner: AB.yellow, outer: AB.lime, alpha: glow) }
            for (i, (dx, col)) in [(-r * 0.62, AB.salmon), (r * 0.62, AB.blue)].enumerated() {
                let pts = Sketch.oval(P(dx, 0), r, r, n: 18)
                piece(&c, q, pts, k: i, fill: .color(col), offset: CGSize(width: 1.8, height: -1.6), width: 1.6, amp: 0.35)
                AB.stroke(&c, [P(dx - r * 0.5, -r * 0.35), P(dx - r * 0.2, -r * 0.62)], clock: q.clock, seed: q.seed &+ 9 &+ i, p: q.on, width: 1.2, color: .white, amp: 0.1)
            }
        case "scatter":      // `n` straight strokes spreading from the origin: `len` long (grows with `grow`), starting at `r0`, turned `rot` degrees; `col` colour
            let n = Int(q["n", default: 8]), len = q["len", default: 24], r0 = q["r0", default: 10], rot = q["rot", default: 0] * .pi / 180
            let grow = BP.eout(q["grow", default: 1]) * BP.cl(q.on * 2)
            let col = q.look.palette(q["col", default: 2])
            for i in 0..<n {
                let a = rot + Double(i) / Double(n) * 2 * .pi
                AB.stroke(&c, [P(r0 * cos(a), r0 * sin(a)), P((r0 + len * grow) * cos(a), (r0 + len * grow) * sin(a))], clock: q.clock, seed: q.seed &+ i, p: 1,
                          width: 2.3, color: col, amp: 0.3)
            }
        case "eye": eye(&c, q)
        case "earthLimb": earthLimb(&c, q)
        case "drop":         // a water drop, centred (its widest part); s size
            let s = q["s", default: 8]
            let d = Double.pi / 180, t0 = -38.7 * d, t1 = 218.7 * d
            var pts = [P(0, -1.6 * s)]
            for i in 0...14 { let a = t0 + (t1 - t0) * Double(i) / 14; pts.append(P(s * cos(a), s * sin(a))) }
            piece(&c, q, pts, k: 0, fill: AB.vgrad(AB.blue.opacity(0.7), AB.blue, y0: -1.6 * s, y1: s), offset: CGSize(width: 1.5, height: -1.2), width: 1.5, amp: 0.25)
            AB.stroke(&c, [P(-s * 0.5, s * 0.1), P(-s * 0.4, s * 0.55)], clock: q.clock, seed: q.seed &+ 5, p: q.on, width: 1.2, color: .white, amp: 0.1)
        case "spray":        // a sprayed cloud, centred: rx, ry, col (palette number), alpha, grow (0...1, sprays in on its word by default)
            AB.spray(&c, at: .zero, rx: q["rx", default: 40], ry: q["ry", default: 20], color: q.look.palette(q["col", default: 2]), alpha: q["alpha", default: 1],
                     grow: q["grow", default: BP.eout(q.on)], seed: q.seed)
        case "glow":         // a soft disc, centred: r, col (inside) and col2 (outer, default col), alpha
            let a = q.look.palette(q["col", default: 6]), b = q.look.palette(q["col2", default: q["col", default: 6]])
            AB.glow(&c, at: .zero, r: q["r", default: 30] * BP.eout(q.on), inner: a, outer: b, alpha: q["alpha", default: 1])
        case "person":       // the round figure, feet at the origin; blink 1 closes the eyes
            AB.person(&c, feet: .zero, clock: q.clock, seed: q.seed, p: q.on, blink: q["blink", default: 0] > 0.5)
        default: break
        }
    }

    // MARK: skin

    /// A cut through skin, top centre at the origin, `w` wide (260) and `d` deep (100): a skin-coloured outer layer on an orange to salmon
    /// deeper layer, with a hair, a few round cells and a wobbly surface.
    private static func skinCut(_ c: inout GraphicsContext, _ q: ScenePart) {
        let w = q["w", default: 260], d = q["d", default: 100], x0 = -w / 2, x1 = w / 2
        func top(_ x: Double) -> Double { 2.2 * sin(x * 0.06) + 1.2 * sin(x * 0.17 + 1) }
        var surface: [CGPoint] = []
        for i in 0...26 { let x = x0 + w * Double(i) / 26; surface.append(P(x, top(x))) }
        // deeper layer
        let body = surface + [P(x1, d), P(x1 * 0.5, d + 3), P(0, d - 2), P(x0 * 0.5, d + 2), P(x0, d)]
        piece(&c, q, body, k: 0, fill: AB.vgrad(AB.salmon, AB.orange, y0: 0, y1: d), offset: CGSize(width: -2, height: -2))
        // outer layer, a band along the surface
        let band = surface + surface.reversed().map { P($0.x, $0.y + 11) }
        AB.paint(&c, band, clock: q.clock, seed: q.seed &+ 13, p: q.fill, with: .color(AB.skin))
        AB.stroke(&c, surface.reversed().map { P($0.x, $0.y + 11) }, clock: q.clock, seed: q.seed &+ 14, p: q.on, width: 1.1, color: AB.ink.opacity(0.55))
        AB.stroke(&c, surface, clock: q.clock, seed: q.seed &+ 15, p: q.on, width: 2.4)
        // round cells in the deeper layer
        var cells = Path()
        for (fx, fy, rx) in [(0.12, 0.36, 9.0), (0.26, 0.62, 11), (0.4, 0.4, 8), (0.55, 0.7, 10), (0.7, 0.38, 9), (0.84, 0.6, 11), (0.92, 0.34, 7), (0.07, 0.72, 8)] {
            cells.addEllipse(in: CGRect(x: x0 + w * fx - rx, y: d * fy - rx * 0.65, width: 2 * rx, height: 1.3 * rx))
        }
        var cg = c; cg.opacity *= q.on
        cg.stroke(cells, with: .color(AB.ink.opacity(0.22)), lineWidth: 1)
        // a hair, with its root (hair 0 leaves it out)
        guard q["hair", default: 1] > 0.5 else { return }
        let hx = q["hairAt", default: -w * 0.33]
        AB.stroke(&c, [P(hx, top(hx) + 20), P(hx + 1, top(hx) + 4), P(hx + 4, top(hx) - 12), P(hx + 10, top(hx) - 24)], clock: q.clock, seed: q.seed &+ 16, p: q.on, width: 1.6, amp: 0.3)
        var root = Path(ellipseIn: CGRect(x: hx - 5, y: top(hx) + 20, width: 10, height: 13))
        root.closeSubpath()
        c.fill(root, with: .color(AB.skin.opacity(q.fill))); var rg = c; rg.opacity *= q.on; rg.stroke(root, with: .color(AB.ink), lineWidth: 1.3)
    }

    /// One nerve ending, centred on its bulb at the origin, its stalk running down `len` (default 44). kind 0 cold (blue), 1 warm (orange), 2 touch (lime).
    /// `lit` 0...1 glows yellow; `sig` 0...1 sends a yellow bead down the stalk.
    private static func nerve(_ c: inout GraphicsContext, _ q: ScenePart) {
        let len = q["len", default: 44], kind = Int(q["kind", default: 0])
        let col = [AB.blue, AB.orange, AB.lime][max(0, min(2, kind))]
        let lit = q["lit", default: 0], sig = q["sig", default: 0]
        if lit > 0.01 { AB.glow(&c, at: .zero, r: 26, inner: AB.yellow, outer: AB.lime, alpha: lit) }
        let stalk = [P(0, 8), P(2.5, len * 0.3), P(-2, len * 0.62), P(0, len)]
        AB.stroke(&c, stalk, clock: q.clock, seed: q.seed, p: q.on, width: 1.8, amp: 0.4)
        if kind == 2 {      // touch: a flat disc in a cup
            let disc = Sketch.oval(.zero, 10, 5.5, n: 16)
            piece(&c, q, disc, k: 1, fill: .color(col), offset: CGSize(width: 1.5, height: -1.5), width: 1.6, amp: 0.3)
        } else {
            let bulb = Sketch.oval(.zero, 6.5, 9, n: 16)
            piece(&c, q, bulb, k: 1, fill: .color(col), offset: CGSize(width: 1.5, height: -1.5), width: 1.6, amp: 0.3)
        }
        if sig > 0.01 && sig < 0.999 {
            let y = 8 + (len - 8) * sig
            AB.glow(&c, at: P(0, y), r: 9, inner: AB.yellow, outer: AB.yellow, alpha: 1)
            c.fill(Path(ellipseIn: CGRect(x: -3.2, y: y - 3.2, width: 6.4, height: 6.4)), with: .color(AB.yellow))
            c.stroke(Path(ellipseIn: CGRect(x: -3.2, y: y - 3.2, width: 6.4, height: 6.4)), with: .color(AB.ink), lineWidth: 1.2)
        }
    }

    // MARK: brain

    /// A round, friendly brain, centred, about 100 wide and 70 tall at s 1. `lit` 0...1 glows yellow behind it and turns it warm.
    private static func brain(_ c: inout GraphicsContext, _ q: ScenePart) {
        let s = q["s", default: 1], lit = q["lit", default: 0]
        var g = c; g.scaleBy(x: s, y: s)
        if lit > 0.01 { AB.glow(&g, at: .zero, r: 78, inner: AB.yellow, outer: AB.lime, alpha: lit) }
        var pts: [CGPoint] = []
        for i in 0..<30 {
            let t = Double(i) / 30 * 2 * .pi
            let bump = 1 + 0.07 * sin(6 * t + 0.5) + 0.03 * sin(11 * t)
            pts.append(P(50 * cos(t) * bump, 34 * sin(t) * bump * (sin(t) > 0 ? 0.95 : 1.0) + (sin(t) > 0 ? 0 : -2)))
        }
        var qq = q
        piece(&g, qq, pts, k: 0, fill: AB.vgrad(AB.skin, AB.salmon, y0: -34, y1: 34), offset: CGSize(width: -3, height: -2.5), amp: 0.5)
        qq = q
        // folds
        AB.stroke(&g, [P(-2, -33), P(3, -20), P(-3, -8), P(2, 6), P(-1, 18)], clock: q.clock, seed: q.seed &+ 21, p: q.on, width: 1.5, amp: 0.4)
        AB.stroke(&g, [P(-38, -10), P(-30, -18), P(-20, -12), P(-14, -20)], clock: q.clock, seed: q.seed &+ 22, p: q.on, width: 1.3, amp: 0.3)
        AB.stroke(&g, [P(-34, 8), P(-26, 2), P(-18, 10), P(-10, 4)], clock: q.clock, seed: q.seed &+ 23, p: q.on, width: 1.3, amp: 0.3)
        AB.stroke(&g, [P(14, -16), P(22, -22), P(30, -14), P(38, -20)], clock: q.clock, seed: q.seed &+ 24, p: q.on, width: 1.3, amp: 0.3)
        AB.stroke(&g, [P(12, 8), P(20, 2), P(28, 10), P(38, 4)], clock: q.clock, seed: q.seed &+ 25, p: q.on, width: 1.3, amp: 0.3)
        AB.stroke(&g, [P(-8, 30), P(-9, 40), P(-2, 44)], clock: q.clock, seed: q.seed &+ 26, p: q.on, width: 1.5, amp: 0.2)
    }

    // MARK: finger

    /// A finger pointing down, its base at the origin: `len` long (96), `wd` wide (26). `sheath` 0...1 draws a thin blue rubber sheath over it with a rolled cuff.
    private static func finger(_ c: inout GraphicsContext, _ q: ScenePart) {
        let len = q["len", default: 96], wd = q["wd", default: 26], sheath = q["sheath", default: 0]
        let outline = Sketch.digit(P(0, 0), len: len, wd: wd, angle: 180)
        let body = outline + [P(wd / 2, 0), P(-wd / 2, 0)]
        piece(&c, q, body, k: 0, fill: AB.vgrad(AB.skin, AB.salmon, y0: 0, y1: len), offset: CGSize(width: -2.2, height: 0))
        // nail and two creases
        let nail = [P(-wd * 0.28, len - 15), P(-wd * 0.3, len - 6), P(-wd * 0.14, len - 3), P(wd * 0.04, len - 7), P(wd * 0.04, len - 15)]
        var ng = c; ng.opacity *= q.fill
        ng.fill(Sketch.path(nail, closed: true, t: q.clock, seed: q.seed &+ 9, amp: 0.3), with: .color(.white.opacity(0.55)))
        AB.stroke(&c, nail, closed: true, clock: q.clock, seed: q.seed &+ 9, p: q.on, width: 1.1, amp: 0.3)
        AB.stroke(&c, [P(-wd * 0.3, len * 0.42), P(wd * 0.25, len * 0.42 + 1)], clock: q.clock, seed: q.seed &+ 10, p: q.on, width: 1, color: AB.ink.opacity(0.6), amp: 0.2)
        AB.stroke(&c, [P(-wd * 0.28, len * 0.26), P(wd * 0.22, len * 0.26 + 1)], clock: q.clock, seed: q.seed &+ 11, p: q.on, width: 1, color: AB.ink.opacity(0.6), amp: 0.2)
        if sheath > 0.01 {
            var sg = c; sg.opacity *= sheath
            let sl = Sketch.digit(P(0, 4), len: len + 7, wd: wd + 9, angle: 180)
            let sb = sl + [P((wd + 9) / 2, 4), P(-(wd + 9) / 2, 4)]
            AB.paint(&sg, sb, clock: q.clock, seed: q.seed &+ 30, p: 1, with: .color(AB.blue.opacity(0.28)), amp: 0.4)
            AB.stroke(&sg, sl, closed: false, clock: q.clock, seed: q.seed &+ 30, p: 1, width: 2.1, color: AB.blue, amp: 0.4)
            // the rolled cuff at the base
            AB.stroke(&sg, Sketch.oval(P(0, 3), (wd + 14) / 2, 4.5, n: 14), closed: true, clock: q.clock, seed: q.seed &+ 31, p: 1, width: 2.2, color: AB.blue, amp: 0.3)
        }
    }

    // MARK: tub of water

    /// A glass tub, bottom centre at the origin: `w` wide (130), `h` tall (96), water to `level` 0...1 (0.78). The water is blue with a wavy top and a few bubbles.
    private static func tub(_ c: inout GraphicsContext, _ q: ScenePart) {
        let w = q["w", default: 130], h = q["h", default: 96], level = q["level", default: 0.78]
        let glass = [P(-w / 2, -h), P(-w / 2 + 7, -6), P(-w / 2 + 14, 0), P(w / 2 - 14, 0), P(w / 2 - 7, -6), P(w / 2, -h)]
        let ty = -h * level
        let water = [P(-w / 2 + (w / 2 - (w / 2 - 7)) * (1 - level) * 0.4 + (-h - ty) * 0.0, ty), P(-w / 2 + 3 + 4 * level, ty + 1), P(-w / 2 + 7, -6), P(-w / 2 + 14, 0),
                     P(w / 2 - 14, 0), P(w / 2 - 7, -6), P(w / 2 - 3 - 4 * level, ty + 1), P(w / 2 - 1 - (1 - level) * 4, ty)]
        AB.paint(&c, water, clock: q.clock, seed: q.seed &+ 40, p: q.fill, with: AB.vgrad(AB.blue.opacity(0.62), AB.blue, y0: ty, y1: 0), amp: 0.4)
        // wavy surface and bubbles
        var top: [CGPoint] = []
        for i in 0...10 { let x = -w / 2 + 6 + (w - 12) * Double(i) / 10; top.append(P(x, ty + 1.6 * sin(Double(i) * 1.3 + q.clock * 2))) }
        AB.stroke(&c, top, clock: q.clock, seed: q.seed &+ 41, p: q.on, width: 1.4, color: AB.ink.opacity(0.7), amp: 0.2)
        var bub = Path()
        for (fx, fy, r) in [(0.22, 0.45, 2.6), (0.7, 0.6, 2.0), (0.4, 0.8, 1.6), (0.82, 0.32, 1.8)] {
            bub.addEllipse(in: CGRect(x: -w / 2 + w * fx - r, y: ty * (1 - fy) - r, width: 2 * r, height: 2 * r))
        }
        var bg = c; bg.opacity *= q.on; bg.stroke(bub, with: .color(.white.opacity(0.85)), lineWidth: 1)
        AB.stroke(&c, glass, closed: false, clock: q.clock, seed: q.seed &+ 42, p: q.on, width: 2, offset: CGSize(width: -2.5, height: -1))
        AB.stroke(&c, [P(-w / 2 - 5, -h), P(w / 2 + 5, -h)], clock: q.clock, seed: q.seed &+ 43, p: q.on, width: 2, amp: 0.3)
    }

    // MARK: eye

    /// An eye, centred: an almond, `s` scale (1 is about 56 wide), `look` -1...1 turns the iris left or right, `lid` 0...1 closes it a little.
    private static func eye(_ c: inout GraphicsContext, _ q: ScenePart) {
        let s = q["s", default: 1], look = q["look", default: 0]
        var g = c; g.scaleBy(x: s, y: s)
        let lid = 1 - 0.5 * q["lid", default: 0]
        var almond: [CGPoint] = []
        for i in 0...10 { let t = Double(i) / 10; let x = -28 + 56 * t; almond.append(P(x, -15 * lid * sin(t * .pi))) }
        for i in 1..<10 { let t = 1 - Double(i) / 10; let x = -28 + 56 * t; almond.append(P(x, 13 * sin(t * .pi))) }
        var qq = q
        qq = q
        AB.paint(&g, almond, clock: q.clock, seed: q.seed, p: q.fill, with: .color(.white.opacity(0.92)), amp: 0.4)
        var clipped = g
        clipped.clip(to: Sketch.path(almond, closed: true, t: q.clock, seed: q.seed, amp: 0.4))
        let ix = look * 8
        AB.paint(&clipped, Sketch.oval(P(ix, 0), 12.5, 12.5, n: 20), clock: q.clock, seed: q.seed &+ 1, p: q.fill, with: .color(AB.lime), amp: 0.3)
        AB.stroke(&clipped, Sketch.oval(P(ix, 0), 12.5, 12.5, n: 20), closed: true, clock: q.clock, seed: q.seed &+ 1, p: q.on, width: 1.5, amp: 0.3)
        var pupil = Path(ellipseIn: CGRect(x: ix - 5.2, y: -5.2, width: 10.4, height: 10.4))
        pupil.closeSubpath()
        clipped.fill(pupil, with: .color(AB.ink.opacity(q.on)))
        clipped.fill(Path(ellipseIn: CGRect(x: ix - 4, y: -6, width: 4, height: 4)), with: .color(.white.opacity(q.on)))
        AB.stroke(&g, almond, closed: true, clock: q.clock, seed: q.seed, p: q.on, width: 1.9, offset: CGSize(width: -2, height: -2), amp: 0.4)
        for (x, a) in [(-14.0, -1.0), (0.0, 0.0), (14.0, 1.0)] {
            AB.stroke(&g, [P(x, -15 * lid * sin((x + 28) / 56 * .pi)), P(x + a * 4, -15 * lid * sin((x + 28) / 56 * .pi) - 8)], clock: q.clock, seed: q.seed &+ 5, p: q.on, width: 1.5, amp: 0.2)
        }
    }

    // MARK: the planet's edge

    /// The top of a planet, its centre at the origin: `R` radius (320), drawn from `a0` to `a1` degrees (0 is right, clockwise, so about 215 to 325 is the top).
    /// Warm land under a band of blue air `th` thick (24), grainy where it thins out.
    private static func earthLimb(_ c: inout GraphicsContext, _ q: ScenePart) {
        let R = q["R", default: 320], th = q["th", default: 24], a0 = q["a0", default: 215], a1 = q["a1", default: 325]
        let d = Double.pi / 180, n = 36
        func arc(_ r: Double) -> [CGPoint] { (0...n).map { i in let a = (a0 + (a1 - a0) * Double(i) / Double(n)) * d; return P(r * cos(a), r * sin(a)) } }
        // air: a band of blue with a grainy outer edge
        let air = arc(R + th) + arc(R).reversed()
        var ag = c; ag.opacity *= q["air", default: 1]
        AB.paint(&ag, air, clock: q.clock, seed: q.seed &+ 50, p: q.fill, with: .color(AB.blue.opacity(0.3)), amp: 0.3)
        var grain = Path()
        for i in 0..<Int((a1 - a0) * 4) {
            let a = (a0 + (a1 - a0) * Sketch.rnd(q.seed &+ i * 3)) * d, r = R + th * (0.25 + 1.0 * Sketch.rnd(q.seed &+ i * 3 + 1)), rr = 0.5 + 0.8 * Sketch.rnd(q.seed &+ i * 3 + 2)
            grain.addEllipse(in: CGRect(x: r * cos(a) - rr, y: r * sin(a) - rr, width: 2 * rr, height: 2 * rr))
        }
        var gg = ag; gg.opacity *= q.fill; gg.fill(grain, with: .color(AB.blue))
        // land
        let land = arc(R) + [P(0, 0)]
        AB.paint(&c, land, clock: q.clock, seed: q.seed &+ 51, p: q.fill, with: AB.vgrad(AB.skin, AB.salmon, y0: -R, y1: -R + 120), amp: 0.4)
        AB.stroke(&c, arc(R), closed: false, clock: q.clock, seed: q.seed &+ 52, p: q.on, width: 2.2, offset: CGSize(width: 0, height: -3), amp: 0.5)
    }
}
