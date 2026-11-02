import SwiftUI

// "Why is the sky blue at noon and red at sunset?" pictures, drawn as blueprint technical illustrations (2026-10-31).
// Chalk linework with a tilted disc of air (or a tilted slice of atmosphere) for depth, DASHED routes for light that march along themselves,
// and small filled round pins on thin stems as markers. Colour only on pins and on the light travelling along routes: mustard (the Sun,
// the focal point), sky blue (blue light), coral (red and orange light), teal (air, the molecule, scatter arrows), lime (the eye).
// Labels are mono uppercase and use only the slide's own words. Every picture loops: it plays on the stage's free clock, holds about a
// second and fades its moving parts. Reduce Motion shows the held end state. Drawn in a 343 x 340 design space; keep clear of the
// bottom-right corner (x > 285, y > 255).

private let skSize = CGSize(width: 343, height: 340)
private let skMustard = Color(hex: 0xF2C14E)
private let skSky = Color(hex: 0x7FB8E6)
private let skCoral = Color(hex: 0xF2674B)
private let skTeal = Color(hex: 0x6FC9C0)
private let skLime = Color(hex: 0xC8E26B)

// MARK: - Shared helpers

/// Loop time plus whether the picture is held (Reduce Motion: the stage clock stands still behind `t`, so show the end state).
private func skCycle(_ t: Double, _ clock: Double, story: Double, extra: Double = 1.5) -> (Double, Bool) {
    if clock < t { return (story, true) }
    return (clock.truncatingRemainder(dividingBy: story + extra), false)
}

/// 1 while the picture plays and holds, then fades to 0 over the last half second of the loop.
private func skFade(_ u: Double, _ story: Double) -> Double { 1 - BP.pr(u, story + 1.0, story + 1.5) }

private func skOval(_ ctr: CGPoint, _ rx: Double, _ ry: Double) -> Path {
    Path(ellipseIn: CGRect(x: ctr.x - rx, y: ctr.y - ry, width: 2 * rx, height: 2 * ry))
}

private func skHead(_ p: inout Path, _ a: CGPoint, _ b: CGPoint, _ size: Double = 6) {
    let len = hypot(b.x - a.x, b.y - a.y)
    guard len > 0.1 else { return }
    let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    p.move(to: BP.pt(b.x - ux * size - uy * size * 0.56, b.y - uy * size + ux * size * 0.56)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * size + uy * size * 0.56, b.y - uy * size - ux * size * 0.56))
}

/// The point `d` short of `b`, on the way from `a`.
private func skShort(_ a: CGPoint, _ b: CGPoint, _ d: Double) -> CGPoint {
    let len = max(1, hypot(b.x - a.x, b.y - a.y))
    return BP.pt(b.x - (b.x - a.x) / len * d, b.y - (b.y - a.y) / len * d)
}

/// A dashed route from `a` to `b`, drawn on by `p`; `phase` makes the dashes march along it.
private func skRoute(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, p: Double, color: Color, width: Double = 1.3, phase: Double = 0, alpha: Double = 1) {
    guard p > 0.001, alpha > 0.01 else { return }
    var path = Path(); path.move(to: a); path.addLine(to: b)
    c.stroke(path.trimmedPath(from: 0, to: BP.cl(p)), with: .color(color.opacity(alpha)),
             style: StrokeStyle(lineWidth: width, lineCap: .round, dash: [5, 5], dashPhase: -phase))
}

/// A dashed arrow that streams from `a` to `b`: `m` 0...1 is how far through its journey it is. Held shows it whole.
private func skStream(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, m: Double, held: Bool, color: Color, width: Double = 1.3, alpha: Double = 1) {
    let s1 = held ? 1.0 : BP.cl(m * 1.5), s0 = held ? 0.0 : BP.cl(m * 1.5 - 0.5)
    let al = (held ? 0.9 : 1 - BP.pr(m, 0.8, 1.0)) * alpha
    guard s1 - s0 > 0.01, al > 0.01 else { return }
    var path = Path(); path.move(to: BP.mixp(a, b, s0)); path.addLine(to: BP.mixp(a, b, s1))
    if s1 > 0.999 { skHead(&path, a, b, 5.5) }
    c.stroke(path, with: .color(color.opacity(al)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: s1 > 0.999 ? [] : [4, 3]))
}

