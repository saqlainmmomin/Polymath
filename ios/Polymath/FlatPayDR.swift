import SwiftUI

// "Why isn't the shop paid the moment you tap your card?" pictures in the drafting style (2026-11-03): white paper, crisp black outlines, a
// card terminal drawn like a real one (front face, thickness, keypad, screen, contactless panel), light hatching for shade and ONE yellow
// accent for the message. Labels are the slide's own words. On a swipeable card each picture loops; narrated it plays once with the voice
// and holds. Drawn in the default 343 x 320 design space, clear of the bottom-right corner (x > 288, y > 235).

private func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

// MARK: - Shared parts

enum PayDR {
    /// The card terminal on its foot, front face with a little thickness to the right. Body 72 x 106 with its top left at `at`;
    /// the foot reaches 12 below. `on` draws the outlines, `fill` the white and the hatching.
    static func terminal(_ c: inout GraphicsContext, at o: CGPoint, on: Double, fill: Double) {
        var g = c; g.opacity = fill
        let r = CGRect(x: o.x, y: o.y, width: 72, height: 106)
        let dx = 10.0, dy = -7.0
        // thickness: the body again, up and to the right, with the corners joined
        let back = Path(roundedRect: r.offsetBy(dx: dx, dy: dy), cornerRadius: 9)
        g.fill(back, with: .color(DR.side))
        DR.hatch(&g, back, in: r.offsetBy(dx: dx, dy: dy), spacing: 3.2, alpha: 0.3)
        DR.draw(&c, back, p: on, width: DR.hair + 0.2)
        var join = Path()
        join.move(to: pt(r.maxX - 2.6, r.minY + 2.6)); join.addLine(to: pt(r.maxX - 2.6 + dx, r.minY + 2.6 + dy))
        join.move(to: pt(r.maxX - 2.6, r.maxY - 2.6)); join.addLine(to: pt(r.maxX - 2.6 + dx, r.maxY - 2.6 + dy))
        join.move(to: pt(r.minX + 2.6, r.minY + 2.6)); join.addLine(to: pt(r.minX + 2.6 + dx, r.minY + 2.6 + dy))
        DR.draw(&c, join, p: on, width: DR.hair + 0.2)
        // the foot
        var foot = Path()
        foot.move(to: pt(o.x + 12, r.maxY - 1)); foot.addLine(to: pt(o.x + 60, r.maxY - 1))
        foot.addLine(to: pt(o.x + 66, r.maxY + 12)); foot.addLine(to: pt(o.x + 6, r.maxY + 12)); foot.closeSubpath()
        g.fill(foot, with: .color(DR.side))
        DR.hatch(&g, foot, in: foot.boundingRect, spacing: 3, alpha: 0.35)
        DR.draw(&c, foot, p: on)
        // the front
        let front = Path(roundedRect: r, cornerRadius: 9)
        g.fill(front, with: .color(DR.face))
        DR.draw(&c, front, p: on, width: DR.line + 0.15)
        // contactless panel with the symbol
        let panel = CGRect(x: o.x + 8, y: o.y + 8, width: 56, height: 26)
        g.fill(Path(roundedRect: panel, cornerRadius: 4), with: .color(DR.side))
        DR.draw(&c, Path(roundedRect: panel, cornerRadius: 4), p: on, width: DR.hair)
        symbol(&c, at: pt(o.x + 21, o.y + 21), on: on)
        // screen: a dark glass with the amount as two short bars
        let screen = Path(roundedRect: CGRect(x: o.x + 8, y: o.y + 40, width: 56, height: 20), cornerRadius: 3)
        g.fill(screen, with: .color(DR.ink.opacity(0.88)))
        DR.draw(&c, screen, p: on, width: DR.hair + 0.2)
        if fill > 0 {
            var bars = Path()
            bars.addRoundedRect(in: CGRect(x: o.x + 14, y: o.y + 46, width: 22, height: 3), cornerSize: CGSize(width: 1.5, height: 1.5))
            bars.addRoundedRect(in: CGRect(x: o.x + 14, y: o.y + 52, width: 34, height: 2.4), cornerSize: CGSize(width: 1.2, height: 1.2))
            g.fill(bars, with: .color(.white.opacity(0.85)))
        }
        // keypad: three by four keys
        var keys = Path()
        for row in 0..<4 { for col in 0..<3 {
            keys.addRoundedRect(in: CGRect(x: o.x + 11 + 17.5 * Double(col), y: o.y + 66 + 9.5 * Double(row), width: 13, height: 6.5), cornerSize: CGSize(width: 2, height: 2))
        } }
        g.fill(keys, with: .color(DR.face))
        DR.draw(&c, keys, p: on, width: DR.hair)
    }

