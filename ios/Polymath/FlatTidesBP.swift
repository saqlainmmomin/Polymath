import SwiftUI

// "Why does one Moon give most beaches two high tides a day?" pictures, drawn as blueprint technical illustrations (2026-10-28).
// One chalk-ink colour, one mustard accent per card (the sea's top edge, the near-sea arrow, the two bulges, your beach, the extra stretch),
// flat tints only, mono uppercase labels that use the card text's own words. Every picture loops ambiently: it plays, holds its end beat
// for about a second, then resets without a jump (the sea falls back, the arrows retract, or the whole picture fades). Tap restarts,
// Reduce Motion shows the held end state. Cards 2 to 5 share one Earth, one Moon and one bulge shape. Drawn in a 343 x 340 design space;
// keep clear of the bottom-right corner (x > 285, y > 255).

private let tbSize = CGSize(width: 343, height: 340)
private let tbE = CGPoint(x: 168, y: 170)       // Earth's centre, the same on cards 2 to 5
private let tbR = 50.0                           // Earth (the ground)
private let tbBand = 4.0                         // the sea's thickness when it is level
private let tbAmp = 16.0                         // how far a bulge rises (deliberately exaggerated)
private let tbMoonD = 144.0                      // the Moon's distance from Earth's centre
private let tbMoonR = 14.0

// MARK: - Shared helpers

/// Ambient loop time: the story ends at `story`, the loop lasts `story + extra`. Reduce Motion (the stage's clock stands still behind `t`)
/// shows the held end state.
private func tbCycle(_ t: Double, _ clock: Double, story: Double, extra: Double = 1.5) -> Double {
    if clock < t { return story }
    return clock.truncatingRemainder(dividingBy: story + extra)
}

/// 1 while the picture plays and holds (about a second), then fades to 0 over the last half second of the loop.
private func tbFade(_ u: Double, _ story: Double) -> Double { 1 - BP.pr(u, story + 1.0, story + 1.5) }

private func tbRad(_ deg: Double) -> Double { deg * Double.pi / 180 }

private func tbOval(_ ctr: CGPoint, _ rx: Double, _ ry: Double) -> Path {
    Path(ellipseIn: CGRect(x: ctr.x - rx, y: ctr.y - ry, width: 2 * rx, height: 2 * ry))
}

/// The point at radius `r` and screen angle `th` (radians, y down, so a positive turn is clockwise) from Earth's centre.
private func tbOnE(_ r: Double, _ th: Double) -> CGPoint { BP.pt(tbE.x + r * cos(th), tbE.y + r * sin(th)) }

private func tbBall(_ c: inout GraphicsContext, _ ctr: CGPoint, r: Double, color: Color, tint: Double) {
    let p = tbOval(ctr, r, r)
    c.fill(p, with: .color(BP.paper)); c.fill(p, with: .color(color.opacity(tint)))
    c.stroke(p, with: .color(color), lineWidth: BP.edge)
}

private func tbMoon(_ c: inout GraphicsContext, _ ctr: CGPoint, ink: Color) {
    tbBall(&c, ctr, r: tbMoonR, color: ink, tint: 0.16)
    c.stroke(tbOval(BP.pt(ctr.x - 4, ctr.y - 3), 3, 3), with: .color(ink.opacity(0.6)), lineWidth: BP.hair)
    c.stroke(tbOval(BP.pt(ctr.x + 4.5, ctr.y + 4), 2, 2), with: .color(ink.opacity(0.6)), lineWidth: BP.hair)
}

private func tbArrow(_ c: inout GraphicsContext, from a: CGPoint, to b: CGPoint, color: Color, width: Double = 2) {
    let len = hypot(b.x - a.x, b.y - a.y)
    guard len > 1 else { return }
    let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len, h = min(6.5, len * 0.7)
    var p = Path(); p.move(to: a); p.addLine(to: b)
    p.move(to: BP.pt(b.x - ux * h - uy * 3.4, b.y - uy * h + ux * 3.4)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * h + uy * 3.4, b.y - uy * h - ux * 3.4))
    c.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
}