private enum SkGlyph { case sun, horizon, eye, atom, dot }

private func skGlyph(_ c: inout GraphicsContext, _ g: SkGlyph, _ at: CGPoint, _ r: Double) {
    let col = BP.paper
    switch g {
    case .sun:
        c.stroke(skOval(at, r * 0.3, r * 0.3), with: .color(col), lineWidth: 1.1)
        var rays = Path()
        for i in 0..<8 {
            let a = Double(i) * Double.pi / 4
            rays.move(to: BP.pt(at.x + cos(a) * r * 0.5, at.y + sin(a) * r * 0.5)); rays.addLine(to: BP.pt(at.x + cos(a) * r * 0.72, at.y + sin(a) * r * 0.72))
        }
        c.stroke(rays, with: .color(col), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
    case .horizon:
        var p = Path()
        let cy = at.y + r * 0.22
        for i in 0...12 {
            let a = Double.pi + Double.pi * Double(i) / 12
            let q = BP.pt(at.x + cos(a) * r * 0.42, cy + sin(a) * r * 0.42)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.move(to: BP.pt(at.x - r * 0.64, cy)); p.addLine(to: BP.pt(at.x + r * 0.64, cy))
        c.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
    case .eye:
        var p = Path()
        p.move(to: BP.pt(at.x - r * 0.64, at.y)); p.addQuadCurve(to: BP.pt(at.x + r * 0.64, at.y), control: BP.pt(at.x, at.y - r * 0.8))
        p.addQuadCurve(to: BP.pt(at.x - r * 0.64, at.y), control: BP.pt(at.x, at.y + r * 0.8))
        c.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: 1.1, lineJoin: .round))
        c.fill(skOval(at, r * 0.2, r * 0.2), with: .color(col))
    case .atom:
        c.fill(skOval(at, r * 0.18, r * 0.18), with: .color(col))
        for ang in [0.6, -0.6] {
            let e = skOval(at, r * 0.66, r * 0.26).applying(CGAffineTransform(translationX: -at.x, y: -at.y)
                .concatenating(CGAffineTransform(rotationAngle: ang)).concatenating(CGAffineTransform(translationX: at.x, y: at.y)))
            c.stroke(e, with: .color(col), lineWidth: 1.0)
        }
    case .dot:
        c.stroke(skOval(at, r * 0.34, r * 0.34), with: .color(col), lineWidth: 1.0)
    }
}