    /// The contactless symbol: a dot and three arcs opening to the right.
    static func symbol(_ c: inout GraphicsContext, at p: CGPoint, on: Double) {
        var s = Path()
        for r in [5.0, 9.0, 13.0] {
            for i in 0...8 {
                let a = -0.8 + 1.6 * Double(i) / 8
                let q = pt(p.x - 7 + r * cos(a), p.y + r * sin(a))
                if i == 0 { s.move(to: q) } else { s.addLine(to: q) }
            }
        }
        DR.draw(&c, s, p: on, width: DR.hair + 0.15)
        if on > 0.2 { c.fill(Path(ellipseIn: CGRect(x: p.x - 8.8, y: p.y - 1.8, width: 3.6, height: 3.6)), with: .color(DR.ink)) }
    }

    /// A bank card, 52 x 33, centred on `at`: magnetic stripe, chip and a few number marks.
    static func card(_ c: inout GraphicsContext, at: CGPoint, on: Double, fill: Double) {
        let r = CGRect(x: at.x - 26, y: at.y - 16.5, width: 52, height: 33)
        var g = c; g.opacity = fill
        let body = Path(roundedRect: r, cornerRadius: 3.5)
        g.fill(body, with: .color(DR.face))
        DR.draw(&c, body, p: on)
        g.fill(Path(CGRect(x: r.minX + 0.6, y: r.minY + 5.5, width: r.width - 1.2, height: 5.5)), with: .color(DR.ink.opacity(0.85)))
        let chip = Path(roundedRect: CGRect(x: r.minX + 6, y: r.minY + 15, width: 10, height: 8), cornerRadius: 1.2)
        DR.draw(&c, chip, p: on, width: DR.hair)
        var marks = Path()
        marks.move(to: pt(r.minX + 6, r.maxY - 4)); marks.addLine(to: pt(r.minX + 30, r.maxY - 4))
        marks.move(to: pt(r.minX + 34, r.maxY - 4)); marks.addLine(to: pt(r.minX + 44, r.maxY - 4))
        marks.move(to: pt(r.minX + 20, r.minY + 19)); marks.addLine(to: pt(r.minX + 44, r.minY + 19))
        DR.draw(&c, marks, p: on, width: DR.hair, color: DR.ink.opacity(0.55))
    }

