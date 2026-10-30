import SwiftUI

// "Why does one gear click make the same hill feel easier?" pictures, drawn as blueprint technical illustrations (2026-10-28).
// Cards 1, 2, 3 and 5 draw the same bike, chain and rings from one shared helper (bgBike): a side-on cutaway with a pedal ring, a stack of
// three back rings (biggest first), a chain that really runs round whichever ring it sits on, and a rider (cards 1 and 5) made from bpPerson.
// One chalk-ink colour, one mustard accent per card (the gear lever, the moved stretch of chain, the long distance, the height line, the
// force arrow), thin even lines, flat tints, mono uppercase labels that use the slide's own words. Every picture loops ambiently: it plays,
// holds its end beat for about a second, then the whole picture fades and starts again. Tap restarts, Reduce Motion shows the held end state.
// Drawn in a 343 x 340 design space; keep clear of the bottom-right corner (x > 285, y > 255).

private let bgSize = CGSize(width: 343, height: 340)
private let bgRingR: [Double] = [0.46, 0.345, 0.23]     // back rings, in wheel radii, biggest first: ratio 1 : 1.33 : 2 to the pedal ring
private let bgRa = 0.46                                  // the pedal ring, in wheel radii
private let bgCrankLen = 0.56                            // crank arm, in wheel radii
private let bgTau = 2 * Double.pi

// MARK: - Small helpers

/// Ambient loop time: the story ends at `story`, the loop lasts `story + extra`. Reduce Motion (the clock stands still behind `t`) shows the held end.
private func bgCycle(_ t: Double, _ clock: Double, story: Double, extra: Double = 1.5) -> Double {
    if clock < t { return story }
    return clock.truncatingRemainder(dividingBy: story + extra)
}

/// Whole-picture fade: in over the first third of a second, held, out over the last half second of the loop.
private func bgAlpha(_ u: Double, _ story: Double) -> Double { BP.pr(u, 0, 0.35) * (1 - BP.pr(u, story + 1.0, story + 1.5)) }

/// Integral of `f` from 0 to `u` (Simpson), for angles that follow a changing speed.
private func bgInt(_ u: Double, _ f: (Double) -> Double) -> Double {
    guard u > 0 else { return 0 }
    let n = 48, h = u / Double(n)
    var s = f(0) + f(u)
    for i in 1..<n { s += f(Double(i) * h) * (i % 2 == 0 ? 2 : 4) }
    return s * h / 3
}

private func bgFrac(_ x: Double) -> Double { x - x.rounded(.down) }

/// Radius of the back ring the chain sits on, in wheel radii: `shift` 0 is the biggest, 1 the smallest (the middle ring is half way).
private func bgRingRadius(_ shift: Double) -> Double {
    let k = BP.cl(shift) * 2
    return k < 1 ? BP.mix(bgRingR[0], bgRingR[1], k) : BP.mix(bgRingR[1], bgRingR[2], k - 1)
}

private func bgOval(_ ctr: CGPoint, _ r: Double) -> Path { Path(ellipseIn: CGRect(x: ctr.x - r, y: ctr.y - r, width: 2 * r, height: 2 * r)) }

private func bgArrow(_ c: inout GraphicsContext, from a: CGPoint, to b: CGPoint, color: Color, width: Double, alpha: Double = 1) {
    let len = hypot(b.x - a.x, b.y - a.y)
    guard len > 1, alpha > 0.01 else { return }
    let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len, h = min(6.5, len * 0.7)
    var p = Path(); p.move(to: a); p.addLine(to: b)
    p.move(to: BP.pt(b.x - ux * h - uy * 3.4, b.y - uy * h + ux * 3.4)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * h + uy * 3.4, b.y - uy * h - ux * 3.4))
    c.stroke(p, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
}

// MARK: - The chain: a closed belt round the pedal ring (right) and one back ring (left)

private struct BgLoop {
    let A: CGPoint, B: CGPoint, ra: Double, rb: Double
    let nTop: Double, sweepA: Double, sweepB: Double, ell: Double, L: Double

    init(a: CGPoint, ra: Double, b: CGPoint, rb: Double) {
        A = a; B = b; self.ra = ra; self.rb = rb
        let d = hypot(b.x - a.x, b.y - a.y)
        let psi = atan2(b.y - a.y, b.x - a.x)
        let kappa = acos(max(-1, min(1, (ra - rb) / d)))
        let c1 = psi + kappa, c2 = psi - kappa
        let top = sin(c1) < sin(c2) ? c1 : c2
        let bot = sin(c1) < sin(c2) ? c2 : c1
        func md(_ x: Double) -> Double { let m = x.truncatingRemainder(dividingBy: 2 * Double.pi); return m < 0 ? m + 2 * Double.pi : m }
        nTop = top
        sweepA = md(bot - top)
        sweepB = md(top - bot)
        ell = sqrt(max(0, d * d - (ra - rb) * (ra - rb)))
        L = 2 * ell + ra * md(bot - top) + rb * md(top - bot)
    }

    /// The point `s0` along the chain, travelling the way the chain runs: along the top towards the pedal ring, round its front, back along the bottom.
    func pos(_ s0: Double) -> CGPoint {
        var s = s0.truncatingRemainder(dividingBy: L)
        if s < 0 { s += L }
        let nBot = nTop + sweepA
        if s < ell {
            let a = BP.pt(B.x + rb * cos(nTop), B.y + rb * sin(nTop)), b = BP.pt(A.x + ra * cos(nTop), A.y + ra * sin(nTop))
            return BP.mixp(a, b, s / max(ell, 0.001))
        }
        s -= ell
        if s < ra * sweepA {
            let th = nTop + s / ra
            return BP.pt(A.x + ra * cos(th), A.y + ra * sin(th))
        }
        s -= ra * sweepA
        if s < ell {
            let a = BP.pt(A.x + ra * cos(nBot), A.y + ra * sin(nBot)), b = BP.pt(B.x + rb * cos(nBot), B.y + rb * sin(nBot))
            return BP.mixp(a, b, s / max(ell, 0.001))
        }
        s -= ell
        let th = nBot + s / rb
        return BP.pt(B.x + rb * cos(th), B.y + rb * sin(th))
    }

    func path() -> Path {
        var p = Path()
        let step = 1.6
        p.move(to: pos(0))
        var s = step
        while s < L { p.addLine(to: pos(s)); s += step }
        p.closeSubpath()
        return p
    }

