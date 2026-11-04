import SwiftUI

// Drafting parts for scene topics that stand on the ground: a phone, a battery cell, a glass meter, a tank of liquid, a snowflake and the
// ground line. Every standing part has its bottom centre at the origin, so a scene centres it by x and sets its feet with y. Each has a
// little thickness (the back slab, hatched, joined at the corners) like `terminal`, never a bare rectangle. Same `on` / `fill`
// conventions as the rest of DR: `on` draws the outlines, `fill` fades the white and the hatching in.

extension DR {
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    /// A slab seen from the front with its right and top edges showing: the back slab (hatched side colour), the corner joins, then the front.
    private static func block(_ c: inout GraphicsContext, _ r: CGRect, radius: Double, dx: Double, dy: Double, on: Double, fill: Double) {
        var g = c; g.opacity = fill
        let back = Path(roundedRect: r.offsetBy(dx: dx, dy: dy), cornerRadius: radius)
        g.fill(back, with: .color(DR.side))
        DR.hatch(&g, back, in: r.offsetBy(dx: dx, dy: dy), spacing: 3.2, alpha: 0.3)
        DR.draw(&c, back, p: on, width: DR.hair + 0.2)
        var join = Path()
        let k = radius * 0.3
        for (x, y) in [(r.maxX - k, r.minY + k), (r.maxX - k, r.maxY - k), (r.minX + k, r.minY + k)] {
            join.move(to: pt(x, y)); join.addLine(to: pt(x + dx, y + dy))
        }
        DR.draw(&c, join, p: on, width: DR.hair + 0.2)
        let front = Path(roundedRect: r, cornerRadius: radius)
        g.fill(front, with: .color(DR.face))
        DR.draw(&c, front, p: on, width: DR.line + 0.15)
    }

    /// The glass window of a battery or meter: a level of yellow charge from the bottom (`level` 0...1, or grey with `grey`), a hatched
    /// "still there" patch above it (`stuck` 0...1) and tick marks down the left side.
    private static func window(_ c: inout GraphicsContext, _ win: CGRect, radius: Double, on: Double, fill: Double, level: Double, stuck: Double,
                               grey: Bool, ticks: Int) {
        var g = c; g.opacity = fill
        let wp = Path(roundedRect: win, cornerRadius: radius)
        g.fill(wp, with: .color(DR.side))
        let top = win.maxY - win.height * BP.cl(level)
        var lg = g; lg.clip(to: wp)
        if level > 0.001 {
            let body = Path(CGRect(x: win.minX, y: top, width: win.width, height: win.maxY - top))
            lg.fill(body, with: .color(grey ? DR.ink.opacity(0.16) : DR.accent))
            lg.fill(Path(CGRect(x: win.maxX - 6, y: top, width: 6, height: win.maxY - top)), with: .color(grey ? DR.ink.opacity(0.1) : DR.accentSide))
            var edge = Path(); edge.move(to: pt(win.minX, top)); edge.addLine(to: pt(win.maxX, top))
            lg.stroke(edge, with: .color(DR.ink.opacity(0.7)), lineWidth: DR.hair)
        }
        if stuck > 0.001 {
            var sg = c; sg.opacity = fill * stuck; sg.clip(to: wp)
            DR.hatch(&sg, wp, in: CGRect(x: win.minX, y: win.minY, width: win.width, height: max(0, top - win.minY)), spacing: 4, alpha: 0.42)
        }
        var t = Path()
        for i in 1..<max(ticks, 2) {
            let y = win.minY + win.height * Double(i) / Double(ticks)
            t.move(to: pt(win.minX, y)); t.addLine(to: pt(win.minX + (i % 2 == 0 ? 7 : 4), y))
        }
        DR.draw(&c, t, p: on, width: DR.hair, color: DR.ink.opacity(0.6))
        DR.draw(&c, wp, p: on, width: DR.hair + 0.2)
    }

    /// A phone standing on its bottom edge: 92 wide, 184 tall, with side buttons, an island and a home bar. `dark` 0...1 turns the screen off.
    /// `icon` 0...1 shows a battery icon on the screen with `level` 0...1 of yellow in it (white outline once the screen is dark).
    static func phone(_ c: inout GraphicsContext, on: Double, fill: Double, dark: Double, icon: Double, level: Double) {
        let w = 92.0, h = 184.0
        let r = CGRect(x: -w / 2, y: -h, width: w, height: h)
        block(&c, r, radius: 15, dx: 9, dy: -6, on: on, fill: fill)
        var g = c; g.opacity = fill
        for (y0, hh) in [(-146.0, 20.0), (-118.0, 13.0), (-100.0, 13.0)] {
            let b = Path(roundedRect: CGRect(x: r.minX - 3, y: y0, width: 3, height: hh), cornerRadius: 1.2)
            g.fill(b, with: .color(DR.side)); DR.draw(&c, b, p: on, width: DR.hair)
        }
        let sc = r.insetBy(dx: 6, dy: 6)
        let screen = Path(roundedRect: sc, cornerRadius: 10)
        g.fill(screen, with: .color(DR.side))
        g.fill(screen, with: .color(DR.ink.opacity(0.94 * dark)))
        var glare = g; glare.opacity = fill * (1 - dark)
        DR.hatch(&glare, screen, in: CGRect(x: sc.minX, y: sc.minY, width: 34, height: 34), spacing: 5, alpha: 0.14)
        DR.draw(&c, screen, p: on, width: DR.hair + 0.2)
        g.fill(Path(roundedRect: CGRect(x: -14, y: sc.minY + 7, width: 28, height: 8), cornerRadius: 4), with: .color(DR.ink))
        g.fill(Path(roundedRect: CGRect(x: -16, y: sc.maxY - 8, width: 32, height: 3), cornerRadius: 1.5),
               with: .color(dark > 0.5 ? Color.white.opacity(0.3) : DR.ink.opacity(0.45)))
        if icon > 0.001 {
            var ig = c; ig.opacity = fill * icon
            let line = dark > 0.5 ? Color.white : DR.ink
            let b = CGRect(x: -26, y: -h / 2 - 13, width: 50, height: 26)
            if level > 0.001 {
                ig.fill(Path(roundedRect: CGRect(x: b.minX + 3, y: b.minY + 3, width: (b.width - 6) * BP.cl(level), height: b.height - 6), cornerRadius: 3),
                        with: .color(DR.accent))
            }
            ig.stroke(Path(roundedRect: b, cornerRadius: 6), with: .color(line), lineWidth: 1.6)
            ig.fill(Path(roundedRect: CGRect(x: b.maxX + 2, y: b.midY - 5, width: 4, height: 10), cornerRadius: 1.5), with: .color(line))
        }
    }

