import SwiftUI

// "Why isn't the shop paid the moment you tap your card?" pictures in the drafting style (2026-11-03): white paper, crisp black outlines, a
// card terminal drawn like a real one, light hatching for shade and ONE yellow accent for the message. The objects themselves (terminal, hand
// and card, bank, network, shop, envelope, yes, slip) live in the drafting kit (`Drafting.swift`). Labels are the slide's own words. On a swipeable card each picture loops; narrated it plays once with the voice
// and holds. Drawn in the default 343 x 320 design space, clear of the bottom-right corner (x > 288, y > 235).

private func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

// MARK: - Card 1: you tap, it beeps, and you walk away

struct PayDRTap: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 4.6

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 1.5,
                       label: "A line drawing on white: a hand holds a bank card out to a card terminal on a counter, then taps it on the contactless panel. Thin rings spread from the panel. The hand pulls back, and a short message, a gold envelope with a question mark, rises from the terminal and floats up and away. Labels say: card reader, message, can this card pay?",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u, clock) }
                       })
    }

    private static let term = pt(111, 114)           // the terminal's top left
    private static let tapAt = pt(153, 124)         // where the card lies on the contactless panel
    private static let rest = pt(-70, -58)
    private static let m0 = pt(157, 106), m1 = pt(173, 40), m2 = pt(233, 30), m3 = pt(267, 62)

    private static func flight(_ e: Double) -> CGPoint {
        let m = 1 - e
        return pt(m * m * m * m0.x + 3 * m * m * e * m1.x + 3 * m * e * e * m2.x + e * e * e * m3.x,
                  m * m * m * m0.y + 3 * m * m * e * m1.y + 3 * m * e * e * m2.y + e * e * e * m3.y)
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ clock: Double) {
        let on = BP.pr(u, 0, 0.9), fill = BP.pr(u, 0.25, 0.8)

        // the counter
        var counter = Path(); counter.move(to: pt(14, 232)); counter.addLine(to: pt(284, 232))
        DR.draw(&c, counter, p: on, width: DR.line + 0.2)
        var edge = Path(); edge.move(to: pt(14, 240)); edge.addLine(to: pt(284, 240))
        DR.draw(&c, edge, p: on, width: DR.hair, color: DR.ink.opacity(0.5))

        DR.terminal(&c, at: term, on: on, fill: fill)

        // rings spread from the panel as the card touches it
        for i in 0..<3 {
            let p = BP.pr(u, 1.45 + 0.22 * Double(i), 2.3 + 0.22 * Double(i))
            guard p > 0.001, p < 0.999 else { continue }
            let r = 12 + 30 * BP.eout(p)
            var ring = Path()
            ring.addArc(center: tapAt, radius: r, startAngle: .radians(-1.0), endAngle: .radians(1.0), clockwise: false)
            ring.addArc(center: tapAt, radius: r, startAngle: .radians(.pi - 1.0), endAngle: .radians(.pi + 1.0), clockwise: false)
            c.stroke(ring, with: .color(DR.ink.opacity(0.75 * (1 - p))), style: StrokeStyle(lineWidth: DR.hair + 0.2, lineCap: .round, dash: [3, 2.5]))
        }

        // the hand carries the card in to the panel, holds, and takes it back
        let k = BP.eio(BP.pr(u, 0.9, 1.5)) - BP.eio(BP.pr(u, 2.0, 2.7))
        let cardAt = pt(tapAt.x + rest.x * (1 - k), tapAt.y + rest.y * (1 - k))
        var hc = c                                                     // the hand comes in from the left, so the whole hand is mirrored
        hc.translateBy(x: cardAt.x, y: 0); hc.scaleBy(x: -1, y: 1); hc.translateBy(x: -cardAt.x, y: 0)
        DR.heldCard(&hc, at: cardAt, on: on, fill: fill)

        // the message: leaves the top of the terminal and floats off, then bobs a little where it rests
        let e = BP.eio(BP.pr(u, 2.2, 3.5))
        if e > 0 {
            var trail = Path(); trail.move(to: m0); trail.addCurve(to: m3, control1: m1, control2: m2)
            DR.draw(&c, trail, p: e, width: DR.hair, color: DR.ink.opacity(0.5), dash: [3, 3.5])
            let pos = flight(e)
            DR.envelope(&c, at: pt(pos.x, pos.y + sin(max(0, clock - 3.5) * 2.4) * 1.5 * BP.pr(u, 3.4, 3.8)), alpha: BP.pr(u, 2.2, 2.45))
        }

        DR.label(&c, "CARD READER", anchor: pt(term.x + 71, 176), at: pt(250, 204), align: .center, p: BP.pr(u, 0.5, 1.0))
        DR.label(&c, "MESSAGE", anchor: pt(m3.x, m3.y - 13), at: pt(262, 22), align: .leading, p: BP.pr(u, 2.9, 3.3))
        DR.label(&c, "CAN THIS CARD PAY?", anchor: pt(m3.x, m3.y + 13), at: pt(224, 98), align: .leading, p: BP.pr(u, 3.8, 4.3))
    }
}

