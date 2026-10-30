import SwiftUI

// "Why does a car engine need an electric motor just to start?" pictures, drawn as blueprint technical illustrations (2026-10-28).
// Every card draws the same engine cutaway from one shared helper (carEngine), so the cylinder looks identical throughout: a block seen
// from the front with an oblique cut-away depth, bore, piston, rod, bent shaft and two valves in the head. One chalk-ink colour, one mustard
// accent per card (the electric motor, the piston, the push stroke, the flywheel), thin even lines, flat tints, mono uppercase labels that
// use the slide text's own words. A picture starts once its card has settled, plays one action (about 2-3.4 s), then holds; tap replays,
// Reduce Motion shows the end state. Drawn in a 343 x 340 design space; keep clear of the bottom-right corner (x > 285, y > 255).

private let carSize = CGSize(width: 343, height: 340)

// MARK: - Shared engine cutaway

private enum CE {
    static let r = 18.0, rod = 50.0, cy = 77.0                        // crank radius, rod length, shaft height below the top of the head
    static let bore = 19.0, wall = 29.0, pitch = 58.0                 // half bore, half block per cylinder, cylinder spacing
    static let headTop = -14.0, wallBottom = 58.0, caseBottom = 105.0, base = 111.0

    /// Height of the piston pin when the shaft has turned `th` from the top of the stroke (clockwise).
    static func pinY(_ th: Double) -> Double { cy - (r * cos(th) + sqrt(rod * rod - r * r * sin(th) * sin(th))) }
    /// One full four-move cycle is two turns of the shaft: 0...4 pi.
    static func wrap(_ x: Double) -> Double { let m = 4 * Double.pi; return x - (x / m).rounded(.down) * m }
}

/// Where the engine sits: `ox`, `oy` is the middle of the first bore at the top of the head, `s` is points per local unit.
private struct CarGeo {
    var ox: Double, oy: Double, s: Double
    func p(_ x: Double, _ y: Double) -> CGPoint { BP.pt(ox + x * s, oy + y * s) }
    func cx(_ i: Int) -> Double { Double(i) * CE.pitch }
}

/// What is inside a cylinder at one moment of its four moves.
private struct CarGas {
    var gas = 0.0, hot = 0.0, intake = 0.0, exhaust = 0.0, spark = 0.0
}

/// The state of a cylinder at `phase` (0...4 pi): 0-pi pulls in, pi-2pi squeezes, 2pi-3pi pushes, 3pi-4pi clears out.
private func carGas(_ phase: Double) -> CarGas {
    let ph = CE.wrap(phase), k = min(3, Int(ph / .pi)), u = ph / .pi - Double(k)
    var s = CarGas()
    switch k {
    case 0: s.gas = BP.mix(0.06, 0.12, u); s.intake = BP.pr(u, 0, 0.1) * (1 - BP.pr(u, 0.9, 1))
    case 1: s.gas = BP.mix(0.12, 0.30, u)
    case 2: s.gas = BP.mix(0.32, 0.20, u); s.hot = BP.mix(1, 0.5, u)
    default: s.gas = BP.mix(0.20, 0.06, u); s.exhaust = BP.pr(u, 0, 0.1) * (1 - BP.pr(u, 0.9, 1))
    }
    s.spark = BP.cl(1 - abs(ph - 2 * .pi) / 0.3)
    return s
}

private struct CarCyl {
    var theta = 0.0                       // shaft angle seen by this cylinder; 0 is the piston at the top
    var gas = CarGas()
    var pistonTint: Color? = nil          // the mustard piston
    var sparkColor: Color? = nil
}

private func carHash(_ a: Int, _ b: Int) -> Double {
    let v = sin(Double(a) * 12.9898 + Double(b) * 78.233) * 43758.5453
    return abs(v - v.rounded(.down))
}

private func carStar(_ c: inout GraphicsContext, _ at: CGPoint, r: Double, color: Color, alpha: Double) {
    guard alpha > 0.01 else { return }
    var p = Path()
    for i in 0..<16 {
        let a = Double(i) * .pi / 8, rr = i % 2 == 0 ? r : r * 0.45
        let q = BP.pt(at.x + rr * cos(a), at.y + rr * sin(a))
        if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
    }
    p.closeSubpath()
    c.fill(p, with: .color(color.opacity(alpha)))
}

/// An outlined bar (rods, arms, shafts, limbs): ink edge, paper inside.
private func carBar(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, w: Double, ink: Color) {
    var p = Path(); p.move(to: a); p.addLine(to: b)
    c.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: w, lineCap: .round))
    c.stroke(p, with: .color(BP.paper), style: StrokeStyle(lineWidth: max(1, w - 2.2), lineCap: .round))
}

/// A short arrow from `a` to `b` with a small head.
private func carArrow(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, color: Color, alpha: Double) {
    guard alpha > 0.01 else { return }
    let len = hypot(b.x - a.x, b.y - a.y), ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    var p = Path(); p.move(to: a); p.addLine(to: b)
    p.move(to: BP.pt(b.x - ux * 5 - uy * 3, b.y - uy * 5 + ux * 3)); p.addLine(to: b); p.addLine(to: BP.pt(b.x - ux * 5 + uy * 3, b.y - uy * 5 - ux * 3))
    c.stroke(p, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round))
}

