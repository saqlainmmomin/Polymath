import SwiftUI

// "Why doesn't instant glue stick inside its own tube?" pictures, drawn as blueprint technical illustrations (2026-10-28).
// Every card draws the same tube of glue (glTube + glCap), the same glue drop (glDome + glDrop) and the same fingertip (glFinger) from shared
// helpers, so the objects look identical throughout: a front-on cutaway with a slight oblique depth. One chalk-ink colour, one mustard accent per
// card (the drop on the finger, the water in both drops, the film of water, the moisture reaching the glue), flat tints only, hatching means
// "gone hard". Labels are mono uppercase and use the slide text's own words. Each picture plays once after its card has settled (about 3 s),
// then rests on its end state; tap replays; Reduce Motion shows the end state. Drawn in a 343 x 340 design space; keep clear of the
// bottom-right corner (x > 285, y > 255).

private let glSize = CGSize(width: 343, height: 340)

// MARK: - Shared parts

/// Where a part sits: `cx`, `oy` is the screen position of its local origin, `s` points per local unit.
private struct GlGeo {
    var cx: Double, oy: Double, s: Double
    func p(_ x: Double, _ y: Double) -> CGPoint { BP.pt(cx + x * s, oy + y * s) }
    var dv: CGPoint { BP.pt(6.5 * s, -3.6 * s) }          // the oblique depth
}

private func glPoly(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }

private func glFillEdge(_ c: inout GraphicsContext, _ p: Path, ink: Color, tint: Double) {
    c.fill(p, with: .color(BP.paper)); c.fill(p, with: .color(ink.opacity(tint)))
    c.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
}

/// Diagonal hatching inside `clip`, only within `reveal`: the flat tint and the lines that say "gone hard".
private func glHatch(_ c: inout GraphicsContext, clip: Path, reveal: CGRect, bounds: CGRect, color: Color, tint: Double) {
    var g = c
    g.clip(to: clip)
    g.clip(to: Path(reveal))
    g.fill(Path(bounds), with: .color(color.opacity(tint)))
    var h = Path()
    var x = bounds.minX - bounds.height
    while x < bounds.maxX {
        h.move(to: BP.pt(x, bounds.maxY)); h.addLine(to: BP.pt(x + bounds.height, bounds.minY)); x += 5
    }
    g.stroke(h, with: .color(color.opacity(0.85)), lineWidth: BP.hair)
}

/// A drop of glue: a dome standing on `base(x)`, `w` wide and `h` high.
private func glDome(cx: Double, w: Double, h: Double, base: (Double) -> Double) -> Path {
    var p = Path()
    let n = 28
    for i in 0...n {
        let u = -1 + 2 * Double(i) / Double(n), x = cx + u * w / 2
        let q = BP.pt(x, base(x) - h * pow(max(0, 1 - u * u), 0.6))
        if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
    }
    for i in stride(from: n, through: 0, by: -1) {
        let x = cx + (-1 + 2 * Double(i) / Double(n)) * w / 2
        p.addLine(to: BP.pt(x, base(x)))
    }
    p.closeSubpath()
    return p
}

/// Draws a glue drop: runny (a light tint) until `set` grows hatching up from its base.
private func glDrop(_ c: inout GraphicsContext, _ path: Path, color: Color, runny: Double, hatch: Color, hard: Double, set: Double) {
    c.fill(path, with: .color(BP.paper)); c.fill(path, with: .color(color.opacity(runny)))
    if set > 0.001 {
        let b = path.boundingRect
        let reveal = CGRect(x: b.minX - 1, y: b.maxY - b.height * set - 1, width: b.width + 2, height: b.height * set + 2)
        glHatch(&c, clip: path, reveal: reveal, bounds: b, color: hatch, tint: hard)
    }
    c.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
}