// MARK: - Card 2: reader, shop's bank, card network, your bank, and back

struct PayDRHops: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 8.8

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 6.55,
                       label: "A line drawing on white: four places in a row, a card reader, the shop's bank, a card network and your bank. A message, a gold envelope, hops along them one by one. Then a gold yes hops back along the same path to the card reader. Labels say: card reader, shop's bank, card network, your bank, yes.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let xs: [Double] = [50, 134, 218, 302]
    private static let base = 168.0

    /// Along the row: q 0...3 is how many hops have been made; each hop is an arc over the gap.
    private static func spot(_ q: Double) -> CGPoint {
        let k = min(2, max(0, Int(q))), f = q - Double(k)
        return pt(BP.mix(xs[k], xs[k + 1], f), 86 - 16 * sin(Double.pi * f))
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        var ground = Path(); ground.move(to: pt(14, base)); ground.addLine(to: pt(330, base))
        DR.draw(&c, ground, p: BP.pr(u, 0, 0.8), width: DR.line + 0.2)

        let names = ["CARD READER", "SHOP'S BANK", "CARD NETWORK", "YOUR BANK"]
        for i in 0..<4 {
            let on = BP.pr(u, 0.1 + 0.15 * Double(i), 0.8 + 0.15 * Double(i)), fill = BP.pr(u, 0.3 + 0.15 * Double(i), 0.7 + 0.15 * Double(i))
            switch i {
            case 0:
                var r = c
                r.translateBy(x: xs[0] - 22, y: base - 118 * 0.55 - 6); r.scaleBy(x: 0.55, y: 0.55)
                DR.terminal(&r, at: .zero, on: on, fill: fill)
            case 2: DR.network(&c, at: pt(xs[2], base - 30), on: on, fill: fill)
            default: DR.bank(&c, cx: xs[i], base: base - 1, on: on, fill: fill)
            }
            let low = i % 2 == 0 ? 200.0 : 222.0
            DR.label(&c, names[i], anchor: pt(xs[i], base + 3), at: pt(xs[i], low), align: .center, p: BP.pr(u, 0.7 + 0.3 * Double(i), 1.4 + 0.3 * Double(i)))
        }

        // the message goes out, the yes comes back, both in the accent
        var out = 0.0, back = 3.0
        for k in 0..<3 {
            out += BP.eio(BP.pr(u, 0.8 + 0.9 * Double(k), 1.35 + 0.9 * Double(k)))
            back -= BP.eio(BP.pr(u, 4.2 + 0.9 * Double(k), 4.75 + 0.9 * Double(k)))
        }
        DR.envelope(&c, at: spot(out), alpha: BP.pr(u, 0.2, 0.6) * (1 - BP.pr(u, 3.35, 3.75)))
        DR.yes(&c, at: spot(back), alpha: BP.pr(u, 3.45, 3.85) * (1 - BP.pr(u, 7.7, 8.2)), word: true)
    }
}

// MARK: - Card 3: the yes is a promise, the money is not at the shop