/// A wheel seen from the front: disc, rim ring, `n` spokes turned by `angle`, and a hub.
private func carWheel(_ c: inout GraphicsContext, _ at: CGPoint, r: Double, angle: Double, color: Color, tint: Double, spokes n: Int = 3) {
    let disc = Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: 2 * r, height: 2 * r))
    c.fill(disc, with: .color(BP.paper)); c.fill(disc, with: .color(color.opacity(tint)))
    c.stroke(disc, with: .color(color), lineWidth: BP.edge)
    var sp = Path()
    for k in 0..<n {
        let a = angle + Double(k) * 2 * .pi / Double(n)
        sp.move(to: at); sp.addLine(to: BP.pt(at.x + (r - 1.5) * cos(a), at.y + (r - 1.5) * sin(a)))
    }
    c.stroke(sp, with: .color(color), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
    let hub = Path(ellipseIn: CGRect(x: at.x - r * 0.28, y: at.y - r * 0.28, width: r * 0.56, height: r * 0.56))
    c.fill(hub, with: .color(BP.paper)); c.fill(hub, with: .color(color.opacity(0.5)))
    c.stroke(hub, with: .color(color), lineWidth: BP.hair)
}

/// The engine: one block with `cyls.count` cylinders in a row (the first bore at `g.ox`), cut open along its front.
private func carEngine(_ c: inout GraphicsContext, _ g: CarGeo, _ cyls: [CarCyl], ink: Color) {
    let n = cyls.count, s = g.s
    let x0 = -CE.wall, x1 = g.cx(n - 1) + CE.wall, yT = CE.headTop, yB = CE.base
    let dv = BP.pt(9 * s, -5 * s)
    func off(_ q: CGPoint) -> CGPoint { BP.pt(q.x + dv.x, q.y + dv.y) }
    func poly(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }
    func rect(_ xa: Double, _ ya: Double, _ xb: Double, _ yb: Double) -> CGRect {
        let a = g.p(xa, ya)
        return CGRect(x: a.x, y: a.y, width: (xb - xa) * s, height: (yb - ya) * s)
    }
    func fillCut(_ r: CGRect) { c.fill(Path(r), with: .color(BP.paper)); c.fill(Path(r), with: .color(ink.opacity(0.05))) }

    // the block: top face, right face and the cut front, every edge in ink
    let top = poly([g.p(x0, yT), g.p(x1, yT), off(g.p(x1, yT)), off(g.p(x0, yT))])
    let side = poly([g.p(x1, yT), off(g.p(x1, yT)), off(g.p(x1, yB)), g.p(x1, yB)])
    let body = Path(rect(x0, yT, x1, yB))
    c.fill(top, with: .color(BP.paper)); c.fill(top, with: .color(ink.opacity(0.08)))
    c.fill(side, with: .color(BP.paper)); c.fill(side, with: .color(ink.opacity(0.20)))
    c.fill(body, with: .color(BP.paper)); c.fill(body, with: .color(ink.opacity(0.13)))
    for f in [top, side, body] { c.stroke(f, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round)) }

    // the cut: crankcase, bores and the two ports of each head
    fillCut(rect(x0 + 4, CE.wallBottom, x1 - 4, CE.caseBottom))
    for i in 0..<n {
        let bx = g.cx(i)
        fillCut(rect(bx - CE.bore, 0, bx + CE.bore, CE.wallBottom + 0.5))
        for sx in [-11.0, 11.0] { fillCut(rect(bx + sx - 4, yT - 1.2, bx + sx + 4, 0.5)) }
    }
    var e = Path()
    var ceil = x0 + 4
    for i in 0..<n {
        let bx = g.cx(i)
        // bore walls and head, open where the ports are
        e.move(to: g.p(bx - CE.bore, CE.wallBottom)); e.addLine(to: g.p(bx - CE.bore, 0)); e.addLine(to: g.p(bx - 15, 0))
        e.move(to: g.p(bx - 7, 0)); e.addLine(to: g.p(bx + 7, 0))
        e.move(to: g.p(bx + 15, 0)); e.addLine(to: g.p(bx + CE.bore, 0)); e.addLine(to: g.p(bx + CE.bore, CE.wallBottom))
        for sx in [-11.0, 11.0] {
            e.move(to: g.p(bx + sx - 4, yT)); e.addLine(to: g.p(bx + sx - 4, 0))
            e.move(to: g.p(bx + sx + 4, yT)); e.addLine(to: g.p(bx + sx + 4, 0))
        }
        // crankcase roof between bores
        e.move(to: g.p(ceil, CE.wallBottom)); e.addLine(to: g.p(bx - CE.bore, CE.wallBottom))
        ceil = bx + CE.bore
    }
    e.move(to: g.p(ceil, CE.wallBottom)); e.addLine(to: g.p(x1 - 4, CE.wallBottom))
    e.move(to: g.p(x0 + 4, CE.wallBottom)); e.addLine(to: g.p(x0 + 4, CE.caseBottom)); e.addLine(to: g.p(x1 - 4, CE.caseBottom)); e.addLine(to: g.p(x1 - 4, CE.wallBottom))
    c.stroke(e, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, lineJoin: .round))

    // the shaft through the crankcase
    let shaftW = max(3.6, 5.4 * s)
    carBar(&c, g.p(x0 + 8, CE.cy), g.p(x1 - 8, CE.cy), w: shaftW, ink: ink)

    for (i, st) in cyls.enumerated() {
        let bx = g.cx(i), th = st.theta
        let pinY = CE.pinY(th), pTop = pinY - 5
        let sparkCol = st.sparkColor ?? ink

        // the gas above the piston: flat tint, a few dots that squeeze with it
        let hGas = pTop
        if hGas > 0.5 {
            let r = rect(bx - CE.bore, 0, bx + CE.bore, hGas)
            c.fill(Path(r), with: .color(ink.opacity(st.gas.gas)))
            c.fill(Path(r), with: .color(ink.opacity(st.gas.hot * 0.18)))
            if hGas > 8 {
                for k in 0..<10 {
                    let q = g.p(bx - 16 + 32 * carHash(k, i), 2 + (hGas - 4) * carHash(k + 20, i))
                    c.fill(Path(ellipseIn: CGRect(x: q.x - 0.9, y: q.y - 0.9, width: 1.8, height: 1.8)), with: .color(ink.opacity(min(0.8, st.gas.gas * 1.8 + st.gas.hot * 0.3))))
                }
            }
        }

        // bent shaft: counterweight, arm, journal and pin
        let cen = g.p(bx, CE.cy), pin = g.p(bx + CE.r * sin(th), CE.cy - CE.r * cos(th))
        let cw = g.p(bx - 11 * sin(th), CE.cy + 11 * cos(th))
        let cwPath = Path(ellipseIn: CGRect(x: cw.x - 7.5 * s, y: cw.y - 7.5 * s, width: 15 * s, height: 15 * s))
        c.fill(cwPath, with: .color(BP.paper)); c.fill(cwPath, with: .color(ink.opacity(0.22)))
        c.stroke(cwPath, with: .color(ink), lineWidth: BP.edge)
        carBar(&c, cen, pin, w: shaftW, ink: ink)
        let jr = 5.5 * s
        let jPath = Path(ellipseIn: CGRect(x: cen.x - jr, y: cen.y - jr, width: 2 * jr, height: 2 * jr))
        c.fill(jPath, with: .color(BP.paper)); c.fill(jPath, with: .color(ink.opacity(0.3)))
        c.stroke(jPath, with: .color(ink), lineWidth: BP.edge)

        // rod, then the piston on top of it
        let pp = g.p(bx, pinY)
        carBar(&c, pp, pin, w: shaftW, ink: ink)
        let pr = 3.4 * s
        let pinPath = Path(ellipseIn: CGRect(x: pin.x - pr, y: pin.y - pr, width: 2 * pr, height: 2 * pr))
        c.fill(pinPath, with: .color(BP.paper)); c.stroke(pinPath, with: .color(ink), lineWidth: BP.edge)

        let pr0 = rect(bx - 18, pTop, bx + 18, pTop + 10)
        let pc = st.pistonTint ?? ink
        c.fill(Path(pr0), with: .color(BP.paper))
        c.fill(Path(pr0), with: .color(pc.opacity(st.pistonTint == nil ? 0.22 : 0.88)))
        c.stroke(Path(pr0), with: .color(pc), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        var rings = Path()
        for ry in [2.6, 5.0] { rings.move(to: g.p(bx - 18, pTop + ry)); rings.addLine(to: g.p(bx + 18, pTop + ry)) }
        c.stroke(rings, with: .color(st.pistonTint == nil ? ink.opacity(0.7) : BP.paper.opacity(0.7)), lineWidth: BP.hair)
        let gp = Path(ellipseIn: CGRect(x: pp.x - 2.2 * s, y: pp.y - 2.2 * s, width: 4.4 * s, height: 4.4 * s))
        c.fill(gp, with: .color(BP.paper)); c.stroke(gp, with: .color(st.pistonTint == nil ? ink : BP.paper), lineWidth: BP.hair)

        // valves: stem above the head, a plate that drops into the bore when open
        var v = Path()
        for (sx, open) in [(-11.0, st.gas.intake), (11.0, st.gas.exhaust)] {
            let plateY = open * 5
            v.move(to: g.p(bx + sx, yT - 6)); v.addLine(to: g.p(bx + sx, plateY))
            v.move(to: g.p(bx + sx - 5, plateY)); v.addLine(to: g.p(bx + sx + 5, plateY))
        }
        c.stroke(v, with: .color(ink), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

        // spark plug
        let nut = rect(bx - 3.5, yT - 5.5, bx + 3.5, yT)
        c.fill(Path(nut), with: .color(BP.paper)); c.stroke(Path(nut), with: .color(ink), lineWidth: BP.hair)
        var plug = Path(); plug.move(to: g.p(bx, yT - 5.5)); plug.addLine(to: g.p(bx, 1.5))
        plug.move(to: g.p(bx, yT - 5.5)); plug.addLine(to: g.p(bx, yT - 9))
        c.stroke(plug, with: .color(ink), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        carStar(&c, g.p(bx, 4), r: (4 + 8 * st.gas.spark) * s + 1, color: sparkCol, alpha: st.gas.spark)
    }
}

/// A fixed point on a cylinder for leaders: the top of its intake port, exhaust port, spark plug, or the middle of its left wall.
private func carPort(_ g: CarGeo, _ i: Int, _ dx: Double) -> CGPoint { g.p(g.cx(i) + dx, CE.headTop - 7) }

// MARK: - Card 1: press start, a small electric motor turns the engine for a moment, then the engine runs by itself

struct CarStart: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 0.4,
                       label: "A cutaway car engine with two cylinders and a small electric motor bolted to its side, shown in gold. On a dash panel at the right, a start button is pressed. The motor spins and turns the engine through a link for a moment. Then the link pulls away, the motor stops, and the engine keeps turning on its own, with its pistons moving and sparks firing. A label says it runs by itself.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, max(t, clock)) }, size: carSize)
    }

    private static let geo = CarGeo(ox: 134, oy: 114, s: 0.82)

    /// Shaft angle: the motor winds it up from 0.5 s, and it carries on at the same speed once the link has gone.
    private static func theta(_ t: Double) -> Double {
        let u = max(0, t - 0.5), ramp = 0.45
        return 10 * (u < ramp ? u * u / (2 * ramp) : u - ramp / 2)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ tt: Double) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))
        let th = theta(tt), running = t >= 1.7
        let crankY = geo.p(0, CE.cy).y, crankX = geo.p(0, 0).x
        let motor = BP.pt(66, crankY)

        // the engine: two cylinders, the second half a turn behind the first
        var cyls: [CarCyl] = []
        for i in 0..<2 {
            let ph = th + Double(i) * .pi
            var gas = carGas(ph)
            if !running { gas.hot = 0; gas.spark = 0 }
            cyls.append(CarCyl(theta: ph, gas: gas))
        }
        bpGroup(&c, alpha: a0) { g in carEngine(&g, geo, cyls, ink: ink) }

        // the electric motor, bolted to the side of the crankcase through a flange
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.05, 0.45))) { g in
            let flange = CGRect(x: 100, y: crankY - 22, width: 10, height: 44)
            let stub = CGRect(x: 88, y: crankY - 9, width: 12, height: 18)
            for r in [flange, stub] {
                g.fill(Path(r), with: .color(BP.paper)); g.fill(Path(r), with: .color(ink.opacity(0.14)))
                g.stroke(Path(r), with: .color(ink), lineWidth: BP.edge)
            }
            for dy in [-15.0, 15.0] { g.fill(Path(ellipseIn: CGRect(x: 103.2, y: crankY + dy - 1.8, width: 3.6, height: 3.6)), with: .color(ink)) }
            let can = Path(ellipseIn: CGRect(x: motor.x - 24, y: motor.y - 24, width: 48, height: 48))
            g.fill(can, with: .color(BP.paper)); g.fill(can, with: .color(acc.opacity(0.2)))
            g.stroke(can, with: .color(acc), lineWidth: BP.edge)
            g.stroke(Path(ellipseIn: CGRect(x: motor.x - 16, y: motor.y - 16, width: 32, height: 32)), with: .color(acc.opacity(0.7)), lineWidth: BP.hair)
            let am = theta(min(t, 1.7)) * 1.0
            var sp = Path()
            for k in 0..<3 {
                let a = am + Double(k) * 2 * .pi / 3
                sp.move(to: motor); sp.addLine(to: BP.pt(motor.x + 14 * cos(a), motor.y + 14 * sin(a)))
            }
            g.stroke(sp, with: .color(acc), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            g.fill(Path(ellipseIn: CGRect(x: motor.x - 4, y: motor.y - 4, width: 8, height: 8)), with: .color(acc))
        }

        // the link from motor to shaft: it draws on at the press and pulls back to the motor once the engine runs
        let linkOn = BP.pr(t, 0.45, 0.65), linkOff = BP.eio(BP.pr(t, 1.7, 2.0))
        let reach = BP.mix(74, crankX - 6, linkOn * (1 - linkOff))
        if linkOn > 0.01 && linkOff < 0.99 { carBar(&c, BP.pt(74, crankY), BP.pt(reach, crankY), w: 5.4, ink: ink) }

        // the dash panel with the start button
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.05, 0.45))) { g in
            let front = CGRect(x: 226, y: 112, width: 54, height: 62)
            func poly(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }
            let topF = poly([BP.pt(226, 112), BP.pt(280, 112), BP.pt(288, 107), BP.pt(234, 107)])
            let sideF = poly([BP.pt(280, 112), BP.pt(288, 107), BP.pt(288, 169), BP.pt(280, 174)])
            let post = CGRect(x: 246, y: 174, width: 14, height: 36)
            g.fill(Path(post), with: .color(BP.paper)); g.fill(Path(post), with: .color(ink.opacity(0.14)))
            g.stroke(Path(post), with: .color(ink), lineWidth: BP.edge)
            for (f, tint) in [(topF, 0.08), (sideF, 0.2), (Path(front), 0.13)] {
                g.fill(f, with: .color(BP.paper)); g.fill(f, with: .color(ink.opacity(tint)))
                g.stroke(f, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
            }
            var dashes = Path()
            for y in [123.0, 129.0] { dashes.move(to: BP.pt(234, y)); dashes.addLine(to: BP.pt(246, y)) }
            g.stroke(dashes, with: .color(ink.opacity(0.6)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
            let press = BP.pr(t, 0.25, 0.4) * (1 - BP.pr(t, 0.65, 0.85))
            let ctr = BP.pt(253, 148)
            let ring = Path(ellipseIn: CGRect(x: ctr.x - 13, y: ctr.y - 13, width: 26, height: 26))
            g.fill(ring, with: .color(BP.paper)); g.stroke(ring, with: .color(ink), lineWidth: BP.edge)
            let b = Path(ellipseIn: CGRect(x: ctr.x - 8.5, y: ctr.y - 8.5 + 1.6 * press, width: 17, height: 17))
            g.fill(b, with: .color(ink.opacity(0.18 + 0.4 * press))); g.stroke(b, with: .color(ink), lineWidth: BP.edge)
            let pulse = BP.pr(t, 0.4, 0.9)
            if pulse > 0 && pulse < 1 {
                let rr = 15 + 9 * pulse
                g.stroke(Path(ellipseIn: CGRect(x: ctr.x - rr, y: ctr.y - rr, width: 2 * rr, height: 2 * rr)), with: .color(ink.opacity(0.7 * (1 - pulse))), lineWidth: BP.hair)
            }
        }

        // labels
        bpLeader(&c, anchor: BP.pt(150, 101), elbow: BP.pt(150, 62), tail: 0, text: "ENGINE", ink: ink, p: BP.pr(t, 0.1, 0.55))
        bpLeader(&c, anchor: BP.pt(52, motor.y - 20), elbow: BP.pt(30, 126), tail: 0, text: "ELECTRIC\nMOTOR", ink: ink, p: BP.pr(t, 0.15, 0.6))
        bpLeader(&c, anchor: BP.pt(253, 139), elbow: BP.pt(253, 86), tail: 0, text: "START", ink: ink, p: BP.pr(t, 0.2, 0.65))
        bpLeader(&c, anchor: BP.pt(150, geo.p(0, CE.base).y), elbow: BP.pt(150, 250), tail: 0, text: "RUNS BY ITSELF", ink: ink, p: BP.pr(t, 2.0, 2.6))
    }
}

// MARK: - Card 2: hot gas pushes the piston down and the shaft turns half a turn, like a leg on a bike pedal

struct CarPiston: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.2, tick: 1.0,
                       label: "A cutaway cylinder with a gold piston at the top, a rod and a bent shaft below. A spark lights the fuel and air, and the hot gas pushes the piston down the cylinder. The rod turns the bent shaft half a turn. Beside it, a leg turns a bike pedal in the same way.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, max(t, clock)) }, size: carSize)
    }

    private static let geo = CarGeo(ox: 150, oy: 62, s: 1.12)

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ tt: Double) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.45))
        // the first push winds the shaft up from rest; it then keeps turning at a steady speed, push after push (the pedal turns with it)
        let u = max(0, tt - 1.0), ramp = 0.6
        let th = 4.5 * (u < ramp ? u * u / (2 * ramp) : u - ramp / 2)
        let ignite = BP.pr(t, 0.85, 1.05)

        var gas = carGas(2 * .pi + th)
        gas.gas *= ignite; gas.hot *= ignite
        if tt < 1.4 { gas.spark = BP.pr(t, 0.75, 0.9) * (1 - BP.pr(t, 0.95, 1.3)) } else { gas.spark *= ignite }
        bpGroup(&c, alpha: a0) { g in carEngine(&g, geo, [CarCyl(theta: th, gas: gas, pistonTint: acc)], ink: ink) }

        // the push: three arrows down the bore while the piston travels
        let pTop = geo.p(0, CE.pinY(th) - 5).y
        let ph2 = CE.wrap(2 * .pi + th), su = ph2 / .pi - 2
        let travel = ph2 >= 2 * .pi && ph2 < 3 * .pi ? ignite * BP.pr(su, 0, 0.1) * (1 - BP.pr(su, 0.85, 1)) : 0
        for dx in [-9.0, 0.0, 9.0] {
            let x = geo.p(dx, 0).x, y0 = geo.p(0, 4).y
            if pTop - y0 > 14 { carArrow(&c, BP.pt(x, y0 + 4), BP.pt(x, pTop - 5), color: ink, alpha: 0.85 * travel) }
        }

        // the bike pedal beside it, turning with the same angle
        let hip = BP.pt(256, 56), ctr = BP.pt(256, 142), crankLen = 22.0
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.3, 0.8))) { g in
            let ringP = Path(ellipseIn: CGRect(x: ctr.x - 16, y: ctr.y - 16, width: 32, height: 32))
            g.fill(ringP, with: .color(BP.paper)); g.stroke(ringP, with: .color(ink.opacity(0.8)), lineWidth: BP.hair)
            let pedal = BP.pt(ctr.x + crankLen * sin(th), ctr.y - crankLen * cos(th))
            // two-bone leg, knee bending to the right
            let a = 52.0, b = 54.0
            let dx = pedal.x - hip.x, dy = pedal.y - hip.y, d = hypot(dx, dy)
            let ux = dx / d, uy = dy / d
            let ca = (a * a + d * d - b * b) / (2 * a * d)
            let h = a * sqrt(max(0, 1 - ca * ca))
            let knee = BP.pt(hip.x + ux * a * ca + uy * h, hip.y + uy * a * ca - ux * h)
            carBar(&g, hip, knee, w: 9, ink: ink)
            carBar(&g, knee, pedal, w: 7.5, ink: ink)
            carBar(&g, ctr, pedal, w: 4.6, ink: ink)
            g.fill(Path(ellipseIn: CGRect(x: ctr.x - 4, y: ctr.y - 4, width: 8, height: 8)), with: .color(ink))
            let foot = CGRect(x: pedal.x - 2, y: pedal.y - 3.5, width: 14, height: 7)
            g.fill(Path(roundedRect: foot, cornerRadius: 3), with: .color(BP.paper))
            g.stroke(Path(roundedRect: foot, cornerRadius: 3), with: .color(ink), lineWidth: BP.edge)
        }

        // labels: parts down the left, tracking the moving ones
        let pistonAt = geo.p(-18, CE.pinY(th) - 2)
        let rodMid = BP.mixp(geo.p(0, CE.pinY(th)), geo.p(CE.r * sin(th), CE.cy - CE.r * cos(th)), 0.5)
        let armMid = geo.p(CE.r * sin(th) * 0.5, CE.cy - CE.r * cos(th) * 0.5)
        bpLeader(&c, anchor: geo.p(-29, 24), elbow: BP.pt(104, 66), tail: -4, text: "CYLINDER", ink: ink, p: BP.pr(t, 0.2, 0.7))
        bpLeader(&c, anchor: pistonAt, elbow: BP.pt(104, 106), tail: -4, text: "PISTON", ink: ink, p: BP.pr(t, 0.3, 0.8))
        bpLeader(&c, anchor: rodMid, elbow: BP.pt(104, 138), tail: -4, text: "ROD", ink: ink, p: BP.pr(t, 0.4, 0.9))
        bpLeader(&c, anchor: armMid, elbow: BP.pt(104, 174), tail: -4, text: "BENT SHAFT", ink: ink, p: BP.pr(t, 0.5, 1.0))
        bpLeader(&c, anchor: BP.pt(ctr.x - 8, ctr.y + 18), elbow: BP.pt(222, 216), tail: 0, text: "BIKE PEDAL", ink: ink, p: BP.pr(t, 0.6, 1.1))
    }
}

