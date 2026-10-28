import SwiftUI

// "Why is it summer when Earth is farthest from the Sun?" topic: five hand-drawn pictures (owner-approved style, 2026-10-27).
// Paper background, wobbly ink that "boils" eight times a second, handwritten labels, warm fills. Card 4 is the topic's one
// hands-on picture (drag to tilt the torch); the rest play and loop by themselves. Every picture is drawn in a fixed
// 343 x 320 design space that `scene` scales and centres into whatever panel the card gives it.
// The lean always points to the upper left; Earth's June and July places are on the right of the Sun, December and January on the left.

private func cl(_ x: Double) -> Double { min(1, max(0, x)) }
private func pr(_ t: Double, _ a: Double, _ b: Double) -> Double { cl((t - a) / (b - a)) }
private func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
private func mix(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }
private func pop(_ x: Double) -> Double { let c1 = 1.70158, c3 = c1 + 1; return x <= 0 ? 0 : 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }
private func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

private enum SN {
    static let ink = Sketch.inkColor
    static let sun = Color(hex: 0xF6C945), sunDeep = Color(hex: 0xF08A24)
    static let sea = Color(hex: 0x9ED4EE), land = Color(hex: 0x86C46A)
    static let night = Color(hex: 0x2F3E7A)
    static let red = Color(hex: 0xE5533D), blue = Color(hex: 0x3C6FB0)
    static let straw = Color(hex: 0xF2D27A)
    static let page = Color(hex: 0xFFFDF7)
    static let leanDeg = -23.0   // the top of Earth leans to the upper left, always
}

/// Draws in a 343 x 320 design space scaled and centred into the panel.
private func scene(_ ctx: inout GraphicsContext, _ s: CGSize, _ body: (inout GraphicsContext) -> Void) {
    let u = min(s.width / 343, s.height / 320)
    var c = ctx
    c.translateBy(x: (s.width - 343 * u) / 2, y: (s.height - 320 * u) / 2)
    c.scaleBy(x: u, y: u)
    body(&c)
}

private func say(_ ctx: inout GraphicsContext, _ text: String, _ p: CGPoint, size: Double = 16, t: Double, seed: Int, color: Color = SN.ink,
                 alpha: Double = 1, anchor: UnitPoint = .center, font: String = "Noteworthy-Bold") {
    Sketch.say(&ctx, text, p, size: size, t: t, seed: seed, font: font, color: color, alpha: alpha, anchor: anchor)
}

/// A hand-drawn line or curve ending in an arrowhead.
private func arrow(_ ctx: inout GraphicsContext, _ pts: [CGPoint], t: Double, seed: Int, width: Double = 2, color: Color = SN.ink,
                   head: Double = 8, drawn: Double = 1, amp: Double = 0.8) {
    Sketch.ink(&ctx, pts, closed: false, t: t, seed: seed, width: width, color: color, drawn: drawn, amp: amp)
    guard drawn > 0.95, pts.count >= 2 else { return }
    let b = pts[pts.count - 1], a = pts[pts.count - 2]
    let ang = atan2(b.y - a.y, b.x - a.x)
    for (i, s) in [-1.0, 1.0].enumerated() {
        let q = pt(b.x - head * cos(ang + s * 0.5), b.y - head * sin(ang + s * 0.5))
        Sketch.ink(&ctx, [b, q], closed: false, t: t, seed: seed + 5 + i, width: width, color: color, amp: 0.3)
    }
}

/// Cartoon emphasis ticks fanning out from a point.
private func burst(_ ctx: inout GraphicsContext, _ c: CGPoint, r0: Double, r1: Double, angles: [Double], t: Double, seed: Int, alpha: Double, color: Color = SN.ink) {
    guard alpha > 0.01 else { return }
    for (i, a) in angles.enumerated() {
        Sketch.ink(&ctx, [pt(c.x + r0 * cos(a), c.y + r0 * sin(a)), pt(c.x + r1 * cos(a), c.y + r1 * sin(a))], closed: false, t: t, seed: seed + i,
                   width: 2, color: color.opacity(alpha), amp: 0.4)
    }
}

/// A hand-drawn Sun with rays.
private func sunDraw(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, t: Double, seed: Int, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    var l = ctx
    l.opacity = ctx.opacity * alpha
    for i in 0..<12 {
        let a = Double(i) / 12 * 2 * .pi + t * 0.12
        let long = i % 2 == 0
        let r1 = r * ((long ? 1.85 : 1.55) + 0.07 * sin(t * 3 + Double(i)))
        Sketch.ink(&l, [pt(c.x + r * 1.28 * cos(a), c.y + r * 1.28 * sin(a)), pt(c.x + r1 * cos(a), c.y + r1 * sin(a))], closed: false, t: t, seed: seed + i,
                   width: 2.2, color: SN.sunDeep, amp: 0.5)
    }
    Sketch.ink(&l, Sketch.oval(c, r, r, n: 24), closed: true, t: t, seed: seed + 20, width: 2.4, fill: SN.sun)
    Sketch.ink(&l, [pt(c.x - r * 0.55, c.y - r * 0.2), pt(c.x - r * 0.35, c.y - r * 0.55)], closed: false, t: t, seed: seed + 21, width: 2,
               color: Color.white.opacity(0.85), amp: 0.3)
}

