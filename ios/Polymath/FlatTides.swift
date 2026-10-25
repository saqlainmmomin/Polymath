import SwiftUI

// Moon and tides topic: six flat Canvas scenes. First build, 2026-10-25.
// Warm dusk colours. The ocean bulges are drawn far bigger than they are (every Earth scene says so on screen).
// Card 4 is hands-on (a slider spins Earth through the bulges) and plays a silent demo until it is touched.

private func cl(_ x: Double) -> Double { min(1, max(0, x)) }
private func pr(_ t: Double, _ a: Double, _ b: Double) -> Double { cl((t - a) / (b - a)) }
private func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
private func pop(_ x: Double) -> Double { let c1 = 1.70158, c3 = c1 + 1; return x <= 0 ? 0 : 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }

/// Warm dusk sky for the space scenes: plum to rose.
private let dusk: [UInt32] = [0x1C1238, 0x34184A, 0x5A2650]

private enum C {
    static let sea = Color(hex: 0x3FA9F5), seaHi = Color(hex: 0xA6DDFF), seaDeep = Color(hex: 0x1D6FD1)
    static let rock = Color(hex: 0x6FBE6A), rockDark = Color(hex: 0x3F8F55), sandy = Color(hex: 0xE9C27E)
    static let sand = Color(hex: 0xF4CB8C), sandWet = Color(hex: 0xC99A5E)
    static let moon = Color(hex: 0xF6EEDA), moonShade = Color(hex: 0xC9BFA6)
    static let sun = Color(hex: 0xFFC94A), sunHot = Color(hex: 0xFF8A3D)
    static let beach = Pal.coral
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

/// A few twinkling stars, sparse so the warm sky stays calm.
private func sky(_ ctx: inout GraphicsContext, _ s: CGSize, _ t: Double, maxY: Double = 1) {
    let pts: [(Double, Double, Double)] = [(0.07, 0.08, 0.2), (0.22, 0.20, 1.4), (0.41, 0.06, 2.2), (0.63, 0.14, 0.7), (0.81, 0.05, 1.9), (0.93, 0.24, 2.9),
                                           (0.12, 0.42, 0.5), (0.52, 0.30, 1.1), (0.74, 0.40, 2.6), (0.30, 0.62, 3.0), (0.88, 0.70, 1.6), (0.05, 0.86, 2.4), (0.60, 0.90, 0.9)]
    for (x, y, ph) in pts where y <= maxY {
        let a = 0.25 + 0.4 * (0.5 + 0.5 * sin(t * 1.4 + ph))
        let r = 1.1
        ctx.fill(Path(ellipseIn: CGRect(x: x * s.width - r, y: y * s.height - r, width: 2 * r, height: 2 * r)), with: .color(.white.opacity(a)))
    }
}

/// The Moon: cream disc with soft craters. `lit` > 0 shades the half facing away from the Sun (light from the left).
private func moon(_ ctx: inout GraphicsContext, _ p: CGPoint, _ r: Double, alpha: Double = 1, lightFromLeft: Bool = false) {
    guard alpha > 0.01 else { return }
    var l = ctx; l.opacity = alpha
    l.fill(Path(ellipseIn: CGRect(x: p.x - r * 2.2, y: p.y - r * 2.2, width: r * 4.4, height: r * 4.4)),
           with: .radialGradient(Gradient(colors: [C.moon.opacity(0.35), .clear]), center: p, startRadius: r * 0.8, endRadius: r * 2.2))
    let disc = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
    l.fill(disc, with: .color(C.moon))
    for (dx, dy, rr) in [(-0.3, -0.25, 0.22), (0.32, 0.1, 0.16), (-0.05, 0.42, 0.13), (0.25, -0.42, 0.1)] {
        l.fill(Path(ellipseIn: CGRect(x: p.x + dx * r - rr * r, y: p.y + dy * r - rr * r, width: 2 * rr * r, height: 2 * rr * r)), with: .color(C.moonShade.opacity(0.7)))
    }
    if lightFromLeft {
        l.drawLayer { d in
            d.clip(to: disc)
            d.fill(Path(CGRect(x: p.x, y: p.y - r, width: r, height: 2 * r)), with: .color(Color(hex: 0x2A1F3A).opacity(0.78)))
        }
    }
}

/// Ocean around Earth as a closed shape: `rad(θ)` is its outer radius at angle θ (maths angle, 0 = right, toward the Moon).
private func oceanPath(_ c: CGPoint, _ rad: (Double) -> Double) -> Path {
    var p = Path()
    let n = 144
    for i in 0...n {
        let a = Double(i) / Double(n) * 2 * .pi
        let r = rad(a)
        let q = CGPoint(x: c.x + r * cos(a), y: c.y - r * sin(a))
        if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
    }
    p.closeSubpath()
    return p
}

/// Earth seen from above its North Pole: an ocean layer (shape given) over a green rock ball whose land turns by `spin`.
private func earth(_ ctx: inout GraphicsContext, _ c: CGPoint, _ R: Double, spin: Double, ocean rad: (Double) -> Double) {
    let sea = oceanPath(c, rad)
    ctx.fill(sea, with: .radialGradient(Gradient(colors: [C.seaDeep, C.sea, C.seaHi]), center: c, startRadius: R * 0.9, endRadius: R * 1.5))
    ctx.stroke(sea, with: .color(C.seaHi.opacity(0.9)), lineWidth: 1.5)
    let disc = Path(ellipseIn: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R))
    ctx.fill(disc, with: .radialGradient(Gradient(colors: [Color(hex: 0x8ED47F), C.rock, C.rockDark]), center: CGPoint(x: c.x - R * 0.3, y: c.y - R * 0.3), startRadius: 0, endRadius: R * 1.3))
    ctx.drawLayer { l in
        l.clip(to: disc)
        let blobs: [(Double, Double, Double)] = [(0.0, 0.55, 0.28), (1.3, 0.4, 0.22), (2.4, 0.62, 0.3), (3.6, 0.3, 0.2), (4.7, 0.6, 0.25), (5.6, 0.2, 0.16)]
        for (a0, d, rr) in blobs {
            let a = a0 + spin
            let q = CGPoint(x: c.x + d * R * cos(a), y: c.y - d * R * sin(a))
            l.fill(Path(ellipseIn: CGRect(x: q.x - rr * R, y: q.y - rr * R * 0.8, width: 2 * rr * R, height: 1.6 * rr * R)), with: .color(C.sandy.opacity(0.55)))
        }
        l.fill(Path(ellipseIn: CGRect(x: c.x - R * 0.16, y: c.y - R * 0.16, width: R * 0.32, height: R * 0.32)), with: .color(.white.opacity(0.75)))   // the North Pole's ice
    }
    ctx.stroke(disc, with: .color(Color(hex: 0x2E6B43).opacity(0.6)), lineWidth: 1)
}

