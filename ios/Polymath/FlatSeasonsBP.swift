import SwiftUI

// "Why is it summer when Earth is farthest from the Sun?" pictures, drawn as blueprint technical illustrations (2026-10-28).
// One chalk-ink colour, one mustard accent per card (Earth at its farthest point, the three extra steps, the axis arrow, the light patch,
// London's lit arc), flat tints only, mono uppercase labels that use the card text's own words. Every picture loops ambiently: it plays,
// holds its end beat for about a second, fades its moving parts and starts again; labels appear once and stay. Tap restarts, Reduce Motion
// shows the held end state. Drawn in a 343 x 340 design space; keep clear of the bottom-right corner (x > 285, y > 255).

private let ssSize = CGSize(width: 343, height: 340)

// MARK: - Shared helpers

/// Ambient loop time: the story ends at `story`, the loop lasts `story + extra`. Reduce Motion (the stage's clock stands still behind `t`)
/// shows the held end state.
private func ssCycle(_ t: Double, _ clock: Double, story: Double, extra: Double = 1.5) -> Double {
    if clock < t { return story }
    return clock.truncatingRemainder(dividingBy: story + extra)
}

/// 1 while the picture plays and holds, then fades to 0 over the last half second of the loop.
private func ssFade(_ u: Double, _ story: Double) -> Double { 1 - BP.pr(u, story + 1.0, story + 1.5) }

private func ssOval(_ ctr: CGPoint, _ rx: Double, _ ry: Double) -> Path {
    Path(ellipseIn: CGRect(x: ctr.x - rx, y: ctr.y - ry, width: 2 * rx, height: 2 * ry))
}

/// A flat disc: paper underneath, a tint, an edge.
private func ssBall(_ c: inout GraphicsContext, _ ctr: CGPoint, r: Double, color: Color, tint: Double, width: Double = BP.edge) {
    let p = ssOval(ctr, r, r)
    c.fill(p, with: .color(BP.paper)); c.fill(p, with: .color(color.opacity(tint)))
    c.stroke(p, with: .color(color), lineWidth: width)
}

