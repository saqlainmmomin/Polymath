import SwiftUI

// "In a room of 23, what's the chance two share a birthday?" topic, five pictures in the hand-drawn style (Sketch.swift).
// Rebuilt 2026-10-27 from the approved copy in tasks/spine-birthday/slides.md. Paper background, boiling ink lines, handwritten words.
// Cards 1-4 play and loop by themselves; card 5 is the topic's one hands-on picture (drag to add people).

private func cl(_ x: Double) -> Double { min(1, max(0, x)) }
private func pr(_ t: Double, _ a: Double, _ b: Double) -> Double { cl((t - a) / (b - a)) }
private func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
private func mix(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }
private func backOut(_ x: Double) -> Double { let c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }

private enum BD {
    static let ink = Sketch.inkColor
    static let page = Color(hex: 0xFFFDF7)
    static let gold = Color(hex: 0xF4C64F), goldLine = Color(hex: 0xE59B00), goldText = Color(hex: 0xB36B00)
    static let red = Color(hex: 0xE5533D), green = Color(hex: 0x4E9A4C), grey = Color(hex: 0x6B6259)
    static let bodies: [Color] = [Color(hex: 0x4F9AD6), Color(hex: 0x7DBB6B), Color(hex: 0xB08AD8), Color(hex: 0xF28FB1), Color(hex: 0xF4A24A), Color(hex: 0x5BC0BE)]
    static let hats: [Color] = [Color(hex: 0xE5533D), Color(hex: 0xF4C64F), Color(hex: 0x5BC0BE), Color(hex: 0xB08AD8), Color(hex: 0xF28FB1)]
    static let skins: [Color] = [Color(hex: 0xF6D3B3), Color(hex: 0xE8B98F), Color(hex: 0xC98F66), Color(hex: 0x9A6A47)]
}

/// Chance that at least two of n people share a birthday (365 equal days).
private func shared(_ n: Int) -> Double {
    guard n > 1 else { return 0 }
    var q = 1.0
    for k in 0..<n { q *= (365.0 - Double(k)) / 365.0 }
    return 1 - q
}

private func word(_ ctx: inout GraphicsContext, _ s: String, _ p: CGPoint, _ size: Double, t: Double, seed: Int, color: Color = BD.ink,
                  alpha: Double = 1, anchor: UnitPoint = .center, marker: Bool = false, angle: Double = 0) {
    Sketch.say(&ctx, s, p, size: max(10, size), t: t, seed: seed, font: marker ? "MarkerFelt-Wide" : "Noteworthy-Bold",
               color: color, alpha: alpha, anchor: anchor, angle: angle)
}

/// Little cartoon emphasis dashes around a point.
private func rays(_ ctx: inout GraphicsContext, _ c: CGPoint, r0: Double, r1: Double, angles: [Double], t: Double, seed: Int, alpha: Double, color: Color = BD.ink) {
    guard alpha > 0.02 else { return }
    for (i, a) in angles.enumerated() {
        let rr = mix(r0, r1, alpha)
        Sketch.ink(&ctx, [CGPoint(x: c.x + r0 * cos(a), y: c.y + r0 * sin(a)), CGPoint(x: c.x + rr * cos(a), y: c.y + rr * sin(a))],
                   closed: false, t: t, seed: seed + i, width: 2, color: color.opacity(alpha))
    }
}

/// A hand-drawn person standing at `foot`, about 43 k tall with the hat. `wave` (radians of phase) raises an arm.
private func person(_ ctx: inout GraphicsContext, _ foot: CGPoint, _ k: Double, t: Double, seed: Int, body: Color, hat: Color?, skin: Color,
                    pen: Double = 1, alpha: Double = 1, wave: Double? = nil) {
    guard k > 0.05, alpha > 0.01 else { return }
    var l = ctx
    l.opacity = alpha
    func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: foot.x + x * k, y: foot.y + y * k) }
    let wd = max(1.3, min(2.4, 2 * k + 0.8))
    let fa = min(1, pen * 1.6)
    if let w = wave {
        let sway = 2.5 * sin(w)
        Sketch.ink(&l, [P(8, -12), P(13.5 + sway * 0.4, -19), P(14 + sway, -28)], closed: false, t: t, seed: seed + 9, width: wd, drawn: pen)
    }
    Sketch.ink(&l, [P(-9, 0), P(-9.5, -9), P(-6, -16), P(6, -16), P(9.5, -9), P(9, 0)], closed: true, t: t, seed: seed, width: wd,
               fill: body.opacity(fa), drawn: pen)
    Sketch.ink(&l, Sketch.oval(P(0, -24), 6.6 * k, 7 * k, n: 18), closed: true, t: t, seed: seed + 3, width: wd, fill: skin.opacity(fa), drawn: pen)
    if let h = hat {
        Sketch.ink(&l, [P(-5.5, -29.5), P(0, -43), P(5.5, -29.5)], closed: true, t: t, seed: seed + 5, width: wd, fill: h.opacity(fa), drawn: pen)
    }
    if pen > 0.9 && k > 0.3 {
        let r = max(0.7, 0.9 * k)
        for dx in [-2.4, 2.4] {
            let c = P(dx, -24.5)
            l.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(BD.ink))
        }
        if k > 0.9 {
            Sketch.ink(&l, [P(-2.6, -21.4), P(0, -19.6), P(2.6, -21.4)], closed: false, t: t, seed: seed + 6, width: 1.2)
        }
    }
}