struct PayDRPromise: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 5.6

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 3.0,
                       label: "A line drawing on white: your bank on the left with a bar for what you can spend, full. A yes, shown in gold, arrives at the bank and the bar drops. On the right the shop's till stays empty, with a gap between the bank and the shop. Labels say: your bank, what you can spend, your bank's yes, the shop.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let bankX = 270.0, shopX = 79.0, base = 150.0
    private static let track = CGRect(x: 215, y: 166, width: 110, height: 16)

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        let on = BP.pr(u, 0, 0.8), fill = BP.pr(u, 0.2, 0.7)
        var ground = Path(); ground.move(to: pt(14, base)); ground.addLine(to: pt(330, base))
        DR.draw(&c, ground, p: on, width: DR.line + 0.2)
        DR.bank(&c, cx: bankX, base: base - 1, on: on, fill: fill)
        DR.shop(&c, cx: shopX, base: base - 1, on: BP.pr(u, 0.15, 0.95), fill: BP.pr(u, 0.35, 0.85))

        // the gap between them: a dimension line with nothing on it
        var gap = Path()
        gap.move(to: pt(120, 126)); gap.addLine(to: pt(228, 126))
        for x in [120.0, 228.0] { gap.move(to: pt(x, 120)); gap.addLine(to: pt(x, 132)) }
        DR.draw(&c, gap, p: BP.pr(u, 3.8, 4.1), width: DR.hair, color: DR.ink.opacity(0.6), dash: [4, 3.5])

        // what you can spend: a full bar that drops when the yes arrives
        let drop = BP.eio(BP.pr(u, 2.7, 3.3)), level = 1 - 0.4 * drop
        let tr = Path(roundedRect: track, cornerRadius: 3)
        var tg = c; tg.opacity = fill
        tg.fill(tr, with: .color(DR.face))
        let inner = track.insetBy(dx: 2.5, dy: 2.5)
        let bar = Path(roundedRect: CGRect(x: inner.minX, y: inner.minY, width: inner.width * level, height: inner.height), cornerRadius: 1.5)
        tg.fill(bar, with: .color(DR.side))
        DR.hatch(&tg, bar, in: bar.boundingRect, spacing: 3, alpha: 0.4)
        tg.stroke(bar, with: .color(DR.ink), lineWidth: DR.hair + 0.2)
        var gone = Path(); gone.addRect(CGRect(x: inner.minX + inner.width * level, y: inner.minY, width: inner.width * (1 - level), height: inner.height))
        tg.stroke(gone, with: .color(DR.ink.opacity(0.7 * drop)), style: StrokeStyle(lineWidth: DR.hair, dash: [3, 3]))
        DR.draw(&c, tr, p: on)

        // the yes arrives from the right and rests beside the bank
        let move = BP.eio(BP.pr(u, 1.2, 1.9)), pulse = 1 + 0.06 * sin(Double.pi * BP.pr(u, 1.9, 2.3))
        var s = c
        let at = pt(BP.mix(130, 204, move), base - 38)
        s.translateBy(x: at.x, y: at.y); s.scaleBy(x: pulse, y: pulse)
        DR.yes(&s, at: .zero, alpha: BP.pr(u, 1.2, 1.4), word: false)

        DR.label(&c, "YOUR BANK", anchor: pt(bankX - 14, base - 54), at: pt(258, 56), align: .leading, p: BP.pr(u, 0.4, 1.0))
        DR.label(&c, "WHAT YOU CAN SPEND", anchor: pt(250, 184), at: pt(268, 214), align: .center, p: BP.pr(u, 2.2, 2.8))
        DR.label(&c, "YOUR BANK'S YES", anchor: pt(at.x, base - 48), at: pt(142, 80), align: .leading, p: BP.pr(u, 4.6, 5.2))
        DR.label(&c, "THE SHOP", anchor: pt(shopX, base + 3), at: pt(shopX, 190), align: .center, p: BP.pr(u, 3.8, 4.4))
    }
}

// MARK: - Card 4: totals, a few working days, then the shop is paid