    /// The stretch from `s0` for `len` points, as a polyline.
    func stretch(from s0: Double, len: Double) -> Path {
        var p = Path()
        guard len > 0.5 else { return p }
        p.move(to: pos(s0))
        var s = 1.6
        while s < len { p.addLine(to: pos(s0 + s)); s += 1.6 }
        p.addLine(to: pos(s0 + len))
        return p
    }
}

// MARK: - The shared bike

/// Where the bike stands and how every moving part is turned. Units are wheel radii from the rear axle `o`; y runs down.
private struct BgRig {
    var o: CGPoint
    var R: Double
    var wheel = 0.0         // wheel turn, radians clockwise
    var crank = 0.0         // pedal turn, radians clockwise from "up"
    var shift = 0.0         // 0 = chain on the biggest back ring, 1 = on the smallest
    var travel = 0.0        // how far the chain has run, in points (moves the links)
    var frame = true        // false: a cutaway of just wheel, rings, chain and pedals
    func p(_ x: Double, _ y: Double) -> CGPoint { BP.pt(o.x + x * R, o.y + y * R) }
    var bb: CGPoint { p(1.12, 0.14) }
    var front: CGPoint { p(2.7, 0) }
    var grip: CGPoint { p(2.30, -1.10) }
    var hip: CGPoint { p(0.78, -1.17) }
    var leverPos: CGPoint { p(2.16, -1.22) }
    func pedal(_ extra: Double) -> CGPoint {
        let a = crank + extra
        return BP.pt(bb.x + bgCrankLen * R * sin(a), bb.y - bgCrankLen * R * cos(a))
    }
    var pitch: Double { max(3.0, R * 0.075) }
    var tooth: Double { pitch * 0.5 }
    var chainW: Double { max(1.8, R * 0.05) }
    /// The chain as it runs now.
    var loop: BgLoop {
        BgLoop(a: bb, ra: bgRa * R + tooth * 0.5, b: o, rb: bgRingRadius(shift) * R + tooth * 0.5)
    }
}

private func bgWheel(_ c: inout GraphicsContext, _ ctr: CGPoint, _ R: Double, rot: Double, ink: Color) {
    let disc = bgOval(ctr, R)
    c.fill(disc, with: .color(BP.paper)); c.fill(disc, with: .color(ink.opacity(0.05)))
    c.stroke(disc, with: .color(ink), lineWidth: BP.edge)
    let ri = R * 0.88
    c.stroke(bgOval(ctr, ri), with: .color(ink.opacity(0.55)), lineWidth: BP.hair)
    var sp = Path()
    for k in 0..<8 {
        let a = rot + Double(k) * Double.pi / 4
        sp.move(to: ctr); sp.addLine(to: BP.pt(ctr.x + ri * cos(a), ctr.y + ri * sin(a)))
    }
    c.stroke(sp, with: .color(ink.opacity(0.35)), lineWidth: BP.hair)
    // one marked spoke, so every wheel turn can be counted
    let am = rot - Double.pi / 2
    var m = Path()
    m.move(to: BP.pt(ctr.x + R * 0.62 * cos(am), ctr.y + R * 0.62 * sin(am)))
    m.addLine(to: BP.pt(ctr.x + ri * cos(am), ctr.y + ri * sin(am)))
    c.stroke(m, with: .color(ink), style: StrokeStyle(lineWidth: max(1.6, R * 0.035), lineCap: .round))
    c.fill(bgOval(ctr, max(1.4, R * 0.06)), with: .color(ink))
}

private func bgRing(_ c: inout GraphicsContext, _ ctr: CGPoint, _ r: Double, ang: Double, pitch: Double, tooth: Double, ink: Color, tint: Double) {
    let disc = bgOval(ctr, r)
    c.fill(disc, with: .color(BP.paper)); c.fill(disc, with: .color(ink.opacity(tint)))
    let n = max(8, Int((2 * Double.pi * r / pitch).rounded()))
    var t = Path()
    for k in 0..<n {
        let a = ang + 2 * Double.pi * Double(k) / Double(n)
        t.move(to: BP.pt(ctr.x + r * cos(a), ctr.y + r * sin(a)))
        t.addLine(to: BP.pt(ctr.x + (r + tooth) * cos(a), ctr.y + (r + tooth) * sin(a)))
    }
    c.stroke(t, with: .color(ink), style: StrokeStyle(lineWidth: max(1.0, tooth * 0.9), lineCap: .butt))
    c.stroke(disc, with: .color(ink), lineWidth: BP.hair)
}

private func bgFrame(_ c: inout GraphicsContext, _ g: BgRig, ink: Color) {
    let seat = g.p(0.78, -1.0), head = g.p(2.12, -1.0), headB = g.p(2.24, -0.72)
    var tri = Path(); tri.move(to: seat); tri.addLine(to: head); tri.addLine(to: headB); tri.addLine(to: g.bb); tri.closeSubpath()
    c.fill(tri, with: .color(BP.paper)); c.fill(tri, with: .color(ink.opacity(0.07)))
    var f = Path()
    f.move(to: g.bb); f.addLine(to: seat)                       // seat tube
    f.move(to: seat); f.addLine(to: head)                       // top tube
    f.move(to: headB); f.addLine(to: g.bb)                      // down tube
    f.move(to: head); f.addLine(to: headB)                      // head tube
    f.move(to: headB); f.addLine(to: g.front)                   // fork
    f.move(to: seat); f.addLine(to: g.o)                        // seat stay
    f.move(to: g.bb); f.addLine(to: g.o)                        // chain stay
    f.move(to: seat); f.addLine(to: g.p(0.74, -1.12))           // seat post
    c.stroke(f, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, lineJoin: .round))
    var s = Path()
    s.move(to: g.p(0.58, -1.14)); s.addLine(to: g.p(0.92, -1.14))      // saddle
    c.stroke(s, with: .color(ink), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
    c.fill(bgOval(g.front, max(1.4, g.R * 0.06)), with: .color(ink))
}

