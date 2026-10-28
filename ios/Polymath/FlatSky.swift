import SwiftUI

// "Why is the sky blue, but red at sunset?" topic: five flat Canvas scenes. First build, 2026-10-26.
// Warm sunny colours. Air particles and light waves are drawn much bigger than they are, and the air layer much thicker (every scene says so on screen).
// Card 5 is hands-on (a slider moves the Sun from high to low) and plays a silent demo until it is touched.

private func cl(_ x: Double) -> Double { min(1, max(0, x)) }
private func pr(_ t: Double, _ a: Double, _ b: Double) -> Double { cl((t - a) / (b - a)) }
private func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }

/// Blend between two hex colours.
private func mix(_ a: UInt32, _ b: UInt32, _ k: Double) -> Color {
    func ch(_ v: UInt32, _ shift: UInt32) -> Double { Double((v >> shift) & 0xFF) }
    let k = cl(k)
    return Color(red: (ch(a, 16) + (ch(b, 16) - ch(a, 16)) * k) / 255,
                 green: (ch(a, 8) + (ch(b, 8) - ch(a, 8)) * k) / 255,
                 blue: (ch(a, 0) + (ch(b, 0) - ch(a, 0)) * k) / 255)
}

private enum SK {
    static let sun = Color(hex: 0xFFC94A), sunPale = Color(hex: 0xFFF2B0), sunHot = Color(hex: 0xFF7A3D)
    static let blue = Color(hex: 0x1450D6), blueText = Color(hex: 0x8CC8FF), blueBright = Color(hex: 0x4DA3FF)
    static let red = Color(hex: 0xE8452E), redText = Color(hex: 0xFF9A84), redBright = Color(hex: 0xFF5A4A)
    static let skin = Color(hex: 0xF4B48C), shirt = Color(hex: 0x5FC4B4), trousers = Color(hex: 0x4A5A8A)
    static let earth = Color(hex: 0x6FBE6A), earthDark = Color(hex: 0x3F8F55)
    /// The seven bands of sunlight, red to violet.
    static let spectrum: [UInt32] = [0xFF4B4B, 0xFF9A3C, 0xFFD84A, 0x5CD06B, 0x3F9BFF, 0x6A5CFF, 0xA46BFF]
}

/// Rough chip width, to keep a chip inside the picture.
private func chipW(_ text: String, _ size: Double) -> Double { Double(text.count) * size * 0.66 + 18 }
/// Clamp a centred chip's x so the whole chip stays inside a width.
private func fitX(_ x: Double, _ text: String, _ size: Double, _ w: Double) -> Double {
    let half = chipW(text, size) / 2
    return min(max(x, half + 4), w - half - 4)
}

/// An arrow from a to b.
private func arrow(_ ctx: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ color: Color, width: Double = 3, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    let dx = b.x - a.x, dy = b.y - a.y, len = hypot(dx, dy)
    guard len > 2 else { return }
    let ux = dx / len, uy = dy / len
    let head = min(len * 0.6, 6 + width * 2)
    let base = CGPoint(x: b.x - ux * head, y: b.y - uy * head)
    var shaft = Path(); shaft.move(to: a); shaft.addLine(to: base)
    ctx.stroke(shaft, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: width, lineCap: .round))
    var tip = Path()
    tip.move(to: b)
    tip.addLine(to: CGPoint(x: base.x - uy * head * 0.6, y: base.y + ux * head * 0.6))
    tip.addLine(to: CGPoint(x: base.x + uy * head * 0.6, y: base.y - ux * head * 0.6))
    tip.closeSubpath()
    ctx.fill(tip, with: .color(color.opacity(alpha)))
}

private func note(_ ctx: inout GraphicsContext, _ text: String, at p: CGPoint, anchor: UnitPoint, alpha: Double = 0.9) {
    Kit.chip(&ctx, text, p, anchor: anchor, color: .white.opacity(0.9), size: 7, alpha: alpha)
}

/// The Sun: a soft glow, turning rays and a bright disc. `hot` 0...1 shifts it from yellow toward orange-red.
private func sunDisc(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, hot: Double = 0, t: Double = 0, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    var l = ctx; l.opacity = alpha
    let edge = mix(0xFFC94A, 0xFF5A2E, hot)
    let gr = r * 2.6
    l.fill(Path(ellipseIn: CGRect(x: c.x - gr, y: c.y - gr, width: 2 * gr, height: 2 * gr)),
           with: .radialGradient(Gradient(colors: [edge.opacity(0.55), .clear]), center: c, startRadius: r * 0.7, endRadius: gr))
    for i in 0..<10 {
        let a = Double(i) / 10 * 2 * .pi + t * 0.25
        let r1 = r * (1.2 + 0.05 * sin(t * 2 + Double(i))), r2 = r * (1.42 + 0.12 * sin(t * 2 + Double(i)))
        var p = Path()
        p.move(to: CGPoint(x: c.x + r1 * cos(a), y: c.y + r1 * sin(a)))
        p.addLine(to: CGPoint(x: c.x + r2 * cos(a), y: c.y + r2 * sin(a)))
        l.stroke(p, with: .color(edge.opacity(0.9)), style: StrokeStyle(lineWidth: max(1.6, r * 0.09), lineCap: .round))
    }
    l.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
           with: .radialGradient(Gradient(colors: [SK.sunPale, mix(0xFFC94A, 0xFF8A4A, hot), edge]), center: c, startRadius: 0, endRadius: r))
}

