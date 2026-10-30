import SwiftUI

// "In a room of 23, what's the chance two share a birthday?" pictures, drawn as blueprint technical illustrations (2026-10-28).
// One chalk-ink colour, one mustard accent per card (the needle, you and your day, your 22 handshakes, the rooms with a match, the chance bar),
// thin even lines, flat tints only, mono uppercase labels that use the slide text's own words. Every picture loops ambiently: it plays its
// story, holds the end beat for a second, then fades (or eases) back to its start and goes round again. Labels and the first fade-in follow the
// stage's `t` so they appear once and stay; Reduce Motion shows the held end state. Drawn in a 343 x 340 design space; keep clear of the
// bottom-right corner (x > 285, y > 255), where like and save sit.

private let bbSize = CGSize(width: 343, height: 340)

// MARK: - Shared helpers

/// Loop time: (seconds into the round, reduce). The round lasts `story` + 1.6 s: the story, 1 s of holding the end, then 0.6 s of reset.
/// Reduce Motion (the stage's clock stands still behind `t`) shows the held end state.
private func bbCycle(_ t: Double, _ clock: Double, story: Double) -> (Double, Bool) {
    if clock < t { return (story, true) }
    return (clock.truncatingRemainder(dividingBy: story + 1.6), false)
}

/// 1 while the story plays and holds, easing to 0 over the last 0.6 s of the round (the reset fade).
private func bbFade(_ u: Double, _ story: Double) -> Double { 1 - BP.pr(u, story + 1.0, story + 1.6) }

/// A fixed pseudo-random number 0...1, so pictures never shimmer between frames.
private func bbHash(_ a: Int, _ b: Int) -> Double {
    let v = sin(Double(a) * 12.9898 + Double(b) * 78.233) * 43758.5453
    return abs(v - v.rounded(.down))
}

private func bbDot(_ c: inout GraphicsContext, _ at: CGPoint, r: Double, color: Color, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    c.fill(Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(alpha)))
}

/// Mono text at a larger size, for counters.
private func bbNum(_ c: inout GraphicsContext, _ s: String, _ at: CGPoint, ink: Color, alpha: Double = 1, anchor: UnitPoint = .center, size: CGFloat = 16) {
    guard alpha > 0.01 else { return }
    c.draw(c.resolve(Text(s).font(T.mono(size)).foregroundColor(ink.opacity(alpha))), at: at, anchor: anchor)
}

/// One small person in a party hat, standing on `feet` (about 26 points tall at s = 1); solid paper fill so lines behind it are hidden.
private func bbMini(_ c: inout GraphicsContext, _ x: Double, _ feet: Double, ink: Color, alpha: Double = 1, s: Double = 1, hat: Bool = true, tint: Double = 0.14) {
    guard alpha > 0.01 else { return }
    var g = c
    g.opacity = alpha
    let hy = feet - 15.5 * s, r = 3.5 * s
    var legs = Path()
    for d in [-1.6, 1.6] { legs.move(to: BP.pt(x + d * s, feet - 4 * s)); legs.addLine(to: BP.pt(x + d * s, feet)) }
    g.stroke(legs, with: .color(ink), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
    var body = Path()
    body.move(to: BP.pt(x - 3.2 * s, feet - 11 * s)); body.addLine(to: BP.pt(x + 3.2 * s, feet - 11 * s))
    body.addLine(to: BP.pt(x + 4 * s, feet - 3.5 * s)); body.addLine(to: BP.pt(x - 4 * s, feet - 3.5 * s)); body.closeSubpath()
    g.fill(body, with: .color(BP.paper)); g.fill(body, with: .color(ink.opacity(tint)))
    g.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: BP.hair, lineJoin: .round))
    let head = Path(ellipseIn: CGRect(x: x - r, y: hy - r, width: 2 * r, height: 2 * r))
    g.fill(head, with: .color(BP.paper)); g.stroke(head, with: .color(ink), lineWidth: BP.hair)
    if hat {
        var h = Path()
        h.move(to: BP.pt(x, hy - r - 7 * s)); h.addLine(to: BP.pt(x + 3 * s, hy - r + 0.8 * s)); h.addLine(to: BP.pt(x - 3 * s, hy - r + 0.8 * s)); h.closeSubpath()
        g.fill(h, with: .color(BP.paper)); g.fill(h, with: .color(ink.opacity(0.35)))
        g.stroke(h, with: .color(ink), style: StrokeStyle(lineWidth: BP.hair, lineJoin: .round))
        bbDot(&g, BP.pt(x, hy - r - 7 * s), r: 1.1 * s + 0.2, color: ink)
    }
}