    /// A battery cell standing upright: 80 wide, 150 tall, thick to the right, a terminal on top and a window showing the charge.
    /// `level` 0...1 is the yellow charge; `stuck` 0...1 hatches the empty part above it ("still there, just out of reach").
    static func battery(_ c: inout GraphicsContext, on: Double, fill: Double, level: Double, stuck: Double) {
        let w = 80.0, h = 150.0
        let r = CGRect(x: -w / 2, y: -h, width: w, height: h)
        block(&c, r, radius: 12, dx: 8, dy: -6, on: on, fill: fill)
        block(&c, CGRect(x: -14, y: -h - 10, width: 28, height: 11), radius: 3, dx: 6, dy: -4, on: on, fill: fill)
        window(&c, r.insetBy(dx: 9, dy: 9), radius: 7, on: on, fill: fill, level: level, stuck: stuck, grey: false, ticks: 4)
    }

    /// A tall glass tube with tick marks: 40 wide, 170 tall. `level` 0...1; `grey` shows a grey level instead of yellow.
    static func meter(_ c: inout GraphicsContext, on: Double, fill: Double, level: Double, grey: Bool) {
        let w = 40.0, h = 170.0
        let r = CGRect(x: -w / 2, y: -h, width: w, height: h)
        block(&c, r, radius: 8, dx: 7, dy: -5, on: on, fill: fill)
        window(&c, r.insetBy(dx: 6, dy: 6), radius: 5, on: on, fill: fill, level: level, stuck: 0, grey: grey, ticks: 10)
    }

    /// A glass tank of liquid: 140 wide, `h` tall (136 by default), thick to the right. `thick` 0...1 thickens the liquid (denser hatching).
    static func tank(_ c: inout GraphicsContext, on: Double, fill: Double, thick: Double, h: Double = 136) {
        let w = 140.0
        let r = CGRect(x: -w / 2, y: -h, width: w, height: h)
        block(&c, r, radius: 10, dx: 10, dy: -7, on: on, fill: fill)
        var g = c; g.opacity = fill
        let inner = r.insetBy(dx: 6, dy: 6)
        let liquid = Path(roundedRect: CGRect(x: inner.minX, y: inner.minY + 22, width: inner.width, height: inner.height - 22), cornerRadius: 6)
        g.fill(liquid, with: .color(DR.side))
        DR.hatch(&g, liquid, in: liquid.boundingRect, spacing: 9 - 6 * thick, alpha: 0.16 + 0.4 * thick)
        var surface = Path()
        for i in 0...24 {
            let x = inner.minX + inner.width * Double(i) / 24, y = inner.minY + 22 + 1.6 * sin(Double(i) * 0.9)
            if i == 0 { surface.move(to: pt(x, y)) } else { surface.addLine(to: pt(x, y)) }
        }
        DR.draw(&c, surface, p: on, width: DR.hair + 0.2)
        DR.draw(&c, Path(roundedRect: inner, cornerRadius: 6), p: on, width: DR.hair, color: DR.ink.opacity(0.5))
        var shine = Path()
        shine.move(to: pt(inner.minX + 7, inner.minY + 30)); shine.addLine(to: pt(inner.minX + 7, inner.minY + 62))
        DR.draw(&c, shine, p: on, width: DR.hair + 0.3, color: DR.ink.opacity(0.3))
    }

    /// A snowflake centred at the origin, six arms with two side branches each, `size` the arm length.
    static func snowflake(_ c: inout GraphicsContext, on: Double, size: Double) {
        var p = Path()
        for i in 0..<6 {
            let a = Double(i) * .pi / 3
            let d = pt(cos(a), sin(a))
            p.move(to: .zero); p.addLine(to: pt(d.x * size, d.y * size))
            for f in [0.55, 0.8] {
                let b = pt(d.x * size * f, d.y * size * f)
                for s in [-1.0, 1.0] {
                    let a2 = a + s * 0.7
                    p.move(to: b); p.addLine(to: pt(b.x + cos(a2) * size * 0.28, b.y + sin(a2) * size * 0.28))
                }
            }
        }
        DR.draw(&c, p, p: on, width: DR.hair + 0.3, color: DR.ink.opacity(0.75))
    }

    /// The ground: a firm line and a hairline under it, `w` wide and centred on the origin.
    static func ground(_ c: inout GraphicsContext, w: Double, on: Double) {
        var a = Path(); a.move(to: pt(-w / 2, 0)); a.addLine(to: pt(w / 2, 0))
        var b = Path(); b.move(to: pt(-w / 2, 5)); b.addLine(to: pt(w / 2, 5))
        DR.draw(&c, a, p: on, width: DR.line + 0.4)
        DR.draw(&c, b, p: on, width: DR.hair, color: DR.ink.opacity(0.45))
    }
}