/// A straw sun hat sitting on `base`, leaning with the pole. `s` is its size (1 = about 25 points wide).
private func hatDraw(_ ctx: inout GraphicsContext, _ base: CGPoint, lean: Double, s: Double, t: Double, seed: Int) {
    guard s > 0.02 else { return }
    var l = ctx
    l.translateBy(x: base.x, y: base.y)
    l.rotate(by: .degrees(lean))
    func q(_ x: Double, _ y: Double) -> CGPoint { pt(x * s, y * s) }
    Sketch.ink(&l, Sketch.oval(q(0, 0), 12.5 * s, 4 * s, n: 18), closed: true, t: t, seed: seed, width: 1.8, fill: SN.straw, amp: 0.5)
    Sketch.ink(&l, [q(-7, 0), q(-7.5, -6), q(-5, -11), q(0, -12.5), q(5, -11), q(7.5, -6), q(7, 0)], closed: true, t: t, seed: seed + 1, width: 1.8,
               fill: SN.straw, amp: 0.5)
    Sketch.ink(&l, [q(-7.3, -4.8), q(7.3, -4.8), q(7.1, -1.6), q(-7.1, -1.6)], closed: true, t: t, seed: seed + 2, width: 1.4, fill: SN.red, amp: 0.4)
}

private func snowflake(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, t: Double, seed: Int, alpha: Double) {
    guard alpha > 0.01 else { return }
    for i in 0..<3 {
        let a = Double(i) * .pi / 3 + 0.2
        Sketch.ink(&ctx, [pt(c.x - r * cos(a), c.y - r * sin(a)), pt(c.x + r * cos(a), c.y + r * sin(a))], closed: false, t: t, seed: seed + i, width: 2,
                   color: SN.blue.opacity(alpha), amp: 0.3)
    }
}

private func miniSun(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, t: Double, seed: Int, alpha: Double) {
    guard alpha > 0.01 else { return }
    var l = ctx
    l.opacity = ctx.opacity * alpha
    Sketch.ink(&l, Sketch.oval(c, r * 0.55, r * 0.55, n: 14), closed: true, t: t, seed: seed, width: 1.8, fill: SN.sun, amp: 0.4)
    for i in 0..<8 {
        let a = Double(i) / 8 * 2 * .pi
        Sketch.ink(&l, [pt(c.x + r * 0.8 * cos(a), c.y + r * 0.8 * sin(a)), pt(c.x + r * 1.15 * cos(a), c.y + r * 1.15 * sin(a))], closed: false, t: t,
                   seed: seed + 1 + i, width: 1.8, color: SN.sunDeep, amp: 0.3)
    }
}

// A few rough landmasses (centre longitude and latitude, half-sizes in degrees) for the side-on globe.
private let snLands: [(lon: Double, lat: Double, dlon: Double, dlat: Double)] = [
    (-100, 45, 34, 22), (15, 48, 20, 12), (78, 46, 56, 20), (20, 4, 24, 30), (-60, -14, 18, 28), (134, -25, 18, 10), (-42, 72, 14, 8)
]

