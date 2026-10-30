import SwiftUI

// "How does your phone find you with no mobile signal?" pictures, drawn as blueprint technical illustrations (2026-10-30).
// One chalk-ink colour, one mustard accent per card (the pulses coming down, the pulse and its two tags, the wait and then the distance,
// the spot on Earth, the corrected position), flat tints only, mono uppercase labels that use the approved slide's own words.
// Every picture loops ambiently: it plays, holds its end beat for about a second, fades its moving parts and starts again. Tap restarts,
// Reduce Motion shows the held end state. Cards share one phone (a rounded rectangle with a bars indicator, hollow because there is no
// mobile signal) and one satellite (a small body with two solar panels). Drawn in a 343 x 340 design space; keep clear of the
// bottom-right corner (x > 285, y > 255).

private let gpSize = CGSize(width: 343, height: 340)

// MARK: - Shared helpers

/// Ambient loop time: the story ends at `story`, the loop lasts `story + extra`. Reduce Motion (the stage's clock stands still behind `t`)
/// shows the held end state.
private func gpCycle(_ t: Double, _ clock: Double, story: Double, extra: Double = 1.5) -> Double {
    if clock < t { return story }
    return clock.truncatingRemainder(dividingBy: story + extra)
}

/// 1 while the picture plays and holds, then fades to 0 over the last half second of the loop.
private func gpFade(_ u: Double, _ story: Double) -> Double { 1 - BP.pr(u, story + 1.0, story + 1.5) }

private func gpOval(_ ctr: CGPoint, _ rx: Double, _ ry: Double) -> Path {
    Path(ellipseIn: CGRect(x: ctr.x - rx, y: ctr.y - ry, width: 2 * rx, height: 2 * ry))
}

private func gpRad(_ deg: Double) -> Double { deg * Double.pi / 180 }

private func gpHead(_ p: inout Path, _ a: CGPoint, _ b: CGPoint, _ size: Double = 6) {
    let len = hypot(b.x - a.x, b.y - a.y)
    guard len > 0.1 else { return }
    let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    p.move(to: BP.pt(b.x - ux * size - uy * size * 0.56, b.y - uy * size + ux * size * 0.56)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * size + uy * size * 0.56, b.y - uy * size - ux * size * 0.56))
}

