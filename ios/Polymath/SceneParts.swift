import SwiftUI

// The parts a scene file can name (tasks/scene-format.md). Each part draws in its own frame, at the origin unless it says otherwise,
// from a few numbers (`params`) plus the draw-on (`on`), the fill fade (`fill`) and a free-running `clock` for loops. Add a part here
// once and every scene can use it; keep the names stable, since scene files refer to them.

struct ScenePart {
    let p: [String: Double]
    let on: Double
    let fill: Double
    let clock: Double
    subscript(_ key: String, default d: Double) -> Double { p[key] ?? d }
}

enum SceneParts {
    /// Every part's name, for the checker (`tools/scene/scene.py`), which reads this list from the source.
    static let names = ["glueTube", "bead", "waterDrop", "tear", "skin", "waterFilm", "calendar", "stopwatch", "plank",
                        "playingCard", "chips",
                        "terminal", "card", "heldCard", "envelope", "bank", "network", "shop", "yes", "slip"]

    static func draw(_ name: String, _ c: inout GraphicsContext, _ q: ScenePart) {
        switch name {
        case "glueTube":       // in its own frame, about x 22...187, y 89...151
            DR.glueTube(&c, on: q.on, fill: q.fill, clock: q.clock,
                        capOffset: CGSize(width: q["capX", default: 0], height: q["capY", default: 0]), capTurn: q["capTurn", default: 0],
                        tipGlue: q["tipGlue", default: 0], tipHard: q["tipHard", default: 0])
        case "bead":           // bottom centre at the origin; w half-width, h height, hard 0...1, fromBottom 0 or 1, yellow 1 or 0
            DR.bead(&c, base: .zero, w: q["w", default: 14], h: q["h", default: 18], yellow: q["yellow", default: 1] > 0.5,
                    hard: q["hard", default: 0], fromBottom: q["fromBottom", default: 0] > 0.5)
        case "waterDrop":      // centred at the origin
            DR.waterDrop(&c, at: .zero, size: q["size", default: 5], alpha: q["alpha", default: 1])
        case "tear":           // a falling drop of glue, centred at the origin
            DR.tear(&c, size: q["size", default: 10])
        case "skin":           // a cut through skin from x0 to x1: ridged top at `surface`, shaded and celled below, down to `bottom`
            DR.skin(&c, x0: q["x0", default: 0], x1: q["x1", default: 200], surface: q["surface", default: 0], ridge: q["ridge", default: 5],
                    bottom: q["bottom", default: 80], fill: q.fill)
        case "waterFilm":      // a thin dashed film of water hugging the same ridges, shimmering
            DR.waterFilm(&c, x0: q["x0", default: 0], x1: q["x1", default: 200], surface: q["surface", default: 0], ridge: q["ridge", default: 5],
                         clock: q.clock, fill: q.fill)
        case "calendar":       // a desk calendar, top left at the origin; `page` counts months turned (0...3: MAY to AUG)
            DR.calendar(&c, page: q["page", default: 0], on: q.on, fill: q.fill)
        case "stopwatch":      // centred at the origin; `seconds` 0...12 sweeps the hand, `readout` 0...1 shows "3 s" under it
            DR.stopwatch(&c, seconds: q["seconds", default: 0], readout: q["readout", default: 0], on: q.on, fill: q.fill)
        case "plank":          // a wooden plank from the origin, w wide and h tall, with grain
            DR.plank(&c, w: q["w", default: 300], h: q["h", default: 26], on: q.on, fill: q.fill)
        case "playingCard":    // a playing card centred at the origin, 30 x 42; rank 2...14 (11 J, 12 Q, 13 K, 14 A), suit 0 spades,
                               // 1 hearts, 2 diamonds, 3 clubs; up 0 face down ... 1 face up (it turns over); lit 0...1 yellow face
            DR.playingCard(&c, rank: Int(q["rank", default: 14]), suit: Int(q["suit", default: 0]), up: q["up", default: 1],
                           lit: q["lit", default: 0], on: q.on, fill: q.fill)
        case "chips":          // a stack of n chips, bottom centre at the origin; n can grow or shrink smoothly
            DR.chips(&c, n: q["n", default: 3], on: q.on, fill: q.fill)
        case "terminal": DR.terminal(&c, at: .zero, on: q.on, fill: q.fill)
        case "card": DR.card(&c, at: .zero, on: q.on, fill: q.fill)
        case "heldCard": DR.heldCard(&c, at: .zero, on: q.on, fill: q.fill)
        case "envelope": DR.envelope(&c, at: .zero, alpha: q.fill)
        case "bank": DR.bank(&c, cx: 0, base: 0, on: q.on, fill: q.fill)
        case "network": DR.network(&c, at: .zero, on: q.on, fill: q.fill)
        case "shop": DR.shop(&c, cx: 0, base: 0, on: q.on, fill: q.fill, tray: q["tray", default: 1] > 0.5)
        case "yes": DR.yes(&c, at: .zero, alpha: q.fill, word: q["word", default: 1] > 0.5)
        case "slip": DR.slip(&c, at: .zero, big: q["big", default: 0] > 0.5, set: q["set", default: 0], alpha: q.fill)
        default: break
        }
    }
}