/// A small filled round pin on a thin stem: the head (radius `r`) carries a tiny icon, the stem ends in a base dot.
private func skPin(_ c: inout GraphicsContext, base: CGPoint, head: CGPoint, r: Double, color: Color, glyph: SkGlyph, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    bpGroup(&c, alpha: alpha) { g in
        var stem = Path(); stem.move(to: base); stem.addLine(to: BP.pt(head.x, head.y + r))
        g.stroke(stem, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        g.fill(skOval(base, 3.0, 1.6), with: .color(color.opacity(0.9)))
        g.fill(skOval(head, r, r), with: .color(color))
        skGlyph(&g, glyph, head, r)
    }
}

/// A tilted disc of air: a thick elliptical slab with chalk contour rings and a dashed centre ring.
private func skDisc(_ c: inout GraphicsContext, _ ctr: CGPoint, _ rx: Double, _ ry: Double, th: Double = 8, ink: Color, alpha: Double) {
    bpGroup(&c, alpha: alpha) { g in
        var side = Path(); side.move(to: BP.pt(ctr.x - rx, ctr.y))
        for i in 0...40 {
            let a = Double.pi - Double.pi * Double(i) / 40
            side.addLine(to: BP.pt(ctr.x + rx * cos(a), ctr.y + th + ry * sin(a)))
        }
        side.addLine(to: BP.pt(ctr.x + rx, ctr.y)); side.closeSubpath()
        g.fill(side, with: .color(BP.paper)); g.fill(side, with: .color(ink.opacity(0.1)))
        g.stroke(side, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        let top = skOval(ctr, rx, ry)
        g.fill(top, with: .color(BP.paper)); g.fill(top, with: .color(ink.opacity(0.07)))
        g.stroke(top, with: .color(ink), lineWidth: BP.edge)
        for k in [0.7, 0.4] { g.stroke(skOval(ctr, rx * k, ry * k), with: .color(ink.opacity(0.3)), lineWidth: 0.8) }
        g.stroke(skOval(ctr, rx * 0.55, ry * 0.55), with: .color(ink.opacity(0.3)), style: StrokeStyle(lineWidth: 0.8, dash: [2, 3]))
    }
}

/// A short sine wave along a to b: `lambda` is the wavelength, `phase` slides the crests toward b, `p` reveals it from a.
private func skWave(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, lambda: Double, amp: Double, phase: Double, p: Double, color: Color, alpha: Double) {
    guard p > 0.01, alpha > 0.01 else { return }
    let len = hypot(b.x - a.x, b.y - a.y), ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    var path = Path()
    let n = 90
    for i in 0...n {
        let s = Double(i) / Double(n)
        if s > p { break }
        let off = amp * sin(2 * Double.pi * s * len / lambda - phase) * min(1, s * 10) * min(1, (1 - s) * 10)
        let q = BP.pt(a.x + (b.x - a.x) * s - uy * off, a.y + (b.y - a.y) * s + ux * off)
        if i == 0 { path.move(to: q) } else { path.addLine(to: q) }
    }
    c.stroke(path, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
}

// MARK: - Card 1: the question: the Sun, mixed light, clear air, noon and sunset

struct SkyBPSun: View {
    let active: Bool
    private static let story = 4.8

    var body: some View {
        BlueprintStage(active: active, length: 3.2, tick: 1.6,
                       label: "The Sun on a tall pin above a tilted disc of clear air. Its light, all colours mixed, travels down a dashed route into the air carrying faint blue, gold and red bars. On the rim of the air, two pins, noon in blue and sunset in red, each with a gold question mark that pulses.",
                       draw: { c, t, pal, clock in let (u, _) = skCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u) }, size: skSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink
        let fo = skFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))
        let ctr = BP.pt(171, 205)
        skDisc(&c, ctr, 112, 36, ink: ink, alpha: a0)

        // the light comes down the route into the air, carrying faint bars of every colour
        let start = BP.pt(171, 94), end = BP.pt(171, 203)
        let pr = BP.eio(BP.pr(u, 0.5, 2.0))
        bpGroup(&c, alpha: fo) { g in
            skRoute(&g, start, end, p: pr, color: ink, phase: u * 14)
            for j in 0..<4 {
                let s = (u * 0.3 + Double(j) / 4).truncatingRemainder(dividingBy: 1)
                guard s <= pr else { continue }
                let y = BP.mix(start.y, end.y, s)
                let a = 0.7 * BP.pr(s, 0, 0.1) * (1 - BP.pr(s, 0.9, 1))
                for (i, col) in [skSky, skMustard, skCoral].enumerated() {
                    var b = Path(); let yy = y + Double(i - 1) * 3.2
                    b.move(to: BP.pt(166, yy)); b.addLine(to: BP.pt(176, yy))
                    g.stroke(b, with: .color(col.opacity(a)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
            }
            // once the light is in the air, a blue route and a coral route lead to the two pins
            let q = BP.eio(BP.pr(u, 2.0, 3.2))
            skRoute(&g, end, BP.pt(70, 213), p: q, color: skSky, phase: u * 14)
            skRoute(&g, end, BP.pt(272, 213), p: q, color: skCoral, phase: u * 14)
        }

        // the Sun and the two rim pins
        skPin(&c, base: BP.pt(171, 88), head: BP.pt(171, 56), r: 11, color: skMustard, glyph: .sun, alpha: a0)
        skPin(&c, base: BP.pt(66, 215), head: BP.pt(66, 172), r: 9.5, color: skSky, glyph: .sun, alpha: a0)
        skPin(&c, base: BP.pt(276, 215), head: BP.pt(276, 172), r: 9.5, color: skCoral, glyph: .horizon, alpha: a0)

        // a mustard "?" over each pin, pulsing
        let qa = BP.pr(u, 2.8, 3.2) * fo
        if qa > 0.01 {
            let k = 0.5 + 0.5 * sin((u - 2.8) * 5)
            for x in [66.0, 276.0] {
                var g = c
                g.opacity = qa
                g.translateBy(x: x, y: 146)
                g.scaleBy(x: 1 + 0.25 * k, y: 1 + 0.25 * k)
                g.draw(g.resolve(Text("?").font(T.mono(16)).foregroundColor(skMustard)), at: .zero, anchor: .center)
                g.stroke(skOval(.zero, 11 + 3 * k, 11 + 3 * k), with: .color(skMustard.opacity(0.5 * (1 - k))), lineWidth: 1)
            }
        }

        bpLeader(&c, anchor: BP.pt(160, 56), elbow: BP.pt(146, 56), tail: -6, text: "THE SUN", ink: ink, p: BP.pr(t, 0.4, 1.1))
        bpLeader(&c, anchor: BP.pt(173, 125), elbow: BP.pt(186, 125), tail: 6, text: "ALL COLOURS MIXED", ink: ink, p: BP.pr(t, 0.6, 1.3))
        bpLeader(&c, anchor: BP.pt(118, 218), elbow: BP.pt(104, 262), tail: -8, text: "CLEAR AIR", ink: ink, p: BP.pr(t, 0.8, 1.5))
        bpLeader(&c, anchor: BP.pt(77, 172), elbow: BP.pt(90, 172), tail: 6, text: "NOON", ink: ink, p: BP.pr(t, 1.0, 1.7))
        bpLeader(&c, anchor: BP.pt(265, 172), elbow: BP.pt(252, 172), tail: -6, text: "SUNSET", ink: ink, p: BP.pr(t, 1.1, 1.8))
    }
}

// MARK: - Card 2: two waves arrive at one molecule, which scatters light every way

struct SkyBPWave: View {
    let active: Bool
    private static let story = 5.0

    var body: some View {
        BlueprintStage(active: active, length: 3.2, tick: 1.4,
                       label: "A tilted disc of air with one molecule at its centre, a teal pin. A short blue wave and a long red wave keep travelling in from the left along dashed routes. Teal arrows keep fanning out from the molecule across the disc in every direction.",
                       draw: { c, t, pal, clock in let (u, held) = skCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u, held) }, size: skSize)
    }

    private static let mol = BP.pt(195, 196)

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ held: Bool) {
        let ink = pal.ink
        let fo = skFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))
        skDisc(&c, mol, 104, 34, ink: ink, alpha: a0)

        // the two waves travel in along dashed routes; the crests keep sliding toward the molecule
        let bA = BP.pt(18, 168), bB = BP.pt(186, 192)
        let rA = BP.pt(18, 216), rB = BP.pt(186, 200)
        let p = BP.eio(BP.pr(u, 0.4, 1.8))
        let v = 40.0
        bpGroup(&c, alpha: fo) { g in
            skRoute(&g, bA, bB, p: p, color: ink, width: 1, phase: u * 14, alpha: 0.35)
            skRoute(&g, rA, rB, p: p, color: ink, width: 1, phase: u * 14, alpha: 0.35)
            skWave(&g, bA, bB, lambda: 16, amp: 4.5, phase: 2 * Double.pi * v * u / 16, p: p, color: skSky, alpha: 1)
            skWave(&g, rA, rB, lambda: 40, amp: 4.5, phase: 2 * Double.pi * v * u / 40, p: p, color: skCoral, alpha: 1)
        }

        // the scattered arrows fan out across the disc once the waves have arrived
        let angles: [Double] = [-75, -35, 0, 30, 60, 95, 130, -110]
        let rx = 88.0, ry = 30.0
        let reach = BP.pr(u, 1.6, 2.0)
        for (k, deg) in angles.enumerated() {
            let a = deg * Double.pi / 180
            let tip = BP.pt(mol.x + rx * cos(a), mol.y + ry * sin(a))
            let m = (u * 0.5 + Double(k) * 0.137).truncatingRemainder(dividingBy: 1)
            bpGroup(&c, alpha: fo) { g in skStream(&g, BP.pt(mol.x, mol.y - 2), tip, m: m, held: held, color: skTeal, alpha: reach) }
        }

        // the molecule: a teal pin at the centre; a ring where each wave lands
        let ring = (u * 0.8).truncatingRemainder(dividingBy: 1)
        bpGroup(&c, alpha: fo * reach) { g in
            g.stroke(skOval(mol, 4 + 18 * ring, 1.5 + 6 * ring), with: .color(skMustard.opacity(0.7 * (1 - ring))), lineWidth: 1)
        }
        skPin(&c, base: mol, head: BP.pt(195, 152), r: 10, color: skTeal, glyph: .atom, alpha: a0)

        bpLeader(&c, anchor: BP.pt(60, 174), elbow: BP.pt(50, 146), tail: 6, text: "BLUE WAVE: SHORT", ink: ink, p: BP.pr(t, 0.4, 1.1))
        bpLeader(&c, anchor: BP.pt(60, 212), elbow: BP.pt(36, 250), tail: 6, text: "RED WAVE: LONG", ink: ink, p: BP.pr(t, 0.6, 1.3))
        bpLeader(&c, anchor: BP.pt(205, 150), elbow: BP.pt(222, 126), tail: 6, text: "MOLECULE\nOF AIR", ink: ink, p: BP.pr(t, 0.8, 1.5))
        let tip = BP.pt(mol.x + rx * cos(30 * Double.pi / 180), mol.y + ry * sin(30 * Double.pi / 180))
        bpLeader(&c, anchor: tip, elbow: BP.pt(272, 254), tail: -8, text: "SCATTERED IN\nALL DIRECTIONS", ink: ink, p: BP.pr(t, 1.0, 1.7))
    }
}