private func note(_ ctx: inout GraphicsContext, _ s: CGSize, _ text: String, at p: CGPoint, anchor: UnitPoint, alpha: Double = 0.9) {
    Kit.chip(&ctx, text, p, anchor: anchor, color: .white.opacity(0.85), size: 7, alpha: alpha)
}

/// The panel the hands-on card sits in: same look as FlatPicture.
private struct TidePanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .background(LinearGradient(colors: dusk.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
    }
}

// MARK: - Card 1: a beach, shown much faster: the water creeps up and back while the Moon crosses the sky

struct TidesBeach: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 10, still: 5, cues: [Cue(5, .soft)], replayOnTap: true, sky: [0x2B1C55, 0x7A3F78, 0xF2956B],
                    label: "A beach seen from the side, shown much faster. The Moon rises and crosses the sky. As it does, the sea slowly creeps up the sand to the high tide mark, covering a sandcastle, then slides back down to the low tide mark.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let p = t / 10
            let lvl = pow(sin(.pi * p), 2)                  // 0 = low tide, 1 = high tide
            let lowY = h * 0.86, highY = h * 0.64
            let waterY = lowY + (highY - lowY) * lvl
            func sandY(_ x: Double) -> Double { h - h * 0.44 * x / w }
            func shoreX(_ y: Double) -> Double { (h - y) / (h * 0.44) * w }
            let xw = shoreX(waterY), xHigh = shoreX(highY), xLow = shoreX(lowY)

            sky(&ctx, s, t, maxY: 0.5)
            // the Moon crossing the sky
            let mp = CGPoint(x: w * (0.08 + 0.84 * p), y: h * 0.60 - h * 0.44 * sin(.pi * p))
            let mr = min(w, h) * 0.065
            moon(&ctx, mp, mr, alpha: cl(sin(.pi * p) * 5))
            Kit.chip(&ctx, "THE MOON", CGPoint(x: fitX(mp.x, "THE MOON", 7, w), y: mp.y + mr + 8), anchor: .top, color: C.moon, size: 7, alpha: cl(sin(.pi * p) * 5) * 0.9)

            // sand, the band the tide covers, a sandcastle and an umbrella
            var sand = Path()
            sand.move(to: CGPoint(x: 0, y: h)); sand.addLine(to: CGPoint(x: w, y: sandY(w))); sand.addLine(to: CGPoint(x: w, y: h)); sand.closeSubpath()
            ctx.fill(sand, with: .linearGradient(Gradient(colors: [C.sand, Color(hex: 0xE3AE6A)]), startPoint: CGPoint(x: 0, y: h * 0.55), endPoint: CGPoint(x: 0, y: h)))
            var wet = Path()
            wet.move(to: CGPoint(x: xLow, y: lowY)); wet.addLine(to: CGPoint(x: xHigh, y: highY)); wet.addLine(to: CGPoint(x: xHigh, y: highY + 7)); wet.addLine(to: CGPoint(x: xLow, y: lowY + 7)); wet.closeSubpath()
            ctx.fill(wet, with: .color(C.sandWet.opacity(0.45)))
            let cx = w * 0.6, cy = sandY(cx)
            let castle = CGRect(x: cx - 11, y: cy - 16, width: 22, height: 16)
            ctx.fill(Path(castle), with: .color(Color(hex: 0xE0A85C)))
            for k in 0..<3 { ctx.fill(Path(CGRect(x: castle.minX + Double(k) * 8, y: castle.minY - 5, width: 6, height: 5)), with: .color(Color(hex: 0xE0A85C))) }
            var flag = Path(); flag.move(to: CGPoint(x: cx, y: castle.minY - 5)); flag.addLine(to: CGPoint(x: cx, y: castle.minY - 15))
            ctx.stroke(flag, with: .color(Color(hex: 0x6B4A2B)), lineWidth: 1.2)
            ctx.fill(Path(CGRect(x: cx, y: castle.minY - 15, width: 7, height: 4.5)), with: .color(Pal.coral))
            let ux = w * 0.9, uy = sandY(ux)
            var pole = Path(); pole.move(to: CGPoint(x: ux, y: uy)); pole.addLine(to: CGPoint(x: ux - 4, y: uy - 34))
            ctx.stroke(pole, with: .color(Color(hex: 0x5A3E2B)), lineWidth: 1.6)
            var canopy = Path()
            canopy.addArc(center: CGPoint(x: ux - 4, y: uy - 30), radius: 18, startAngle: .degrees(190), endAngle: .degrees(350), clockwise: false)
            canopy.closeSubpath()
            ctx.fill(canopy, with: .color(Pal.coral))

            // the sea: everything under the water line and over the sand
            var sea = Path()
            sea.move(to: CGPoint(x: 0, y: waterY)); sea.addLine(to: CGPoint(x: xw, y: waterY)); sea.addLine(to: CGPoint(x: 0, y: h)); sea.closeSubpath()
            ctx.fill(sea, with: .linearGradient(Gradient(colors: [C.sea.opacity(0.9), C.seaDeep.opacity(0.95)]), startPoint: CGPoint(x: 0, y: waterY), endPoint: CGPoint(x: 0, y: h)))
            // moonlight on the water and little ripples
            for k in 0..<4 {
                let y = waterY + 5 + Double(k) * 6
                let x0 = mp.x - 14 + sin(t * 2 + Double(k)) * 4
                guard x0 + 28 < shoreX(y) else { continue }
                var g = Path(); g.move(to: CGPoint(x: x0, y: y)); g.addLine(to: CGPoint(x: x0 + 28 - Double(k) * 5, y: y))
                ctx.stroke(g, with: .color(C.moon.opacity(0.5 * cl(sin(.pi * p) * 3))), lineWidth: 1.4)
            }
            var foam = Path()
            foam.move(to: CGPoint(x: max(0, xw - 34), y: waterY + 0.5))
            for i in 1...8 { foam.addLine(to: CGPoint(x: xw - 34 + Double(i) * 4.25, y: waterY + 0.5 + (i % 2 == 0 ? -1.3 : 1.3) * (0.6 + 0.4 * sin(t * 6)))) }
            ctx.stroke(foam, with: .color(.white.opacity(0.9)), lineWidth: 1.6)
            ctx.stroke(Path(CGRect(x: 0, y: waterY, width: xw, height: 0)), with: .color(C.seaHi), lineWidth: 1.5)

            // the two marks
            let hi = pr(lvl, 0.75, 0.95), lo = 1 - pr(lvl, 0.05, 0.25)
            for (y, x, txt, on) in [(highY, xHigh, "HIGH TIDE", hi), (lowY, xLow, "LOW TIDE", lo)] {
                var d = Path(); d.move(to: CGPoint(x: x - 4, y: y)); d.addLine(to: CGPoint(x: x + 26, y: y))
                ctx.stroke(d, with: .color(.white.opacity(0.75)), style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
                Kit.chip(&ctx, txt, CGPoint(x: min(x + 30, w - chipW(txt, 9) - 2), y: y), anchor: .leading, color: on > 0.5 ? Pal.signal : .white, size: 9, alpha: 0.55 + 0.45 * on)
            }
            note(&ctx, s, "SHOWN MUCH FASTER", at: CGPoint(x: 10, y: 10), anchor: .topLeading)
        }
    }
}