/// A hand-drawn Earth seen side-on: sea, rough continents turning with `spin`, a white cap on the north pole, a dotted equator,
/// the half away from the Sun in shade (`light` = unit vector from Earth toward the Sun), and the lean as a red arrow that
/// runs through the poles. `lean` is degrees clockwise from straight up.
private func globeDraw(_ ctx: inout GraphicsContext, c: CGPoint, r: Double, lean: Double, spin: Double, light: CGPoint?, t: Double, seed: Int,
                       pen: Double = 1, detail: Bool = true, nightAlpha: Double = 0.45, arrowLen: Double = 1.75, showN: Bool = false) {
    let amp = r > 30 ? 1.1 : 0.6
    let pts = Sketch.oval(c, r, r, n: 36)
    let disc = Sketch.path(pts, closed: true, t: t, seed: seed, amp: amp)
    ctx.fill(disc, with: .color(SN.sea.opacity(pen > 0.5 ? 1 : pen * 2)))
    ctx.drawLayer { l in
        l.clip(to: disc)
        var g = l
        g.translateBy(x: c.x, y: c.y)
        g.rotate(by: .degrees(lean))
        if detail {
            for (i, b) in snLands.enumerated() {
                var lw = (b.lon + spin).truncatingRemainder(dividingBy: 360)
                if lw > 180 { lw -= 360 }
                if lw < -180 { lw += 360 }
                if cos(lw * .pi / 180) < -0.35 { continue }
                var poly: [CGPoint] = []
                for k in 0..<12 {
                    let a = Double(k) / 12 * 2 * .pi
                    let nz = 0.85 + 0.3 * Sketch.rnd(i * 31 + k)
                    let lon = (lw + b.dlon * cos(a) * nz) * .pi / 180
                    let lat = (b.lat + b.dlat * sin(a) * nz) * .pi / 180
                    let x = cos(lon) < 0 ? (sin(lon) >= 0 ? 1.0 : -1.0) * r * cos(lat) : r * cos(lat) * sin(lon)
                    poly.append(pt(x, -r * sin(lat)))
                }
                Sketch.ink(&g, poly, closed: true, t: t, seed: seed + 50 + i, width: max(1, r * 0.035), fill: SN.land, amp: max(0.3, r * 0.015))
            }
            g.fill(Path(ellipseIn: CGRect(x: -0.55 * r, y: -1.13 * r, width: 1.1 * r, height: 0.44 * r)), with: .color(.white.opacity(0.92)))
            var eq = Path()
            for k in 0...20 {
                let a = Double.pi * Double(k) / 20
                let p = pt(r * cos(a), r * 0.2 * sin(a))
                if k == 0 { eq.move(to: p) } else { eq.addLine(to: p) }
            }
            g.stroke(eq, with: .color(SN.ink.opacity(0.5)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, dash: [3, 3]))
        }
    }
    if let L = light {
        let P = pt(-L.y, L.x)
        var half = Path()
        half.move(to: pt(c.x + P.x * 2 * r, c.y + P.y * 2 * r))
        half.addLine(to: pt(c.x + P.x * 2 * r - L.x * 2 * r, c.y + P.y * 2 * r - L.y * 2 * r))
        half.addLine(to: pt(c.x - P.x * 2 * r - L.x * 2 * r, c.y - P.y * 2 * r - L.y * 2 * r))
        half.addLine(to: pt(c.x - P.x * 2 * r, c.y - P.y * 2 * r))
        half.closeSubpath()
        ctx.drawLayer { l in
            l.clip(to: disc)
            l.clip(to: half)
            l.fill(Path(CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(SN.night.opacity(nightAlpha)))
            if detail {
                var hatch = Path()
                let n = Int(4 * r / 6)
                for k in 0..<n {
                    let x0 = c.x - 2 * r + 6 * Double(k)
                    hatch.move(to: pt(x0, c.y + r)); hatch.addLine(to: pt(x0 + 2 * r, c.y - r))
                }
                l.stroke(hatch, with: .color(SN.ink.opacity(0.16)), lineWidth: 1)
            }
        }
    }
    Sketch.ink(&ctx, pts, closed: true, t: t, seed: seed, width: r > 30 ? 2.4 : 1.9, drawn: pen, amp: amp)
    if arrowLen > 0 {
        let a = pt(sin(lean * .pi / 180), -cos(lean * .pi / 180))
        let tip = pt(c.x + a.x * r * arrowLen, c.y + a.y * r * arrowLen)
        let tail = pt(c.x - a.x * r * 1.3, c.y - a.y * r * 1.3)
        arrow(&ctx, [tail, tip], t: t, seed: seed + 90, width: r > 30 ? 3 : 2.4, color: SN.red, head: r > 30 ? 12 : 8, drawn: pen, amp: 0.4)
        if showN && pen > 0.9 {
            say(&ctx, "N", pt(tip.x + a.x * 10 - 7, tip.y + a.y * 10), size: 13, t: t, seed: seed + 95, color: SN.red)
        }
    }
}

// MARK: - Card 1: Earth's near-circle path round the Sun; farthest in July, closest in January; the north wears a sun hat in July

struct SeasonsFar: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 11, still: 7.8, cues: [Cue(1.8, .soft), Cue(5.6, .light)], replayOnTap: true, sky: Sketch.paper,
                    label: "Earth's path round the Sun, drawn as the almost-perfect circle it is. Earth starts on the left, in January, labelled closest. It travels over the top to the right, in July, labelled farthest. There its north half puts on a little sun hat, and a caption says it is summer up north in July.") { ctx, s, t, _ in
            scene(&ctx, s) { c in draw(&c, t) }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ t: Double) {
        ctx.opacity = 1 - pr(t, 10.3, 11)
        let pen = eio(pr(t, 0.1, 1.4))
        let C = pt(171.5, 150), R = 100.0, er = 20.0
        Sketch.ink(&ctx, Sketch.oval(C, R, R, n: 56), closed: true, t: t, seed: 301, width: 2.2, drawn: pen)
        sunDraw(&ctx, C, 26, t: t, seed: 310, alpha: pr(t, 0.2, 0.9))

        let go = eio(pr(t, 2.4, 5.4))
        let a = Double.pi + go * Double.pi
        let jan = pt(C.x - R, C.y)
        let e = pt(C.x + R * cos(a), C.y + R * sin(a))
        // a faint copy stays behind in January
        let ghost = pr(t, 2.5, 3.1)
        if ghost > 0.01 {
            var l = ctx
            l.opacity = ctx.opacity * ghost * 0.5
            Sketch.ink(&l, Sketch.oval(jan, er, er, n: 24), closed: true, t: t, seed: 320, width: 1.6, fill: SN.sea.opacity(0.5), amp: 0.5)
        }
        // Earth itself, leaning the same way all the way round
        let d = hypot(C.x - e.x, C.y - e.y)
        let earthA = pr(t, 1.2, 1.9)
        if earthA > 0.01 {
            var l = ctx
            l.opacity = ctx.opacity * earthA
            globeDraw(&l, c: e, r: er, lean: SN.leanDeg, spin: t * 40, light: pt((C.x - e.x) / d, (C.y - e.y) / d), t: t, seed: 330, nightAlpha: 0.4, arrowLen: 0)
        }
        // the sun hat, once Earth has arrived in July
        let a0 = pt(sin(SN.leanDeg * .pi / 180), -cos(SN.leanDeg * .pi / 180))
        let hatK = pop(pr(t, 5.5, 6.0))
        hatDraw(&ctx, pt(e.x + a0.x * er * 0.93, e.y + a0.y * er * 0.93), lean: SN.leanDeg, s: hatK, t: t, seed: 340)

        // labels, each with a small arrow to its Earth
        let janA = pr(t, 1.6, 2.2), julA = pr(t, 5.5, 6.1)
        say(&ctx, "JANUARY:", pt(8, 20), size: 17, t: t, seed: 350, alpha: janA, anchor: .leading)
        say(&ctx, "CLOSEST", pt(8, 40), size: 17, t: t, seed: 351, color: SN.blue, alpha: janA, anchor: .leading)
        if janA > 0.9 { arrow(&ctx, [pt(40, 56), pt(52, 86), pt(64, 118)], t: t, seed: 352, width: 1.8, drawn: pr(t, 2.0, 2.6)) }
        say(&ctx, "JULY:", pt(335, 20), size: 17, t: t, seed: 360, alpha: julA, anchor: .trailing)
        say(&ctx, "FARTHEST", pt(335, 40), size: 17, t: t, seed: 361, color: SN.sunDeep, alpha: julA, anchor: .trailing)
        if julA > 0.9 { arrow(&ctx, [pt(304, 56), pt(296, 90), pt(288, 124)], t: t, seed: 362, width: 1.8, drawn: pr(t, 5.7, 6.2)) }
        let cap = pr(t, 6.4, 7.0)
        say(&ctx, "SUMMER UP NORTH IN JULY", pt(171.5, 288), size: 18, t: t, seed: 370, alpha: cap)
        if cap > 0.95 {
            Sketch.ink(&ctx, [pt(30, 304), pt(90, 307), pt(171, 304), pt(252, 307), pt(313, 304)], closed: false, t: t, seed: 371, width: 1.6, color: SN.sunDeep, drawn: pr(t, 6.9, 7.5))
        }
        burst(&ctx, pt(e.x + a0.x * er * 1.3, e.y + a0.y * er * 1.3), r0: 14, r1: 14 + 7 * pr(t, 5.7, 6.1), angles: [-2.7, -2.2, -1.7], t: t, seed: 380, alpha: pr(t, 5.7, 6.1) * (1 - pr(t, 6.3, 6.7)), color: SN.sunDeep)
    }
}

