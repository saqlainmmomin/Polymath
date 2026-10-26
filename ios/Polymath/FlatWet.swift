import SwiftUI
import UIKit

// "How do you know something is wet?" topic: four flat Canvas scenes. First build, 2026-10-26.
// Warm peach light. Sensors, nerves and signals are drawn much bigger than they are (every zoomed scene says so on screen).
// Card 4 is hands-on (cold or warm water) and plays a silent demo until it is touched.

private func cl(_ x: Double) -> Double { min(1, max(0, x)) }
private func pr(_ t: Double, _ a: Double, _ b: Double) -> Double { cl((t - a) / (b - a)) }
private func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }

/// Warm peach light for every scene.
private let peach: [UInt32] = [0xFFF3E0, 0xFFDDBD, 0xF8BC94]

private enum W {
    static let skin = Color(hex: 0xF4B48C), skinDeep = Color(hex: 0xE3906A), skinLine = Color(hex: 0xB86A4C), nail = Color(hex: 0xFFDCC8)
    static let water = Color(hex: 0x4FB3F0), waterHi = Color(hex: 0xBFE7FF), waterDeep = Color(hex: 0x2A86D6)
    static let warmWater = Color(hex: 0xF7A25E), warmHi = Color(hex: 0xFFD7A8)
    static let cold = Color(hex: 0x3E95F2), coldText = Color(hex: 0x9CD0FF)
    static let heat = Color(hex: 0xFF8A3D), touch = Color(hex: 0xE2569B), touchText = Color(hex: 0xFFA6CF), pain = Color(hex: 0xE04848)
    static let shirt = Color(hex: 0x5FC4B4), shirtDark = Color(hex: 0x3E9C8E)
    static let brain = Color(hex: 0xF7A6BA), brainLine = Color(hex: 0xC9617F)
    static let nerve = Color(hex: 0xFFF4DC)
}

/// Rough chip width, to keep a chip inside the picture.
private func chipW(_ text: String, _ size: Double) -> Double { Double(text.count) * size * 0.66 + 18 }
/// Clamp a centred chip's x so the whole chip stays inside a width.
private func fitX(_ x: Double, _ text: String, _ size: Double, _ w: Double) -> Double {
    let half = chipW(text, size) / 2
    return min(max(x, half + 4), w - half - 4)
}

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

/// A finger from the side: a thick skin capsule from `base` to `tip`, with a nail near the tip.
private func finger(_ ctx: inout GraphicsContext, _ base: CGPoint, _ tip: CGPoint, width: Double) {
    var p = Path(); p.move(to: base); p.addLine(to: tip)
    ctx.stroke(p, with: .color(W.skinLine), style: StrokeStyle(lineWidth: width + 2.5, lineCap: .round))
    ctx.stroke(p, with: .color(W.skin), style: StrokeStyle(lineWidth: width, lineCap: .round))
    let dx = tip.x - base.x, dy = tip.y - base.y, len = max(1, hypot(dx, dy))
    let ux = dx / len, uy = dy / len
    let nc = CGPoint(x: tip.x - ux * width * 0.42 + uy * width * 0.16, y: tip.y - uy * width * 0.42 - ux * width * 0.16)
    let nail = Path(ellipseIn: CGRect(x: -width * 0.26, y: -width * 0.19, width: width * 0.52, height: width * 0.38))
        .applying(CGAffineTransform(rotationAngle: atan2(dy, dx)).concatenating(CGAffineTransform(translationX: nc.x, y: nc.y)))
    ctx.fill(nail, with: .color(W.nail))
}