// MARK: - Card 2: the Moon's gravity pulls the ocean into one bulge

struct TidesPull: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 8, still: 5, cues: [Cue(2.2, .soft)], replayOnTap: true, sky: dusk,
                    label: "Earth seen from above, with a layer of ocean all round it and the Moon to its right. Arrows show the Moon's pull, gravity. The rock stays put, but the water flows toward the Moon and piles up in one bulge on the side facing it. The bulge is drawn much bigger than it really is.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let b = eio(pr(t, 0.8, 3.0)) * (1 - eio(pr(t, 7.2, 8.0)))
            let R = min(w * 0.24, h * 0.32)
            let c = CGPoint(x: w * 0.34, y: h * 0.53)
            let mr = R * 0.36
            let mc = CGPoint(x: w - mr - 14, y: c.y)
            sky(&ctx, s, t)
            earth(&ctx, c, R, spin: t * 0.08) { a in
                let k = max(0, cos(a))
                return R * (1.13 + b * (0.34 * k * k * k - 0.05))
            }
            moon(&ctx, mc, mr)
            // the pull: chevrons flowing from the Earth toward the Moon
            let x0 = c.x + R * 1.5, x1 = mc.x - mr - 6
            for i in 0..<3 {
                let k = ((t * 0.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1))
                let x = x0 + (x1 - x0 - 14) * k
                arrow(&ctx, CGPoint(x: x, y: c.y), CGPoint(x: x + 14, y: c.y), Pal.signal, width: 2.4, alpha: sin(.pi * k) * (0.35 + 0.65 * cl(t / 0.8)))
            }
            for dy in [-0.42, 0.42] {
                let k = ((t * 0.5 + 0.5).truncatingRemainder(dividingBy: 1))
                let x = x0 + (x1 - x0 - 12) * k
                arrow(&ctx, CGPoint(x: x, y: c.y + dy * R), CGPoint(x: x + 12, y: c.y + dy * R * 0.88), Pal.signal, width: 1.6, alpha: sin(.pi * k) * 0.6)
            }
            let g = "GRAVITY: THE MOON'S PULL"
            Kit.chip(&ctx, g, CGPoint(x: fitX((x0 + x1) / 2, g, 8, w), y: c.y - R * 1.0), anchor: .bottom, color: Pal.signal, size: 8)
            Kit.chip(&ctx, "ROCK: HARDLY MOVES", CGPoint(x: c.x, y: c.y + R * 0.3), color: .white, size: 7)
            Kit.chip(&ctx, "WATER: FREE TO FLOW", CGPoint(x: fitX(c.x, "WATER: FREE TO FLOW", 7, w), y: c.y + R * 1.2 + 6), anchor: .top, color: C.seaHi, size: 7)
            let bulge = "ONE BULGE"
            Kit.chip(&ctx, bulge, CGPoint(x: c.x + R * 1.42, y: c.y + R * 0.5), anchor: .topLeading, color: C.seaHi, size: 8, alpha: pr(b, 0.6, 0.95))
            note(&ctx, s, "BULGE DRAWN MUCH BIGGER", at: CGPoint(x: w - 8, y: h - 8), anchor: .bottomTrailing, alpha: 0.85)
        }
    }
}