// MARK: - Card 3: blue goes all over the sky, red far less

struct SkyBPAll: View {
    let active: Bool
    private static let story = 5.0

    var body: some View {
        BlueprintStage(active: active, length: 3.2, tick: 1.4,
                       label: "Sunlight, a gold dashed route, crosses a tilted disc of air. Many pale blue arrows keep fanning out from it in every direction and land on small blue pins spread around the rim, all over the sky. A few red arrows too, far fewer. A green eye pin stands at the front of the disc: your eyes.",
                       draw: { c, t, pal, clock in let (u, held) = skCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u, held) }, size: skSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ held: Bool) {
        let ink = pal.ink
        let fo = skFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))
        let ctr = BP.pt(176, 185), rx = 110.0, ry = 36.0
        skDisc(&c, ctr, rx, ry, ink: ink, alpha: a0)

        // pins spread around the rim: ALL OVER THE SKY
        var bases: [CGPoint] = [], heads: [CGPoint] = []
        for deg in [175.0, 215, 250, 290, 325, 5] {
            let a = deg * Double.pi / 180
            let b = BP.pt(ctr.x + rx * cos(a), ctr.y + ry * sin(a))
            bases.append(b); heads.append(BP.pt(b.x, b.y - 26))
        }
        for i in 0..<6 { skPin(&c, base: bases[i], head: heads[i], r: 6.5, color: skSky, glyph: .dot, alpha: a0) }
        let eyeHead = BP.pt(176, 190)

        // sunlight crosses the air; scatter arrows stream out wherever it has reached
        let a = BP.pt(14, 170), b = BP.pt(330, 170)
        let pr = BP.eio(BP.pr(u, 0.3, 1.6))
        bpGroup(&c, alpha: fo) { g in skRoute(&g, a, b, p: pr, color: skMustard, width: 1.5, phase: u * 16) }

        let sp: [CGPoint] = [105, 145, 200, 240].map { BP.pt($0, 170) }
        let blue: [(Int, Int)] = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 3), (2, 4), (3, 4), (3, 5), (1, 6), (2, 6)]
        let coral: [(Int, Int)] = [(0, 2), (3, 5)]
        func target(_ s: Int, _ ti: Int) -> CGPoint {
            let h = ti == 6 ? eyeHead : heads[ti]
            return skShort(sp[s], h, ti == 6 ? 12 : 9)
        }
        func reached(_ s: Int) -> Double { BP.cl((a.x + (b.x - a.x) * pr - sp[s].x) / 12) }
        for (k, e) in blue.enumerated() {
            let m = (u * 0.5 + Double(k) * 0.113).truncatingRemainder(dividingBy: 1)
            bpGroup(&c, alpha: fo) { g in skStream(&g, sp[e.0], target(e.0, e.1), m: m, held: held, color: skSky, alpha: reached(e.0)) }
        }
        for (k, e) in coral.enumerated() {
            let m = (u * 0.42 + 0.3 + Double(k) * 0.5).truncatingRemainder(dividingBy: 1)
            bpGroup(&c, alpha: fo) { g in skStream(&g, sp[e.0], target(e.0, e.1), m: m, held: held, color: skCoral, width: 1.1, alpha: reached(e.0)) }
        }

        // your eyes: a lime pin at the centre-front
        skPin(&c, base: BP.pt(176, 221), head: eyeHead, r: 9.5, color: skLime, glyph: .eye, alpha: a0)

        bpLeader(&c, anchor: BP.pt(28, 170), elbow: BP.pt(28, 262), tail: 6, text: "SUNLIGHT", ink: ink, p: BP.pr(t, 0.3, 1.0))
        bpLeader(&c, anchor: BP.pt(106, 208), elbow: BP.pt(86, 242), tail: -6, text: "AIR", ink: ink, p: BP.pr(t, 0.5, 1.2))
        bpLeader(&c, anchor: BP.pt(62, 156), elbow: BP.pt(30, 110), tail: 6, text: "ALL OVER\nTHE SKY", ink: ink, p: BP.pr(t, 0.7, 1.4))
        bpLeader(&c, anchor: BP.pt(141, 148), elbow: BP.pt(141, 98), tail: 6, text: "BLUE: ABOUT FOUR TIMES\nAS STRONGLY AS RED", ink: ink, p: BP.pr(t, 0.9, 1.6))
        bpLeader(&c, anchor: BP.pt(263, 166), elbow: BP.pt(302, 150), tail: 4, text: "RED", ink: ink, p: BP.pr(t, 1.1, 1.8))
        bpLeader(&c, anchor: BP.pt(186, 190), elbow: BP.pt(200, 236), tail: 6, text: "YOUR EYES", ink: ink, p: BP.pr(t, 1.3, 2.0))
    }
}