/// The sea's outer radius at screen angle `th`: level, plus a bulge on the side facing `axis` (strength `b1`) and the side facing away (`b2`).
private func tbOuter(_ th: Double, axis: Double, b1: Double, b2: Double) -> Double {
    let d = cos(th - axis)
    return tbR + tbBand + tbAmp * (d >= 0 ? b1 : b2) * d * d
}

/// Earth from above with its sea. `axis` is the angle of the Moon; `b1` / `b2` grow the near and far bulges (0...1). With `hi` the bulges
/// are picked out in the accent. `spin` turns the spokes, so a turning Earth shows.
private func tbEarth(_ c: inout GraphicsContext, axis: Double, b1: Double, b2: Double, hi: Bool, spin: Double, ink: Color, acc: Color) {
    var sea = Path()
    for i in 0...180 {
        let th = 2 * Double.pi * Double(i) / 180
        let q = tbOnE(tbOuter(th, axis: axis, b1: b1, b2: b2), th)
        if i == 0 { sea.move(to: q) } else { sea.addLine(to: q) }
    }
    sea.closeSubpath()
    c.fill(sea, with: .color(BP.paper)); c.fill(sea, with: .color(ink.opacity(0.18)))
    c.stroke(sea, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
    if hi {
        for side in 0..<2 {
            let b = side == 0 ? b1 : b2
            guard b > 0.03 else { continue }
            let start = axis + (side == 0 ? -Double.pi / 2 : Double.pi / 2)
            var out = Path()
            for i in 0...36 {
                let th = start + Double.pi * Double(i) / 36
                let q = tbOnE(tbOuter(th, axis: axis, b1: b1, b2: b2), th)
                if i == 0 { out.move(to: q) } else { out.addLine(to: q) }
            }
            var fillP = out
            for i in stride(from: 36, through: 0, by: -1) { fillP.addLine(to: tbOnE(tbR + tbBand, start + Double.pi * Double(i) / 36)) }
            fillP.closeSubpath()
            c.fill(fillP, with: .color(acc.opacity(0.38)))
            c.stroke(out, with: .color(acc), style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))
        }
    }
    let disc = tbOval(tbE, tbR, tbR)
    c.fill(disc, with: .color(BP.paper)); c.fill(disc, with: .color(ink.opacity(0.08)))
    c.stroke(disc, with: .color(ink), lineWidth: BP.edge)
    var spokes = Path()
    for k in 0..<6 {
        let a = spin + Double(k) * Double.pi / 3
        spokes.move(to: tbOnE(5, a)); spokes.addLine(to: tbOnE(tbR - 1, a))
    }
    c.stroke(spokes, with: .color(ink.opacity(0.3)), lineWidth: BP.hair)
    c.fill(tbOval(tbE, 2.2, 2.2), with: .color(ink))
}

// MARK: - Card 1: the sea creeps up the sand, falls back, creeps up again

struct TidesBPBeach: View {
    let active: Bool
    private static let story = 6.8

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 6.7,
                       label: "A beach seen from the side, cut away. The sea creeps up the sand to a high-tide mark, falls back to a low-tide mark, then rises again and stays at the second high tide. The top edge of the sea is marked in gold.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, tbCycle(t, clock, story: Self.story)) }, size: tbSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let left = 16.0, right = 300.0, bottom = 250.0
        func ys(_ x: Double) -> Double { 214 - 0.40 * (x - left) }
        let hi = 128.0, lo = 172.0
        func shore(_ lv: Double) -> Double { left + (214 - lv) / 0.40 }

        // the sea: low, up to the high mark, down to the low mark, up again and held; it falls back during the reset
        let rise = BP.eio(BP.pr(u, 0.7, 2.5)) - BP.eio(BP.pr(u, 3.0, 4.8)) + BP.eio(BP.pr(u, 5.0, 6.8)) - BP.eio(BP.pr(u, story + 1.0, story + 1.5))
        let lv = lo - (lo - hi) * rise