// MARK: - Card 3: the pull is strongest on the near side, weakest on the far side, so there are two bulges

struct TidesTwo: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 11, still: 8, cues: [Cue(0.6, .light), Cue(1.3, .light), Cue(2.0, .light), Cue(5.4, .soft)], replayOnTap: true, sky: dusk,
                    label: "Earth from above with its ocean, and the Moon to the right. Three arrows show the Moon's pull: longest on the near side, shorter in the middle, shortest on the far side. The near water moves toward the Moon the most and bulges out. The far water moves least, gets left behind, and makes a second bulge on the far side. The bulges are drawn much bigger than they really are.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let fade = 1 - eio(pr(t, 10.3, 11))
            let bn = eio(pr(t, 2.8, 4.4)) * fade, bf = eio(pr(t, 4.4, 6.0)) * fade
            let R = min(w * 0.22, h * 0.3)
            let c = CGPoint(x: w * 0.38, y: h * 0.5)
            let mr = R * 0.34
            let mc = CGPoint(x: w - mr - 10, y: c.y)
            sky(&ctx, s, t)
            earth(&ctx, c, R, spin: t * 0.06) { a in
                let k = cos(a)
                let near = max(0, k) * max(0, k), far = max(0, -k) * max(0, -k)
                return R * (1.1 + 0.3 * (bn * near + bf * far) - 0.06 * (bn + bf) / 2 * sin(a) * sin(a))
            }
            moon(&ctx, mc, mr)
            // the three pulls
            let arrows: [(Double, Double, String, Double, Bool)] = [   // start x, length, label, appears at, label above
                (c.x + R * 1.08, R * 0.95, "PULLS MOST", 0.3, true),
                (c.x - R * 0.08, R * 0.6, "PULLS LESS", 1.0, false),
                (c.x - R * 1.06, R * 0.34, "PULLS LEAST", 1.7, true)
            ]
            for (x, len, txt, at, above) in arrows {
                let g = eio(pr(t, at, at + 0.5)) * fade
                guard g > 0 else { continue }
                arrow(&ctx, CGPoint(x: x, y: c.y), CGPoint(x: x + len * g, y: c.y), Pal.coral, width: 3.4)
                let lx = fitX(x + len / 2, txt, 8, w)
                Kit.chip(&ctx, txt, CGPoint(x: lx, y: above ? c.y - 11 : c.y + 11), anchor: above ? .bottom : .top, color: Pal.signal, size: 8, alpha: pr(t, at + 0.2, at + 0.5) * fade)
            }
            let lb = "LEFT BEHIND"
            Kit.chip(&ctx, lb, CGPoint(x: fitX(c.x - R * 1.15, lb, 8, w), y: c.y + R * 0.62), anchor: .top, color: C.seaHi, size: 8, alpha: pr(t, 5.3, 5.7) * fade)
            let tb = "TWO BULGES"
            Kit.chip(&ctx, tb, CGPoint(x: w / 2, y: 10), anchor: .top, color: C.seaHi, size: 9, alpha: pr(t, 6.2, 6.6) * fade)
            note(&ctx, s, "BULGE DRAWN MUCH BIGGER", at: CGPoint(x: w - 8, y: h - 8), anchor: .bottomTrailing, alpha: 0.85)
        }
    }
}