/// The tube of glue: local x -20...20, tip at y 12, shoulders at 40, flat crimped end at 130...137. `level` is the local height of the glue's
/// surface and `tilt` how much it leans (the slosh). `plug` 0...1 hardens the glue in the tip from the top down.
private func glTube(_ c: inout GraphicsContext, _ g: GlGeo, ink: Color, level: Double, tilt: Double, plug: Double = 0) {
    let outer = [g.p(-6, 12), g.p(6, 12), g.p(20, 40), g.p(20, 130), g.p(-20, 130), g.p(-20, 40)]
    let dv = g.dv
    func off(_ q: CGPoint) -> CGPoint { BP.pt(q.x + dv.x, q.y + dv.y) }
    // depth: the top of the tip and the right side
    let topFace = glPoly([outer[0], outer[1], off(outer[1]), off(outer[0])])
    let side = glPoly([outer[1], outer[2], outer[3], off(outer[3]), off(outer[2]), off(outer[1])])
    glFillEdge(&c, topFace, ink: ink, tint: 0.08)
    glFillEdge(&c, side, ink: ink, tint: 0.2)
    // the front, then the flat crimp at the bottom
    glFillEdge(&c, glPoly(outer), ink: ink, tint: 0.07)
    let crimp = Path(CGRect(x: g.p(-20, 130).x, y: g.p(-20, 130).y, width: 40 * g.s, height: 7 * g.s))
    glFillEdge(&c, crimp, ink: ink, tint: 0.25)
    var ribs = Path()
    for k in 1...3 { let y = 130 + 7.0 * Double(k) / 4; ribs.move(to: g.p(-20, y)); ribs.addLine(to: g.p(20, y)) }
    c.stroke(ribs, with: .color(ink.opacity(0.6)), lineWidth: BP.hair)
    // the cut: glue inside the walls
    let inner = glPoly([g.p(-4, 17), g.p(4, 17), g.p(17, 43), g.p(17, 127), g.p(-17, 127), g.p(-17, 43)])
    c.fill(inner, with: .color(BP.paper))
    var gc = c
    gc.clip(to: inner)
    func sy(_ x: Double) -> Double { level + tilt * x / 17 }
    gc.fill(glPoly([g.p(-20, sy(-20)), g.p(20, sy(20)), g.p(20, 140), g.p(-20, 140)]), with: .color(ink.opacity(0.26)))
    var surf = Path(); surf.move(to: g.p(-20, sy(-20))); surf.addLine(to: g.p(20, sy(20)))
    gc.stroke(surf, with: .color(ink), lineWidth: BP.hair)
    if plug > 0.001 {
        let b = inner.boundingRect
        let reveal = CGRect(x: b.minX, y: b.minY, width: b.width, height: g.p(0, 14 + 30 * plug).y - b.minY)
        glHatch(&c, clip: inner, reveal: reveal, bounds: b, color: ink, tint: 0.34)
    }
    c.stroke(inner, with: .color(ink.opacity(0.55)), style: StrokeStyle(lineWidth: BP.hair, lineJoin: .round))
    c.stroke(glPoly(outer), with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
}

/// The cap, over the tip; (dx, dy) lifts it in local units.
private func glCap(_ c: inout GraphicsContext, _ g: GlGeo, ink: Color, dx: Double = 0, dy: Double = 0) {
    let dv = g.dv
    let x0 = -10 + dx, x1 = 10 + dx, y0 = -12 + dy, y1 = 20 + dy
    let front = [g.p(x0, y0), g.p(x1, y0), g.p(x1, y1), g.p(x0, y1)]
    func off(_ q: CGPoint) -> CGPoint { BP.pt(q.x + dv.x * 0.8, q.y + dv.y * 0.8) }
    glFillEdge(&c, glPoly([front[0], front[1], off(front[1]), off(front[0])]), ink: ink, tint: 0.1)
    glFillEdge(&c, glPoly([front[1], off(front[1]), off(front[2]), front[2]]), ink: ink, tint: 0.22)
    glFillEdge(&c, glPoly(front), ink: ink, tint: 0.14)
    var grip = Path()
    for y in [-4.0, 2.0, 8.0] { grip.move(to: g.p(x0 + 2, y + dy)); grip.addLine(to: g.p(x1 - 2, y + dy)) }
    c.stroke(grip, with: .color(ink.opacity(0.6)), lineWidth: BP.hair)
}

/// A fingertip pointing up, apex at the local origin, local x -22...22; the lower end breaks off with a zigzag.
private func glFinger(_ c: inout GraphicsContext, _ g: GlGeo, ink: Color, length: Double = 80) {
    func outline(_ dx: Double, _ dy: Double) -> Path {
        var p = Path()
        p.move(to: BP.pt(g.p(-22, length).x + dx, g.p(-22, length).y + dy))
        p.addLine(to: BP.pt(g.p(-22, 22).x + dx, g.p(-22, 22).y + dy))
        for i in 1...16 {
            let a = Double.pi + Double.pi * Double(i) / 16
            let q = g.p(22 * cos(a), 22 + 22 * sin(a))
            p.addLine(to: BP.pt(q.x + dx, q.y + dy))
        }
        p.addLine(to: BP.pt(g.p(22, length).x + dx, g.p(22, length).y + dy))
        let zig = [(14.0, 4.0), (7.0, -1.0), (0.0, 4.0), (-7.0, -1.0), (-14.0, 4.0)]
        for (x, dyz) in zig { p.addLine(to: BP.pt(g.p(x, length + dyz).x + dx, g.p(x, length + dyz).y + dy)) }
        p.closeSubpath()
        return p
    }
    let dv = g.dv
    glFillEdge(&c, outline(dv.x, dv.y), ink: ink, tint: 0.2)
    var join = Path()
    for y in [22.0, length] { join.move(to: g.p(22, y)); join.addLine(to: BP.pt(g.p(22, y).x + dv.x, g.p(22, y).y + dv.y)) }
    c.stroke(join, with: .color(ink), lineWidth: BP.edge)
    glFillEdge(&c, outline(0, 0), ink: ink, tint: 0.1)
    // fingerprint ridges near the tip
    var ridges = Path()
    for r in [6.0, 11.0, 16.0] {
        for i in 0...14 {
            let a = Double.pi * 1.12 + Double.pi * 0.76 * Double(i) / 14
            let q = g.p(r * cos(a), 36 + r * sin(a))
            if i == 0 { ridges.move(to: q) } else { ridges.addLine(to: q) }
        }
    }
    c.stroke(ridges, with: .color(ink.opacity(0.55)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
}

/// A small calendar page showing a month.
private func glCalendar(_ c: inout GraphicsContext, _ r: CGRect, month: String, ink: Color) {
    glFillEdge(&c, Path(r), ink: ink, tint: 0.07)
    let head = CGRect(x: r.minX, y: r.minY, width: r.width, height: 13)
    c.fill(Path(head), with: .color(ink.opacity(0.28)))
    c.stroke(Path(head), with: .color(ink), lineWidth: BP.hair)
    for dx in [0.28, 0.72] {
        var ring = Path(); ring.move(to: BP.pt(r.minX + r.width * dx, r.minY - 4)); ring.addLine(to: BP.pt(r.minX + r.width * dx, r.minY + 2))
        c.stroke(ring, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
    bpText(&c, month, BP.pt(r.midX, r.minY + 7), ink: ink)
    for row in 0..<3 { for col in 0..<5 {
        let q = BP.pt(r.minX + 7 + Double(col) * (r.width - 14) / 4, r.minY + 21 + Double(row) * 7)
        c.fill(Path(ellipseIn: CGRect(x: q.x - 1.1, y: q.y - 1.1, width: 2.2, height: 2.2)), with: .color(ink.opacity(0.6)))
    } }
}

/// A short arrow head at `b` pointing along a to b.
private func glHead(_ p: inout Path, _ a: CGPoint, _ b: CGPoint) {
    let len = hypot(b.x - a.x, b.y - a.y), ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    p.move(to: BP.pt(b.x - ux * 5 - uy * 3, b.y - uy * 5 + ux * 3)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * 5 + uy * 3, b.y - uy * 5 - ux * 3))
}

private func glDot(_ c: inout GraphicsContext, _ at: CGPoint, r: Double, color: Color, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    c.fill(Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(alpha)))
}

/// Ambient loop time: `hold` is when the end state is reached, the loop lasts `hold + 1.5`; Reduce Motion (the stage's clock stands still
/// behind `t`) shows the held end state. Returns (time in the cycle, reduce).
private func glCycle(_ t: Double, _ clock: Double, hold: Double, extra: Double = 1.5) -> (Double, Bool) {
    if clock < t { return (hold, true) }
    return (clock.truncatingRemainder(dividingBy: hold + extra), false)
}

// MARK: - Card 1: hard in seconds on a finger, runny for months in the tube

struct GlueBPFast: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 2.4, tick: 1.8,
                       label: "A cutaway tube of glue standing on the left, with its cap on, and a fingertip on the right with a drop of glue on it, shown in gold. A small calendar page says May and a timer says three seconds. The glue in the tube sloshes slowly and stays runny. The drop on the finger fills with hatching and goes hard. Labels say: in the tube, runny for months; on your finger, hard in seconds.",
                       draw: { c, t, pal, clock in let (u, r) = glCycle(t, clock, hold: 2.4); Self.draw(&c, t, pal, u, clock, r) }, size: glSize)
    }

    private static let tube = GlGeo(cx: 84, oy: 31.6, s: 1.2)
    private static let finger = GlGeo(cx: 250, oy: 120, s: 1.2)

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))

        // the tube: its glue sloshes slowly, then settles
        let slosh = still ? 0 : sin(clock * 1.7) * 4.5 * BP.pr(t, 0.3, 1.2)
        bpGroup(&c, alpha: a0) { g in
            glTube(&g, tube, ink: ink, level: 62, tilt: slosh)
            glCap(&g, tube, ink: ink)
        }

        // the calendar: months go by in the tube
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.2, 0.6))) { g in
            glCalendar(&g, CGRect(x: 124, y: 78, width: 46, height: 42), month: "MAY", ink: ink)
        }

        // the finger and its drop (mustard)
        bpGroup(&c, alpha: a0) { g in glFinger(&g, finger, ink: ink, length: 80) }
        let fx = finger.cx, fy = finger.oy
        let drop = glDome(cx: fx, w: 32, h: 22, base: { x in fy + 26.4 - sqrt(max(0, 26.4 * 26.4 - (x - fx) * (x - fx))) + 1 })
        let set = BP.eio(BP.pr(u, 0.5, 1.8))
        let dropA = BP.pr(u, 0, 0.3) * (1 - BP.pr(u, 3.4, 3.9))        // a fresh drop each round, fading out and in
        bpGroup(&c, alpha: dropA) { g in
            glDrop(&g, drop, color: acc, runny: 0.2, hatch: acc, hard: 0.5, set: set)
        }

        // the timer: three seconds, the ring fills as the drop sets
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.2, 0.6))) { g in
            let ctr = BP.pt(fx, 56), r = 17.0
            g.fill(Path(roundedRect: CGRect(x: ctr.x - 3, y: ctr.y - r - 5, width: 6, height: 5), cornerRadius: 1), with: .color(ink.opacity(0.5)))
            g.stroke(Path(roundedRect: CGRect(x: ctr.x - 3, y: ctr.y - r - 5, width: 6, height: 5), cornerRadius: 1), with: .color(ink), lineWidth: BP.hair)
            let face = Path(ellipseIn: CGRect(x: ctr.x - r, y: ctr.y - r, width: 2 * r, height: 2 * r))
            g.fill(face, with: .color(BP.paper)); g.fill(face, with: .color(ink.opacity(0.07)))
            g.stroke(face, with: .color(ink.opacity(0.6)), lineWidth: BP.hair)
            var arc = Path()
            let n = 40
            for i in 0...n {
                let a = -Double.pi / 2 + 2 * Double.pi * Double(i) / Double(n)
                let q = BP.pt(ctr.x + (r - 0.5) * cos(a), ctr.y + (r - 0.5) * sin(a))
                if i == 0 { arc.move(to: q) } else { arc.addLine(to: q) }
            }
            bpGroup(&g, alpha: dropA) { h in bpTrace(&h, arc, p: set, color: ink, width: 2) }
            bpText(&g, "3S", ctr, ink: ink)
        }

        bpLeader(&c, anchor: tube.p(-12, 100), elbow: BP.pt(12, 246), tail: 10, text: "IN THE TUBE:\nRUNNY FOR MONTHS", ink: ink, p: BP.pr(t, 0.3, 0.9))
        bpLeader(&c, anchor: BP.pt(244, 200), elbow: BP.pt(148, 246), tail: 24, text: "ON YOUR FINGER:\nHARD IN SECONDS", ink: acc, p: BP.pr(t, 0.4, 1.0))
    }
}

