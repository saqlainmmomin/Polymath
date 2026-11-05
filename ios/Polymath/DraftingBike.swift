import SwiftUI

// Drafting parts made for bike-gears (2026-11-04): a bicycle with a rider, the drive train as two big gears and a chain, and a walker.
// Same conventions as DraftingParts: `on` draws the outlines, `fill` fades the white fills in. Tubes are drawn as outlined tubes (a black
// line with a white one down the middle) so a frame reads as metal, not as a single stroke.

extension DR {
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
    private static func poly(_ p: [CGPoint], closed: Bool = false) -> Path { var path = Path(); path.addLines(p); if closed { path.closeSubpath() }; return path }
    private static func circle(_ c: CGPoint, _ r: Double) -> Path { Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)) }

    /// A tube: a heavy black line with a white one inside it.
    private static func tube(_ c: inout GraphicsContext, _ pts: [CGPoint], w: Double = 3.4, on: Double, fill: Double) {
        let p = poly(pts)
        DR.draw(&c, p, p: on, width: w)
        var g = c; g.opacity *= fill
        g.stroke(p.trimmedPath(from: 0, to: BP.cl(on)), with: .color(DR.face), style: StrokeStyle(lineWidth: w - 1.9, lineCap: .round, lineJoin: .round))
    }

    /// The closed loop of a chain round two rings, `c1` radius `r1` and `c2` radius `r2` (the outer tangents and the arcs), as points.
    static func chainLoop(_ c1: CGPoint, _ r1: Double, _ c2: CGPoint, _ r2: Double) -> [CGPoint] {
        let d = hypot(c2.x - c1.x, c2.y - c1.y), th = atan2(c2.y - c1.y, c2.x - c1.x)
        let al = acos(max(-1, min(1, (r1 - r2) / d)))
        func on(_ c: CGPoint, _ r: Double, _ a: Double) -> CGPoint { pt(c.x + r * cos(a), c.y + r * sin(a)) }
        var out: [CGPoint] = []
        for i in 0...16 { out.append(on(c2, r2, th - al + 2 * al * Double(i) / 16)) }                         // round the second ring, the far side
        for i in 0...24 { out.append(on(c1, r1, th + al + (2 * .pi - 2 * al) * Double(i) / 24)) }              // then round the first, the near side
        return out
    }

    /// Link marks along a loop: a chain drawn as a black band with a white middle and pins. `march` slides the pins along it.
    static func chain(_ c: inout GraphicsContext, _ loop: [CGPoint], on: Double, march: Double, width: Double = 3.6) {
        var p = poly(loop, closed: true)
        p.closeSubpath()
        DR.draw(&c, p, p: on, width: width)
        c.stroke(p.trimmedPath(from: 0, to: BP.cl(on)), with: .color(DR.face), style: StrokeStyle(lineWidth: width - 1.7, lineCap: .round, lineJoin: .round))
        c.stroke(p.trimmedPath(from: 0, to: BP.cl(on)), with: .color(DR.ink),
                 style: StrokeStyle(lineWidth: width - 1.2, lineCap: .butt, lineJoin: .round, dash: [0.9, 3.1], dashPhase: march))
    }

    /// A gear wheel: a ring with teeth round it, five arms and a hub, turned `turn` turns; `marker` puts a yellow dot on the rim at the start of the turn.
    static func gearWheel(_ c: inout GraphicsContext, at m: CGPoint, r: Double, turn: Double, on: Double, fill: Double, marker: Bool, accent: Bool = false, arms: Int = 5) {
        let a0 = turn * 2 * .pi
        var g = c; g.opacity *= fill
        let disc = circle(m, r)
        g.fill(disc, with: .color(accent ? DR.accent : DR.face))
        // teeth: a short-dashed heavy band just outside the ring
        let teeth = circle(m, r + 1.6)
        c.stroke(teeth.trimmedPath(from: 0, to: BP.cl(on)), with: .color(DR.ink), style: StrokeStyle(lineWidth: 3.2, lineCap: .butt, dash: [1.5, 1.6], dashPhase: a0 * r * 0.52))
        DR.draw(&c, disc, p: on, width: DR.line)
        if r > 9 {
            let inner = circle(m, r * 0.62)
            DR.draw(&c, inner, p: on, width: DR.hair + 0.1)
            var spokes = Path()
            for i in 0..<arms {
                let a = a0 + Double(i) / Double(arms) * 2 * .pi
                spokes.move(to: pt(m.x + r * 0.22 * cos(a), m.y + r * 0.22 * sin(a))); spokes.addLine(to: pt(m.x + r * 0.62 * cos(a), m.y + r * 0.62 * sin(a)))
            }
            DR.draw(&c, spokes, p: on, width: DR.line + 0.5)
        }
        g.fill(circle(m, max(2, r * 0.16)), with: .color(DR.side))
        DR.draw(&c, circle(m, max(2, r * 0.16)), p: on, width: DR.hair + 0.1)
        if marker {
            let q = pt(m.x + (r - 3.2) * cos(a0 - .pi / 2), m.y + (r - 3.2) * sin(a0 - .pi / 2))
            var mg = c; mg.opacity *= BP.cl(on * 2 - 1)
            mg.fill(circle(q, 3.4), with: .color(DR.accent)); mg.stroke(circle(q, 3.4), with: .color(DR.ink), lineWidth: DR.hair + 0.2)
        }
    }

    // MARK: the drive train alone

    /// The pedal ring (radius 40, 44 teeth) at the left, a back ring at the right and the chain round both, centred on the origin: the rings are 120 apart.
    /// `turn` is how many turns the pedal ring has made; the back ring turns 44 / `rear` teeth as often. `rear` is the back ring's radius and teeth count
    /// together (28 is the big one, 14 the small), and it can slide between them: the faint circles show where the other rings sit.
    static func gearPair(_ c: inout GraphicsContext, on: Double, fill: Double, turn: Double, rear: Double, marker: Double) {
        let c1 = pt(-58, 0), c2 = pt(62, 0), R = 40.0, r = rear
        // the stack of other rings, faint, behind the one in use
        var stack = Path()
        for rr in [28.0, 21.0, 14.0] { stack.addEllipse(in: CGRect(x: c2.x - rr, y: c2.y - rr, width: 2 * rr, height: 2 * rr)) }
        DR.draw(&c, stack, p: on, width: DR.hair, color: DR.ink.opacity(0.35), dash: [2, 2.5])
        chain(&c, chainLoop(c1, R, c2, r), on: on, march: turn * 2 * .pi * R * 0.0 - turn * 2 * .pi * R)
        gearWheel(&c, at: c1, r: R, turn: turn, on: on, fill: fill, marker: marker > 0.5)
        gearWheel(&c, at: c2, r: r, turn: turn * R / r, on: on, fill: fill, marker: marker > 0.5, accent: marker > 0.5, arms: r > 12 ? 5 : 4)
    }

    // MARK: bicycle

    /// A bicycle seen from the side, 210 wide and 118 tall, standing on the origin: wheels of radius 36 with spokes, an outlined frame, saddle and bars,
    /// pedal ring, chain and a back ring. `wheel` and `crank` are turns made so far; `rear` the back ring's radius (10 big, 5 small); `rider` 1 puts a rider on it
    /// (legs follow the pedals); `lever` 0...1 lights the gear lever yellow; `lean` degrees the rider leans forward over the bars (default 38).
    static func bike(_ c: inout GraphicsContext, on: Double, fill: Double, wheel: Double, crank: Double, rear: Double, rider: Double, lever: Double, lean: Double, hot: Bool = false) {
        let ra = pt(-50, -36), fb = pt(50, -36), bb = pt(-2, -21), seat = pt(-19, -76), h1 = pt(37, -80), h2 = pt(41, -64)
        // wheels
        for (m, ph) in [(ra, 0.0), (fb, 0.5)] {
            var g = c; g.opacity *= fill
            g.fill(circle(m, 35), with: .color(DR.face))
            var spokes = Path()
            for i in 0..<18 { let a = (wheel + ph) * 2 * .pi + Double(i) / 18 * 2 * .pi; spokes.move(to: pt(m.x + 4 * cos(a), m.y + 4 * sin(a))); spokes.addLine(to: pt(m.x + 30 * cos(a), m.y + 30 * sin(a))) }
            DR.draw(&c, spokes, p: on, width: 0.55, color: DR.ink.opacity(0.7))
            DR.draw(&c, circle(m, 30), p: on, width: DR.hair + 0.15)
            DR.draw(&c, circle(m, 34.2), p: on, width: 3.8)
            c.stroke(circle(m, 34.2).trimmedPath(from: 0, to: BP.cl(on)), with: .color(DR.side), lineWidth: 1.8)
            g.fill(circle(m, 4.2), with: .color(DR.face)); DR.draw(&c, circle(m, 4.2), p: on, width: DR.line)
            // a mark on the tyre so a turn shows
            let a = (wheel + ph) * 2 * .pi
            var tm = Path(); tm.move(to: pt(m.x + 31 * cos(a), m.y + 31 * sin(a))); tm.addLine(to: pt(m.x + 35.6 * cos(a), m.y + 35.6 * sin(a)))
            DR.draw(&c, tm, p: on, width: 1.2, color: DR.ink.opacity(0.9))
        }
        // the drive train
        let chainR = 14.0
        let rearC = ra
        chain(&c, chainLoop(bb, chainR, rearC, rear), on: on, march: -crank * 2 * .pi * chainR)
        // the other back rings, faint
        var cass = Path()
        for rr in [10.0, 7.5, 5.0] { cass.addEllipse(in: CGRect(x: ra.x - rr, y: ra.y - rr, width: 2 * rr, height: 2 * rr)) }
        DR.draw(&c, cass, p: on, width: DR.hair, color: DR.ink.opacity(0.35))
        gearWheel(&c, at: rearC, r: rear, turn: crank * chainR / rear, on: on, fill: fill, marker: false, accent: hot, arms: 0)
        gearWheel(&c, at: bb, r: chainR, turn: crank, on: on, fill: fill, marker: false, arms: 5)
        // derailleur, hanging under the back ring
        let der = poly([pt(ra.x + 2, ra.y + 3), pt(ra.x - 7, ra.y + 22)])
        DR.draw(&c, der, p: on, width: 2)
        DR.draw(&c, circle(pt(ra.x - 7, ra.y + 22), 3), p: on, width: DR.hair + 0.2)
        DR.draw(&c, circle(pt(ra.x - 2, ra.y + 29), 2.4), p: on, width: DR.hair + 0.2)
        // frame
        tube(&c, [ra, bb], on: on, fill: fill)
        tube(&c, [ra, seat], w: 3, on: on, fill: fill)
        tube(&c, [bb, seat], on: on, fill: fill)
        tube(&c, [seat, h1], on: on, fill: fill)
        tube(&c, [bb, h2], w: 4, on: on, fill: fill)
        tube(&c, [h1, h2], w: 4.2, on: on, fill: fill)
        tube(&c, [h2, pt(46, -50), fb], w: 3, on: on, fill: fill)
        // saddle and bars
        var g = c; g.opacity *= fill
        let post = poly([seat, pt(seat.x - 1, seat.y - 7)])
        DR.draw(&c, post, p: on, width: 2.4)
        let saddle = Path { p in
            p.move(to: pt(seat.x - 13, seat.y - 9)); p.addQuadCurve(to: pt(seat.x + 9, seat.y - 9), control: pt(seat.x - 2, seat.y - 15))
            p.addQuadCurve(to: pt(seat.x - 13, seat.y - 9), control: pt(seat.x - 3, seat.y - 5))
        }
        g.fill(saddle, with: .color(DR.ink.opacity(0.85))); DR.draw(&c, saddle, p: on, width: DR.line)
        let stem = poly([h1, pt(h1.x - 2, h1.y - 8), pt(h1.x - 12, h1.y - 11), pt(h1.x - 15, h1.y - 4)])
        DR.draw(&c, stem, p: on, width: 2.6)
        // the gear lever: a small paddle on the bar, yellow when clicked
        let lv = Path(roundedRect: CGRect(x: h1.x - 13, y: h1.y - 9, width: 7.5, height: 3.4), cornerRadius: 1.4)
        g.fill(lv, with: .color(DR.face))
        if lever > 0.01 { var lg = g; lg.opacity *= lever; lg.fill(Path(roundedRect: CGRect(x: h1.x - 14.5, y: h1.y - 10.5, width: 10.5, height: 6.4), cornerRadius: 2.6), with: .color(DR.accent)) }
        DR.draw(&c, lv, p: on, width: DR.hair + 0.3)
        // pedals and cranks
        let ang = crank * 2 * .pi, cr = 15.0
        let p1 = pt(bb.x + cr * cos(ang), bb.y + cr * sin(ang)), p2 = pt(bb.x - cr * cos(ang), bb.y - cr * sin(ang))
        DR.draw(&c, poly([p2, bb, p1]), p: on, width: 2.6)
        for p in [p1, p2] {
            let pedal = Path(roundedRect: CGRect(x: p.x - 5, y: p.y - 1.4, width: 10, height: 2.8), cornerRadius: 1)
            g.fill(pedal, with: .color(DR.side)); DR.draw(&c, pedal, p: on, width: DR.hair + 0.3)
        }
        // the rider (redrawn 2026-11-05 after a monoline road-cyclist reference): hip on the saddle, a long arched back leaning to the bars,
        // long legs that follow the pedals, a bent arm to the hoods, a helmet with vents and sunglasses
        if rider > 0.01 {
            var rg = c; rg.opacity *= rider
            let hip = pt(seat.x - 3, seat.y - 12), lr = lean * .pi / 180
            let u = pt(sin(lr), -cos(lr)), nb = pt(u.y, -u.x), nc = pt(-u.y, u.x)       // along the back, to its top side, to its chest side
            let shoulder = pt(hip.x + 47 * u.x, hip.y + 47 * u.y)
            func tubeLimb(_ pts: [CGPoint], _ w: Double, _ col: Color) {
                let p = poly(pts)
                rg.stroke(p, with: .color(DR.ink), style: StrokeStyle(lineWidth: w + 2, lineCap: .round, lineJoin: .round))
                rg.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
            }
            func leg(_ foot: CGPoint, back: Bool) {
                let l1 = 41.0, l2 = 39.0
                let ankle = pt(foot.x - 1, foot.y - 3)
                let dx = ankle.x - hip.x, dy = ankle.y - hip.y, d = min(hypot(dx, dy), l1 + l2 - 0.6)
                let k = (l1 * l1 - l2 * l2 + d * d) / (2 * d), hh = sqrt(max(0, l1 * l1 - k * k))
                let ux = dx / hypot(dx, dy), uy = dy / hypot(dx, dy)
                let knee = pt(hip.x + ux * k + uy * hh, hip.y + uy * k - ux * hh)         // knee bends forward
                let col = back ? DR.side : DR.face
                tubeLimb([hip, knee], 7.4, col)
                tubeLimb([knee, ankle], 5.2, col)
                let shoe = Path { p in
                    p.move(to: pt(ankle.x - 3.5, ankle.y - 2)); p.addLine(to: pt(ankle.x + 3, ankle.y - 3.2)); p.addQuadCurve(to: pt(ankle.x + 11, ankle.y + 1.5), control: pt(ankle.x + 8, ankle.y - 2.5))
                    p.addLine(to: pt(ankle.x + 11, ankle.y + 3.6)); p.addLine(to: pt(ankle.x - 3.5, ankle.y + 3.6)); p.closeSubpath()
                }
                rg.fill(shoe, with: .color(back ? DR.side : DR.face)); rg.stroke(shoe, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
            }
            leg(p2, back: true)
            // torso: an arched back from the hip to the shoulder, a flatter chest side, shaded like a jersey
            func at(_ t: Double, _ off: Double, _ n: CGPoint) -> CGPoint { pt(hip.x + u.x * 47 * t + n.x * off, hip.y + u.y * 47 * t + n.y * off) }
            let torso = Path { p in
                p.move(to: at(0, 6, nb)); p.addQuadCurve(to: at(1, 7, nb), control: at(0.5, 14, nb))
                p.addQuadCurve(to: at(1.06, -1, nb), control: at(1.1, 6, nb))
                p.addLine(to: at(1, 6, nc)); p.addQuadCurve(to: at(0, 5, nc), control: at(0.5, 7, nc)); p.closeSubpath()
            }
            rg.fill(torso, with: .color(DR.face))
            rg.stroke(torso, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
            // the arm: a bent elbow, forearm down to the hoods on the bars
            let hand = pt(h1.x - 10, h1.y - 10)
            let elbow = pt((shoulder.x + hand.x) / 2 + 3, (shoulder.y + hand.y) / 2 + 8)
            tubeLimb([shoulder, elbow], 6, DR.face)
            tubeLimb([elbow, hand], 4.8, DR.face)
            let hood = Path(roundedRect: CGRect(x: hand.x - 3, y: hand.y - 4, width: 11, height: 6.5), cornerRadius: 3)
            rg.fill(hood, with: .color(DR.face)); rg.stroke(hood, with: .color(DR.ink), lineWidth: DR.line)
            leg(p1, back: false)
            // head: tucked in, helmet with vents, sunglasses
            let head = pt(shoulder.x + 11, shoulder.y - 5)
            rg.fill(circle(head, 6.4), with: .color(DR.face)); rg.stroke(circle(head, 6.4), with: .color(DR.ink), lineWidth: DR.line)
            let helmet = Path { p in
                p.move(to: pt(head.x - 9.5, head.y + 1.5)); p.addQuadCurve(to: pt(head.x + 7.5, head.y - 4.5), control: pt(head.x - 6, head.y - 13))
                p.addQuadCurve(to: pt(head.x - 9.5, head.y + 1.5), control: pt(head.x + 1, head.y - 2.5))
            }
            rg.fill(helmet, with: .color(DR.side)); rg.stroke(helmet, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
            var vents = Path()
            for i in 0..<2 { vents.move(to: pt(head.x - 4 + Double(i) * 3.4, head.y - 6.2 + Double(i) * 0.6)); vents.addLine(to: pt(head.x - 1.4 + Double(i) * 3.4, head.y - 7.6 + Double(i) * 0.6)) }
            rg.stroke(vents, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.hair + 0.3, lineCap: .round))
            let glasses = Path(roundedRect: CGRect(x: head.x + 1.5, y: head.y - 2.2, width: 6, height: 3.4), cornerRadius: 1.4)
            rg.fill(glasses, with: .color(DR.ink))
        }
    }

    // MARK: walker

    /// A walker seen from the side, feet at the origin, 66 tall, facing right, leaning `lean` degrees into a climb. `stride` -1...1 swings the legs (and the arms the other way):
    /// 0 stands, 1 has the front foot far ahead. Tapered limbs, a backpack, shoes.
    static func walker(_ c: inout GraphicsContext, on: Double, fill: Double, stride s: Double, lean: Double, pack: Bool) {
        let hip = pt(0, -33), l1 = 17.0, l2 = 17.0
        let lr = lean * .pi / 180
        let shoulder = pt(hip.x + 22 * sin(lr), hip.y - 22 * cos(lr))
        var g = c; g.opacity *= fill
        func limb(_ a: CGPoint, _ b: CGPoint, _ w0: Double, _ w1: Double, col: Color) {
            let dx = b.x - a.x, dy = b.y - a.y, d = max(0.001, hypot(dx, dy)), nx = -dy / d, ny = dx / d
            let p = poly([pt(a.x + nx * w0 / 2, a.y + ny * w0 / 2), pt(b.x + nx * w1 / 2, b.y + ny * w1 / 2), pt(b.x - nx * w1 / 2, b.y - ny * w1 / 2), pt(a.x - nx * w0 / 2, a.y - ny * w0 / 2)], closed: true)
            g.fill(p, with: .color(col)); DR.draw(&c, p, p: on, width: DR.line)
            for e in [a, b] { _ = e }
        }
        func leg(_ swing: Double, back: Bool) {
            let ankleX = hip.x + sin(swing) * 26, lift = abs(swing) * 6
            let ankle = pt(ankleX, -2.5 - (back ? 0 : lift * 0.3))
            let dx = ankle.x - hip.x, dy = ankle.y - hip.y, d = min(hypot(dx, dy), l1 + l2 - 0.4)
            let k = (l1 * l1 - l2 * l2 + d * d) / (2 * d), hh = sqrt(max(0, l1 * l1 - k * k)), ux = dx / hypot(dx, dy), uy = dy / hypot(dx, dy)
            let knee = pt(hip.x + ux * k + uy * hh, hip.y + uy * k - ux * hh)
            let col = back ? DR.side : DR.face
            limb(hip, knee, 8, 6.4, col: col); limb(knee, ankle, 6.2, 4.6, col: col)
            let shoe = poly([pt(ankle.x - 3, ankle.y - 3), pt(ankle.x + 8, ankle.y - 2), pt(ankle.x + 9, ankle.y + 2.4), pt(ankle.x - 3, ankle.y + 2.4)], closed: true)
            g.fill(shoe, with: .color(DR.ink.opacity(0.85))); DR.draw(&c, shoe, p: on, width: DR.line)
        }
        func arm(_ swing: Double, back: Bool) {
            let hand = pt(shoulder.x + sin(swing) * 15, shoulder.y + 19), elbow = pt(shoulder.x + sin(swing) * 6 + 2, shoulder.y + 10)
            let col = back ? DR.side : DR.face
            limb(shoulder, elbow, 5, 4.2, col: col); limb(elbow, hand, 4.2, 3.4, col: col)
        }
        leg(-s * 0.9, back: true); arm(s * 0.9, back: true)
        if pack {
            let bp = Path(roundedRect: CGRect(x: shoulder.x - 14, y: shoulder.y - 2, width: 11, height: 19), cornerRadius: 3)
            g.fill(bp, with: .color(DR.side)); DR.hatch(&g, bp, in: bp.boundingRect, spacing: 2.6, alpha: 0.4); DR.draw(&c, bp, p: on, width: DR.line)
        }
        limb(hip, shoulder, 11, 12, col: DR.face)
        let neckTop = pt(shoulder.x + 2 * sin(lr), shoulder.y - 4)
        let head = pt(neckTop.x + 3, neckTop.y - 6)
        g.fill(circle(head, 6.4), with: .color(DR.face)); DR.draw(&c, circle(head, 6.4), p: on, width: DR.line)
        leg(s * 0.9, back: false); arm(-s * 0.9, back: false)
    }
}