private func skin(_ i: Int) -> Color { BD.skins[Int(Sketch.rnd(i * 5 + 1) * 4) % 4] }

/// A wall calendar with a red top strip and a faint grid of days.
private struct Cal {
    let rect: CGRect, cols: Int, rows: Int, head: Double
    var cw: Double { rect.width / Double(cols) }
    var ch: Double { (rect.height - head) / Double(rows) }
    func cell(_ i: Int) -> CGRect {
        CGRect(x: rect.minX + Double(i % cols) * cw, y: rect.minY + head + Double(i / cols) * ch, width: cw, height: ch)
    }
    func draw(_ ctx: inout GraphicsContext, t: Double, seed: Int, pen: Double) {
        let r = rect
        Sketch.ink(&ctx, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)],
                   closed: true, t: t, seed: seed, width: 2.2, fill: BD.page.opacity(min(1, pen * 1.5)), drawn: pen)
        Sketch.ink(&ctx, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.minY + head), CGPoint(x: r.minX, y: r.minY + head)],
                   closed: true, t: t, seed: seed + 1, width: 2, fill: BD.red.opacity(min(1, pen * 1.5)), drawn: pen)
        if pen > 0.5 {
            var g = Path()
            for c in 1..<cols { g.move(to: CGPoint(x: r.minX + Double(c) * cw, y: r.minY + head)); g.addLine(to: CGPoint(x: r.minX + Double(c) * cw, y: r.maxY)) }
            for q in 1..<rows { g.move(to: CGPoint(x: r.minX, y: r.minY + head + Double(q) * ch)); g.addLine(to: CGPoint(x: r.maxX, y: r.minY + head + Double(q) * ch)) }
            ctx.stroke(g, with: .color(BD.ink.opacity(0.17 * pen)), lineWidth: 0.6)
            for fx in [0.25, 0.75] {
                let c = CGPoint(x: r.minX + r.width * fx, y: r.minY + head * 0.5)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 2.5, y: c.y - 2.5, width: 5, height: 5)), with: .color(BD.page))
            }
        }
    }
}

private func fillCell(_ ctx: inout GraphicsContext, _ r: CGRect, _ color: Color, inset: Double = 0.8, alpha: Double = 1) {
    ctx.fill(Path(roundedRect: r.insetBy(dx: inset, dy: inset), cornerRadius: 1.5), with: .color(color.opacity(alpha)))
}

// MARK: - Card 1: a room of 23 in party hats; a dial first says your guess (low), then swings to about 50%