    /// A hand holding a card by its lower right corner, as in a tap (drawn after a line-art reference, 2026-11-03): the thumb lies across the card with
    /// its nail, the back of the hand is a big rounded shape beside it, three curled fingers hang behind the card, then a cuff and the forearm
    /// running off down to the right. `at` is the card's centre. Draws the card too, so card and hand stack in the right order.
    static func heldCard(_ c: inout GraphicsContext, at: CGPoint, on: Double, fill: Double) {
        var h = c
        h.translateBy(x: at.x, y: at.y)
        var f = h; f.opacity = fill
        func fillDraw(_ p: Path, width: Double = DR.line + 0.1) { f.fill(p, with: .color(DR.face)); DR.draw(&h, p, p: on, width: width) }
        func capsule(_ top: CGPoint, _ tip: CGPoint, _ w: Double) -> Path {
            let len = hypot(tip.x - top.x, tip.y - top.y), ang = atan2(tip.y - top.y, tip.x - top.x)
            return Path(roundedRect: CGRect(x: 0, y: -w / 2, width: len, height: w), cornerRadius: w / 2)
                .applying(CGAffineTransform(translationX: top.x, y: top.y).rotated(by: ang).concatenating(.identity))
                .applying(.identity)
        }
        func rotated(_ p: Path, _ o: CGPoint, _ a: Double) -> Path {
            p.applying(CGAffineTransform(translationX: -o.x, y: -o.y).concatenating(CGAffineTransform(rotationAngle: a)).concatenating(CGAffineTransform(translationX: o.x, y: o.y)))
        }
        // three curled fingers and a fourth tip, hanging behind the card
        for (top, tip, w) in [(pt(11, 10), pt(7, 22), 7.0), (pt(24, 14), pt(14.5, 37), 7.5), (pt(30, 20), pt(19.5, 46), 7.5), (pt(36, 26), pt(25, 51), 7.5)] {
            let p = capsule(top, tip, w)
            f.fill(p, with: .color(DR.face)); DR.draw(&h, p, p: on)
        }
        PayDR.card(&h, at: .zero, on: on, fill: fill)
        // the forearm and cuff
        var arm = Path()
        arm.move(to: pt(95, 59)); arm.addLine(to: pt(150, 112)); arm.addLine(to: pt(118, 150)); arm.addLine(to: pt(79, 76))
        fillDraw(arm)
        DR.hatch(&f, arm, in: arm.boundingRect, spacing: 3.2, alpha: 0.3)
        var cuff = Path()
        cuff.move(to: pt(84, 50)); cuff.addLine(to: pt(95, 59)); cuff.addLine(to: pt(79, 76)); cuff.addLine(to: pt(66, 71)); cuff.closeSubpath()
        fillDraw(cuff)
        // the back of the hand
        var back = Path()
        back.move(to: pt(26, 6))
        back.addCurve(to: pt(42, 4), control1: pt(31, 4), control2: pt(36, 3.8))
        back.addLine(to: pt(58, 5))
        back.addCurve(to: pt(70, 12), control1: pt(66, 5), control2: pt(69, 7))
        back.addCurve(to: pt(76, 33), control1: pt(72, 19), control2: pt(73, 25))
        back.addCurve(to: pt(85, 52), control1: pt(78, 40), control2: pt(81, 46))
        back.addLine(to: pt(66, 71))
        back.addCurve(to: pt(46, 46), control1: pt(58, 64), control2: pt(50, 56))
        back.addCurve(to: pt(42, 30), control1: pt(44, 40), control2: pt(44, 34))
        back.addCurve(to: pt(24, 10), control1: pt(38, 24), control2: pt(30, 16))
        back.closeSubpath()
        fillDraw(back)
        DR.hatch(&f, back, in: back.boundingRect, spacing: 3.4, alpha: 0.0)
        var shade = Path()
        for i in 0..<7 { let x = 50.0 + 4 * Double(i); shade.move(to: pt(x + 2, 56 - Double(i) * 1.6 + 8)); shade.addLine(to: pt(x, 44 - Double(i) * 1.6 + 4)) }
        DR.draw(&h, shade, p: on, width: DR.hair, color: DR.ink.opacity(0.5))
        var knuckles = Path()
        knuckles.move(to: pt(46, 6)); knuckles.addCurve(to: pt(52, 14), control1: pt(46, 9), control2: pt(48, 12))
        knuckles.move(to: pt(56, 5)); knuckles.addCurve(to: pt(62, 12), control1: pt(56, 8), control2: pt(58, 11))
        DR.draw(&h, knuckles, p: on, width: DR.hair, color: DR.ink.opacity(0.6))
        // the thumb across the card, nail at its tip; the base melts into the hand, so only the outline is stroked
        var thumb = Path()
        thumb.move(to: pt(48, 31))
        thumb.addCurve(to: pt(20, 7.5), control1: pt(40, 24), control2: pt(24, 12))
        thumb.addCurve(to: pt(11.5, 12), control1: pt(16, 5), control2: pt(11, 8))
        thumb.addCurve(to: pt(22, 26), control1: pt(12, 15), control2: pt(16, 18))
        thumb.addCurve(to: pt(46, 41), control1: pt(28, 33), control2: pt(36, 38))
        f.fill(thumb, with: .color(DR.face))
        DR.draw(&h, thumb, p: on, width: DR.line + 0.1)
        let nail = rotated(Path(ellipseIn: CGRect(x: 11.5, y: 7.5, width: 9, height: 6.5)), pt(16, 10.8), 0.6)
        DR.draw(&h, nail, p: on, width: DR.hair + 0.1)
        var crease = Path(); crease.move(to: pt(30, 18)); crease.addCurve(to: pt(34, 26), control1: pt(32, 20), control2: pt(34, 23))
        DR.draw(&h, crease, p: on, width: DR.hair, color: DR.ink.opacity(0.6))
    }