/// A simple person standing on `foot`, with arms and hands. With `face` they face us and look up with both eyes; without, they are drawn from behind. Returns where the eyes are.
@discardableResult
private func person(_ ctx: inout GraphicsContext, foot: CGPoint, height hgt: Double, face: Bool = false) -> CGPoint {
    let hr = hgt * 0.15
    let head = CGPoint(x: foot.x, y: foot.y - hgt + hr)
    let bw = hgt * 0.28
    let torso = CGRect(x: foot.x - bw / 2, y: head.y + hr * 0.9, width: bw, height: hgt * 0.4)
    for dx in [-0.22, 0.22] {
        var leg = Path(); leg.move(to: CGPoint(x: foot.x + dx * bw, y: torso.maxY - 2)); leg.addLine(to: CGPoint(x: foot.x + dx * bw, y: foot.y))
        ctx.stroke(leg, with: .color(SK.trousers), style: StrokeStyle(lineWidth: bw * 0.38, lineCap: .round))
    }
    ctx.fill(Path(roundedRect: torso, cornerRadius: bw * 0.35), with: .color(SK.shirt))
    for sgn in [-1.0, 1.0] {
        let shoulder = CGPoint(x: foot.x + sgn * bw * 0.4, y: torso.minY + bw * 0.3)
        let hand = CGPoint(x: foot.x + sgn * bw * 0.82, y: torso.minY + torso.height * 0.8)
        var arm = Path(); arm.move(to: shoulder); arm.addLine(to: hand)
        ctx.stroke(arm, with: .color(SK.shirt), style: StrokeStyle(lineWidth: bw * 0.26, lineCap: .round))
        let hrad = bw * 0.15
        ctx.fill(Path(ellipseIn: CGRect(x: hand.x - hrad, y: hand.y - hrad, width: 2 * hrad, height: 2 * hrad)), with: .color(SK.skin))
    }
    ctx.fill(Path(ellipseIn: CGRect(x: head.x - hr, y: head.y - hr, width: 2 * hr, height: 2 * hr)), with: .color(SK.skin))
    guard face else { return CGPoint(x: head.x + hr * 0.25, y: head.y - hr * 0.1) }
    let ink = Color(hex: 0x2A1A10)
    for sgn in [-1.0, 1.0] {
        let e = CGPoint(x: head.x + sgn * hr * 0.4, y: head.y - hr * 0.1)
        let ew = hr * 0.34, eh = hr * 0.4
        ctx.fill(Path(ellipseIn: CGRect(x: e.x - ew, y: e.y - eh, width: 2 * ew, height: 2 * eh)), with: .color(.white))
        let pr = hr * 0.17
        ctx.fill(Path(ellipseIn: CGRect(x: e.x - pr, y: e.y - eh * 0.85, width: 2 * pr, height: 2 * pr)), with: .color(ink))   // pupils at the top: looking up
    }
    var smile = Path()
    smile.move(to: CGPoint(x: head.x - hr * 0.3, y: head.y + hr * 0.42))
    smile.addQuadCurve(to: CGPoint(x: head.x + hr * 0.3, y: head.y + hr * 0.42), control: CGPoint(x: head.x, y: head.y + hr * 0.75))
    ctx.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: max(1.2, hr * 0.1), lineCap: .round))
    return CGPoint(x: head.x, y: head.y - hr * 0.1)
}

// MARK: - Card 1: one scene. The Sun crosses the sky and the sky changes colour with it

struct SkyTwo: View {
    let active: Bool
    private static let day = 8.0
    var body: some View {
        FlatPicture(active: active, period: Self.day, still: 0, replayOnTap: true, sky: [0x3B93E8, 0x7CC4FA, 0xBFE5FF],
                    label: "One landscape and one Sun. The Sun starts high at noon in a blue sky, then slides across and sinks to the horizon at sunset while the whole sky turns orange and red. It is the same sky and the same Sun.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let horizon = h * 0.8
            let u = (0.5 + t / Self.day).truncatingRemainder(dividingBy: 1)     // 0 sunrise, 0.5 noon, 1 sunset
            let alt = sin(.pi * u)                                              // 0 on the horizon, 1 straight up
            let red = 1 - eio(pr(alt, 0.1, 0.55))                               // 0 = blue noon sky, 1 = sunset sky

            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon + 20)),
                     with: .linearGradient(Gradient(colors: [mix(0x2E8FEA, 0x5B4B9E, red), mix(0x6CBBF6, 0xE2566B, red), mix(0xBFE5FF, 0xFFB45A, red)]),
                                           startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)))
            let r = min(w * 0.07, h * 0.06)
            let sun = CGPoint(x: w * (0.14 + 0.72 * u), y: horizon + r * 0.6 - alt * (horizon + r * 0.6 - h * 0.18))
            sunDisc(&ctx, sun, r, hot: red, t: t)

            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: horizon + 4)); hill.addQuadCurve(to: CGPoint(x: w, y: horizon + 4), control: CGPoint(x: w / 2, y: horizon - 16))
            hill.addLine(to: CGPoint(x: w, y: h)); hill.addLine(to: CGPoint(x: 0, y: h)); hill.closeSubpath()
            ctx.fill(hill, with: .linearGradient(Gradient(colors: [mix(0x7BCB6B, 0x5A3468, red), mix(0x4FA85A, 0x33203F, red)]),
                                                 startPoint: CGPoint(x: 0, y: horizon - 10), endPoint: CGPoint(x: 0, y: h)))

            // NOON under the high Sun; SUNSET above the Sun as it sinks
            let noonA = pr(alt, 0.8, 0.95)
            Kit.chip(&ctx, "NOON", CGPoint(x: fitX(sun.x, "NOON", 8, w), y: sun.y + r * 1.8 + 10), anchor: .top, color: .white, size: 8, alpha: noonA)
            let setA = u > 0.5 ? pr(0.42 - alt, 0, 0.1) * pr(alt, 0.02, 0.08) : 0
            Kit.chip(&ctx, "SUNSET", CGPoint(x: fitX(sun.x, "SUNSET", 8, w), y: sun.y - r * 2.2 - 8), anchor: .bottom, color: Color(hex: 0xFFE0C0), size: 8, alpha: setA)
            Kit.chip(&ctx, "SAME SKY, SAME SUN", CGPoint(x: w / 2, y: h * 0.93), color: .white, size: 8)
        }
    }
}