private func ssSun(_ c: inout GraphicsContext, _ ctr: CGPoint, r: Double, ink: Color) {
    var rays = Path()
    for k in 0..<12 {
        let a = Double(k) * Double.pi / 6
        rays.move(to: BP.pt(ctr.x + (r + 3) * cos(a), ctr.y + (r + 3) * sin(a)))
        rays.addLine(to: BP.pt(ctr.x + (r + 3 + (k % 2 == 0 ? 5 : 3)) * cos(a), ctr.y + (r + 3 + (k % 2 == 0 ? 5 : 3)) * sin(a)))
    }
    c.stroke(rays, with: .color(ink.opacity(0.75)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
    ssBall(&c, ctr, r: r, color: ink, tint: 0.22)
}

private func ssHead(_ p: inout Path, _ a: CGPoint, _ b: CGPoint) {
    let len = hypot(b.x - a.x, b.y - a.y), ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    p.move(to: BP.pt(b.x - ux * 6 - uy * 3.4, b.y - uy * 6 + ux * 3.4)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * 6 + uy * 3.4, b.y - uy * 6 - ux * 3.4))
}

// MARK: - Card 1: July is farthest, January is closest

struct SeasonsBPFar: View {
    let active: Bool
    private static let story = 3.7

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 1.5,
                       label: "A top-down view of Earth's nearly circular path round the Sun. Earth travels round it and pauses at the top, marked in gold, where it is farthest from the Sun in July, then at the bottom, where it is closest in January.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, ssCycle(t, clock, story: Self.story)) }, size: ssSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = ssFade(u, story)
        let cx = 171.0, cy = 154.0, a = 112.0, b = 111.35
        func orbit(_ th: Double) -> CGPoint { BP.pt(cx - b * sin(th), cy - a * cos(th)) }
        let sun = BP.pt(171, 166), jul = orbit(0), jan = orbit(Double.pi)

        var ring = Path()
        for i in 0...120 {
            let q = orbit(2 * Double.pi * Double(i) / 120)
            if i == 0 { ring.move(to: q) } else { ring.addLine(to: q) }
        }
        bpTrace(&c, ring, p: BP.pr(t, 0, 0.9), color: ink.opacity(0.8), width: BP.hair)

        let gp = BP.pr(t, 0.5, 1.1)
        bpGuide(&c, BP.pt(171, 150), BP.pt(171, jul.y + 15), p: gp, color: ink.opacity(0.6))
        bpGuide(&c, BP.pt(171, 182), BP.pt(171, jan.y - 15), p: gp, color: ink.opacity(0.6))
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0, 0.5))) { g in ssSun(&g, sun, r: 14, ink: ink) }

        // Earth at its farthest point stays marked in mustard
        bpGroup(&c, alpha: BP.pr(u, 1.3, 1.6) * fo) { g in
            ssBall(&g, jul, r: 8, color: acc, tint: 0.4)
            g.stroke(ssOval(jul, 13, 13), with: .color(acc), lineWidth: BP.hair)
        }
        // the travelling Earth: right side up to July, a beat there, then round to January
        let th = u < 2.1 ? -Double.pi / 2 + (Double.pi / 2) * BP.eio(BP.pr(u, 0.3, 1.5)) : Double.pi * BP.eio(BP.pr(u, 2.1, story))
        bpGroup(&c, alpha: BP.pr(u, 0, 0.3) * fo) { g in ssBall(&g, orbit(th), r: 8, color: ink, tint: 0.2) }

        bpLeader(&c, anchor: BP.pt(jul.x + 9, jul.y - 4), elbow: BP.pt(jul.x + 26, jul.y - 22), tail: 10, text: "JULY\nFARTHEST", ink: acc, p: BP.pr(t, 0.6, 1.3))
        bpLeader(&c, anchor: BP.pt(jan.x + 9, jan.y + 4), elbow: BP.pt(jan.x + 26, jan.y + 26), tail: 10, text: "JANUARY\nCLOSEST", ink: ink, p: BP.pr(t, 0.8, 1.5))
    }
}

// MARK: - Card 2: 100 steps in January, 103 in July, the same distance for Australia and Canada