    /// The message: an envelope in the accent, 34 x 24, with a question mark on it, centred on `at`.
    static func envelope(_ c: inout GraphicsContext, at: CGPoint, alpha: Double) {
        guard alpha > 0.01 else { return }
        var g = c; g.opacity = alpha
        let r = CGRect(x: at.x - 17, y: at.y - 12, width: 34, height: 24)
        let body = Path(roundedRect: r, cornerRadius: 2.5)
        g.fill(body, with: .color(DR.accent))
        g.stroke(body, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
        var flap = Path()
        flap.move(to: pt(r.minX, r.minY)); flap.addLine(to: pt(at.x, at.y - 1)); flap.addLine(to: pt(r.maxX, r.minY))
        g.stroke(flap, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.hair + 0.2, lineJoin: .round))
        let q = g.resolve(Text("?").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(DR.ink))
        g.draw(q, at: pt(at.x, at.y + 5.5), anchor: .center)
    }
}

// MARK: - Shared drawings for cards 2-4

extension PayDR {
    /// A bank, front-on: pediment, entablature, four fluted columns, two steps. 56 wide, 58 high, standing on `base` at x = `cx`.
    static func bank(_ c: inout GraphicsContext, cx: Double, base: Double, on: Double, fill: Double) {
        var g = c; g.opacity = fill
        func box(_ r: CGRect, _ shade: Bool = false, _ w: Double = DR.line) {
            let p = Path(r)
            g.fill(p, with: .color(shade ? DR.side : DR.face))
            DR.draw(&c, p, p: on, width: w)
        }
        box(CGRect(x: cx - 28, y: base - 5, width: 56, height: 5), true)
        box(CGRect(x: cx - 25, y: base - 10, width: 50, height: 5), true)
        for dx in [-18.0, -6, 6, 18] {
            box(CGRect(x: cx + dx - 3.5, y: base - 38, width: 7, height: 28), false, DR.hair + 0.3)
            var flute = Path()
            for fx in [-1.2, 1.2] { flute.move(to: pt(cx + dx + fx, base - 35)); flute.addLine(to: pt(cx + dx + fx, base - 13)) }
            DR.draw(&c, flute, p: on, width: DR.hair - 0.15, color: DR.ink.opacity(0.55))
            box(CGRect(x: cx + dx - 4.5, y: base - 40, width: 9, height: 2.5), false, DR.hair + 0.3)
            box(CGRect(x: cx + dx - 4.5, y: base - 12.5, width: 9, height: 2.5), false, DR.hair + 0.3)
        }
        box(CGRect(x: cx - 27, y: base - 46, width: 54, height: 6), true)
        var roof = Path()
        roof.move(to: pt(cx - 29, base - 46)); roof.addLine(to: pt(cx, base - 60)); roof.addLine(to: pt(cx + 29, base - 46)); roof.closeSubpath()
        g.fill(roof, with: .color(DR.face))
        DR.hatch(&g, roof, in: roof.boundingRect, spacing: 3.4, alpha: 0.28)
        DR.draw(&c, roof, p: on)
        DR.draw(&c, Path(ellipseIn: CGRect(x: cx - 3.5, y: base - 55, width: 7, height: 7)), p: on, width: DR.hair)
    }