        // the sand: a wedge with a slope, hatched
        var sand = Path()
        sand.move(to: BP.pt(left, ys(left))); sand.addLine(to: BP.pt(right, ys(right)))
        sand.addLine(to: BP.pt(right, bottom)); sand.addLine(to: BP.pt(left, bottom)); sand.closeSubpath()
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0, 0.5))) { g in
            g.fill(sand, with: .color(BP.paper)); g.fill(sand, with: .color(ink.opacity(0.10)))
            var h = g
            h.clip(to: sand)
            var hatch = Path()
            var x = left - 160.0
            while x < right + 10 { hatch.move(to: BP.pt(x, bottom + 4)); hatch.addLine(to: BP.pt(x + 170, bottom + 4 - 170)); x += 11 }
            h.stroke(hatch, with: .color(ink.opacity(0.2)), lineWidth: BP.hair)
            g.stroke(sand, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        }

        // the two tide marks
        let gH = BP.pr(t, 2.3, 3.0), gL = BP.pr(t, 0.3, 1.0)
        bpGuide(&c, BP.pt(left, hi), BP.pt(shore(hi), hi), p: gH, color: ink.opacity(0.55))
        bpGuide(&c, BP.pt(left, lo), BP.pt(shore(lo), lo), p: gL, color: ink.opacity(0.55))

        // the sea: a wedge against the sand, its top edge in mustard
        let xs = shore(lv)
        var top: [CGPoint] = []
        let n = 28
        for i in 0...n {
            let x = left + (xs - left) * Double(i) / Double(n)
            let amp = 1.1 * BP.pr(xs - left, 6, 30)
            top.append(BP.pt(x, lv + amp * sin(x * 0.12 + u * 2.4)))
        }
        var seaP = Path(); seaP.addLines(top); seaP.addLine(to: BP.pt(left, ys(left))); seaP.closeSubpath()
        var seaTop = Path(); seaTop.addLines(top)
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0, 0.5))) { g in
            g.fill(seaP, with: .color(BP.paper)); g.fill(seaP, with: .color(ink.opacity(0.22)))
            var wall = Path(); wall.move(to: BP.pt(left, lv)); wall.addLine(to: BP.pt(left, ys(left)))
            g.stroke(wall, with: .color(ink), lineWidth: BP.hair)
            g.stroke(Path { q in q.move(to: BP.pt(left, ys(left))); q.addLine(to: BP.pt(right, ys(right))) }, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
            g.stroke(seaTop, with: .color(acc), style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))
        }

        bpLeader(&c, anchor: BP.pt(shore(hi), hi), elbow: BP.pt(255, 84), tail: 10, text: "HIGH TIDE", ink: ink, p: BP.pr(t, 2.3, 3.1))
        bpLeader(&c, anchor: BP.pt(shore(lo), lo), elbow: BP.pt(110, 104), tail: 10, text: "LOW TIDE", ink: ink, p: BP.pr(t, 0.3, 1.1))
    }
}

// MARK: - Card 2: the Moon pulls the near sea hardest and the far sea least

struct TidesBPPull: View {
    let active: Bool
    private static let story = 2.8

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.6,
                       label: "Earth seen from above with the Moon to its right. Three arrows point toward the Moon from the near sea, the ground and the far sea. The arrow on the near sea is the longest and is marked in gold; the arrow on the far sea is the shortest.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, tbCycle(t, clock, story: Self.story)) }, size: tbSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let mid = tbE.y
        let moon = BP.pt(tbE.x + tbMoonD, mid)
        let fa = BP.eout(BP.pr(t, 0, 0.5))
        bpGroup(&c, alpha: fa) { g in
            tbEarth(&g, axis: 0, b1: 0, b2: 0, hi: false, spin: 0.5, ink: ink, acc: acc)
            tbMoon(&g, moon, ink: ink)
        }

