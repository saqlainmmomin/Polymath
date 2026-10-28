import SwiftUI

// "Why doesn't instant glue stick inside its own tube?" topic. First hand-drawn style sample, 2026-10-27: card 1 only.
// Paper background, wobbly ink lines that "boil" (redraw with a fresh wobble) eight times a second like cartoon frames,
// a second faint pencil pass, marker and handwriting lettering. Cards 2-4 (GlueTwo, GlueFilm, GlueCap) follow below.

private func cl(_ x: Double) -> Double { min(1, max(0, x)) }
private func pr(_ t: Double, _ a: Double, _ b: Double) -> Double { cl((t - a) / (b - a)) }
private func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
private func mix(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }

private enum G {
    static let ink = Color(hex: 0x2B2420)
    static let tube = Color(hex: 0xF4C64F), band = Color(hex: 0xE5533D), cap = Color(hex: 0xE5533D)
    static let glue = Color(hex: 0xBFE3F2), glueHi = Color(hex: 0xF4FBFF)
    static let skin = Color(hex: 0xF6BE98), nail = Color(hex: 0xFFE2D0)
    static let page = Color(hex: 0xFFFDF7)
    // set glue: a cloudier, yellowish white
    static func drop(_ k: Double) -> Color {
        Color(red: mix(0.75, 0.93, k), green: mix(0.89, 0.86, k), blue: mix(0.95, 0.68, k))
    }
}

// MARK: - Card 1: a tube that says SUPERGLUE turns see-through and its glue sloshes, runny for months; a drop on a fingertip goes hard in seconds

struct GlueTube: View {
    let active: Bool
    private static let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN"]