// MARK: - Card 2: sunlight splits into colours, and each colour is a wave: red long, blue short

struct SkyColours: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 11, still: 7, cues: [Cue(1.2, .soft), Cue(3.2, .light)], replayOnTap: true, sky: [0x2A2358, 0x3E2A6B, 0x5A3470],
                    label: "Sunlight, a white beam, enters a glass prism and fans out into a band of colours: red, orange, yellow, green, blue and violet. Below, two waves of light travel along. The red wave is long and stretched out. The blue wave is shorter, with its crests closer together. The waves are drawn much bigger than they really are.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let py = h * 0.27
            let ps = h * 0.2
            // the Sun and its white beam
            let sunC = CGPoint(x: 18, y: py)
            sunDisc(&ctx, sunC, 9, t: t)
            let apex = CGPoint(x: w * 0.4, y: py - ps * 0.62)
            let lb = CGPoint(x: w * 0.4 - ps * 0.6, y: py + ps * 0.42), rb = CGPoint(x: w * 0.4 + ps * 0.6, y: py + ps * 0.42)
            let enterX = apex.x + (py - apex.y) / (lb.y - apex.y) * (lb.x - apex.x)
            let ey = py + ps * 0.1
            let exitX = apex.x + (ey - apex.y) / (rb.y - apex.y) * (rb.x - apex.x)
            _ = enterX
            let grow = eio(pr(t, 0.3, 1.2))
            var beam = Path(); beam.move(to: CGPoint(x: 30, y: py)); beam.addLine(to: CGPoint(x: 30 + (exitX - 30) * grow, y: py + (ey - py) * grow))
            ctx.stroke(beam, with: .color(.white.opacity(0.25)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
            ctx.stroke(beam, with: .color(.white), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            // the colours fan out of the prism
            let fan = eio(pr(t, 1.2, 2.4))
            let endX = exitX + (w - 8 - exitX) * fan
            let spread = h * 0.13
            let c0 = CGPoint(x: exitX, y: ey)
            for i in 0..<6 {
                let f0 = Double(i) / 6, f1 = Double(i + 1) / 6
                var q = Path()
                q.move(to: c0); q.addLine(to: CGPoint(x: endX, y: ey + (f0 - 0.5) * spread * 2.6)); q.addLine(to: CGPoint(x: endX, y: ey + (f1 - 0.5) * spread * 2.6)); q.closeSubpath()
                ctx.fill(q, with: .color(Color(hex: SK.spectrum[i]).opacity(0.92)))
            }
            // the prism
            var prism = Path(); prism.move(to: apex); prism.addLine(to: rb); prism.addLine(to: lb); prism.closeSubpath()
            ctx.fill(prism, with: .linearGradient(Gradient(colors: [Color(hex: 0xE6F4FF).opacity(0.55), Color(hex: 0xA9D3FF).opacity(0.28)]), startPoint: apex, endPoint: CGPoint(x: apex.x, y: lb.y)))
            ctx.stroke(prism, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
            Kit.chip(&ctx, "SUNLIGHT", CGPoint(x: 10, y: py - 22), anchor: .bottomLeading, color: SK.sun, size: 8, alpha: pr(t, 0.2, 0.6))
            Kit.chip(&ctx, "SPLIT INTO COLOURS", CGPoint(x: w - 14, y: ey - spread * 1.4 - 8), anchor: .bottomTrailing, color: .white, size: 8, alpha: pr(t, 2.0, 2.5))

            // two waves of light: red long, blue short. They travel to the right.
            var dv = Path(); dv.move(to: CGPoint(x: 10, y: h * 0.52)); dv.addLine(to: CGPoint(x: w - 10, y: h * 0.52))
            ctx.stroke(dv, with: .color(.white.opacity(0.2)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            let lamR = w * 0.3, lamB = lamR / 1.6, amp = min(11.0, h * 0.03)
            let waves: [(Double, Double, Color, Color, String, Color, Double)] = [
                (h * 0.7, lamR, SK.redBright, SK.redText, "RED: LONG WAVE", SK.redText, 3.0),
                (h * 0.88, lamB, SK.blueBright, SK.blueText, "BLUE: SHORT WAVE", SK.blueText, 3.6)]
            for (cy, lam, col, _, txt, tcol, at) in waves {
                let reveal = eio(pr(t, at, at + 1.0))
                let x1 = 10 + (w - 20) * reveal
                var wp = Path()
                var x = 10.0
                wp.move(to: CGPoint(x: x, y: cy - amp * sin(2 * .pi * (x / lam - t * 0.45))))
                while x < x1 {
                    x = min(x + 3, x1)
                    wp.addLine(to: CGPoint(x: x, y: cy - amp * sin(2 * .pi * (x / lam - t * 0.45))))
                }
                ctx.stroke(wp, with: .color(col.opacity(0.25)), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                ctx.stroke(wp, with: .color(col), style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                Kit.chip(&ctx, txt, CGPoint(x: 10, y: cy - amp - 7), anchor: .bottomLeading, color: tcol, size: 8, alpha: pr(t, at + 0.3, at + 0.7))
            }
            note(&ctx, "WAVES DRAWN MUCH BIGGER", at: CGPoint(x: w - 8, y: h - 6), anchor: .bottomTrailing, alpha: 0.85 * pr(t, 4.2, 4.6))
        }
    }
}

// MARK: - Card 3: mixed light crosses air; the particles bounce blue in new directions much more than red

struct SkyBounce: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 9, still: 6.5, cues: [Cue(1.0, .light), Cue(1.6, .light), Cue(2.2, .light), Cue(2.8, .light), Cue(3.4, .light), Cue(4.4, .soft)], replayOnTap: true, sky: [0xFFF6E3, 0xFFEBCB, 0xFFDDB0],
                    label: "A beam of mixed sunlight crosses a patch of air, drawn from the side. Air particles, drawn much bigger than they are, sit in its path. Five blue arrows hit particles and bounce off in new directions: blue is bounced often. One red arrow slips between the particles and carries on to the other side: red is bounced less.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let ym = h * 0.46
            let patch = CGRect(x: w * 0.17, y: h * 0.12, width: w * 0.66, height: h * 0.68)
            let fade = 1 - pr(t, 8.2, 9.0)

            // the patch of air
            ctx.fill(Path(roundedRect: patch, cornerRadius: 14), with: .linearGradient(Gradient(colors: [Color(hex: 0xCFE8FF).opacity(0.8), Color(hex: 0xE6F3FF).opacity(0.55)]), startPoint: CGPoint(x: 0, y: patch.minY), endPoint: CGPoint(x: 0, y: patch.maxY)))
            ctx.stroke(Path(roundedRect: patch, cornerRadius: 14), with: .color(Color(hex: 0x7FB6EE).opacity(0.8)), style: StrokeStyle(lineWidth: 1.4, dash: [4, 4]))

            // the beam: mixed light going in, redder light coming out
            var band = Path()
            band.move(to: CGPoint(x: 0, y: ym - 12)); band.addLine(to: CGPoint(x: patch.maxX, y: ym - 7))
            band.addLine(to: CGPoint(x: w, y: ym - 3.5)); band.addLine(to: CGPoint(x: w, y: ym + 3.5)); band.addLine(to: CGPoint(x: patch.maxX, y: ym + 7)); band.addLine(to: CGPoint(x: 0, y: ym + 12)); band.closeSubpath()
            ctx.fill(band, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFD65A).opacity(0.62), Color(hex: 0xFFB04A).opacity(0.5), Color(hex: 0xFF8A5C).opacity(0.5)]), startPoint: .zero, endPoint: CGPoint(x: w, y: 0)))

            // five air particles on the beam, with a lane between them for red
            let rp = min(8.0, w * 0.024)
            let offs: [Double] = [-15, 15, -17, 14, -15]
            let dirs: [(Double, Double)] = [(-0.5, -0.87), (-0.5, 0.87), (0.78, -0.62), (0.55, 0.83), (0.3, -0.95)]
            var pts: [CGPoint] = []
            for i in 0..<5 { pts.append(CGPoint(x: patch.minX + patch.width * (0.16 + 0.17 * Double(i)), y: ym + offs[i])) }
            let blen = h * 0.2
            for i in 0..<5 {
                let p = pts[i]
                let go = 0.7 + 0.6 * Double(i)              // when this blue arrow leaves for its particle
                // blue light travelling in along its lane
                let k = pr(t, go, go + 0.45)
                if k > 0 && k < 1 {
                    let x1 = p.x - rp - 30 + 30 * k
                    arrow(&ctx, CGPoint(x: x1 - 14, y: p.y), CGPoint(x: x1, y: p.y), SK.blue, width: 3, alpha: fade)
                }
                // the particle
                let hit = pr(t, go + 0.45, go + 0.9)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - rp, y: p.y - rp, width: 2 * rp, height: 2 * rp)), with: .radialGradient(Gradient(colors: [.white, Color(hex: 0xCFE3F7)]), center: CGPoint(x: p.x - rp * 0.3, y: p.y - rp * 0.3), startRadius: 0, endRadius: rp * 1.3))
                ctx.stroke(Path(ellipseIn: CGRect(x: p.x - rp, y: p.y - rp, width: 2 * rp, height: 2 * rp)), with: .color(Color(hex: 0x6FA6DC)), lineWidth: 1.4)
                if hit > 0 && hit < 1 { Kit.ring(&ctx, p, rp + 12 * hit, SK.blue, alpha: 1 - hit, width: 1.6) }
                // the bounce
                let g = eio(hit)
                let d = dirs[i], dl = hypot(d.0, d.1)
                let a = CGPoint(x: p.x + d.0 / dl * (rp + 3), y: p.y + d.1 / dl * (rp + 3))
                let b = CGPoint(x: p.x + d.0 / dl * (rp + 3 + blen * g), y: p.y + d.1 / dl * (rp + 3 + blen * g))
                arrow(&ctx, a, b, SK.blue, width: 3.4, alpha: fade)
            }
            // the red light slips between them
            let rk = pr(t, 3.8, 6.0)
            if rk > 0 {
                let head = 10 + (w - 16) * eio(rk)
                let len = 34 + 160 * pr(t, 5.6, 6.4)
                arrow(&ctx, CGPoint(x: max(8, head - len), y: ym), CGPoint(x: head, y: ym), SK.red, width: 3.6, alpha: fade)
            }

            // labels
            let pc = "AIR PARTICLES (DRAWN MUCH BIGGER)"
            Kit.chip(&ctx, pc, CGPoint(x: w / 2, y: 10), anchor: .top, color: Color(hex: 0xFFF6E3), size: 7, alpha: pr(t, 0.2, 0.6))
            var lead = Path(); lead.move(to: CGPoint(x: pts[2].x, y: 32)); lead.addLine(to: CGPoint(x: pts[2].x, y: pts[2].y - rp - 3))
            ctx.stroke(lead, with: .color(Color(hex: 0x6FA6DC).opacity(0.9 * pr(t, 0.3, 0.7))), style: StrokeStyle(lineWidth: 1.2, dash: [2, 3]))
            Kit.chip(&ctx, "BLUE: BOUNCED OFTEN", CGPoint(x: w / 2, y: h * 0.865), color: SK.blueText, size: 8, alpha: pr(t, 3.0, 3.5))
            Kit.chip(&ctx, "RED: BOUNCED LESS", CGPoint(x: w / 2, y: h * 0.94), color: SK.redText, size: 8, alpha: pr(t, 5.0, 5.5))
        }
    }
}