        // the three pulls grow out together, hold, then draw back in
        let grow = BP.eout(BP.pr(u, 1.2, 2.6)) * (1 - BP.eio(BP.pr(u, story + 0.9, story + 1.5)))
        let far = BP.pt(tbE.x - (tbR + tbBand / 2), mid), ground = tbE, near = BP.pt(tbE.x + tbR + tbBand / 2, mid)
        tbArrow(&c, from: far, to: BP.pt(far.x + 22 * grow, mid), color: ink)
        tbArrow(&c, from: ground, to: BP.pt(ground.x + 38 * grow, mid), color: ink)
        tbArrow(&c, from: near, to: BP.pt(near.x + 62 * grow, mid), color: acc, width: 2.4)

        bpLeader(&c, anchor: near, elbow: BP.pt(238, 118), tail: 12, text: "NEAR SEA", ink: acc, p: BP.pr(t, 0.3, 1.1))
        bpLeader(&c, anchor: ground, elbow: BP.pt(180, 246), tail: 12, text: "GROUND", ink: ink, p: BP.pr(t, 0.45, 1.25))
        bpLeader(&c, anchor: far, elbow: BP.pt(100, 118), tail: -12, text: "FAR SEA", ink: ink, p: BP.pr(t, 0.6, 1.4))
        bpText(&c, "MOON", BP.pt(moon.x, moon.y + tbMoonR + 14), ink: ink, alpha: BP.pr(t, 0.2, 0.7))
    }
}

// MARK: - Card 3: three runners pulled toward a magnet become the sea, the ground and the sea, and the sea piles up at both ends

/// A simple running figure in profile, facing right, standing on `y` (the middle of its body); `ph` swings its arms and legs.
private func tbRunner(_ c: inout GraphicsContext, _ x: Double, _ y: Double, ph: Double, ink: Color) {
    let hip = BP.pt(x - 2, y + 3), sh = BP.pt(x, y - 15)
    var limbs = Path()
    for s in [0.0, Double.pi] {
        let a = sin(ph + s), l = max(0, cos(ph + s))
        limbs.move(to: hip)
        limbs.addQuadCurve(to: BP.pt(hip.x + 11 * a, hip.y + 22 - 5 * l), control: BP.pt(hip.x + 8 * a + 4, hip.y + 12 - 2 * l))
        limbs.move(to: sh)
        limbs.addQuadCurve(to: BP.pt(sh.x - 10 * a + 3, sh.y + 9 - 3 * l), control: BP.pt(sh.x - 5 * a + 3, sh.y + 8))
    }
    limbs.move(to: BP.pt(x + 1, y - 18)); limbs.addLine(to: hip)
    c.stroke(limbs, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, lineJoin: .round))
    let head = tbOval(BP.pt(x + 2.5, y - 25), 6.5, 6.5)
    c.fill(head, with: .color(BP.paper)); c.stroke(head, with: .color(ink), lineWidth: BP.edge)
}

/// A horseshoe magnet opening to the left, centred on `ctr`.
private func tbMagnet(_ c: inout GraphicsContext, _ ctr: CGPoint, ink: Color) {
    let r = 13.0
    var p = Path()
    p.move(to: BP.pt(ctr.x - 16, ctr.y - r)); p.addLine(to: BP.pt(ctr.x, ctr.y - r))
    p.addArc(center: ctr, radius: r, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
    p.addLine(to: BP.pt(ctr.x - 16, ctr.y + r))
    c.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 7, lineCap: .butt))
    c.stroke(p, with: .color(BP.paper), style: StrokeStyle(lineWidth: 4.2, lineCap: .butt))
    var tips = Path()
    for s in [-1.0, 1.0] { tips.move(to: BP.pt(ctr.x - 16, ctr.y + s * r)); tips.addLine(to: BP.pt(ctr.x - 9, ctr.y + s * r)) }
    c.stroke(tips, with: .color(ink), style: StrokeStyle(lineWidth: 7, lineCap: .butt))
}