struct BirthRoom: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 9, still: 6.5, cues: [Cue(1.6, .soft), Cue(4.2, .rigid)], replayOnTap: true, sky: Sketch.paper,
                    label: "A hand-drawn room of 23 people in party hats. Above them a dial called chance. First its needle points low, labelled your guess. Then it swings up to the middle, labelled about 50 percent.") { ctx, s, t, _ in
            Self.draw(&ctx, s, t)
        }
    }

    private static func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ t: Double) {
        let w = s.width, h = s.height
        let u = min(w / 343, h / 320)
        ctx.opacity = 1 - pr(t, 8.4, 9)
        let pen = eio(pr(t, 0.1, 1.3))

        // the crowd: 8 + 7 + 8 people, back row first
        let counts = [8, 7, 8]
        let sp = min(36 * u, (w - 24 * u) / 8)
        let gap = min(34 * u, h * 0.115)
        let front = h - 30 * u
        var idx = 0
        for (r, c) in counts.enumerated() {
            let y = front - gap * Double(2 - r)
            for j in 0..<c {
                let x = w / 2 + (Double(j) - Double(c - 1) / 2) * sp
                let arrive = pr(t, 0.3 + Double(idx) * 0.045, 0.7 + Double(idx) * 0.045)
                let bounce = 1.6 * u * max(0, sin(t * 3.2 + Double(idx) * 1.3)) * pr(t, 1.4, 1.8)
                person(&ctx, CGPoint(x: x, y: y - bounce - (1 - arrive) * 10 * u), 0.85 * u, t: t, seed: 100 + idx * 11,
                       body: BD.bodies[idx % BD.bodies.count], hat: BD.hats[(idx * 2 + r) % BD.hats.count], skin: skin(idx), pen: arrive, alpha: arrive)
                idx += 1
            }
        }
        word(&ctx, "23 PEOPLE", CGPoint(x: w / 2, y: h - 5 * u), 13 * u, t: t, seed: 90, alpha: pr(t, 1.2, 1.6), anchor: .bottom)

        // the dial
        let r = 66 * u
        let cx = w / 2, cy = max(h * 0.40, r + 32 * u)
        func pt(_ p: Double, _ rad: Double) -> CGPoint { CGPoint(x: cx + rad * cos(.pi * (1 - p)), y: cy - rad * sin(.pi * (1 - p))) }
        var face = (0...24).map { pt(Double($0) / 24, r) }
        face.append(CGPoint(x: cx - r, y: cy))
        Sketch.ink(&ctx, face, closed: true, t: t, seed: 10, width: 2.4, fill: BD.page.opacity(min(1, pen * 1.5)), drawn: pen)
        let hot = pr(t, 4.7, 5.2)
        if hot > 0 {   // the middle of the dial lights up red
            let band = (0...6).map { pt(0.44 + Double($0) * 0.02, r - 6 * u) }
            Sketch.ink(&ctx, band, closed: false, t: t, seed: 12, width: 5 * u, color: BD.red.opacity(hot), amp: 0.5)
        }
        for p in [0.0, 0.25, 0.5, 0.75, 1.0] {
            Sketch.ink(&ctx, [pt(p, r - 3 * u), pt(p, r - 12 * u)], closed: false, t: t, seed: 20 + Int(p * 8), width: 1.8, drawn: pen)
        }
        word(&ctx, "CHANCE", CGPoint(x: cx, y: cy + 9 * u), 13 * u, t: t, seed: 30, alpha: pen, anchor: .top)

        // the needle: nervous and low (your guess), then a big swing to the middle
        let swing = backOut(pr(t, 4.0, 4.9))
        let unsure = (1 - pr(t, 3.9, 4.1)) * pr(t, 1.2, 1.5)
        var p = mix(0.09, 0.5, swing) + 0.018 * sin(t * 9) * unsure
        if t > 5.0 { p += 0.010 * sin(t * 6) * (1 - pr(t, 5.0, 7.5)) }
        let na = pr(t, 1.1, 1.5)
        if na > 0 {
            let tip = pt(p, r * 0.84)
            Sketch.ink(&ctx, [CGPoint(x: cx, y: cy), tip], closed: false, t: t, seed: 40, width: 3.6, color: BD.red.opacity(na))
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 6 * u, y: cy - 6 * u, width: 12 * u, height: 12 * u)), with: .color(BD.ink.opacity(na)))
        }
        // YOUR GUESS (while it points low)
        let ga = pr(t, 1.7, 2.1) * (1 - pr(t, 4.1, 4.5))
        if ga > 0 {
            let lx = cx - r - 8 * u, ly = cy - 26 * u
            word(&ctx, "YOUR GUESS", CGPoint(x: lx, y: ly), 13 * u, t: t, seed: 50, color: BD.goldText, alpha: ga, anchor: .trailing)
            Sketch.ink(&ctx, [CGPoint(x: lx + 3 * u, y: ly + 3 * u), CGPoint(x: cx - r * 0.7, y: cy - 12 * u)], closed: false, t: t, seed: 51, width: 1.8, color: BD.goldText.opacity(ga))
        }
        // ABOUT 50%
        let ba = pr(t, 4.8, 5.2)
        word(&ctx, "ABOUT 50%", CGPoint(x: cx, y: cy - r - 8 * u), 17 * u, t: t, seed: 60, color: BD.red, alpha: ba, anchor: .bottom, marker: true)
        rays(&ctx, pt(0.5, r + 4 * u), r0: 6 * u, r1: 15 * u, angles: [-2.2, -0.94], t: t, seed: 70, alpha: pr(t, 4.9, 5.3) * (1 - pr(t, 6.6, 7.2)), color: BD.red)
    }
}

// MARK: - Card 2: you (gold) and your day on a calendar; 22 strangers drop their birthdays, none on yours

struct BirthYours: View {
    let active: Bool
    private static let cols = 20, rows = 19, mine = 163
    /// Calendar cells for the 22 strangers: all different from each other and from your day.
    private static let theirs: [Int] = {
        var used: Set<Int> = [mine]
        var out: [Int] = []
        for i in 0..<22 {
            var d = Int(Sketch.rnd(i * 11 + 5) * 365)
            while used.contains(d) || (abs(d % cols - mine % cols) <= 1 && abs(d / cols - mine / cols) <= 1) { d = (d + 37) % 365 }
            used.insert(d); out.append(d)
        }
        return out
    }()

    var body: some View {
        FlatPicture(active: active, period: 11, still: 9.4, cues: [Cue(1.8, .soft), Cue(8.4, .success)], replayOnTap: true, sky: Sketch.paper,
                    label: "You, drawn in gold and waving, next to a calendar with your birthday circled in gold. Along the top stand 22 strangers. One by one each drops their birthday onto the calendar. None land on your day. A note says the chance that one does is less than 6 percent.") { ctx, s, t, _ in
            Self.draw(&ctx, s, t)
        }
    }

