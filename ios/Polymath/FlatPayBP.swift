import SwiftUI

// "Why isn't the shop paid the moment you tap your card?" pictures, drawn as blueprint technical illustrations (2026-10-29).
// Cards 1-3 share one card reader, one bank (a small building with columns) and one message / yes, so they look identical throughout; cards 3-4 share
// the shop. One chalk-ink colour, one mustard accent per card (the message, the message and the yes, the yes and the dropping bar, the totals on their way
// to the shop). Every picture LOOPS: it plays, holds its end beat about a second, fades what moves and starts again. Labels are mono uppercase and use
// only the slide's own words. Reduce Motion shows the held end state. Drawn in a 343 x 340 design space; keep clear of the bottom-right corner
// (x > 285, y > 255).

private let pySize = CGSize(width: 343, height: 340)
private let pyLength = 3.2          // the stage's own clock only paces the labels; the loop runs on the free clock

// MARK: - Shared parts

private func pyPoly(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }

private func pyFill(_ c: inout GraphicsContext, _ p: Path, ink: Color, tint: Double, width: Double = BP.edge) {
    c.fill(p, with: .color(BP.paper)); c.fill(p, with: .color(ink.opacity(tint)))
    c.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: width, lineJoin: .round))
}

/// Loop time: (seconds into the loop, held still). With Reduce Motion the stage's clock stands at 2.2 behind `t`, so the end state shows.
private func pyCycle(_ t: Double, _ clock: Double, hold: Double, loop: Double) -> (Double, Bool) {
    if clock < t { return (hold, true) }
    return (clock.truncatingRemainder(dividingBy: loop), false)
}

/// A short line from `a` to `b` with a dot on `a`, drawn on by `p`.
private func pyStub(_ c: inout GraphicsContext, from a: CGPoint, to b: CGPoint, ink: Color, p: Double) {
    guard p > 0.001 else { return }
    var path = Path(); path.move(to: a); path.addLine(to: b)
    bpTrace(&c, path, p: p, color: ink, width: BP.hair)
    c.fill(Path(ellipseIn: CGRect(x: a.x - 2.2, y: a.y - 2.2, width: 4.4, height: 4.4)), with: .color(ink.opacity(BP.pr(p, 0, 0.1))))
}