/// Handlebar and stem (the lever is drawn separately, after the rider).
private func bgBar(_ c: inout GraphicsContext, _ g: BgRig, ink: Color) {
    var b = Path()
    b.move(to: g.p(2.12, -1.0)); b.addLine(to: g.p(2.07, -1.17))
    b.move(to: g.p(2.07, -1.17)); b.addQuadCurve(to: g.p(2.34, -1.10), control: g.p(2.27, -1.20))
    c.stroke(b, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge + 0.4, lineCap: .round, lineJoin: .round))
}

/// The whole drivetrain and bike. `pulled` is the length of chain (points) already drawn past the gate on the top run, shown in `pulledColor`.
private func bgBike(_ c: inout GraphicsContext, _ g: BgRig, ink: Color, pulled: Double = 0, pulledColor: Color? = nil, pulledAlpha: Double = 1) {
    let R = g.R
    bgWheel(&c, g.o, R, rot: g.wheel, ink: ink)
    if g.frame { bgWheel(&c, g.front, R, rot: g.wheel, ink: ink) }
    // far pedal and crank half sit behind the frame
    if g.frame {
        bgFrame(&c, g, ink: ink)
    } else {
        var s = Path()
        s.move(to: g.bb); s.addLine(to: g.o)
        s.move(to: g.bb); s.addLine(to: g.p(1.0, -0.5))
        c.stroke(s, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
    }
    bgBar(&c, g, ink: ink)
    // the stack of back rings, then the pedal ring
    for (i, r) in bgRingR.enumerated() {
        bgRing(&c, g.o, r * R, ang: g.wheel, pitch: g.pitch, tooth: g.tooth, ink: ink, tint: 0.05 + 0.05 * Double(i))
    }
    bgRing(&c, g.bb, bgRa * R, ang: g.crank, pitch: g.pitch, tooth: g.tooth, ink: ink, tint: 0.08)
    // the chain: a pale band with the links running along it
    let lp = g.loop, w = g.chainW
    let path = lp.path()
    c.stroke(path, with: .color(ink.opacity(0.32)), style: StrokeStyle(lineWidth: w, lineJoin: .round))
    var ph = (-g.travel).truncatingRemainder(dividingBy: g.pitch)
    if ph < 0 { ph += g.pitch }
    c.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: w, lineJoin: .round, dash: [g.pitch * 0.5, g.pitch * 0.5], dashPhase: ph))
    // the stretch pulled past the gate
    if let pc = pulledColor, pulled > 0.5 {
        let sg = lp.ell * 0.45
        c.stroke(lp.stretch(from: sg, len: min(pulled, lp.L - 1)), with: .color(pc.opacity(pulledAlpha)), style: StrokeStyle(lineWidth: w + 2.0, lineCap: .round, lineJoin: .round))
        let q = lp.pos(sg), q2 = lp.pos(sg + 1)
        let dx = q2.x - q.x, dy = q2.y - q.y, dl = max(0.001, hypot(dx, dy))
        var gate = Path()
        gate.move(to: BP.pt(q.x - dy / dl * (w + 3), q.y + dx / dl * (w + 3))); gate.addLine(to: BP.pt(q.x + dy / dl * (w + 3), q.y - dx / dl * (w + 3)))
        c.stroke(gate, with: .color(ink), style: StrokeStyle(lineWidth: BP.hair + 0.3, lineCap: .round))
    }
    // crank and pedals
    let p0 = g.pedal(0), p1 = g.pedal(Double.pi)
    var cr = Path(); cr.move(to: p1); cr.addLine(to: p0)
    c.stroke(cr, with: .color(ink), style: StrokeStyle(lineWidth: max(2.4, R * 0.06), lineCap: .round))
    c.stroke(cr, with: .color(BP.paper), style: StrokeStyle(lineWidth: max(0.8, R * 0.06 - 1.8), lineCap: .round))
    for p in [p1, p0] {
        let pr = max(2.2, R * 0.085)
        c.fill(Path(CGRect(x: p.x - pr, y: p.y - pr * 0.4, width: 2 * pr, height: pr * 0.8)), with: .color(ink))
    }
    c.fill(bgOval(g.bb, max(1.8, R * 0.05)), with: .color(BP.paper))
    c.stroke(bgOval(g.bb, max(1.8, R * 0.05)), with: .color(ink), lineWidth: BP.hair)
    c.fill(bgOval(g.o, max(1.8, R * 0.05)), with: .color(BP.paper))
    c.stroke(bgOval(g.o, max(1.8, R * 0.05)), with: .color(ink), lineWidth: BP.hair)
}