    /// A card network: a little globe in the middle with spokes to five nodes. About 60 wide, 56 high, centred on `at`.
    static func network(_ c: inout GraphicsContext, at: CGPoint, on: Double, fill: Double) {
        var g = c; g.opacity = fill
        var nodes: [CGPoint] = []
        for i in 0..<5 {
            let a = -Double.pi / 2 + 2 * Double.pi * Double(i) / 5
            nodes.append(pt(at.x + 27 * cos(a) * 1.05, at.y + 25 * sin(a)))
        }
        var spokes = Path()
        for n in nodes { spokes.move(to: at); spokes.addLine(to: n) }
        DR.draw(&c, spokes, p: on, width: DR.hair + 0.2)
        for n in nodes {
            let d = Path(ellipseIn: CGRect(x: n.x - 5.5, y: n.y - 5.5, width: 11, height: 11))
            g.fill(d, with: .color(DR.face))
            DR.hatch(&g, d, in: d.boundingRect, spacing: 2.6, alpha: 0.3)
            DR.draw(&c, d, p: on)
        }
        let globe = Path(ellipseIn: CGRect(x: at.x - 11, y: at.y - 11, width: 22, height: 22))
        g.fill(globe, with: .color(DR.face))
        DR.hatch(&g, globe, in: globe.boundingRect, spacing: 3, alpha: 0.28)
        DR.draw(&c, globe, p: on, width: DR.line + 0.1)
        var lines = Path()
        lines.addEllipse(in: CGRect(x: at.x - 5, y: at.y - 11, width: 10, height: 22))
        lines.move(to: pt(at.x - 11, at.y)); lines.addLine(to: pt(at.x + 11, at.y))
        DR.draw(&c, lines, p: on, width: DR.hair, color: DR.ink.opacity(0.7))
    }

    /// A shop, front-on: striped scalloped awning, two posts, a counter with a till on it. 64 wide, 62 high, standing on `base` at x = `cx`.
    /// `tray` is an open, empty money tray in the counter's front.
    static func shop(_ c: inout GraphicsContext, cx: Double, base: Double, on: Double, fill: Double, tray: Bool = true) {
        var g = c; g.opacity = fill
        var posts = Path()
        for sx in [-1.0, 1.0] { posts.move(to: pt(cx + sx * 29, base - 48)); posts.addLine(to: pt(cx + sx * 29, base)) }
        DR.draw(&c, posts, p: on, width: DR.line)
        let counter = Path(CGRect(x: cx - 29, y: base - 24, width: 58, height: 24))
        g.fill(counter, with: .color(DR.side))
        DR.hatch(&g, counter, in: counter.boundingRect, spacing: 3.4, alpha: 0.25)
        DR.draw(&c, counter, p: on)
        let till = Path(roundedRect: CGRect(x: cx - 12, y: base - 38, width: 24, height: 14), cornerRadius: 2)
        g.fill(till, with: .color(DR.face)); DR.draw(&c, till, p: on)
        let screen = Path(roundedRect: CGRect(x: cx - 8, y: base - 36, width: 16, height: 5), cornerRadius: 1)
        g.fill(screen, with: .color(DR.ink.opacity(0.85)))
        var keys = Path()
        for k in 0..<4 { keys.addRect(CGRect(x: cx - 8 + 4.2 * Double(k), y: base - 28, width: 3, height: 2.4)) }
        g.fill(keys, with: .color(DR.ink.opacity(0.7)))
        if tray {
            let t = Path(roundedRect: CGRect(x: cx - 22, y: base - 17, width: 44, height: 10), cornerRadius: 2)
            g.fill(t, with: .color(DR.face)); DR.draw(&c, t, p: on)
            var mid = Path(); mid.move(to: pt(cx, base - 15)); mid.addLine(to: pt(cx, base - 9))
            DR.draw(&c, mid, p: on, width: DR.hair, color: DR.ink.opacity(0.5), dash: [2, 2])
        }
        for i in 0..<4 {
            let x0 = cx - 32 + 16 * Double(i), x1 = x0 + 16, yb = base - 48
            var p = Path()
            p.move(to: pt(x0, base - 62)); p.addLine(to: pt(x1, base - 62)); p.addLine(to: pt(x1, yb))
            for k in 0...10 { let a = Double.pi * Double(k) / 10; p.addLine(to: pt((x0 + x1) / 2 + 8 * cos(a), yb + 7 * sin(a))) }
            p.closeSubpath()
            g.fill(p, with: .color(DR.face))
            if i % 2 == 0 { DR.hatch(&g, p, in: p.boundingRect, spacing: 2.6, alpha: 0.5) }
            DR.draw(&c, p, p: on)
        }
    }