/// The card reader, front-on: body 40 x 56 centred on `at`, screen, contactless arcs, keypad, and a foot reaching 33 below the centre.
private func pyReader(_ c: inout GraphicsContext, _ at: CGPoint, ink: Color) {
    let x = at.x, y = at.y
    pyFill(&c, pyPoly([BP.pt(x - 14, y + 27), BP.pt(x + 14, y + 27), BP.pt(x + 18, y + 33), BP.pt(x - 18, y + 33)]), ink: ink, tint: 0.2)
    pyFill(&c, Path(roundedRect: CGRect(x: x - 20, y: y - 28, width: 40, height: 56), cornerRadius: 6), ink: ink, tint: 0.08)
    let screen = Path(roundedRect: CGRect(x: x - 14, y: y - 22, width: 28, height: 12), cornerRadius: 2)
    c.fill(screen, with: .color(ink.opacity(0.22)))
    c.stroke(screen, with: .color(ink), lineWidth: BP.hair)
    var arcs = Path()
    for r in [5.0, 9.0, 13.0] {
        for i in 0...8 {
            let a = -0.75 + 1.5 * Double(i) / 8
            let q = BP.pt(x - 4 + r * cos(a), y + 6 + r * sin(a))
            if i == 0 { arcs.move(to: q) } else { arcs.addLine(to: q) }
        }
    }
    c.stroke(arcs, with: .color(ink.opacity(0.75)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
    for row in 0..<2 { for col in 0..<3 {
        let q = BP.pt(x - 8 + 8 * Double(col), y + 17 + 6 * Double(row))
        c.fill(Path(ellipseIn: CGRect(x: q.x - 1.3, y: q.y - 1.3, width: 2.6, height: 2.6)), with: .color(ink.opacity(0.7)))
    } }
}

/// A bank: a small building with a pediment, four columns and two steps, 54 wide and 46 high, centred on `at`.
private func pyBank(_ c: inout GraphicsContext, _ at: CGPoint, ink: Color) {
    let x = at.x, y = at.y
    pyFill(&c, pyPoly([BP.pt(x - 26, y - 12), BP.pt(x, y - 23), BP.pt(x + 26, y - 12)]), ink: ink, tint: 0.14)
    pyFill(&c, Path(CGRect(x: x - 26, y: y - 12, width: 52, height: 5)), ink: ink, tint: 0.22)
    for cx in [-18.0, -6.0, 6.0, 18.0] {
        pyFill(&c, Path(CGRect(x: x + cx - 3, y: y - 7, width: 6, height: 19)), ink: ink, tint: 0.1)
    }
    pyFill(&c, Path(CGRect(x: x - 24, y: y + 12, width: 48, height: 5)), ink: ink, tint: 0.2)
    pyFill(&c, Path(CGRect(x: x - 27, y: y + 17, width: 54, height: 6)), ink: ink, tint: 0.26)
}

/// A card network: a hub with spokes to five nodes, 52 wide.
private func pyNetwork(_ c: inout GraphicsContext, _ at: CGPoint, ink: Color) {
    var nodes: [CGPoint] = []
    for i in 0..<5 {
        let a = -Double.pi / 2 + 2 * Double.pi * Double(i) / 5
        nodes.append(BP.pt(at.x + 21 * cos(a) * 1.15, at.y + 21 * sin(a)))
    }
    var rim = Path()
    for (i, n) in nodes.enumerated() { if i == 0 { rim.move(to: n) } else { rim.addLine(to: n) } }
    rim.closeSubpath()
    c.stroke(rim, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 3]))
    var spokes = Path()
    for n in nodes { spokes.move(to: at); spokes.addLine(to: n) }
    c.stroke(spokes, with: .color(ink), lineWidth: BP.hair)
    for n in nodes { pyFill(&c, Path(ellipseIn: CGRect(x: n.x - 5, y: n.y - 5, width: 10, height: 10)), ink: ink, tint: 0.2) }
    pyFill(&c, Path(ellipseIn: CGRect(x: at.x - 9, y: at.y - 9, width: 18, height: 18)), ink: ink, tint: 0.26)
}

/// The message: a small envelope with a question mark, 30 x 22, in `color`.
private func pyEnvelope(_ c: inout GraphicsContext, _ at: CGPoint, color: Color) {
    let x = at.x, y = at.y
    pyFill(&c, Path(roundedRect: CGRect(x: x - 15, y: y - 11, width: 30, height: 22), cornerRadius: 2.5), ink: color, tint: 0.22)
    var flap = Path()
    flap.move(to: BP.pt(x - 15, y - 11)); flap.addLine(to: BP.pt(x, y - 1)); flap.addLine(to: BP.pt(x + 15, y - 11))
    c.stroke(flap, with: .color(color), style: StrokeStyle(lineWidth: BP.hair, lineJoin: .round))
    bpText(&c, "?", BP.pt(x, y + 5), ink: color)
}