struct SeasonsBPSteps: View {
    let active: Bool
    private static let story = 3.9
    private static let x0 = 40.0, step = 2.5, yJ = 46.0, yL = 96.0

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.4,
                       label: "Two measuring lines from the Sun to Earth, side by side. January is 100 steps long; July is 103, and the three extra steps are shown in gold, about 3 percent. Below, one Earth at the same distance from the Sun has Canada in winter and Australia in summer.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, ssCycle(t, clock, story: Self.story)) }, size: ssSize)
    }

    private static func row(_ c: inout GraphicsContext, y: Double, n: Double, ink: Color, acc: Color) {
        let end = x0 + n * step, knee = x0 + min(n, 100) * step
        var base = Path(); base.move(to: BP.pt(x0, y)); base.addLine(to: BP.pt(knee, y))
        var tk = Path(), tx = Path()
        for k in 0...Int(n) {
            let x = x0 + Double(k) * step, h = k % 10 == 0 ? 7.0 : 3.0
            if k <= 100 { tk.move(to: BP.pt(x, y - h)); tk.addLine(to: BP.pt(x, y + h)) }
            else { tx.move(to: BP.pt(x, y - h)); tx.addLine(to: BP.pt(x, y + h)) }
        }
        c.stroke(base, with: .color(ink), lineWidth: BP.hair)
        c.stroke(tk, with: .color(ink.opacity(0.75)), lineWidth: BP.hair)
        if n > 100 {
            var e = Path(); e.move(to: BP.pt(knee, y)); e.addLine(to: BP.pt(end, y))
            c.stroke(e, with: .color(acc), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            c.stroke(tx, with: .color(acc), lineWidth: BP.edge)
        }
        ssBall(&c, BP.pt(end + 6, y), r: 6, color: ink, tint: 0.2)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = ssFade(u, story)

        // the two lines are drawn together up to 100 steps; July goes on for three more
        let n1 = 100 * BP.eio(BP.pr(u, 0.3, 1.8))
        let n2 = n1 + 3 * BP.eout(BP.pr(u, 1.9, 2.4))
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0, 0.4))) { g in
            ssSun(&g, BP.pt(26, yJ), r: 11, ink: ink); ssSun(&g, BP.pt(26, yL), r: 11, ink: ink)
        }
        bpGroup(&c, alpha: BP.pr(u, 0, 0.3) * fo) { g in
            row(&g, y: yJ, n: n1, ink: ink, acc: acc)
            row(&g, y: yL, n: n2, ink: ink, acc: acc)
        }
        bpGuide(&c, BP.pt(x0 + 100 * step, yJ - 24), BP.pt(x0 + 100 * step, yL + 22), p: BP.pr(t, 1.8, 2.2), color: ink.opacity(0.6))
        let la = BP.pr(t, 0.2, 0.6)
        bpText(&c, "JANUARY: 100 STEPS", BP.pt(x0, yJ - 18), ink: ink, alpha: la, anchor: .leading)
        bpText(&c, "JULY: 103 STEPS", BP.pt(x0, yL - 18), ink: ink, alpha: la, anchor: .leading)
        bpLeader(&c, anchor: BP.pt(294, yL), elbow: BP.pt(300, yL + 22), tail: -10, text: "3 PERCENT", ink: acc, p: BP.pr(t, 2.2, 2.8))

        // one Earth, the same distance for Canada and Australia
        let by = 219.0, ex = 170.0, er = 30.0
        let bA = BP.eout(BP.pr(t, 2.8, 3.4))
        bpGroup(&c, alpha: bA) { g in
            ssSun(&g, BP.pt(26, by), r: 11, ink: ink)
            bpGuide(&g, BP.pt(42, by), BP.pt(ex - er - 4, by), color: ink.opacity(0.7))
            ssBall(&g, BP.pt(ex, by), r: er, color: ink, tint: 0.12)
            g.stroke(ssOval(BP.pt(ex, by), er, 8), with: .color(ink.opacity(0.55)), lineWidth: BP.hair)
        }
        bpText(&c, "SAME DISTANCE", BP.pt(88, by - 16), ink: ink, alpha: bA)
        bpLeader(&c, anchor: BP.pt(ex + 12, by - 20), elbow: BP.pt(ex + 42, by - 31), tail: 10, text: "CANADA\nWINTER", ink: ink, p: BP.pr(t, 3.1, 3.8))
        bpLeader(&c, anchor: BP.pt(ex + 12, by + 24), elbow: BP.pt(ex + 38, by + 33), tail: 10, text: "AUSTRALIA\nSUMMER", ink: ink, p: BP.pr(t, 3.2, 3.9))
    }
}

// MARK: - Card 3: the lean never turns, so each half takes a turn toward the Sun

/// A globe with its axis as a mustard arrow. `tilt` leans the axis to the right of upright; the north half is the darker one.
private func ssGlobe(_ c: inout GraphicsContext, _ ctr: CGPoint, r: Double, tilt: Double, ink: Color, acc: Color) {
    let ax = BP.pt(sin(tilt), -cos(tilt)), pp = BP.pt(cos(tilt), sin(tilt))
    let disc = ssOval(ctr, r, r)
    c.fill(disc, with: .color(BP.paper)); c.fill(disc, with: .color(ink.opacity(0.06)))
    let a0 = atan2(ax.y, ax.x)
    var north = Path()
    for i in 0...24 {
        let a = a0 - Double.pi / 2 + Double.pi * Double(i) / 24
        let q = BP.pt(ctr.x + r * cos(a), ctr.y + r * sin(a))
        if i == 0 { north.move(to: q) } else { north.addLine(to: q) }
    }
    north.closeSubpath()
    c.fill(north, with: .color(ink.opacity(0.26)))
    c.stroke(disc, with: .color(ink), lineWidth: BP.edge)
    var eq = Path()
    eq.move(to: BP.pt(ctr.x - pp.x * r, ctr.y - pp.y * r)); eq.addLine(to: BP.pt(ctr.x + pp.x * r, ctr.y + pp.y * r))
    c.stroke(eq, with: .color(ink.opacity(0.7)), lineWidth: BP.hair)
    let tail = BP.pt(ctr.x - ax.x * r * 1.45, ctr.y - ax.y * r * 1.45), tip = BP.pt(ctr.x + ax.x * r * 1.8, ctr.y + ax.y * r * 1.8)
    var axis = Path(); axis.move(to: tail); axis.addLine(to: tip); ssHead(&axis, tail, tip)
    c.stroke(axis, with: .color(acc), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, lineJoin: .round))
}