// MARK: - Card 3: four small cylinders in a row, one move each; only the push has a spark and a mustard piston

struct CarStrokes: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 1.9,
                       label: "Four small cutaway cylinders in a row, one for each move of the piston. First it pulls fuel and air in through the open valve on one side. Then it squeezes them with both valves shut. Then a spark lights them and the hot gas pushes the piston down, shown in gold. Last it clears the used gas out through the open valve on the other side. The moves play in order from left to right.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, max(t, clock)) }, size: carSize)
    }

    private static let s = 0.62, oy = 112.0
    private static let names = ["PULLS IN", "SQUEEZES", "PUSH", "CLEARS OUT"]

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ tt: Double) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.45))
        // Each cylinder does its stroke in turn (0.65 s, 0.7 s apart), then turns the shaft on through the next half turn to be ready
        // again; the sequence repeats every 2.8 s with the shaft always turning forward, so the loop has no jump.
        let period = 2.8
        for i in 0..<4 {
            let geo = CarGeo(ox: 56 + 78 * Double(i), oy: oy, s: s)
            let raw = tt - 0.5 - 0.7 * Double(i)
            let w = raw < 0 ? 2.0 : raw.truncatingRemainder(dividingBy: period)
            let start = Double(i) * .pi
            var phase = start, gas = carGas(start)
            if w < 0.65 {
                phase = start + .pi * BP.eio(BP.pr(w, 0, 0.65)); gas = carGas(phase)
            } else if w >= 0.8 && w < 1.3 {
                let r = BP.eio(BP.pr(w, 0.8, 1.3))
                phase = start + .pi + .pi * r
                let a = carGas(start + .pi), b = carGas(start)
                gas = CarGas(gas: BP.mix(a.gas, b.gas, r), hot: BP.mix(a.hot, 0, r), intake: 0, exhaust: 0, spark: 0)
            } else if w >= 0.65 && w < 0.8 {
                phase = start + .pi; gas = carGas(start + .pi)
            }
            if i == 2 {
                if w < 0.65 { gas.hot *= BP.pr(w, 0.05, 0.25) } else if w >= 1.3 || w < 0 { gas.hot = 0 }
                gas.spark = w < 0.65 ? BP.pr(w, 0, 0.06) * (1 - BP.pr(w, 0.1, 0.45)) : 0
            }
            var cyl = CarCyl(theta: phase, gas: gas)
            if i == 2 { cyl.pistonTint = acc }
            bpGroup(&c, alpha: a0) { g in carEngine(&g, geo, [cyl], ink: ink) }

            // fuel and air in, used gas out: an arrow along the open valve's port
            if i == 0 {
                let q = carPort(geo, 0, -11)
                carArrow(&c, BP.pt(q.x, q.y - 16), BP.pt(q.x, q.y - 2), color: ink, alpha: gas.intake)
            }
            if i == 3 {
                let q = carPort(geo, 0, 11)
                carArrow(&c, BP.pt(q.x, q.y - 2), BP.pt(q.x, q.y - 16), color: ink, alpha: gas.exhaust)
            }
            let tx = geo.p(0, 0).x, isPush = i == 2
            bpText(&c, names[i], BP.pt(tx, 202), ink: isPush ? acc : ink, alpha: BP.pr(t, 0.2 + 0.1 * Double(i), 0.6 + 0.1 * Double(i)))
        }

        let g0 = CarGeo(ox: 56, oy: oy, s: s), g2 = CarGeo(ox: 212, oy: oy, s: s), g3 = CarGeo(ox: 290, oy: oy, s: s)
        bpLeader(&c, anchor: carPort(g0, 0, -11), elbow: BP.pt(49, 72), tail: 0, text: "FUEL AND AIR IN", ink: ink, p: BP.pr(t, 0.3, 0.8))
        bpLeader(&c, anchor: carPort(g3, 0, 11), elbow: BP.pt(297, 72), tail: -4, text: "USED GAS OUT", ink: ink, p: BP.pr(t, 0.4, 0.9))
        bpLeader(&c, anchor: carPort(g2, 0, 0), elbow: BP.pt(170, 30), tail: -4, text: "SPARK", ink: ink, p: BP.pr(t, 0.5, 1.0))
    }
}