// MARK: - Card 4: someone looks up; every patch of the sky bounces blue toward their eye

struct SkyEverywhere: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 11, still: 8, cues: [Cue(1.0, .soft), Cue(2.2, .light), Cue(4.6, .success)], replayOnTap: true, sky: [0xFFF1D6, 0xFFE8C4, 0xFFE0B0],
                    label: "A smiling person stands on the grass, arms by their sides, and looks up at the sky with both eyes. The Sun is at the top left, with its sunlight crossing the sky. Air particles, drawn much bigger than they are, are scattered all over the sky. Each one bounces blue light in many directions, and some of it travels to the person's eye. Because the particles fill the whole sky, every patch of sky glows blue.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let g = eio(pr(t, 2.0, 6.0))            // how blue the sky has become
            let ground = h * 0.88

            // the sky starts pale and turns blue as the particles go to work
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: ground + 14)),
                     with: .linearGradient(Gradient(colors: [mix(0xFFF1D6, 0x3B93E8, g), mix(0xFFE8C4, 0xB5E0FF, g)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: ground)))
            let sunC = CGPoint(x: w * 0.13, y: h * 0.12)
            let sr = min(w * 0.06, h * 0.045)

            // particles all over the sky
            let spots: [(Double, Double)] = [(0.32, 0.11), (0.54, 0.07), (0.76, 0.13), (0.92, 0.07), (0.22, 0.28), (0.44, 0.24), (0.66, 0.29), (0.88, 0.31),
                                             (0.12, 0.46), (0.34, 0.43), (0.62, 0.46), (0.86, 0.5)]
            var pts: [CGPoint] = []
            for (x, y) in spots { pts.append(CGPoint(x: w * x, y: h * y)) }
            let eyeBase = person(&ctx, foot: CGPoint(x: w / 2, y: ground + 4), height: h * 0.22, face: true)
            let eye = CGPoint(x: eyeBase.x, y: eyeBase.y)
            let rp = min(5.0, w * 0.015)

            // glows: every patch of sky shines blue
            for (i, p) in pts.enumerated() {
                let a = eio(pr(t, 1.6 + 0.2 * Double(i), 2.4 + 0.2 * Double(i)))
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 54, y: p.y - 54, width: 108, height: 108)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0x6FC0FF).opacity(0.55 * a), .clear]), center: p, startRadius: 4, endRadius: 54))
            }
            // sunlight crossing the sky
            for i in 0..<5 {
                let ang = 0.12 + 0.28 * Double(i)
                let kk = (t * 0.22 + Double(i) * 0.19).truncatingRemainder(dividingBy: 1)
                let d0 = 26 + (w * 0.8) * kk
                let a = CGPoint(x: sunC.x + d0 * cos(ang), y: sunC.y + d0 * sin(ang))
                let b = CGPoint(x: a.x + 18 * cos(ang), y: a.y + 18 * sin(ang))
                arrow(&ctx, a, b, SK.sun, width: 2.6, alpha: 0.9 * sin(.pi * kk) * pr(t, 0.2, 0.8))
            }
            sunDisc(&ctx, sunC, sr, t: t)

            // blue bounced toward the eye, and out every other way
            for (i, p) in pts.enumerated() {
                let at = 2.0 + 0.2 * Double(i)
                let on = eio(pr(t, at, at + 0.5))
                let pa = pr(t, 0.6 + 0.08 * Double(i), 1.2 + 0.08 * Double(i))
                // line and flowing dots to the eye
                let tgt = CGPoint(x: eye.x, y: eye.y - 3)
                var ln = Path(); ln.move(to: p); ln.addLine(to: tgt)
                ctx.stroke(ln, with: .color(.white.opacity(0.28 * on)), style: StrokeStyle(lineWidth: 1.2, dash: [1, 3]))
                for j in 0..<2 {
                    let k = (t * 0.42 + Double(i) * 0.13 + Double(j) * 0.5).truncatingRemainder(dividingBy: 1)
                    let q = CGPoint(x: p.x + (tgt.x - p.x) * k, y: p.y + (tgt.y - p.y) * k)
                    ctx.fill(Path(ellipseIn: CGRect(x: q.x - 3.4, y: q.y - 3.4, width: 6.8, height: 6.8)), with: .color(.white.opacity(0.85 * on)))
                    ctx.fill(Path(ellipseIn: CGRect(x: q.x - 2.3, y: q.y - 2.3, width: 4.6, height: 4.6)), with: .color(SK.blue.opacity(on)))
                }
                // short arrows leaving the particle in other directions
                for j in 0..<2 {
                    let ang = Double(i) * 1.9 + Double(j) * 3.0
                    let len = 20 * on
                    let a = CGPoint(x: p.x + (rp + 3) * cos(ang), y: p.y + (rp + 3) * sin(ang))
                    arrow(&ctx, a, CGPoint(x: a.x + len * cos(ang), y: a.y + len * sin(ang)), SK.blue, width: 2, alpha: on)
                }
                var l = ctx; l.opacity = pa
                l.fill(Path(ellipseIn: CGRect(x: p.x - rp, y: p.y - rp, width: 2 * rp, height: 2 * rp)), with: .color(.white))
                l.stroke(Path(ellipseIn: CGRect(x: p.x - rp, y: p.y - rp, width: 2 * rp, height: 2 * rp)), with: .color(Color(hex: 0x6FA6DC)), lineWidth: 1.2)
            }

            // the grass, and the person on it (drawn again over the streams)
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: ground + 8)); hill.addQuadCurve(to: CGPoint(x: w, y: ground + 8), control: CGPoint(x: w / 2, y: ground - 12))
            hill.addLine(to: CGPoint(x: w, y: h)); hill.addLine(to: CGPoint(x: 0, y: h)); hill.closeSubpath()
            ctx.fill(hill, with: .linearGradient(Gradient(colors: [Color(hex: 0x7BCB6B), Color(hex: 0x4FA85A)]), startPoint: CGPoint(x: 0, y: ground - 10), endPoint: CGPoint(x: 0, y: h)))
            let eyeP = person(&ctx, foot: CGPoint(x: w / 2, y: ground + 4), height: h * 0.22, face: true)
            if t > 2.4 { Kit.ring(&ctx, eyeP, 6 + 10 * ((t * 0.7).truncatingRemainder(dividingBy: 1)), SK.blue, alpha: 0.6 * g * (1 - (t * 0.7).truncatingRemainder(dividingBy: 1)), width: 1.4) }

            // labels
            Kit.chip(&ctx, "SUN", CGPoint(x: fitX(sunC.x, "SUN", 8, w), y: sunC.y + sr * 1.6 + 8), anchor: .top, color: SK.sun, size: 8, alpha: pr(t, 0.2, 0.6))
            let pp = pts[6]
            Kit.chip(&ctx, "PARTICLES", CGPoint(x: fitX(pp.x, "PARTICLES", 8, w), y: pp.y - rp - 22), anchor: .bottom, color: .white, size: 8, alpha: pr(t, 1.2, 1.6))
            var lead = Path(); lead.move(to: CGPoint(x: pp.x, y: pp.y - rp - 20)); lead.addLine(to: CGPoint(x: pp.x, y: pp.y - rp - 3))
            ctx.stroke(lead, with: .color(.white.opacity(0.8 * pr(t, 1.2, 1.6))), lineWidth: 1.2)
            let ev = "BLUE BOUNCES EVERY WAY"
            Kit.chip(&ctx, ev, CGPoint(x: fitX(w / 2, ev, 8, w), y: h * 0.575), color: Color(hex: 0xD8EEFF), size: 8, alpha: pr(t, 3.4, 3.9))
            Kit.chip(&ctx, "YOUR EYE", CGPoint(x: eyeP.x + 30, y: eyeP.y + 4), anchor: .leading, color: .white, size: 8, alpha: pr(t, 4.6, 5.0))
            note(&ctx, "PARTICLES DRAWN MUCH BIGGER", at: CGPoint(x: w - 8, y: h - 6), anchor: .bottomTrailing, alpha: 0.85 * pr(t, 1.2, 1.6))
        }
    }
}