/// The phone, shared by every card: a rounded rectangle, a bars indicator at the top of the screen (four hollow bars: no mobile signal)
/// and a home line. `s` scales it; at 1 it is 22 x 38.
private func gpPhone(_ c: inout GraphicsContext, _ ctr: CGPoint, s: Double, ink: Color) {
    let w = 22 * s, h = 38 * s
    let body = Path(roundedRect: CGRect(x: ctr.x - w / 2, y: ctr.y - h / 2, width: w, height: h), cornerRadius: 4.5 * s)
    c.fill(body, with: .color(BP.paper)); c.fill(body, with: .color(ink.opacity(0.1)))
    c.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
    let top = ctr.y - h / 2
    for i in 0..<4 {
        let bh = (2.0 + 2.0 * Double(i)) * s
        let r = CGRect(x: ctr.x - 7.2 * s + Double(i) * 4.2 * s, y: top + 12 * s - bh, width: 2.6 * s, height: bh)
        c.stroke(Path(r), with: .color(ink.opacity(0.75)), lineWidth: 0.8)
    }
    var home = Path(); home.move(to: BP.pt(ctr.x - 4 * s, ctr.y + h / 2 - 4 * s)); home.addLine(to: BP.pt(ctr.x + 4 * s, ctr.y + h / 2 - 4 * s))
    c.stroke(home, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
}

/// The satellite, shared by every card: a small square body and a solar panel each side. At `s` = 1 it is 48 wide.
private func gpSat(_ c: inout GraphicsContext, _ ctr: CGPoint, s: Double, ink: Color) {
    for side in [-1.0, 1.0] {
        var arm = Path(); arm.move(to: BP.pt(ctr.x + side * 5 * s, ctr.y)); arm.addLine(to: BP.pt(ctr.x + side * 8 * s, ctr.y))
        c.stroke(arm, with: .color(ink), lineWidth: BP.hair)
        let x0 = side > 0 ? ctr.x + 8 * s : ctr.x - 24 * s
        let panel = Path(CGRect(x: x0, y: ctr.y - 3.8 * s, width: 16 * s, height: 7.6 * s))
        c.fill(panel, with: .color(BP.paper)); c.fill(panel, with: .color(ink.opacity(0.14)))
        c.stroke(panel, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        var cells = Path()
        for k in 1..<3 { cells.move(to: BP.pt(x0 + Double(k) * 16 * s / 3, ctr.y - 3.8 * s)); cells.addLine(to: BP.pt(x0 + Double(k) * 16 * s / 3, ctr.y + 3.8 * s)) }
        c.stroke(cells, with: .color(ink.opacity(0.6)), lineWidth: 0.8)
    }
    let body = Path(roundedRect: CGRect(x: ctr.x - 5 * s, y: ctr.y - 5 * s, width: 10 * s, height: 10 * s), cornerRadius: 1.6 * s)
    c.fill(body, with: .color(BP.paper)); c.fill(body, with: .color(ink.opacity(0.22)))
    c.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
}

/// A pulse in flight: a bright dot with a short fading trail, `k` 0...1 along a to b.
private func gpPulse(_ c: inout GraphicsContext, from a: CGPoint, to b: CGPoint, k: Double, color: Color) {
    guard k > 0.001, k < 0.999 else { return }
    let len = max(1, hypot(b.x - a.x, b.y - a.y))
    for i in 0..<4 {
        let kk = k - Double(i) * 5.5 / len
        guard kk > 0 else { continue }
        let r = 3.6 - Double(i) * 0.7
        c.fill(gpOval(BP.mixp(a, b, kk), r, r), with: .color(color.opacity(1 - Double(i) * 0.22)))
    }
}

/// A flat ripple where a pulse lands, `k` 0...1.
private func gpRipple(_ c: inout GraphicsContext, _ at: CGPoint, k: Double, color: Color) {
    guard k > 0.001, k < 0.999 else { return }
    c.stroke(gpOval(at, 5 + 22 * BP.eout(k), 2 + 7 * BP.eout(k)), with: .color(color.opacity(1 - k)), lineWidth: BP.hair + 0.4)
}

// MARK: - Card 1: zero bars, and your phone still finds you

struct GpBPSilent: View {
    let active: Bool
    private static let story = 5.6
    private static let sats = [BP.pt(62, 92), BP.pt(171, 50), BP.pt(282, 86)]
    private static let order = [1, 0, 2, 1, 0, 2]
    private static let land = BP.pt(171, 181)

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 1.9,
                       label: "A phone on an open hillside showing zero bars. Three small satellites high above send pulses, in gold, travelling down to the phone one after another. Nothing goes back up.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, gpCycle(t, clock, story: Self.story)) }, size: gpSize)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = gpFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))

        // the hillside
        var hill = Path()
        hill.move(to: BP.pt(8, 252))
        hill.addCurve(to: BP.pt(171, 222), control1: BP.pt(80, 250), control2: BP.pt(120, 222))
        hill.addCurve(to: BP.pt(335, 240), control1: BP.pt(222, 222), control2: BP.pt(262, 244))
        var ground = hill
        ground.addLine(to: BP.pt(335, 262)); ground.addLine(to: BP.pt(8, 262)); ground.closeSubpath()
        bpGroup(&c, alpha: a0) { g in
            g.fill(ground, with: .color(BP.paper)); g.fill(ground, with: .color(ink.opacity(0.1)))
            var h = g
            h.clip(to: ground)
            var hatch = Path()
            var x = -40.0
            while x < 340 { hatch.move(to: BP.pt(x, 266)); hatch.addLine(to: BP.pt(x + 48, 210)); x += 11 }
            h.stroke(hatch, with: .color(ink.opacity(0.16)), lineWidth: BP.hair)
            g.stroke(hill, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
        }

        // the satellites, and the paths the pulses follow
        for (i, s) in sats.enumerated() {
            let origin = BP.pt(s.x, s.y + 6)
            bpGuide(&c, origin, land, p: BP.pr(t, 0.3 + 0.1 * Double(i), 1.0 + 0.1 * Double(i)), color: ink.opacity(0.3))
            bpGroup(&c, alpha: a0) { g in gpSat(&g, s, s: 0.62, ink: ink) }
        }

        // pulses come down one after another; each leaves a ripple where it lands
        for j in 0..<order.count {
            let start = 1.0 + 0.7 * Double(j)
            let s = sats[order[j]]
            let origin = BP.pt(s.x, s.y + 6)
            bpGroup(&c, alpha: fo) { g in
                gpPulse(&g, from: origin, to: land, k: BP.pr(u, start, start + 0.9), color: acc)
                gpRipple(&g, land, k: BP.pr(u, start + 0.9, start + 1.5), color: acc)
            }
        }
        // the held end: the three paths stay as gold arrows pointing down, none pointing up
        let hold = BP.pr(u, 5.0, 5.5) * fo
        bpGroup(&c, alpha: hold) { g in
            for s in sats {
                let origin = BP.pt(s.x, s.y + 12)
                var arrow = Path(); arrow.move(to: origin); arrow.addLine(to: land)
                gpHead(&arrow, origin, land, 7)
                g.stroke(arrow, with: .color(acc), style: StrokeStyle(lineWidth: BP.hair + 0.3, lineCap: .round, lineJoin: .round))
            }
        }

        // the phone
        bpGroup(&c, alpha: a0) { g in gpPhone(&g, BP.pt(171, 203), s: 1, ink: ink) }

        bpLeader(&c, anchor: BP.pt(166, 192), elbow: BP.pt(146, 206), tail: -12, text: "NO MOBILE SIGNAL", ink: ink, p: BP.pr(t, 0.5, 1.2))
        bpLeader(&c, anchor: BP.pt(182, 190), elbow: BP.pt(200, 180), tail: 12, text: "YOUR PHONE", ink: ink, p: BP.pr(t, 0.65, 1.35))
        bpLeader(&c, anchor: BP.pt(182, 205), elbow: BP.pt(198, 207), tail: 12, text: "LISTENING", ink: ink, p: BP.pr(t, 0.8, 1.5))
    }
}

// MARK: - Card 2: satellites keep sending where they are and when it was sent

struct GpBPSend: View {
    let active: Bool
    private static let story = 5.8
    private static let earth = BP.pt(171, 430)
    private static let sendAt = 1.7, landAt = 3.2

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: Self.landAt,
                       label: "A satellite circles above Earth. A gold pulse leaves it carrying two tags, one for where the satellite is and one for the time it was sent, and lands on a phone standing on the ground. Nothing goes back up.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, gpCycle(t, clock, story: Self.story)) }, size: gpSize)
    }

    private static func orbit(_ phi: Double) -> CGPoint { BP.pt(171 + 330 * sin(phi), 430 - 330 * cos(phi)) }
    private static func phi(_ u: Double) -> Double { gpRad(-24) + gpRad(36) * BP.pr(u, 0, story) }

    private static func pinTag(_ c: inout GraphicsContext, _ ctr: CGPoint, acc: Color) {
        let r = Path(roundedRect: CGRect(x: ctr.x - 9, y: ctr.y - 9, width: 18, height: 18), cornerRadius: 4.5)
        c.fill(r, with: .color(BP.paper)); c.fill(r, with: .color(acc.opacity(0.2)))
        c.stroke(r, with: .color(acc), lineWidth: BP.edge)
        var pin = Path()
        pin.move(to: BP.pt(ctr.x, ctr.y + 5.5))
        pin.addLine(to: BP.pt(ctr.x - 3.4, ctr.y - 0.6)); pin.addArc(center: BP.pt(ctr.x, ctr.y - 2), radius: 3.6, startAngle: .degrees(160), endAngle: .degrees(20), clockwise: false)
        pin.closeSubpath()
        c.stroke(pin, with: .color(acc), style: StrokeStyle(lineWidth: 1.1, lineJoin: .round))
        c.fill(gpOval(BP.pt(ctr.x, ctr.y - 2), 1.1, 1.1), with: .color(acc))
    }

    private static func clockTag(_ c: inout GraphicsContext, _ ctr: CGPoint, acc: Color) {
        let r = Path(roundedRect: CGRect(x: ctr.x - 9, y: ctr.y - 9, width: 18, height: 18), cornerRadius: 4.5)
        c.fill(r, with: .color(BP.paper)); c.fill(r, with: .color(acc.opacity(0.2)))
        c.stroke(r, with: .color(acc), lineWidth: BP.edge)
        c.stroke(gpOval(ctr, 5.2, 5.2), with: .color(acc), lineWidth: 1.1)
        var hands = Path()
        hands.move(to: BP.pt(ctr.x, ctr.y - 3.4)); hands.addLine(to: ctr); hands.addLine(to: BP.pt(ctr.x + 2.8, ctr.y + 1.2))
        c.stroke(hands, with: .color(acc), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = gpFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))
        let phone = BP.pt(171, 211), land = BP.pt(171, 189)
        let s0 = orbit(phi(sendAt))

        // Earth, cut off at the bottom of the picture
        bpGroup(&c, alpha: a0) { g in
            var h = g
            h.clip(to: Path(CGRect(x: 8, y: 0, width: 327, height: 292)))
            let earth = gpOval(Self.earth, 200, 200)
            h.fill(earth, with: .color(BP.paper)); h.fill(earth, with: .color(ink.opacity(0.08)))
            h.stroke(earth, with: .color(ink), lineWidth: BP.edge)
        }
        // the satellite's path
        var path = Path()
        let phiEnd = asin(151.0 / 330.0)
        for i in 0...40 {
            let q = orbit(-phiEnd + 2 * phiEnd * Double(i) / 40)
            if i == 0 { path.move(to: q) } else { path.addLine(to: q) }
        }
        bpTrace(&c, path, p: BP.pr(t, 0.1, 0.9), color: ink.opacity(0.4), width: BP.hair, dash: [3, 4])

        // the satellite circles; it fades in with each round
        let sat = orbit(phi(u))
        let sa = BP.pr(u, 0, 0.4) * fo
        bpGroup(&c, alpha: sa) { g in gpSat(&g, sat, s: 0.8, ink: ink) }
        bpText(&c, "SATELLITE", BP.pt(min(298, max(42, sat.x)), sat.y - 20), ink: ink, alpha: sa * BP.pr(t, 0.3, 0.8))

        // the pulse and its two tags: sent, flies down to the phone, then the tags step out either side
        let k = BP.pr(u, sendAt, landAt)
        let d = BP.pt((land.x - s0.x) / hypot(land.x - s0.x, land.y - s0.y), (land.y - s0.y) / hypot(land.x - s0.x, land.y - s0.y))
        let n = BP.pt(-d.y, d.x)
        let q = BP.mixp(s0, land, k)
        let e = BP.eio(BP.pr(u, landAt + 0.1, landAt + 0.8))
        let fWhere = BP.pt(126, 184), fTime = BP.pt(216, 184)
        let posWhere = BP.mixp(BP.pt(q.x + n.x * 15, q.y + n.y * 15), fWhere, e)
        let posTime = BP.mixp(BP.pt(q.x - n.x * 15, q.y - n.y * 15), fTime, e)
        bpGroup(&c, alpha: fo) { g in
            g.stroke(gpOval(s0, 5, 5), with: .color(ink.opacity(0.5 * BP.pr(u, sendAt + 0.2, sendAt + 0.6))), style: StrokeStyle(lineWidth: BP.hair, dash: [2, 2]))
            var trace = Path(); trace.move(to: s0); trace.addLine(to: land)
            bpTrace(&g, trace, p: k, color: acc.opacity(0.85), width: BP.hair, dash: [4, 4])
            gpPulse(&g, from: s0, to: land, k: k, color: acc)
            gpRipple(&g, land, k: BP.pr(u, landAt, landAt + 0.6), color: acc)
        }
        bpGroup(&c, alpha: BP.pr(u, sendAt - 0.2, sendAt + 0.2) * fo) { g in
            pinTag(&g, posWhere, acc: acc)
            clockTag(&g, posTime, acc: acc)
        }

        // the phone on the ground
        bpGroup(&c, alpha: a0) { g in gpPhone(&g, phone, s: 1, ink: ink) }

        bpLeader(&c, anchor: BP.pt(182, 222), elbow: BP.pt(204, 246), tail: 10, text: "YOUR PHONE", ink: ink, p: BP.pr(t, 0.5, 1.2))
        bpGroup(&c, alpha: fo) { g in
            bpLeader(&g, anchor: BP.mixp(s0, land, 0.5), elbow: BP.pt(118, 150), tail: -10, text: "RADIO SIGNAL", ink: acc, p: BP.pr(u, sendAt + 0.4, sendAt + 1.2))
            bpLeader(&g, anchor: BP.pt(fWhere.x - 8, fWhere.y + 3), elbow: BP.pt(106, 204), tail: -10, text: "WHERE IT IS", ink: acc, p: BP.pr(u, landAt + 0.7, landAt + 1.5))
            bpLeader(&g, anchor: BP.pt(fTime.x + 8, fTime.y + 3), elbow: BP.pt(238, 204), tail: 10, text: "TIME SENT", ink: acc, p: BP.pr(u, landAt + 0.8, landAt + 1.6))
        }
    }
}