// MARK: - Parts made for the superglue scenes, drawn as in the hand-written pictures

extension DR {
    private static func q(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    /// A falling drop of glue: a yellow teardrop with an outline, centred at the origin.
    static func tear(_ c: inout GraphicsContext, size s: Double) {
        var d = Path()
        d.move(to: q(0, -s))
        d.addCurve(to: q(0, s), control1: q(s, 0.1 * s), control2: q(0.8 * s, s))
        d.addCurve(to: q(0, -s), control1: q(-0.8 * s, s), control2: q(-s, 0.1 * s))
        c.fill(d, with: .color(accent)); c.stroke(d, with: .color(ink), lineWidth: line)
    }

    private static func ridge(_ x: Double, _ surface: Double, _ amp: Double) -> Double { surface + amp * sin(x * 0.09) }

    /// A cut through skin: ridged top, shaded deeper down, a few cell outlines.
    static func skin(_ c: inout GraphicsContext, x0: Double, x1: Double, surface: Double, ridge amp: Double, bottom: Double, fill: Double) {
        guard fill > 0 else { return }
        var g = c; g.opacity *= fill
        var flesh = Path(); flesh.move(to: q(x0, bottom))
        for i in 0...40 { let x = x0 + (x1 - x0) * Double(i) / 40; flesh.addLine(to: q(x, ridge(x, surface, amp))) }
        flesh.addLine(to: q(x1, bottom)); flesh.closeSubpath()
        g.fill(flesh, with: .color(side))
        hatch(&g, flesh, in: CGRect(x: x0, y: bottom - 46, width: x1 - x0, height: 46), spacing: 4, alpha: 0.3)
        var cells = Path()
        let w = x1 - x0
        for (fx, dy) in [(0.19, 22.0), (0.35, 28), (0.51, 21), (0.68, 27), (0.84, 22), (0.27, 44), (0.6, 46), (0.76, 48)] {
            let x = x0 + w * fx, y = surface + dy
            cells.addEllipse(in: CGRect(x: x - 11, y: y - 6, width: 22, height: 12))
        }
        g.stroke(cells, with: .color(ink.opacity(0.25)), lineWidth: hair)
        var top = Path()
        for i in 0...40 { let x = x0 + (x1 - x0) * Double(i) / 40; let p = q(x, ridge(x, surface, amp)); if i == 0 { top.move(to: p) } else { top.addLine(to: p) } }
        g.stroke(top, with: .color(ink), lineWidth: line)
    }

    /// A thin film of water on the same ridges: a dashed line just above them, gently shimmering, and a row of dots.
    static func waterFilm(_ c: inout GraphicsContext, x0: Double, x1: Double, surface: Double, ridge amp: Double, clock: Double, fill: Double) {
        guard fill > 0 else { return }
        var g = c; g.opacity *= fill
        var film = Path()
        for i in 0...40 {
            let x = x0 + (x1 - x0) * Double(i) / 40
            let p = q(x, ridge(x, surface, amp) - 4 - 0.6 * sin(clock * 2 + x * 0.2))
            if i == 0 { film.move(to: p) } else { film.addLine(to: p) }
        }
        g.stroke(film, with: .color(ink.opacity(0.7)), style: StrokeStyle(lineWidth: hair, dash: [2.5, 2]))
        var dots = Path()
        var x = x0 + 10
        while x < x1 - 4 { dots.addEllipse(in: CGRect(x: x - 0.9, y: ridge(x, surface, amp) - 2.9, width: 1.8, height: 1.8)); x += 14.5 }
        g.fill(dots, with: .color(ink.opacity(0.5)))
    }

    /// A desk calendar, 56 x 50, top left at the origin. `page` 0...3 turns MAY to AUG; each turn lifts and folds the old page back.
    static func calendar(_ c: inout GraphicsContext, page: Double, on: Double, fill: Double) {
        let months = ["MAY", "JUN", "JUL", "AUG"]
        let cal = CGRect(x: 0, y: 0, width: 56, height: 50)
        var g = c; g.opacity *= fill
        let sheet = Path(roundedRect: cal, cornerRadius: 4)
        g.fill(sheet, with: .color(face)); draw(&c, sheet, p: on)
        var band = Path(); band.move(to: q(0, 12)); band.addLine(to: q(cal.maxX, 12))
        draw(&c, band, p: on)
        for x in [15.0, cal.maxX - 15] { draw(&c, Path(roundedRect: CGRect(x: x - 2.5, y: -5, width: 5, height: 10), cornerRadius: 2.5), p: on) }
        let shown = min(3, Int(page.rounded(.down)))
        let turning = page - Double(shown)
        if fill > 0 {
            let m = c.resolve(Text(months[min(3, shown + (turning > 0 ? 1 : 0))]).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(ink))
            g.draw(m, at: q(cal.midX, 31), anchor: .center)
        }
        if turning > 0, shown < 3 {
            let h = (cal.height - 12) * (1 - BP.eio(turning))
            let old = Path(roundedRect: CGRect(x: 0, y: 12, width: cal.width, height: max(1, h)), cornerRadius: 3)
            c.fill(old, with: .color(face)); c.stroke(old, with: .color(ink), lineWidth: line)
            if h > 20 {
                let m = c.resolve(Text(months[shown]).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(ink))
                c.draw(m, at: q(cal.midX, 12 + h / 2), anchor: .center)
            }
        }
    }

    /// A stopwatch of radius 17, centred at the origin. `seconds` (0...12) sweeps the hand with a yellow wedge behind it.
    static func stopwatch(_ c: inout GraphicsContext, seconds: Double, readout: Double, on: Double, fill: Double) {
        let r = 17.0
        let face = Path(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r))
        var g = c; g.opacity *= fill
        g.fill(face, with: .color(self.face)); draw(&c, face, p: on)
        draw(&c, Path(roundedRect: CGRect(x: -3.5, y: -r - 6, width: 7, height: 5), cornerRadius: 1.5), p: on)
        var ticks = Path()
        for i in 0..<12 { let a = Double(i) / 12 * 2 * .pi; ticks.move(to: q((r - 4) * sin(a), -(r - 4) * cos(a))); ticks.addLine(to: q((r - 2) * sin(a), -(r - 2) * cos(a))) }
        draw(&c, ticks, p: on, width: hair)
        let sweep = seconds / 12 * 2 * .pi
        if sweep > 0.001 {
            var wedge = Path(); wedge.move(to: .zero)
            wedge.addArc(center: .zero, radius: r - 5, startAngle: .radians(-.pi / 2), endAngle: .radians(-.pi / 2 + sweep), clockwise: false)
            wedge.closeSubpath()
            c.fill(wedge, with: .color(accent.opacity(0.85)))
        }
        var hand = Path(); hand.move(to: .zero); hand.addLine(to: q((r - 5) * sin(sweep), -(r - 5) * cos(sweep)))
        draw(&c, hand, p: on)
        if readout > 0 {
            let lbl = c.resolve(Text("\(Int(seconds.rounded())) s").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundColor(ink))
            var lc = c; lc.opacity *= readout
            lc.draw(lbl, at: q(0, r + 9), anchor: .center)
        }
    }