// MARK: - Card 4: the motor turns the shaft by belt; the shaft drags the piston up, and the first spark lights the squeezed mix

struct CarDrag: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 2.5,
                       label: "A cutaway cylinder with the shaft below it. A gold electric motor at the right turns the shaft through a belt. The shaft drags the piston down to pull fuel and air in, then up to squeeze it. At the top a gold spark lights the first squeezed load, the belt lets go, and the push begins.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, max(t, clock)) }, size: carSize)
    }

    private static let geo = CarGeo(ox: 118, oy: 70, s: 1.0)

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ tt: Double) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.45))
        // the shaft is dragged through the pull and the squeeze; the push after the spark is the engine's own
        // after the spark the engine winds up from rest and keeps turning and firing on its own, so nothing freezes
        let ru = max(0, tt - 2.5), rramp = 0.5
        let th = Double.pi * BP.eio(BP.pr(tt, 0.5, 1.5)) + Double.pi * BP.eio(BP.pr(tt, 1.5, 2.5))
            + 6 * (ru < rramp ? ru * ru / (2 * rramp) : ru - rramp / 2)

        var gas = carGas(th)
        let sparkOn = BP.pr(t, 2.35, 2.5)
        gas.spark *= sparkOn
        if t < 2.45 { gas.hot = 0 }
        bpGroup(&c, alpha: a0) { g in carEngine(&g, geo, [CarCyl(theta: th, gas: gas, sparkColor: acc)], ink: ink) }

        let crank = geo.p(0, CE.cy)
        let pulley = BP.pt(186, crank.y), motor = BP.pt(276, crank.y)
        let belt = BP.pr(t, 0.3, 0.6) * (1 - BP.pr(t, 2.55, 2.85))
        let thBelt = Double.pi * BP.eio(BP.pr(t, 0.5, 1.5)) + Double.pi * BP.eio(BP.pr(t, 1.5, 2.5))

        // the shaft carries on out of the block to a pulley
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.05, 0.5))) { g in
            carBar(&g, BP.pt(crank.x, crank.y), BP.pt(pulley.x, pulley.y), w: 5.4, ink: ink)
            carWheel(&g, pulley, r: 12, angle: th, color: ink, tint: 0.14)
        }

        // the motor: gold can, small pulley, a foot
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.05, 0.5))) { g in
            let foot = CGRect(x: 260, y: motor.y + 20, width: 32, height: 8)
            g.fill(Path(foot), with: .color(BP.paper)); g.fill(Path(foot), with: .color(ink.opacity(0.14)))
            g.stroke(Path(foot), with: .color(ink), lineWidth: BP.edge)
            let can = Path(ellipseIn: CGRect(x: motor.x - 22, y: motor.y - 22, width: 44, height: 44))
            let on = 1 - 0.65 * BP.pr(t, 2.5, 2.9)
            g.fill(can, with: .color(BP.paper)); g.fill(can, with: .color(acc.opacity(0.28 * on)))
            g.stroke(can, with: .color(acc), lineWidth: BP.edge)
            g.stroke(Path(ellipseIn: CGRect(x: motor.x - 15, y: motor.y - 15, width: 30, height: 30)), with: .color(acc.opacity(0.7)), lineWidth: BP.hair)
            carWheel(&g, motor, r: 8, angle: thBelt * 1.8, color: acc, tint: 0.3)
        }

        // the belt: moving dashes, gone when the motor lets go
        if belt > 0.01 {
            var top = Path(), bottom = Path()
            top.move(to: BP.pt(pulley.x, pulley.y - 12)); top.addLine(to: BP.pt(motor.x, motor.y - 8))
            bottom.move(to: BP.pt(motor.x, motor.y + 8)); bottom.addLine(to: BP.pt(pulley.x, pulley.y + 12))
            let style = StrokeStyle(lineWidth: 2, lineCap: .butt, dash: [5, 3], dashPhase: -thBelt * 9)
            c.stroke(top, with: .color(ink.opacity(belt)), style: style)
            c.stroke(bottom, with: .color(ink.opacity(belt)), style: style)
        }

        // the first spark stays marked on the plug
        let dot = BP.pr(t, 2.45, 2.6)
        let sp = geo.p(0, 4)
        c.fill(Path(ellipseIn: CGRect(x: sp.x - 2.4, y: sp.y - 2.4, width: 4.8, height: 4.8)), with: .color(acc.opacity(dot)))

        bpLeader(&c, anchor: geo.p(-29, 24), elbow: BP.pt(76, 70), tail: -4, text: "CYLINDER", ink: ink, p: BP.pr(t, 0.2, 0.7))
        bpLeader(&c, anchor: BP.pt(166, crank.y), elbow: BP.pt(166, 232), tail: -4, text: "SHAFT DRAGS THE PISTON", ink: ink, p: BP.pr(t, 0.4, 1.0))
        bpLeader(&c, anchor: BP.pt(motor.x, motor.y - 22), elbow: BP.pt(motor.x, 92), tail: -4, text: "ELECTRIC MOTOR", ink: ink, p: BP.pr(t, 0.3, 0.8))
        bpLeader(&c, anchor: geo.p(0, CE.headTop - 9), elbow: BP.pt(118, 26), tail: 0, text: "FIRST SPARK", ink: ink, p: BP.pr(t, 2.3, 2.9))
    }
}