// MARK: - Card 3: the gap between sent and arrived is a distance

struct GpBPGap: View {
    let active: Bool
    private static let story = 6.9
    private static let flashAt = 0.8, thunderAt = 3.4
    private static let sendAt = 4.9, landAt = 5.4
    private static let ground = 226.0, phoneX = 240.0

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: Self.landAt,
                       label: "First a lightning flash, then thunder a few seconds later, with the wait marked in gold on a timeline. Then a satellite straight overhead sends a pulse that lands on the phone about 0.07 seconds later, a gap much shorter than a blink, marked in gold as the distance.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, gpCycle(t, clock, story: Self.story)) }, size: gpSize)
    }

    private static func tick(_ c: inout GraphicsContext, _ x: Double, _ y: Double, color: Color, alpha: Double) {
        guard alpha > 0.01 else { return }
        var p = Path(); p.move(to: BP.pt(x, y - 7)); p.addLine(to: BP.pt(x, y + 7))
        c.stroke(p, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
    }

    private static func line(_ c: inout GraphicsContext, _ x0: Double, _ x1: Double, _ y: Double, color: Color, width: Double) {
        guard x1 - x0 > 0.5 else { return }
        var p = Path(); p.move(to: BP.pt(x0, y)); p.addLine(to: BP.pt(x1, y))
        c.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = gpFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))
        let bolt = BP.pt(70, ground)

        // ground and the storm cloud
        var gl = Path(); gl.move(to: BP.pt(8, ground)); gl.addLine(to: BP.pt(335, ground))
        bpTrace(&c, gl, p: BP.pr(t, 0, 0.7), color: ink, width: BP.edge)
        var cloud = Path()
        cloud.move(to: BP.pt(38, 80)); cloud.addLine(to: BP.pt(106, 80))
        cloud.addQuadCurve(to: BP.pt(118, 66), control: BP.pt(122, 80))
        cloud.addQuadCurve(to: BP.pt(100, 56), control: BP.pt(114, 54))
        cloud.addQuadCurve(to: BP.pt(78, 40), control: BP.pt(98, 38))
        cloud.addQuadCurve(to: BP.pt(58, 54), control: BP.pt(58, 40))
        cloud.addQuadCurve(to: BP.pt(36, 64), control: BP.pt(40, 48))
        cloud.addQuadCurve(to: BP.pt(38, 80), control: BP.pt(24, 74))
        bpGroup(&c, alpha: a0) { g in
            g.fill(cloud, with: .color(BP.paper)); g.fill(cloud, with: .color(ink.opacity(0.16)))
            g.stroke(cloud, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        }

        // the flash: bright for a moment, then it stays drawn thinner
        let fl = BP.pr(u, flashAt, flashAt + 0.08) * fo
        let bright = 1 - BP.pr(u, flashAt + 0.3, flashAt + 0.6)
        var zig = Path()
        let pts = [BP.pt(76, 82), BP.pt(66, 118), BP.pt(80, 118), BP.pt(68, 160), BP.pt(82, 160), BP.pt(70, 200), BP.pt(76, ground)]
        zig.addLines(pts)
        bpGroup(&c, alpha: fl) { g in
            g.stroke(zig, with: .color(ink.opacity(0.55 + 0.45 * bright)), style: StrokeStyle(lineWidth: 1.4 + 1.4 * bright, lineCap: .round, lineJoin: .round))
        }

        // thunder: arcs spread along the ground toward the phone, far slower than the pulse later
        let radius = 159.0 * BP.pr(u, flashAt + 0.1, thunderAt)
        let wa = (1 - BP.pr(u, thunderAt, thunderAt + 0.5)) * fo
        bpGroup(&c, alpha: wa) { g in
            for i in 0..<3 {
                let r = radius - 12 * Double(i)
                guard r > 6 else { continue }
                var arc = Path()
                for j in 0...16 {
                    let a = -gpRad(55) * Double(j) / 16
                    let p = BP.pt(bolt.x + r * cos(a), bolt.y + r * sin(a))
                    if j == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
                }
                g.stroke(arc, with: .color(ink.opacity(0.85 - 0.25 * Double(i))), style: StrokeStyle(lineWidth: BP.hair + 0.2, lineCap: .round))
            }
        }

        // timeline of the wait: FLASH at one end, THUNDER at the other, the wait between in mustard
        let ya = 252.0, x0 = 50.0
        let xEnd = x0 + 66.0 * (thunderAt - flashAt)
        let xa = x0 + 66.0 * (min(max(u, flashAt), thunderAt) - flashAt)
        line(&c, 40, 270, ya, color: ink.opacity(0.35), width: BP.hair)
        bpGroup(&c, alpha: fo) { g in
            line(&g, x0, xa, ya, color: acc, width: 3)
            tick(&g, x0, ya, color: ink, alpha: BP.pr(u, flashAt, flashAt + 0.1))
            tick(&g, xEnd, ya, color: ink, alpha: BP.pr(u, thunderAt, thunderAt + 0.1))
        }
        bpText(&c, "FLASH", BP.pt(x0, ya + 16), ink: ink, alpha: BP.pr(u, flashAt, flashAt + 0.3) * fo)
        bpText(&c, "THUNDER", BP.pt(xEnd, ya + 16), ink: ink, alpha: BP.pr(u, thunderAt, thunderAt + 0.3) * fo)
        bpText(&c, "THE WAIT", BP.pt((x0 + xEnd) / 2, ya - 14), ink: acc, alpha: BP.pr(u, thunderAt + 0.1, thunderAt + 0.5) * fo)

        // the satellite straight overhead, the pulse, and the gap
        let sat = BP.pt(phoneX, 48), top = BP.pt(phoneX, 58), land = BP.pt(phoneX, 186)
        let k = BP.pr(u, sendAt, landAt)
        bpGroup(&c, alpha: BP.pr(u, 4.2, 4.7) * fo) { g in gpSat(&g, sat, s: 0.8, ink: ink) }
        bpGroup(&c, alpha: fo) { g in
            var trace = Path(); trace.move(to: top); trace.addLine(to: land)
            bpTrace(&g, trace, p: k, color: acc.opacity(0.85), width: BP.hair, dash: [4, 4])
            gpPulse(&g, from: top, to: land, k: k, color: acc)
            gpRipple(&g, land, k: BP.pr(u, landAt, landAt + 0.6), color: acc)
        }

        let yb = 308.0, sx = 130.0, ex = 158.0
        line(&c, 40, 270, yb, color: ink.opacity(0.35), width: BP.hair)
        bpGroup(&c, alpha: fo) { g in
            line(&g, sx, sx + (ex - sx) * k, yb, color: acc, width: 3)
            tick(&g, sx, yb, color: ink, alpha: BP.pr(u, sendAt, sendAt + 0.1))
            tick(&g, ex, yb, color: ink, alpha: BP.pr(u, landAt, landAt + 0.1))
        }
        bpText(&c, "SENT", BP.pt(sx - 4, yb + 16), ink: ink, alpha: BP.pr(u, sendAt, sendAt + 0.3) * fo, anchor: .trailing)
        bpText(&c, "ARRIVED", BP.pt(ex + 4, yb + 16), ink: ink, alpha: BP.pr(u, landAt, landAt + 0.3) * fo, anchor: .leading)
        bpText(&c, "ABOUT 0.07 SECONDS", BP.pt((sx + ex) / 2, yb - 14), ink: acc, alpha: BP.pr(u, landAt + 0.2, landAt + 0.8) * fo)

        // the gap, marked on the path as the distance
        let dp = BP.pr(u, landAt + 0.2, landAt + 0.9)
        bpGroup(&c, alpha: fo) { g in
            let dx = phoneX - 22
            let end = BP.mix(66, 176, dp)
            var dim = Path()
            dim.move(to: BP.pt(dx, 66)); dim.addLine(to: BP.pt(dx, end))
            dim.move(to: BP.pt(dx - 4, 66)); dim.addLine(to: BP.pt(dx + 4, 66))
            gpHead(&dim, BP.pt(dx, 90), BP.pt(dx, 66), 5)
            if dp > 0.98 {
                dim.move(to: BP.pt(dx - 4, 176)); dim.addLine(to: BP.pt(dx + 4, 176))
                gpHead(&dim, BP.pt(dx, 150), BP.pt(dx, 176), 5)
            }
            if dp > 0.01 { g.stroke(dim, with: .color(acc), style: StrokeStyle(lineWidth: BP.hair + 0.2, lineCap: .round, lineJoin: .round)) }
            bpLeader(&g, anchor: BP.pt(dx, 120), elbow: BP.pt(dx - 12, 132), tail: -10, text: "DISTANCE", ink: acc, p: BP.pr(u, landAt + 0.8, landAt + 1.5))
        }

        // the phone
        bpGroup(&c, alpha: a0) { g in gpPhone(&g, BP.pt(phoneX, ground - 19), s: 1, ink: ink) }
    }
}