// MARK: - Card 2: 100 steps to the Sun in January, 103 in July; then one Earth with Australia in summer and Canada in winter

struct SeasonsSteps: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 13, still: 11, cues: [Cue(2.5, .soft), Cue(4.8, .rigid), Cue(8.4, .light)], replayOnTap: true, sky: Sketch.paper,
                    label: "Two rows of footprints walk from Earth to the Sun. In January it takes 100 steps and in July 103 steps, the last three marked in red, so the distances are almost the same. Then one Earth sits beside the Sun with two dashed lines of equal length to it. Canada, in the north half leaning away, is labelled winter, and Australia, in the south half leaning toward the Sun, is labelled summer, both at the same moment.") { ctx, s, t, _ in
            scene(&ctx, s) { c in draw(&c, t) }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ t: Double) {
        let a = 1 - pr(t, 5.0, 5.5)
        let b = pr(t, 5.6, 6.1) * (1 - pr(t, 12.2, 12.8))
        if a > 0.01 { var l = ctx; l.opacity = ctx.opacity * a; rows(&l, t) }
        if b > 0.01 { var l = ctx; l.opacity = ctx.opacity * b; halves(&l, t) }
    }

    private func rows(_ ctx: inout GraphicsContext, _ t: Double) {
        let pen = eio(pr(t, 0.1, 1.0))
        let step = 2.5
        let rowsSpec: [(name: String, n: Int, y: Double, t0: Double, t1: Double)] = [("JANUARY", 100, 124, 0.6, 2.5), ("JULY", 103, 232, 2.8, 4.8)]
        for (ri, rs) in rowsSpec.enumerated() {
            let x0 = 40.0
            let sunX = x0 + step * Double(rs.n) + 17
            var earth = ctx
            globeDraw(&earth, c: pt(26, rs.y), r: 11, lean: SN.leanDeg, spin: 20, light: pt(1, 0), t: t, seed: 400 + ri * 40, pen: pen, detail: false, nightAlpha: 0.4, arrowLen: 0)
            sunDraw(&ctx, pt(sunX, rs.y), 14, t: t, seed: 410 + ri * 40, alpha: pr(t, 0.2, 0.9))
            let k = pr(t, rs.t0, rs.t1)
            let shown = Int(k * Double(rs.n))
            var feet = Path(), red = Path()
            for i in 0..<shown {
                let fy = rs.y + (i % 2 == 0 ? -2.6 : 2.6)
                let r = CGRect(x: x0 + step * Double(i), y: fy - 1.8, width: 2.0, height: 3.6)
                if ri == 1 && i >= 100 { red.addEllipse(in: r) } else { feet.addEllipse(in: r) }
            }
            ctx.fill(feet, with: .color(SN.ink.opacity(0.8)))
            ctx.fill(red, with: .color(SN.red))
            let la = pr(t, rs.t0 - 0.2, rs.t0 + 0.3)
            say(&ctx, "\(rs.name): \(shown) STEPS", pt(24, rs.y - 52), size: 18, t: t, seed: 420 + ri, color: ri == 0 ? SN.ink : SN.sunDeep, alpha: la, anchor: .leading)
            if ri == 1 && shown >= 103 {
                let m = pr(t, 4.7, 5.0)
                let bx = x0 + step * 100
                Sketch.ink(&ctx, [pt(bx, rs.y + 14), pt(bx, rs.y + 20), pt(bx + step * 3, rs.y + 20), pt(bx + step * 3, rs.y + 14)], closed: false, t: t, seed: 430, width: 1.8,
                           color: SN.red.opacity(m), amp: 0.3)
                say(&ctx, "+3", pt(bx + step * 1.5, rs.y + 36), size: 18, t: t, seed: 431, color: SN.red, alpha: m)
            }
        }
    }

    private func halves(_ ctx: inout GraphicsContext, _ t: Double) {
        let pen = eio(pr(t, 5.7, 6.7))
        let E = pt(140, 165), r = 64.0, S = pt(300, 165)
        // dashed lines of the same length from the Sun to a spot in Canada and a spot in Australia
        let can = pt(E.x + 0.52 * r, E.y - 0.55 * r), aus = pt(E.x + 0.52 * r, E.y + 0.55 * r)
        let dash = pr(t, 6.6, 7.2)
        if dash > 0.01 {
            for p in [can, aus] {
                let dd = hypot(p.x - S.x, p.y - S.y)
                var d = Path(); d.move(to: p); d.addLine(to: pt(S.x + (p.x - S.x) / dd * 36, S.y + (p.y - S.y) / dd * 36))
                ctx.stroke(d, with: .color(SN.ink.opacity(0.5 * dash)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [5, 5]))
            }
        }
        globeDraw(&ctx, c: E, r: r, lean: SN.leanDeg, spin: -10, light: pt(1, 0), t: t, seed: 440, pen: pen, nightAlpha: 0.4, arrowLen: 1.5)
        sunDraw(&ctx, S, 26, t: t, seed: 450, alpha: pr(t, 5.8, 6.3))
        // two spots, drawn over the globe so they show up
        let spotA = pr(t, 6.6, 7.0)
        if spotA > 0.01 {
            var l = ctx
            l.opacity = ctx.opacity * spotA
            Sketch.ink(&l, Sketch.oval(pt(can.x - 3, can.y - 2), 18, 11, n: 16), closed: true, t: t, seed: 460, width: 1.6, fill: SN.land, amp: 0.7)
            Sketch.ink(&l, Sketch.oval(pt(aus.x - 2, aus.y + 2), 14, 9, n: 16), closed: true, t: t, seed: 461, width: 1.6, fill: SN.land, amp: 0.7)
            for p in [can, aus] {
                Sketch.ink(&l, Sketch.oval(p, 3.6, 3.6, n: 10), closed: true, t: t, seed: 462, width: 1.4, fill: SN.red, amp: 0.3)
            }
        }
        // Canada: winter (the north half leans away from the Sun)
        let ca = pr(t, 7.2, 7.8)
        say(&ctx, "CANADA: WINTER", pt(140, 56), size: 18, t: t, seed: 470, alpha: ca)
        snowflake(&ctx, pt(36, 56), 9, t: t, seed: 471, alpha: ca)
        if ca > 0.9 { arrow(&ctx, [pt(158, 70), pt(172, 92), pt(can.x - 1, can.y - 12)], t: t, seed: 472, width: 1.8, drawn: pr(t, 7.6, 8.1)) }
        // Australia: summer (the south half leans toward the Sun)
        let au = pr(t, 8.4, 9.0)
        say(&ctx, "AUSTRALIA: SUMMER", pt(140, 276), size: 18, t: t, seed: 480, alpha: au)
        miniSun(&ctx, pt(26, 276), 12, t: t, seed: 481, alpha: au)
        if au > 0.9 { arrow(&ctx, [pt(160, 258), pt(174, 238), pt(aus.x - 1, aus.y + 12)], t: t, seed: 482, width: 1.8, drawn: pr(t, 8.8, 9.3)) }
    }
}