// MARK: - Card 4 (hands-on): spin Earth through the two bulges; your beach gets two high tides a day

struct TidesSpin: View {
    let active: Bool
    @State private var day = 0.0          // 0...1 = one turn of Earth
    @State private var touched = false
    @State private var t0 = Date()
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        TidePanel {
            VStack(spacing: 4) {
                TimelineView(.animation(paused: !active || reduce)) { tl in
                    Canvas { ctx, s in draw(&ctx, s, tl.date.timeIntervalSince(t0)) }
                }
                HStack(spacing: 8) {
                    Text("START").font(T.mono(9)).foregroundStyle(.white.opacity(0.75))
                    Slider(value: Binding(get: { day }, set: { day = $0; if !touched { touched = true; Haptic.fire(.soft) } }), in: 0...1)
                        .tint(Pal.coral)
                    Text("1 DAY").font(T.mono(9)).foregroundStyle(Pal.signal)
                }
                .padding(.horizontal, 12).padding(.bottom, 8)
            }
        }
        .task(id: "\(active)-\(touched)-\(reduce)") {
            guard active, !touched else { return }
            if reduce { day = 0.75; return }
            t0 = Date()
            while !Task.isCancelled && !touched {
                let t = Date().timeIntervalSince(t0).truncatingRemainder(dividingBy: 10.5)
                day = pr(t, 0.6, 8.6)
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Earth from above, with the ocean stretched into two bulges, one toward the Moon and one on the far side. A slider turns Earth through one day. A marked beach rides round with it: in a bulge it has high tide, between the bulges low tide. In one turn it passes through both bulges, so it gets two high tides a day.")
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ time: Double) {
        let w = s.width, h = s.height
        let R = min(w * 0.23, h * 0.3)
        let c = CGPoint(x: w * 0.36, y: h * 0.53)
        let mr = R * 0.32
        let mc = CGPoint(x: w - mr - 12, y: c.y + R * 0.15)
        func rad(_ a: Double) -> Double { let k = cos(a); return R * (1.1 + 0.32 * k * k) }
        let spin = 2 * .pi * day
        sky(&ctx, s, time)
        earth(&ctx, c, R, spin: spin, ocean: rad)
        moon(&ctx, mc, mr)
        Kit.chip(&ctx, "THE MOON", CGPoint(x: fitX(mc.x, "THE MOON", 7, w), y: mc.y + mr + 8), anchor: .top, color: C.moon, size: 7, alpha: 0.85)
        // your beach rides round on the rock
        let a = .pi / 2 + spin
        let depth = cos(a) * cos(a)                  // 1 inside a bulge, 0 between them
        let bp = CGPoint(x: c.x + R * cos(a), y: c.y - R * sin(a))
        Kit.ring(&ctx, bp, 7 + 1.5 * sin(time * 4), C.beach, width: 1.6)
        ctx.fill(Path(ellipseIn: CGRect(x: bp.x - 4, y: bp.y - 4, width: 8, height: 8)), with: .color(C.beach))
        // turning arrow
        var turn = Path()
        turn.addArc(center: c, radius: R * 0.62, startAngle: .degrees(-200), endAngle: .degrees(-250), clockwise: true)
        ctx.stroke(turn, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        let ta = 250.0 * .pi / 180
        arrow(&ctx, CGPoint(x: c.x + R * 0.62 * cos(ta - 0.15), y: c.y - R * 0.62 * sin(ta - 0.15)), CGPoint(x: c.x + R * 0.62 * cos(ta), y: c.y - R * 0.62 * sin(ta)), .white.opacity(0.8), width: 1.6)

        // inset: your beach from the side
        let box = CGRect(x: w * 0.64, y: 10, width: w * 0.36 - 10, height: min(h * 0.3, 74))
        ctx.fill(Path(roundedRect: box, cornerRadius: 6), with: .color(Pal.night.opacity(0.55)))
        ctx.stroke(Path(roundedRect: box, cornerRadius: 6), with: .color(C.beach.opacity(0.8)), lineWidth: 1.2)
        let inner = box.insetBy(dx: 6, dy: 6)
        ctx.drawLayer { l in
            l.clip(to: Path(roundedRect: inner, cornerRadius: 3))
            let lowY = inner.maxY - inner.height * 0.18, highY = inner.minY + inner.height * 0.42
            let wy = lowY + (highY - lowY) * depth
            func sandY(_ x: Double) -> Double { inner.maxY - (x - inner.minX) / inner.width * inner.height * 0.75 }
            var sand = Path(); sand.move(to: CGPoint(x: inner.minX, y: inner.maxY)); sand.addLine(to: CGPoint(x: inner.maxX, y: sandY(inner.maxX))); sand.addLine(to: CGPoint(x: inner.maxX, y: inner.maxY)); sand.closeSubpath()
            l.fill(sand, with: .color(C.sand))
            let xw = inner.minX + (inner.maxY - wy) / (inner.height * 0.75) * inner.width
            var sea = Path(); sea.move(to: CGPoint(x: inner.minX, y: wy)); sea.addLine(to: CGPoint(x: xw, y: wy)); sea.addLine(to: CGPoint(x: inner.minX, y: inner.maxY)); sea.closeSubpath()
            l.fill(sea, with: .color(C.sea.opacity(0.92)))
        }
        let state = depth > 0.7 ? "HIGH TIDE" : depth < 0.3 ? "LOW TIDE" : ""
        Kit.chip(&ctx, "YOUR BEACH", CGPoint(x: box.minX + 6, y: box.minY + 6), anchor: .topLeading, color: C.beach, size: 7)
        if !state.isEmpty { Kit.chip(&ctx, state, CGPoint(x: box.midX, y: box.maxY + 6), anchor: .top, color: depth > 0.7 ? Pal.signal : .white, size: 9) }

        // the counter
        let highs = (day >= 0.25 ? 1 : 0) + (day >= 0.75 ? 1 : 0)
        let doneDay = day >= 0.97
        let txt = doneDay ? "2 HIGH TIDES A DAY" : "HIGH TIDES SO FAR: \(highs)"
        Kit.chip(&ctx, txt, CGPoint(x: 10, y: 10), anchor: .topLeading, color: doneDay ? Pal.signal : .white, size: doneDay ? 10 : 8)
        note(&ctx, s, "BULGE DRAWN MUCH BIGGER", at: CGPoint(x: w - 8, y: h - 6), anchor: .bottomTrailing, alpha: 0.8)
    }
}

// MARK: - Card 5: the Sun pulls too; in a line the bulges grow (spring tides), a quarter turn later they shrink

struct TidesSun: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 12, still: 1.5, cues: [Cue(0.3, .soft), Cue(6.3, .soft)], replayOnTap: true, sky: dusk,
                    label: "The Sun on the left, Earth in the middle with its ocean, and the Moon going round Earth. The Sun's pull is a bit less than half the Moon's. At new moon and full moon the Sun, Earth and Moon are in a line, their pulls add together and the bulges are big: spring tides. At half moon they are not in a line and the bulges are smaller. The bulges are drawn much bigger than they really are.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let k = Int(t / 3) % 4
            let lt = t - Double(k) * 3
            let e = eio(pr(lt, 2.1, 3.0))
            let am = Double.pi + Double.pi / 2 * (Double(k) + e)     // new moon (left) → half → full (right) → half
            let R = min(w * 0.12, h * 0.17)
            let c = CGPoint(x: w * 0.6, y: h * 0.52)
            let orbit = min(w * 0.27, h * 0.33)
            sky(&ctx, s, t)
            // the Sun, big and far away to the left
            let sc = CGPoint(x: -w * 0.03, y: c.y)
            let sr = min(h * 0.2, w * 0.14)
            ctx.fill(Path(ellipseIn: CGRect(x: sc.x - sr * 2.2, y: sc.y - sr * 2.2, width: sr * 4.4, height: sr * 4.4)),
                     with: .radialGradient(Gradient(colors: [C.sun.opacity(0.55), C.sunHot.opacity(0.18), .clear]), center: sc, startRadius: sr * 0.8, endRadius: sr * 2.2))
            ctx.fill(Path(ellipseIn: CGRect(x: sc.x - sr, y: sc.y - sr, width: 2 * sr, height: 2 * sr)),
                     with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF2B0), C.sun, C.sunHot]), center: sc, startRadius: 0, endRadius: sr))
            Kit.chip(&ctx, "THE SUN", CGPoint(x: 10, y: sc.y + sr + 8), anchor: .topLeading, color: C.sun, size: 7)
            // the Moon's path
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - orbit, y: c.y - orbit, width: 2 * orbit, height: 2 * orbit)), with: .color(.white.opacity(0.22)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            // the ocean: the Moon's stretch plus the Sun's (a bit less than half as strong) along the Sun's line
            earth(&ctx, c, R, spin: t * 0.05) { a in
                let m = cos(a - am), sn = cos(a)
                return R * (1.08 + 0.26 * (m * m + 0.46 * sn * sn))
            }
            let mp = CGPoint(x: c.x + orbit * cos(am), y: c.y - orbit * sin(am))
            let mr = R * 0.4
            moon(&ctx, mp, mr, lightFromLeft: true)
            let inLine = (k % 2 == 0)
            let hold = e < 0.05 ? pr(lt, 0.15, 0.5) : 0
            let phase = k == 0 ? "NEW MOON" : k == 2 ? "FULL MOON" : "HALF MOON"
            let below = mp.y < c.y - orbit * 0.5
            Kit.chip(&ctx, phase, CGPoint(x: fitX(mp.x, phase, 7, w), y: below ? mp.y + mr + 6 : mp.y - mr - 6), anchor: below ? .top : .bottom, color: C.moon, size: 7, alpha: hold)
            let l1 = inLine ? "SUN AND MOON IN A LINE" : "NOT IN A LINE"
            let l2 = inLine ? "SPRING TIDES: BIGGER" : "SMALLER TIDES"
            Kit.chip(&ctx, l1, CGPoint(x: 10, y: 10), anchor: .topLeading, color: .white, size: 8, alpha: hold)
            Kit.chip(&ctx, l2, CGPoint(x: 10, y: 32), anchor: .topLeading, color: inLine ? Pal.signal : C.seaHi, size: 9, alpha: hold)
            // how strong each pull is on the tides
            let bx = 10.0, by = h - 34, bw = w * 0.2
            for (i, (txt, f, col)) in [("MOON'S PULL", 1.0, C.moon), ("SUN'S PULL", 0.46, C.sun)].enumerated() {
                let y = by + Double(i) * 14
                ctx.draw(ctx.resolve(Text(txt).font(T.mono(7)).foregroundColor(.white.opacity(0.85))), at: CGPoint(x: bx, y: y), anchor: .leading)
                ctx.fill(Path(roundedRect: CGRect(x: bx + 66, y: y - 3, width: bw * f, height: 6), cornerRadius: 3), with: .color(col))
            }
            note(&ctx, s, "BULGE DRAWN MUCH BIGGER", at: CGPoint(x: w - 8, y: h - 8), anchor: .bottomTrailing, alpha: 0.85)
        }
    }
}