    private static func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ t: Double) {
        let w = s.width, h = s.height
        let u = min(w / 343, h / 320)
        ctx.opacity = 1 - pr(t, 10.4, 11)
        let pen = eio(pr(t, 0.1, 1.3))
        let v = min(1.35, max(1, h / (262 * u)))   // spare height stretches the calendar rows
        let oy = max(0, (h - (262 + 152 * (v - 1)) * u) * 0.5)

        // the calendar
        let cw = 9 * u, ch = 8 * u * v, head = 14 * u
        let cal = Cal(rect: CGRect(x: w - 10 * u - cw * Double(cols), y: oy + 62 * u, width: cw * Double(cols), height: head + ch * Double(rows)),
                      cols: cols, rows: rows, head: head)
        cal.draw(&ctx, t: t, seed: 200, pen: pen)

        // the strangers (top row): each drops a birthday onto the calendar
        let sp = (w - 20 * u) / 22
        let k = min(0.46 * u, sp * 0.036)
        let footY = oy + 50 * u
        word(&ctx, "22 STRANGERS", CGPoint(x: w / 2, y: oy + 2 * u), 13 * u, t: t, seed: 210, alpha: pr(t, 0.9, 1.3), anchor: .top)
        for i in 0..<22 {
            let x = 10 * u + sp * (Double(i) + 0.5)
            let arrive = pr(t, 0.3 + Double(i) * 0.02, 0.7 + Double(i) * 0.02)
            let ti = 2.2 + Double(i) * 0.27
            let hop = 3 * u * sin(pr(t, ti - 0.1, ti + 0.2) * .pi)
            person(&ctx, CGPoint(x: x, y: footY - hop), k, t: t, seed: 300 + i * 9, body: BD.bodies[i % BD.bodies.count],
                   hat: BD.hats[(i + 1) % BD.hats.count], skin: skin(i + 40), pen: arrive, alpha: arrive)
            let fly = pr(t, ti, ti + 0.3)
            let target = cal.cell(theirs[i])
            let from = CGPoint(x: x, y: footY - 34 * k)
            let to = CGPoint(x: target.midX, y: target.midY)
            let col = BD.bodies[i % BD.bodies.count]
            if fly > 0 && fly < 1 {
                let e = fly * fly
                let c = CGPoint(x: mix(from.x, to.x, e), y: mix(from.y, to.y, e))
                let r = 3.2 * u
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(col))
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(BD.ink), lineWidth: 1.2)
            } else if fly >= 1 {
                fillCell(&ctx, target, col, alpha: 0.95)
            }
        }

        // your day
        let mineCell = cal.cell(mine)
        let ga = pr(t, 1.2, 1.7)
        if ga > 0 {
            fillCell(&ctx, mineCell, BD.gold, inset: 0.4, alpha: ga)
            let pulse = 1 + 0.25 * sin(pr(t, 8.3, 9.2) * .pi)
            Sketch.ink(&ctx, Sketch.oval(CGPoint(x: mineCell.midX, y: mineCell.midY), 9 * u * pulse, 8 * u * pulse, n: 20), closed: false, t: t, seed: 220,
                       width: 2.2, color: BD.goldLine, drawn: eio(pr(t, 1.3, 2.0)))
            let lx = cal.rect.minX - 14 * u, ly = mineCell.midY
            word(&ctx, "YOUR BIRTHDAY", CGPoint(x: lx, y: ly), 13 * u, t: t, seed: 230, color: BD.goldText, alpha: pr(t, 1.6, 2.0), anchor: .trailing)
            Sketch.ink(&ctx, [CGPoint(x: lx + 3 * u, y: ly), CGPoint(x: mineCell.minX - 9 * u, y: ly)], closed: false, t: t, seed: 231, width: 1.8,
                       color: BD.goldText.opacity(pr(t, 1.8, 2.2)))
        }

        // you
        let youX = (cal.rect.minX - 14 * u) / 2
        person(&ctx, CGPoint(x: youX, y: cal.rect.maxY - 6 * u), 1.5 * u, t: t, seed: 400, body: BD.gold, hat: BD.hats[0], skin: BD.skins[1], pen: pen, alpha: pen,
               wave: t * 6)
        word(&ctx, "YOU", CGPoint(x: youX, y: cal.rect.maxY + 3 * u), 15 * u, t: t, seed: 410, color: BD.goldText, alpha: pr(t, 0.8, 1.2), anchor: .top, marker: true)

        // the answer
        let la = pr(t, 8.4, 8.9)
        word(&ctx, "LESS THAN 6%", CGPoint(x: cal.rect.midX, y: cal.rect.maxY + 4 * u), 19 * u, t: t, seed: 420, color: BD.red, alpha: la, anchor: .top, marker: true)
        rays(&ctx, CGPoint(x: cal.rect.midX + 82 * u, y: cal.rect.maxY + 16 * u), r0: 5 * u, r1: 13 * u, angles: [-0.6, 0.0, 0.6], t: t, seed: 430,
             alpha: pr(t, 8.5, 8.9) * (1 - pr(t, 9.6, 10.2)), color: BD.red)
    }
}

// MARK: - Card 3: 23 people in a ring shake hands once with each other: your 22 lines in gold, the other 231 in ink, to 253

struct BirthPairs: View {
    let active: Bool
    private static let inkPairs: [(Int, Int)] = (1..<23).flatMap { i in ((i + 1)..<23).map { (i, $0) } }

    var body: some View {
        FlatPicture(active: active, period: 12, still: 9.6, cues: [Cue(1.8, .soft), Cue(3.2, .light), Cue(8.3, .success)], replayOnTap: true, sky: Sketch.paper,
                    label: "23 hand-drawn people standing in a ring. One of them is you, in gold. Handshake lines appear one by one between pairs. The 22 lines that include you are gold, the other 231 are ink. A counter climbs to 253 handshakes. Notes say: 22 include you, and one line equals one pair.") { ctx, s, t, _ in
            Self.draw(&ctx, s, t)
        }
    }

