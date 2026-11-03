import SwiftUI

// "In a room of 23, what's the chance two share a birthday?" pictures in the drafting style (2026-11-03): white paper, crisp black outlines,
// small realistic line people in party hats (`DR.person`), light hatching for shade and ONE yellow accent for the thing that matters (the dial's
// needle, you, your handshakes, the matching rooms, the chance bar). Labels are the slide's own words. On a swipeable card each picture
// loops; narrated it plays once with the voice and holds. Drawn in the default 343 x 320 design space, clear of the bottom-right corner
// (x > 288, y > 235).

private func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

// MARK: - Card 1: a room of 23, and a dial that guesses low then swings to about 50%

struct BirthDRRoom: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 2.7

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 2.3,
                       label: "A line drawing on white: a room of 23 small people in party hats, standing in two rows. Above them a dial reads chance. Its gold needle first sits low, the small guess, then swings up to about 50 percent and holds. Labels say: 23 people, chance, about 50%.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let centre = pt(171, 150)
    private static let radius = 82.0

    private static func onDial(_ f: Double, _ r: Double) -> CGPoint {
        let a = Double.pi + Double.pi * f
        return pt(centre.x + r * cos(a), centre.y + r * sin(a))
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        let on = BP.pr(u, 0, 0.7), fill = BP.pr(u, 0.15, 0.6)

        // the dial: a half-round gauge with a thick rim, ticks every 5%, and a hub
        var face = Path()
        face.move(to: pt(centre.x - radius, centre.y))
        for i in 0...48 { face.addLine(to: onDial(Double(i) / 48, radius)) }
        face.closeSubpath()
        var fg = c; fg.opacity = fill
        fg.fill(face, with: .color(DR.face))
        var ring = Path()
        for i in 0...48 { let q = onDial(Double(i) / 48, radius - 7); if i == 0 { ring.move(to: q) } else { ring.addLine(to: q) } }
        DR.draw(&c, ring, p: on, width: DR.hair + 0.1, color: DR.ink.opacity(0.7))
        for i in 0..<48 {                                                  // the rim shaded with short hatching
            guard Double(i) / 48 < on else { break }
            var h = Path(); h.move(to: onDial(Double(i) / 48, radius - 1)); h.addLine(to: onDial(Double(i) / 48 + 0.006, radius - 6))
            fg.stroke(h, with: .color(DR.ink.opacity(0.35)), lineWidth: DR.hair)
        }
        DR.draw(&c, face, p: on, width: DR.line + 0.2)
        var ticks = Path()
        for k in 0...20 {
            let f = Double(k) / 20, len = k % 5 == 0 ? 12.0 : 5.0
            ticks.move(to: onDial(f, radius - 9)); ticks.addLine(to: onDial(f, radius - 9 - len))
        }
        DR.draw(&c, ticks, p: BP.pr(u, 0.1, 0.8), width: DR.hair + 0.1, color: DR.ink.opacity(0.85))
        for (f, s) in [(0.0, "0"), (0.5, "50"), (1.0, "100")] {
            let q = onDial(f, radius - 28)
            var tg = c; tg.opacity = BP.pr(u, 0.4, 0.9)
            tg.draw(tg.resolve(Text(s).font(.system(size: 8, weight: .semibold, design: .rounded)).foregroundColor(DR.ink.opacity(0.7))), at: pt(q.x, q.y + (f == 0.5 ? 2 : -1)), anchor: .center)
        }

        // the needle: a low guess, a swing up to 50%, a hold
        let swing = BP.eio(BP.pr(u, 0.9, 2.3))
        let after = u - 2.3
        let wobble = after > 0 ? 0.014 * exp(-after * 5) * sin(after * 16) : 0
        let jitter = 0.01 * sin(u * 7) * (1 - BP.pr(u, 0.7, 1.0))
        let f = 0.10 + 0.40 * swing + wobble + jitter
        var ng = c; ng.opacity = on
        let tip = onDial(f, radius - 14), a = Double.pi + Double.pi * f
        let side = pt(-sin(a), cos(a))
        var needle = Path()
        needle.move(to: pt(centre.x + side.x * 3.2, centre.y + side.y * 3.2)); needle.addLine(to: tip)
        needle.addLine(to: pt(centre.x - side.x * 3.2, centre.y - side.y * 3.2)); needle.closeSubpath()
        ng.fill(needle, with: .color(DR.accent))
        ng.stroke(needle, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
        let hub = Path(ellipseIn: CGRect(x: centre.x - 6, y: centre.y - 6, width: 12, height: 12))
        ng.fill(hub, with: .color(DR.face)); ng.stroke(hub, with: .color(DR.ink), lineWidth: DR.line)
        ng.fill(Path(ellipseIn: CGRect(x: centre.x - 1.6, y: centre.y - 1.6, width: 3.2, height: 3.2)), with: .color(DR.ink))

        // the room: 12 + 11 people in two rows
        for i in 0..<23 {
            let row = i < 12 ? 0 : 1, k = row == 0 ? i : i - 12
            let x = row == 0 ? 171 + (Double(k) - 5.5) * 20 : 171 + (Double(k) - 5) * 20
            let d = BP.pr(u, 0.05 + 0.014 * Double(i), 0.3 + 0.014 * Double(i))
            DR.person(&c, x: x, feet: row == 0 ? 224 : 254, s: 0.5, variant: (i * 7 + row) % 3 == 0 ? 1 : 0, on: d, alpha: d)
        }

        DR.label(&c, "23 PEOPLE", anchor: pt(66, 214), at: pt(24, 176), align: .leading, p: BP.pr(u, 0.3, 0.9))
        DR.label(&c, "CHANCE", anchor: pt(centre.x + 40, centre.y - 22), at: pt(250, 172), align: .leading, p: BP.pr(u, 0.2, 0.8))
        DR.label(&c, "ABOUT 50%", anchor: onDial(0.5, radius + 1), at: pt(centre.x + 34, 40), align: .leading, p: BP.pr(u, 1.8, 2.4))
    }
}