// MARK: - Card 2: school glue loses water, superglue takes it in

struct GlueBPWater: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 2.9, tick: 2.8,
                       label: "Two drops of glue side by side on a plank, seen in cross-section, with the water in each shown in gold. On the left, school glue: its water rises away as vapour and the drop dries and goes hard. On the right, superglue: moisture from the air arrives and drifts into the drop, and it goes hard. Labels say: school glue, superglue, water, air.",
                       draw: { c, t, pal, clock in let (u, r) = glCycle(t, clock, hold: 2.9); Self.draw(&c, t, pal, u, clock, r) }, size: glSize)
    }

    private static let y0 = 193.0
    private static let lx = 88.0, rx = 250.0
    private static let inside: [(Double, Double)] = [(-26, -14), (0, -12), (24, -14), (-14, -28), (12, -30), (0, -42)]

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))

        // the plank in cross-section
        bpGroup(&c, alpha: a0) { g in
            let dv = BP.pt(10, -6)
            func off(_ q: CGPoint) -> CGPoint { BP.pt(q.x + dv.x, q.y + dv.y) }
            let tl = BP.pt(16, 196), tr = BP.pt(320, 196), br = BP.pt(320, 222), bl = BP.pt(16, 222)
            glFillEdge(&g, glPoly([tl, tr, off(tr), off(tl)]), ink: ink, tint: 0.08)
            glFillEdge(&g, glPoly([tr, off(tr), off(br), br]), ink: ink, tint: 0.2)
            glFillEdge(&g, glPoly([tl, tr, br, bl]), ink: ink, tint: 0.12)
            var grain = Path()
            for (y, x0, x1) in [(205.0, 30.0, 150.0), (213.0, 90.0, 250.0), (207.0, 200.0, 305.0)] { grain.move(to: BP.pt(x0, y)); grain.addLine(to: BP.pt(x1, y)) }
            g.stroke(grain, with: .color(ink.opacity(0.4)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, dash: [6, 5]))
        }

        // left: school glue dries, so its drop shrinks a little as the water leaves
        let dry = BP.eio(BP.pr(u, 0.5, 1.8)), wet = BP.eio(BP.pr(u, 1.9, 2.9))
        let dropA = BP.pr(u, 0, 0.35) * (1 - BP.pr(u, 3.9, 4.4))
        let leftDrop = glDome(cx: lx, w: 92, h: 56 * (1 - 0.15 * dry), base: { _ in y0 })
        let rightDrop = glDome(cx: rx, w: 92, h: 56, base: { _ in y0 })
        bpGroup(&c, alpha: a0 * dropA) { g in
            glDrop(&g, leftDrop, color: ink, runny: 0.14, hatch: ink, hard: 0.3, set: dry)
            glDrop(&g, rightDrop, color: ink, runny: 0.14, hatch: ink, hard: 0.3, set: wet)
        }

        // water guides: vapour rises from the left drop, moisture falls on the right one
        let gp = BP.pr(t, 0.2, 0.9)
        for lane in [64.0, 88.0, 112.0] {
            var w = Path()
            for i in 0...20 {
                let y = 128 - 44 * Double(i) / 20
                let q = BP.pt(lane + 3 * sin(y / 6), y)
                if i == 0 { w.move(to: q) } else { w.addLine(to: q) }
            }
            var arrow = w
            glHead(&arrow, BP.pt(lane, 90), BP.pt(lane + 3 * sin(84.0 / 6), 84))
            bpTrace(&c, arrow, p: gp, color: acc.opacity(0.55), width: BP.hair)
        }
        for lane in [218.0, 238.0, 258.0] {
            var s = Path(); s.move(to: BP.pt(lane, 78)); s.addLine(to: BP.pt(lane, 126))
            glHead(&s, BP.pt(lane, 100), BP.pt(lane, 128))
            bpTrace(&c, s, p: gp, color: acc.opacity(0.55), width: BP.hair)
        }

        // the water in each drop: it leaves the left, it arrives in the right (mustard)
        for (k, d) in inside.enumerated() {
            // left: rises, wobbling, and thins out in the air
            let ru = BP.eio(BP.pr(u, 0.3 + 0.1 * Double(k), 1.5 + 0.1 * Double(k)))
            let sx = lx + d.0, sy = y0 + d.1
            let ey = 80 + 7 * Double(k)
            let q = BP.pt(sx + 5 * sin(ru * 9 + Double(k)) * ru, BP.mix(sy, ey, ru))
            glDot(&c, q, r: 2.6, color: acc, alpha: (1 - 0.55 * BP.pr(ru, 0.7, 1)) * dropA)

            // right: drifts down from the air and settles in the drop
            let v = BP.eio(BP.pr(u, 1.0 + 0.12 * Double(k), 2.2 + 0.12 * Double(k)))
            let lane = [218.0, 238.0, 258.0][k % 3]
            let from = BP.pt(lane, 74 + 8 * Double(k / 3))
            let to = BP.pt(rx + d.0, y0 + d.1)
            glDot(&c, BP.mixp(from, to, v), r: 2.6, color: acc, alpha: BP.pr(v, 0, 0.12) * dropA)
        }

        // titles over each drop
        bpText(&c, "SCHOOL GLUE", BP.pt(lx, 28), ink: ink, alpha: BP.pr(t, 0.1, 0.6))
        bpText(&c, "SUPERGLUE", BP.pt(rx, 28), ink: ink, alpha: BP.pr(t, 0.2, 0.7))
        bpLeader(&c, anchor: BP.pt(64, 112), elbow: BP.pt(52, 112), tail: -4, text: "WATER", ink: acc, p: BP.pr(t, 0.3, 0.9))
        bpLeader(&c, anchor: BP.pt(258, 100), elbow: BP.pt(276, 100), tail: 0, text: "WATER", ink: acc, p: BP.pr(t, 0.4, 1.0))
        bpLeader(&c, anchor: BP.pt(218, 82), elbow: BP.pt(190, 62), tail: -4, text: "AIR", ink: ink, p: BP.pr(t, 0.5, 1.1))
    }
}