/// A sensor in the skin: a nerve running down out of the picture, ending in a bulb that glows when `on`.
private func sensor(_ ctx: inout GraphicsContext, _ p: CGPoint, _ r: Double, _ color: Color, on: Double, alpha: Double = 1, nerveTo: Double) {
    guard alpha > 0.01 else { return }
    var l = ctx; l.opacity = alpha
    var n = Path(); n.move(to: CGPoint(x: p.x, y: p.y + r)); n.addCurve(to: CGPoint(x: p.x + r * 0.6, y: nerveTo), control1: CGPoint(x: p.x - r, y: p.y + r * 3), control2: CGPoint(x: p.x + r * 1.4, y: nerveTo - r * 2))
    l.stroke(n, with: .color(W.nerve.opacity(0.9)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
    if on > 0.01 {
        l.fill(Path(ellipseIn: CGRect(x: p.x - r * 2.6, y: p.y - r * 2.6, width: r * 5.2, height: r * 5.2)),
               with: .radialGradient(Gradient(colors: [color.opacity(0.55 * on), .clear]), center: p, startRadius: r * 0.5, endRadius: r * 2.6))
    }
    let disc = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
    l.fill(disc, with: .color(color.opacity(0.45 + 0.55 * on)))
    l.stroke(disc, with: .color(.white.opacity(0.85)), lineWidth: 1.4)
}

/// The skin's surface: gentle bumps along y0.
private func bumps(_ x: Double, _ y0: Double) -> Double { y0 + 2.6 * sin(x / 9) + 1.4 * sin(x / 4.3 + 1) }

/// A point on a cubic Bézier.
private func bez(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint, _ t: Double) -> CGPoint {
    let u = 1 - t
    let x = u * u * u * a.x + 3 * u * u * t * b.x + 3 * u * t * t * c.x + t * t * t * d.x
    let y = u * u * u * a.y + 3 * u * u * t * b.y + 3 * u * t * t * c.y + t * t * t * d.y
    return CGPoint(x: x, y: y)
}

/// A friendly cartoon brain, seen from the side.
private func brain(_ ctx: inout GraphicsContext, _ c: CGPoint, _ bw: Double, glow: Double) {
    let bh = bw * 0.72
    if glow > 0.01 {
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - bw, y: c.y - bh, width: bw * 2, height: bh * 2)),
                 with: .radialGradient(Gradient(colors: [Pal.signal.opacity(0.6 * glow), .clear]), center: c, startRadius: bw * 0.3, endRadius: bw))
    }
    let body = Path(ellipseIn: CGRect(x: c.x - bw / 2, y: c.y - bh / 2, width: bw, height: bh))
    ctx.fill(body, with: .color(W.brain))
    ctx.stroke(body, with: .color(W.brainLine), lineWidth: 2)
    ctx.drawLayer { l in
        l.clip(to: body)
        for (dx, dy, r, a0, a1) in [(-0.22, -0.12, 0.16, 200.0, 360.0), (0.08, -0.2, 0.18, 190.0, 350.0), (0.28, 0.02, 0.14, 250.0, 420.0),
                                    (-0.3, 0.16, 0.13, 290.0, 450.0), (0.0, 0.12, 0.15, 160.0, 330.0)] {
            var g = Path()
            g.addArc(center: CGPoint(x: c.x + dx * bw, y: c.y + dy * bw), radius: r * bw, startAngle: .degrees(a0), endAngle: .degrees(a1), clockwise: false)
            l.stroke(g, with: .color(W.brainLine.opacity(0.75)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }
}

/// The panel the hands-on card sits in: same look as FlatPicture.
private struct WetPanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .background(LinearGradient(colors: peach.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
    }
}

// MARK: - Card 1: a dry shirt feels damp; zoom into the skin: sensors for cold, heat, touch and pain, none for wet

struct WetNoSensor: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 10, still: 8.5, cues: [Cue(1.5, .soft), Cue(6.4, .light)], replayOnTap: true, sky: peach,
                    label: "A shirt hangs on a washing line on a cold evening. A finger touches it, and it feels damp, even though the shirt can still be dry. Then the picture zooms into the skin of the finger. It shows four kinds of sensor, tiny nerve endings, lighting up one by one: cold, heat, touch and pain. A fifth slot for wet is empty and crossed out: there is no sensor for wet. The sensors are drawn much bigger than they are.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            // the washing line and the shirt
            let y0 = h * 0.08
            var line = Path(); line.move(to: CGPoint(x: 0, y: y0)); line.addQuadCurve(to: CGPoint(x: w, y: y0), control: CGPoint(x: w / 2, y: y0 + 12))
            ctx.stroke(line, with: .color(Color(hex: 0x8A6A52)), lineWidth: 1.6)
            let sw = min(w * 0.3, h * 0.34)
            let cx = w * 0.6 + 2 * sin(t * 1.3), top = y0 + 8
            let pts: [(Double, Double)] = [(-0.18, 0), (-0.5, 0.08), (-0.64, 0.34), (-0.42, 0.42), (-0.36, 0.28), (-0.36, 1.0),
                                           (0.36, 1.0), (0.36, 0.28), (0.42, 0.42), (0.64, 0.34), (0.5, 0.08), (0.18, 0)]
            var shirt = Path()
            for (i, (px, py)) in pts.enumerated() {
                let q = CGPoint(x: cx + px * sw, y: top + py * sw)
                if i == 0 { shirt.move(to: q) } else { shirt.addLine(to: q) }
            }
            shirt.addQuadCurve(to: CGPoint(x: cx - 0.18 * sw, y: top), control: CGPoint(x: cx, y: top + 0.16 * sw))
            ctx.fill(shirt, with: .linearGradient(Gradient(colors: [W.shirt, W.shirtDark]), startPoint: CGPoint(x: cx, y: top), endPoint: CGPoint(x: cx, y: top + sw)))
            ctx.stroke(shirt, with: .color(W.shirtDark), lineWidth: 1.4)
            for px in [-0.42, 0.42] { ctx.fill(Path(roundedRect: CGRect(x: cx + px * sw - 3, y: y0 + 1, width: 6, height: 13), cornerRadius: 1.5), with: .color(Color(hex: 0xFFC94A))) }

            // a finger reaches in and touches the shirt
            let reach = eio(pr(t, 0.3, 1.4))
            let touchP = CGPoint(x: cx - 0.36 * sw - 2, y: top + 0.62 * sw)
            let tip = CGPoint(x: touchP.x - (1 - reach) * w * 0.25, y: touchP.y + (1 - reach) * h * 0.08)
            let base = CGPoint(x: tip.x - w * 0.42, y: tip.y + h * 0.12)
            finger(&ctx, base, tip, width: min(22, h * 0.07))
            if t > 1.4 { Kit.ring(&ctx, tip, 6 + 10 * pr(t, 1.4, 2.2), Pal.signal, alpha: 1 - pr(t, 1.4, 2.2)) }
            Kit.chip(&ctx, "FEELS DAMP", CGPoint(x: fitX(tip.x - 10, "FEELS DAMP", 9, w), y: tip.y - 18), anchor: .bottom, color: W.coldText, size: 9, alpha: pr(t, 1.6, 2.0))
            let dry = "CAN STILL BE DRY"
            Kit.chip(&ctx, dry, CGPoint(x: fitX(cx + 0.1 * sw, dry, 8, w), y: top + sw + 6), anchor: .top, color: Pal.signal, size: 8, alpha: pr(t, 2.6, 3.0))

            // zoom into the skin of the fingertip
            let z = eio(pr(t, 3.4, 4.1))
            guard z > 0.01 else { return }
            let zr = CGRect(x: 12, y: h * 0.5, width: w - 24, height: h * 0.5 - 30)
            var link = Path()
            link.move(to: tip); link.addLine(to: CGPoint(x: zr.minX, y: zr.minY))
            link.move(to: tip); link.addLine(to: CGPoint(x: zr.maxX, y: zr.minY))
            ctx.stroke(link, with: .color(Color(hex: 0x8A6A52).opacity(0.5 * z)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            var zl = ctx; zl.opacity = z
            let box = Path(roundedRect: zr, cornerRadius: 8)
            zl.fill(box, with: .color(.white.opacity(0.7)))
            let surf = zr.minY + zr.height * 0.26
            zl.drawLayer { l in
                l.clip(to: box)
                var sk = Path()
                sk.move(to: CGPoint(x: zr.minX, y: zr.maxY))
                var x = zr.minX; while x <= zr.maxX { sk.addLine(to: CGPoint(x: x, y: bumps(x, surf))); x += 3 }
                sk.addLine(to: CGPoint(x: zr.maxX, y: zr.maxY)); sk.closeSubpath()
                l.fill(sk, with: .linearGradient(Gradient(colors: [W.skin, W.skinDeep]), startPoint: CGPoint(x: 0, y: surf), endPoint: CGPoint(x: 0, y: zr.maxY)))
            }
            zl.stroke(box, with: .color(W.skinLine.opacity(0.7)), lineWidth: 1.4)
            Kit.chip(&zl, "YOUR SKIN, ZOOMED IN", CGPoint(x: zr.minX + 8, y: zr.minY + 6), anchor: .topLeading, color: .white, size: 7)
            // four sensors light up one by one, then the empty slot for wet
            let kinds: [(String, Color)] = [("COLD", W.cold), ("HEAT", W.heat), ("TOUCH", W.touch), ("PAIN", W.pain)]
            let r = min(8.0, zr.height * 0.08)
            let by = surf + zr.height * 0.3
            for i in 0..<5 {
                let x = zr.minX + zr.width * (0.1 + 0.2 * Double(i))
                let p = CGPoint(x: x, y: by)
                let at = 4.3 + 0.45 * Double(i)
                if i < 4 {
                    let on = pr(t, at, at + 0.3)
                    sensor(&zl, p, r, kinds[i].1, on: on, alpha: pr(t, 4.0, 4.3), nerveTo: zr.maxY + 4)
                    Kit.chip(&zl, kinds[i].0, CGPoint(x: x, y: by + r + 8), anchor: .top, color: .white, size: 7, alpha: on)
                } else {
                    let on = pr(t, 6.2, 6.6)
                    var slot = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
                    zl.stroke(slot, with: .color(Pal.night.opacity(0.55 * on)), style: StrokeStyle(lineWidth: 1.6, dash: [3, 3]))
                    slot = Path(); slot.move(to: CGPoint(x: p.x - r * 0.6, y: p.y - r * 0.6)); slot.addLine(to: CGPoint(x: p.x + r * 0.6, y: p.y + r * 0.6))
                    slot.move(to: CGPoint(x: p.x + r * 0.6, y: p.y - r * 0.6)); slot.addLine(to: CGPoint(x: p.x - r * 0.6, y: p.y + r * 0.6))
                    zl.stroke(slot, with: .color(Pal.coral.opacity(on)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    Kit.chip(&zl, "WET", CGPoint(x: x, y: by + r + 8), anchor: .top, color: Pal.coral, size: 7, alpha: on)
                }
            }
            let ns = "NO SENSOR FOR WET"
            Kit.chip(&ctx, ns, CGPoint(x: zr.maxX - 6, y: zr.minY + 6), anchor: .topTrailing, color: Pal.signal, size: 8, alpha: pr(t, 6.7, 7.1))
            note(&ctx, "SENSORS DRAWN MUCH BIGGER", at: CGPoint(x: w - 8, y: h - 6), anchor: .bottomTrailing, alpha: 0.85 * z)
        }
    }
}

// MARK: - Card 2: the same finger in air and in water; heat leaves it over 20 times faster in water, and the cold sensors fire

struct WetCooling: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 10, still: 7, cues: [Cue(1.4, .soft), Cue(3.6, .light)], replayOnTap: true, sky: peach,
                    label: "Two fingers. The left one hangs in the air. The right one dips into a glass of water. Little orange dots of heat leave both fingers: a few drift slowly away into the air, but many rush away into the water, over 20 times faster. A thermometer beside each finger shows its skin cooling: slowly in air, fast in water. Then the cold sensor in the wet finger sends a signal up toward the brain.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let fw = min(26.0, w * 0.075)
            let dip = eio(pr(t, 0.4, 1.4))
            // the glass of water on the right
            let gl = CGRect(x: w * 0.56, y: h * 0.4, width: w * 0.36, height: h * 0.44)
            let wl = gl.minY + gl.height * 0.18
            let water = Path(CGRect(x: gl.minX, y: wl, width: gl.width, height: gl.maxY - wl))
            ctx.fill(water, with: .linearGradient(Gradient(colors: [W.waterHi, W.water, W.waterDeep]), startPoint: CGPoint(x: 0, y: wl), endPoint: CGPoint(x: 0, y: gl.maxY)))
            // fingers, hanging from the top
            let ax = w * 0.27, atip = CGPoint(x: ax, y: h * 0.58)
            let bx = gl.midX, btip = CGPoint(x: bx, y: h * 0.28 + (gl.maxY - h * 0.1 - h * 0.28) * dip)
            finger(&ctx, CGPoint(x: ax, y: -fw), atip, width: fw)
            finger(&ctx, CGPoint(x: bx, y: -fw), btip, width: fw)
            // water in front of the dipped part, a little see-through, and the glass
            ctx.drawLayer { l in
                l.clip(to: water)
                l.fill(water, with: .color(W.water.opacity(0.22)))
            }
            ctx.stroke(Path(CGRect(x: gl.minX, y: wl, width: gl.width, height: 0)), with: .color(.white.opacity(0.9)), lineWidth: 1.5)
            var glass = Path(); glass.move(to: CGPoint(x: gl.minX, y: gl.minY)); glass.addLine(to: CGPoint(x: gl.minX, y: gl.maxY)); glass.addLine(to: CGPoint(x: gl.maxX, y: gl.maxY)); glass.addLine(to: CGPoint(x: gl.maxX, y: gl.minY))
            ctx.stroke(glass, with: .color(.white.opacity(0.95)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))

            // heat leaving each finger: a few slow dots in air, many fast dots in water
            func heat(_ tip: CGPoint, n: Int, speed: Double, reach: Double, alpha: Double) {
                guard alpha > 0.01 else { return }
                for i in 0..<n {
                    let k = (t * speed + Double(i) / Double(n)).truncatingRemainder(dividingBy: 1)
                    let ang = -0.2 * .pi + 1.4 * .pi * (Double(i) * 0.618).truncatingRemainder(dividingBy: 1)     // spread round the sides and below
                    let from = CGPoint(x: tip.x + cos(ang) * fw * 0.5, y: tip.y - fw * 0.6 + sin(ang) * fw * 0.5)
                    let p = CGPoint(x: from.x + cos(ang) * reach * k, y: from.y + sin(ang) * reach * k)
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - 2.6, y: p.y - 2.6, width: 5.2, height: 5.2)), with: .color(W.heat.opacity(alpha * sin(.pi * k))))
                }
            }
            heat(atip, n: 4, speed: 0.22, reach: fw * 1.6, alpha: 1)
            heat(btip, n: 14, speed: 0.9, reach: fw * 1.9, alpha: pr(t, 1.2, 1.8))
            Kit.chip(&ctx, "HEAT LEAVES YOUR SKIN", CGPoint(x: w / 2, y: 8), anchor: .top, color: W.heat, size: 8)

            // a thermometer for each finger's skin
            func gauge(_ x: Double, _ level: Double) {
                let tr = CGRect(x: x - 4, y: h * 0.2, width: 8, height: h * 0.26)
                let bulb = CGRect(x: x - 7, y: tr.maxY - 3, width: 14, height: 14)
                let fill = level > 0.6 ? W.heat : level > 0.35 ? Color(hex: 0xC58BD0) : W.cold
                ctx.fill(Path(roundedRect: tr, cornerRadius: 4), with: .color(.white.opacity(0.9)))
                ctx.fill(Path(roundedRect: CGRect(x: tr.minX + 2, y: tr.maxY - tr.height * level, width: 4, height: tr.height * level), cornerRadius: 2), with: .color(fill))
                ctx.fill(Path(ellipseIn: bulb), with: .color(fill))
                ctx.stroke(Path(roundedRect: tr, cornerRadius: 4), with: .color(W.skinLine.opacity(0.6)), lineWidth: 1)
                Kit.chip(&ctx, "SKIN", CGPoint(x: x, y: tr.minY - 4), anchor: .bottom, color: .white, size: 6)
            }
            gauge(w * 0.1, 0.9 - 0.08 * pr(t, 1.4, 9))
            gauge(w * 0.48, 0.9 - 0.62 * eio(pr(t, 1.4, 3.6)))

            Kit.chip(&ctx, "IN AIR: SLOW", CGPoint(x: fitX(ax, "IN AIR: SLOW", 7, w), y: h - 8), anchor: .bottom, color: .white, size: 7)
            let fast = "IN WATER: OVER 20× FASTER"
            Kit.chip(&ctx, fast, CGPoint(x: fitX(gl.midX, fast, 7, w), y: h - 8), anchor: .bottom, color: Pal.signal, size: 7, alpha: pr(t, 1.6, 2.0))

            // the cold sensor in the wet finger sends its signal up
            let sig = pr(t, 3.6, 3.9)
            if sig > 0 {
                for i in 0..<3 {
                    let k = (t * 0.8 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    let p = CGPoint(x: bx, y: btip.y - fw - (btip.y - fw + fw) * k)
                    Kit.softDot(&ctx, p, 3.4, W.cold, alpha: sig * sin(.pi * k))
                }
                arrow(&ctx, CGPoint(x: bx + fw * 0.9, y: h * 0.3), CGPoint(x: bx + fw * 0.9, y: h * 0.14), W.cold, width: 2.2, alpha: sig)
                Kit.chip(&ctx, "COLD SIGNAL", CGPoint(x: fitX(bx + fw * 0.9 + 46, "COLD SIGNAL", 8, w), y: h * 0.22), color: W.coldText, size: 8, alpha: sig)
            }
        }
    }
}