    /// A wooden plank seen from the side, top left at the origin, with three wavy grain lines and shade along the bottom.
    static func plank(_ c: inout GraphicsContext, w: Double, h: Double, on: Double, fill: Double) {
        let plank = Path(roundedRect: CGRect(x: 0, y: 0, width: w, height: h), cornerRadius: 3)
        var g = c; g.opacity *= fill
        g.fill(plank, with: .color(face)); hatch(&g, plank, in: CGRect(x: 0, y: h - 8, width: w, height: 8))
        draw(&c, plank, p: on)
        var grain = Path()
        for (y0, k) in [(7.0, 0.0), (13.0, 1.3), (19.0, 2.4)] where y0 < h - 3 {
            grain.move(to: q(12, y0))
            for i in 1...20 { let x = 12 + (w - 24) * Double(i) / 20; grain.addLine(to: q(x, y0 + 1.6 * sin((x + 18) * 0.045 + k))) }
        }
        draw(&c, grain, p: on, width: hair, color: ink.opacity(0.4))
    }

    // MARK: playing cards and chips (made for poker)

    /// A playing card, 30 x 42, centred at the origin. Turning over squeezes it to an edge and back, showing the hatched back first.
    static func playingCard(_ c: inout GraphicsContext, rank: Int, suit: Int, up: Double, lit: Double, on: Double, fill: Double) {
        let w = 30.0, h = 42.0
        let turn = BP.cl(up), squeeze = abs(cos(turn * .pi))
        var g = c
        g.scaleBy(x: max(0.02, squeeze), y: 1)
        let card = Path(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerRadius: 3.5)
        var f = g; f.opacity *= fill
        let faceUp = turn >= 0.5
        f.fill(card, with: .color(faceUp && lit > 0 ? accent.opacity(lit) : face))
        if faceUp && lit < 1 { f.fill(card, with: .color(face.opacity(1 - lit))); if lit > 0 { f.fill(card, with: .color(accent.opacity(lit))) } }
        if !faceUp {
            let inner = Path(roundedRect: CGRect(x: -w / 2 + 3.5, y: -h / 2 + 3.5, width: w - 7, height: h - 7), cornerRadius: 2)
            hatch(&f, inner, in: inner.boundingRect, spacing: 2.6, alpha: 0.45)
            f.stroke(inner, with: .color(ink.opacity(0.5)), lineWidth: hair)
        }
        draw(&g, card, p: on)
        guard faceUp, fill > 0 else { return }
        let ranks = [2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8", 9: "9", 10: "10", 11: "J", 12: "Q", 13: "K", 14: "A"]
        let suits = ["♠", "♥", "♦", "♣"]
        let sym = suits[max(0, min(3, suit))]
        var t = g; t.opacity *= fill
        let r = t.resolve(Text(ranks[rank] ?? "?").font(.system(size: 9.5, weight: .bold, design: .rounded)).foregroundColor(ink))
        t.draw(r, at: CGPoint(x: -w / 2 + 3.5, y: -h / 2 + 3), anchor: .topLeading)
        let small = t.resolve(Text(sym).font(.system(size: 7.5)).foregroundColor(ink))
        t.draw(small, at: CGPoint(x: -w / 2 + 3.5, y: -h / 2 + 14), anchor: .topLeading)
        let big = t.resolve(Text(sym).font(.system(size: 17)).foregroundColor(ink))
        t.draw(big, at: CGPoint(x: 2, y: 4), anchor: .center)
    }

    /// A stack of chips seen a little from above, bottom centre at the origin: each chip an outlined disc, 3 apart. The top one is yellow.
    static func chips(_ c: inout GraphicsContext, n: Double, on: Double, fill: Double) {
        let count = Int(n.rounded(.up)), rx = 10.0, ry = 3.6, step = 3.2
        guard count > 0 else { return }
        for i in 0..<count {
            let y = -Double(i) * step
            let top = i == count - 1
            var side = Path()
            side.move(to: q(-rx, y - step)); side.addLine(to: q(-rx, y))
            side.addArc(center: q(0, y), radius: rx, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            side.addLine(to: q(rx, y - step))
            var g = c; g.opacity *= fill
            g.fill(Path(ellipseIn: CGRect(x: -rx, y: y - ry, width: 2 * rx, height: 2 * ry)), with: .color(face))
            g.fill(Path(CGRect(x: -rx, y: y - step, width: 2 * rx, height: step)), with: .color(side.isEmpty ? face : self.side))
            draw(&c, side, p: on, width: hair + 0.2)
            if top {
                let disc = Path(ellipseIn: CGRect(x: -rx, y: y - step - ry, width: 2 * rx, height: 2 * ry))
                g.fill(disc, with: .color(accent))
                draw(&c, disc, p: on, width: hair + 0.2)
                let inner = Path(ellipseIn: CGRect(x: -rx * 0.55, y: y - step - ry * 0.55, width: rx * 1.1, height: ry * 1.1))
                draw(&c, inner, p: on, width: hair, dash: [2, 1.6])
            }
        }
    }
}