// MARK: - Card 3: the skin's thin film of water, and a drop that lands on it

struct GlueBPFilm: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.0, tick: 0.85,
                       label: "A magnified cutaway of fingertip skin with ridges on top, and a thin film of water on it shown in gold. A drop of glue falls and lands on the film, then goes hard from the bottom up, where it touches the water. Labels say: water film, glue, skin.",
                       draw: { c, t, pal, clock in let (u, r) = glCycle(t, clock, hold: 3.0); Self.draw(&c, t, pal, u, clock, r) }, size: glSize)
    }

    private static func ridge(_ x: Double) -> Double { 196 + 5 * cos((x - 18) * 2 * Double.pi / 36) }
    private static func filmTop(_ x: Double) -> Double { ridge(x) - 8 }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))
        let x0 = 18.0, x1 = 318.0, bottom = 250.0
        let xs = stride(from: x0, through: x1, by: 3).map { $0 }
        let dv = BP.pt(10, -6)

        bpGroup(&c, alpha: a0) { g in
            // depth: the back of the top surface and the cut end
            var strip = Path()
            for (i, x) in xs.enumerated() { let q = BP.pt(x, ridge(x)); if i == 0 { strip.move(to: q) } else { strip.addLine(to: q) } }
            for x in xs.reversed() { strip.addLine(to: BP.pt(x + dv.x, ridge(x) + dv.y)) }
            strip.closeSubpath()
            glFillEdge(&g, strip, ink: ink, tint: 0.07)
            glFillEdge(&g, glPoly([BP.pt(x1, ridge(x1)), BP.pt(x1 + dv.x, ridge(x1) + dv.y), BP.pt(x1 + dv.x, bottom + dv.y), BP.pt(x1, bottom)]), ink: ink, tint: 0.2)
            // the front of the skin
            var body = Path()
            for (i, x) in xs.enumerated() { let q = BP.pt(x, ridge(x)); if i == 0 { body.move(to: q) } else { body.addLine(to: q) } }
            body.addLine(to: BP.pt(x1, bottom)); body.addLine(to: BP.pt(x0, bottom)); body.closeSubpath()
            glFillEdge(&g, body, ink: ink, tint: 0.1)
            // cell layers under the surface
            var layers = Path()
            for y in [222.0, 238.0] { layers.move(to: BP.pt(x0 + 6, y)); layers.addLine(to: BP.pt(x1 - 6, y)) }
            g.stroke(layers, with: .color(ink.opacity(0.4)), style: StrokeStyle(lineWidth: BP.hair, dash: [2, 5]))
            var cells = Path()
            for (row, y) in [212.0, 230.0].enumerated() {
                var x = x0 + 14 + (row == 0 ? 0 : 12)
                while x < x1 - 10 { cells.move(to: BP.pt(x, y - 4)); cells.addLine(to: BP.pt(x, y + 4)); x += 24 }
            }
            g.stroke(cells, with: .color(ink.opacity(0.35)), lineWidth: BP.hair)
        }

        // the film of water, mustard, riding the ridges
        let fp = BP.pr(t, 0.05, 0.5)
        bpGroup(&c, alpha: fp) { g in
            var film = Path()
            for (i, x) in xs.enumerated() { let q = BP.pt(x, filmTop(x)); if i == 0 { film.move(to: q) } else { film.addLine(to: q) } }
            let top = film
            for x in xs.reversed() { film.addLine(to: BP.pt(x, ridge(x))) }
            film.closeSubpath()
            g.fill(film, with: .color(BP.paper)); g.fill(film, with: .color(acc.opacity(0.5 + (still ? 0 : 0.1 * sin(clock * 1.6)))))
            g.stroke(top, with: .color(acc), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        }

        // the drop falls, lands on the film and spreads, then goes hard from the bottom up
        let cx = 170.0
        let f = BP.pr(u, 0.2, 0.85), land = BP.pr(u, 0.8, 0.9), spread = BP.eout(BP.pr(u, 0.85, 1.3))
        let dropA = BP.pr(u, 0.15, 0.35) * (1 - BP.pr(u, 4.0, 4.5))
        let w = BP.mix(30, 140, spread), h = BP.mix(34, 64, spread)
        let yBase = filmTop(cx) - 130 * (1 - f * f)
        let drop = glDome(cx: cx, w: w, h: h, base: { x in yBase + (filmTop(x) - filmTop(cx)) * land })
        bpGroup(&c, alpha: dropA) { g in glDrop(&g, drop, color: ink, runny: 0.18, hatch: ink, hard: 0.38, set: BP.eio(BP.pr(u, 1.1, 3.0))) }

        bpLeader(&c, anchor: BP.pt(130, 160), elbow: BP.pt(34, 120), tail: 10, text: "GLUE", ink: ink, p: BP.pr(t, 0.9, 1.5))
        bpLeader(&c, anchor: BP.pt(256, filmTop(256) + 3), elbow: BP.pt(256, 160), tail: 0, text: "WATER FILM", ink: acc, p: BP.pr(t, 0.2, 0.8))
        bpLeader(&c, anchor: BP.pt(60, 236), elbow: BP.pt(20, 278), tail: 10, text: "SKIN", ink: ink, p: BP.pr(t, 0.3, 0.9))
    }
}