    var body: some View {
        FlatPicture(active: active, period: 10, still: 8.6, cues: [Cue(1.9, .soft), Cue(4.4, .rigid), Cue(5.5, .light)], replayOnTap: true, sky: Sketch.paper,
                    label: "A hand-drawn tube of glue with SUPERGLUE written on it, next to an open hand. A drop of glue falls on a fingertip, a stopwatch counts three seconds, and the drop goes hard. Then the tube turns see-through: the glue inside is still runny and sloshes as the tube rocks, while a calendar flips from January to June. Labels say: on your finger, hard in seconds; in the tube, runny for months.") { ctx, s, t, _ in
            draw(&ctx, s, t)
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ t: Double) {
        let w = s.width, h = s.height
        let u = min(w / 343, h / 320)
        ctx.opacity = 1 - pr(t, 9.4, 10)
        let pen = eio(pr(t, 0.1, 1.4))   // lines drawn on at the start

        // ---- the hand and its drop (right): an open hand from the bottom edge, the drop on the middle fingertip
        let hx = w * 0.74, tipY = h * 0.54, palmTop = h * 0.74, fwd = 17 * u
        let fx = hx - 9 * u
        let skin = G.skin.opacity(pr(t, 0.6, 1.4))
        // fingers first (the palm covers their bases): offset from the hand's centre, how far below the tallest tip, lean in degrees
        let fingers: [(dx: Double, drop: Double, ang: Double)] = [(-28, 10, -6), (-9, 0, 0), (9, 8, 4), (28, 26, 10)]
        for (i, f) in fingers.enumerated() {
            let base = CGPoint(x: hx + f.dx * u, y: palmTop + 12 * u)
            let len = base.y - (tipY + f.drop * u)
            Sketch.ink(&ctx, Sketch.digit(base, len: len, wd: fwd, angle: f.ang), closed: false, t: t, seed: 11 + i * 3, fill: skin, drawn: pen)
            for (j, k) in [0.42, 0.62].enumerated() {   // knuckle creases
                let a = f.ang * .pi / 180, ux = sin(a), uy = -cos(a), nx = cos(a), ny = sin(a)
                let p = CGPoint(x: base.x + ux * len * (1 - k), y: base.y + uy * len * (1 - k))
                Sketch.ink(&ctx, [CGPoint(x: p.x - nx * fwd * 0.28, y: p.y - ny * fwd * 0.28), CGPoint(x: p.x + nx * fwd * 0.28, y: p.y + ny * fwd * 0.28)],
                           closed: false, t: t, seed: 12 + i * 3 + j, width: 1.1, drawn: pen)
            }
        }
        Sketch.ink(&ctx, Sketch.digit(CGPoint(x: hx - 30 * u, y: palmTop + 36 * u), len: 48 * u, wd: 20 * u, angle: -55), closed: false, t: t, seed: 26,
                   fill: skin, drawn: pen)
        // the palm: filled, with only its sides inked so the fingers and thumb flow out of it
        Sketch.ink(&ctx, [CGPoint(x: hx - 38 * u, y: palmTop), CGPoint(x: hx + 38 * u, y: palmTop + 6 * u), CGPoint(x: hx + 41 * u, y: h + 14),
                          CGPoint(x: hx - 41 * u, y: h + 14)], closed: true, t: t, seed: 27, fill: skin, drawn: 0)
        Sketch.ink(&ctx, [CGPoint(x: hx + 38 * u, y: palmTop + 4 * u), CGPoint(x: hx + 41 * u, y: h + 14)], closed: false, t: t, seed: 28, drawn: pen)
        Sketch.ink(&ctx, [CGPoint(x: hx - 38 * u, y: palmTop), CGPoint(x: hx - 38.5 * u, y: palmTop + 20 * u)], closed: false, t: t, seed: 29, drawn: pen)
        Sketch.ink(&ctx, [CGPoint(x: hx - 39 * u, y: palmTop + 50 * u), CGPoint(x: hx - 41 * u, y: h + 14)], closed: false, t: t, seed: 30, drawn: pen)
        for i in 0..<3 {   // the skin between fingers
            let a = hx + fingers[i].dx * u + fwd / 2, b = hx + fingers[i + 1].dx * u - fwd / 2
            Sketch.ink(&ctx, [CGPoint(x: a, y: palmTop + 1), CGPoint(x: (a + b) / 2, y: palmTop + 4 * u), CGPoint(x: b, y: palmTop + 1)], closed: false,
                       t: t, seed: 31 + i, width: 1.8, drawn: pen)
        }
        Sketch.ink(&ctx, [CGPoint(x: hx - 24 * u, y: palmTop + 22 * u), CGPoint(x: hx, y: palmTop + 30 * u), CGPoint(x: hx + 26 * u, y: palmTop + 24 * u)],
                   closed: false, t: t, seed: 34, width: 1.2, color: G.ink.opacity(0.6), drawn: pen)

        // the drop: falls (1.5-1.9), squashes on landing, wobbles while runny, goes hard (3.8-4.6)
        let fall = pr(t, 1.5, 1.9), hard = eio(pr(t, 3.8, 4.6))
        if t > 1.5 {
            let land = pr(t, 1.9, 2.25)
            let squash = sin(land * .pi) * 0.25
            let jig = (1 - hard) * pr(t, 1.9, 2.0) * 0.06 * sin(t * 11)
            let rx = 16 * u * (1 + squash + jig), ry = 11 * u * (1 - squash - jig)
            let c = fall < 1 ? CGPoint(x: fx, y: mix(-20, tipY - 4 * u, eio(fall) * eio(fall))) : CGPoint(x: fx, y: tipY - 4 * u)
            let pts = fall < 1 ? Sketch.oval(c, 7 * u, 10 * u, n: 18) : Sketch.oval(c, rx, ry, n: 26)
            let shape = Sketch.path(pts, closed: true, t: t, seed: 21)
            Sketch.ink(&ctx, pts, closed: true, t: t, seed: 21, width: 2, fill: G.drop(hard))
            if hard < 0.6 {   // a wet shine while runny
                Sketch.ink(&ctx, [CGPoint(x: c.x - rx * 0.45, y: c.y - ry * 0.25), CGPoint(x: c.x - rx * 0.1, y: c.y - ry * 0.55)], closed: false,
                           t: t, seed: 22, width: 2.2, color: G.glueHi.opacity(1 - hard / 0.6))
            }
            if hard > 0.01 {   // pencil hatching once it is hard
                ctx.drawLayer { l in
                    l.clip(to: shape)
                    l.opacity = hard
                    for i in 0..<7 {
                        let x0 = c.x - rx + Double(i) * rx * 0.36
                        Sketch.ink(&l, [CGPoint(x: x0, y: c.y + ry), CGPoint(x: x0 + ry * 1.6, y: c.y - ry)], closed: false, t: t, seed: 30 + i,
                                   width: 1, color: G.ink.opacity(0.55), amp: 0.5)
                    }
                }
            }
            let pop = pr(t, 4.4, 4.7)   // cartoon "it set" marks
            if pop > 0 {
                for (i, a) in [-2.4, -1.57, -0.74].enumerated() {
                    let r0 = rx + 6 * u, r1 = rx + (8 + 8 * pop) * u
                    Sketch.ink(&ctx, [CGPoint(x: c.x + r0 * cos(a), y: c.y + r0 * sin(a) * 0.9), CGPoint(x: c.x + r1 * cos(a), y: c.y + r1 * sin(a) * 0.9)],
                               closed: false, t: t, seed: 40 + i, width: 2, color: G.ink.opacity(pop))
                }
            }
        }

        // the stopwatch: counts from the landing until the drop is hard
        let swA = pr(t, 1.9, 2.3)
        if swA > 0 {
            let c = CGPoint(x: fx - 58 * u, y: h * 0.36), r = 17 * u
            var l = ctx; l.opacity = swA
            Sketch.ink(&l, Sketch.oval(c, r, r, n: 24), closed: true, t: t, seed: 50, width: 2, fill: G.page)
            Sketch.ink(&l, [CGPoint(x: c.x - 3 * u, y: c.y - r - 5 * u), CGPoint(x: c.x + 3 * u, y: c.y - r - 5 * u)], closed: false, t: t, seed: 51, width: 3)
            let secs = min(3, max(0, (t - 2.0) / 0.8))
            let a = -Double.pi / 2 + secs * 2 * .pi
            Sketch.ink(&l, [c, CGPoint(x: c.x + r * 0.75 * cos(a), y: c.y + r * 0.75 * sin(a))], closed: false, t: t, seed: 52, width: 2, color: G.band)
            Sketch.say(&l, "\(Int(secs.rounded(.down)))s", CGPoint(x: c.x, y: c.y + r + 12 * u), size: 13 * u, t: t, seed: 53)
        }
        Sketch.say(&ctx, "On your finger:", CGPoint(x: fx - 8 * u, y: 14 * u), size: 15 * u, t: t, seed: 60, alpha: pr(t, 4.6, 5.0), anchor: .top)
        Sketch.say(&ctx, "hard in seconds", CGPoint(x: fx - 8 * u, y: 34 * u), size: 15 * u, t: t, seed: 61, color: G.band, alpha: pr(t, 4.6, 5.0), anchor: .top)

        // ---- the tube (left): drawn with its label, turns see-through (5.0-6.0), then rocks so the runny glue sloshes
        let tx = w * 0.25, hw = 30 * u, yT = h * 0.33, yB = h * 0.74
        let clear = eio(pr(t, 5.0, 6.0))
        let rock = 6 * sin((t - 6.0) * 2.2) * pr(t, 6.0, 6.6) * (1 - pr(t, 8.6, 9.2))
        ctx.drawLayer { l in
            l.translateBy(x: tx, y: yB + 10 * u)
            l.rotate(by: .degrees(rock))
            l.translateBy(x: -tx, y: -(yB + 10 * u))
            let body = [CGPoint(x: tx - hw, y: yT), CGPoint(x: tx + hw, y: yT), CGPoint(x: tx + hw * 1.08, y: yB), CGPoint(x: tx - hw * 1.08, y: yB)]
            // the glue inside, under the wrapper: its surface stays level while the tube rocks, and ripples
            let lag = 6 * sin((t - 6.25) * 2.2) * pr(t, 6.2, 6.8) * (1 - pr(t, 8.6, 9.2))
            let slope = tan(-lag * .pi / 180), level = yT + 26 * u
            var glue: [CGPoint] = stride(from: tx - hw + 2, through: tx + hw - 2, by: 4).map { x in
                CGPoint(x: x, y: level + (x - tx) * slope + 2 * u * sin(x / (8 * u) + t * 4) * pr(t, 5.6, 6.2))
            }
            glue += [CGPoint(x: tx + hw * 1.06 - 2, y: yB - 2), CGPoint(x: tx - hw * 1.06 + 2, y: yB - 2)]
            if clear > 0.01 {
                Sketch.ink(&l, glue, closed: true, t: t, seed: 70, width: 1.6, color: G.ink.opacity(0.7 * clear), fill: G.glue.opacity(0.9 * clear))
                for i in 0..<3 {   // slow bubbles: it is a liquid
                    let ph = (t * 0.25 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                    let p = CGPoint(x: tx + (Double(i) - 1) * hw * 0.5, y: mix(yB - 10 * u, level + 8 * u, ph))
                    Sketch.ink(&l, Sketch.oval(p, 2.6 * u, 2.6 * u, n: 10), closed: true, t: t, seed: 75 + i, width: 1.1, color: G.ink.opacity(0.5 * clear * (1 - ph)))
                }
            }
            let wrap = 1 - 0.88 * clear
            // the body, shoulder, crimped end and cap
            Sketch.ink(&l, body, closed: true, t: t, seed: 80, fill: G.tube.opacity(wrap * pr(t, 0.6, 1.4)), drawn: pen)
            Sketch.ink(&l, [CGPoint(x: tx - hw, y: yT), CGPoint(x: tx - hw * 0.32, y: yT - 18 * u), CGPoint(x: tx + hw * 0.32, y: yT - 18 * u), CGPoint(x: tx + hw, y: yT)],
                       closed: true, t: t, seed: 81, fill: G.tube.opacity(wrap * pr(t, 0.6, 1.4)), drawn: pen)
            Sketch.ink(&l, [CGPoint(x: tx - hw * 1.2, y: yB), CGPoint(x: tx + hw * 1.2, y: yB), CGPoint(x: tx + hw * 1.2, y: yB + 10 * u), CGPoint(x: tx - hw * 1.2, y: yB + 10 * u)],
                       closed: true, t: t, seed: 82, fill: G.tube.opacity(pr(t, 0.6, 1.4)), drawn: pen)
            for i in 0..<5 {
                let x = tx - hw + Double(i + 1) * hw * 2 / 6
                Sketch.ink(&l, [CGPoint(x: x, y: yB + 2 * u), CGPoint(x: x, y: yB + 8 * u)], closed: false, t: t, seed: 83 + i, width: 1.2, drawn: pen)
            }
            let cw = hw * 0.42, cTop = yT - 52 * u, cBot = yT - 18 * u
            Sketch.ink(&l, [CGPoint(x: tx - cw, y: cBot), CGPoint(x: tx - cw, y: cTop + 4 * u), CGPoint(x: tx - cw + 4 * u, y: cTop),
                            CGPoint(x: tx + cw - 4 * u, y: cTop), CGPoint(x: tx + cw, y: cTop + 4 * u), CGPoint(x: tx + cw, y: cBot)],
                       closed: true, t: t, seed: 90, fill: G.cap.opacity(pr(t, 0.6, 1.4)), drawn: pen)
            // the red band with SUPERGLUE written down it
            let band = [CGPoint(x: tx - hw * 0.72, y: yT + 12 * u), CGPoint(x: tx + hw * 0.72, y: yT + 12 * u),
                        CGPoint(x: tx + hw * 0.76, y: yB - 12 * u), CGPoint(x: tx - hw * 0.76, y: yB - 12 * u)]
            Sketch.ink(&l, band, closed: true, t: t, seed: 91, width: 1.8, color: G.ink.opacity(wrap), fill: G.band.opacity(wrap * pr(t, 0.9, 1.5)), drawn: pen)
            Sketch.say(&l, "SUPERGLUE", CGPoint(x: tx, y: (yT + yB) / 2), size: 19 * u, t: t, seed: 92, font: "MarkerFelt-Wide",
                       color: .white, alpha: wrap * pr(t, 1.0, 1.6), angle: -90)
        }

        // the calendar: flips from JAN to JUN while the glue stays runny
        let calA = pr(t, 5.8, 6.2)
        if calA > 0 {
            let c = CGPoint(x: tx + hw + 34 * u, y: h * 0.16), pw = 21 * u, ph = 24 * u
            var l = ctx; l.opacity = calA
            Sketch.ink(&l, [CGPoint(x: c.x - pw, y: c.y - ph), CGPoint(x: c.x + pw, y: c.y - ph), CGPoint(x: c.x + pw, y: c.y + ph), CGPoint(x: c.x - pw, y: c.y + ph)],
                       closed: true, t: t, seed: 100, width: 2, fill: G.page)
            Sketch.ink(&l, [CGPoint(x: c.x - pw, y: c.y - ph), CGPoint(x: c.x + pw, y: c.y - ph), CGPoint(x: c.x + pw, y: c.y - ph * 0.45), CGPoint(x: c.x - pw, y: c.y - ph * 0.45)],
                       closed: true, t: t, seed: 101, width: 2, fill: G.band)
            let k = min(Self.months.count - 1, max(0, Int((t - 6.2) / 0.42)))
            let flip = (t - 6.2) / 0.42 - Double(k)
            let fade = k < Self.months.count - 1 ? 1 - pr(flip, 0.75, 1) : 1
            Sketch.say(&l, Self.months[k], CGPoint(x: c.x, y: c.y + ph * 0.28), size: 16 * u, t: t, seed: 102 + k, alpha: fade)
        }
        Sketch.say(&ctx, "In the tube:", CGPoint(x: tx, y: h - 46 * u), size: 15 * u, t: t, seed: 110, alpha: pr(t, 7.2, 7.6), anchor: .top)
        Sketch.say(&ctx, "runny for months", CGPoint(x: tx, y: h - 26 * u), size: 15 * u, t: t, seed: 111, color: G.band, alpha: pr(t, 7.2, 7.6), anchor: .top)
    }
}

// MARK: - Shared bits for cards 2-4 (drawn in a 343 x 320 design space, scaled to the panel)

private enum GW {
    static let water = Color(hex: 0x7CC4EE), waterDeep = Color(hex: 0x3E8FCB)
    static let wood = Color(hex: 0xF3D9A8), woodDark = Color(hex: 0xDDB178)
    static let orange = Color(hex: 0xF29A3A)
}

private func gp(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

private func gscene(_ ctx: inout GraphicsContext, _ s: CGSize, _ body: (inout GraphicsContext) -> Void) {
    let u = min(s.width / 343, s.height / 320)
    var c = ctx
    c.translateBy(x: (s.width - 343 * u) / 2, y: (s.height - 320 * u) / 2)
    c.scaleBy(x: u, y: u)
    body(&c)
}

/// Handwriting that also follows the loop's fade-out (the context's opacity).
private func gsay(_ ctx: inout GraphicsContext, _ text: String, _ p: CGPoint, size: Double, t: Double, seed: Int, font: String = "Noteworthy-Bold",
                  color: Color = G.ink, alpha: Double = 1, anchor: UnitPoint = .center, angle: Double = 0) {
    Sketch.say(&ctx, text, p, size: size, t: t, seed: seed, font: font, color: color, alpha: alpha * ctx.opacity, anchor: anchor, angle: angle)
}

/// A hand-drawn line or curve ending in an arrowhead.
private func garrow(_ ctx: inout GraphicsContext, _ pts: [CGPoint], t: Double, seed: Int, color: Color = G.ink, drawn: Double = 1) {
    guard drawn > 0.01 else { return }
    Sketch.ink(&ctx, pts, closed: false, t: t, seed: seed, width: 1.8, color: color, drawn: drawn, amp: 0.8)
    guard drawn > 0.95, pts.count >= 2 else { return }
    let b = pts[pts.count - 1], a = pts[pts.count - 2]
    let ang = atan2(b.y - a.y, b.x - a.x)
    for (i, s) in [-1.0, 1.0].enumerated() {
        let q = gp(b.x - 8 * cos(ang + s * 0.5), b.y - 8 * sin(ang + s * 0.5))
        Sketch.ink(&ctx, [b, q], closed: false, t: t, seed: seed + 5 + i, width: 1.8, color: color, amp: 0.3)
    }
}

/// A little water drop (pointed on top) or a round dot of moisture.
private func gblob(_ ctx: inout GraphicsContext, _ c: CGPoint, r: Double, t: Double, seed: Int, fill: Color = GW.water, tear: Bool = false, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    var l = ctx
    l.opacity = ctx.opacity * alpha
    var pts: [CGPoint]
    if tear {
        pts = [gp(c.x, c.y - r * 1.7), gp(c.x + r * 0.7, c.y - r * 0.3), gp(c.x + r, c.y + r * 0.4), gp(c.x, c.y + r * 1.1),
               gp(c.x - r, c.y + r * 0.4), gp(c.x - r * 0.7, c.y - r * 0.3)]
    } else {
        pts = Sketch.oval(c, r, r, n: 10)
    }
    Sketch.ink(&l, pts, closed: true, t: t, seed: seed, width: 1.3, color: G.ink.opacity(0.75), fill: fill, amp: 0.5)
}

/// Pencil hatching inside `clip`, for glue that has gone hard. `op` is the loop's fade.
private func ghatch(_ ctx: inout GraphicsContext, clip: Path, box: CGRect, amount: Double, op: Double, t: Double, seed: Int, gap: Double = 8) {
    guard amount > 0.01 else { return }
    ctx.drawLayer { l in
        l.clip(to: clip)
        l.opacity = op * amount
        let h = box.height
        var x = box.minX - h
        var i = 0
        while x < box.maxX {
            Sketch.ink(&l, [gp(x, box.maxY), gp(x + h, box.minY)], closed: false, t: t, seed: seed + i, width: 1, color: G.ink.opacity(0.55), amp: 0.5)
            x += gap; i += 1
        }
    }
}

/// Cartoon "it set" marks round a puddle.
private func gpop(_ ctx: inout GraphicsContext, c: CGPoint, rx: Double, ry: Double, k: Double, t: Double, seed: Int) {
    guard k > 0.01 else { return }
    for (i, a) in [-2.4, -1.57, -0.74].enumerated() {
        let r0x = rx + 5, r0y = ry + 8, r1x = rx + 5 + 9 * k, r1y = ry + 8 + 9 * k
        Sketch.ink(&ctx, [gp(c.x + r0x * cos(a), c.y + r0y * sin(a)), gp(c.x + r1x * cos(a), c.y + r1y * sin(a))], closed: false, t: t, seed: seed + i,
                   width: 2, color: G.ink.opacity(k * ctx.opacity))
    }
}

// MARK: - Card 2: school glue lets its water go, superglue takes water in. Two drops on a plank, both go hard.

struct GlueTwo: View {
    let active: Bool

    var body: some View {
        FlatPicture(active: active, period: 13, still: 8.2, cues: [Cue(2.1, .soft), Cue(5.0, .rigid), Cue(7.1, .light)], replayOnTap: true, sky: Sketch.paper,
                    label: "Two drops of glue on a wooden plank. On the left, a bottle of white school glue: little blue water drops and wavy lines rise away from its drop as it goes hard. On the right, the yellow superglue tube: blue dots of moisture drift in from the air onto its drop as it goes hard. Labels say: school glue, water leaves; superglue, water arrives; moisture in the air.") { ctx, s, t, _ in
            var c = ctx
            c.opacity = 1 - pr(t, 12.4, 13)
            gscene(&c, s) { Self.draw(&$0, t) }
        }
    }

    /// A glue container leaning with its nozzle at `p`, as if about to drip.
    private static func pourer(_ ctx: inout GraphicsContext, at p: CGPoint, bottle: Bool, t: Double, pen: Double, fillIn: Double, seed: Int) {
        var l = ctx
        l.translateBy(x: p.x, y: p.y)
        l.rotate(by: .degrees(-24))
        if bottle {
            Sketch.ink(&l, [gp(-4, 0), gp(4, 0), gp(6, -14), gp(-6, -14)], closed: true, t: t, seed: seed, width: 2, fill: GW.orange.opacity(fillIn), drawn: pen)
            Sketch.ink(&l, [gp(-6, -12), gp(6, -12), gp(24, -32), gp(26, -78), gp(18, -88), gp(-18, -88), gp(-26, -78), gp(-24, -32)], closed: true, t: t,
                       seed: seed + 1, fill: Color.white.opacity(fillIn), drawn: pen)
            Sketch.ink(&l, [gp(-25, -72), gp(25, -72), gp(25.5, -42), gp(-25.5, -42)], closed: true, t: t, seed: seed + 2, width: 1.6,
                       fill: Color(hex: 0xD7E6F7).opacity(fillIn), drawn: pen)
            gsay(&l, "SCHOOL", gp(0, -63), size: 11, t: t, seed: seed + 3, font: "MarkerFelt-Wide", color: Color(hex: 0x2F5FA8), alpha: pr(t, 1.0, 1.6))
            gsay(&l, "GLUE", gp(0, -50), size: 12, t: t, seed: seed + 4, font: "MarkerFelt-Wide", color: Color(hex: 0x2F5FA8), alpha: pr(t, 1.0, 1.6))
        } else {
            Sketch.ink(&l, [gp(-4, 0), gp(4, 0), gp(6, -10), gp(-6, -10)], closed: true, t: t, seed: seed, width: 2, fill: G.tube.opacity(fillIn), drawn: pen)
            Sketch.ink(&l, [gp(-6, -8), gp(6, -8), gp(24, -28), gp(25, -82), gp(-25, -82), gp(-24, -28)], closed: true, t: t, seed: seed + 1,
                       fill: G.tube.opacity(fillIn), drawn: pen)
            Sketch.ink(&l, [gp(-28, -82), gp(28, -82), gp(28, -92), gp(-28, -92)], closed: true, t: t, seed: seed + 2, fill: G.tube.opacity(fillIn), drawn: pen)
            for i in 0..<5 {
                let x = -20 + Double(i) * 10
                Sketch.ink(&l, [gp(x, -84), gp(x, -90)], closed: false, t: t, seed: seed + 5 + i, width: 1.1, drawn: pen)
            }
            Sketch.ink(&l, [gp(-24, -74), gp(24, -74), gp(24.5, -38), gp(-24.5, -38)], closed: true, t: t, seed: seed + 3, width: 1.8,
                       fill: G.band.opacity(fillIn), drawn: pen)
            gsay(&l, "SUPER", gp(0, -63), size: 11, t: t, seed: seed + 11, font: "MarkerFelt-Wide", color: .white, alpha: pr(t, 1.0, 1.6))
            gsay(&l, "GLUE", gp(0, -50), size: 12, t: t, seed: seed + 12, font: "MarkerFelt-Wide", color: .white, alpha: pr(t, 1.0, 1.6))
        }
    }

    private static func draw(_ ctx: inout GraphicsContext, _ t: Double) {
        let fade = ctx.opacity
        let pen = eio(pr(t, 0.1, 1.2)), fillIn = pr(t, 0.5, 1.3)
        let tipY = 122.0, leftX = 112.0, rightX = 284.0, puddleY = 205.0

        // the plank
        Sketch.ink(&ctx, [gp(18, 186), gp(325, 186), gp(340, 222), gp(3, 222)], closed: true, t: t, seed: 201, fill: GW.wood.opacity(fillIn), drawn: pen)
        Sketch.ink(&ctx, [gp(3, 222), gp(340, 222), gp(340, 240), gp(3, 240)], closed: true, t: t, seed: 202, fill: GW.woodDark.opacity(fillIn), drawn: pen)
        for i in 0..<4 {
            let x = 24 + Double(i) * 82
            Sketch.ink(&ctx, [gp(x, 231), gp(x + 34, 231)], closed: false, t: t, seed: 203 + i, width: 1, color: G.ink.opacity(0.3), drawn: pen, amp: 0.4)
        }

        // the two glues, each about to drip
        pourer(&ctx, at: gp(leftX, tipY), bottle: true, t: t, pen: pen, fillIn: fillIn, seed: 210)
        pourer(&ctx, at: gp(rightX, tipY), bottle: false, t: t, pen: pen, fillIn: fillIn, seed: 230)

        // the drops: grow at the nozzle, fall, squash on the plank, then go hard (school glue slowly, superglue quickly)
        let flow = pr(t, 2.6, 3.3) * (1 - pr(t, 9.6, 10.8))
        for side in 0..<2 {
            let dx = side == 0 ? leftX : rightX
            let hard = side == 0 ? eio(pr(t, 3.0, 7.4)) : eio(pr(t, 3.0, 5.2))
            let runny = side == 0 ? Color.white : G.glue
            let grow = pr(t, 1.0, 1.55), fall = pr(t, 1.55, 2.1)
            if t < 2.1 && t > 1.0 {
                let y = mix(tipY + 6, puddleY - 12, fall * fall)
                gblob(&ctx, gp(dx, y), r: 7 * (fall > 0 ? 1 : grow), t: t, seed: 260 + side, fill: runny, tear: true)
            }
            if t >= 2.1 {
                let land = pr(t, 2.1, 2.5)
                let e = eio(land), squash = sin(land * .pi) * 0.2
                let jig = (1 - hard) * pr(t, 2.1, 2.3) * 0.05 * sin(t * 11)
                let dry = side == 0 ? hard : 0
                let rx = 30 * mix(0.27, 1, e) * (1 + squash * 0.5 + jig) * (1 - 0.14 * dry)
                let ry = 13 * mix(1.1, 1, e) * (1 - squash * 0.6 - jig) * (1 - 0.22 * dry)
                let c = gp(dx, puddleY)
                let pts = Sketch.oval(c, rx, ry, n: 26)
                let shape = Sketch.path(pts, closed: true, t: t, seed: 270 + side)
                let body: Color = side == 0 ? Color(red: mix(1.0, 0.92, hard), green: mix(1.0, 0.90, hard), blue: mix(1.0, 0.80, hard)) : G.drop(hard)
                Sketch.ink(&ctx, pts, closed: true, t: t, seed: 270 + side, width: 2, fill: body)
                if hard < 0.6 {
                    Sketch.ink(&ctx, [gp(c.x - rx * 0.5, c.y - ry * 0.3), gp(c.x - rx * 0.15, c.y - ry * 0.6)], closed: false, t: t, seed: 275 + side,
                               width: 2.2, color: Color.white.opacity(1 - hard / 0.6))
                }
                ghatch(&ctx, clip: shape, box: CGRect(x: c.x - rx, y: c.y - ry, width: 2 * rx, height: 2 * ry), amount: hard, op: fade, t: t, seed: 280 + side * 20, gap: 7)
                gpop(&ctx, c: c, rx: rx, ry: ry, k: side == 0 ? pr(t, 6.9, 7.3) : pr(t, 4.8, 5.2), t: t, seed: 300 + side * 5)
            }
        }

        // left: water leaves the school glue, as little blue drops and wavy lines rising away
        let hardL = eio(pr(t, 3.0, 7.4)), hardR = eio(pr(t, 3.0, 5.2))
        let flowL = flow * (1 - 0.6 * hardL)
        for i in 0..<4 {
            let ph = (t * 0.42 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
            let x = leftX + (Double(i) - 1.5) * 15 + 4 * sin(ph * 9 + Double(i) * 1.7)
            let a = flowL * pr(ph, 0, 0.12) * (1 - pr(ph, 0.65, 1))
            gblob(&ctx, gp(x, 190 - ph * 58), r: 4.2, t: t, seed: 310 + i, tear: true, alpha: a)
        }
        for i in 0..<3 {
            let ph = (t * 0.3 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            let a = flowL * pr(ph, 0, 0.15) * (1 - pr(ph, 0.6, 1))
            guard a > 0.02 else { continue }
            let x0 = leftX + (Double(i) - 1) * 21, y0 = 184 - ph * 40
            var pts: [CGPoint] = []
            for k in 0..<7 {
                let dk = Double(k)
                pts.append(gp(x0 + 3.2 * sin(dk * 1.3 + t * 3 + Double(i)), y0 - dk * 3.6))
            }
            Sketch.ink(&ctx, pts, closed: false, t: t, seed: 320 + i, width: 1.8, color: GW.waterDeep.opacity(a * fade), amp: 0.3)
        }

        // right: moisture drifts in from the air to the superglue drop
        let starts: [CGPoint] = [gp(333, 118), gp(326, 160), gp(322, 82), gp(228, 170), gp(238, 138), gp(338, 196)]
        let flowR = flow * (1 - 0.5 * hardR)
        for (i, s0) in starts.enumerated() {
            let ph = (t * 0.4 + Double(i) / 6).truncatingRemainder(dividingBy: 1)
            let target = gp(rightX + (Double(i % 3) - 1) * 14, 199)
            let pos = gp(mix(s0.x, target.x, ph), mix(s0.y, target.y, ph) + 5 * sin(ph * 10 + Double(i)))
            let a = flowR * pr(ph, 0, 0.1) * (1 - pr(ph, 0.85, 1))
            gblob(&ctx, pos, r: 4.2, t: t, seed: 330 + i, alpha: a)
        }

        // words
        let la = pr(t, 3.3, 3.9), ra = pr(t, 3.6, 4.2)
        gsay(&ctx, "SCHOOL GLUE:", gp(leftX - 6, 266), size: 16, t: t, seed: 340, alpha: la)
        gsay(&ctx, "WATER LEAVES", gp(leftX - 6, 288), size: 16, t: t, seed: 341, color: GW.waterDeep, alpha: la)
        gsay(&ctx, "SUPERGLUE:", gp(rightX - 12, 266), size: 16, t: t, seed: 342, alpha: ra)
        gsay(&ctx, "WATER ARRIVES", gp(rightX - 12, 288), size: 16, t: t, seed: 343, color: GW.waterDeep, alpha: ra)
        let ma = pr(t, 3.0, 3.6)
        gsay(&ctx, "MOISTURE IN THE AIR", gp(338, 15), size: 13.5, t: t, seed: 344, color: GW.waterDeep, alpha: ma, anchor: .trailing)
        garrow(&ctx, [gp(318, 30), gp(327, 50), gp(324, 68)], t: t, seed: 345, color: GW.waterDeep, drawn: pr(t, 3.3, 3.9))
    }
}

// MARK: - Card 3: a fingertip's skin up close, a thin film of water on it; a glue drop lands and goes hard from the bottom up

struct GlueFilm: View {
    let active: Bool

    var body: some View {
        FlatPicture(active: active, period: 12, still: 7.0, cues: [Cue(1.9, .soft), Cue(2.8, .light), Cue(5.3, .rigid)], replayOnTap: true, sky: Sketch.paper,
                    label: "A big close-up of the skin on a fingertip, with fingerprint ridges, and a thin blue film of water on top, drawn much thicker than it really is. A drop of glue lands on the film and goes hard from the bottom up, where it touches the water. Labels say: skin; film of water, drawn much thicker; glue goes hard.") { ctx, s, t, _ in
            var c = ctx
            c.opacity = 1 - pr(t, 11.4, 12)
            gscene(&c, s) { Self.draw(&$0, t) }
        }
    }

    private static func skinY(_ x: Double) -> Double { 222 + 5 * sin(x * 0.045 + 0.6) + 3 * sin(x * 0.11 + 2.0) + 1.5 * sin(x * 0.23) }
    /// The water film is flatter than the skin under it: thicker in the dips.
    private static func filmY(_ x: Double) -> Double { 0.55 * skinY(x) + 0.45 * 222 - 9 }

    private static func draw(_ ctx: inout GraphicsContext, _ t: Double) {
        let fade = ctx.opacity
        let pen = eio(pr(t, 0.1, 1.3)), fillIn = pr(t, 0.4, 1.2)
        let xs: [Double] = Array(stride(from: -8.0, through: 351.0, by: 9.0))

        // skin, with fingerprint ridges under the surface
        var skin: [CGPoint] = xs.map { gp($0, skinY($0)) }
        skin += [gp(351, 335), gp(-8, 335)]
        Sketch.ink(&ctx, skin, closed: true, t: t, seed: 401, fill: G.skin.opacity(fillIn), drawn: pen)
        for k in 0..<5 {
            var ridge: [CGPoint] = []
            for x in xs { ridge.append(gp(x, skinY(x) + 20 + Double(k) * 16 + 2.5 * sin(x * 0.09 + Double(k)))) }
            Sketch.ink(&ctx, ridge, closed: false, t: t, seed: 410 + k, width: 1.4, color: Color(hex: 0xB86F4A).opacity(0.6), drawn: pen, amp: 0.6)
        }

        // the film of water
        var film: [CGPoint] = xs.map { gp($0, filmY($0)) }
        for x in xs.reversed() { film.append(gp(x, skinY(x))) }
        Sketch.ink(&ctx, film, closed: true, t: t, seed: 430, width: 1.6, color: GW.waterDeep, fill: GW.water.opacity(0.85 * fillIn), drawn: pen)
        for i in 0..<4 {   // glints on the water
            let x = 30 + Double(i) * 82, a = 0.5 + 0.5 * sin(t * 2.2 + Double(i) * 1.9)
            Sketch.ink(&ctx, [gp(x, filmY(x) + 4), gp(x + 12, filmY(x + 12) + 4)], closed: false, t: t, seed: 440 + i, width: 1.6,
                       color: Color.white.opacity(0.8 * a * pr(t, 1.0, 1.6) * fade), amp: 0.4)
        }

        // the drop: falls, spreads into a dome on the film, and goes hard from the bottom up
        let cx = 170.0
        let baseY = filmY(cx) + 1
        let fall = pr(t, 1.2, 1.9)
        if t > 1.2 && t < 1.9 {
            gblob(&ctx, gp(cx, mix(-20, baseY - 17, fall * fall)), r: 11, t: t, seed: 450, fill: G.glue, tear: true)
        }
        if t >= 1.9 {
            let e = eio(pr(t, 1.9, 2.5))
            let rx = mix(15, 62, e) * (1 + 0.07 * sin(e * .pi)), ry = mix(34, 38, e)
            let hk = eio(pr(t, 2.7, 5.4))
            var pts: [CGPoint] = []
            for i in 0...22 {
                let a = Double.pi * Double(i) / 22
                let x = cx - rx * cos(a)
                pts.append(gp(x, filmY(x) + 1 - ry * sin(a)))
            }
            var x = cx + rx - 12
            while x > cx - rx + 6 { pts.append(gp(x, filmY(x) + 1)); x -= 12 }
            let shape = Sketch.path(pts, closed: true, t: t, seed: 460)
            Sketch.ink(&ctx, pts, closed: true, t: t, seed: 460, width: 2, fill: G.glue)
            if hk < 0.7 {
                Sketch.ink(&ctx, [gp(cx - rx * 0.45, baseY - ry * 0.7), gp(cx - rx * 0.1, baseY - ry * 0.92)], closed: false, t: t, seed: 461, width: 2.2,
                           color: G.glueHi.opacity(1 - hk / 0.7))
            }
            if hk > 0.02 {
                let bot = baseY + 8, front = baseY + 3 - hk * (ry + 10)
                let x0 = cx - rx - 6, x1 = cx + rx + 6
                let wob = Double(Sketch.frame(t)) * 1.7
                var region = Path()
                var px = x0
                region.move(to: gp(x0, bot))
                while px <= x1 { region.addLine(to: gp(px, front + 2 * sin(px * 0.35 + wob))); px += 4 }
                region.addLine(to: gp(x1, bot))
                region.closeSubpath()
                ctx.drawLayer { l in
                    l.opacity = fade
                    l.clip(to: shape)
                    l.fill(region, with: .color(G.drop(1)))
                    ghatch(&l, clip: region, box: CGRect(x: x0, y: baseY - ry - 4, width: x1 - x0, height: ry + 12), amount: 1, op: fade, t: t, seed: 470, gap: 7)
                }
                Sketch.ink(&ctx, pts, closed: true, t: t, seed: 460, width: 2, color: G.ink)
            }
            gpop(&ctx, c: gp(cx, baseY - ry * 0.5), rx: rx, ry: ry * 0.5, k: pr(t, 5.2, 5.6), t: t, seed: 480)
        }

        // words
        gsay(&ctx, "SKIN", gp(14, 160), size: 18, t: t, seed: 490, alpha: pr(t, 0.9, 1.4), anchor: .leading)
        garrow(&ctx, [gp(30, 176), gp(38, 192), gp(42, skinY(42) - 6)], t: t, seed: 491, drawn: pr(t, 1.0, 1.6))
        gsay(&ctx, "FILM OF WATER", gp(338, 52), size: 16, t: t, seed: 492, color: GW.waterDeep, alpha: pr(t, 1.3, 1.9), anchor: .trailing)
        gsay(&ctx, "(DRAWN MUCH THICKER)", gp(338, 73), size: 13, t: t, seed: 493, color: GW.waterDeep, alpha: pr(t, 1.3, 1.9), anchor: .trailing)
        garrow(&ctx, [gp(300, 88), gp(306, 140), gp(296, filmY(296) - 3)], t: t, seed: 494, color: GW.waterDeep, drawn: pr(t, 1.5, 2.1))
        gsay(&ctx, "GLUE GOES HARD", gp(10, 30), size: 17, t: t, seed: 495, color: G.band, alpha: pr(t, 3.4, 4.0), anchor: .leading)
        garrow(&ctx, [gp(58, 46), gp(76, 100), gp(114, baseY - 14)], t: t, seed: 496, color: G.band, drawn: pr(t, 3.6, 4.2))
    }
}

// MARK: - Card 4 (hands-on): the tube with its cap on; drag the cap off and moisture creeps in and sets the glue in the tip

private final class CapSim { var hard = 0.0; var last: Date? }

struct GlueCap: View {
    let active: Bool
    @State private var touched = false      // false: the silent demo plays
    @State private var dragging = false
    @State private var dragLift = 0.0       // 0 = cap on, 1 = cap right off
    @State private var grabbed = 0.0
    @State private var lift0 = 0.0
    @State private var liftTo = 0.0
    @State private var since = Date.distantPast
    @State private var t0 = Date()
    @State private var sim = CapSim()
    @Environment(\.accessibilityReduceMotion) private var reduce

    private static let demoPeriod = 14.0
    private static func demoLift(_ c: Double) -> Double { eio(pr(c, 3.2, 4.4)) - eio(pr(c, 11.0, 12.0)) }
    private static func demoHard(_ c: Double) -> Double { pr(c, 4.4, 9.6) }

    private func cycle(_ now: Date) -> Double { reduce ? 8.5 : now.timeIntervalSince(t0).truncatingRemainder(dividingBy: Self.demoPeriod) }

    private func liftNow(_ now: Date) -> Double {
        if !touched { return Self.demoLift(cycle(now)) }
        if dragging { return dragLift }
        return mix(lift0, liftTo, eio(pr(now.timeIntervalSince(since), 0, 0.28)))
    }

    var body: some View {
        TimelineView(.animation(paused: !active || reduce)) { tl in
            ZStack(alignment: .bottomTrailing) {
                Canvas { ctx, s in render(&ctx, s, tl.date) }
                if touched && sim.hard > 0.98 {
                    Button {
                        sim.hard = 0; sim.last = Date()
                        Haptic.fire(.soft)
                    } label: {
                        Text("try a new tube")
                            .font(.custom("Noteworthy-Bold", size: 14)).foregroundStyle(Sketch.inkColor)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(Color(hex: 0xFFFDF7)))
                            .overlay(Capsule().stroke(Sketch.inkColor.opacity(0.6), lineWidth: 1.2))
                    }
                    .buttonStyle(.plain).padding(10)
                }
            }
        }
        .background(LinearGradient(colors: Sketch.paper.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
        .overlay {
            // a handle around the cap only, so a swipe anywhere else on the picture still turns the page
            GeometryReader { g in
                let u = min(g.size.width / 343, g.size.height / 320)
                let ox = (g.size.width - 343 * u) / 2, oy = (g.size.height - 320 * u) / 2
                Color.clear
                    .frame(width: 84 * u, height: 130 * u)
                    .contentShape(Rectangle())
                    .position(x: ox + 85 * u, y: oy + 100 * u)
                    .highPriorityGesture(drag)
                    .onTapGesture { toggleCap() }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
        .onChange(of: active) { _, a in if a { t0 = Date() } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A tube of glue standing upright with its red cap on and runny glue showing through the tube. Dragging the cap up and off lets blue dots of moisture creep into the open tip, and the glue there goes hard and blocks it. Putting the cap back on stops any new moisture. Until you touch it, the cap lifts off and goes back on by itself.")
        .accessibilityValue(isOff ? "Cap off" : "Cap on")
        .accessibilityAdjustableAction { dir in setCap(off: dir == .increment) }
    }

    private var isOff: Bool { touched ? (dragging ? dragLift > 0.5 : liftTo > 0.5) : Self.demoLift(cycle(Date())) > 0.5 }

    private func adopt() {
        guard !touched else { return }
        let c = cycle(Date())
        let l = Self.demoLift(c)
        sim.hard = Self.demoHard(c); sim.last = Date()
        lift0 = l; liftTo = l; dragLift = l; since = .distantPast
        touched = true
    }

    private func setCap(off: Bool) {
        adopt()
        lift0 = liftNow(Date()); liftTo = off ? 1 : 0; since = Date()
        if reduce && off { sim.hard = 1 }
        Haptic.fire(off ? .soft : .rigid)
    }

    private func toggleCap() { adopt(); setCap(off: liftNow(Date()) < 0.5) }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { v in
                if !dragging {
                    adopt()
                    grabbed = liftNow(Date()); dragLift = grabbed; dragging = true
                    Haptic.fire(.soft)
                }
                let new = min(1, max(0, grabbed - v.translation.height / 66))
                if (dragLift > 0.5) != (new > 0.5) { Haptic.fire(.light) }
                dragLift = new
            }
            .onEnded { _ in
                lift0 = dragLift; liftTo = dragLift > 0.5 ? 1 : 0; since = Date(); dragging = false
                if reduce && liftTo == 1 { sim.hard = 1 }
                Haptic.fire(liftTo == 0 ? .rigid : .soft)
            }
    }

    private func render(_ ctx: inout GraphicsContext, _ s: CGSize, _ now: Date) {
        let el = reduce ? 20 : now.timeIntervalSince(t0)
        let cyc = cycle(now)
        let lift: Double, hard: Double
        if touched {
            lift = liftNow(now)
            if !reduce {
                if let last = sim.last {
                    let dt = min(0.1, max(0, now.timeIntervalSince(last)))
                    sim.hard = min(1, sim.hard + dt * pr(lift, 0.45, 0.75) / 5)
                }
                sim.last = now
            }
            hard = sim.hard
        } else {
            lift = Self.demoLift(cyc); hard = Self.demoHard(cyc)
        }
        var c = ctx
        c.opacity = (touched || reduce) ? 1 : (el > Self.demoPeriod ? pr(cyc, 0, 0.5) : 1) * (1 - pr(cyc, 13.4, 14))
        let hint = touched ? 0 : pr(el, 1.4, 2.0)
        gscene(&c, s) { Self.draw(&$0, el, lift, hard, hint: hint) }
    }

    private static func draw(_ ctx: inout GraphicsContext, _ t: Double, _ lift: Double, _ hard: Double, hint: Double) {
        let fade = ctx.opacity
        let pen = eio(pr(t, 0.1, 1.4)), fillIn = pr(t, 0.5, 1.3)
        let tx = 85.0, hw = 34.0, yT = 168.0, yB = 292.0, yN = 146.0, yTip = 131.0, nw = 8.0
        let off = pr(lift, 0.45, 0.75)

        // the glue inside, seen through the tube
        let glue: [CGPoint] = [gp(tx - nw + 2, yTip + 2), gp(tx + nw - 2, yTip + 2), gp(tx + nw - 2, yN), gp(tx + hw - 2, yT),
                               gp(tx + hw * 1.06 - 2, yB - 2), gp(tx - hw * 1.06 + 2, yB - 2), gp(tx - hw + 2, yT), gp(tx - nw + 2, yN)]
        let gShape = Sketch.path(glue, closed: true, t: t, seed: 501)
        Sketch.ink(&ctx, glue, closed: true, t: t, seed: 501, width: 1.6, color: G.ink.opacity(0.7 * fillIn), fill: G.glue.opacity(0.9 * fillIn))
        for i in 0..<3 {   // slow bubbles: it is a liquid
            let ph = (t * 0.25 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
            let p = gp(tx + (Double(i) - 1) * hw * 0.5, mix(yB - 12, yT + 14, ph))
            Sketch.ink(&ctx, Sketch.oval(p, 2.6, 2.6, n: 10), closed: true, t: t, seed: 505 + i, width: 1.1, color: G.ink.opacity(0.5 * fillIn * (1 - ph)))
        }

        // the hard plug grows down from the tip
        if hard > 0.01 {
            let front = yTip + 2 + hard * 38
            let x0 = tx - hw, x1 = tx + hw
            let wob = Double(Sketch.frame(t)) * 1.7
            var region = Path()
            var px = x0
            region.move(to: gp(x0, yTip - 4))
            region.addLine(to: gp(x0, front))
            while px <= x1 { region.addLine(to: gp(px, front + 1.6 * sin(px * 0.5 + wob))); px += 4 }
            region.addLine(to: gp(x1, yTip - 4))
            region.closeSubpath()
            ctx.drawLayer { l in
                l.opacity = fade
                l.clip(to: gShape)
                l.fill(region, with: .color(G.drop(1)))
                ghatch(&l, clip: region, box: CGRect(x: x0, y: yTip - 4, width: x1 - x0, height: front - yTip + 8), amount: 1, op: fade, t: t, seed: 520, gap: 6)
            }
        }

        // the tube wrapper: faint, so the glue shows through
        Sketch.ink(&ctx, [gp(tx - hw, yT), gp(tx + hw, yT), gp(tx + hw * 1.08, yB), gp(tx - hw * 1.08, yB)], closed: true, t: t, seed: 502,
                   fill: G.tube.opacity(0.16 * fillIn), drawn: pen)
        Sketch.ink(&ctx, [gp(tx - hw, yT), gp(tx - nw, yN), gp(tx + nw, yN), gp(tx + hw, yT)], closed: true, t: t, seed: 503, fill: G.tube.opacity(0.16 * fillIn), drawn: pen)
        Sketch.ink(&ctx, [gp(tx - nw, yN), gp(tx - nw, yTip), gp(tx + nw, yTip), gp(tx + nw, yN)], closed: false, t: t, seed: 504, drawn: pen)
        Sketch.ink(&ctx, [gp(tx - hw * 0.72, yT + 12), gp(tx + hw * 0.72, yT + 12), gp(tx + hw * 0.76, yB - 14), gp(tx - hw * 0.76, yB - 14)], closed: true, t: t,
                   seed: 508, width: 1.6, color: G.ink.opacity(0.35), fill: G.band.opacity(0.14 * fillIn), drawn: pen)
        Sketch.ink(&ctx, [gp(tx - hw * 1.2, yB), gp(tx + hw * 1.2, yB), gp(tx + hw * 1.2, yB + 10), gp(tx - hw * 1.2, yB + 10)], closed: true, t: t, seed: 509,
                   fill: G.tube.opacity(fillIn), drawn: pen)
        for i in 0..<5 {
            let x = tx - hw + Double(i + 1) * hw * 2 / 6
            Sketch.ink(&ctx, [gp(x, yB + 2), gp(x, yB + 8)], closed: false, t: t, seed: 510 + i, width: 1.2, drawn: pen)
        }
        // a hard nub squeezed out of the tip
        let nub = pr(hard, 0.2, 0.6)
        if nub > 0.01 {
            let c = gp(tx, yTip - 1)
            let pts = Sketch.oval(c, nw + 1, 6 * nub, n: 14)
            Sketch.ink(&ctx, pts, closed: true, t: t, seed: 530, width: 1.8, fill: G.drop(1))
            ghatch(&ctx, clip: Sketch.path(pts, closed: true, t: t, seed: 530), box: CGRect(x: c.x - nw - 1, y: c.y - 6 * nub, width: 2 * nw + 2, height: 12 * nub),
                   amount: 1, op: fade, t: t, seed: 531, gap: 5)
        }

        // the red cap, lifted by `lift`
        var cp = ctx
        cp.translateBy(x: 0, y: -lift * 64)
        let cw = 13.0, cTop = yTip - 19, cBot = yN + 5
        Sketch.ink(&cp, [gp(tx - cw, cBot), gp(tx - cw, cTop + 5), gp(tx - cw + 5, cTop), gp(tx + cw - 5, cTop), gp(tx + cw, cTop + 5), gp(tx + cw, cBot)],
                   closed: true, t: t, seed: 540, fill: G.cap.opacity(fillIn), drawn: pen)
        for i in 0..<3 {
            let y = cTop + 12 + Double(i) * 8
            Sketch.ink(&cp, [gp(tx - cw + 3, y), gp(tx + cw - 3, y)], closed: false, t: t, seed: 541 + i, width: 1.1, color: G.ink.opacity(0.5), drawn: pen, amp: 0.4)
        }
        Sketch.ink(&cp, [gp(tx - cw + 4, cTop + 5), gp(tx - cw + 4, cBot - 6)], closed: false, t: t, seed: 545, width: 2, color: Color.white.opacity(0.55 * fillIn), amp: 0.4)

        // moisture drifting toward the tube: it reaches the open tip, but stops short of the cap
        let starts: [CGPoint] = [gp(320, 40), gp(335, 95), gp(290, 18), gp(240, 40), gp(310, 140), gp(255, 100), gp(205, 20), gp(330, 150)]
        let target = gp(tx + 2, yTip - 3)
        let reach = mix(0.88, 1, off)
        for (i, s0) in starts.enumerated() {
            let ph = (t * 0.45 + Double(i) / 8).truncatingRemainder(dividingBy: 1)
            let q = ph * reach
            let pos = gp(mix(s0.x, target.x, q), mix(s0.y, target.y, q) + 5 * sin(ph * 9 + Double(i)))
            let a = pr(t, 1.6, 2.2) * pr(ph, 0, 0.1) * (1 - pr(ph, 0.8, 1))
            gblob(&ctx, pos, r: 4.2, t: t, seed: 550 + i, alpha: a)
        }
        gpop(&ctx, c: gp(tx, yTip - 6), rx: 8, ry: 4, k: pr(hard, 0.9, 1), t: t, seed: 560)

        // words
        let onA = 1 - pr(lift, 0.3, 0.55), offA = pr(lift, 0.45, 0.7)
        gsay(&ctx, "CAP ON:", gp(168, 196), size: 15, t: t, seed: 570, alpha: onA * pr(t, 1.2, 1.8), anchor: .leading)
        gsay(&ctx, "NO WATER IN", gp(168, 217), size: 15, t: t, seed: 571, color: GW.waterDeep, alpha: onA * pr(t, 1.2, 1.8), anchor: .leading)
        gsay(&ctx, "CAP OFF:", gp(168, 196), size: 15, t: t, seed: 572, alpha: offA, anchor: .leading)
        gsay(&ctx, "MOISTURE CREEPS IN", gp(168, 217), size: 15, t: t, seed: 573, color: GW.waterDeep, alpha: offA, anchor: .leading)
        let ha = pr(hard, 0.5, 0.7)
        gsay(&ctx, "HARD GLUE", gp(168, 258), size: 15, t: t, seed: 574, color: G.band, alpha: ha, anchor: .leading)
        gsay(&ctx, "BLOCKS THE TIP", gp(168, 279), size: 15, t: t, seed: 575, color: G.band, alpha: ha, anchor: .leading)
        garrow(&ctx, [gp(162, 252), gp(130, 200), gp(106, 154)], t: t, seed: 576, color: G.band, drawn: ha)
        if hint > 0.01 {
            gsay(&ctx, "drag the", gp(6, 34), size: 15, t: t, seed: 580, color: G.band, alpha: hint, anchor: .leading)
            gsay(&ctx, "cap up", gp(6, 53), size: 15, t: t, seed: 581, color: G.band, alpha: hint, anchor: .leading)
            garrow(&ctx, [gp(34, 68), gp(40, 92), gp(66, 106)], t: t, seed: 582, color: G.band, drawn: hint)
        }
    }
}