/// The gear lever: a small pod on the handlebar with a paddle that swings when pressed (`pressed` 0...1). `k` exaggerates the size.
private func bgLever(_ c: inout GraphicsContext, _ g: BgRig, k: Double, pressed: Double, color: Color, hi: Bool) {
    let P = g.leverPos, R = g.R
    let w = 0.17 * R * k, h = 0.10 * R * k
    let pod = Path(roundedRect: CGRect(x: P.x - w / 2, y: P.y - h / 2, width: w, height: h), cornerRadius: h * 0.4)
    c.fill(pod, with: .color(BP.paper)); c.fill(pod, with: .color(color.opacity(hi ? 0.9 : 0.3)))
    c.stroke(pod, with: .color(color), lineWidth: BP.edge)
    let ang = BP.mix(100, 138, pressed) * Double.pi / 180, L = 0.22 * R * k
    let st = BP.pt(P.x + w * 0.2, P.y + h / 2)
    var pd = Path(); pd.move(to: st); pd.addLine(to: BP.pt(st.x + L * cos(ang), st.y + L * sin(ang)))
    c.stroke(pd, with: .color(color), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
}

/// A ring that grows and fades round a point: the click.
private func bgRipple(_ c: inout GraphicsContext, _ at: CGPoint, p: Double, r: Double, color: Color) {
    guard p > 0.01, p < 1 else { return }
    c.stroke(bgOval(at, 3 + r * BP.eout(p)), with: .color(color.opacity(1 - p)), lineWidth: BP.hair + 0.2)
}

// MARK: - People: legs that reach a foot, a torso from bpPerson

/// A leg from `hip` to `foot`, knee bent forward (to the right).
private func bgLeg(_ c: inout GraphicsContext, hip: CGPoint, foot: CGPoint, a: Double, b: Double, ink: Color, alpha: Double) {
    let dx = foot.x - hip.x, dy = foot.y - hip.y
    let d = max(0.001, hypot(dx, dy))
    let dc = min(d, a + b - 0.3)
    let ux = dx / d, uy = dy / d
    let x = (dc * dc + a * a - b * b) / (2 * dc)
    let h = sqrt(max(0, a * a - x * x))
    let knee = BP.pt(hip.x + ux * x + uy * h, hip.y + uy * x - ux * h)
    var leg = Path(); leg.move(to: hip); leg.addLine(to: knee); leg.addLine(to: foot)
    bpGroup(&c, alpha: alpha) { g in
        g.stroke(leg, with: .color(ink), style: StrokeStyle(lineWidth: 6.2, lineCap: .round, lineJoin: .round))
        g.stroke(leg, with: .color(BP.paper), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        g.fill(Path(ellipseIn: CGRect(x: foot.x - 3.5, y: foot.y - 1, width: 9, height: 4.6)), with: .color(ink))
    }
}

/// Torso, neck and head of a person in profile (facing right) from bpPerson, tilted forward by `lean` radians about the hip. Returns the shoulder.
@discardableResult
private func bgTorso(_ c: inout GraphicsContext, hip: CGPoint, lean: Double, ink: Color) -> CGPoint {
    var t = c
    t.translateBy(x: hip.x, y: hip.y); t.rotate(by: .radians(lean)); t.translateBy(x: -hip.x, y: -hip.y)
    t.clip(to: Path(CGRect(x: hip.x - 40, y: hip.y - 120, width: 80, height: 118.5)))
    bpPerson(&t, base: hip, facing: 1, ink: ink, shirt: 0.22, hair: 0, talk: false)
    return BP.pt(hip.x + 25 * sin(lean), hip.y - 25 * cos(lean))
}

/// The head centre of that torso.
private func bgHead(hip: CGPoint, lean: Double) -> CGPoint {
    BP.pt(hip.x + 1.5 * cos(lean) + 39.5 * sin(lean), hip.y + 1.5 * sin(lean) - 39.5 * cos(lean))
}

/// A rider on the bike: far leg, torso, near leg, arm to the grip.
private func bgRider(_ c: inout GraphicsContext, _ g: BgRig, lean: Double, ink: Color) {
    let hip = g.hip, leg = g.R * 1.0
    bgLeg(&c, hip: hip, foot: g.pedal(Double.pi), a: leg, b: leg, ink: ink, alpha: 0.6)
    let sh = bgTorso(&c, hip: hip, lean: lean, ink: ink)
    bgLeg(&c, hip: hip, foot: g.pedal(0), a: leg, b: leg, ink: ink, alpha: 1)
    let gr = g.grip
    bpArm(&c, from: sh, elbow: BP.pt((sh.x + gr.x) / 2, (sh.y + gr.y) / 2 + 11), to: gr, ink: ink)
}

// MARK: - Card 1: the same hill, the same legs; one click

struct BikeBPHill: View {
    let active: Bool
    private static let story = 7.6

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.9,
                       label: "A rider on a steep hill, seen from the side, pushes hard on the pedals and barely moves. A finger clicks the gear lever on the handlebar, shown in gold. Then the same rider on the same hill pedals faster and rolls up it. Labels: gear lever, same hill.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, bgCycle(t, clock, story: Self.story)) }, size: bgSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        c.opacity = bgAlpha(u, story)
        let R = 29.0, ang = 22.0 * Double.pi / 180
        let W0 = BP.pt(104, 238)
        let d = BP.pt(cos(ang), -sin(ang)), n = BP.pt(-sin(ang), -cos(ang))
        func world(_ p: CGPoint) -> CGPoint { BP.pt(W0.x + p.x * cos(ang) + p.y * sin(ang), W0.y - p.x * sin(ang) + p.y * cos(ang)) }
        func yS(_ x: Double) -> Double { W0.y - tan(ang) * (x - W0.x) }

        // timeline: the lever clicks at 3.9, the legs then spin faster and the bike rolls up
        let click = 3.9
        let shiftAt: (Double) -> Double = { BP.eio(BP.pr($0, click, click + 0.5)) }
        let rate: (Double) -> Double = { BP.mix(1.15, 3.5, BP.eio(BP.pr($0, 4.2, 5.6))) }
        let crank = bgInt(u, rate)
        let wheel = bgInt(u) { rate($0) * bgRa / bgRingRadius(shiftAt($0)) }
        let dist = wheel * R

        // the hill: a section with hatching, ticks and stakes that slide back as the bike climbs
        let xl = 14.0, xr = 282.0
        var block = Path()
        block.move(to: BP.pt(xl, yS(xl))); block.addLine(to: BP.pt(xr, yS(xr))); block.addLine(to: BP.pt(xr, 290)); block.addLine(to: BP.pt(xl, 290)); block.closeSubpath()
        c.fill(block, with: .color(BP.paper)); c.fill(block, with: .color(ink.opacity(0.07)))
        var h = c
        h.clip(to: block)
        var hatch = Path()
        for i in stride(from: -200.0, to: 300.0, by: 13.0) { hatch.move(to: BP.pt(xl + i, 300)); hatch.addLine(to: BP.pt(xl + i + 170, 130)) }
        h.stroke(hatch, with: .color(ink.opacity(0.12)), lineWidth: BP.hair)
        c.stroke(block, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        var ticks = Path()
        let off28 = dist.truncatingRemainder(dividingBy: 28)
        for k in -6...12 {
            let s = Double(k) * 28 - off28
            let p = BP.pt(W0.x + s * d.x, W0.y + s * d.y)
            guard p.x > xl + 5, p.x < xr - 5 else { continue }
            ticks.move(to: p); ticks.addLine(to: BP.pt(p.x - n.x * 6, p.y - n.y * 6))
        }
        c.stroke(ticks, with: .color(ink.opacity(0.75)), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
        let off130 = dist.truncatingRemainder(dividingBy: 130)
        for k in -1...3 {
            let s = Double(k) * 130 + 150 - off130
            let p = BP.pt(W0.x + s * d.x, W0.y + s * d.y)
            guard p.x > xl + 8, p.x < xr - 8 else { continue }
            let top = BP.pt(p.x + n.x * 18, p.y + n.y * 18)
            var pole = Path(); pole.move(to: p); pole.addLine(to: top)
            c.stroke(pole, with: .color(ink), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
            var pen = Path()
            pen.move(to: top); pen.addLine(to: BP.pt(top.x - d.x * 10 + n.x * -2, top.y - d.y * 10 - n.y * 2)); pen.addLine(to: BP.pt(top.x - n.x * 6, top.y - n.y * 6)); pen.closeSubpath()
            c.fill(pen, with: .color(ink.opacity(0.4))); c.stroke(pen, with: .color(ink), lineWidth: BP.hair)
        }

        // the bike and rider, tilted to the hill
        var b = c
        b.translateBy(x: W0.x, y: W0.y); b.rotate(by: .radians(-ang))
        var rig = BgRig(o: BP.pt(0, -R), R: R)
        rig.wheel = wheel; rig.crank = crank; rig.shift = shiftAt(u); rig.travel = crank * bgRa * R
        let lean = 52.0 * Double.pi / 180
        bgBike(&b, rig, ink: ink)
        bgRider(&b, rig, lean: lean, ink: ink)
        // the effort: lines behind the head, drops that fall off it (the same before and after the click)
        let head = bgHead(hip: rig.hip, lean: lean)
        var fx = Path()
        for i in -1...1 {
            let a = Double.pi + 0.5 * Double(i) - lean * 0.5
            fx.move(to: BP.pt(head.x + 13 * cos(a), head.y + 13 * sin(a))); fx.addLine(to: BP.pt(head.x + 19 * cos(a), head.y + 19 * sin(a)))
        }
        b.stroke(fx, with: .color(ink.opacity(0.55 + 0.35 * sin(u * 9))), style: StrokeStyle(lineWidth: BP.hair + 0.3, lineCap: .round))
        for i in 0..<2 {
            let f = bgFrac(u / 0.9 + Double(i) * 0.5)
            let q = BP.pt(head.x - 5 - Double(i) * 6, head.y - 8 + f * 20)
            b.fill(Path(ellipseIn: CGRect(x: q.x - 1.2, y: q.y - 1.7, width: 2.4, height: 3.4)), with: .color(ink.opacity(0.8 * (1 - f))))
        }
        let pressed = BP.eout(BP.pr(u, 3.7, 3.9))
        bgLever(&b, rig, k: 2.2, pressed: pressed, color: acc, hi: true)

        // the finger that clicks it
        let lw = world(rig.leverPos)
        let appr = BP.eout(BP.pr(u, 3.0, 3.7)), press = BP.pr(u, 3.7, 3.9) - BP.pr(u, 3.9, 4.15)
        let fa = BP.pr(u, 2.9, 3.4) * (1 - BP.pr(u, 4.4, 4.9))
        let tip = BP.pt(lw.x + 4 + (1 - appr) * 40, lw.y - 7 + (1 - appr) * -30 + press * 4.5)
        bpGroup(&c, alpha: fa) { g in
            let dir = BP.pt(0.80, -0.60)
            let base = BP.pt(tip.x + dir.x * 24, tip.y + dir.y * 24)
            let palm = BP.pt(base.x + dir.x * 13, base.y + dir.y * 13)
            let wrist = BP.pt(palm.x + dir.x * 34, palm.y + dir.y * 34)
            var wr = Path(); wr.move(to: palm); wr.addLine(to: wrist)
            g.stroke(wr, with: .color(ink), style: StrokeStyle(lineWidth: 15, lineCap: .butt))
            g.stroke(wr, with: .color(BP.paper), style: StrokeStyle(lineWidth: 12.4, lineCap: .butt))
            let pm = bgOval(palm, 11)
            g.fill(pm, with: .color(BP.paper)); g.fill(pm, with: .color(ink.opacity(0.1))); g.stroke(pm, with: .color(ink), lineWidth: BP.edge)
            var fg2 = Path(); fg2.move(to: tip); fg2.addLine(to: base)
            g.stroke(fg2, with: .color(ink), style: StrokeStyle(lineWidth: 8.4, lineCap: .round))
            g.stroke(fg2, with: .color(BP.paper), style: StrokeStyle(lineWidth: 6.2, lineCap: .round))
        }
        bgRipple(&c, lw, p: BP.pr(u, 3.85, 4.5), r: 18, color: acc)

        // labels
        bpLeader(&c, anchor: BP.pt(lw.x, lw.y - 5), elbow: BP.pt(lw.x + 4, 86), tail: 14, text: "GEAR LEVER", ink: ink, p: BP.pr(t, 0.6, 1.3))
        bpLeader(&c, anchor: BP.pt(236, yS(236) - 1), elbow: BP.pt(240, 128), tail: 12, text: "SAME HILL", ink: ink, p: BP.pr(t, 0.9, 1.6))
    }

}

// MARK: - Card 2: a smaller back ring spins the wheel more for each pedal turn

struct BikeBPRings: View {
    let active: Bool
    private static let story = 7.9

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 5.2,
                       label: "A cutaway of a bike's pedal ring, chain and a stack of three back rings on the rear wheel. One pedal turn pulls a stretch of chain past a gate, and on the bigger back ring it turns the wheel once. The gear lever is pressed and the chain slides to the smaller back ring. The same pedal turn pulls the same stretch of chain, shown in gold, and the wheel turns twice. Labels: pedal ring, chain, back rings, gear lever.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, bgCycle(t, clock, story: Self.story)) }, size: bgSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        c.opacity = bgAlpha(u, story)
        let R = 78.0
        var rig = BgRig(o: BP.pt(100, 186), R: R)
        rig.frame = false

        // timeline: one pedal turn on the big ring, the lever, the chain slides, the same pedal turn again
        let c1 = bgTau * BP.eio(BP.pr(u, 1.0, 3.2)), c2 = bgTau * BP.eio(BP.pr(u, 5.7, 7.9))
        rig.crank = c1 + c2
        rig.wheel = c1 * (bgRa / bgRingR[0]) + c2 * (bgRa / bgRingR[2])
        rig.shift = BP.eio(BP.pr(u, 4.4, 5.2))
        rig.travel = bgRa * R * (c1 + c2)
        let firstTurn = u < 4.6
        let pulled = bgRa * R * (firstTurn ? c1 : c2)
        let pcol: Color = firstTurn ? ink : acc
        let palpha = firstTurn ? 0.45 * (1 - BP.pr(u, 3.9, 4.3)) : 1

        bgBike(&c, rig, ink: ink, pulled: pulled, pulledColor: pcol, pulledAlpha: palpha)

        // the notch the marked spoke passes: count the wheel turns
        let top = BP.pt(rig.o.x, rig.o.y - R)
        var notch = Path(); notch.move(to: BP.pt(top.x, top.y + 1)); notch.addLine(to: BP.pt(top.x - 4, top.y - 8)); notch.addLine(to: BP.pt(top.x + 4, top.y - 8)); notch.closeSubpath()
        c.fill(notch, with: .color(ink))

        // the lever sits on a stub of handlebar, pressed at 4.2
        let lp = rig.leverPos
        var stub = Path(); stub.move(to: rig.p(2.0, -1.12)); stub.addLine(to: rig.p(2.40, -1.10))
        c.stroke(stub, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge + 0.4, lineCap: .round))
        bgLever(&c, rig, k: 1.0, pressed: BP.eout(BP.pr(u, 4.15, 4.4)), color: ink, hi: false)
        bgRipple(&c, lp, p: BP.pr(u, 4.3, 4.9), r: 16, color: ink)

        // labels
        let lab = BP.pr(t, 0.5, 1.2)
        bpLeader(&c, anchor: BP.pt(lp.x, lp.y - 5), elbow: BP.pt(lp.x - 26, 52), tail: -12, text: "GEAR LEVER", ink: ink, p: lab)
        let bb = rig.bb, rp = bgRa * R
        bpLeader(&c, anchor: BP.pt(bb.x + rp * cos(-0.9), bb.y + rp * sin(-0.9)), elbow: BP.pt(232, 128), tail: 12, text: "PEDAL RING", ink: ink, p: BP.pr(t, 0.7, 1.4))
        bpLeader(&c, anchor: BP.pt(143, 155), elbow: BP.pt(150, 112), tail: 12, text: "CHAIN", ink: ink, p: BP.pr(t, 0.9, 1.6))
        let mid = bgRingR[1] * R
        bpLeader(&c, anchor: BP.pt(rig.o.x + mid * cos(-2.36), rig.o.y + mid * sin(-2.36)), elbow: BP.pt(56, 88), tail: 12, text: "BACK RINGS", ink: ink, p: BP.pr(t, 1.1, 1.8))
    }

}

// MARK: - Card 3: a smaller back ring carries you farther with each pedal turn

struct BikeBPCarry: View {
    let active: Bool
    private static let story = 7.6

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 7.0,
                       label: "Two lanes of road, each with the same small bike seen from the side. One pedal turn on the bigger back ring rolls the top bike a short way, and its marker lands. The gear lever clicks on the second bike. One pedal turn on the smaller back ring rolls it much farther, and its marker, shown in gold, lands. The two distances are marked under the roads. Labels: bigger back ring, smaller back ring, one pedal turn, shorter way, farther.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, bgCycle(t, clock, story: Self.story)) }, size: bgSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        c.opacity = bgAlpha(u, story)
        let R = 16.0, xs = 28.0
        let road1 = 150.0, road2 = 244.0

        let a1 = bgTau * BP.eio(BP.pr(u, 1.0, 3.0))
        let a2 = bgTau * BP.eio(BP.pr(u, 5.0, 7.0))
        let x1 = xs + a1 * R                      // bigger back ring: the wheel turns once for the pedal turn
        let x2 = xs + a2 * 2 * R                  // smaller back ring: twice
        let m1 = xs + bgTau * R, m2 = xs + bgTau * 2 * R
        let lane2 = BP.pr(u, 3.5, 4.0)

        // roads
        for (y, a) in [(road1, 1.0), (road2, lane2)] {
            var r = Path(); r.move(to: BP.pt(10, y)); r.addLine(to: BP.pt(332, y))
            c.stroke(r, with: .color(ink.opacity(a)), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
            var tk = Path()
            for k in 0..<23 { let x = 14 + Double(k) * 14; tk.move(to: BP.pt(x, y + 2)); tk.addLine(to: BP.pt(x - 4, y + 6)) }
            c.stroke(tk, with: .color(ink.opacity(0.3 * a)), lineWidth: BP.hair)
        }
        // the start line
        bpGuide(&c, BP.pt(xs, 112), BP.pt(xs, 262), p: BP.pr(u, 0.2, 0.9), color: ink.opacity(0.5))

        // the two distances, marked on the road
        let l1 = BP.pr(u, 3.0, 3.6), l2 = BP.pr(u, 7.0, 7.6)
        func marker(_ x: Double, _ y: Double, _ p: Double, _ col: Color) {
            guard p > 0.01 else { return }
            var tri = Path(); tri.move(to: BP.pt(x, y + 1)); tri.addLine(to: BP.pt(x - 4.5, y + 9 * p + 1)); tri.addLine(to: BP.pt(x + 4.5, y + 9 * p + 1)); tri.closeSubpath()
            c.fill(tri, with: .color(col))
        }
        marker(m1, road1, BP.eout(BP.pr(u, 3.0, 3.25)), ink)
        marker(m2, road2, BP.eout(BP.pr(u, 7.0, 7.25)), acc)
        if l1 > 0.01 {
            bpGuide(&c, BP.pt(m1, road1 + 10), BP.pt(m1, road1 + 22), p: l1, color: ink.opacity(0.7))
            bpDimension(&c, from: BP.pt(xs, road1 + 18), to: BP.pt(m1, road1 + 18), tick: BP.pt(0, 3.5), text: "", labelWidth: 0, ink: ink, p: l1)
            bpText(&c, "SHORTER WAY", BP.pt((xs + m1) / 2, road1 + 31), ink: ink, alpha: BP.pr(l1, 0.6, 1))
        }
        if l2 > 0.01 {
            bpGuide(&c, BP.pt(m2, road2 + 10), BP.pt(m2, road2 + 22), p: l2, color: acc.opacity(0.8))
            bpDimension(&c, from: BP.pt(xs, road2 + 18), to: BP.pt(m2, road2 + 18), tick: BP.pt(0, 3.5), text: "", labelWidth: 0, ink: acc, p: l2)
            bpText(&c, "FARTHER", BP.pt((xs + m2) / 2, road2 + 31), ink: acc, alpha: BP.pr(l2, 0.6, 1))
        }

        // lane 1: the bigger back ring
        var r1 = BgRig(o: BP.pt(x1, road1 - R), R: R)
        r1.wheel = a1; r1.crank = a1; r1.shift = 0; r1.travel = bgRa * R * a1
        bgBike(&c, r1, ink: ink)
        bgLever(&c, r1, k: 3.0, pressed: 0, color: ink, hi: false)

        // lane 2: the lever clicks, the chain slides to the smaller ring, the same pedal turn rolls it farther
        var r2 = BgRig(o: BP.pt(x2, road2 - R), R: R)
        r2.wheel = 2 * a2; r2.crank = a2; r2.shift = BP.eio(BP.pr(u, 4.35, 4.85)); r2.travel = bgRa * R * a2
        if lane2 > 0.01 {
            var g = c
            g.opacity = c.opacity * lane2
            bgBike(&g, r2, ink: ink)
            bgLever(&g, r2, k: 3.0, pressed: BP.eout(BP.pr(u, 4.2, 4.4)), color: ink, hi: false)
            bgRipple(&g, r2.leverPos, p: BP.pr(u, 4.3, 4.9), r: 10, color: ink)
        }

        // labels (the ring labels wait until the bike has landed)
        let hub1 = BP.pt(m1, road1 - R), hub2 = BP.pt(m2, road2 - R)
        let bb1 = r1.bb
        bpLeader(&c, anchor: bb1, elbow: BP.pt(150, 66), tail: 12, text: "ONE PEDAL TURN", ink: ink, p: BP.pr(u, 1.0, 1.7))
        bpLeader(&c, anchor: hub1, elbow: BP.pt(140, 94), tail: 12, text: "BIGGER BACK RING", ink: ink, p: BP.pr(u, 3.1, 3.8))
        bpLeader(&c, anchor: hub2, elbow: BP.pt(222, 198), tail: -14, text: "SMALLER BACK RING", ink: ink, p: BP.pr(u, 7.0, 7.6))
    }

}

// MARK: - Card 4: a shorter way per turn means a lighter push, and more turns to the top

struct BikeBPWalk: View {
    let active: Bool
    private static let story = 6.4

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 5.8,
                       label: "Two walkers climb two identical steep paths side by side. The left walker takes a few long, heaving strides. The right walker takes many short quick steps. They set off together and both reach the same top, marked by a gold height line. Labels: long strides, short quick steps, same top.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, bgCycle(t, clock, story: Self.story)) }, size: bgSize)
    }

    private static let topY = 110.0, baseY = 240.0, rise = 130.0
    private static let arrive = 5.8

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        c.opacity = bgAlpha(u, story)
        let D = hypot(rise, rise), dd = BP.pt(rise / D, -rise / D)
        let sEnd = D + 4

        // progress: both set off together and arrive together
        let x = BP.pr(u, 0.7, arrive)
        let s = sEnd * (0.85 * x + 0.15 * BP.eio(x))
        let amp = BP.pr(u, 0.55, 1.0) * (1 - BP.pr(u, arrive - 0.5, arrive))

        for (i, x0) in [18.0, 176.0].enumerated() {
            let P0 = BP.pt(x0, baseY), S = BP.pt(x0 + rise, topY)
            // the hill: a block with the steep path along its top
            var block = Path()
            block.move(to: P0); block.addLine(to: S); block.addLine(to: BP.pt(x0 + rise + 16, topY)); block.addLine(to: BP.pt(x0 + rise + 16, 250)); block.addLine(to: BP.pt(x0, 250)); block.closeSubpath()
            c.fill(block, with: .color(BP.paper)); c.fill(block, with: .color(ink.opacity(0.07)))
            var h = c
            h.clip(to: block)
            var hatch = Path()
            for k in stride(from: -140.0, to: 200.0, by: 13.0) { hatch.move(to: BP.pt(x0 + k, 260)); hatch.addLine(to: BP.pt(x0 + k + 130, 130)) }
            h.stroke(hatch, with: .color(ink.opacity(0.12)), lineWidth: BP.hair)
            c.stroke(block, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))

            func ground(_ sp: Double) -> CGPoint {
                if sp <= D { return BP.pt(P0.x + dd.x * sp, P0.y + dd.y * sp) }
                return BP.pt(S.x + (sp - D), topY)
            }
            let long = i == 0
            bgWalker(&c, s: s, Ls: long ? 36 : 12, lift: long ? 9 : 4, bob: long ? 5.5 : 1.6, lean: long ? 0.50 : 0.30, amp: amp, ground: ground, ink: ink)
        }

        // the height line at the top, the one mustard thing
        let lineP = BP.pr(t, 0.2, 1.0)
        let arr = BP.pr(u, arrive - 0.2, arrive + 0.4)
        var hl = Path(); hl.move(to: BP.pt(10, topY)); hl.addLine(to: BP.pt(334, topY))
        bpTrace(&c, hl, p: lineP, color: acc, width: 1.6 + 1.2 * arr, dash: [6, 4])
        for x0 in [18.0, 176.0] {
            let fx = x0 + rise + 8
            var flag = Path(); flag.move(to: BP.pt(fx, topY)); flag.addLine(to: BP.pt(fx, topY - 22 * arr))
            flag.addLine(to: BP.pt(fx + 11 * arr, topY - 17 * arr)); flag.addLine(to: BP.pt(fx, topY - 12 * arr))
            if arr > 0.01 { c.stroke(flag, with: .color(acc), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)) }
        }

        // labels
        bpLeader(&c, anchor: BP.pt(163, topY), elbow: BP.pt(172, 70), tail: 12, text: "SAME TOP", ink: ink, p: BP.pr(t, 0.5, 1.2))
        bpText(&c, "LONG STRIDES", BP.pt(83, 268), ink: ink, alpha: BP.pr(t, 0.7, 1.3))
        bpText(&c, "SHORT QUICK", BP.pt(239, 264), ink: ink, alpha: BP.pr(t, 0.8, 1.4))
        bpText(&c, "STEPS", BP.pt(239, 277), ink: ink, alpha: BP.pr(t, 0.8, 1.4))
    }

}