private func hash(_ a: Int, _ b: Int) -> Double {
    let v = sin(Double(a) * 12.9898 + Double(b) * 78.233) * 43758.5453
    return abs(v - v.rounded(.down))
}

private func dot(_ c: inout GraphicsContext, _ at: CGPoint, r: Double, color: Color = DR.ink, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    c.fill(Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(alpha)))
}

/// Plain rounded text in the drafting look, for counters.
private func word(_ c: inout GraphicsContext, _ s: String, _ at: CGPoint, size: CGFloat = 15, weight: Font.Weight = .semibold, alpha: Double = 1, anchor: UnitPoint = .leading, tracking: CGFloat = 0.4) {
    guard alpha > 0.01 else { return }
    c.draw(c.resolve(Text(s).font(.system(size: size, weight: weight, design: .rounded)).tracking(tracking).foregroundColor(DR.ink.opacity(alpha))), at: at, anchor: anchor)
}

// MARK: - Card 2: you in gold, and 22 strangers each dropping a birthday on a year calendar

struct BirthDRYours: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 4.3

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 4.1,
                       label: "A line drawing on white: you, in a gold party hat, next to a calendar grid of the year with your birthday marked in gold. Below, a row of 22 strangers in party hats each drops a birthday onto the calendar, one after another, and none lands on your day. Labels say: you, 22 strangers, less than 6%.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let gx = 140.0, gy = 44.0, cell = 7.0, cols = 19
    private static let mine = 99
    private static let cells: [Int] = {
        var used: Set<Int> = [mine]
        var out: [Int] = []
        for i in 0..<22 {
            var k = Int(hash(i, 7) * 365) % 365
            while used.contains(k) { k = (k + 1) % 365 }
            used.insert(k); out.append(k)
        }
        return out
    }()

    private static func centre(_ idx: Int) -> CGPoint {
        pt(gx + Double(idx % cols) * cell + cell / 2, gy + Double(idx / cols) * cell + cell / 2)
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        let on = BP.pr(u, 0, 0.7), fill = BP.pr(u, 0.15, 0.6)

        // the calendar page: rings along the top, a grid of 365 days
        let frame = Path(roundedRect: CGRect(x: gx - 6, y: gy - 6, width: 19 * cell + 12, height: 20 * cell + 12), cornerRadius: 4)
        var fg = c; fg.opacity = fill
        fg.fill(frame, with: .color(DR.face))
        var days = Path()
        for i in 0..<365 { days.addRect(CGRect(x: gx + Double(i % cols) * cell + 0.8, y: gy + Double(i / cols) * cell + 0.8, width: cell - 1.6, height: cell - 1.6)) }
        fg.stroke(days, with: .color(DR.ink.opacity(0.38)), lineWidth: 0.5)
        DR.draw(&c, frame, p: on, width: DR.line + 0.1)
        for k in 0..<5 {
            let x = gx + 12 + Double(k) * 27
            DR.draw(&c, Path(roundedRect: CGRect(x: x - 2, y: gy - 11, width: 4, height: 9), cornerRadius: 2), p: on, width: DR.hair + 0.2)
        }

        // your day, in gold, tied to you by a dashed line
        let mc = centre(mine)
        var tie = Path(); tie.move(to: pt(92, 100)); tie.addLine(to: pt(mc.x - 7, mc.y + 1))
        DR.draw(&c, tie, p: BP.pr(u, 0.4, 0.9), width: DR.hair, color: DR.ink.opacity(0.7), dash: [3, 3])
        var mg = c; mg.opacity = BP.pr(u, 0.3, 0.7)
        let day = Path(roundedRect: CGRect(x: mc.x - 5, y: mc.y - 5, width: 10, height: 10), cornerRadius: 2)
        mg.fill(day, with: .color(DR.accent)); mg.stroke(day, with: .color(DR.ink), lineWidth: DR.line)

        // you, with a gold hat
        DR.person(&c, x: 62, feet: 140, s: 1.0, variant: 0, gold: true, on: on, alpha: on)
        DR.label(&c, "YOU", anchor: pt(62, 78), at: pt(62, 46), align: .center, p: BP.pr(u, 0.2, 0.7))
        word(&c, "LESS THAN 6%", pt(62, 176), size: 10, alpha: BP.pr(u, 3.6, 4.3), anchor: .center, tracking: 0.6)

        // the 22 strangers, each sending a birthday to the calendar
        for i in 0..<22 {
            let x = 171 + (Double(i) - 10.5) * 11
            let s0 = 1.9 + 0.075 * Double(i)
            let lit = BP.pr(u, s0, s0 + 0.15)
            let appear = BP.pr(u, 1.0 + 0.02 * Double(i), 1.3 + 0.02 * Double(i))
            DR.person(&c, x: x, feet: 258, s: 0.4, variant: i % 3 == 0 ? 1 : 0, on: appear, alpha: appear * (0.55 + 0.45 * lit))

            let fl = BP.pr(u, s0, s0 + 0.55)
            let from = pt(x, 226), to = centre(cells[i])
            let ctrl = pt((from.x + to.x) / 2, min(from.y, to.y) - 26)
            if fl > 0 && fl < 1 {
                let k = BP.eio(fl), m = 1 - k
                dot(&c, pt(m * m * from.x + 2 * m * k * ctrl.x + k * k * to.x, m * m * from.y + 2 * m * k * ctrl.y + k * k * to.y), r: 2.2)
            } else if fl >= 1 {
                let pop = BP.pr(u, s0 + 0.55, s0 + 0.85)
                c.fill(Path(CGRect(x: to.x - 2.6, y: to.y - 2.6, width: 5.2, height: 5.2)), with: .color(DR.ink.opacity(0.85)))
                if pop < 1 { c.stroke(Path(ellipseIn: CGRect(x: to.x - 3 - 5 * pop, y: to.y - 3 - 5 * pop, width: 6 + 10 * pop, height: 6 + 10 * pop)), with: .color(DR.ink.opacity(0.6 * (1 - pop))), lineWidth: DR.hair) }
            }
        }

        // a bracket under the strangers
        var br = Path()
        br.move(to: pt(48, 266)); br.addLine(to: pt(48, 271)); br.addLine(to: pt(294, 271)); br.addLine(to: pt(294, 266))
        DR.draw(&c, br, p: BP.pr(u, 1.0, 1.6), width: DR.hair + 0.1)
        word(&c, "22 STRANGERS", pt(171, 284), size: 8.5, alpha: BP.pr(u, 1.2, 1.7), anchor: .center, tracking: 0.6)
    }
}