// MARK: - Card 5 (hands-on): the Sun moves from high to low; the long trip through air takes the blue and leaves red

struct SkySunset: View {
    let active: Bool
    @State private var sun = 0.0          // 0 = Sun high, 1 = Sun low
    @State private var touched = false
    @State private var t0 = Date()
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        ZStack(alignment: .bottom) {
            TimelineView(.animation(paused: !active || reduce)) { tl in
                Canvas { ctx, s in draw(&ctx, s, tl.date.timeIntervalSince(t0)) }
            }
            HStack(spacing: 8) {
                Text("NOON").font(T.mono(9)).foregroundStyle(.white.opacity(0.9))
                Slider(value: Binding(get: { sun }, set: { sun = $0; if !touched { touched = true; Haptic.fire(.soft) } }), in: 0...1)
                    .tint(Pal.coral)
                Text("SUNSET").font(T.mono(9)).foregroundStyle(Pal.signal)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Pal.night.opacity(0.55)))
            .padding(.horizontal, 10).padding(.bottom, 8)
        }
        .background(Color(hex: 0x3F8F55))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
        .task(id: "\(active)-\(touched)-\(reduce)") {
            guard active, !touched else { return }
            if reduce { sun = 0.92; return }
            t0 = Date()
            while !Task.isCancelled && !touched {
                let t = Date().timeIntervalSince(t0).truncatingRemainder(dividingBy: 11)
                sun = eio(pr(t, 0.8, 5.4)) * (1 - eio(pr(t, 8.0, 10.4)))
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Earth with a thin layer of air all round it, drawn much thicker than it is, and a person standing on top. A slider moves the Sun from high in the sky to low on the horizon. When the Sun is high, its light goes straight down through the layer on a short trip, and the sky is blue. When the Sun is low, its light grazes through the layer on a trip with about 40 times more air. The air bounces the blue away, only red light reaches the person, and the sky turns orange and red.")
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ time: Double) {
        let w = s.width, h = s.height
        // geometry: Earth is a huge ball; the person stands on top of it
        let R = w * 0.7, H = R * 0.14
        let O = CGPoint(x: w / 2, y: h * 0.64)
        let C = CGPoint(x: O.x, y: O.y + R)
        let D = min(w * 0.46, O.y - 24)
        let alpha = (.pi / 2) * (1 - sun)                               // how high the Sun is
        let u = CGPoint(x: -cos(alpha), y: -sin(alpha))                 // from the person toward the Sun
        let trip = -R * sin(alpha) + sqrt(R * R * sin(alpha) * sin(alpha) + 2 * R * H + H * H)    // distance from the person to the top of the air layer
        let ratio = trip / H                                            // how much more air than from straight overhead
        let red = eio(pr(alpha, 0.7, 0.05))                            // how red the sky is
        let loss = pr(ratio, 1.2, 4.6)                                  // how much blue the long trip has lost
        let sunP = CGPoint(x: O.x + D * u.x, y: O.y + D * u.y)
        let entry = CGPoint(x: O.x + trip * u.x, y: O.y + trip * u.y)

        // the sky follows the Sun
        ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                 with: .linearGradient(Gradient(colors: [mix(0x3B93E8, 0x5B4B9E, red), mix(0x7CC4FA, 0xE2566B, red), mix(0xBFE5FF, 0xFFB45A, red)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: O.y + 20)))
        let hotC = CGPoint(x: sunP.x, y: sunP.y)
        ctx.fill(Path(ellipseIn: CGRect(x: hotC.x - w * 0.5, y: hotC.y - w * 0.5, width: w, height: w)),
                 with: .radialGradient(Gradient(colors: [mix(0xFFE9A0, 0xFF7A3D, red).opacity(0.45 * red), .clear]), center: hotC, startRadius: 10, endRadius: w * 0.5))

        // the air layer: a pale haze with tiny particles in it, drawn far thicker than it is
        let shell = Path(ellipseIn: CGRect(x: C.x - R - H, y: C.y - R - H, width: 2 * (R + H), height: 2 * (R + H)))
        ctx.fill(shell, with: .color(.white.opacity(0.42)))
        ctx.stroke(shell, with: .color(.white.opacity(0.95)), lineWidth: 1.6)
        for k in 0..<110 {
            let a = -(.pi / 2) + (Double(k) * 0.6180339).truncatingRemainder(dividingBy: 1) * 1.8 - 0.9
            let rr = R + H * (0.12 + 0.76 * (Double(k) * 0.7548776).truncatingRemainder(dividingBy: 1))
            ctx.fill(Path(ellipseIn: CGRect(x: C.x + rr * cos(a) - 1.3, y: C.y + rr * sin(a) - 1.3, width: 2.6, height: 2.6)), with: .color(.white.opacity(0.85)))
        }
        // Earth
        let disc = Path(ellipseIn: CGRect(x: C.x - R, y: C.y - R, width: 2 * R, height: 2 * R))
        ctx.fill(disc, with: .linearGradient(Gradient(colors: [Color(hex: 0x7BCB6B), SK.earth, SK.earthDark]), startPoint: CGPoint(x: 0, y: O.y), endPoint: CGPoint(x: 0, y: h)))
        ctx.stroke(disc, with: .color(Color(hex: 0x2E6B43).opacity(0.7)), lineWidth: 1.2)

        // the two trips, always marked: straight down from a high Sun, and grazing in from a low one
        let highTop = CGPoint(x: O.x, y: O.y - D), lowEnd = CGPoint(x: O.x - D, y: O.y)
        for p in [highTop, lowEnd] {
            var g = Path(); g.move(to: p); g.addLine(to: O)
            ctx.stroke(g, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 1.4, dash: [4, 4]))
        }

        // the Sun's light: pale yellow in the open, then turning red as the air takes the blue
        var out = Path(); out.move(to: sunP); out.addLine(to: entry)
        ctx.stroke(out, with: .color(Color(hex: 0x9A6B2E).opacity(0.3)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        ctx.stroke(out, with: .color(SK.sunPale), style: StrokeStyle(lineWidth: 4.4, lineCap: .round))
        let segs = 18
        var inside = Path(); inside.move(to: entry); inside.addLine(to: O)
        ctx.stroke(inside, with: .color(Color(hex: 0x9A6B2E).opacity(0.3)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        for i in 0..<segs {
            let f0 = Double(i) / Double(segs), f1 = Double(i + 1) / Double(segs)
            var q = Path()
            q.move(to: CGPoint(x: entry.x + (O.x - entry.x) * f0, y: entry.y + (O.y - entry.y) * f0))
            q.addLine(to: CGPoint(x: entry.x + (O.x - entry.x) * f1, y: entry.y + (O.y - entry.y) * f1))
            ctx.stroke(q, with: .color(mix(0xFFF2B0, 0xFF3F2E, loss * (f0 + f1) / 2)), style: StrokeStyle(lineWidth: 5.5, lineCap: .butt))
        }
        // little dots of light travelling down the beam
        for j in 0..<4 {
            let k = (time * 0.35 + Double(j) / 4).truncatingRemainder(dividingBy: 1)
            let p = CGPoint(x: sunP.x + (O.x - sunP.x) * k, y: sunP.y + (O.y - sunP.y) * k)
            let inside = hypot(p.x - O.x, p.y - O.y) < trip
            let f = inside ? 1 - hypot(p.x - O.x, p.y - O.y) / trip : 0
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 2.4, y: p.y - 2.4, width: 4.8, height: 4.8)), with: .color(mix(0xFFFFFF, 0xFFD0C0, loss * f).opacity(0.95)))
        }
        // blue bounced away: the longer the trip, the more of it
        let n = Int(2 + 8 * pr(ratio, 1, 5.2))
        for i in 0..<n {
            let f = (Double(i) + 0.5) / Double(n)
            let p = CGPoint(x: entry.x + (O.x - entry.x) * f, y: entry.y + (O.y - entry.y) * f)
            let nl = hypot(p.x - C.x, p.y - C.y)
            let nx = (p.x - C.x) / nl, ny = (p.y - C.y) / nl
            let rot = (i % 2 == 0 ? 0.75 : -0.75)
            let dx = nx * cos(rot) - ny * sin(rot), dy = nx * sin(rot) + ny * cos(rot)
            let k = (time * 0.8 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
            let a = CGPoint(x: p.x + dx * (5 + 8 * k), y: p.y + dy * (5 + 8 * k))
            arrow(&ctx, a, CGPoint(x: a.x + dx * 19, y: a.y + dy * 19), SK.blue, width: 3, alpha: sin(.pi * k))
        }
        sunDisc(&ctx, sunP, min(w * 0.05, 15), hot: red, t: time)

        // the person on top of the world
        let foot = CGPoint(x: O.x, y: O.y + 2)
        person(&ctx, foot: foot, height: h * 0.12)

        // labels
        let hiOn = 1 - pr(sun, 0.05, 0.4), loOn = pr(sun, 0.6, 0.95)
        Kit.chip(&ctx, "NOON: SHORT TRIP", CGPoint(x: O.x + 12, y: h * 0.27), anchor: .leading, color: hiOn > 0.5 ? Pal.signal : .white, size: 7, alpha: 0.6 + 0.4 * hiOn)
        let lo = "SUNSET: ABOUT 40 TIMES MORE AIR"
        Kit.chip(&ctx, lo, CGPoint(x: fitX(O.x - 40, lo, 7, w), y: O.y + 34), color: loOn > 0.5 ? Pal.signal : .white, size: 7, alpha: 0.6 + 0.4 * loOn)
        let al = "AIR LAYER (DRAWN MUCH THICKER)"
        Kit.chip(&ctx, al, CGPoint(x: w - 12, y: O.y + 66), anchor: .trailing, color: .white, size: 7)
        var lead = Path(); lead.move(to: CGPoint(x: w - 40, y: O.y + 58)); lead.addLine(to: CGPoint(x: w - 40, y: O.y + 22))
        ctx.stroke(lead, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 1.2, dash: [2, 3]))
        Kit.chip(&ctx, "BLUE BOUNCED AWAY", CGPoint(x: 10, y: O.y - 46), anchor: .bottomLeading, color: SK.blueText, size: 7, alpha: 0.5 + 0.5 * pr(ratio, 1, 3))
        Kit.chip(&ctx, "RED REACHES YOU", CGPoint(x: O.x + 18, y: O.y - 14), anchor: .leading, color: SK.redText, size: 7, alpha: pr(loss, 0.4, 0.9))
    }
}