    /// The yes: a pill in the accent, with the word YES or a tick, centred on `at`.
    static func yes(_ c: inout GraphicsContext, at: CGPoint, alpha: Double, word: Bool) {
        guard alpha > 0.01 else { return }
        var g = c; g.opacity = alpha
        let pill = Path(roundedRect: CGRect(x: at.x - 18, y: at.y - 9, width: 36, height: 18), cornerRadius: 9)
        g.fill(pill, with: .color(DR.accent))
        g.stroke(pill, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
        if word {
            g.draw(g.resolve(Text("YES").font(.system(size: 9.5, weight: .bold, design: .rounded)).tracking(0.8).foregroundColor(DR.ink)), at: at, anchor: .center)
        } else {
            var tick = Path()
            tick.move(to: pt(at.x - 5, at.y)); tick.addLine(to: pt(at.x - 1.5, at.y + 3.5)); tick.addLine(to: pt(at.x + 6, at.y - 4))
            g.stroke(tick, with: .color(DR.ink), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }

    /// A slip of paper (a payment, or a total when `big`) with two lines on it; `set` turns it to the accent.
    static func slip(_ c: inout GraphicsContext, at: CGPoint, big: Bool, set: Double = 0, alpha: Double) {
        guard alpha > 0.01 else { return }
        var g = c; g.opacity = alpha
        let w = big ? 22.0 : 11.0, h = big ? 14.0 : 7.0
        let r = Path(roundedRect: CGRect(x: at.x - w / 2, y: at.y - h / 2, width: w, height: h), cornerRadius: big ? 2 : 1.2)
        g.fill(r, with: .color(DR.face))
        if set > 0 { g.fill(r, with: .color(DR.accent.opacity(set))) }
        g.stroke(r, with: .color(DR.ink), style: StrokeStyle(lineWidth: big ? DR.line : DR.hair + 0.2, lineJoin: .round))
        if big {
            var l = Path()
            for dy in [-2.0, 2.2] { l.move(to: pt(at.x - 6, at.y + dy)); l.addLine(to: pt(at.x + 6, at.y + dy)) }
            g.stroke(l, with: .color(DR.ink.opacity(0.7)), lineWidth: DR.hair)
        }
    }
}

// MARK: - Card 1: you tap, it beeps, and you walk away

struct PayDRTap: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 3.8

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 1.5,
                       label: "A line drawing on white: a hand holds a bank card out to a card terminal on a counter, then taps it on the contactless panel. Thin rings spread from the panel. The hand pulls back, and a short message, a gold envelope with a question mark, rises from the terminal and floats up and away. Labels say: card reader, message, can this card pay?",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u, clock) }
                       })
    }

    private static let term = pt(150, 114)           // the terminal's top left
    private static let tapAt = pt(180, 124)         // where the card lies on the contactless panel
    private static let rest = pt(70, -58)
    private static let m0 = pt(186, 106), m1 = pt(170, 40), m2 = pt(110, 30), m3 = pt(76, 62)

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

        PayDR.terminal(&c, at: term, on: on, fill: fill)

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
        PayDR.heldCard(&c, at: cardAt, on: on, fill: fill)

        // the message: leaves the top of the terminal and floats off, then bobs a little where it rests
        let e = BP.eio(BP.pr(u, 2.2, 3.5))
        if e > 0 {
            var trail = Path(); trail.move(to: m0); trail.addCurve(to: m3, control1: m1, control2: m2)
            DR.draw(&c, trail, p: e, width: DR.hair, color: DR.ink.opacity(0.5), dash: [3, 3.5])
            let pos = flight(e)
            PayDR.envelope(&c, at: pt(pos.x, pos.y + sin(max(0, clock - 3.5) * 2.4) * 1.5 * BP.pr(u, 3.4, 3.8)), alpha: BP.pr(u, 2.2, 2.45))
        }

        DR.label(&c, "CARD READER", anchor: pt(term.x + 1, 176), at: pt(100, 202), align: .center, p: BP.pr(u, 0.5, 1.0))
        DR.label(&c, "MESSAGE", anchor: pt(m3.x - 10, m3.y - 11), at: pt(26, 20), align: .leading, p: BP.pr(u, 2.9, 3.3))
        DR.label(&c, "CAN THIS CARD PAY?", anchor: pt(m3.x, m3.y + 13), at: pt(24, 96), align: .leading, p: BP.pr(u, 3.2, 3.6))
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
                PayDR.terminal(&r, at: .zero, on: on, fill: fill)
            case 2: PayDR.network(&c, at: pt(xs[2], base - 30), on: on, fill: fill)
            default: PayDR.bank(&c, cx: xs[i], base: base - 1, on: on, fill: fill)
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
        PayDR.envelope(&c, at: spot(out), alpha: BP.pr(u, 0.2, 0.6) * (1 - BP.pr(u, 3.35, 3.75)))
        PayDR.yes(&c, at: spot(back), alpha: BP.pr(u, 3.45, 3.85) * (1 - BP.pr(u, 7.7, 8.2)), word: true)
    }
}