/// A walker on a steep path: hip over the ground at distance `s`, feet that plant and swing with step length `Ls`.
private func bgWalker(_ c: inout GraphicsContext, s: Double, Ls: Double, lift: Double, bob: Double, lean: Double, amp: Double, ground: (Double) -> CGPoint, ink: Color) {
    let hv = 29.0, leg = 23.0
    let q = s / Ls
    let g0 = ground(s)
    let hip = BP.pt(g0.x, g0.y - hv - bob * abs(sin(Double.pi * q)) * amp)
    func foot(_ k: Int) -> (CGPoint, Double) {
        let cc = bgFrac(s / (2 * Ls) + 0.5 * Double(k))
        var xf = 0.0, lf = 0.0
        if cc < 0.5 { xf = Ls / 2 - Ls * (cc / 0.5) } else { let w = (cc - 0.5) / 0.5; xf = -Ls / 2 + Ls * w; lf = lift * sin(Double.pi * w) }
        let f = ground(s + xf * amp)
        return (BP.pt(f.x, f.y - lf * amp), xf)
    }
    let near = foot(0), far = foot(1)
    let tilt = lean * (0.4 + 0.6 * amp)
    bgLeg(&c, hip: hip, foot: far.0, a: leg, b: leg, ink: ink, alpha: 0.6)
    let sh = bgTorso(&c, hip: hip, lean: tilt, ink: ink)
    bgLeg(&c, hip: hip, foot: near.0, a: leg, b: leg, ink: ink, alpha: 1)
    let swing = -near.1 / (Ls / 2) * 8 * amp
    bpArm(&c, from: sh, elbow: BP.pt(sh.x + swing * 0.5 + 1, sh.y + 11), to: BP.pt(sh.x + swing + 4, sh.y + 19), ink: ink)
}