struct SeasonsBPLean: View {
    let active: Bool
    private static let story = 4.4
    private static let tilt = 23.0 * Double.pi / 180

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 1.4,
                       label: "Earth goes once round the Sun, seen from the side. Its axis, a gold arrow tilted 23 degrees from upright, always points the same way. In June the north half leans toward the Sun and the south half away; in December, on the far side, it is the other way round.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, ssCycle(t, clock, story: Self.story)) }, size: ssSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = ssFade(u, story)
        let sun = BP.pt(171, 160), rx = 100.0, ry = 38.0, gr = 16.0
        let june = BP.pt(sun.x - rx, sun.y), dec = BP.pt(sun.x + rx, sun.y)

        bpTrace(&c, Path(ellipseIn: CGRect(x: sun.x - rx, y: sun.y - ry, width: 2 * rx, height: 2 * ry)), p: BP.pr(t, 0, 0.8), color: ink.opacity(0.8), width: BP.hair)

        // June and December stay drawn, the same arrow leaning the same way in both
        let ga = BP.eout(BP.pr(t, 0.2, 0.7))
        bpGroup(&c, alpha: ga) { g in
            ssGlobe(&g, june, r: gr, tilt: tilt, ink: ink, acc: acc)
            ssGlobe(&g, dec, r: gr, tilt: tilt, ink: ink, acc: acc)
            // the 23 degrees: upright, the axis, and the angle between
            var up = Path(); up.move(to: dec); up.addLine(to: BP.pt(dec.x, dec.y - 44))
            g.stroke(up, with: .color(ink.opacity(0.7)), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 3]))
            var arc = Path()
            for i in 0...12 {
                let a = -Double.pi / 2 + tilt * Double(i) / 12
                let q = BP.pt(dec.x + 36 * cos(a), dec.y + 36 * sin(a))
                if i == 0 { arc.move(to: q) } else { arc.addLine(to: q) }
            }
            g.stroke(arc, with: .color(ink), lineWidth: BP.hair)
        }
        bpText(&c, "JUNE", BP.pt(june.x, 200), ink: ink, alpha: ga)
        bpText(&c, "DECEMBER", BP.pt(dec.x, 200), ink: ink, alpha: ga)

        // the Sun and the travelling Earth (behind the Sun in the back half of the path)
        let al = -Double.pi / 2 + 2 * Double.pi * BP.pr(u, 0.4, story)
        let pos = BP.pt(sun.x - rx * cos(al), sun.y + ry * sin(al))
        let ea = BP.pr(u, 0, 0.35) * fo
        let behind = sin(al) < 0
        if behind { bpGroup(&c, alpha: ea) { g in ssGlobe(&g, pos, r: gr, tilt: tilt, ink: ink, acc: acc) } }
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0, 0.5))) { g in ssSun(&g, sun, r: 16, ink: ink) }
        if !behind { bpGroup(&c, alpha: ea) { g in ssGlobe(&g, pos, r: gr, tilt: tilt, ink: ink, acc: acc) } }

        let n = june.x + 11.2, nt = june.y - 26.5
        bpLeader(&c, anchor: BP.pt(n, nt), elbow: BP.pt(104, 106), tail: 10, text: "NORTH", ink: ink, p: BP.pr(t, 0.7, 1.3))
        bpLeader(&c, anchor: BP.pt(june.x - 8.9, june.y + 21), elbow: BP.pt(40, 222), tail: 10, text: "SOUTH", ink: ink, p: BP.pr(t, 0.8, 1.4))
        let am = -Double.pi / 2 + tilt / 2
        bpLeader(&c, anchor: BP.pt(dec.x + 36 * cos(am), dec.y + 36 * sin(am)), elbow: BP.pt(292, 92), tail: -10, text: "23 DEGREES", ink: acc, p: BP.pr(t, 0.9, 1.5))
    }
}