struct PayDRTotals: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 10.4

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 9.6,
                       label: "A line drawing on white: many small payment slips drop onto two banks and add up into totals. Three days tick off on a calendar. Only then do the totals, shown in gold, slide from the banks to the shop. Labels say: many payments, totals, a few working days, the shop.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let banks: [Double] = [237, 299]
    private static let shopX = 73.0, base = 150.0, pileY = 70.0
    private static let slots: [(Double, Double)] = [(-11, 0), (0, 0), (11, 0), (-5.5, -7), (5.5, -7), (0, -14)]
    private static let cal = CGRect(x: 148, y: 176, width: 92, height: 40)

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        let on = BP.pr(u, 0, 0.8), fill = BP.pr(u, 0.2, 0.7)
        var ground = Path(); ground.move(to: pt(14, base)); ground.addLine(to: pt(330, base))
        DR.draw(&c, ground, p: on, width: DR.line + 0.2)
        for x in banks { DR.bank(&c, cx: x, base: base - 1, on: on, fill: fill) }
        DR.shop(&c, cx: shopX, base: base - 1, on: BP.pr(u, 0.3, 1.0), fill: BP.pr(u, 0.5, 1.0), tray: false)

        // the calendar: three ticks pass
        let fade = 1.0
        let page = Path(roundedRect: cal, cornerRadius: 3)
        var cg = c; cg.opacity = BP.pr(u, 0.4, 1.0)
        cg.fill(page, with: .color(DR.face)); DR.draw(&c, page, p: BP.pr(u, 0.4, 1.0))
        var band = Path(); band.move(to: pt(cal.minX, cal.minY + 9)); band.addLine(to: pt(cal.maxX, cal.minY + 9))
        DR.draw(&c, band, p: BP.pr(u, 0.4, 1.0))
        for dx in [0.22, 0.78] {
            DR.draw(&c, Path(roundedRect: CGRect(x: cal.minX + cal.width * dx - 2, y: cal.minY - 5, width: 4, height: 9), cornerRadius: 2), p: BP.pr(u, 0.4, 1.0))
        }
        for j in 0..<3 {
            let cell = CGRect(x: cal.minX + 3 + 29.5 * Double(j), y: cal.minY + 13, width: 27, height: 24)
            let p = BP.pr(u, 5.0 + 0.8 * Double(j), 5.4 + 0.8 * Double(j))
            var cc = c; cc.opacity = BP.pr(u, 0.6, 1.2)
            let cp = Path(roundedRect: cell, cornerRadius: 2)
            cc.stroke(cp, with: .color(DR.ink.opacity(0.7)), lineWidth: DR.hair)
            var tick = Path()
            tick.move(to: pt(cell.midX - 6, cell.midY)); tick.addLine(to: pt(cell.midX - 1.5, cell.midY + 5)); tick.addLine(to: pt(cell.midX + 7, cell.midY - 5))
            var tg = c; tg.opacity = fade
            DR.draw(&tg, tick, p: p, width: 2)
        }

        // many payments rain onto the banks and add up into totals; the totals turn gold as they set off for the shop
        for i in 0..<12 {
            let s = 0.3 + 0.15 * Double(i)
            let f = BP.pr(u, s, s + 0.45)
            let slot = slots[i / 2], bx = banks[i % 2]
            let at = pt(bx + slot.0, 46 + (pileY + slot.1 - 46) * f * f)
            DR.slip(&c, at: at, big: false, alpha: BP.pr(u, s, s + 0.08) * (1 - BP.pr(u, 2.6, 3.0)))
        }
        let ta = BP.pr(u, 2.6, 3.2) * fade, m = BP.pr(u, 7.6, 8.0), e = BP.eio(BP.pr(u, 8.0, 9.6))
        let targets: [Double] = [96, 66]
        for (i, bx) in banks.enumerated() {
            DR.slip(&c, at: pt(BP.mix(bx, targets[i], e), pileY - 6 + 36 * BP.eio(BP.pr(u, 9.6, 10.2))), big: true, set: m, alpha: ta)
        }

        DR.label(&c, "MANY PAYMENTS", anchor: pt(banks[1], pileY - 10), at: pt(228, 36), align: .leading, p: BP.pr(u, 0.3, 1.0))
        DR.label(&c, "TOTALS", anchor: pt(banks[0] - 8, pileY - 14), at: pt(150, 40), align: .leading, p: BP.pr(u, 2.6, 3.2))
        DR.label(&c, "A FEW WORKING DAYS", anchor: pt(194, cal.maxY + 2), at: pt(190, 246), align: .center, p: BP.pr(u, 4.2, 4.9))
        DR.label(&c, "THE SHOP", anchor: pt(shopX, base + 3), at: pt(shopX + 6, 188), align: .center, p: BP.pr(u, 3.4, 4.0))
    }
}