// MARK: - Card 5: the same speed on flat road, slower pedalling with a smaller back ring

struct BikeBPFlat: View {
    let active: Bool
    private static let story = 7.0

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.9,
                       label: "A rider on flat road, seen from the side, pedals fast on the bigger back ring with a light push on each pedal. The lever clicks and the chain slides to the smaller back ring. The legs slow down and a gold arrow on the pedal grows, showing a harder push, while the road keeps passing at the same speed. Labels: flat road, smaller back ring, bigger back ring.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, bgCycle(t, clock, story: Self.story)) }, size: bgSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        c.opacity = bgAlpha(u, story)
        let R = 29.0, roadY = 212.0
        let still = u == story
        let wr = 8.4                                                     // the wheel turns at one steady rate: the same speed all through
        let shiftAt: (Double) -> Double = { BP.eio(BP.pr($0, 3.9, 4.6)) }
        let shift = shiftAt(u)
        var crank = bgInt(u) { wr * bgRingRadius(shiftAt($0)) / bgRa }  // the chain keeps pace with the wheel, so the legs slow as the ring shrinks
        if still { crank = 1.0 }
        let wheel = wr * u, dist = wheel * R

        // the road, with a band of ground, ticks and posts that stream past at one speed
        var band = Path()
        band.move(to: BP.pt(8, roadY)); band.addLine(to: BP.pt(334, roadY)); band.addLine(to: BP.pt(334, roadY + 16)); band.addLine(to: BP.pt(8, roadY + 16)); band.closeSubpath()
        c.fill(band, with: .color(BP.paper)); c.fill(band, with: .color(ink.opacity(0.07)))
        var rd = Path(); rd.move(to: BP.pt(8, roadY)); rd.addLine(to: BP.pt(334, roadY))
        c.stroke(rd, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
        var tk = Path()
        let o46 = dist.truncatingRemainder(dividingBy: 46)
        for k in 0..<9 {
            let x = 8 + Double(k) * 46 - o46
            guard x > 10, x < 330 else { continue }
            tk.move(to: BP.pt(x, roadY + 4)); tk.addLine(to: BP.pt(x - 14, roadY + 4))
        }
        c.stroke(tk, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
        let o150 = dist.truncatingRemainder(dividingBy: 150)
        for k in -1...3 {
            let x = Double(k) * 150 + 250 - o150
            guard x > 12, x < 331 else { continue }
            var pole = Path(); pole.move(to: BP.pt(x, roadY)); pole.addLine(to: BP.pt(x, roadY - 30))
            c.stroke(pole, with: .color(ink), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
            var pen = Path(); pen.move(to: BP.pt(x, roadY - 30)); pen.addLine(to: BP.pt(x - 11, roadY - 27)); pen.addLine(to: BP.pt(x, roadY - 22)); pen.closeSubpath()
            c.fill(pen, with: .color(ink.opacity(0.4))); c.stroke(pen, with: .color(ink), lineWidth: BP.hair)
        }

        // the bike and rider
        var rig = BgRig(o: BP.pt(118, roadY - R), R: R)
        rig.wheel = wheel; rig.crank = crank; rig.shift = shift; rig.travel = crank * bgRa * R
        bgBike(&c, rig, ink: ink)
        bgRider(&c, rig, lean: 40.0 * Double.pi / 180, ink: ink)
        bgLever(&c, rig, k: 2.2, pressed: BP.eout(BP.pr(u, 3.8, 4.0)), color: ink, hi: false)
        bgRipple(&c, rig.leverPos, p: BP.pr(u, 3.9, 4.5), r: 16, color: ink)

        // the push on the pedal: light on the bigger ring, harder on the smaller one
        let force = 7 + 17 * shift
        for extra in [0.0, Double.pi] {
            let a = crank + extra
            let f = sin(a)
            guard f > 0 else { continue }
            let p = rig.pedal(extra)
            bgArrow(&c, from: BP.pt(p.x, p.y + 4), to: BP.pt(p.x, p.y + 4 + force * (0.55 + 0.45 * f)), color: acc, width: 2.4, alpha: min(1, f * 2.5))
        }

        // labels
        let ringBig = bgRingR[0] * R, ringSmall = bgRingR[2] * R
        bpLeader(&c, anchor: BP.pt(rig.o.x + ringBig * cos(-2.1), rig.o.y + ringBig * sin(-2.1)), elbow: BP.pt(10, 124), tail: 10, text: "BIGGER BACK RING", ink: ink, p: BP.pr(u, 0.6, 1.3))
        bpLeader(&c, anchor: BP.pt(rig.o.x + ringSmall * cos(-1.75), rig.o.y + ringSmall * sin(-1.75)), elbow: BP.pt(10, 100), tail: 10, text: "SMALLER BACK RING", ink: ink, p: BP.pr(u, 4.4, 5.1))
        bpText(&c, "FLAT ROAD", BP.pt(250, roadY + 28), ink: ink, alpha: BP.pr(t, 0.5, 1.2))
    }

}