// MARK: - Card 3: 23 people in a ring and every handshake between them

struct BirthDRPairs: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 4.3

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 4.05,
                       label: "A line drawing on white: 23 small people in party hats stand in a ring. Handshake lines draw between them one at a time: every handshake draws in thin black while a counter in the middle climbs to 253, then the 22 that include you light up in gold. Labels say: 23 people, handshakes, 22 include you.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let centre = pt(171, 158)
    private static let radius = 92.0

    private static func spot(_ k: Int) -> CGPoint {
        let a = (90 + 360 * Double(k) / 23) * Double.pi / 180
        return pt(centre.x + radius * cos(a), centre.y + radius * sin(a))
    }

    private static let pairs: [(Int, Int)] = {
        var all: [(Int, Int)] = []
        for i in 0..<23 { for j in (i + 1)..<23 { all.append((i, j)) } }
        return all.sorted { hash($0.0, $0.1) < hash($1.0, $1.1) }
    }()

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        let on = BP.pr(u, 0, 0.6)

        // all 253 handshakes in thin black while the counter climbs, then the 22 that include you in gold
        var all = Path()
        for (n, (i, j)) in pairs.enumerated() {
            let s0 = 1.2 + Double(n) / 253 * 1.4
            let p = BP.eout(BP.pr(u, s0, s0 + 0.2))
            guard p > 0 else { continue }
            all.move(to: spot(i)); all.addLine(to: BP.mixp(spot(i), spot(j), p))
        }
        c.stroke(all, with: .color(DR.ink.opacity(0.32)), lineWidth: 0.5)
        for j in 1..<23 {
            let s0 = 3.1 + Double(j - 1) / 22 * 0.7
            let p = BP.eout(BP.pr(u, s0, s0 + 0.25))
            guard p > 0 else { continue }
            var l = Path(); l.move(to: spot(0)); l.addLine(to: BP.mixp(spot(0), spot(j), p))
            c.stroke(l, with: .color(DR.ink), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            c.stroke(l, with: .color(DR.accent), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        let count = u < 1.2 ? 0 : u >= 2.8 ? 253 : min(253, Int((u - 1.2) / 1.6 * 253) + 1)

        // the people stand over the lines' ends
        for k in 0..<23 {
            let p = spot(k), a = BP.pr(u, 0.03 + 0.012 * Double(k), 0.25 + 0.012 * Double(k))
            if a > 0.01 {
                var back = c; back.opacity = a
                back.fill(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y - 14, width: 14, height: 24)), with: .color(DR.face))
            }
            DR.person(&c, x: p.x, feet: p.y + 11, s: k == 0 ? 0.46 : 0.4, variant: k % 3 == 0 ? 1 : 0, gold: k == 0, on: a, alpha: a)
        }

        // the counter
        let box = Path(roundedRect: CGRect(x: centre.x - 42, y: centre.y - 25, width: 84, height: 50), cornerRadius: 6)
        var bg = c; bg.opacity = on
        bg.fill(box, with: .color(DR.face)); bg.stroke(box, with: .color(DR.ink), lineWidth: DR.line + 0.1)
        word(&c, "\(count)", pt(centre.x, centre.y - 6), size: 24, alpha: on, anchor: .center, tracking: 0)
        word(&c, "HANDSHAKES", pt(centre.x, centre.y + 14), size: 8.5, alpha: BP.pr(u, 1.2, 1.7), anchor: .center, tracking: 0.6)

        DR.label(&c, "23 PEOPLE", anchor: pt(112, 78), at: pt(36, 44), align: .leading, p: BP.pr(u, 0.3, 0.9))
        DR.label(&c, "22 INCLUDE YOU", anchor: pt(164, 254), at: pt(60, 288), align: .leading, p: BP.pr(u, 3.0, 3.5))
    }
}