// MARK: - Card 5: four cylinders push in turn on one shaft with a heavy wheel on its end; their pushes blend into a steadier line

struct CarFlywheel: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 1.05,
                       label: "A cutaway engine with four cylinders in a row and a heavy gold wheel on the end of the shaft. The cylinders fire one after another. Below, a graph of the pushes on the shaft grows as it goes. Each push is a hump that rises and fades, and the humps overlap, so the line they add up to stays steadier, with the heavy wheel carrying the shaft through the gaps.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, max(t, clock)) }, size: carSize)
    }

    private static let geo = CarGeo(ox: 44, oy: 62, s: 0.7)
    private static let gx0 = 44.0, gw = 200.0, gBase = 250.0, gH = 38.0

    /// One push: a hump that rises and fades over 1.5 pi of shaft turn, starting at `start`.
    private static func hump(_ phi: Double, start: Double) -> Double {
        let u = (phi - start) / (1.5 * .pi)
        return u <= 0 || u >= 1 ? 0 : pow(sin(.pi * u), 1.5)
    }
    private static func gpt(_ phi: Double, _ v: Double, _ ws: Double) -> CGPoint { BP.pt(gx0 + gw * (phi - ws) / (4 * .pi), gBase - gH * v) }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ tt: Double) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.45))
        let phi = max(0, tt - 0.4) * 4 * Double.pi / 2.6, span = 4 * Double.pi, ws = max(0, phi - span)      // the graph scrolls once it fills

        var cyls: [CarCyl] = []
        for i in 0..<4 { cyls.append(CarCyl(theta: phi + Double(i) * .pi, gas: carGas(phi + Double(i) * .pi))) }
        bpGroup(&c, alpha: a0) { g in carEngine(&g, geo, cyls, ink: ink) }

        // the shaft out of the block, and the heavy wheel on its end
        let crank = geo.p(0, CE.cy), wheel = BP.pt(236, crank.y), wr = 34.0
        let endX = geo.p(geo.cx(3) + CE.wall, 0).x
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.05, 0.5))) { g in
            carBar(&g, BP.pt(endX - 6, crank.y), BP.pt(wheel.x, crank.y), w: 5, ink: ink)
            // thickness behind: a second rim and the two lines joining them
            let d = BP.pt(8, -4.5), dl = hypot(d.x, d.y), nx = -d.y / dl, ny = d.x / dl
            let back = Path(ellipseIn: CGRect(x: wheel.x + d.x - wr, y: wheel.y + d.y - wr, width: 2 * wr, height: 2 * wr))
            g.fill(back, with: .color(BP.paper)); g.fill(back, with: .color(acc.opacity(0.2)))
            var join = Path()
            for sgn in [-1.0, 1.0] {
                join.move(to: BP.pt(wheel.x + sgn * nx * wr, wheel.y + sgn * ny * wr))
                join.addLine(to: BP.pt(wheel.x + d.x + sgn * nx * wr, wheel.y + d.y + sgn * ny * wr))
            }
            g.stroke(back, with: .color(acc), lineWidth: BP.edge)
            g.stroke(join, with: .color(acc), lineWidth: BP.edge)
            // the front face: heavy rim, holes that turn with the shaft, hub
            let face = Path(ellipseIn: CGRect(x: wheel.x - wr, y: wheel.y - wr, width: 2 * wr, height: 2 * wr))
            g.fill(face, with: .color(BP.paper)); g.fill(face, with: .color(acc.opacity(0.34)))
            g.stroke(face, with: .color(acc), lineWidth: BP.edge)
            g.stroke(Path(ellipseIn: CGRect(x: wheel.x - 26, y: wheel.y - 26, width: 52, height: 52)), with: .color(acc.opacity(0.8)), lineWidth: BP.hair)
            for k in 0..<4 {
                let a = phi + Double(k) * .pi / 2, hc = BP.pt(wheel.x + 16 * cos(a), wheel.y + 16 * sin(a))
                let hole = Path(ellipseIn: CGRect(x: hc.x - 5, y: hc.y - 5, width: 10, height: 10))
                g.fill(hole, with: .color(BP.paper)); g.stroke(hole, with: .color(acc), lineWidth: BP.hair)
            }
            let hub = Path(ellipseIn: CGRect(x: wheel.x - 6, y: wheel.y - 6, width: 12, height: 12))
            g.fill(hub, with: .color(acc.opacity(0.75))); g.stroke(hub, with: .color(acc), lineWidth: BP.hair)
        }
        // an arc arrow around the wheel: it keeps going
        var arc = Path()
        for i in 0...24 {
            let a = -2.2 + 3.6 * Double(i) / 24, q = BP.pt(wheel.x + (wr + 9) * cos(a), wheel.y + (wr + 9) * sin(a))
            if i == 0 { arc.move(to: q) } else { arc.addLine(to: q) }
        }
        let aEnd = -2.2 + 3.6, ae = BP.pt(wheel.x + (wr + 9) * cos(aEnd), wheel.y + (wr + 9) * sin(aEnd))
        let tan = BP.pt(-sin(aEnd), cos(aEnd))
        arc.move(to: BP.pt(ae.x - tan.x * 5 - tan.y * 3, ae.y - tan.y * 5 + tan.x * 3)); arc.addLine(to: ae)
        arc.addLine(to: BP.pt(ae.x - tan.x * 5 + tan.y * 3, ae.y - tan.y * 5 - tan.x * 3))
        bpTrace(&c, arc, p: BP.pr(t, 1.8, 2.4), color: acc.opacity(0.9), width: BP.hair)

        // the graph: pushes on the shaft over two turns, each hump overlapping the next, and the line they add up to
        let ga = BP.pr(t, 0.2, 0.6)
        var axes = Path()
        axes.move(to: BP.pt(gx0, gBase)); axes.addLine(to: BP.pt(gx0, gBase - 62)); axes.move(to: BP.pt(gx0 - 4, gBase - 56)); axes.addLine(to: BP.pt(gx0, gBase - 63)); axes.addLine(to: BP.pt(gx0 + 4, gBase - 56))
        axes.move(to: BP.pt(gx0, gBase)); axes.addLine(to: BP.pt(gx0 + gw + 6, gBase)); axes.move(to: BP.pt(gx0 + gw, gBase - 4)); axes.addLine(to: BP.pt(gx0 + gw + 7, gBase)); axes.addLine(to: BP.pt(gx0 + gw, gBase + 4))
        bpTrace(&c, axes, p: ga, color: ink)
        let steps = 160
        let m0 = Int((ws / .pi).rounded(.down)) - 2, m1 = Int((phi / .pi).rounded(.up))
        let starts = (m0...m1).map { Double($0) * Double.pi }
        for st in starts {
            var fill = Path(), line = Path()
            var started = false
            for k in 0...steps {
                let ph = ws + (phi - ws) * Double(k) / Double(steps)
                guard ph >= st, ph <= st + 1.5 * .pi else { continue }
                let q = gpt(ph, hump(ph, start: st), ws)
                if !started { fill.move(to: BP.pt(q.x, gBase)); fill.addLine(to: q); line.move(to: q); started = true } else { fill.addLine(to: q); line.addLine(to: q) }
            }
            guard started else { continue }
            if let last = line.currentPoint { fill.addLine(to: BP.pt(last.x, gBase)); fill.closeSubpath() }
            c.fill(fill, with: .color(ink.opacity(0.12)))
            c.stroke(line, with: .color(ink.opacity(0.7)), style: StrokeStyle(lineWidth: BP.hair, lineJoin: .round))
        }
        var sum = Path()
        for k in 0...steps {
            let ph = ws + (phi - ws) * Double(k) / Double(steps)
            var v = 0.0
            for st in starts { v += hump(ph, start: st) }
            let q = gpt(ph, v, ws)
            if k == 0 { sum.move(to: q) } else { sum.addLine(to: q) }
        }
        if phi > 0.05 { c.stroke(sum, with: .color(ink), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)) }
        if phi > 0.001 && phi < span {
            let x = gpt(phi, 0, ws).x
            bpGuide(&c, BP.pt(x, gBase - 60), BP.pt(x, gBase), color: ink.opacity(0.35))
        }

        bpLeader(&c, anchor: geo.p(geo.cx(0) + CE.wall, CE.headTop), elbow: BP.pt(26, 30), tail: 10, text: "CYLINDERS", ink: ink, p: BP.pr(t, 0.2, 0.7))
        bpLeader(&c, anchor: BP.pt(wheel.x - 4, wheel.y - wr - 4), elbow: BP.pt(232, 54), tail: 0, text: "HEAVY WHEEL", ink: ink, p: BP.pr(t, 0.3, 0.8))
        bpLeader(&c, anchor: BP.pt(gx0, gBase - 56), elbow: BP.pt(gx0, 172), tail: 0, text: "PUSH ON THE SHAFT", ink: ink, p: BP.pr(t, 0.4, 0.9))
    }
}