private func bbPoly(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }

// MARK: - Card 1: a room of 23, and a dial that guesses low then swings to about 50%

struct BirthBPRoom: View {
    let active: Bool
    private static let story = 2.7

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.3,
                       label: "A room of 23 small people in party hats, standing in two rows. Above them a dial reads chance. Its gold needle first sits low, the small guess, then swings up to about 50 percent and holds, then eases back and starts again. Labels say: 23 people, chance, about 50%.",
                       draw: { c, t, pal, clock in let (u, r) = bbCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u, r) }, size: bbSize)
    }

    private static let center = BP.pt(171, 150)
    private static let radius = 80.0

    private static func onDial(_ f: Double, _ r: Double) -> CGPoint {
        let a = Double.pi + Double.pi * f
        return BP.pt(center.x + r * cos(a), center.y + r * sin(a))
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))

        // the dial
        bpGroup(&c, alpha: a0) { g in
            var half = Path()
            half.move(to: BP.pt(center.x - radius, center.y))
            for i in 0...48 { half.addLine(to: onDial(Double(i) / 48, radius)) }
            half.closeSubpath()
            g.fill(half, with: .color(BP.paper)); g.fill(half, with: .color(ink.opacity(0.07)))
            g.stroke(half, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
            var ticks = Path()
            for k in 0...20 {
                let f = Double(k) / 20, len = k % 5 == 0 ? 11.0 : 5.0
                ticks.move(to: onDial(f, radius)); ticks.addLine(to: onDial(f, radius - len))
            }
            g.stroke(ticks, with: .color(ink.opacity(0.7)), lineWidth: BP.hair)
        }
        bpGuide(&c, BP.pt(center.x, center.y - radius - 3), BP.pt(center.x, 56), p: BP.pr(t, 1.6, 2.2), color: acc.opacity(0.7))
        bpText(&c, "ABOUT 50%", BP.pt(center.x, 44), ink: acc, alpha: BP.pr(t, 1.8, 2.4))
        bpText(&c, "CHANCE", BP.pt(center.x, center.y + 20), ink: ink, alpha: BP.pr(t, 0.2, 0.8))

        // the needle: a low guess, a swing up to 50%, a hold, and back down to the guess before the round ends
        let swing = BP.eio(BP.pr(u, 0.9, 2.3)), back = BP.eio(BP.pr(u, Self.story + 1.0, Self.story + 1.6))
        let after = u - 2.3
        let wobble = after > 0 ? 0.014 * exp(-after * 5) * sin(after * 16) : 0
        let jitter = 0.01 * sin(u * 7) * (1 - BP.pr(u, 0.7, 1.0))
        let f = 0.10 + (0.40 * swing + wobble) * (1 - back) + jitter
        bpGroup(&c, alpha: a0) { g in
            var n = Path(); n.move(to: center); n.addLine(to: onDial(f, radius - 14))
            g.stroke(n, with: .color(acc), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            g.fill(Path(ellipseIn: CGRect(x: center.x - 5.5, y: center.y - 5.5, width: 11, height: 11)), with: .color(BP.paper))
            g.stroke(Path(ellipseIn: CGRect(x: center.x - 5.5, y: center.y - 5.5, width: 11, height: 11)), with: .color(ink), lineWidth: BP.edge)
        }

        // the room: 12 + 11 people
        for i in 0..<23 {
            let row = i < 12 ? 0 : 1, k = row == 0 ? i : i - 12
            let x = row == 0 ? 171 + (Double(k) - 5.5) * 22 : 171 + (Double(k) - 5) * 22
            let a = BP.pr(t, 0.05 + 0.014 * Double(i), 0.3 + 0.014 * Double(i))
            bbMini(&c, x, row == 0 ? 222 : 252, ink: ink, alpha: a, tint: 0.08 + 0.12 * bbHash(i, 3))
        }
        bpLeader(&c, anchor: BP.pt(50, 198), elbow: BP.pt(28, 178), tail: 10, text: "23 PEOPLE", ink: ink, p: BP.pr(t, 0.3, 0.9))
    }
}