struct TidesBPBulges: View {
    let active: Bool
    private static let story = 7.0

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 6.6,
                       label: "Three runners in a line are pulled toward a magnet and the gaps between them open up, the front runner furthest. They become the near sea, the ground and the far sea around Earth, and the sea rises into two bulges, one at each end, marked in gold, with the Moon to the right.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, tbCycle(t, clock, story: Self.story)) }, size: tbSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let g = BP.eout(BP.pr(u, 0, 0.4)) * tbFade(u, story)
        let ey = tbE.y
        let pull = BP.eio(BP.pr(u, 0.6, 3.5))              // the runners are pulled
        let k = BP.eio(BP.pr(u, 3.9, 4.9))                 // they change into the sea, the ground and the sea
        let b1 = BP.eout(BP.pr(u, 5.0, 6.0)), b2 = BP.eout(BP.pr(u, 5.6, 6.6))
        let moon = BP.pt(tbE.x + tbMoonD, ey)

        // Earth, the Moon and the bulges fade in as the runners fade out
        bpGroup(&c, alpha: k * g) { q in
            tbEarth(&q, axis: 0, b1: b1, b2: b2, hi: true, spin: 0.5, ink: ink, acc: acc)
            tbMoon(&q, moon, ink: ink)
        }

        // runners: back, middle, front. Start close together; the front one is pulled furthest.
        let startX = [40.0, 72.0, 104.0], pullX = [96.0, 164.0, 244.0]
        let dotX = [tbE.x - (tbR + tbBand / 2) - 8 * b2, tbE.x, tbE.x + tbR + tbBand / 2 + 8 * b1]
        var xs: [Double] = []
        for i in 0..<3 { xs.append(BP.mix(BP.mix(startX[i], pullX[i], pull), dotX[i], k)) }
        bpGroup(&c, alpha: (1 - k) * g) { q in
            for i in 0..<3 { tbRunner(&q, xs[i], ey, ph: u * 9, ink: ink) }
            tbMagnet(&q, BP.pt(moon.x, ey), ink: ink)
            bpGuide(&q, BP.pt(xs[2] + 14, ey - 5), BP.pt(moon.x - 22, ey - 5), p: 1, color: ink.opacity(0.5))
        }

        // names follow the runners, then the sea points they become
        let names = ["FAR SEA", "GROUND", "NEAR SEA"], elbowY = [82.0, 104.0, 126.0]
        bpGroup(&c, alpha: g) { q in
            for i in 0..<3 {
                let ay = BP.mix(ey - 32, ey, k)
                bpLeader(&q, anchor: BP.pt(xs[i], ay), elbow: BP.pt(xs[i] + 10, elbowY[i]), tail: 12, text: names[i], ink: ink, p: BP.pr(u, 1.0 + 0.3 * Double(i), 1.8 + 0.3 * Double(i)))
            }
        }
        let la = BP.pr(u, 6.1, 6.9)
        bpGroup(&c, alpha: g) { q in
            bpText(&q, "MOON", BP.pt(moon.x, moon.y + tbMoonR + 14), ink: ink, alpha: BP.pr(u, 4.6, 5.2))
            guard la > 0.01 else { return }
            let far = tbOnE(tbOuter(tbRad(145), axis: 0, b1: b1, b2: b2), tbRad(145)), near = tbOnE(tbOuter(tbRad(35), axis: 0, b1: b1, b2: b2), tbRad(35))
            var ls = Path()
            ls.move(to: BP.pt(128, 254)); ls.addLine(to: far)
            ls.move(to: BP.pt(208, 254)); ls.addLine(to: near)
            bpTrace(&q, ls, p: la, color: acc, width: BP.hair)
            for p in [far, near] { q.fill(tbOval(p, 2.2, 2.2), with: .color(acc.opacity(BP.pr(la, 0, 0.2)))) }
            bpText(&q, "TWO BULGES", BP.pt(tbE.x, 262), ink: acc, alpha: BP.pr(la, 0.5, 1))
        }
    }
}