// MARK: - Card 3: Earth round the Sun with its lean drawn as an arrow that never turns

struct SeasonsLean: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 14, still: 12.5, cues: [Cue(5.7, .rigid), Cue(10.1, .rigid)], replayOnTap: true, sky: Sketch.paper,
                    label: "Earth travels round the Sun with its lean drawn as a red arrow through the poles. The arrow never turns: at every stop along the path it points to the same upper left, and faint copies of Earth are left behind, all with parallel arrows. In June, on the right, the north half leans toward the Sun and is lit. In December, on the left of the path, the north half leans away from the Sun and is in shade. The south half does the opposite.") { ctx, s, t, _ in
            scene(&ctx, s) { c in draw(&c, t) }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ t: Double) {
        ctx.opacity = 1 - pr(t, 13.2, 14)
        let pen = eio(pr(t, 0.1, 1.3))
        let C = pt(171.5, 170), rx = 126.0, ry = 50.0, er = 19.0
        Sketch.ink(&ctx, Sketch.oval(C, rx, ry, n: 56), closed: true, t: t, seed: 501, width: 2.2, drawn: pen)
        func place(_ th: Double) -> CGPoint { pt(C.x + rx * cos(th), C.y + ry * sin(th)) }
        func toSun(_ th: Double) -> CGPoint {
            let vx = -rx * cos(th), vy = -ry * sin(th), d = hypot(vx, vy)
            return pt(vx / d, vy / d)
        }
        // where Earth is on its trip: December on the left (pi), June on the right (2 pi), December again (3 pi)
        let th = Double.pi + Double.pi * eio(pr(t, 2.4, 5.6)) + Double.pi * eio(pr(t, 6.8, 10.0))
        // stamps left behind, one every eighth of the trip
        for k in 0..<8 {
            let thk = Double.pi + Double.pi * Double(k) / 4
            let a = k == 0 ? pr(t, 1.5, 2.1) * 0.6 : pr(th, thk + 0.05, thk + 0.5) * 0.6
            if a > 0.01 {
                var l = ctx
                l.opacity = ctx.opacity * a
                globeDraw(&l, c: place(thk), r: er, lean: SN.leanDeg, spin: 0, light: toSun(thk), t: t, seed: 520 + k * 3, detail: false, nightAlpha: 0.5, arrowLen: 1.75)
            }
        }
        sunDraw(&ctx, C, 24, t: t, seed: 530, alpha: pr(t, 0.2, 0.9))
        let ea = pr(t, 1.5, 2.1)
        if ea > 0.01 {
            var l = ctx
            l.opacity = ctx.opacity * ea
            globeDraw(&l, c: place(th), r: er, lean: SN.leanDeg, spin: t * 45, light: toSun(th), t: t, seed: 560, nightAlpha: 0.5, arrowLen: 1.9, showN: true)
        }
        // the one idea, across the top
        let ba = pr(t, 2.0, 2.6)
        say(&ctx, "THE LEAN NEVER TURNS", pt(171.5, 24), size: 21, t: t, seed: 570, alpha: ba, font: "MarkerFelt-Wide")
        if ba > 0.95 {
            Sketch.ink(&ctx, [pt(30, 42), pt(90, 45), pt(171, 42), pt(252, 45), pt(313, 42)], closed: false, t: t, seed: 571, width: 1.8, color: SN.red, drawn: pr(t, 2.4, 3.0))
        }
        // June (right) and December (left)
        let ja = pr(t, 5.6, 6.2), da = pr(t, 10.0, 10.6)
        say(&ctx, "JUNE:", pt(335, 270), size: 17, t: t, seed: 580, alpha: ja, anchor: .trailing)
        say(&ctx, "NORTH LEANS IN", pt(335, 290), size: 17, t: t, seed: 581, color: SN.sunDeep, alpha: ja, anchor: .trailing)
        if ja > 0.9 { arrow(&ctx, [pt(304, 256), pt(302, 232), pt(299, 210)], t: t, seed: 582, width: 1.8, drawn: pr(t, 5.9, 6.4)) }
        say(&ctx, "DECEMBER:", pt(8, 270), size: 17, t: t, seed: 590, alpha: da, anchor: .leading)
        say(&ctx, "NORTH LEANS AWAY", pt(8, 290), size: 17, t: t, seed: 591, color: SN.blue, alpha: da, anchor: .leading)
        if da > 0.9 { arrow(&ctx, [pt(40, 256), pt(42, 232), pt(44, 210)], t: t, seed: 592, width: 1.8, drawn: pr(t, 10.3, 10.8)) }
        burst(&ctx, pt(C.x + rx + 22, C.y - 34), r0: 6, r1: 6 + 8 * pr(t, 5.7, 6.1), angles: [-2.4, -1.57, -0.74], t: t, seed: 595, alpha: pr(t, 5.7, 6.1) * (1 - pr(t, 6.5, 7.0)), color: SN.sunDeep)
    }
}