// MARK: - Card 2: you in gold, and 22 strangers each dropping a birthday on a year calendar

struct BirthBPYours: View {
    let active: Bool
    private static let story = 3.3

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.05,
                       label: "You, in gold, wearing a party hat, next to a calendar grid of the year with your birthday marked in gold. Below, a row of 22 strangers in party hats each drops a birthday onto the calendar, one after another, and none lands on your day. Labels say: you, 22 strangers, less than 6%.",
                       draw: { c, t, pal, clock in let (u, r) = bbCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u, r) }, size: bbSize)
    }

    private static let gx = 140.0, gy = 44.0, cell = 7.0, cols = 19
    private static let mine = 99                                   // row 5, column 4
    private static let cells: [Int] = {
        var used: Set<Int> = [mine]
        var out: [Int] = []
        for i in 0..<22 {
            var k = Int(bbHash(i, 7) * 365) % 365
            while used.contains(k) { k = (k + 1) % 365 }
            used.insert(k); out.append(k)
        }
        return out
    }()

    private static func centre(_ idx: Int) -> CGPoint {
        BP.pt(gx + Double(idx % cols) * cell + cell / 2, gy + Double(idx / cols) * cell + cell / 2)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))
        let fo = bbFade(u, story)

        // the calendar grid: 365 days
        bpGroup(&c, alpha: a0) { g in
            let frame = Path(roundedRect: CGRect(x: gx - 6, y: gy - 6, width: 19 * cell + 12, height: 20 * cell + 12), cornerRadius: 3)
            g.fill(frame, with: .color(BP.paper)); g.fill(frame, with: .color(ink.opacity(0.05)))
            g.stroke(frame, with: .color(ink), lineWidth: BP.edge)
            var days = Path()
            for i in 0..<365 {
                days.addRect(CGRect(x: gx + Double(i % cols) * cell + 0.9, y: gy + Double(i / cols) * cell + 0.9, width: cell - 1.8, height: cell - 1.8))
            }
            g.fill(days, with: .color(ink.opacity(0.16)))
            g.stroke(days, with: .color(ink.opacity(0.45)), lineWidth: 0.6)
        }
        // your day, in gold, tied to you by a dashed line
        let mc = centre(mine)
        bpGuide(&c, BP.pt(86, 100), BP.pt(mc.x - 6, mc.y + 1), p: BP.pr(t, 0.4, 0.9), color: acc.opacity(0.8))
        bpGroup(&c, alpha: BP.pr(t, 0.3, 0.7)) { g in
            g.fill(Path(CGRect(x: mc.x - 3.2, y: mc.y - 3.2, width: 6.4, height: 6.4)), with: .color(acc))
            g.stroke(Path(roundedRect: CGRect(x: mc.x - 6, y: mc.y - 6, width: 12, height: 12), cornerRadius: 2), with: .color(acc), lineWidth: BP.edge)
        }

        // you, in gold, with a party hat
        bpGroup(&c, alpha: a0) { g in
            g.translateBy(x: 62, y: 118)
            bpPerson(&g, base: BP.pt(0, 0), facing: 0, ink: acc, shirt: 0.3, hair: 1, talk: false)
            var h = Path(); h.move(to: BP.pt(1.5, -64)); h.addLine(to: BP.pt(8, -44)); h.addLine(to: BP.pt(-6, -44)); h.closeSubpath()
            g.fill(h, with: .color(BP.paper)); g.fill(h, with: .color(acc.opacity(0.4)))
            g.stroke(h, with: .color(acc), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
            bbDot(&g, BP.pt(1.5, -64), r: 2, color: acc)
        }
        bpText(&c, "YOU", BP.pt(62, 38), ink: acc, alpha: BP.pr(t, 0.2, 0.7))
        bpText(&c, "LESS THAN 6%", BP.pt(62, 168), ink: ink, alpha: BP.pr(t, 2.4, 3.1))

        // the 22 strangers, each sending a birthday to the calendar
        for i in 0..<22 {
            let x = 171 + (Double(i) - 10.5) * 11
            let s0 = 0.5 + 0.095 * Double(i)
            let lit = BP.pr(u, s0, s0 + 0.15)
            let appear = BP.pr(t, 0.05 + 0.02 * Double(i), 0.3 + 0.02 * Double(i))
            bbMini(&c, x, 246, ink: ink, alpha: appear * (0.5 + 0.5 * lit * fo), s: 0.75, tint: 0.1 + 0.1 * lit * fo)

            let fl = BP.pr(u, s0, s0 + 0.55)
            let from = BP.pt(x, 224), to = centre(cells[i])
            let ctrl = BP.pt((from.x + to.x) / 2, min(from.y, to.y) - 26)
            if fl > 0 && fl < 1 {
                let k = BP.eio(fl), m = 1 - k
                let q = BP.pt(m * m * from.x + 2 * m * k * ctrl.x + k * k * to.x, m * m * from.y + 2 * m * k * ctrl.y + k * k * to.y)
                bbDot(&c, q, r: 2.2, color: ink, alpha: fo)
            } else if fl >= 1 {
                let pop = BP.pr(u, s0 + 0.55, s0 + 0.85)
                bpGroup(&c, alpha: fo) { g in
                    g.fill(Path(CGRect(x: to.x - 2.8, y: to.y - 2.8, width: 5.6, height: 5.6)), with: .color(ink.opacity(0.95)))
                    if pop < 1 { g.stroke(Path(ellipseIn: CGRect(x: to.x - 3 - 5 * pop, y: to.y - 3 - 5 * pop, width: 6 + 10 * pop, height: 6 + 10 * pop)), with: .color(ink.opacity(0.7 * (1 - pop))), lineWidth: BP.hair) }
                }
            }
        }

        // a bracket under the strangers
        var br = Path()
        br.move(to: BP.pt(52, 252)); br.addLine(to: BP.pt(52, 257)); br.addLine(to: BP.pt(282, 257)); br.addLine(to: BP.pt(282, 252))
        bpTrace(&c, br, p: BP.pr(t, 0.3, 0.9), color: ink, width: BP.hair)
        bpText(&c, "22 STRANGERS", BP.pt(167, 272), ink: ink, alpha: BP.pr(t, 0.6, 1.1))
    }
}

