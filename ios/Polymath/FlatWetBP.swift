import SwiftUI

// "Can your skin feel wet when it is dry?" pictures, drawn as blueprint technical illustrations (2026-10-31).
// One chalk-ink colour, one mustard accent per card (the empty slot, the cold signal, the cold and touch signals joining into WET, the
// tags that light), flat tints only, mono uppercase labels that use the approved slide's own words. Every picture loops ambiently:
// it plays, holds its end beat for about a second, fades its moving parts and starts again. Tap restarts, Reduce Motion shows the held
// end state. Drawn in a 343 x 340 design space; keep clear of the bottom-right corner (x > 285, y > 255).

private let wtSize = CGSize(width: 343, height: 340)

// MARK: - Shared helpers

/// Ambient loop time: the story ends at `story`, the loop lasts `story + extra`. Reduce Motion shows the held end state.
private func wtCycle(_ t: Double, _ clock: Double, story: Double, extra: Double = 1.5) -> Double {
    if clock < t { return story }
    return clock.truncatingRemainder(dividingBy: story + extra)
}

/// 1 while the picture plays and holds, then fades to 0 over the last half second of the loop.
private func wtFade(_ u: Double, _ story: Double) -> Double { 1 - BP.pr(u, story + 1.0, story + 1.5) }

private func wtOval(_ ctr: CGPoint, _ rx: Double, _ ry: Double) -> Path {
    Path(ellipseIn: CGRect(x: ctr.x - rx, y: ctr.y - ry, width: 2 * rx, height: 2 * ry))
}

private func wtHead(_ p: inout Path, _ a: CGPoint, _ b: CGPoint, _ size: Double = 5) {
    let len = hypot(b.x - a.x, b.y - a.y)
    guard len > 0.1 else { return }
    let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    p.move(to: BP.pt(b.x - ux * size - uy * size * 0.56, b.y - uy * size + ux * size * 0.56)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * size + uy * size * 0.56, b.y - uy * size - ux * size * 0.56))
}

private func wtPoly(_ pts: [CGPoint]) -> Path {
    var p = Path()
    for (i, q) in pts.enumerated() { if i == 0 { p.move(to: q) } else { p.addLine(to: q) } }
    return p
}

private func wtLength(_ pts: [CGPoint]) -> Double {
    var n = 0.0
    for i in 1..<pts.count { n += hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y) }
    return n
}

/// The point `k` (0...1) of the way along a polyline.
private func wtAlong(_ pts: [CGPoint], _ k: Double) -> CGPoint {
    var left = wtLength(pts) * BP.cl(k)
    for i in 1..<pts.count {
        let a = pts[i - 1], b = pts[i]
        let d = hypot(b.x - a.x, b.y - a.y)
        if left <= d || i == pts.count - 1 { return BP.mixp(a, b, d > 0 ? min(1, left / d) : 0) }
        left -= d
    }
    return pts[0]
}

/// A signal in flight along a nerve: a bright dot with a short fading trail.
private func wtPulse(_ c: inout GraphicsContext, _ pts: [CGPoint], k: Double, color: Color) {
    guard k > 0.001, k < 0.999 else { return }
    let len = max(1, wtLength(pts))
    for i in 0..<4 {
        let kk = k - Double(i) * 5.5 / len
        guard kk > 0 else { continue }
        let r = 3.6 - Double(i) * 0.7
        c.fill(wtOval(wtAlong(pts, kk), r, r), with: .color(color.opacity(1 - Double(i) * 0.22)))
    }
}

/// A flat ring where a signal lands, `k` 0...1.
private func wtRing(_ c: inout GraphicsContext, _ at: CGPoint, r: Double, k: Double, color: Color) {
    guard k > 0.001, k < 0.999 else { return }
    c.stroke(wtOval(at, r + 16 * BP.eout(k), r + 16 * BP.eout(k)), with: .color(color.opacity(1 - k)), lineWidth: BP.hair + 0.4)
}