// MARK: - Card 3: the yes is a promise, the money is not at the shop

struct PayDRPromise: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 4.4

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 2.0,
                       label: "A line drawing on white: your bank on the left with a bar for what you can spend, full. A yes, shown in gold, arrives at the bank and the bar drops. On the right the shop's till stays empty, with a gap between the bank and the shop. Labels say: your bank, what you can spend, your bank's yes, the shop.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let bankX = 79.0, shopX = 270.0, base = 150.0
    private static let track = CGRect(x: 24, y: 166, width: 110, height: 16)

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        let on = BP.pr(u, 0, 0.8), fill = BP.pr(u, 0.2, 0.7)
        var ground = Path(); ground.move(to: pt(14, base)); ground.addLine(to: pt(330, base))
        DR.draw(&c, ground, p: on, width: DR.line + 0.2)
        PayDR.bank(&c, cx: bankX, base: base - 1, on: on, fill: fill)
        PayDR.shop(&c, cx: shopX, base: base - 1, on: BP.pr(u, 0.15, 0.95), fill: BP.pr(u, 0.35, 0.85))

        // the gap between them: a dimension line with nothing on it
        var gap = Path()
        gap.move(to: pt(120, 126)); gap.addLine(to: pt(228, 126))
        for x in [120.0, 228.0] { gap.move(to: pt(x, 120)); gap.addLine(to: pt(x, 132)) }
        DR.draw(&c, gap, p: BP.pr(u, 0.5, 1.1), width: DR.hair, color: DR.ink.opacity(0.6), dash: [4, 3.5])

        // what you can spend: a full bar that drops when the yes arrives
        let drop = BP.eio(BP.pr(u, 2.0, 2.7)), level = 1 - 0.4 * drop
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
        let move = BP.eio(BP.pr(u, 0.6, 1.8)), pulse = 1 + 0.06 * sin(Double.pi * BP.pr(u, 1.8, 2.2))
        var s = c
        let at = pt(BP.mix(222, 140, move), base - 38)
        s.translateBy(x: at.x, y: at.y); s.scaleBy(x: pulse, y: pulse)
        PayDR.yes(&s, at: .zero, alpha: BP.pr(u, 0.5, 0.9), word: false)

        DR.label(&c, "YOUR BANK", anchor: pt(bankX - 14, base - 54), at: pt(34, 76), align: .leading, p: BP.pr(u, 0.4, 1.0))
        DR.label(&c, "WHAT YOU CAN SPEND", anchor: pt(60, 184), at: pt(74, 214), align: .center, p: BP.pr(u, 0.9, 1.7))
        DR.label(&c, "YOUR BANK'S YES", anchor: pt(at.x, base - 48), at: pt(150, 76), align: .leading, p: BP.pr(u, 1.5, 2.3))
        DR.label(&c, "THE SHOP", anchor: pt(shopX, base + 3), at: pt(shopX, 190), align: .center, p: BP.pr(u, 2.0, 2.8))
    }
}