// MARK: - Card 4: the same light, a small bright spot or a long dim patch

struct SeasonsBPTorch: View {
    let active: Bool
    private static let story = 4.4
    private static let px = 62.0, py = 80.0, table = 226.0, beta = 7.5 * Double.pi / 180, maxTilt = 50.0 * Double.pi / 180

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 0.7,
                       label: "A torch above a table tilts back and forth. Held straight, its light makes a small, bright gold spot on the table. Tilted, the same light spreads into a long, dim patch.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, ssCycle(t, clock, story: Self.story, extra: 1.0)) }, size: ssSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))
        let h = table - py
        let tl = BP.eio(BP.pr(u, 1.0, 2.6)) - BP.eio(BP.pr(u, 3.0, story))
        let th = tl * maxTilt

        // the table
        bpGroup(&c, alpha: a0) { g in
            func poly(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }
            let top = poly([BP.pt(14, table), BP.pt(304, table), BP.pt(316, table - 8), BP.pt(26, table - 8)])
            let front = poly([BP.pt(14, table), BP.pt(304, table), BP.pt(304, table + 14), BP.pt(14, table + 14)])
            for (p, k) in [(top, 0.1), (front, 0.2)] {
                g.fill(p, with: .color(BP.paper)); g.fill(p, with: .color(ink.opacity(k)))
                g.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
            }
        }

        // the light: a wedge from the torch to a patch on the table
        let x1 = px + h * tan(th - beta), x2 = px + h * tan(th + beta)
        let w0 = 2 * h * tan(beta), w = x2 - x1
        let bright = 0.12 + 0.8 * pow(w0 / w, 2.2)
        bpGroup(&c, alpha: a0) { g in
            var wedge = Path(); wedge.move(to: BP.pt(px, py)); wedge.addLine(to: BP.pt(x1, table)); wedge.addLine(to: BP.pt(x2, table)); wedge.closeSubpath()
            g.fill(wedge, with: .color(acc.opacity(0.08)))
            var edges = Path()
            edges.move(to: BP.pt(px, py)); edges.addLine(to: BP.pt(x1, table)); edges.move(to: BP.pt(px, py)); edges.addLine(to: BP.pt(x2, table))
            g.stroke(edges, with: .color(acc.opacity(0.55)), style: StrokeStyle(lineWidth: BP.hair, dash: [4, 4]))
            var patch = Path()
            patch.move(to: BP.pt(x1, table)); patch.addLine(to: BP.pt(x2, table)); patch.addLine(to: BP.pt(x2 + 12, table - 8)); patch.addLine(to: BP.pt(x1 + 12, table - 8)); patch.closeSubpath()
            g.fill(patch, with: .color(acc.opacity(bright)))
            g.stroke(patch, with: .color(acc), style: StrokeStyle(lineWidth: BP.hair, lineJoin: .round))
        }