// MARK: - Card 4 (hands-on): a torch over a table; drag to tilt it

struct SeasonsTorch: View {
    let active: Bool
    @State private var phi: Double? = nil        // degrees, set once the reader drags
    @State private var base: Double? = nil       // the tilt when the current drag began
    @State private var t0 = Date()
    @Environment(\.accessibilityReduceMotion) private var reduce

    private static let maxPhi = 50.0
    /// The torch swings by itself until the reader takes hold: rest, tilt, rest, back.
    private static func autoPhi(_ el: Double) -> Double {
        let c = el.truncatingRemainder(dividingBy: 9)
        return 44 * (eio(pr(c, 1, 3.6)) - eio(pr(c, 5.4, 8.2)))
    }

    var body: some View {
        TimelineView(.animation(paused: !active || reduce)) { tl in
            Canvas { ctx, s in
                let el = reduce ? 0 : tl.date.timeIntervalSince(t0)
                let p = phi ?? (reduce ? 0 : Self.autoPhi(el))
                scene(&ctx, s) { c in SeasonsTorch.draw(&c, el, p, hint: phi == nil && !reduce ? 1 : 0) }
            }
        }
        .background(LinearGradient(colors: Sketch.paper.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
        .overlay {
            // a drag handle around the torch only, so swipes elsewhere on the picture still turn the page
            GeometryReader { g in
                let u = min(g.size.width / 343, g.size.height / 320)
                let ox = (g.size.width - 343 * u) / 2, oy = (g.size.height - 320 * u) / 2
                Color.clear
                    .frame(width: 120 * u, height: 120 * u)
                    .contentShape(Rectangle())
                    .position(x: ox + 62 * u, y: oy + 56 * u)
                    .highPriorityGesture(drag)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
        .onChange(of: active) { _, a in if a { t0 = Date() } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A torch above a table. Dragging the torch sideways tilts it. Held straight down, it makes a small, bright spot of light on the table. Tilted, the same light spreads into a long, dim patch. Until you touch it, the torch swings slowly back and forth by itself.")
        .accessibilityValue(phi.map { "Tilted \(Int($0)) degrees" } ?? "Swinging by itself")
        .accessibilityAdjustableAction { dir in
            let cur = phi ?? 0
            phi = min(Self.maxPhi, max(0, cur + (dir == .increment ? 10 : -10)))
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { v in
                if base == nil {
                    base = phi ?? (reduce ? 0 : Self.autoPhi(Date().timeIntervalSince(t0)))
                    if phi == nil { Haptic.fire(.soft) }
                }
                let old = phi ?? base ?? 0
                let new = min(Self.maxPhi, max(0, (base ?? 0) + v.translation.width * 0.4))
                if (old < 22) != (new < 22) { Haptic.fire(.light) }
                phi = new
            }
            .onEnded { _ in base = nil }
    }

    private static func draw(_ ctx: inout GraphicsContext, _ t: Double, _ phiDeg: Double, hint: Double) {
        let yT = 206.0, px = 62.0, py = 76.0, H = yT - py
        let beta = 11.0 * Double.pi / 180
        let p = phiDeg * Double.pi / 180
        let pen = eio(pr(t, 0.1, 1.2))
        let wood = Color(hex: 0xF3D9A8), woodDark = Color(hex: 0xDDB178)

        // the table
        let top = [pt(22, yT - 26), pt(321, yT - 26), pt(338, yT + 22), pt(5, yT + 22)]
        Sketch.ink(&ctx, top, closed: true, t: t, seed: 601, width: 2.2, fill: wood, drawn: pen)
        Sketch.ink(&ctx, [pt(5, yT + 22), pt(338, yT + 22), pt(338, yT + 38), pt(5, yT + 38)], closed: true, t: t, seed: 602, width: 2.2, fill: woodDark, drawn: pen)
        for (i, x) in [24.0, 306.0].enumerated() {
            Sketch.ink(&ctx, [pt(x, yT + 38), pt(x, yT + 62), pt(x + 12, yT + 62), pt(x + 12, yT + 38)], closed: false, t: t, seed: 603 + i, width: 2.2, fill: woodDark, drawn: pen)
        }
        for i in 0..<5 {   // wood grain
            let x = 40 + Double(i) * 60
            Sketch.ink(&ctx, [pt(x, yT + 30), pt(x + 22, yT + 30)], closed: false, t: t, seed: 610 + i, width: 1, color: SN.ink.opacity(0.35), amp: 0.4)
        }

        // where the beam lands
        let e1 = px + H * tan(p - beta), e2 = px + H * tan(p + beta)
        let len = e2 - e1, mid = (e1 + e2) / 2
        let l0 = 2 * H * tan(beta)
        let bright = cl(pow(l0 / len, 1.2))
        let spotC = pt(mid, yT - 2)
        let fillC = Color(red: mix(0.99, 0.98, bright), green: mix(0.94, 0.80, bright), blue: mix(0.72, 0.25, bright)).opacity(mix(0.6, 1, bright))
        ctx.drawLayer { l in
            l.clip(to: Sketch.path(top, closed: true, t: t, seed: 601))
            Sketch.ink(&l, Sketch.oval(spotC, len / 2, 12, n: 28), closed: true, t: t, seed: 620, width: 1.8, fill: fillC, drawn: pen)
            Sketch.ink(&l, Sketch.oval(spotC, len / 4, 6, n: 18), closed: true, t: t, seed: 621, width: 0.1, color: .clear, fill: Color(hex: 0xFFF6C8).opacity(bright))
        }
        // the beam
        var cone = Path()
        cone.move(to: pt(px, py)); cone.addLine(to: pt(e1, yT - 2)); cone.addLine(to: pt(e2, yT - 2)); cone.closeSubpath()
        ctx.fill(cone, with: .color(Color(hex: 0xFFE680).opacity(0.28)))
        var edges = Path()
        edges.move(to: pt(e1, yT - 2)); edges.addLine(to: pt(px, py)); edges.addLine(to: pt(e2, yT - 2))
        ctx.stroke(edges, with: .color(SN.sunDeep.opacity(0.6)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [5, 4]))
        // cartoon shine around a small bright spot
        let shine = cl((bright - 0.55) / 0.45)
        if shine > 0.01 {
            for i in 0..<7 {
                let a = Double.pi * (1.1 + 0.8 * Double(i) / 6)
                let rr = len / 2
                Sketch.ink(&ctx, [pt(mid + (rr + 5) * cos(a), yT - 2 + (12 + 5) * sin(a) * 1.0), pt(mid + (rr + 12) * cos(a), yT - 2 + (12 + 14) * sin(a))],
                           closed: false, t: t, seed: 630 + i, width: 2, color: SN.sunDeep.opacity(shine), amp: 0.4)
            }
        }

        // the torch, hung on its tip and turning round it
        var g = ctx
        g.translateBy(x: px, y: py)
        g.rotate(by: .radians(-p))
        Sketch.ink(&g, [pt(-7, -14), pt(7, -14), pt(7, -48), pt(-7, -48)], closed: true, t: t, seed: 640, width: 2.2, fill: SN.red, drawn: pen)
        Sketch.ink(&g, [pt(-11, 0), pt(11, 0), pt(7, -14), pt(-7, -14)], closed: true, t: t, seed: 641, width: 2.2, fill: Color(hex: 0xC9CED6), drawn: pen)
        Sketch.ink(&g, [pt(-3, -26), pt(3, -26), pt(3, -34), pt(-3, -34)], closed: true, t: t, seed: 642, width: 1.4, fill: Color(hex: 0x6B7280), drawn: pen)
        Sketch.ink(&g, Sketch.oval(pt(0, 0), 11, 3.4, n: 14), closed: true, t: t, seed: 643, width: 1.6, fill: Color(hex: 0xFFF6C8), amp: 0.4)

        // a hint until the reader takes hold
        if hint > 0 {
            let a = 0.55 + 0.35 * sin(t * 3)
            var arc: [CGPoint] = []
            for i in 0...6 { let d = (6.0 + 36 * Double(i) / 6) * Double.pi / 180; arc.append(pt(px + 70 * sin(d), py + 70 * cos(d))) }
            arrow(&ctx, arc, t: t, seed: 650, width: 1.8, color: SN.red.opacity(a), head: 7, drawn: pr(t, 1.2, 1.8))
            say(&ctx, "drag", pt(px + 90 * sin(0.42), py + 90 * cos(0.42)), size: 14, t: t, seed: 655, color: SN.red, alpha: a * pr(t, 1.4, 2.0), anchor: .leading)
        }

        // what it shows
        let sa = 1 - pr(phiDeg, 10, 20), ta = pr(phiDeg, 20, 30)
        say(&ctx, "STRAIGHT: SMALL, BRIGHT SPOT", pt(171.5, 296), size: 18, t: t, seed: 660, color: SN.sunDeep, alpha: sa * pr(t, 0.6, 1.2))
        say(&ctx, "TILTED: LONG, DIM PATCH", pt(171.5, 296), size: 18, t: t, seed: 661, color: SN.blue, alpha: ta)
    }
}

// MARK: - Card 5: Earth spinning seen from above its north pole; London spends most of a June spin in light and most of a December spin in the dark

struct SeasonsDay: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 13, still: 5, cues: [Cue(2.0, .soft), Cue(6.8, .light)], replayOnTap: true, sky: Sketch.paper,
                    label: "Earth seen from above its north pole, spinning, with the Sun on the left lighting the day side and the right side in night. A red dot for London goes round once every day along a ring. In June most of the ring is lit, so London spends most of its spin in daylight. Then the picture moves on to December, when most of the ring is dark, so London spends most of its spin in the dark.") { ctx, s, t, _ in
            scene(&ctx, s) { c in draw(&c, t) }
        }
    }

    private static let lat = 51.5 * Double.pi / 180
    // landmasses seen from the north pole: centre longitude and latitude, half-sizes in degrees
    private static let lands: [(lon: Double, lat: Double, dlon: Double, dlat: Double)] = [
        (-100, 48, 36, 22), (12, 49, 14, 8), (-3, 54, 3.5, 4.5), (80, 50, 62, 20), (20, 10, 26, 24), (-42, 72, 15, 8), (140, 36, 7, 7)
    ]

    private func draw(_ ctx: inout GraphicsContext, _ t: Double) {
        ctx.opacity = 1 - pr(t, 12.3, 13)
        let pen = eio(pr(t, 0.1, 1.3))
        let C = pt(214, 160), R = 98.0
        let spin = 140 + 105 * t
        let delta = mix(23.4, -23.4, eio(pr(t, 5.4, 6.6))) * Double.pi / 180
        let lat = Self.lat
        func at(_ lonDeg: Double, _ latDeg: Double, _ rr: Double) -> CGPoint {
            let a = (lonDeg + spin) * Double.pi / 180, rad = rr * cos(max(latDeg, 0) * Double.pi / 180)
            return pt(C.x - rad * cos(a), C.y + rad * sin(a))
        }

        // the Sun on the left, its light heading for Earth
        sunDraw(&ctx, pt(46, C.y), 21, t: t, seed: 700, alpha: pr(t, 0.2, 0.9))
        let la = pr(t, 0.8, 1.4)
        for (i, dy) in [-46.0, 0, 46].enumerated() {
            arrow(&ctx, [pt(88, C.y + dy), pt(108, C.y + dy)], t: t, seed: 710 + i * 8, width: 2, color: SN.sunDeep.opacity(la), head: 6, drawn: la)
        }

        // Earth from above: sea, land turning with the spin, the night side
        let pts = Sketch.oval(C, R, R, n: 48)
        let disc = Sketch.path(pts, closed: true, t: t, seed: 720, amp: 1.2)
        ctx.fill(disc, with: .color(SN.sea.opacity(pr(t, 0.4, 1.0))))
        ctx.drawLayer { l in
            l.clip(to: disc)
            for (i, b) in Self.lands.enumerated() {
                var poly: [CGPoint] = []
                for k in 0..<12 {
                    let a = Double(k) / 12 * 2 * .pi
                    let nz = 0.85 + 0.3 * Sketch.rnd(i * 17 + k)
                    poly.append(at(b.lon + b.dlon * cos(a) * nz, b.lat + b.dlat * sin(a) * nz, R))
                }
                Sketch.ink(&l, poly, closed: true, t: t, seed: 730 + i, width: 1.6, fill: SN.land.opacity(pr(t, 0.6, 1.2)), amp: 0.8)
            }
            // night: from the terminator (an ellipse that bulges one way in June and the other in December) round the far side
            var night = Path()
            for i in 0...24 {
                let a = Double.pi * Double(i) / 24
                let p = pt(C.x + R * sin(delta) * sin(a), C.y - R * cos(a))
                if i == 0 { night.move(to: p) } else { night.addLine(to: p) }
            }
            for i in 0...24 {
                let a = Double.pi / 2 - Double.pi * Double(i) / 24
                night.addLine(to: pt(C.x + R * 1.02 * cos(a), C.y + R * 1.02 * sin(a)))
            }
            night.closeSubpath()
            l.fill(night, with: .color(SN.night.opacity(0.5)))
            var hatch = Path()
            for k in 0..<36 {
                let x0 = C.x - 2 * R + 6 * Double(k)
                hatch.move(to: pt(x0, C.y + R)); hatch.addLine(to: pt(x0 + 2 * R, C.y - R))
            }
            l.clip(to: night)
            l.stroke(hatch, with: .color(SN.ink.opacity(0.16)), lineWidth: 1)
        }
        Sketch.ink(&ctx, pts, closed: true, t: t, seed: 720, width: 2.4, drawn: pen, amp: 1.2)

        // London's ring: gold where it is day, navy where it is night
        let rr = R * cos(lat)
        let ra = pr(t, 1.8, 2.4)
        if ra > 0.01 {
            var day = Path(), dark = Path()
            let n = 90
            for i in 0..<n {
                let a0 = 2 * Double.pi * Double(i) / Double(n), a1 = 2 * Double.pi * Double(i + 1) / Double(n)
                let am = (a0 + a1) / 2
                let lit = cos(am) > -tan(lat) * tan(delta)
                let p0 = pt(C.x - rr * cos(a0), C.y + rr * sin(a0)), p1 = pt(C.x - rr * cos(a1), C.y + rr * sin(a1))
                if lit { day.move(to: p0); day.addLine(to: p1) } else { dark.move(to: p0); dark.addLine(to: p1) }
            }
            let st = StrokeStyle(lineWidth: 5, lineCap: .butt)
            ctx.stroke(day, with: .color(SN.sun.opacity(ra)), style: st)
            ctx.stroke(dark, with: .color(Color(hex: 0x1D2757).opacity(ra * 0.9)), style: st)
        }
        // London itself, going round
        let london = at(0, 51.5, R)
        let da = pr(t, 1.2, 1.8)
        if da > 0.01 {
            Sketch.ink(&ctx, Sketch.oval(london, 7.5, 7.5, n: 14), closed: true, t: t, seed: 760, width: 2.2, color: .white.opacity(da), fill: SN.red.opacity(da), amp: 0.4)
        }
        Sketch.ink(&ctx, Sketch.oval(C, 2.5, 2.5, n: 8), closed: true, t: t, seed: 761, width: 1.4, fill: SN.ink, amp: 0.2)

        // words
        let w = pr(t, 1.4, 2.0)
        say(&ctx, "DAY", pt(C.x - 52, 24), size: 20, t: t, seed: 770, color: SN.sunDeep, alpha: w)
        say(&ctx, "NIGHT", pt(C.x + 52, 24), size: 20, t: t, seed: 771, color: SN.blue, alpha: w)
        let june = pr(t, 1.8, 2.4) * (1 - pr(t, 5.4, 5.9)), dec = pr(t, 6.2, 6.8)
        for (a, name, w0) in [(june, "LONDON IN JUNE", 148.0), (dec, "LONDON IN DECEMBER", 190.0)] {
            say(&ctx, name, pt(185, 296), size: 19, t: t, seed: name.count * 7, alpha: a)
            if a > 0.01 {
                Sketch.ink(&ctx, Sketch.oval(pt(185 - w0 / 2 - 13, 296), 6, 6, n: 12), closed: true, t: t, seed: 780, width: 1.8, color: .white.opacity(a), fill: SN.red.opacity(a), amp: 0.3)
            }
        }
        burst(&ctx, pt(C.x, C.y - R - 4), r0: 4, r1: 4 + 7 * pr(t, 6.6, 7.0), angles: [-2.2, -1.57, -0.94], t: t, seed: 790, alpha: pr(t, 6.6, 7.0) * (1 - pr(t, 7.4, 7.9)), color: SN.blue)
    }
}