/// The yes: a small pill in `color`. With `word` it says YES, without it shows a tick.
private func pyYes(_ c: inout GraphicsContext, _ at: CGPoint, color: Color, word: Bool) {
    let x = at.x, y = at.y
    pyFill(&c, Path(roundedRect: CGRect(x: x - 18, y: y - 9, width: 36, height: 18), cornerRadius: 9), ink: color, tint: 0.22)
    if word {
        bpText(&c, "YES", at, ink: color)
    } else {
        var tick = Path()
        tick.move(to: BP.pt(x - 5, y)); tick.addLine(to: BP.pt(x - 1.5, y + 3.5)); tick.addLine(to: BP.pt(x + 6, y - 4))
        c.stroke(tick, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }
}

/// The shop, front-on: striped awning, counter with a register, and an open empty tray. 64 wide, centred on `at` (tray centre at +21).
private func pyShop(_ c: inout GraphicsContext, _ at: CGPoint, ink: Color) {
    let x = at.x, y = at.y
    var walls = Path()
    for s in [-1.0, 1.0] { walls.move(to: BP.pt(x + s * 27, y - 21)); walls.addLine(to: BP.pt(x + s * 27, y + 33)) }
    c.stroke(walls, with: .color(ink.opacity(0.7)), lineWidth: BP.hair)
    pyFill(&c, Path(CGRect(x: x - 27, y: y + 8, width: 54, height: 25)), ink: ink, tint: 0.1)
    pyFill(&c, Path(roundedRect: CGRect(x: x - 12, y: y - 6, width: 24, height: 14), cornerRadius: 2), ink: ink, tint: 0.14)
    c.fill(Path(CGRect(x: x - 9, y: y - 4, width: 18, height: 5)), with: .color(ink.opacity(0.3)))
    let tray = Path(roundedRect: CGRect(x: x - 24, y: y + 14, width: 48, height: 14), cornerRadius: 2)
    c.fill(tray, with: .color(BP.paper)); c.fill(tray, with: .color(ink.opacity(0.03)))
    c.stroke(tray, with: .color(ink), lineWidth: BP.edge)
    var mid = Path(); mid.move(to: BP.pt(x, y + 16)); mid.addLine(to: BP.pt(x, y + 26))
    c.stroke(mid, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: BP.hair, dash: [2, 2]))
    // awning: four striped panels with scalloped edges
    for i in 0..<4 {
        let x0 = x - 32 + 16 * Double(i), x1 = x0 + 16, yb = y - 21
        var p = Path()
        p.move(to: BP.pt(x0, y - 33)); p.addLine(to: BP.pt(x1, y - 33)); p.addLine(to: BP.pt(x1, yb))
        for k in 0...10 {
            let a = Double.pi * Double(k) / 10
            p.addLine(to: BP.pt((x0 + x1) / 2 + 8 * cos(a), yb + 8 * sin(a)))
        }
        p.closeSubpath()
        pyFill(&c, p, ink: ink, tint: i % 2 == 0 ? 0.26 : 0.07)
    }
}

// MARK: - Card 1: you tap, it beeps, and you walk away