// MARK: - Card 4: Earth turns under the two bulges, and the beach meets both

private func tbChip(_ c: inout GraphicsContext, _ ctr: CGPoint, _ text: String, lit: Double, ink: Color) {
    let w = Double(text.count) * 6.9 + 18, h = 21.0
    let r = CGRect(x: ctr.x - w / 2, y: ctr.y - h / 2, width: w, height: h)
    let p = Path(roundedRect: r, cornerRadius: 5)
    c.fill(p, with: .color(BP.paper)); c.fill(p, with: .color(ink.opacity(0.24 * lit)))
    c.stroke(p, with: .color(ink.opacity(0.35 + 0.65 * lit)), lineWidth: BP.hair + 0.3 * lit)
    bpText(&c, text, ctr, ink: ink, alpha: 0.45 + 0.55 * lit)
}

struct TidesBPTurn: View {
    let active: Bool
    private static let story = 7.0

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 6.4,
                       label: "Earth seen from above, turning, with two bulges of sea fixed toward the Moon. A gold dot for your beach rides round: low tide at the start, high tide as it passes under one bulge, low tide between, and high tide again under the other bulge.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, tbCycle(t, clock, story: Self.story)) }, size: tbSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let g = BP.eout(BP.pr(u, 0, 0.4)) * tbFade(u, story)
        let ey = tbE.y
        let moon = BP.pt(tbE.x + tbMoonD, ey)
        // the beach starts at the bottom (low tide) and is carried clockwise 270 degrees: bulge, low tide, bulge
        let psi = tbRad(90 + 270 * BP.pr(u, 1.8, 7.0))
        let dot = tbOnE(tbR, psi)
        let high = BP.pr(abs(cos(psi)), 0.70, 0.88)

        bpGroup(&c, alpha: g) { q in
            tbEarth(&q, axis: 0, b1: 1, b2: 1, hi: false, spin: psi, ink: ink, acc: acc)
            tbMoon(&q, moon, ink: ink)
            bpGuide(&q, BP.pt(tbE.x - 80, ey), BP.pt(moon.x - tbMoonR - 4, ey), p: BP.pr(u, 0.2, 0.9), color: ink.opacity(0.45))
            q.stroke(tbOval(dot, 8, 8), with: .color(acc.opacity(0.9)), lineWidth: BP.hair)
            q.fill(tbOval(dot, 4.5, 4.5), with: .color(acc))
            tbChip(&q, BP.pt(80, 292), "HIGH TIDE", lit: high, ink: ink)
            tbChip(&q, BP.pt(190, 292), "LOW TIDE", lit: 1 - high, ink: ink)

            let pb = BP.pr(t, 0.5, 1.3)
            bpLeader(&q, anchor: tbOnE(tbOuter(tbRad(-15), axis: 0, b1: 1, b2: 1), tbRad(-15)), elbow: BP.pt(252, 118), tail: 10, text: "BULGE", ink: ink, p: pb)
            bpLeader(&q, anchor: tbOnE(tbOuter(tbRad(195), axis: 0, b1: 1, b2: 1), tbRad(195)), elbow: BP.pt(84, 118), tail: -10, text: "BULGE", ink: ink, p: BP.pr(t, 0.65, 1.45))
        }
        // YOUR BEACH names the dot where it starts, then again where it ends
        let startA = (1 - BP.pr(u, 1.7, 2.1)), endA = BP.pr(u, 6.2, 6.8)
        bpGroup(&c, alpha: g * startA) { q in
            bpLeader(&q, anchor: tbOnE(tbR, tbRad(90)), elbow: BP.pt(190, 246), tail: 12, text: "YOUR BEACH", ink: acc, p: BP.pr(t, 0.9, 1.7))
        }
        bpGroup(&c, alpha: g * endA) { q in
            bpLeader(&q, anchor: tbOnE(tbR, 0), elbow: BP.pt(240, 134), tail: 10, text: "YOUR BEACH", ink: acc, p: 1)
        }
    }
}