    private static func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ t: Double) {
        let w = s.width, h = s.height
        let u = min(w / 343, h / 320)
        ctx.opacity = 1 - pr(t, 11.3, 12)
        let cx = w / 2, cy = h * 0.5
        let R = min(w * 0.34, h * 0.36)
        let k = R / 135
        func pos(_ i: Int) -> CGPoint {
            let a = -Double.pi / 2 + 2 * Double.pi * Double(i) / 23
            return CGPoint(x: cx + R * cos(a), y: cy + R * sin(a))
        }
        let pts = (0..<23).map { pos($0) }
        let f = Sketch.frame(t)

        // handshake lines
        let nGold = Int(22 * eio(pr(t, 1.8, 3.2)) + 0.0001)
        let nInk = Int(231 * pow(pr(t, 3.2, 8.2), 1.15))
        func line(_ a: CGPoint, _ b: CGPoint, _ id: Int, into path: inout Path) {
            let m = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            let o = (Sketch.rnd(id &* 7 &+ f &* 31) - 0.5) * 3.2 * u
            let dx = b.x - a.x, dy = b.y - a.y
            let len = max(1, hypot(dx, dy))
            path.move(to: a)
            path.addQuadCurve(to: b, control: CGPoint(x: m.x - dy / len * o, y: m.y + dx / len * o))
        }
        var inkLines = Path()
        for q in 0..<min(nInk, inkPairs.count) { let pr = inkPairs[q]; line(pts[pr.0], pts[pr.1], q + 50, into: &inkLines) }
        ctx.stroke(inkLines, with: .color(BD.ink.opacity(0.28)), lineWidth: max(0.8, 0.9 * u))
        var goldLines = Path()
        for j in 0..<min(nGold, 22) { line(pts[0], pts[j + 1], j + 1, into: &goldLines) }
        ctx.stroke(goldLines, with: .color(BD.goldLine), style: StrokeStyle(lineWidth: 2.2 * u, lineCap: .round))

        // the people
        for i in 0..<23 {
            let arrive = pr(t, 0.3 + Double(i) * 0.04, 0.7 + Double(i) * 0.04)
            let foot = CGPoint(x: pts[i].x, y: pts[i].y + 9 * k)
            if i == 0 {
                person(&ctx, foot, k * 1.2, t: t, seed: 500, body: BD.gold, hat: BD.hats[0], skin: BD.skins[1], pen: arrive, alpha: arrive)
            } else {
                person(&ctx, foot, k, t: t, seed: 500 + i * 9, body: BD.bodies[i % BD.bodies.count], hat: BD.hats[i % BD.hats.count], skin: skin(i + 20), pen: arrive, alpha: arrive)
            }
        }
        word(&ctx, "YOU", CGPoint(x: cx + 34 * u, y: cy - R - 6 * u), 13 * u, t: t, seed: 510, color: BD.goldText, alpha: pr(t, 1.0, 1.4), anchor: .center, marker: true)

        // counter, top left
        let n = min(253, nGold + nInk)
        let done = pr(t, 8.3, 8.7)
        word(&ctx, "\(n)", CGPoint(x: 10 * u, y: 4 * u), 36 * u, t: t, seed: 520, color: n >= 253 ? BD.red : BD.ink, alpha: pr(t, 1.6, 2.0), anchor: .topLeading, marker: true)
        word(&ctx, "HANDSHAKES", CGPoint(x: 10 * u, y: 44 * u), 13 * u, t: t, seed: 530, alpha: pr(t, 1.6, 2.0), anchor: .topLeading)
        rays(&ctx, CGPoint(x: 78 * u, y: 20 * u), r0: 6 * u, r1: 14 * u, angles: [-0.9, -0.2], t: t, seed: 540, alpha: done * (1 - pr(t, 9.6, 10.2)), color: BD.red)
        // 22 include you, top right
        word(&ctx, "22 INCLUDE YOU", CGPoint(x: w - 10 * u, y: 8 * u), 14 * u, t: t, seed: 550, color: BD.goldText, alpha: pr(t, 2.0, 2.4), anchor: .topTrailing)
        Sketch.ink(&ctx, [CGPoint(x: w - 112 * u, y: 28 * u), CGPoint(x: w - 10 * u, y: 28 * u)], closed: false, t: t, seed: 551, width: 3, color: BD.goldLine.opacity(pr(t, 2.2, 2.6)))
        // key, bottom
        let ka = pr(t, 1.0, 1.5)
        word(&ctx, "ONE LINE = ONE PAIR", CGPoint(x: w / 2, y: h - 4 * u), 13 * u, t: t, seed: 560, alpha: ka, anchor: .bottom)
    }
}

// MARK: - Card 4: room after room of 23 is dealt onto a calendar; rooms with a match get a tick, rooms without a cross; the tally settles near half

private struct RoomPlan {
    let days: [[Int]]
    let match: [Bool]
    let start: [Double]
    let deal: [Double]
    var verdict: [Double] { (0..<days.count).map { start[$0] + deal[$0] + 0.06 } }
    var end: Double { verdict.last ?? 0 }
}

private let roomPlan: RoomPlan = {
    let rooms = 20
    func build(_ off: Int) -> [[Int]] {
        (0..<rooms).map { r in (0..<23).map { k in Int(Sketch.rnd(off + r * 40 + k) * 365) % 365 } }
    }
    func hit(_ d: [Int]) -> Bool { Set(d).count < d.count }
    var days = build(0)
    for off in stride(from: 0, to: 600_000, by: 1009) {
        let cand = build(off)
        let m = cand.map(hit)
        let total = m.filter { $0 }.count
        let early = m[0..<3].filter { $0 }.count
        if total == 10 && early >= 1 && early <= 2 { days = cand; break }
    }
    var start: [Double] = [], deal: [Double] = []
    var at = 1.3
    for r in 0..<rooms {
        let d = r < 3 ? 0.9 : 0.2
        start.append(at); deal.append(d)
        at += d + (r < 3 ? 0.7 : 0.17)
    }
    return RoomPlan(days: days, match: days.map(hit), start: start, deal: deal)
}()