// MARK: - Card 3: 23 people in a ring and every handshake between them

struct BirthBPPairs: View {
    let active: Bool
    private static let story = 3.7

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.5,
                       label: "23 small people in party hats stand in a ring. Handshake lines draw between them one at a time: first the 22 that include you, in gold, then all the others in chalk, while a counter in the middle climbs to 253 handshakes. Labels say: 23 people, handshakes, 22 include you.",
                       draw: { c, t, pal, clock in let (u, r) = bbCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u, r) }, size: bbSize)
    }

    private static let centre = BP.pt(171, 158)
    private static let radius = 92.0

    private static func spot(_ k: Int) -> CGPoint {
        let a = (90 + 360 * Double(k) / 23) * Double.pi / 180
        return BP.pt(centre.x + radius * cos(a), centre.y + radius * sin(a))
    }

    /// The 231 pairs that leave you out, in a scrambled order.
    private static let others: [(Int, Int)] = {
        var all: [(Int, Int)] = []
        for i in 1..<23 { for j in (i + 1)..<23 { all.append((i, j)) } }
        return all.sorted { bbHash($0.0, $0.1) < bbHash($1.0, $1.1) }
    }()

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))
        let fo = bbFade(u, story)

        // handshakes: yours first (gold), then the rest (chalk)
        bpGroup(&c, alpha: fo) { g in
            for (n, (i, j)) in others.enumerated() {
                let s0 = 1.8 + Double(n) / 231 * 1.6
                var l = Path(); l.move(to: spot(i)); l.addLine(to: spot(j))
                bpTrace(&g, l, p: BP.eout(BP.pr(u, s0, s0 + 0.2)), color: ink.opacity(0.3), width: 0.8)
            }
            for j in 1..<23 {
                let s0 = 0.4 + Double(j - 1) / 22 * 1.4
                var l = Path(); l.move(to: spot(0)); l.addLine(to: spot(j))
                bpTrace(&g, l, p: BP.eout(BP.pr(u, s0, s0 + 0.25)), color: acc, width: 1.1)
            }
        }
        var count = 0
        if u >= 0.4 { count += min(22, Int((u - 0.4) / 1.4 * 22) + 1) }
        if u >= 1.8 { count += min(231, Int((u - 1.8) / 1.6 * 231) + 1) }
        if u >= 3.4 { count = 253 }
        if fo < 1 { count = Int(Double(count) * fo) }

        // the people
        for k in 0..<23 {
            let p = spot(k), a = BP.pr(t, 0.03 + 0.012 * Double(k), 0.25 + 0.012 * Double(k))
            if k == 0 { bbMini(&c, p.x, p.y + 10, ink: acc, alpha: a, s: 1.15, tint: 0.3) }
            else { bbMini(&c, p.x, p.y + 9, ink: ink, alpha: a, s: 0.95, tint: 0.08 + 0.12 * bbHash(k, 5)) }
        }

        // the counter
        bpGroup(&c, alpha: a0) { g in
            let box = Path(roundedRect: CGRect(x: centre.x - 42, y: centre.y - 25, width: 84, height: 50), cornerRadius: 4)
            g.fill(box, with: .color(BP.paper)); g.fill(box, with: .color(ink.opacity(0.07)))
            g.stroke(box, with: .color(ink), lineWidth: BP.edge)
        }
        bbNum(&c, "\(count)", BP.pt(centre.x, centre.y - 6), ink: ink, alpha: a0, size: 24)
        bpText(&c, "HANDSHAKES", BP.pt(centre.x, centre.y + 14), ink: ink, alpha: BP.pr(t, 0.2, 0.7))

        bpLeader(&c, anchor: BP.pt(105, 77), elbow: BP.pt(60, 48), tail: 10, text: "23 PEOPLE", ink: ink, p: BP.pr(t, 0.3, 0.9))
        bpLeader(&c, anchor: BP.pt(161, 253), elbow: BP.pt(96, 284), tail: 10, text: "22 INCLUDE YOU", ink: acc, p: BP.pr(t, 0.6, 1.2))
    }
}