/// A slab of skin seen from the side: a surface line, a thin top layer and a deeper layer under a dashed boundary.
private func wtSkin(_ c: inout GraphicsContext, x0: Double, x1: Double, top: Double, bot: Double, ink: Color, a: Double, tint: Color? = nil) {
    bpGroup(&c, alpha: a) { g in
        let body = Path(CGRect(x: x0, y: top, width: x1 - x0, height: bot - top))
        g.fill(body, with: .color(BP.paper)); g.fill(body, with: .color((tint ?? ink).opacity(tint == nil ? 0.1 : 0.2)))
        var layer = Path(); layer.move(to: BP.pt(x0, top + 9)); layer.addLine(to: BP.pt(x1, top + 9))
        g.stroke(layer, with: .color(ink.opacity(0.45)), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 3]))
        g.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
    }
}

private enum WtKind { case cold, warm, touch }

/// A tiny sensor under the skin: a stem up to the skin, a small bulb and a glyph for what it reacts to. `lit` 0...1 turns it mustard.
private func wtSensor(_ c: inout GraphicsContext, _ ctr: CGPoint, kind: WtKind, ink: Color, acc: Color, lit: Double, a: Double, stemTop: Double, boost: Double = 0, hue: Color? = nil) {
    // `hue`: an optional resting colour for the bulb edge, tint and glyph (colour pass); nil keeps the chalk ink.
    let base = hue ?? ink, tint = hue == nil ? 0.1 : 0.12, boostTint = hue == nil ? 0.12 : 0.05
    bpGroup(&c, alpha: a) { g in
        var stem = Path(); stem.move(to: BP.pt(ctr.x, stemTop)); stem.addLine(to: BP.pt(ctr.x, ctr.y - 6))
        g.stroke(stem, with: .color(ink.opacity(0.75 + 0.25 * boost)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
        if lit > 0.01 { g.stroke(wtOval(ctr, 10.5, 10.5), with: .color(acc.opacity(0.5 * lit)), lineWidth: BP.hair) }
        let bulb = wtOval(ctr, 6, 6)
        g.fill(bulb, with: .color(BP.paper)); g.fill(bulb, with: .color(base.opacity(tint + boostTint * boost))); g.fill(bulb, with: .color(acc.opacity(0.18 * lit)))
        g.stroke(bulb, with: .color(base.opacity((1 - lit) * (0.85 + 0.15 * boost))), lineWidth: BP.edge)
        g.stroke(bulb, with: .color(acc.opacity(lit)), lineWidth: BP.edge)
        var glyph = Path()
        switch kind {
        case .cold:
            for deg in [90.0, 30.0, -30.0] {
                let r = deg * Double.pi / 180
                glyph.move(to: BP.pt(ctr.x - 3 * cos(r), ctr.y - 3 * sin(r))); glyph.addLine(to: BP.pt(ctr.x + 3 * cos(r), ctr.y + 3 * sin(r)))
            }
        case .warm:
            glyph.addEllipse(in: CGRect(x: ctr.x - 2, y: ctr.y - 2, width: 4, height: 4))
        case .touch:
            glyph.move(to: BP.pt(ctr.x, ctr.y - 3)); glyph.addLine(to: BP.pt(ctr.x, ctr.y + 2.6))
            wtHead(&glyph, BP.pt(ctr.x, ctr.y - 1), BP.pt(ctr.x, ctr.y + 3), 3)
        }
        let style = StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round)
        g.stroke(glyph, with: .color(base.opacity(1 - lit)), style: style)
        g.stroke(glyph, with: .color(acc.opacity(lit)), style: style)
    }
}

/// A brain icon: a rounded body, a centre fissure and a few folds. `glow` 0...1 fills it mustard.
private func wtBrain(_ c: inout GraphicsContext, _ ctr: CGPoint, ink: Color, acc: Color, glow: Double, a: Double, hue: Color? = nil) {
    // `hue`: an optional resting colour for the brain's edge and tint (colour pass); nil keeps the chalk ink.
    let base = hue ?? ink, tint = hue == nil ? 0.1 : 0.12
    bpGroup(&c, alpha: a) { g in
        let body = wtOval(ctr, 24, 19)
        g.fill(body, with: .color(BP.paper)); g.fill(body, with: .color(base.opacity(tint))); g.fill(body, with: .color(acc.opacity(0.18 * glow)))
        g.stroke(body, with: .color(base.opacity(1 - glow)), lineWidth: BP.edge)
        g.stroke(body, with: .color(acc.opacity(glow)), lineWidth: BP.edge + 0.4)
        var f = Path()
        f.move(to: BP.pt(ctr.x, ctr.y - 18)); f.addCurve(to: BP.pt(ctr.x, ctr.y + 18), control1: BP.pt(ctr.x - 5, ctr.y - 6), control2: BP.pt(ctr.x + 5, ctr.y + 6))
        for s in [-1.0, 1.0] {
            f.move(to: BP.pt(ctr.x + s * 19, ctr.y - 4)); f.addQuadCurve(to: BP.pt(ctr.x + s * 7, ctr.y - 8), control: BP.pt(ctr.x + s * 13, ctr.y - 14))
            f.move(to: BP.pt(ctr.x + s * 18, ctr.y + 6)); f.addQuadCurve(to: BP.pt(ctr.x + s * 6, ctr.y + 9), control: BP.pt(ctr.x + s * 12, ctr.y + 1))
        }
        g.stroke(f, with: .color(ink.opacity(0.7)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
    }
}

/// A drop of water sitting on the skin: a flat base and a domed top.
private func wtDrop(cx: Double, base: Double) -> Path {
    var p = Path(); p.move(to: BP.pt(cx - 30, base))
    p.addCurve(to: BP.pt(cx + 30, base), control1: BP.pt(cx - 30, base - 52), control2: BP.pt(cx + 30, base - 52))
    p.closeSubpath()
    return p
}

private func wtDrawDrop(_ c: inout GraphicsContext, cx: Double, base: Double, ink: Color, a: Double, tint: Color? = nil) {
    bpGroup(&c, alpha: a) { g in
        let d = wtDrop(cx: cx, base: base)
        g.fill(d, with: .color(BP.paper)); g.fill(d, with: .color((tint ?? ink).opacity(tint == nil ? 0.14 : 0.16)))
        g.stroke(d, with: .color(tint ?? ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        var shine = Path(); shine.move(to: BP.pt(cx - 18, base - 14)); shine.addQuadCurve(to: BP.pt(cx - 8, base - 28), control: BP.pt(cx - 18, base - 24))
        g.stroke(shine, with: .color(ink.opacity(0.55)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
    }
}

// MARK: - Shared scene for cards 2 and 3

private enum WtScene {
    static let skinX0 = 16.0, skinX1 = 268.0, skinTop = 178.0, skinBot = 214.0
    static let dropX = 150.0
    static let coldSensor = BP.pt(128, 228), touchSensor = BP.pt(172, 228)
    static let brain = BP.pt(292, 100)
    static let coldNerve = [BP.pt(128, 234), BP.pt(128, 252), BP.pt(300, 252), BP.pt(300, 118)]
    static let touchNerve = [BP.pt(172, 234), BP.pt(172, 240), BP.pt(284, 240), BP.pt(284, 118)]
    static let speed = 190.0     // points per second along a nerve
}

// MARK: - Card 1: no sensor made just for wet

struct WetBPSensors: View {
    let active: Bool
    private static let story = 3.8

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.6,
                       label: "A patch of skin seen from the side, with three tiny sensors under it labelled cold sensor, warm sensor and touch sensor. The cold sensor is pale, the touch sensor peach and the warm sensor plain chalk. A fourth slot, drawn dashed in mustard, is labelled no sensor just for wet and stays empty.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, wtCycle(t, clock, story: Self.story)) }, size: wtSize)
    }

    private static let xs = [48.0, 102.0, 156.0], slotX = 210.0, sy = 188.0
    private static let kinds: [WtKind] = [.cold, .warm, .touch]
    private static let names = ["COLD SENSOR", "WARM SENSOR", "TOUCH SENSOR"]
    private static let elbows = [268.0, 244.0, 220.0]
    private static let hues: [Color?] = [BP.Hue.ice, nil, BP.Hue.peach]   // cold, warm (chalk), touch

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.6))
        let loopLen = story + 1.5
        let x0 = 16.0, x1 = 327.0, top = 130.0, bot = 170.0

        wtSkin(&c, x0: x0, x1: x1, top: top, bot: bot, ink: ink, a: a0)

        // the loop shimmer: a faint light band sweeps across the skin and the sensors during the hold
        let sp = BP.pr(u, story, story + 1.1)
        let env = sin(Double.pi * sp)
        let bx = BP.mix(-20, 363, sp)
        if env > 0.01 {
            var g = c
            g.clip(to: Path(CGRect(x: x0, y: top, width: x1 - x0, height: bot - top)))
            g.fill(wtPoly([BP.pt(bx - 14, top), BP.pt(bx + 26, top), BP.pt(bx + 12, bot), BP.pt(bx - 28, bot)]), with: .color(ink.opacity(0.14 * env)))
        }

        for i in 0..<3 {
            let s = 0.6 + 0.5 * Double(i)
            let boost = env * max(0, 1 - abs(xs[i] - bx) / 40)
            wtSensor(&c, BP.pt(xs[i], sy), kind: kinds[i], ink: ink, acc: acc, lit: 0, a: BP.eout(BP.pr(t, s, s + 0.4)), stemTop: bot, boost: boost, hue: hues[i])
            bpLeader(&c, anchor: BP.pt(xs[i], sy + 7), elbow: BP.pt(xs[i], elbows[i]), tail: 10, text: names[i], ink: hues[i] ?? ink, p: BP.pr(t, s + 0.2, s + 0.9))
        }

        // the fourth slot: dashed, mustard, empty; its outline gently pulses
        let pulse = 0.5 + 0.5 * sin(2 * Double.pi * u / (loopLen / 2))
        let sa = BP.pr(t, 2.3, 2.9)
        if sa > 0.01 {
            let slot = wtOval(BP.pt(slotX, sy), 7 + 0.9 * pulse, 7 + 0.9 * pulse)
            c.stroke(slot, with: .color(acc.opacity(sa * (0.55 + 0.45 * pulse))), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, dash: [3, 3]))
            var stem = Path(); stem.move(to: BP.pt(slotX, bot)); stem.addLine(to: BP.pt(slotX, sy - 8))
            c.stroke(stem, with: .color(acc.opacity(sa * 0.6)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, dash: [2, 3]))
        }
        bpLeader(&c, anchor: BP.pt(slotX + 9, sy), elbow: BP.pt(slotX + 20, sy), tail: 6, text: "NO SENSOR\nJUST FOR WET", ink: acc, p: BP.pr(t, 2.7, 3.4))

        bpLeader(&c, anchor: BP.pt(290, 152), elbow: BP.pt(290, 108), tail: -10, text: "SKIN", ink: ink, p: BP.pr(t, 0.3, 1.0))
    }
}

// MARK: - Card 2: water takes heat out of the skin and the cold sensor notices

struct WetBPCold: View {
    let active: Bool
    private static let story = 5.4
    private static let dur = wtLength(WtScene.coldNerve) / WtScene.speed
    private static let starts = [1.7, 3.5]

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: Self.starts[0],
                       label: "A drop of water on skin. Heat arrows leave the skin into the drop, the cold sensor under the skin lights up, and a mustard cold signal travels up a nerve to a brain.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, wtCycle(t, clock, story: Self.story)) }, size: wtSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = wtFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))
        let base = WtScene.skinTop, cx = WtScene.dropX

        wtSkin(&c, x0: WtScene.skinX0, x1: WtScene.skinX1, top: base, bot: WtScene.skinBot, ink: ink, a: a0)
        wtDrawDrop(&c, cx: cx, base: base, ink: ink, a: BP.eout(BP.pr(t, 0.2, 0.8)), tint: BP.Hue.ice)

        // the nerve, and the part the signal has already lit
        let nerve = wtPoly(WtScene.coldNerve)
        bpTrace(&c, nerve, p: BP.pr(t, 0.8, 1.6), color: ink.opacity(0.5), width: BP.hair)
        let arrive = starts.map { $0 + dur }
        let k1 = BP.pr(u, starts[0], arrive[0]), k2 = BP.pr(u, starts[1], arrive[1])
        bpGroup(&c, alpha: fo) { g in bpTrace(&g, nerve, p: k1, color: acc.opacity(0.75), width: BP.edge) }

        // heat leaves the skin into the drop: little arrows flow up and keep coming
        bpGroup(&c, alpha: fo * BP.pr(u, 0.5, 0.9)) { g in
            for (i, x) in [136.0, 150.0, 164.0].enumerated() {
                let ph = ((u - 0.5) / 1.1 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                let head = BP.mix(208, 164, ph), tail = min(208, head + 14)
                var ar = Path(); ar.move(to: BP.pt(x, tail)); ar.addLine(to: BP.pt(x, head))
                wtHead(&ar, BP.pt(x, tail), BP.pt(x, head), 4.5)
                g.stroke(ar, with: .color(BP.Hue.coral.opacity(sin(Double.pi * ph))), style: StrokeStyle(lineWidth: BP.hair + 0.3, lineCap: .round, lineJoin: .round))
            }
        }

        // the cold sensor lights, the brain takes the signal
        let lit = BP.pr(u, 1.2, 1.6) * fo
        wtSensor(&c, WtScene.coldSensor, kind: .cold, ink: ink, acc: acc, lit: lit, a: a0, stemTop: WtScene.skinBot, hue: BP.Hue.ice)
        let bump = arrive.map { u >= $0 ? 1 - BP.pr(u, $0, $0 + 0.6) : 0 }.max() ?? 0
        let glow = (0.45 * BP.pr(u, arrive[0], arrive[0] + 0.3) + 0.55 * bump) * fo
        wtBrain(&c, WtScene.brain, ink: ink, acc: acc, glow: glow, a: BP.eout(BP.pr(t, 0.4, 1.0)))
        bpText(&c, "YOUR BRAIN", BP.pt(292, 64), ink: ink, alpha: BP.pr(t, 0.9, 1.4))

        bpGroup(&c, alpha: fo) { g in
            wtPulse(&g, WtScene.coldNerve, k: k1, color: acc)
            wtPulse(&g, WtScene.coldNerve, k: k2, color: acc)
            for ar in arrive { wtRing(&g, WtScene.brain, r: 24, k: BP.pr(u, ar, ar + 0.6), color: acc) }
        }
        bpText(&c, "COLD SIGNAL", BP.pt(214, 266), ink: acc, alpha: BP.pr(u, starts[0], starts[0] + 0.4) * fo)

        bpLeader(&c, anchor: BP.pt(136, 168), elbow: BP.pt(104, 152), tail: -6, text: "HEAT OUT", ink: BP.Hue.coral, p: BP.pr(t, 0.9, 1.6))
        bpLeader(&c, anchor: BP.pt(170, 158), elbow: BP.pt(200, 138), tail: 8, text: "WATER", ink: BP.Hue.ice, p: BP.pr(t, 0.7, 1.4))
        bpLeader(&c, anchor: BP.pt(121, 228), elbow: BP.pt(112, 228), tail: -6, text: "COLD SENSOR", ink: BP.Hue.ice, p: BP.pr(t, 1.1, 1.8))
    }
}

// MARK: - Card 3: cold and a close, even touch join into wet

struct WetBPTouch: View {
    let active: Bool
    private static let story = 4.0
    private static let coldStart = 0.9, touchStart = 1.5

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.7,
                       label: "The same drop on skin gives a close, even touch along its base. A touch sensor lights beside the cold sensor. The pale cold signal and the peach touch signal travel up their nerves to the brain and join into the word wet.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, wtCycle(t, clock, story: Self.story)) }, size: wtSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = wtFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))
        let base = WtScene.skinTop, cx = WtScene.dropX

        wtSkin(&c, x0: WtScene.skinX0, x1: WtScene.skinX1, top: base, bot: WtScene.skinBot, ink: ink, a: a0)
        wtDrawDrop(&c, cx: cx, base: base, ink: ink, a: BP.eout(BP.pr(t, 0.2, 0.8)), tint: BP.Hue.ice)

        // the close, even touch: small even ticks along the base of the drop
        for i in 0..<8 {
            let x = 122.0 + 8.0 * Double(i)
            var tk = Path(); tk.move(to: BP.pt(x, base - 3)); tk.addLine(to: BP.pt(x, base + 6))
            c.stroke(tk, with: .color(BP.Hue.peach.opacity(BP.pr(t, 0.7 + 0.06 * Double(i), 0.9 + 0.06 * Double(i)))), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
        }

        // both nerves and both signals
        let coldN = wtPoly(WtScene.coldNerve), touchN = wtPoly(WtScene.touchNerve)
        bpTrace(&c, coldN, p: BP.pr(t, 0.8, 1.6), color: ink.opacity(0.5), width: BP.hair)
        bpTrace(&c, touchN, p: BP.pr(t, 0.9, 1.6), color: ink.opacity(0.5), width: BP.hair)
        let coldDur = wtLength(WtScene.coldNerve) / WtScene.speed, touchDur = wtLength(WtScene.touchNerve) / WtScene.speed
        let kc = BP.pr(u, coldStart, coldStart + coldDur), kt = BP.pr(u, touchStart, touchStart + touchDur)
        let arrive = max(coldStart + coldDur, touchStart + touchDur)
        bpGroup(&c, alpha: fo) { g in
            bpTrace(&g, coldN, p: kc, color: BP.Hue.ice.opacity(0.85), width: BP.edge)
            bpTrace(&g, touchN, p: kt, color: BP.Hue.peach.opacity(0.85), width: BP.edge)
        }

        // sensors: the cold sensor lights first, then the touch sensor beside it
        wtSensor(&c, WtScene.coldSensor, kind: .cold, ink: ink, acc: BP.Hue.ice, lit: BP.pr(u, 0.5, 0.9) * fo, a: a0, stemTop: WtScene.skinBot, hue: BP.Hue.ice)
        wtSensor(&c, WtScene.touchSensor, kind: .touch, ink: ink, acc: BP.Hue.peach, lit: BP.pr(u, 1.1, 1.5) * fo, a: BP.eout(BP.pr(t, 0.3, 0.8)), stemTop: WtScene.skinBot, hue: BP.Hue.peach)

        // the brain takes both, and the word wet appears beside it
        let bump = u >= arrive ? 1 - BP.pr(u, arrive, arrive + 0.6) : 0
        let glow = (0.45 * BP.pr(u, arrive, arrive + 0.3) + 0.55 * bump) * fo
        wtBrain(&c, WtScene.brain, ink: ink, acc: acc, glow: glow, a: BP.eout(BP.pr(t, 0.4, 1.0)))
        bpText(&c, "YOUR BRAIN", BP.pt(292, 64), ink: ink, alpha: BP.pr(t, 0.9, 1.4))
        bpGroup(&c, alpha: fo) { g in
            wtPulse(&g, WtScene.coldNerve, k: kc, color: BP.Hue.ice)
            wtPulse(&g, WtScene.touchNerve, k: kt, color: BP.Hue.peach)
            wtRing(&g, WtScene.brain, r: 24, k: BP.pr(u, arrive, arrive + 0.6), color: acc)
        }
        let wa = BP.eout(BP.pr(u, arrive + 0.2, arrive + 0.7)) * fo
        if wa > 0.01 {
            var join = Path(); join.move(to: BP.pt(264, 100)); join.addLine(to: BP.pt(250, 100))
            c.stroke(join, with: .color(acc.opacity(wa)), style: StrokeStyle(lineWidth: BP.hair + 0.3, lineCap: .round, dash: [2, 3]))
            c.draw(c.resolve(Text("WET").font(T.mono(24)).tracking(2).foregroundColor(acc.opacity(wa))), at: BP.pt(222, 100), anchor: .center)
        }
        bpText(&c, "COLD SIGNAL", BP.pt(214, 266), ink: BP.Hue.ice, alpha: BP.pr(u, coldStart, coldStart + 0.4) * fo)

        bpLeader(&c, anchor: BP.pt(124, base + 2), elbow: BP.pt(98, 160), tail: -6, text: "CLOSE,\nEVEN TOUCH", ink: BP.Hue.peach, p: BP.pr(t, 0.9, 1.6))
        bpLeader(&c, anchor: BP.pt(178, 228), elbow: BP.pt(186, 228), tail: 4, text: "TOUCH SENSOR", ink: BP.Hue.peach, p: BP.pr(t, 1.2, 1.9))
    }
}

// MARK: - Card 4: a dry finger in a thin rubber sheath feels wet

struct WetBPSheath: View {
    let active: Bool
    private static let story = 9.0
    private static let gx = [56.0, 152.0, 248.0]
    private static let glassTop = 190.0, glassBot = 262.0, level = 212.0
    private static let hoverY = 150.0, dipY = 244.0

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.0,
                       label: "A dry finger in a thin rubber sheath dips into a glass of water, and a yellow tag, feels wet, lights bright. The finger then moves across to a second glass, tagged warmer, less wet and dimmer, and a third, tagged lukewarm, barely, barely lit.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, wtCycle(t, clock, story: Self.story)) }, size: wtSize)
    }

    private static func half(_ y: Double) -> Double { 28 - 4 * (y - glassTop) / (glassBot - glassTop) }

    private static func glass(_ c: inout GraphicsContext, _ cx: Double, ink: Color, a: Double) {
        bpGroup(&c, alpha: a) { g in
            let water = wtPoly([BP.pt(cx - half(level), level), BP.pt(cx + half(level), level), BP.pt(cx + half(glassBot), glassBot), BP.pt(cx - half(glassBot), glassBot)])
            g.fill(water, with: .color(BP.Hue.ice.opacity(0.16)))
            var surf = Path(); surf.move(to: BP.pt(cx - half(level), level)); surf.addLine(to: BP.pt(cx + half(level), level))
            g.stroke(surf, with: .color(BP.Hue.ice), lineWidth: BP.hair + 0.2)
            var body = wtPoly([BP.pt(cx - half(glassTop), glassTop), BP.pt(cx - half(glassBot), glassBot), BP.pt(cx + half(glassBot), glassBot), BP.pt(cx + half(glassTop), glassTop)])
            body.move(to: BP.pt(cx - half(glassTop) - 2, glassTop)); body.addLine(to: BP.pt(cx - half(glassTop), glassTop))
            body.move(to: BP.pt(cx + half(glassTop), glassTop)); body.addLine(to: BP.pt(cx + half(glassTop) + 2, glassTop))
            g.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, lineJoin: .round))
        }
    }

    /// The finger (solid inner outline) inside a thin rubber sheath (a slightly bigger, offset outline that reaches a little past the tip
    /// and flares into a cuff at the top).
    private static func finger(_ c: inout GraphicsContext, tip: CGPoint, ink: Color, a: Double) {
        bpGroup(&c, alpha: a) { g in
            let top = tip.y - 90
            var sheath = Path()
            sheath.move(to: BP.pt(tip.x - 9.5, top - 6)); sheath.addLine(to: BP.pt(tip.x - 9.5, tip.y - 4))
            sheath.addQuadCurve(to: BP.pt(tip.x + 9.5, tip.y - 4), control: BP.pt(tip.x, tip.y + 14))
            sheath.addLine(to: BP.pt(tip.x + 9.5, top - 6))
            g.fill(sheath, with: .color(BP.paper)); g.fill(sheath, with: .color(BP.Hue.peach.opacity(0.14)))
            g.stroke(sheath, with: .color(BP.Hue.peach), style: StrokeStyle(lineWidth: BP.hair + 0.3, lineCap: .round, lineJoin: .round))
            var cuff = Path(); cuff.move(to: BP.pt(tip.x - 12.5, top - 8)); cuff.addQuadCurve(to: BP.pt(tip.x - 9.5, top - 6), control: BP.pt(tip.x - 11, top - 6))
            cuff.move(to: BP.pt(tip.x + 12.5, top - 8)); cuff.addQuadCurve(to: BP.pt(tip.x + 9.5, top - 6), control: BP.pt(tip.x + 11, top - 6))
            g.stroke(cuff, with: .color(BP.Hue.peach), style: StrokeStyle(lineWidth: BP.hair + 0.3, lineCap: .round))
            var inner = Path()
            inner.move(to: BP.pt(tip.x - 6, top)); inner.addLine(to: BP.pt(tip.x - 6, tip.y - 6))
            inner.addQuadCurve(to: BP.pt(tip.x + 6, tip.y - 6), control: BP.pt(tip.x, tip.y + 6))
            inner.addLine(to: BP.pt(tip.x + 6, top))
            g.fill(inner, with: .color(ink.opacity(0.1)))
            g.stroke(inner, with: .color(ink), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round))
        }
    }

    /// A tag under a glass: dim chalk until its moment, then lit mustard at `level` (1 bright, lower dimmer).
    private static func tag(_ c: inout GraphicsContext, _ ctr: CGPoint, lines: [String], w: Double, level: Double, ink: Color, acc: Color, a: Double) {
        guard a > 0.01 else { return }
        let h = lines.count == 1 ? 22.0 : 32.0
        let box = Path(roundedRect: CGRect(x: ctr.x - w / 2, y: ctr.y - h / 2, width: w, height: h), cornerRadius: 5)
        c.fill(box, with: .color(BP.paper.opacity(a))); c.fill(box, with: .color(acc.opacity(0.18 * level * a)))
        if level > 0.9 {
            let halo = Path(roundedRect: CGRect(x: ctr.x - w / 2 - 3, y: ctr.y - h / 2 - 3, width: w + 6, height: h + 6), cornerRadius: 7)
            c.stroke(halo, with: .color(acc.opacity(0.4 * a)), lineWidth: BP.hair)
        }
        c.stroke(box, with: .color(acc.opacity((0.35 + 0.65 * level) * a)), lineWidth: BP.edge)
        for (i, l) in lines.enumerated() {
            bpText(&c, l, BP.pt(ctr.x, ctr.y + (Double(i) - Double(lines.count - 1) / 2) * 13), ink: acc, alpha: (0.45 + 0.55 * level) * a)
        }
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = wtFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.6))

        for x in gx { glass(&c, x, ink: ink, a: a0) }
        bpLeader(&c, anchor: BP.pt(268, 222), elbow: BP.pt(268, 176), tail: 8, text: "WATER", ink: BP.Hue.ice, p: BP.pr(t, 0.4, 1.1))

        // where the finger is: down into the first glass, out, across, down into the second, out, across, down into the third
        let dip = BP.eio(BP.pr(u, 0.8, 1.8)) - BP.eio(BP.pr(u, 3.9, 4.5)) + BP.eio(BP.pr(u, 5.1, 5.8)) - BP.eio(BP.pr(u, 6.6, 7.2)) + BP.eio(BP.pr(u, 7.8, 8.5))
        let tip = BP.pt(gx[0] + 96 * BP.eio(BP.pr(u, 4.3, 5.1)) + 96 * BP.eio(BP.pr(u, 7.0, 7.8)), hoverY + (dipY - hoverY) * dip)
        let fa = BP.pr(u, 0.1, 0.5) * fo
        finger(&c, tip: tip, ink: ink, a: fa)
        let wet = BP.pr(tip.y + 5, level, level + 10)
        if wet > 0.01 { c.stroke(wtOval(BP.pt(tip.x, level), 14, 3), with: .color(BP.Hue.ice.opacity(0.8 * wet * fa)), lineWidth: BP.hair) }

        // while the finger is in the first glass: what each part is
        let gl = (1 - BP.pr(u, 3.9, 4.3)) * fo
        bpGroup(&c, alpha: gl) { g in
            bpLeader(&g, anchor: BP.pt(gx[0], 172), elbow: BP.pt(82, 146), tail: 8, text: "DRY FINGER", ink: ink, p: BP.pr(u, 2.0, 2.7))
            bpLeader(&g, anchor: BP.pt(gx[0] + 9.5, 184), elbow: BP.pt(88, 170), tail: 8, text: "THIN RUBBER SHEATH", ink: BP.Hue.peach, p: BP.pr(u, 2.2, 2.9))
        }

        // tags light in turn: bright, dimmer, barely
        let ty = 287.0
        tag(&c, BP.pt(gx[0], ty), lines: ["FEELS WET"], w: 76, level: 1.0, ink: ink, acc: acc, a: BP.pr(u, 1.8, 2.2) * fo)
        tag(&c, BP.pt(gx[1], ty), lines: ["WARMER:", "LESS WET"], w: 70, level: 0.55, ink: ink, acc: acc, a: BP.pr(u, 5.8, 6.1) * fo)
        tag(&c, BP.pt(gx[2], ty), lines: ["LUKEWARM:", "BARELY"], w: 74, level: 0.25, ink: ink, acc: acc, a: BP.pr(u, 8.5, 8.8) * fo)
    }
}