        // the torch, turning about its front
        bpGroup(&c, alpha: a0) { g in
            let d = BP.pt(sin(th), cos(th)), n = BP.pt(cos(th), -sin(th))
            func at(_ along: Double, _ side: Double) -> CGPoint { BP.pt(px + d.x * along + n.x * side, py + d.y * along + n.y * side) }
            var body = Path()
            body.move(to: at(-50, -7)); body.addLine(to: at(-14, -7)); body.addLine(to: at(0, -11)); body.addLine(to: at(0, 11))
            body.addLine(to: at(-14, 7)); body.addLine(to: at(-50, 7)); body.closeSubpath()
            g.fill(body, with: .color(BP.paper)); g.fill(body, with: .color(ink.opacity(0.14)))
            g.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
            var grip = Path()
            for k in [-40.0, -34.0, -28.0] { grip.move(to: at(k, -7)); grip.addLine(to: at(k, 7)) }
            g.stroke(grip, with: .color(ink.opacity(0.6)), lineWidth: BP.hair)
            var lens = Path(); lens.move(to: at(0, -11)); lens.addLine(to: at(0, 11))
            g.stroke(lens, with: .color(acc), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }

        // brackets on the table mark the two extremes; labels use the card's own words
        let la = BP.pr(t, 0.3, 0.8)
        let smallA = px - w0 / 2, smallB = px + w0 / 2
        let longA = px + h * tan(maxTilt - beta), longB = px + h * tan(maxTilt + beta)
        var br = Path()
        for (xa, xb) in [(smallA, smallB), (longA, longB)] {
            br.move(to: BP.pt(xa, 246)); br.addLine(to: BP.pt(xa, 254)); br.addLine(to: BP.pt(xb, 254)); br.addLine(to: BP.pt(xb, 246))
        }
        bpTrace(&c, br, p: la, color: ink.opacity(0.8), width: BP.hair)
        bpLeader(&c, anchor: BP.pt(px, 254), elbow: BP.pt(50, 280), tail: 10, text: "SMALL,\nBRIGHT SPOT", ink: acc, p: BP.pr(t, 0.5, 1.2))
        bpLeader(&c, anchor: BP.pt((longA + longB) / 2, 254), elbow: BP.pt(250, 280), tail: -10, text: "LONG,\nDIM PATCH", ink: ink, p: BP.pr(t, 0.6, 1.3))
        bpLeader(&c, anchor: BP.pt(px + 3, py - 4), elbow: BP.pt(86, 54), tail: 10, text: "TORCH", ink: ink, p: BP.pr(t, 0.3, 0.9))
        bpLeader(&c, anchor: BP.pt(36, table + 8), elbow: BP.pt(28, 196), tail: 10, text: "TABLE", ink: ink, p: BP.pr(t, 0.4, 1.0))
    }
}

// MARK: - Card 5: more of London's spin in the light in June than in December