struct PayBPTap: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: pyLength, tick: 1.3,
                       label: "A person stands at a shop counter and taps a card on a card reader. A short message, a small envelope with a question mark shown in gold, leaves the reader and floats away. Labels say: card reader, message, can this card pay?",
                       draw: { c, t, pal, clock in let (u, _) = pyCycle(t, clock, hold: 3.8, loop: 6.2); Self.draw(&c, t, pal, u) }, size: pySize)
    }

    private static let reader = BP.pt(140, 181)
    private static let shoulder = BP.pt(208, 205)
    private static let restHand = BP.pt(190, 198), tapHand = BP.pt(155, 190)
    private static let restElbow = BP.pt(206, 222), tapElbow = BP.pt(188, 214)
    private static let p0 = BP.pt(140, 148), p1 = BP.pt(140, 98), p2 = BP.pt(200, 92), p3 = BP.pt(250, 96)

    private static func bezier(_ e: Double) -> CGPoint {
        let m = 1 - e
        return BP.pt(m * m * m * p0.x + 3 * m * m * e * p1.x + 3 * m * e * e * p2.x + e * e * e * p3.x,
                     m * m * m * p0.y + 3 * m * m * e * p1.y + 3 * m * e * e * p2.y + e * e * e * p3.y)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.5))

        bpGroup(&c, alpha: a0) { g in
            var ground = Path(); ground.move(to: BP.pt(24, 252)); ground.addLine(to: BP.pt(280, 252))
            g.stroke(ground, with: .color(ink.opacity(0.45)), lineWidth: BP.hair)
            pyFill(&g, Path(CGRect(x: 96, y: 214, width: 76, height: 38)), ink: ink, tint: 0.1)
            pyReader(&g, reader, ink: ink)
            bpPerson(&g, base: BP.pt(212, 228), facing: -1, ink: ink, shirt: 0.12, hair: 0, talk: false)
            // where the message will come to rest
            g.stroke(Path(roundedRect: CGRect(x: p3.x - 15, y: p3.y - 11, width: 30, height: 22), cornerRadius: 2.5), with: .color(ink.opacity(0.3)),
                     style: StrokeStyle(lineWidth: BP.hair, dash: [3, 3]))
        }

        // the tap: the hand carries the card to the reader and back
        let k = BP.eio(BP.pr(u, 0.6, 1.3)) - BP.eio(BP.pr(u, 1.8, 2.5))
        let hand = BP.mixp(restHand, tapHand, k), elbow = BP.mixp(restElbow, tapElbow, k)
        bpGroup(&c, alpha: a0) { g in
            let cc = BP.pt(hand.x - 13, hand.y - 1.5)
            pyFill(&g, Path(roundedRect: CGRect(x: cc.x - 13, y: cc.y - 8.5, width: 26, height: 17), cornerRadius: 2.5), ink: ink, tint: 0.16)
            var stripe = Path(); stripe.move(to: BP.pt(cc.x - 13, cc.y - 3)); stripe.addLine(to: BP.pt(cc.x + 13, cc.y - 3))
            g.stroke(stripe, with: .color(ink.opacity(0.6)), lineWidth: 2)
            g.stroke(Path(roundedRect: CGRect(x: cc.x - 9, y: cc.y + 1, width: 6, height: 4.5), cornerRadius: 1), with: .color(ink), lineWidth: BP.hair)
            bpArm(&g, from: shoulder, elbow: elbow, to: hand, ink: ink)
        }
        for i in 0..<2 {
            let p = BP.pr(u, 1.3 + 0.25 * Double(i), 2.1 + 0.25 * Double(i))
            guard p > 0.001, p < 0.999 else { continue }
            let r = 14 + 24 * BP.eout(p)
            c.stroke(Path(ellipseIn: CGRect(x: 142 - r, y: 187 - r, width: 2 * r, height: 2 * r)), with: .color(ink.opacity(0.7 * (1 - p))), lineWidth: BP.hair)
        }

        // the message (mustard) leaves the reader and floats off
        let e = BP.eio(BP.pr(u, 1.7, 3.2))
        let ea = BP.pr(u, 1.4, 1.8) * (1 - BP.pr(u, 5.2, 5.8))
        let bob = sin(max(0, u - 3.2) * 3) * 1.5 * BP.pr(u, 3.2, 3.6)
        bpGroup(&c, alpha: ea) { g in
            var trail = Path(); trail.move(to: p0)
            trail.addCurve(to: p3, control1: p1, control2: p2)
            bpTrace(&g, trail, p: e, color: acc.opacity(0.45), width: BP.hair, dash: [3, 4])
            let pos = bezier(e)
            pyEnvelope(&g, BP.pt(pos.x, pos.y + bob), color: acc)
        }

        bpLeader(&c, anchor: BP.pt(121, 175), elbow: BP.pt(106, 175), tail: -6, text: "CARD READER", ink: ink, p: BP.pr(t, 0.3, 1.0))
        bpLeader(&c, anchor: BP.pt(262, 102), elbow: BP.pt(270, 118), tail: 8, text: "MESSAGE", ink: acc, p: BP.pr(t, 1.9, 2.7))
        bpLeader(&c, anchor: BP.pt(252, 85), elbow: BP.pt(258, 62), tail: -8, text: "CAN THIS CARD PAY?", ink: acc, p: BP.pr(t, 2.3, 3.1))
    }
}

// MARK: - Card 2: reader, shop's bank, card network, your bank, and back