// MARK: - Card 4: room after room of 23 dealt onto calendars; rooms with a match get a gold tick

struct BirthBPRooms: View {
    let active: Bool
    private static let story = 3.7

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.4,
                       label: "Room after room of 23 people is dealt out as small calendar cards, 24 in a grid. Each room that has a match gets a gold tick, each room without one gets a chalk cross. A bar of gold ticks settles near half. Labels say: 253 pairs, about 50%.",
                       draw: { c, t, pal, clock in let (u, r) = bbCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u, r) }, size: bbSize)
    }

    private static let gx = 42.0, gy = 54.0
    /// 12 of the 24 rooms have a match, scattered so the running share wanders and then settles at a half.
    private static let verdict: [Int] = [1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1]

    /// For each room, which of the 60 calendar cells hold a birthday (23 of them); a room with a match repeats a cell.
    private static let rooms: [(cells: [Int], dup: Int?)] = {
        (0..<24).map { r in
            var used = Set<Int>(), out: [Int] = []
            for k in 0..<23 {
                var q = Int(bbHash(r * 31 + 5, k) * 60) % 60
                while used.contains(q) { q = (q + 1) % 60 }
                used.insert(q); out.append(q)
            }
            return (out, verdict[r] == 1 ? out[0] : nil)
        }
    }()

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let fo = bbFade(u, story)
        var ticks = 0, done = 0

        for r in 0..<24 {
            let col = r % 6, row = r / 6
            let x = gx + Double(col) * 44, y = gy + Double(row) * 50
            let d0 = 0.3 + 0.115 * Double(r)
            let k = BP.eout(BP.pr(u, d0, d0 + 0.25))
            let ox = (1 - k) * -22, oy = (1 - k) * -12
            let m0 = d0 + 0.3
            let mark = BP.pr(u, m0, m0 + 0.12)
            if u >= m0 { done += 1; ticks += verdict[r] }
            guard k > 0.01 else { continue }
            bpGroup(&c, alpha: k * fo) { g in
                g.translateBy(x: x + ox, y: y + oy)
                let card = Path(roundedRect: CGRect(x: 0, y: 0, width: 38, height: 30), cornerRadius: 2.5)
                g.fill(card, with: .color(BP.paper)); g.fill(card, with: .color(ink.opacity(0.07)))
                g.stroke(card, with: .color(ink), lineWidth: BP.hair)
                g.fill(Path(CGRect(x: 0.5, y: 0.5, width: 37, height: 5)), with: .color(ink.opacity(0.28)))
                let (cells, dup) = rooms[r]
                var plain = Path(), marked = Path()
                for q in 0..<60 {
                    let px = 4.2 + Double(q % 10) * 3.4, py = 10.5 + Double(q / 10) * 3.4
                    let on = cells.contains(q)
                    let rr = on ? 1.1 : 0.5
                    let e = CGRect(x: px - rr, y: py - rr, width: 2 * rr, height: 2 * rr)
                    if on { marked.addEllipse(in: e) } else { plain.addEllipse(in: e) }
                }
                g.fill(plain, with: .color(ink.opacity(0.3)))
                g.fill(marked, with: .color(ink.opacity(0.95)))
                if let q = dup {
                    let px = 4.2 + Double(q % 10) * 3.4, py = 10.5 + Double(q / 10) * 3.4
                    g.stroke(Path(ellipseIn: CGRect(x: px - 2.6, y: py - 2.6, width: 5.2, height: 5.2)), with: .color(acc), lineWidth: BP.hair)
                    g.fill(Path(ellipseIn: CGRect(x: px - 1.5, y: py - 1.5, width: 3, height: 3)), with: .color(acc))
                }
            }
            // the verdict under the card
            if mark > 0.01 {
                bpGroup(&c, alpha: mark * fo) { g in
                    let mx = x + 19, my = y + 41
                    var p = Path()
                    if verdict[r] == 1 {
                        p.move(to: BP.pt(mx - 4.5, my)); p.addLine(to: BP.pt(mx - 1.5, my + 3.5)); p.addLine(to: BP.pt(mx + 4.5, my - 4))
                        g.stroke(p, with: .color(acc), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    } else {
                        p.move(to: BP.pt(mx - 3.2, my - 3.2)); p.addLine(to: BP.pt(mx + 3.2, my + 3.2))
                        p.move(to: BP.pt(mx + 3.2, my - 3.2)); p.addLine(to: BP.pt(mx - 3.2, my + 3.2))
                        g.stroke(p, with: .color(ink.opacity(0.85)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                    }
                }
            }
        }

        // the tally of ticks: share of rooms so far, settling at about half
        let share = done > 0 ? Double(ticks) / Double(done) : 0
        let bar = CGRect(x: 40, y: 268, width: 150, height: 9)
        bpGroup(&c, alpha: BP.eout(BP.pr(t, 0, 0.4))) { g in
            g.fill(Path(bar), with: .color(ink.opacity(0.07)))
            g.fill(Path(CGRect(x: bar.minX, y: bar.minY, width: bar.width * share * fo, height: bar.height)), with: .color(acc.opacity(0.85)))
            g.stroke(Path(bar), with: .color(ink), lineWidth: BP.hair)
            var half = Path(); half.move(to: BP.pt(bar.midX, bar.minY - 3)); half.addLine(to: BP.pt(bar.midX, bar.maxY + 3))
            g.stroke(half, with: .color(ink.opacity(0.8)), lineWidth: BP.hair)
        }
        bpText(&c, "ABOUT 50%", BP.pt(200, 272.5), ink: acc, alpha: BP.pr(t, 3.1, 3.7), anchor: .leading)
        bpLeader(&c, anchor: BP.pt(61, 54), elbow: BP.pt(49, 30), tail: 10, text: "253 PAIRS", ink: ink, p: BP.pr(t, 0.2, 0.8))
    }
}

// MARK: - Card 5: people walk in one by one; people, pairs and chance climb together

struct BirthBPCurve: View {
    let active: Bool
    private static let story = 3.6

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.3,
                       label: "People walk one by one into a room until 57 have arrived, and each new person makes a few new lines to those already there. Three counters climb together: people, pairs, and chance, shown as a gold bar. At the end they read 57 people, 1,596 pairs, over 99%.",
                       draw: { c, t, pal, clock in let (u, r) = bbCycle(t, clock, story: Self.story); Self.draw(&c, t, pal, u, r) }, size: bbSize)
    }

    private static func slot(_ k: Int) -> CGPoint { BP.pt(56 + Double(k % 12) * 22, 82 + Double(k / 12) * 29) }

    private static func chance(_ n: Int) -> Double {
        var p = 1.0
        for i in 0..<max(0, n) { p *= Double(365 - i) / 365 }
        return 1 - p
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ u: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let a0 = BP.eout(BP.pr(t, 0, 0.4))
        let fo = bbFade(u, story)

        // the room, with a door on the left
        bpGroup(&c, alpha: a0) { g in
            var wall = Path()
            wall.move(to: BP.pt(36, 150)); wall.addLine(to: BP.pt(36, 44)); wall.addLine(to: BP.pt(306, 44)); wall.addLine(to: BP.pt(306, 206)); wall.addLine(to: BP.pt(36, 206)); wall.addLine(to: BP.pt(36, 188))
            g.fill(Path(CGRect(x: 36, y: 44, width: 270, height: 162)), with: .color(ink.opacity(0.04)))
            g.stroke(wall, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        }

        let x = 57 * BP.eio(BP.pr(u, 0.3, 3.3))
        let n = min(57, Int(x)), f = n >= 57 ? 1.0 : x - Double(n)

        // pair lines for the person arriving now, and the people already inside
        if n < 57, n > 0 {
            let to = slot(n)
            var l = Path()
            for m in 0..<min(n, 8) {
                let j = Int(bbHash(n, m) * Double(n)) % n
                let q = slot(j)
                l.move(to: BP.pt(to.x, to.y - 9)); l.addLine(to: BP.pt(q.x, q.y - 9))
            }
            bpGroup(&c, alpha: fo) { g in g.stroke(l, with: .color(ink.opacity(0.5 * (1 - 0.6 * f))), lineWidth: BP.hair) }
        }
        for k in 0..<57 {
            let p = slot(k)
            if k < n { bbMini(&c, p.x, p.y, ink: ink, alpha: a0 * fo, s: 0.8, tint: 0.08 + 0.12 * bbHash(k, 2)) }
            else if k == n && n < 57 {
                let w = BP.eout(f)
                bbMini(&c, p.x - 22 * (1 - w), p.y, ink: ink, alpha: w * a0 * fo, s: 0.8, tint: 0.08 + 0.12 * bbHash(k, 2))
            }
        }

        // counters
        let people = n, pairs = n * (n - 1) / 2, q = chance(n)
        let pct = n >= 57 ? "OVER 99%" : "\(Int(q * 100))%"
        bpText(&c, "PEOPLE", BP.pt(24, 226), ink: ink, alpha: BP.pr(t, 0.2, 0.7), anchor: .leading)
        bpText(&c, "PAIRS", BP.pt(24, 250), ink: ink, alpha: BP.pr(t, 0.3, 0.8), anchor: .leading)
        bpText(&c, "CHANCE", BP.pt(24, 274), ink: ink, alpha: BP.pr(t, 0.4, 0.9), anchor: .leading)
        bbNum(&c, "\(people)", BP.pt(100, 225), ink: ink, alpha: a0 * fo, anchor: .leading)
        let big = pairs >= 1000 ? "\(pairs / 1000),\(String(format: "%03d", pairs % 1000))" : "\(pairs)"
        bbNum(&c, big, BP.pt(100, 249), ink: ink, alpha: a0 * fo, anchor: .leading)
        let bar = CGRect(x: 100, y: 270, width: 114, height: 9)
        bpGroup(&c, alpha: a0) { g in
            g.fill(Path(bar), with: .color(ink.opacity(0.07)))
            g.fill(Path(CGRect(x: bar.minX, y: bar.minY, width: bar.width * q * fo, height: bar.height)), with: .color(acc.opacity(0.9)))
            g.stroke(Path(bar), with: .color(ink), lineWidth: BP.hair)
        }
        bpText(&c, pct, BP.pt(224, 274.5), ink: acc, alpha: a0 * fo, anchor: .leading)
    }
}