// MARK: - Card 5: the Moon moves on, so the beach turns a little further

struct TidesBPLater: View {
    let active: Bool
    private static let story = 6.4

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 6.2,
                       label: "Earth seen from above with your beach under the bulge nearest the Moon. Earth turns once while the Moon moves a little on, so the bulge has moved. The beach has to turn a bit further to reach the bulge again, and that extra stretch is marked in gold: about 50 extra minutes.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, tbCycle(t, clock, story: Self.story)) }, size: tbSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let g = BP.eout(BP.pr(u, 0, 0.4)) * tbFade(u, story)
        let phi0 = -28.0                                         // the Moon starts up and to the right
        let lam = BP.pr(u, 1.4, 4.6)                             // Earth's one full turn
        let ex = BP.eio(BP.pr(u, 5.0, 6.2))                      // the extra stretch
        let phi = tbRad(phi0 + 28 * lam)                         // the Moon (and so the bulges) moves on in the same direction
        let psi = tbRad(phi0 + 360 * lam + 28 * ex)              // the beach
        let moon = tbOnE(tbMoonD, phi), ghost = tbOnE(tbMoonD, tbRad(phi0))
        let dot = tbOnE(tbR, psi), start = tbOnE(tbR, tbRad(phi0))

        bpGroup(&c, alpha: g) { q in
            // the Moon's path, and where it was
            var orbit = Path()
            for i in 0...24 { let a = tbRad(-42 + 50 * Double(i) / 24); let p = tbOnE(tbMoonD, a); if i == 0 { orbit.move(to: p) } else { orbit.addLine(to: p) } }
            q.stroke(orbit, with: .color(ink.opacity(0.4)), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 4]))
            q.stroke(tbOval(ghost, tbMoonR, tbMoonR), with: .color(ink.opacity(0.5 * BP.pr(lam, 0.02, 0.2))), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 3]))

            tbEarth(&q, axis: phi, b1: 1, b2: 1, hi: false, spin: psi, ink: ink, acc: acc)
            tbMoon(&q, moon, ink: ink)

            // the extra stretch, in mustard
            if ex > 0.01 {
                var arc = Path()
                for i in 0...16 { let p = tbOnE(tbR, tbRad(phi0 + 28 * ex * Double(i) / 16)); if i == 0 { arc.move(to: p) } else { arc.addLine(to: p) } }
                q.stroke(arc, with: .color(acc), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            q.stroke(tbOval(dot, 8, 8), with: .color(ink.opacity(0.9)), lineWidth: BP.hair)
            q.fill(tbOval(dot, 4.5, 4.5), with: .color(ink))

            bpText(&q, "MOON", BP.pt(moon.x, moon.y - tbMoonR - 13), ink: ink, alpha: BP.pr(t, 0.3, 0.9))
        }
        // YOUR BEACH marks the start spot: shown while the beach waits there, hidden during the turn, back when it returns
        let ya = (1 - BP.pr(u, 1.5, 1.9)) + BP.pr(u, 4.5, 4.9)
        bpGroup(&c, alpha: g * min(1, ya)) { q in
            bpLeader(&q, anchor: start, elbow: BP.pt(194, 96), tail: -14, text: "YOUR BEACH", ink: ink, p: BP.pr(t, 0.5, 1.3))
        }
        let mid = tbOnE(tbR, tbRad(phi0 + 14))
        bpGroup(&c, alpha: g) { q in
            bpLeader(&q, anchor: mid, elbow: BP.pt(270, 205), tail: 8, text: "ABOUT 50\nEXTRA\nMINUTES", ink: acc, p: BP.pr(u, 5.3, 6.2))
        }
    }
}