// MARK: - Card 4: the low Sun's light crosses far more air, so red and orange are what is left

struct SkyBPSunset: View {
    let active: Bool
    private static let story = 8.6

    var body: some View {
        BlueprintStage(active: active, length: 3.2, tick: 1.6,
                       label: "A tilted slice of atmosphere over a ground line, with a green eye pin on the ground. A Sun straight overhead sends a short dashed route down through the air to the eye. Then a low Sun at the horizon sends a long slanted dashed route through far more air. Blue pins peel off sideways along it, and a red and orange route is what is left at the eye. Only the low Sun and the sky near it are red.",
                       draw: { c, t, pal, clock in let (u, held) = skCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u, held) }, size: skSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ held: Bool) {
        let ink = pal.ink
        let fo = skFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))

        // the slice of atmosphere: a box in oblique view, its layers closer together (thicker air) near the ground
        let fl = BP.pt(80, 150), fr = BP.pt(280, 150), bl = BP.pt(106, 128), br = BP.pt(306, 128)
        let gl = BP.pt(80, 250), gr = BP.pt(280, 250), bgr = BP.pt(306, 228)
        func poly(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }
        bpGroup(&c, alpha: a0) { g in
            let top = poly([fl, fr, br, bl]), right = poly([fr, br, bgr, gr]), front = poly([fl, fr, gr, gl])
            for f in [(top, 0.05), (right, 0.09), (front, 0.04)] {
                g.fill(f.0, with: .color(BP.paper)); g.fill(f.0, with: .color(ink.opacity(f.1)))
                g.stroke(f.0, with: .color(ink.opacity(0.75)), style: StrokeStyle(lineWidth: BP.hair + 0.2, lineJoin: .round))
            }
            var layers = Path()
            for y in [162.0, 184, 204, 222, 237] { layers.move(to: BP.pt(80, y)); layers.addLine(to: BP.pt(280, y)) }
            g.stroke(layers, with: .color(ink.opacity(0.25)), style: StrokeStyle(lineWidth: 0.8, dash: [2, 4]))
            var ground = Path(); ground.move(to: BP.pt(12, 250)); ground.addLine(to: BP.pt(333, 250))
            g.stroke(ground, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
        }

        let eyeHead = BP.pt(200, 224)
        let overBase = BP.pt(200, 92), overHead = BP.pt(200, 62)
        let lowHead = BP.pt(30, 196), lowBase = BP.pt(30, 250)
        let L = BP.pt(42, 198), E = BP.pt(190, 224)

        // moment A: the overhead Sun, a short route; it dims once the low Sun takes over
        let aOn = BP.pr(u, 0.4, 0.8) * (1 - BP.pr(u, 3.4, 3.8))
        let aDim = 1 - 0.65 * BP.pr(u, 3.6, 4.0)
        bpGroup(&c, alpha: fo) { g in
            skRoute(&g, BP.pt(200, 98), BP.pt(200, 213), p: BP.eio(BP.pr(u, 0.5, 2.0)), color: ink, phase: u * 14, alpha: aDim)
            g.stroke(skOval(overHead, 16, 16), with: .color(skMustard.opacity(0.7 * aOn)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        }

        // moment B: the low Sun, a long slanted route; the chalk route turns coral toward the eye while blue pins peel off sideways
        let pB = BP.eio(BP.pr(u, 4.0, 6.6))
        let bOn = BP.pr(u, 3.9, 4.3)
        bpGroup(&c, alpha: fo) { g in
            skRoute(&g, L, E, p: pB, color: ink, phase: u * 14, alpha: 0.9)
            for i in 0..<6 {
                let f0 = Double(i) / 6, f1 = Double(i + 1) / 6
                guard pB > f0 else { continue }
                var s = Path(); s.move(to: BP.mixp(L, E, f0)); s.addLine(to: BP.mixp(L, E, min(pB, f1)))
                g.stroke(s, with: .color(skCoral.opacity(BP.cl((Double(i) - 1) / 4))), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 5], dashPhase: -u * 14 - f0 * hypot(E.x - L.x, E.y - L.y)))
            }
            // the sky near the low Sun goes coral: a few thin arcs, nothing more
            for (k, rr) in [20.0, 29.0].enumerated() {
                var arc = Path()
                for i in 0...10 {
                    let a = -0.9 + 1.8 * Double(i) / 10
                    let q = BP.pt(lowHead.x + rr * cos(a), lowHead.y + rr * sin(a))
                    if i == 0 { arc.move(to: q) } else { arc.addLine(to: q) }
                }
                g.stroke(arc, with: .color(skCoral.opacity(0.8 * BP.pr(u, 4.2 + 0.2 * Double(k), 5.0))), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, dash: [2, 3]))
            }
            g.stroke(skOval(lowHead, 16, 16), with: .color(skMustard.opacity(0.7 * bOn)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        }
        for f in [0.2, 0.38, 0.56, 0.74] {
            let gr = BP.eout(BP.pr(u, 4.0 + 2.6 * f, 4.0 + 2.6 * f + 0.6))
            let base = BP.mixp(L, E, f)
            skPin(&c, base: base, head: BP.pt(base.x + 6 * gr, base.y - 6 - 20 * gr), r: 6, color: skSky, glyph: .dot, alpha: gr * fo)
        }

        // the two Suns and the eye
        skPin(&c, base: overBase, head: overHead, r: 11, color: skMustard, glyph: .sun, alpha: a0)
        skPin(&c, base: lowBase, head: lowHead, r: 11, color: skMustard, glyph: .horizon, alpha: a0)
        skPin(&c, base: BP.pt(200, 250), head: eyeHead, r: 9.5, color: skLime, glyph: .eye, alpha: a0)

        bpLeader(&c, anchor: BP.pt(189, 62), elbow: BP.pt(176, 62), tail: -6, text: "SUN OVERHEAD", ink: ink, p: BP.pr(t, 0.4, 1.1))
        bpLeader(&c, anchor: BP.pt(30, 250), elbow: BP.pt(22, 268), tail: 4, text: "LOW SUN", ink: ink, p: BP.pr(t, 0.6, 1.3))
        bpLeader(&c, anchor: BP.pt(70, 203), elbow: BP.pt(92, 268), tail: 4, text: "FAR MORE AIR", ink: ink, p: BP.pr(t, 0.8, 1.5))
        bpLeader(&c, anchor: BP.pt(122, 181), elbow: BP.pt(50, 100), tail: 6, text: "BLUE SCATTERED OFF", ink: ink, p: BP.pr(t, 1.0, 1.7))
        bpLeader(&c, anchor: BP.pt(208, 230), elbow: BP.pt(206, 268), tail: 6, text: "YOUR EYES", ink: ink, p: BP.pr(t, 1.2, 1.9))
        bpLeader(&c, anchor: BP.pt(180, 222), elbow: BP.pt(190, 286), tail: 6, text: "RED AND ORANGE", ink: ink, p: BP.pr(t, 1.4, 2.1))
    }
}