// MARK: - Card 6: the same bulge, a wide open coast vs a funnel-shaped bay

struct TidesCoast: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 7, still: 3.5, cues: [Cue(3.5, .soft)], replayOnTap: true, sky: [0x2B1C55, 0x6A3570, 0xE8876A],
                    label: "Two shores side by side, each with a four-storey building drawn for size. On the open ocean coast the sea rises and falls by less than a metre, a thin line at the building's foot. In the Bay of Fundy, a long narrow bay shaped like a funnel, the sea rises about 16 metres, higher than the building's roof, then falls again.") { ctx, s, t, _ in
            let w = s.width, h = s.height
            let lvl = 0.5 - 0.5 * cos(2 * .pi * t / 7)
            let top = 60.0, floorY = h - 12
            let mpx = (floorY - top) / 19.0                  // pixels per metre
            let lowY = floorY - 2.5 * mpx
            sky(&ctx, s, t, maxY: 0.3)
            var div = Path(); div.move(to: CGPoint(x: w / 2, y: 8)); div.addLine(to: CGPoint(x: w / 2, y: h - 8))
            ctx.stroke(div, with: .color(.white.opacity(0.25)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            for side in 0..<2 {
                let x0 = side == 0 ? 0.0 : w / 2, hw = w / 2
                let range = side == 0 ? 0.8 : 16.0
                let wy = lowY - range * mpx * lvl
                // header: name and size, plus a tiny map of the coast's shape
                let name = side == 0 ? "OPEN OCEAN" : "BAY OF FUNDY"
                let size = side == 0 ? "UNDER 1 M" : "ABOUT 16 M"
                Kit.chip(&ctx, name, CGPoint(x: x0 + 10, y: 10), anchor: .topLeading, color: .white, size: 8)
                Kit.chip(&ctx, size, CGPoint(x: x0 + 10, y: 32), anchor: .topLeading, color: side == 0 ? C.seaHi : Pal.signal, size: 10)
                let map = CGRect(x: x0 + hw - 52, y: 10, width: 42, height: 40)
                ctx.fill(Path(roundedRect: map, cornerRadius: 4), with: .color(C.rock.opacity(0.85)))
                var water = Path()
                if side == 0 {
                    water.addRect(CGRect(x: map.minX, y: map.minY + map.height * 0.45, width: map.width, height: map.height * 0.55))
                } else {
                    water.move(to: CGPoint(x: map.minX, y: map.maxY)); water.addLine(to: CGPoint(x: map.maxX, y: map.maxY))
                    water.addLine(to: CGPoint(x: map.midX + 3, y: map.minY + 4)); water.addLine(to: CGPoint(x: map.midX - 3, y: map.minY + 4)); water.closeSubpath()
                }
                ctx.drawLayer { l in
                    l.clip(to: Path(roundedRect: map, cornerRadius: 4))
                    l.fill(water, with: .color(C.sea))
                }
                for dx in [-0.3, 0.0, 0.3] {
                    let a = CGPoint(x: map.midX + dx * map.width, y: map.maxY - 3)
                    let b = side == 0 ? CGPoint(x: a.x, y: map.minY + map.height * 0.55) : CGPoint(x: map.midX + dx * 6, y: map.minY + map.height * 0.4)
                    arrow(&ctx, a, b, .white.opacity(0.85), width: 1.2)
                }
                // side view: sea floor, a bank, the water and a four-storey building for size
                let shore = x0 + hw * 0.78
                var ground = Path()
                ground.move(to: CGPoint(x: x0, y: floorY)); ground.addLine(to: CGPoint(x: shore, y: floorY)); ground.addLine(to: CGPoint(x: x0 + hw, y: top + 4))
                ground.addLine(to: CGPoint(x: x0 + hw, y: h)); ground.addLine(to: CGPoint(x: x0, y: h)); ground.closeSubpath()
                let shoreAt: (Double) -> Double = { y in shore + (floorY - y) / (floorY - top - 4) * (hw * 0.22) }
                // building
                let bw = hw * 0.22, bh = 13 * mpx
                let bx = x0 + hw * 0.36
                let bRect = CGRect(x: bx, y: lowY - bh, width: bw, height: bh)
                ctx.fill(Path(bRect), with: .color(Color(hex: 0xF3D9B0)))
                ctx.stroke(Path(bRect), with: .color(Color(hex: 0x8A5A3C)), lineWidth: 1)
                for fl in 0..<4 {
                    for col in 0..<2 {
                        let win = CGRect(x: bx + bw * (0.18 + 0.44 * Double(col)), y: bRect.minY + bh * (0.07 + 0.25 * Double(fl)), width: bw * 0.22, height: bh * 0.12)
                        ctx.fill(Path(win), with: .color(Color(hex: 0x7FA8D8)))
                    }
                }
                ctx.fill(Path(CGRect(x: bx - 2, y: lowY, width: bw + 4, height: floorY - lowY)), with: .color(Color(hex: 0x9C7A5A)))   // its base, down to the sea floor
                Kit.chip(&ctx, "4 STOREYS", CGPoint(x: bx + bw / 2, y: bRect.minY - 4), anchor: .bottom, color: .white, size: 7, alpha: 0.9)
                // water up to the shore
                var sea = Path()
                sea.move(to: CGPoint(x: x0, y: wy)); sea.addLine(to: CGPoint(x: shoreAt(wy), y: wy)); sea.addLine(to: CGPoint(x: shore, y: floorY)); sea.addLine(to: CGPoint(x: x0, y: floorY)); sea.closeSubpath()
                ctx.fill(sea, with: .linearGradient(Gradient(colors: [C.sea.opacity(0.85), C.seaDeep.opacity(0.92)]), startPoint: CGPoint(x: 0, y: wy), endPoint: CGPoint(x: 0, y: floorY)))
                ctx.stroke(Path(CGRect(x: x0, y: wy, width: shoreAt(wy) - x0, height: 0)), with: .color(C.seaHi), lineWidth: 1.6)
                ctx.fill(ground, with: .linearGradient(Gradient(colors: [C.sand, Color(hex: 0xC99A5E)]), startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: h)))
                // the high and low marks, with the gap between them
                let highY = lowY - range * mpx
                for y in [highY, lowY] {
                    var d = Path(); d.move(to: CGPoint(x: x0 + 6, y: y)); d.addLine(to: CGPoint(x: shoreAt(y), y: y))
                    ctx.stroke(d, with: .color(.white.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                if side == 1 {
                    let ax = x0 + hw * 0.18
                    arrow(&ctx, CGPoint(x: ax, y: lowY - 2), CGPoint(x: ax, y: highY + 1), Pal.signal, width: 1.8)
                    arrow(&ctx, CGPoint(x: ax, y: highY + 2), CGPoint(x: ax, y: lowY - 1), Pal.signal, width: 1.8)
                }
            }
        }
    }
}