// MARK: - Card 4: totals, a few working days, then the shop is paid

struct PayDRTotals: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 9.0

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 8.2,
                       label: "A line drawing on white: many small payment slips drop onto two banks and add up into totals. Three days tick off on a calendar. Only then do the totals, shown in gold, slide from the banks to the shop. Labels say: many payments, totals, a few working days, the shop.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u) }
                       })
    }

    private static let banks: [Double] = [44, 106]
    private static let shopX = 270.0, base = 150.0, pileY = 70.0
    private static let slots: [(Double, Double)] = [(-11, 0), (0, 0), (11, 0), (-5.5, -7), (5.5, -7), (0, -14)]
    private static let cal = CGRect(x: 148, y: 176, width: 92, height: 40)

    private static func draw(_ c: inout GraphicsContext, _ u: Double) {
        let on = BP.pr(u, 0, 0.8), fill = BP.pr(u, 0.2, 0.7)
        var ground = Path(); ground.move(to: pt(14, base)); ground.addLine(to: pt(330, base))
        DR.draw(&c, ground, p: on, width: DR.line + 0.2)
        for x in banks { PayDR.bank(&c, cx: x, base: base - 1, on: on, fill: fill) }
        PayDR.shop(&c, cx: shopX, base: base - 1, on: BP.pr(u, 0.3, 1.0), fill: BP.pr(u, 0.5, 1.0), tray: false)

        // the calendar: three ticks pass
        let fade = 1 - BP.pr(u, 9.6, 10.2)
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
            let p = BP.pr(u, 3.9 + 0.9 * Double(j), 4.3 + 0.9 * Double(j))
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
            let s = 0.3 + 0.2 * Double(i)
            let f = BP.pr(u, s, s + 0.45)
            let slot = slots[i / 2], bx = banks[i % 2]
            let at = pt(bx + slot.0, 46 + (pileY + slot.1 - 46) * f * f)
            PayDR.slip(&c, at: at, big: false, alpha: BP.pr(u, s, s + 0.08) * (1 - BP.pr(u, 2.9, 3.3)))
        }
        let ta = BP.pr(u, 2.9, 3.5) * fade, m = BP.pr(u, 6.2, 6.6), e = BP.eio(BP.pr(u, 6.6, 8.2))
        let targets: [Double] = [254, 286]
        for (i, bx) in banks.enumerated() {
            PayDR.slip(&c, at: pt(BP.mix(bx, targets[i], e), pileY - 6 + 36 * BP.eio(BP.pr(u, 8.2, 8.8))), big: true, set: m, alpha: ta)
        }

        DR.label(&c, "MANY PAYMENTS", anchor: pt(banks[0], pileY - 10), at: pt(14, 36), align: .leading, p: BP.pr(u, 0.3, 1.0))
        DR.label(&c, "TOTALS", anchor: pt(banks[1] + 8, pileY - 14), at: pt(122, 40), align: .leading, p: BP.pr(u, 0.8, 1.5))
        DR.label(&c, "A FEW WORKING DAYS", anchor: pt(194, cal.maxY + 2), at: pt(190, 246), align: .center, p: BP.pr(u, 1.3, 2.1))
        DR.label(&c, "THE SHOP", anchor: pt(shopX, base + 3), at: pt(shopX + 6, 188), align: .center, p: BP.pr(u, 1.8, 2.6))
    }
}