// MARK: - Card 4: three satellites, two spots, one on Earth

struct GpBPSpots: View {
    let active: Bool
    private static let story = 7.7
    private static let ax = [100.0, 170.0, 228.0], ay = 170.0
    private static let px = 150.0, dd = 50.0
    private static let lockAt = 6.9

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: Self.lockAt,
                       label: "A map from above. One satellite has a ring around it, the places one distance allows, and a dot circles the ring. Two more satellites add their rings. All three rings cross at the same two spots. One spot is on Earth and is marked in gold; an arrow takes the other far out in space.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, gpCycle(t, clock, story: Self.story)) }, size: gpSize)
    }

    private static func radius(_ i: Int) -> Double { hypot(px - ax[i], dd) }
    private static func ring(_ i: Int) -> Path { gpOval(BP.pt(ax[i], ay), radius(i), radius(i)) }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = gpFade(u, story)
        let up = BP.pt(px, ay - dd), dn = BP.pt(px, ay + dd)

        // ring 1, with a dot that goes all the way round it
        let r1 = BP.pr(u, 0.3, 0.9)
        let lap = BP.pr(u, 0.9, 3.0)
        bpGroup(&c, alpha: fo) { g in
            bpTrace(&g, ring(0), p: r1, color: ink, width: BP.edge)
            if lap > 0.001 && lap < 1 {
                // the part already travelled is drawn heavier
                var done = Path()
                let n = max(2, Int(lap * 60))
                for j in 0...n {
                    let a = -Double.pi / 2 + 2 * Double.pi * lap * Double(j) / Double(n)
                    let p = BP.pt(ax[0] + radius(0) * cos(a), ay + radius(0) * sin(a))
                    if j == 0 { done.move(to: p) } else { done.addLine(to: p) }
                }
                g.stroke(done, with: .color(ink), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
        }
        let a = -Double.pi / 2 + 2 * Double.pi * lap
        let dot = BP.pt(ax[0] + radius(0) * cos(a), ay + radius(0) * sin(a))
        bpGroup(&c, alpha: BP.pr(u, 0.9, 1.1) * (1 - BP.pr(u, 3.0, 3.3)) * fo) { g in
            g.fill(gpOval(dot, 5, 5), with: .color(BP.paper))
            g.fill(gpOval(dot, 3.6, 3.6), with: .color(ink))
        }

        // rings 2 and 3 draw in, each with its satellite
        bpGroup(&c, alpha: fo) { g in
            bpTrace(&g, ring(1), p: BP.pr(u, 3.1, 3.9), color: ink, width: BP.edge)
            bpTrace(&g, ring(2), p: BP.pr(u, 4.0, 4.8), color: ink, width: BP.edge)
        }
        let satA = [BP.eout(BP.pr(u, 0, 0.4)), BP.eout(BP.pr(u, 2.9, 3.3)), BP.eout(BP.pr(u, 3.8, 4.2))]
        for i in 0..<3 {
            bpGroup(&c, alpha: satA[i] * fo) { g in gpSat(&g, BP.pt(ax[i], ay), s: 0.56, ink: ink) }
        }

        // the two crossing points: marked as soon as two rings meet, the same two for the third ring
        let spots = BP.eout(BP.pr(u, 5.0, 5.5))
        let dash = StrokeStyle(lineWidth: BP.hair, dash: [3, 3])
        bpGroup(&c, alpha: BP.pr(u, 3.9, 4.2) * fo) { g in
            for p in [up, dn] { g.fill(gpOval(p, 2.4, 2.4), with: .color(ink)) }
        }
        bpGroup(&c, alpha: spots * fo) { g in
            var guide = Path(); guide.move(to: BP.pt(px, up.y + 7)); guide.addLine(to: BP.pt(px, dn.y - 7))
            g.stroke(guide, with: .color(ink.opacity(0.5)), style: dash)
            for p in [up, dn] {
                g.fill(gpOval(p, 5.5, 5.5), with: .color(BP.paper))
                g.stroke(gpOval(p, 5.5, 5.5), with: .color(ink), lineWidth: BP.edge)
            }
        }

        // the upper spot is taken far off the page by an arrow
        let travel = BP.eio(BP.pr(u, 5.7, 6.7))
        let headY = BP.mix(up.y - 7, 30, travel)
        bpGroup(&c, alpha: fo) { g in
            if travel > 0.01 {
                var arrow = Path(); arrow.move(to: BP.pt(px, up.y - 6)); arrow.addLine(to: BP.pt(px, headY))
                gpHead(&arrow, BP.pt(px, headY + 12), BP.pt(px, headY), 7)
                g.stroke(arrow, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, lineJoin: .round))
                var more = Path(); more.move(to: BP.pt(px, headY - 3)); more.addLine(to: BP.pt(px, BP.mix(headY - 3, 12, travel)))
                g.stroke(more, with: .color(ink.opacity(0.5 * travel)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, dash: [2, 4]))
            }
            // the spot itself rides up with the arrow and fades; a dashed ghost stays where it was
            let rider = BP.pt(px, BP.mix(up.y, headY + 10, travel))
            g.fill(gpOval(rider, 5.5, 5.5), with: .color(BP.paper.opacity(travel > 0.01 ? 1 : 0)))
            g.stroke(gpOval(rider, 5.5, 5.5), with: .color(ink.opacity((1 - BP.pr(travel, 0.6, 0.95)) * (travel > 0.01 ? 1 : 0))), lineWidth: BP.edge)
            g.stroke(gpOval(up, 5.5, 5.5), with: .color(ink.opacity(0.6 * BP.pr(travel, 0.05, 0.2))), style: dash)
        }

        // the lower spot locks onto Earth, in mustard
        let lock = BP.eout(BP.pr(u, lockAt, lockAt + 0.4))
        bpGroup(&c, alpha: lock * fo) { g in
            g.stroke(gpOval(dn, BP.mix(16, 9, lock), BP.mix(16, 9, lock)), with: .color(acc), lineWidth: BP.hair + 0.4)
            g.fill(gpOval(dn, 5.2, 5.2), with: .color(acc))
        }

        // labels
        bpLeader(&c, anchor: BP.pt(ax[0], ay + 7), elbow: BP.pt(ax[0], 270), tail: 10, text: "SATELLITE", ink: ink, p: BP.pr(t, 0.4, 1.1))
        bpLeader(&c, anchor: BP.pt(ax[0] + radius(0) * cos(gpRad(-125)), ay + radius(0) * sin(gpRad(-125))), elbow: BP.pt(50, 88), tail: 10, text: "RING", ink: ink, p: BP.pr(t, 0.8, 1.5))
        bpGroup(&c, alpha: fo) { g in
            bpLeader(&g, anchor: BP.pt(px - 5, up.y - 2), elbow: BP.pt(128, 70), tail: -10, text: "TWO SPOTS", ink: ink, p: BP.pr(u, 5.3, 6.0))
            bpLeader(&g, anchor: BP.pt(px, headY + 14), elbow: BP.pt(px + 10, 48), tail: 10, text: "FAR OUT IN SPACE", ink: ink, p: BP.pr(u, 6.3, 7.0) * BP.pr(travel, 0.6, 1))
            bpLeader(&g, anchor: BP.pt(dn.x + 6, dn.y + 5), elbow: BP.pt(170, 244), tail: 10, text: "ON EARTH", ink: acc, p: BP.pr(u, lockAt + 0.1, lockAt + 0.7))
        }
    }
}