struct SeasonsBPDay: View {
    let active: Bool
    private static let story = 4.5
    private static let r = 60.0, cy = 172.0
    private static let lat = 51.5 * Double.pi / 180, tiltD = 23.4 * Double.pi / 180
    private static let spinStart = 0.5

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.23,
                       label: "Earth seen from above the north pole, spinning, twice: June on the left, December on the right. Sunlight comes from the top. London is marked on each. In June London spends most of the spin in light and in December most of it in the dark; London's lit arc is shown in gold and the June one is about twice as long as the December one.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, ssCycle(t, clock, story: Self.story)) }, size: ssSize)
    }

    /// The dark side of a globe seen from the pole with the Sun straight up and `delta` the Sun's latitude.
    private static func night(_ ctr: CGPoint, delta: Double) -> Path {
        var p = Path()
        for i in 0...40 {
            let v = -1 + 2 * Double(i) / 40
            let q = BP.pt(ctr.x + r * v, ctr.y + r * sqrt(max(0, 1 - v * v)))
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        for i in stride(from: 40, through: 0, by: -1) {
            let v = -1 + 2 * Double(i) / 40
            p.addLine(to: BP.pt(ctr.x + r * v, ctr.y + r * sin(delta) * sqrt(max(0, 1 - v * v))))
        }
        p.closeSubpath()
        return p
    }

    /// London's position on its circle of latitude, `l` radians of spin from noon (Sun straight up).
    private static func london(_ ctr: CGPoint, _ l: Double) -> CGPoint {
        let rr = r * cos(lat), a = Double.pi / 2 + l
        return BP.pt(ctr.x + rr * cos(a), ctr.y - rr * sin(a))
    }

    private static func arc(_ ctr: CGPoint, _ l0: Double, _ l1: Double) -> Path {
        var p = Path()
        let n = max(2, Int(abs(l1 - l0) / 0.08))
        for i in 0...n {
            let q = london(ctr, l0 + (l1 - l0) * Double(i) / Double(n))
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        return p
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = ssFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))
        let sigma = 2 * Double.pi * BP.pr(u, spinStart, story)
        let earths: [(CGPoint, Double, String)] = [(BP.pt(85, cy), tiltD, "JUNE"), (BP.pt(250, cy), -tiltD, "DECEMBER")]

        for (ctr, delta, name) in earths {
            // half of the circle of latitude is lit when the Sun is straight over the equator; the lean shifts that
            let lam0 = acos(-(sin(lat) * tan(delta)) / cos(lat))
            bpGroup(&c, alpha: a0) { g in
                let disc = ssOval(ctr, r, r)
                g.fill(disc, with: .color(BP.paper)); g.fill(disc, with: .color(ink.opacity(0.04)))
                let nt = night(ctr, delta: delta)
                g.fill(nt, with: .color(ink.opacity(0.26)))
                var term = Path()
                for i in 0...40 {
                    let v = -1 + 2 * Double(i) / 40
                    let q = BP.pt(ctr.x + r * v, ctr.y + r * sin(delta) * sqrt(max(0, 1 - v * v)))
                    if i == 0 { term.move(to: q) } else { term.addLine(to: q) }
                }
                g.stroke(term, with: .color(ink.opacity(0.55)), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 3]))
                g.stroke(disc, with: .color(ink), lineWidth: BP.edge)
                g.stroke(arc(ctr, -Double.pi, Double.pi), with: .color(ink.opacity(0.3)), style: StrokeStyle(lineWidth: BP.hair, dash: [2, 3]))
                // sunlight arrives from the top
                var rays = Path()
                for dx in [-30.0, 0, 30] {
                    rays.move(to: BP.pt(ctr.x + dx, 56)); rays.addLine(to: BP.pt(ctr.x + dx, 90)); ssHead(&rays, BP.pt(ctr.x + dx, 56), BP.pt(ctr.x + dx, 92))
                }
                g.stroke(rays, with: .color(ink.opacity(0.7)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round))
                g.fill(ssOval(ctr, 2, 2), with: .color(ink))
            }
            // the spin: marks on the rim turn, London travels, and the arc it spends in the light is drawn in mustard
            bpGroup(&c, alpha: a0) { g in
                var ticks = Path()
                for k in 0..<12 {
                    let a = Double(k) * Double.pi / 6 + sigma
                    ticks.move(to: BP.pt(ctr.x + (r - 6) * cos(a), ctr.y - (r - 6) * sin(a))); ticks.addLine(to: BP.pt(ctr.x + (r - 1) * cos(a), ctr.y - (r - 1) * sin(a)))
                }
                g.stroke(ticks, with: .color(ink.opacity(0.8)), lineWidth: BP.hair)
            }
            let l = -lam0 + sigma
            bpGroup(&c, alpha: fo) { g in
                if l > -lam0 + 0.01 {
                    bpTrace(&g, arc(ctr, -lam0, min(l, lam0)), p: 1, color: acc, width: 2.6)
                    if l > lam0 { bpTrace(&g, arc(ctr, lam0, l), p: 1, color: ink.opacity(0.7), width: BP.hair) }
                }
                let lit = abs(l) < lam0
                let m = london(ctr, l)
                g.fill(ssOval(m, 4.6, 4.6), with: .color(BP.paper))
                g.fill(ssOval(m, 3.4, 3.4), with: .color(lit ? acc : ink))
            }
            let label = name == "JUNE" ? "LONG DAY" : "SHORT DAY"
            bpText(&c, name, BP.pt(ctr.x, 244), ink: ink, alpha: BP.pr(t, 0.3, 0.8))
            bpText(&c, label, BP.pt(ctr.x, 257), ink: ink, alpha: BP.pr(t, 0.4, 0.9))
        }

        // LONDON is marked where it rises in the June spin
        let c0 = earths[0].0
        let lam0J = acos(-(sin(lat) * tan(tiltD)) / cos(lat))
        let rise = london(c0, -lam0J)
        bpLeader(&c, anchor: rise, elbow: BP.pt(rise.x + 11, 232), tail: 10, text: "LONDON", ink: acc, p: BP.pr(t, 0.6, 1.3))
    }
}