// MARK: - Card 3: water on skin; a cooling signal and a touch signal travel to the brain, which adds them into "wet"

struct WetGuess: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 10, still: 8.5, cues: [Cue(1.0, .soft), Cue(5.2, .light), Cue(6.2, .success)], replayOnTap: true, sky: peach,
                    label: "Skin seen from the side, zoomed in. A drop of water lands and spreads gently and evenly over the little bumps of the skin. Under the skin, a cold sensor lights up blue and a touch sensor lights up pink. Their signals travel up two nerves to a brain at the top: fast cooling on one side, a soft, even touch on the other. The brain adds the two together: cooling plus touch equals wet. That is your brain's guess. The sensors are drawn much bigger than they are.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let surf = h * 0.72
            // skin
            var sk = Path()
            sk.move(to: CGPoint(x: 0, y: h))
            var x = 0.0; while x <= w { sk.addLine(to: CGPoint(x: x, y: bumps(x, surf))); x += 3 }
            sk.addLine(to: CGPoint(x: w, y: h)); sk.closeSubpath()
            ctx.fill(sk, with: .linearGradient(Gradient(colors: [W.skin, W.skinDeep]), startPoint: CGPoint(x: 0, y: surf), endPoint: CGPoint(x: 0, y: h)))
            ctx.stroke(sk, with: .color(W.skinLine.opacity(0.6)), lineWidth: 1.2)

            // a drop falls, then spreads over the bumps
            let c = w / 2
            let fall = pr(t, 0.2, 1.0)
            if fall < 1 {
                let dy = h * 0.3 + (surf - 8 - h * 0.3) * fall * fall
                var d = Path()
                d.move(to: CGPoint(x: c, y: dy - 12)); d.addQuadCurve(to: CGPoint(x: c, y: dy + 7), control: CGPoint(x: c + 13, y: dy + 6)); d.addQuadCurve(to: CGPoint(x: c, y: dy - 12), control: CGPoint(x: c - 13, y: dy + 6))
                ctx.fill(d, with: .color(W.water))
            } else {
                let half = w * (0.08 + 0.2 * eio(pr(t, 1.0, 2.0)))
                let thick = 16 - 7 * eio(pr(t, 1.0, 2.0))
                var wd = Path()
                var xs: [Double] = []
                var xx = c - half; while xx <= c + half { xs.append(xx); xx += 2 }
                wd.move(to: CGPoint(x: xs[0], y: bumps(xs[0], surf)))
                for v in xs {
                    let k = (v - c) / half
                    wd.addLine(to: CGPoint(x: v, y: bumps(v, surf) - thick * sqrt(max(0, 1 - k * k))))
                }
                for v in xs.reversed() { wd.addLine(to: CGPoint(x: v, y: bumps(v, surf) + 0.5)) }
                wd.closeSubpath()
                ctx.fill(wd, with: .linearGradient(Gradient(colors: [W.waterHi, W.water]), startPoint: CGPoint(x: 0, y: surf - thick), endPoint: CGPoint(x: 0, y: surf)))
                ctx.stroke(wd, with: .color(.white.opacity(0.8)), lineWidth: 1.2)
            }

            // two sensors under the skin, and their nerves up to the brain
            let r = min(9.0, h * 0.035)
            let cp = CGPoint(x: w * 0.36, y: surf + (h - surf) * 0.45), tp = CGPoint(x: w * 0.64, y: surf + (h - surf) * 0.45)
            let bc = CGPoint(x: w / 2, y: h * 0.22), bw = min(w * 0.26, h * 0.3)
            let cOn = pr(t, 2.2, 2.5), tOn = pr(t, 2.7, 3.0)
            let routes: [(CGPoint, CGPoint, CGPoint, CGPoint)] = [
                (cp, CGPoint(x: w * 0.04, y: h * 0.98), CGPoint(x: w * 0.02, y: h * 0.2), CGPoint(x: bc.x - bw * 0.48, y: bc.y + 4)),
                (tp, CGPoint(x: w * 0.96, y: h * 0.98), CGPoint(x: w * 0.98, y: h * 0.2), CGPoint(x: bc.x + bw * 0.48, y: bc.y + 4))
            ]
            for (i, rt) in routes.enumerated() {
                var n = Path(); n.move(to: rt.0); n.addCurve(to: rt.3, control1: rt.1, control2: rt.2)
                ctx.stroke(n, with: .color(.white.opacity(0.85)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                let col = i == 0 ? W.cold : W.touch
                let on = i == 0 ? cOn : tOn
                for j in 0..<3 {
                    let k = (t * 0.55 + Double(j) / 3).truncatingRemainder(dividingBy: 1)
                    Kit.softDot(&ctx, bez(rt.0, rt.1, rt.2, rt.3, k), 3.6, col, alpha: on * pr(t, 3.0, 3.4) * (0.4 + 0.6 * sin(.pi * k)))
                }
            }
            sensor(&ctx, cp, r, W.cold, on: cOn, nerveTo: h + 6)
            sensor(&ctx, tp, r, W.touch, on: tOn, nerveTo: h + 6)
            Kit.chip(&ctx, "FAST COOLING", CGPoint(x: 8, y: h * 0.48), anchor: .leading, color: W.coldText, size: 8, alpha: pr(t, 3.2, 3.6))
            Kit.chip(&ctx, "SOFT, EVEN TOUCH", CGPoint(x: w - 8, y: h * 0.48), anchor: .trailing, color: W.touchText, size: 8, alpha: pr(t, 3.6, 4.0))

            // the brain adds the two signals: "wet"
            let sum = pr(t, 5.0, 5.4)
            brain(&ctx, bc, bw, glow: sum * (0.7 + 0.3 * sin(t * 3)))
            let eq = "COOLING + TOUCH = \"WET\""
            Kit.chip(&ctx, eq, CGPoint(x: fitX(w / 2, eq, 9, w), y: bc.y + bw * 0.36 + 8), anchor: .top, color: Pal.signal, size: 9, alpha: sum)
            Kit.chip(&ctx, "YOUR BRAIN'S GUESS", CGPoint(x: w / 2, y: 6), anchor: .top, color: .white, size: 8, alpha: pr(t, 6.0, 6.4))
            note(&ctx, "SENSORS DRAWN MUCH BIGGER", at: CGPoint(x: w - 8, y: h - 6), anchor: .bottomTrailing, alpha: 0.85)
        }
    }
}