struct PayBPHops: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: pyLength, tick: 6.55,
                       label: "Four places in a row: a card reader, the shop's bank, a card network and your bank. A message, a small envelope shown in gold, hops along them one by one. Then a yes hops back along the same path to the card reader. Labels say: card reader, shop's bank, card network, your bank, yes.",
                       draw: { c, t, pal, clock in let (u, _) = pyCycle(t, clock, hold: 6.9, loop: 8.8); Self.draw(&c, t, pal, u) }, size: pySize)
    }

    private static let xs: [Double] = [50, 134, 218, 302]
    private static let y = 150.0

    /// Along the row: q 0...3 is how many hops have been made; each hop is an arc over the gap.
    private static func spot(_ q: Double) -> CGPoint {
        let k = min(2, max(0, Int(q))), f = q - Double(k)
        return BP.pt(BP.mix(xs[k], xs[k + 1], f), 104 - 16 * sin(Double.pi * f))
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        c.translateBy(x: 0, y: 20)

        // the path the message takes
        var lane = Path(); lane.move(to: BP.pt(xs[0], y)); lane.addLine(to: BP.pt(xs[3], y))
        bpTrace(&c, lane, p: BP.pr(t, 0, 0.8), color: ink.opacity(0.4), width: BP.hair, dash: [4, 4])

        let names = ["CARD READER", "SHOP'S BANK", "CARD NETWORK", "YOUR BANK"]
        for i in 0..<4 {
            let a = BP.eout(BP.pr(t, 0.1 + 0.15 * Double(i), 0.5 + 0.15 * Double(i)))
            bpGroup(&c, alpha: a) { g in
                let at = BP.pt(xs[i], y)
                switch i {
                case 0: pyReader(&g, at, ink: ink)
                case 2: pyNetwork(&g, at, ink: ink)
                default: pyBank(&g, at, ink: ink)
                }
            }
            let low = i % 2 == 0 ? 206.0 : 226.0
            let lp = BP.pr(t, 0.7 + 0.3 * Double(i), 1.4 + 0.3 * Double(i))
            pyStub(&c, from: BP.pt(xs[i], y + 34), to: BP.pt(xs[i], low - 9), ink: ink, p: BP.pr(lp, 0, 0.6))
            bpText(&c, names[i], BP.pt(xs[i], low), ink: ink, alpha: BP.pr(lp, 0.6, 1))
        }

        // the message goes out (mustard), the yes comes back (mustard)
        var out = 0.0, back = 3.0
        for k in 0..<3 {
            out += BP.eio(BP.pr(u, 0.8 + 0.9 * Double(k), 1.35 + 0.9 * Double(k)))
            back -= BP.eio(BP.pr(u, 4.2 + 0.9 * Double(k), 4.75 + 0.9 * Double(k)))
        }
        let envA = BP.pr(u, 0.2, 0.6) * (1 - BP.pr(u, 3.35, 3.75))
        bpGroup(&c, alpha: envA) { g in pyEnvelope(&g, spot(out), color: acc) }
        let yesA = BP.pr(u, 3.45, 3.85) * (1 - BP.pr(u, 7.7, 8.2))
        bpGroup(&c, alpha: yesA) { g in pyYes(&g, spot(back), color: acc, word: true) }
    }
}

// MARK: - Card 3: the yes is a promise, the money is not at the shop

struct PayBPPromise: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: pyLength, tick: 2.0,
                       label: "Your bank on the left with a bar for what you can spend, full. A yes, shown in gold, arrives at the bank and the bar drops. On the right the shop's till stays empty, with a gap between the bank and the shop. Labels say: your bank, what you can spend, your bank's yes, the shop.",
                       draw: { c, t, pal, clock in let (u, _) = pyCycle(t, clock, hold: 4.0, loop: 7.2); Self.draw(&c, t, pal, u) }, size: pySize)
    }

    private static let bank = BP.pt(79, 118), shop = BP.pt(270, 140)
    private static let track = CGRect(x: 24, y: 162, width: 110, height: 16)

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        c.translateBy(x: 0, y: 30)
        let a0 = BP.eout(BP.pr(t, 0, 0.5)), a1 = BP.eout(BP.pr(t, 0.2, 0.7))

        bpGroup(&c, alpha: a0) { g in pyBank(&g, bank, ink: ink) }
        bpGroup(&c, alpha: a1) { g in pyShop(&g, shop, ink: ink) }

        // the gap between them: a dimension line with nothing on it
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.5, 1.1))) { g in
            var gap = Path()
            gap.move(to: BP.pt(114, 146)); gap.addLine(to: BP.pt(232, 146))
            for x in [114.0, 232.0] { gap.move(to: BP.pt(x, 140)); gap.addLine(to: BP.pt(x, 152)) }
            g.stroke(gap, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: BP.hair, dash: [4, 4]))
        }

        // what you can spend: a full bar that drops when the yes arrives
        let drop = BP.eio(BP.pr(u, 2.0, 2.7))
        let level = 1 - 0.4 * drop
        let ba = BP.pr(u, 0, 0.5) * (1 - BP.pr(u, 5.9, 6.4))
        bpGroup(&c, alpha: a0) { g in
            let r = Path(roundedRect: track, cornerRadius: 3)
            g.fill(r, with: .color(BP.paper)); g.fill(r, with: .color(ink.opacity(0.06)))
            g.stroke(r, with: .color(ink), lineWidth: BP.edge)
        }
        bpGroup(&c, alpha: ba) { g in
            let inner = track.insetBy(dx: 2.5, dy: 2.5)
            let full = inner.width
            g.fill(Path(roundedRect: CGRect(x: inner.minX, y: inner.minY, width: full * level, height: inner.height), cornerRadius: 1.5), with: .color(acc.opacity(0.85)))
            // what has just left it
            g.stroke(Path(CGRect(x: inner.minX + full * level, y: inner.minY, width: full * (1 - level), height: inner.height)),
                     with: .color(acc.opacity(0.7 * drop)), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 3]))
        }

        // the yes (mustard) arrives from the right and rests beside the bank
        let move = BP.eio(BP.pr(u, 0.6, 1.8))
        let ya = BP.pr(u, 0.5, 0.9) * (1 - BP.pr(u, 5.9, 6.4))
        let pulse = 1 + 0.06 * sin(Double.pi * BP.pr(u, 1.8, 2.2))
        bpGroup(&c, alpha: ya) { g in
            var s = g
            let at = BP.pt(BP.mix(222, 130, move), bank.y)
            s.translateBy(x: at.x, y: at.y); s.scaleBy(x: pulse, y: pulse)
            pyYes(&s, .zero, color: acc, word: false)
        }

        bpLeader(&c, anchor: BP.pt(66, 104), elbow: BP.pt(48, 76), tail: 10, text: "YOUR BANK", ink: ink, p: BP.pr(t, 0.4, 1.0))
        bpLeader(&c, anchor: BP.pt(52, 178), elbow: BP.pt(52, 206), tail: 10, text: "WHAT YOU CAN SPEND", ink: acc, p: BP.pr(t, 0.9, 1.7))
        bpLeader(&c, anchor: BP.pt(130, 109), elbow: BP.pt(146, 84), tail: 10, text: "YOUR BANK'S YES", ink: acc, p: BP.pr(t, 1.5, 2.3))
        bpLeader(&c, anchor: BP.pt(262, 173), elbow: BP.pt(262, 200), tail: 10, text: "THE SHOP", ink: ink, p: BP.pr(t, 2.0, 2.8))
    }
}