// MARK: - Card 5: the phone's clock drifts, a fourth satellite fixes it

struct GpBPClock: View {
    let active: Bool
    private static let story = 6.6
    private static let fixAt = 4.9, fixed = 5.3
    private static let phone = BP.pt(90, 236)
    private static let shiftMax = 100.0, errMax = gpRad(70)

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 5.05,
                       label: "Two small clocks, the phone's and the satellite's, start together, then the phone's drifts away from the satellite's. Your position, a ring round the phone, drifts about 300 metres off. A fourth satellite sends a pulse to the phone's clock, the clock matches again, and the ring snaps back round the phone, marked in gold.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, gpCycle(t, clock, story: Self.story)) }, size: gpSize)
    }

    private static func clockFace(_ c: inout GraphicsContext, _ ctr: CGPoint, r: Double, angle: Double, ghost: Double?, ink: Color) {
        let face = gpOval(ctr, r, r)
        c.fill(face, with: .color(BP.paper)); c.fill(face, with: .color(ink.opacity(0.1)))
        c.stroke(face, with: .color(ink), lineWidth: BP.edge)
        var ticks = Path()
        for k in 0..<12 {
            let a = Double(k) * Double.pi / 6
            ticks.move(to: BP.pt(ctr.x + (r - 4) * sin(a), ctr.y - (r - 4) * cos(a))); ticks.addLine(to: BP.pt(ctr.x + (r - 1.6) * sin(a), ctr.y - (r - 1.6) * cos(a)))
        }
        c.stroke(ticks, with: .color(ink.opacity(0.7)), lineWidth: 0.8)
        if let gh = ghost {
            var g = Path(); g.move(to: ctr); g.addLine(to: BP.pt(ctr.x + (r - 6) * sin(gh), ctr.y - (r - 6) * cos(gh)))
            c.stroke(g, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, dash: [2, 2]))
        }
        var hand = Path(); hand.move(to: ctr); hand.addLine(to: BP.pt(ctr.x + (r - 5) * sin(angle), ctr.y - (r - 5) * cos(angle)))
        c.stroke(hand, with: .color(ink), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        c.fill(gpOval(ctr, 2, 2), with: .color(ink))
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let fo = gpFade(u, story)
        let a0 = BP.eout(BP.pr(t, 0, 0.5))

        // the clocks: both tick on together, then the phone's runs away from the satellite's until the fourth satellite fixes it
        let drift = BP.eio(BP.pr(u, 0.9, 3.0))
        let fix = BP.eout(BP.pr(u, fixAt, fixed))
        let err = errMax * drift * (1 - fix)
        let sa = 0.8 * u
        let cp = BP.pt(90, 100), cs = BP.pt(252, 100)
        bpGroup(&c, alpha: a0) { g in
            clockFace(&g, cp, r: 22, angle: sa + err, ghost: err > 0.04 ? sa : nil, ink: ink)
            clockFace(&g, cs, r: 22, angle: sa, ghost: nil, ink: ink)
        }
        bpText(&c, "YOUR PHONE'S CLOCK", BP.pt(90, 62), ink: ink, alpha: BP.pr(t, 0.3, 0.8))
        bpText(&c, "SATELLITE'S CLOCK", BP.pt(252, 62), ink: ink, alpha: BP.pr(t, 0.4, 0.9))

        // the fourth satellite joins in and speaks to the phone's clock
        let sat4 = BP.pt(171, 100)
        let sat4A = BP.pr(u, 3.6, 4.1) * fo
        bpGroup(&c, alpha: sat4A) { g in gpSat(&g, sat4, s: 0.55, ink: ink) }
        let pk = BP.pr(u, 4.2, fixAt)
        bpGroup(&c, alpha: fo) { g in
            var link = Path(); link.move(to: BP.pt(156, 100)); link.addLine(to: BP.pt(116, 100))
            bpTrace(&g, link, p: pk, color: ink.opacity(0.45), width: BP.hair, dash: [3, 3])
            gpPulse(&g, from: BP.pt(156, 100), to: BP.pt(116, 100), k: pk, color: ink)
        }
        bpGroup(&c, alpha: fo) { g in
            bpLeader(&g, anchor: BP.pt(171, 108), elbow: BP.pt(171, 140), tail: 10, text: "FOURTH SATELLITE", ink: ink, p: BP.pr(u, 3.9, 4.6))
        }

        // your position: a ring round the phone that drifts off, then snaps back
        let ph = phone
        let shift = shiftMax * (err / errMax)
        let hold = shiftMax * drift
        let pos = BP.pt(ph.x + shift, ph.y)
        var guide = Path(); guide.move(to: BP.pt(90, 124)); guide.addLine(to: BP.pt(90, 208))
        bpTrace(&c, guide, p: BP.pr(t, 0.2, 0.9), color: ink.opacity(0.28), width: BP.hair, dash: [3, 4])
        bpGroup(&c, alpha: a0) { g in gpPhone(&g, ph, s: 0.9, ink: ink) }

        let good = BP.pr(u, fixAt + 0.1, fixed)
        bpGroup(&c, alpha: fo) { g in
            // where it was wrong stays as a dashed ghost with the gap measured
            if hold > 0.5 {
                let ghostA = BP.pr(u, fixAt, fixed)
                g.stroke(gpOval(BP.pt(ph.x + hold, ph.y), 25, 25), with: .color(ink.opacity(0.5 * ghostA)), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 3]))
                let y = 282.0, x1 = ph.x + hold
                var dim = Path()
                dim.move(to: BP.pt(ph.x, y)); dim.addLine(to: BP.pt(x1, y))
                dim.move(to: BP.pt(ph.x, y - 4)); dim.addLine(to: BP.pt(ph.x, y + 4))
                dim.move(to: BP.pt(x1, y - 4)); dim.addLine(to: BP.pt(x1, y + 4))
                if hold > 10 { gpHead(&dim, BP.pt(ph.x + 10, y), BP.pt(ph.x, y), 5); gpHead(&dim, BP.pt(x1 - 10, y), BP.pt(x1, y), 5) }
                g.stroke(dim, with: .color(ink.opacity(1 - 0.45 * good)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round))
            }
            // the position ring: chalk while it is wrong, mustard once it is right again
            g.fill(gpOval(pos, 25, 25), with: .color(acc.opacity(0.12 * good)))
            g.stroke(gpOval(pos, 25, 25), with: .color(ink.opacity(1 - good)), lineWidth: BP.edge)
            g.stroke(gpOval(pos, 25, 25), with: .color(acc.opacity(good)), lineWidth: 2)
            var cross = Path()
            cross.move(to: BP.pt(pos.x - 31, pos.y)); cross.addLine(to: BP.pt(pos.x - 22, pos.y)); cross.move(to: BP.pt(pos.x + 22, pos.y)); cross.addLine(to: BP.pt(pos.x + 31, pos.y))
            cross.move(to: BP.pt(pos.x, pos.y - 31)); cross.addLine(to: BP.pt(pos.x, pos.y - 22)); cross.move(to: BP.pt(pos.x, pos.y + 22)); cross.addLine(to: BP.pt(pos.x, pos.y + 31))
            g.stroke(cross, with: .color(ink.opacity(1 - good)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
            g.stroke(cross, with: .color(acc.opacity(good)), style: StrokeStyle(lineWidth: BP.hair + 0.4, lineCap: .round))
            if good > 0.01 && good < 0.999 { g.stroke(gpOval(pos, 25 + 14 * good, 25 + 14 * good), with: .color(acc.opacity(1 - good)), lineWidth: BP.hair) }
            bpText(&g, "ABOUT 300 METRES OFF", BP.pt(ph.x + shiftMax / 2, 300), ink: ink, alpha: BP.pr(u, 2.8, 3.3))
        }
    }
}