// MARK: - Card 4: room after room of 23 dealt onto calendars; rooms with a match get a gold tick

struct BirthDRRooms: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 3.7

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 3.4,
                       label: "A line drawing on white: room after room of 23 people is dealt out as small calendar cards, 24 in a grid. Each room that has a match gets a gold tick, each room without one gets a black cross. A bar of gold settles near half. Labels say: 253 pairs, about 50%.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let gx = 42.0, gy = 54.0
    private static let verdict: [Int] = [1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1]
    private static let rooms: [(cells: [Int], dup: Int?)] = {
        (0..<24).map { r in
            var used = Set<Int>(), out: [Int] = []
            for k in 0..<23 {
                var q = Int(hash(r * 31 + 5, k) * 60) % 60
                while used.contains(q) { q = (q + 1) % 60 }
                used.insert(q); out.append(q)
            }
            return (out, verdict[r] == 1 ? out[0] : nil)
        }
    }()

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
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
            var g = c
            g.opacity = k
            g.translateBy(x: x + ox, y: y + oy)
            let card = Path(roundedRect: CGRect(x: 0, y: 0, width: 38, height: 30), cornerRadius: 3)
            g.fill(card, with: .color(DR.face))
            let band = Path(CGRect(x: 0, y: 0, width: 38, height: 6))
            var bg = g; bg.clip(to: card)
            bg.fill(band, with: .color(DR.side)); DR.hatch(&bg, band, in: band.boundingRect, spacing: 2.2, alpha: 0.45)
            g.stroke(card, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
            let (cells, dup) = rooms[r]
            var plain = Path(), marked = Path()
            for q in 0..<60 {
                let px = 4.2 + Double(q % 10) * 3.4, py = 10.5 + Double(q / 10) * 3.4
                let rr = cells.contains(q) ? 1.2 : 0.45
                let e = CGRect(x: px - rr, y: py - rr, width: 2 * rr, height: 2 * rr)
                if cells.contains(q) { marked.addEllipse(in: e) } else { plain.addEllipse(in: e) }
            }
            g.fill(plain, with: .color(DR.ink.opacity(0.3)))
            g.fill(marked, with: .color(DR.ink.opacity(0.85)))
            if let q = dup {
                let px = 4.2 + Double(q % 10) * 3.4, py = 10.5 + Double(q / 10) * 3.4
                let ring = Path(ellipseIn: CGRect(x: px - 3, y: py - 3, width: 6, height: 6))
                g.fill(ring, with: .color(DR.accent)); g.stroke(ring, with: .color(DR.ink), lineWidth: DR.hair + 0.1)
                g.fill(Path(ellipseIn: CGRect(x: px - 1.2, y: py - 1.2, width: 2.4, height: 2.4)), with: .color(DR.ink))
            }
            // the verdict under the card
            if mark > 0.01 {
                var vg = c; vg.opacity = mark
                let mx = x + 19, my = y + 41
                var p = Path()
                if verdict[r] == 1 {
                    p.move(to: pt(mx - 5, my)); p.addLine(to: pt(mx - 1.5, my + 4)); p.addLine(to: pt(mx + 5, my - 4.5))
                    vg.stroke(p, with: .color(DR.ink), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    vg.stroke(p, with: .color(DR.accent), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                } else {
                    p.move(to: pt(mx - 3.2, my - 3.2)); p.addLine(to: pt(mx + 3.2, my + 3.2))
                    p.move(to: pt(mx + 3.2, my - 3.2)); p.addLine(to: pt(mx - 3.2, my + 3.2))
                    vg.stroke(p, with: .color(DR.ink.opacity(0.85)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                }
            }
        }

        // the tally: share of rooms with a match so far, settling at about half
        let share = done > 0 ? Double(ticks) / Double(done) : 0
        let bar = CGRect(x: 40, y: 268, width: 150, height: 11)
        var bg = c; bg.opacity = BP.pr(u, 0, 0.4)
        let track = Path(roundedRect: bar, cornerRadius: 3)
        bg.fill(track, with: .color(DR.face))
        let fillR = CGRect(x: bar.minX + 1, y: bar.minY + 1, width: max(0, (bar.width - 2) * share), height: bar.height - 2)
        if fillR.width > 1 {
            let f = Path(roundedRect: fillR, cornerRadius: 2)
            bg.fill(f, with: .color(DR.accent)); bg.stroke(f, with: .color(DR.ink), lineWidth: DR.hair + 0.1)
        }
        bg.stroke(track, with: .color(DR.ink), lineWidth: DR.line)
        var half = Path(); half.move(to: pt(bar.midX, bar.minY - 3)); half.addLine(to: pt(bar.midX, bar.maxY + 3))
        bg.stroke(half, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.hair, dash: [2, 2]))
        word(&c, "ABOUT 50%", pt(200, 273.5), size: 9, alpha: BP.pr(u, 3.1, 3.7), tracking: 0.6)
        DR.label(&c, "253 PAIRS", anchor: pt(61, 54), at: pt(52, 30), align: .leading, p: BP.pr(u, 0.0, 0.3))
    }
}

// MARK: - Card 5: people walk in one by one; people, pairs and chance climb together

struct BirthDRCurve: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 3.6

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 3.3,
                       label: "A line drawing on white: people walk one by one through a door into a room until 57 have arrived, and each new person makes a few new lines to those already there. Three counters climb together: people, pairs, and chance, shown as a gold bar. At the end they read 57 people, 1,596 pairs, over 99%.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static func slot(_ k: Int) -> CGPoint { pt(56 + Double(k % 12) * 22, 84 + Double(k / 12) * 29) }

    private static func chance(_ n: Int) -> Double {
        var p = 1.0
        for i in 0..<max(0, n) { p *= Double(365 - i) / 365 }
        return 1 - p
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        let on = BP.pr(u, 0, 0.5)

        // the room, with a door gap on the left
        var wall = Path()
        wall.move(to: pt(36, 150)); wall.addLine(to: pt(36, 44)); wall.addLine(to: pt(306, 44)); wall.addLine(to: pt(306, 206)); wall.addLine(to: pt(36, 206)); wall.addLine(to: pt(36, 188))
        var rg = c; rg.opacity = on
        rg.fill(Path(CGRect(x: 36, y: 44, width: 270, height: 162)), with: .color(DR.face))
        DR.hatch(&rg, Path(CGRect(x: 36, y: 44, width: 270, height: 5)), in: CGRect(x: 36, y: 44, width: 270, height: 5), spacing: 3, alpha: 0.4)
        DR.draw(&c, wall, p: on, width: DR.line + 0.4)

        let x = 57 * BP.eio(BP.pr(u, 0.9, 3.3))
        let n = min(57, Int(x)), f = n >= 57 ? 1.0 : x - Double(n)

        // lines to the people already inside, from the person arriving now
        if n < 57, n > 0 {
            let to = slot(n)
            var l = Path()
            for m in 0..<min(n, 8) {
                let j = Int(hash(n, m) * Double(n)) % n
                let q = slot(j)
                l.move(to: pt(to.x, to.y - 10)); l.addLine(to: pt(q.x, q.y - 10))
            }
            c.stroke(l, with: .color(DR.ink.opacity(0.7 * (1 - 0.6 * f))), lineWidth: DR.hair)
            var gold = Path()
            if let first = l.currentPoint { gold.move(to: pt(to.x, to.y - 10)); gold.addLine(to: first) }
            c.stroke(gold, with: .color(DR.accent), lineWidth: 1.6)
        }
        for k in 0..<57 {
            let p = slot(k)
            if k < n { DR.person(&c, x: p.x, feet: p.y, s: 0.32, variant: k % 3 == 0 ? 1 : 0, on: on, alpha: on) }
            else if k == n && n < 57 {
                let w = BP.eout(f)
                DR.person(&c, x: p.x - 22 * (1 - w), feet: p.y, s: 0.32, variant: k % 3 == 0 ? 1 : 0, on: w, alpha: w)
            }
        }

        // counters
        let people = n, pairs = n * (n - 1) / 2, q = chance(n)
        let pct = n >= 57 ? "OVER 99%" : "\(Int(q * 100))%"
        word(&c, "PEOPLE", pt(24, 226), size: 8.5, alpha: BP.pr(u, 0.2, 0.7), tracking: 0.6)
        word(&c, "PAIRS", pt(24, 250), size: 8.5, alpha: BP.pr(u, 0.3, 0.8), tracking: 0.6)
        word(&c, "CHANCE", pt(24, 274), size: 8.5, alpha: BP.pr(u, 0.4, 0.9), tracking: 0.6)
        word(&c, "\(people)", pt(100, 225), alpha: on, tracking: 0)
        let big = pairs >= 1000 ? "\(pairs / 1000),\(String(format: "%03d", pairs % 1000))" : "\(pairs)"
        word(&c, big, pt(100, 249), alpha: on, tracking: 0)
        let bar = CGRect(x: 100, y: 268, width: 114, height: 11)
        var bg = c; bg.opacity = on
        let track = Path(roundedRect: bar, cornerRadius: 3)
        bg.fill(track, with: .color(DR.face))
        let fr = CGRect(x: bar.minX + 1, y: bar.minY + 1, width: max(0, (bar.width - 2) * q), height: bar.height - 2)
        if fr.width > 1 { let fp = Path(roundedRect: fr, cornerRadius: 2); bg.fill(fp, with: .color(DR.accent)); bg.stroke(fp, with: .color(DR.ink), lineWidth: DR.hair + 0.1) }
        bg.stroke(track, with: .color(DR.ink), lineWidth: DR.line)
        word(&c, pct, pt(224, 273.5), size: 10, alpha: on, tracking: 0.4)
    }
}