struct BirthRooms: View {
    let active: Bool
    private static let cols = 20, rows = 19

    var body: some View {
        FlatPicture(active: active, period: 14.4, still: 13, cues: [Cue(roomPlan.verdict[0], .soft), Cue(roomPlan.end, .success)], replayOnTap: true, sky: Sketch.paper,
                    label: "A calendar. Room after room of 23 people is dealt onto it, one birthday each. Rooms where two birthdays land on the same day get a tick. Rooms without a shared day get a cross. As more rooms are dealt, the tally of rooms with a match settles near half, labelled about 50 percent.") { ctx, s, t, _ in
            Self.draw(&ctx, s, t)
        }
    }

    private static func glyph(_ ctx: inout GraphicsContext, _ c: CGPoint, _ k: Double, ok: Bool, t: Double, seed: Int, alpha: Double) {
        if ok {
            Sketch.ink(&ctx, [CGPoint(x: c.x - 5 * k, y: c.y), CGPoint(x: c.x - 1.5 * k, y: c.y + 4 * k), CGPoint(x: c.x + 5.5 * k, y: c.y - 5 * k)],
                       closed: false, t: t, seed: seed, width: 2.8, color: BD.green.opacity(alpha), amp: 0.6)
        } else {
            Sketch.ink(&ctx, [CGPoint(x: c.x - 4 * k, y: c.y - 4 * k), CGPoint(x: c.x + 4 * k, y: c.y + 4 * k)], closed: false, t: t, seed: seed, width: 2.4, color: BD.grey.opacity(alpha), amp: 0.5)
            Sketch.ink(&ctx, [CGPoint(x: c.x - 4 * k, y: c.y + 4 * k), CGPoint(x: c.x + 4 * k, y: c.y - 4 * k)], closed: false, t: t, seed: seed + 1, width: 2.4, color: BD.grey.opacity(alpha), amp: 0.5)
        }
    }

    private static func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ t: Double) {
        let w = s.width, h = s.height
        let u = min(w / 343, h / 320)
        ctx.opacity = 1 - pr(t, 13.8, 14.4)
        let pen = eio(pr(t, 0.1, 1.2))
        let v = min(1.5, max(1, h / (215 * u)))   // spare height stretches the calendar rows
        let oy = max(0, (h - (178 + 129 * (v - 1)) * u) * 0.5)
        let plan = roomPlan

        let cw = 7.4 * u, ch = 6.8 * u * v, head = 12 * u
        let cal = Cal(rect: CGRect(x: 10 * u, y: oy + 8 * u, width: cw * Double(cols), height: head + ch * Double(rows)), cols: cols, rows: rows, head: head)
        cal.draw(&ctx, t: t, seed: 600, pen: pen)
        word(&ctx, "A ROOM OF 23", CGPoint(x: cal.rect.midX, y: cal.rect.maxY + 5 * u), 13 * u, t: t, seed: 610, alpha: pr(t, 0.8, 1.2), anchor: .top)

        // the room being dealt now
        var cur = 0
        for r in 0..<plan.days.count where t >= plan.start[r] { cur = r }
        if t >= plan.start[0] {
            let dealt = Int(23 * pr(t, plan.start[cur], plan.start[cur] + plan.deal[cur]) + 0.0001)
            let days = plan.days[cur]
            var seen = Set<Int>()
            var twins: [Int] = []
            for k in 0..<min(23, dealt + (dealt >= 23 || t >= plan.start[cur] + plan.deal[cur] ? 0 : 1)) {
                let d = days[k]
                if seen.contains(d) { twins.append(d) }
                seen.insert(d)
                fillCell(&ctx, cal.cell(d), BD.bodies[k % BD.bodies.count], alpha: k < dealt ? 0.95 : 0.5)
            }
            if t >= plan.verdict[cur], plan.match[cur] {
                let ra = pr(t, plan.verdict[cur], plan.verdict[cur] + 0.12)
                for (i, d) in twins.enumerated() {
                    let c = cal.cell(d)
                    Sketch.ink(&ctx, Sketch.oval(CGPoint(x: c.midX, y: c.midY), 8 * u, 7 * u, n: 16), closed: true, t: t, seed: 620 + i, width: 2.2, color: BD.green.opacity(ra))
                }
            }
        }

        // the tally: two columns
        let colW = min(80 * u, (w - cal.rect.maxX - 24 * u) / 2)
        let zoneL = cal.rect.maxX + 14 * u
        let cxs = [zoneL + colW / 2, zoneL + colW * 1.5 + 4 * u]
        let ha = pr(t, 0.9, 1.3)
        word(&ctx, "ROOMS WITH", CGPoint(x: cxs[0], y: oy + 6 * u), 12 * u, t: t, seed: 630, color: BD.green, alpha: ha, anchor: .top)
        word(&ctx, "A MATCH", CGPoint(x: cxs[0], y: oy + 21 * u), 12 * u, t: t, seed: 631, color: BD.green, alpha: ha, anchor: .top)
        word(&ctx, "ROOMS", CGPoint(x: cxs[1], y: oy + 6 * u), 12 * u, t: t, seed: 632, color: BD.grey, alpha: ha, anchor: .top)
        word(&ctx, "WITHOUT", CGPoint(x: cxs[1], y: oy + 21 * u), 12 * u, t: t, seed: 633, color: BD.grey, alpha: ha, anchor: .top)
        var counts = [0, 0]
        let gx = colW / 4.2
        for r in 0..<plan.days.count where t >= plan.verdict[r] {
            let ok = plan.match[r]
            let ci = ok ? 0 : 1
            let j = counts[ci]; counts[ci] += 1
            let pop = backOut(pr(t, plan.verdict[r], plan.verdict[r] + 0.25))
            let c = CGPoint(x: cxs[ci] - gx * 1.5 + gx * Double(j % 4), y: oy + 52 * u + 20 * u * v * Double(j / 4))
            glyph(&ctx, c, 1.1 * u * pop, ok: ok, t: t, seed: 700 + r * 3, alpha: min(1, pop))
        }
        // settles
        let fin = pr(t, plan.end + 0.5, plan.end + 0.9)
        let mid = (cxs[0] + cxs[1]) / 2
        word(&ctx, "ABOUT 50%", CGPoint(x: mid, y: cal.rect.maxY - 26 * u), 20 * u, t: t, seed: 800, color: BD.red, alpha: fin, anchor: .center, marker: true)
        rays(&ctx, CGPoint(x: mid + 62 * u, y: cal.rect.maxY - 32 * u), r0: 5 * u, r1: 13 * u, angles: [-0.7, 0.0, 0.7], t: t, seed: 810, alpha: fin * (1 - pr(t, plan.end + 1.6, plan.end + 2.2)), color: BD.red)
    }
}