// MARK: - Card 4: totals, a few working days, then the shop is paid

struct PayBPTotals: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: pyLength, tick: 8.2,
                       label: "Many small payments drop onto two banks and add up into totals. Three calendar days tick past. Only then do the totals, shown in gold, slide from the banks to the shop. Labels say: many payments, totals, a few working days, the shop.",
                       draw: { c, t, pal, clock in let (u, _) = pyCycle(t, clock, hold: 9.0, loop: 10.6); Self.draw(&c, t, pal, u) }, size: pySize)
    }

    private static let banks: [Double] = [38, 100]
    private static let shop = BP.pt(270, 87)
    private static let blockY = 108.0
    private static let slots: [(Double, Double)] = [(-11, 0), (0, 0), (11, 0), (-5.5, -6), (5.5, -6), (0, -12)]
    private static let cal = CGRect(x: 148, y: 176, width: 92, height: 40)

    private static func block(_ c: inout GraphicsContext, _ at: CGPoint, color: Color, alpha: Double) {
        bpGroup(&c, alpha: alpha) { g in
            pyFill(&g, Path(roundedRect: CGRect(x: at.x - 10, y: at.y - 6, width: 20, height: 12), cornerRadius: 2), ink: color, tint: 0.28)
            var l = Path()
            for dy in [-1.5, 2.0] { l.move(to: BP.pt(at.x - 5, at.y + dy)); l.addLine(to: BP.pt(at.x + 5, at.y + dy)) }
            g.stroke(l, with: .color(color.opacity(0.7)), lineWidth: BP.hair)
        }
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double) {
        let ink = pal.ink, acc = pal.accent
        c.translateBy(x: 0, y: 10)
        let a0 = BP.eout(BP.pr(t, 0, 0.5)), a1 = BP.eout(BP.pr(t, 0.3, 0.8))

        bpGroup(&c, alpha: a0) { g in for x in banks { pyBank(&g, BP.pt(x, 140), ink: ink) } }
        bpGroup(&c, alpha: a1) { g in pyShop(&g, shop, ink: ink) }

        // the road the totals will take
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.5, 1.1))) { g in
            var road = Path(); road.move(to: BP.pt(124, blockY)); road.addLine(to: BP.pt(236, blockY))
            g.stroke(road, with: .color(ink.opacity(0.35)), style: StrokeStyle(lineWidth: BP.hair, dash: [4, 4]))
        }

        // the calendar: three ticks pass
        let fade = 1 - BP.pr(u, 9.6, 10.2)
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.4, 1.0))) { g in
            let head = CGRect(x: cal.minX, y: cal.minY, width: cal.width, height: 9)
            pyFill(&g, Path(CGRect(x: cal.minX, y: cal.minY, width: cal.width, height: cal.height)), ink: ink, tint: 0.06)
            g.fill(Path(head), with: .color(ink.opacity(0.26)))
            g.stroke(Path(head), with: .color(ink), lineWidth: BP.hair)
            var rings = Path()
            for dx in [0.22, 0.78] { rings.move(to: BP.pt(cal.minX + cal.width * dx, cal.minY - 4)); rings.addLine(to: BP.pt(cal.minX + cal.width * dx, cal.minY + 2)) }
            g.stroke(rings, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        for j in 0..<3 {
            let cell = CGRect(x: cal.minX + 2 + 29.5 * Double(j), y: cal.minY + 12, width: 27, height: 25)
            let p = BP.pr(u, 3.9 + 0.9 * Double(j), 4.3 + 0.9 * Double(j))
            bpGroup(&c, alpha: BP.eout(BP.pr(t, 0.6, 1.2))) { g in
                g.fill(Path(roundedRect: cell, cornerRadius: 2), with: .color(ink.opacity(0.05 + 0.13 * p * fade)))
                g.stroke(Path(roundedRect: cell, cornerRadius: 2), with: .color(ink.opacity(0.6)), lineWidth: BP.hair)
            }
            var tick = Path()
            tick.move(to: BP.pt(cell.midX - 6, cell.midY)); tick.addLine(to: BP.pt(cell.midX - 1.5, cell.midY + 5)); tick.addLine(to: BP.pt(cell.midX + 7, cell.midY - 5))
            bpGroup(&c, alpha: fade) { g in bpTrace(&g, tick, p: p, color: ink, width: 2) }
        }

        // many payments rain onto the banks and add up into totals (a total is ink, then mustard as it sets off)
        for i in 0..<12 {
            let s = 0.3 + 0.2 * Double(i)
            let f = BP.pr(u, s, s + 0.45)
            let slot = slots[i / 2], bx = banks[i % 2]
            let restY = 113 + slot.1
            let at = BP.pt(bx + slot.0, 30 + (restY - 30) * f * f)
            let a = BP.pr(u, s, s + 0.08) * (1 - BP.pr(u, 2.9, 3.3))
            bpGroup(&c, alpha: a) { g in
                pyFill(&g, Path(roundedRect: CGRect(x: at.x - 5, y: at.y - 3.2, width: 10, height: 6.4), cornerRadius: 1.4), ink: ink, tint: 0.2, width: BP.hair)
            }
        }
        let ta = BP.pr(u, 2.9, 3.5) * fade
        let m = BP.pr(u, 6.2, 6.6)
        let e = BP.eio(BP.pr(u, 6.6, 8.2))
        let targets: [Double] = [256, 284]
        for (i, bx) in banks.enumerated() {
            let at = BP.pt(BP.mix(bx, targets[i], e), blockY)
            block(&c, at, color: ink, alpha: ta * (1 - m))
            block(&c, at, color: acc, alpha: ta * m)
        }

        bpLeader(&c, anchor: BP.pt(114, 78), elbow: BP.pt(124, 60), tail: 10, text: "MANY PAYMENTS", ink: ink, p: BP.pr(t, 0.3, 1.0))
        bpLeader(&c, anchor: BP.pt(110, 103), elbow: BP.pt(124, 88), tail: 10, text: "TOTALS", ink: acc, p: BP.pr(t, 0.8, 1.5))
        bpLeader(&c, anchor: BP.pt(194, 216), elbow: BP.pt(186, 242), tail: -10, text: "A FEW WORKING DAYS", ink: ink, p: BP.pr(t, 1.3, 2.1))
        bpLeader(&c, anchor: BP.pt(262, 120), elbow: BP.pt(262, 148), tail: 10, text: "THE SHOP", ink: ink, p: BP.pr(t, 1.8, 2.6))
    }
}