// MARK: - Card 4: cap on, moisture bounces off; cap off, moisture creeps in and the tip goes hard

struct GlueBPCap: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.1, tick: 2.75,
                       label: "A cutaway tube of glue with its cap on. Dots of moisture, shown in gold, fly in from the air and bounce off the cap, so the glue stays runny. Then the cap lifts off, the moisture creeps in at the tip, and the glue at the tip fills with hatching, goes hard and blocks it. Labels say: cap, tip, moisture, glue.",
                       draw: { c, t, pal, clock in let (u, r) = glCycle(t, clock, hold: 3.1, extra: 2.1); Self.draw(&c, t, pal, u, clock, r) }, size: glSize)
    }

    private static let tube = GlGeo(cx: 165, oy: 80, s: 1.3)
    private static let ys = [70.0, 84.0, 98.0, 76.0, 90.0]
    private static let rest: [CGPoint] = [BP.pt(236, 58), BP.pt(226, 80), BP.pt(240, 102), BP.pt(228, 122), BP.pt(244, 140)]
    private static let final: [(Double, Double)] = [(-3, 22), (3, 26), (-2, 31)]       // inside the neck, for dots 2...4

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))
        let g = tube
        let lift = BP.eio(BP.pr(u, 1.4, 2.0)) * (1 - BP.eio(BP.pr(u, 4.2, 4.9)))
        let hard = BP.eio(BP.pr(u, 2.4, 3.1)) * (1 - BP.eio(BP.pr(u, 4.1, 4.6)))
        let dotFade = 1 - BP.pr(u, 4.4, 5.1)

        bpGroup(&c, alpha: a0) { gc in
            glTube(&gc, g, ink: ink, level: 18, tilt: 0, plug: hard)
            glCap(&gc, g, ink: ink, dx: 16 * lift, dy: -36 * lift)
        }

        // moisture: all dots fly at the cap and bounce back; once it is off, three of them creep in at the tip
        let entry = g.p(0, 8)
        for k in 0..<5 {
            let start = BP.pt(272, ys[k]), hit = BP.pt(186, ys[k]), at = rest[k]
            let bu = BP.pr(u, 0.3 + 0.18 * Double(k), 1.2 + 0.18 * Double(k))
            var q: CGPoint
            var a = 1.0
            if bu < 0.5 {
                q = BP.mixp(start, hit, BP.eout(bu * 2)); a = BP.pr(bu, 0, 0.1)
            } else {
                q = BP.mixp(hit, at, BP.eout((bu - 0.5) * 2))
            }
            if k >= 2 {
                let v = BP.pr(u, 1.9 + 0.15 * Double(k - 2), 2.7 + 0.15 * Double(k - 2))
                let fin = g.p(final[k - 2].0, final[k - 2].1)
                if v > 0 {
                    q = v < 0.55 ? BP.mixp(at, entry, BP.eio(v / 0.55)) : BP.mixp(entry, fin, BP.eio((v - 0.55) / 0.45))
                }
            }
            glDot(&c, q, r: 2.6, color: acc, alpha: a * dotFade)
        }

        let capAt = g.p(-10 + 16 * lift, 4 - 36 * lift)
        bpLeader(&c, anchor: capAt, elbow: BP.pt(112, 42), tail: -4, text: "CAP", ink: ink, p: BP.pr(t, 0.2, 0.7))
        bpLeader(&c, anchor: g.p(0, 14), elbow: BP.pt(112, 100), tail: -4, text: "TIP", ink: ink, p: BP.pr(t, 0.3, 0.8))
        bpLeader(&c, anchor: g.p(-12, 95), elbow: BP.pt(112, 196), tail: -4, text: "GLUE", ink: ink, p: BP.pr(t, 0.4, 0.9))
        bpLeader(&c, anchor: rest[0], elbow: BP.pt(262, 40), tail: 0, text: "MOISTURE", ink: acc, p: BP.pr(t, 0.7, 1.3))
    }
}