// MARK: - Card 4 (hands-on): a dry hand in a plastic bag, in cold or warm water

struct WetBag: View {
    let active: Bool
    @State private var cold = true
    @State private var switchedAt = Date.distantPast
    @State private var touched = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        WetPanel {
            VStack(spacing: 6) {
                TimelineView(.animation(paused: !active || reduce)) { tl in
                    Canvas { ctx, s in draw(&ctx, s, tl.date) }
                }
                HStack(spacing: 10) {
                    choice("COLD WATER", isCold: true)
                    choice("WARM WATER", isCold: false)
                }
                .padding(.bottom, 10)
            }
        }
        .task(id: "\(active)-\(touched)-\(reduce)") {
            guard active, !touched, !reduce else { return }
            while !Task.isCancelled && !touched {
                try? await Task.sleep(for: .seconds(4))
                if Task.isCancelled || touched { return }
                cold.toggle(); switchedAt = Date()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("A hand inside a thin plastic bag, dipped into a bowl of water. The hand stays dry the whole time. Two lights show the signals your brain gets: cooling and touch. In cold water both lights are on, and the hand feels wet. In warm water, close to your skin's own heat, only touch is on, and it feels less wet. Buttons switch between cold and warm water.")
    }

    private func choice(_ text: String, isCold: Bool) -> some View {
        let on = cold == isCold
        return Button {
            if !touched { touched = true }
            if cold != isCold { cold = isCold; switchedAt = Date() }
            Haptic.fire(.soft)
        } label: {
            Text(text).font(T.mono(10)).tracking(0.8)
                .foregroundStyle(on ? Color(hex: 0x2A1A10) : .white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(on ? (isCold ? W.waterHi : W.warmHi) : Pal.night.opacity(0.7)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ now: Date) {
        let w = s.width, h = s.height
        let t = now.timeIntervalSinceReferenceDate
        let e = reduce ? 1 : eio(pr(now.timeIntervalSince(switchedAt), 0, 0.7))
        let m = cold ? e : 1 - e                     // 1 = cold water, 0 = warm water
        // the bowl
        let bowl = CGRect(x: w * 0.12, y: h * 0.5, width: w * 0.76, height: h * 0.44)
        let wl = bowl.minY + bowl.height * 0.16
        var basin = Path()
        basin.move(to: CGPoint(x: bowl.minX, y: bowl.minY))
        basin.addCurve(to: CGPoint(x: bowl.maxX, y: bowl.minY), control1: CGPoint(x: bowl.minX + 6, y: bowl.maxY + bowl.height * 0.3), control2: CGPoint(x: bowl.maxX - 6, y: bowl.maxY + bowl.height * 0.3))
        basin.closeSubpath()
        let top = W.waterHi.mix(W.warmHi, 1 - m), mid = W.water.mix(W.warmWater, 1 - m)
        ctx.drawLayer { l in
            l.clip(to: basin)
            l.fill(Path(CGRect(x: bowl.minX, y: wl, width: bowl.width, height: bowl.height * 1.4)), with: .linearGradient(Gradient(colors: [top, mid]), startPoint: CGPoint(x: 0, y: wl), endPoint: CGPoint(x: 0, y: bowl.maxY)))
        }
        // the hand in its bag, dipped in
        let hx = w / 2, tipY = bowl.minY + bowl.height * 0.62
        let fw = min(11.0, w * 0.03)
        let palmTop = h * 0.3, palmBot = tipY - fw * 3.2
        let palm = CGRect(x: hx - fw * 2.4, y: palmTop, width: fw * 4.8, height: palmBot - palmTop)
        var arm = Path(); arm.move(to: CGPoint(x: hx, y: -10)); arm.addLine(to: CGPoint(x: hx, y: palm.midY))
        ctx.stroke(arm, with: .color(W.skinLine), style: StrokeStyle(lineWidth: fw * 3.8 + 2.5, lineCap: .round))
        ctx.stroke(arm, with: .color(W.skin), style: StrokeStyle(lineWidth: fw * 3.8, lineCap: .round))
        ctx.fill(Path(roundedRect: palm, cornerRadius: fw * 1.4), with: .color(W.skin))
        ctx.stroke(Path(roundedRect: palm, cornerRadius: fw * 1.4), with: .color(W.skinLine), lineWidth: 1.2)
        for i in 0..<4 {
            let fx = palm.minX + fw * (0.6 + 1.2 * Double(i))
            let len = [0.85, 1.0, 0.95, 0.75][i]
            finger(&ctx, CGPoint(x: fx, y: palm.maxY - fw * 0.6), CGPoint(x: fx, y: palm.maxY + (tipY - palm.maxY) * len), width: fw)
        }
        finger(&ctx, CGPoint(x: palm.maxX - fw * 0.5, y: palm.minY + palm.height * 0.55), CGPoint(x: palm.maxX + fw * 0.7, y: palm.maxY - fw * 0.1), width: fw * 1.05)
        // the bag: a see-through sleeve round the hand, open at the top
        let bag = CGRect(x: palm.minX - fw * 1.2, y: h * 0.18, width: palm.width + fw * 3.4, height: tipY + fw * 1.4 - h * 0.18)
        let bagPath = Path(roundedRect: bag, cornerRadius: fw * 1.6)
        ctx.fill(bagPath, with: .color(.white.opacity(0.28)))
        ctx.stroke(bagPath, with: .color(.white.opacity(0.95)), lineWidth: 1.8)
        var creases = Path()
        creases.move(to: CGPoint(x: bag.minX + 5, y: bag.minY + 20)); creases.addLine(to: CGPoint(x: bag.minX + 9, y: bag.minY + 46))
        creases.move(to: CGPoint(x: bag.maxX - 6, y: bag.minY + 30)); creases.addLine(to: CGPoint(x: bag.maxX - 10, y: bag.minY + 58))
        ctx.stroke(creases, with: .color(.white.opacity(0.7)), lineWidth: 1)
        // water in front, a little see-through, so the dipped hand shows through
        ctx.drawLayer { l in
            l.clip(to: basin)
            l.fill(Path(CGRect(x: bowl.minX, y: wl, width: bowl.width, height: bowl.height * 1.4)), with: .color(mid.opacity(0.22)))
        }
        var ripple = Path()
        ripple.move(to: CGPoint(x: bowl.minX + 4, y: wl))
        var x = bowl.minX + 4; while x <= bowl.maxX - 4 { ripple.addLine(to: CGPoint(x: x, y: wl + 1.2 * sin(x / 7 + t * 3))); x += 3 }
        ctx.stroke(ripple, with: .color(.white.opacity(0.9)), lineWidth: 1.5)
        var rim = Path()
        rim.move(to: CGPoint(x: bowl.minX, y: bowl.minY))
        rim.addCurve(to: CGPoint(x: bowl.maxX, y: bowl.minY), control1: CGPoint(x: bowl.minX + 6, y: bowl.maxY + bowl.height * 0.3), control2: CGPoint(x: bowl.maxX - 6, y: bowl.maxY + bowl.height * 0.3))
        ctx.stroke(rim, with: .color(Color(hex: 0xC4724C)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        // ice cubes in cold water, steam over warm water
        for (i, dx) in [-0.32, 0.3, 0.4].enumerated() {
            let c = CGPoint(x: bowl.midX + dx * bowl.width, y: wl + 1 + sin(t * 1.5 + Double(i)) * 1.2)
            let r = CGRect(x: c.x - 7, y: c.y - 6, width: 14, height: 12)
            ctx.fill(Path(roundedRect: r, cornerRadius: 3), with: .color(.white.opacity(0.85 * m)))
            ctx.stroke(Path(roundedRect: r, cornerRadius: 3), with: .color(W.waterHi.opacity(m)), lineWidth: 1)
        }
        for i in 0..<3 {
            let k = (t * 0.35 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            let sx = bowl.midX + (Double(i) - 1) * bowl.width * 0.32 + (i == 1 ? 34 : 0)
            var st = Path()
            st.move(to: CGPoint(x: sx, y: wl - 4 - 30 * k))
            st.addCurve(to: CGPoint(x: sx, y: wl - 26 - 30 * k), control1: CGPoint(x: sx + 7, y: wl - 10 - 30 * k), control2: CGPoint(x: sx - 7, y: wl - 18 - 30 * k))
            ctx.stroke(st, with: .color(.white.opacity((1 - m) * 0.8 * sin(.pi * k))), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // labels on the scene
        Kit.chip(&ctx, "PLASTIC BAG", CGPoint(x: bag.minX - 6, y: bag.minY + 12), anchor: .trailing, color: .white, size: 7)
        Kit.chip(&ctx, "HAND: DRY", CGPoint(x: bag.maxX + 6, y: palm.minY + 8), anchor: .leading, color: Pal.signal, size: 8)

        // the two signals the brain gets, and what it decides
        let lamps: [(String, Color, Double)] = [("COOLING", W.cold, m), ("TOUCH", W.touch, 1)]
        for (i, (txt, col, on)) in lamps.enumerated() {
            let p = CGPoint(x: 16, y: 44 + Double(i) * 22)
            Kit.softDot(&ctx, p, 5, col, alpha: 0.25 + 0.75 * on)
            Kit.chip(&ctx, on > 0.5 ? txt : txt + ": HARDLY", CGPoint(x: p.x + 12, y: p.y), anchor: .leading, color: .white, size: 7, alpha: 0.5 + 0.5 * max(on, 0.6))
        }
        let res = m > 0.5 ? "COLD WATER: FEELS WET" : "WARM WATER: FEELS LESS WET"
        Kit.chip(&ctx, res, CGPoint(x: fitX(w / 2, res, 9, w), y: 8), anchor: .top, color: m > 0.5 ? Pal.signal : W.warmHi, size: 9)
    }
}

private extension Color {
    /// Blend toward another colour: 0 = self, 1 = other.
    func mix(_ other: Color, _ k: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0, r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1); b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let f = CGFloat(cl(k))
        return Color(red: Double(r1 + (r2 - r1) * f), green: Double(g1 + (g2 - g1) * f), blue: Double(b1 + (b2 - b1) * f))
    }
}