// MARK: - Card 5 (hands-on): drag to add people; PEOPLE, PAIRS and the CHANCE bar climb together

struct BirthCurve: View {
    let active: Bool
    private static let period = 13.4
    private static let curve: [Double] = (0...57).map { shared($0) }
    @State private var n = 1
    @State private var touched = false
    @State private var demoStart = Date()
    @State private var changedAt = Date.distantPast
    @State private var dragBase = 1
    @State private var dragging = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation(paused: !active || reduce)) { tl in
                Canvas { ctx, size in draw(&ctx, size, tl.date) }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    if !dragging {
                        dragging = true
                        dragBase = touched ? n : current(Date()).n
                        touched = true
                    }
                    let u = min(g.size.width / 343, g.size.height / 320)
                    let span = max(60, g.size.width - 48 * u)
                    set(dragBase + Int((v.translation.width / span * 56).rounded()))
                }
                .onEnded { _ in dragging = false })
        }
        .background(LinearGradient(colors: Sketch.paper.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
        .onChange(of: active) { _, a in if a { demoStart = Date() } }
        .task(id: "\(active)-\(touched)-\(reduce)") { await demoCues() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("People walk into a room one at a time. Three counters climb together: people, pairs, and the chance of a match. At 57 people there are 1,596 pairs and the chance is nearly full. Swipe up or down to add or remove people.")
        .accessibilityValue("\(n) people, \(n * (n - 1) / 2) pairs, \(Self.pct(n)) chance of a match")
        .accessibilityAdjustableAction { dir in
            touched = true
            set(n + (dir == .increment ? 1 : -1))
        }
    }

    private static func pct(_ n: Int) -> String {
        let p = shared(n)
        return p < 0.01 ? (n < 2 ? "0%" : "under 1%") : "\(Int(p * 100))%"
    }

    private static func commas(_ v: Int) -> String { v >= 1000 ? "\(v / 1000),\(String(format: "%03d", v % 1000))" : "\(v)" }

    private func set(_ v: Int) {
        let c = min(57, max(1, v))
        guard c != n else { return }
        let up = c > n
        if up && n < 23 && c >= 23 { Haptic.fire(.rigid) }
        else if c == 57 && up { Haptic.fire(.success) }
        else if c % 4 == 0 { Haptic.fire(.light) }
        n = c
        changedAt = Date()
    }

    /// People in the room now, and how far the newest one has walked in (0-1).
    private func current(_ now: Date) -> (n: Int, pop: Double, fade: Double) {
        if touched { return (n, min(1, now.timeIntervalSince(changedAt) / 0.28), 1) }
        if reduce { return (57, 1, 1) }
        let el = now.timeIntervalSince(demoStart).truncatingRemainder(dividingBy: Self.period)
        let c = 56 * eio(pr(el, 1.2, 9.5))
        let fade = 1 - pr(el, 12.7, 13.4)
        if c >= 55.999 { return (57, 1, fade) }
        return (1 + Int(c), c - Double(Int(c)), fade)
    }

    /// The demo's haptic cues: a firm tap when the room reaches 23, a success when it reaches 57.
    private func demoCues() async {
        guard active, !touched, !reduce else { return }
        func when(_ target: Double) -> Double {
            var lo = 0.0, hi = 1.0
            for _ in 0..<30 { let m = (lo + hi) / 2; if eio(m) < target { lo = m } else { hi = m } }
            return 1.2 + hi * (9.5 - 1.2)
        }
        let t23 = when(22.0 / 56), t57 = when(0.999)
        var base = demoStart
        while !Task.isCancelled && !touched {
            for (at, kind) in [(t23, Cue.Kind.rigid), (t57, Cue.Kind.success)] {
                let wait = base.addingTimeInterval(at).timeIntervalSinceNow
                if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
                if Task.isCancelled || touched { return }
                Haptic.fire(kind)
            }
            base = base.addingTimeInterval(Self.period)
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ now: Date) {
        let w = s.width, h = s.height
        let u = min(w / 343, h / 320)
        let t = now.timeIntervalSinceReferenceDate
        let st = current(now)
        ctx.opacity = st.fade
        let n = st.n
        let pairs = n * (n - 1) / 2
        let p = Self.curve[n]
        let v = min(1.4, max(1, h / (262 * u)))   // spare height spreads the rows
        let oy = max(0, (h - (262 + 25 * 2 * (v - 1) + 30 * (v - 1)) * u) * 0.5)

        // counters
        word(&ctx, "PEOPLE", CGPoint(x: 10 * u, y: oy + 4 * u), 13 * u, t: t, seed: 1, anchor: .topLeading)
        word(&ctx, "\(n)", CGPoint(x: 10 * u, y: oy + 16 * u), 34 * u, t: t, seed: 2, color: Color(hex: 0x3F7DB2), anchor: .topLeading, marker: true)
        word(&ctx, "PAIRS", CGPoint(x: w - 10 * u, y: oy + 4 * u), 13 * u, t: t, seed: 3, anchor: .topTrailing)
        word(&ctx, Self.commas(pairs), CGPoint(x: w - 10 * u, y: oy + 16 * u), 34 * u, t: t, seed: 4, color: BD.goldText, anchor: .topTrailing, marker: true)

        // chance bar
        let bx0 = 10 * u, bx1 = w - 10 * u, by = oy + 92 * u, bh = 16 * u
        word(&ctx, "CHANCE OF A MATCH", CGPoint(x: bx0, y: by - 6 * u), 13 * u, t: t, seed: 5, anchor: .bottomLeading)
        word(&ctx, Self.pct(n) == "under 1%" ? "<1%" : Self.pct(n), CGPoint(x: bx1, y: by - 6 * u), 17 * u, t: t, seed: 6, color: BD.red, anchor: .bottomTrailing, marker: true)
        let bar = [CGPoint(x: bx0, y: by), CGPoint(x: bx1, y: by), CGPoint(x: bx1, y: by + bh), CGPoint(x: bx0, y: by + bh)]
        ctx.fill(Path(roundedRect: CGRect(x: bx0, y: by, width: (bx1 - bx0) * p, height: bh), cornerRadius: 3), with: .color(BD.red.opacity(0.85)))
        Sketch.ink(&ctx, bar, closed: true, t: t, seed: 7, width: 2.2)
        Sketch.ink(&ctx, [CGPoint(x: (bx0 + bx1) / 2, y: by - 2 * u), CGPoint(x: (bx0 + bx1) / 2, y: by + bh + 3 * u)], closed: false, t: t, seed: 8, width: 1.4, color: BD.ink.opacity(0.6))

        // the room: 3 rows of 19, filled from the back row, the newest person walking in from the left
        let sp = (w - 20 * u) / 19
        let k = min(0.55 * u, sp * 0.04)
        let gap = 25 * u * v
        let floorY = oy + 130 * u + gap * 2 + 8 * u
        for i in 0..<n {
            let r = i / 19, c = i % 19
            let newest = i == n - 1 ? eio(st.pop) : 1
            let x = 10 * u + sp * (Double(c) + 0.5) - (1 - newest) * 34 * u
            let y = floorY - gap * Double(2 - r)
            person(&ctx, CGPoint(x: x, y: y), k, t: t, seed: 40 + i * 9, body: BD.bodies[i % BD.bodies.count], hat: BD.hats[(i + r) % BD.hats.count],
                   skin: skin(i), alpha: newest)
        }

        // the control: a track and a knob
        let ty = floorY + 26 * u * v
        let tl = 24 * u, tr = w - 24 * u
        let kx = tl + (tr - tl) * Double(n - 1) / 56
        Sketch.ink(&ctx, [CGPoint(x: tl, y: ty), CGPoint(x: tr, y: ty)], closed: false, t: t, seed: 9, width: 3, color: BD.ink.opacity(0.55))
        let nudge = touched ? 0 : 3 * u * sin(t * 4)
        let knob = Sketch.oval(CGPoint(x: kx + nudge, y: ty), 11 * u, 11 * u, n: 18)
        Sketch.ink(&ctx, knob, closed: true, t: t, seed: 10, width: 2.2, fill: BD.red)
        for dx in [-3.0, 3.0] {
            Sketch.ink(&ctx, [CGPoint(x: kx + nudge + dx * u, y: ty - 4 * u), CGPoint(x: kx + nudge + dx * u, y: ty + 4 * u)], closed: false, t: t, seed: 11, width: 1.6, color: .white, amp: 0.3)
        }
        word(&ctx, "DRAG TO ADD PEOPLE", CGPoint(x: w / 2, y: ty + 20 * u), 13 * u, t: t, seed: 12, color: BD.grey, alpha: touched ? 0.55 : 1, anchor: .top)
    }
}
