import SwiftUI

// "How does a card tap move money from your bank to a shop?" topic: five flat Canvas scenes. First build, 2026-10-26.
// Warm, cheerful money colours: a card, a card reader, a shop, banks with columns, an envelope, coins.
// Nothing is drawn to scale: the two seconds of the real trip are stretched, and the coins are just counters (every card says what it shows).
// Card 3 is hands-on (a two-way toggle: every pair of banks joined, or joined through one network) and plays a silent demo until it is touched.

private func pyCl(_ x: Double) -> Double { min(1, max(0, x)) }
private func pyPr(_ t: Double, _ a: Double, _ b: Double) -> Double { pyCl((t - a) / (b - a)) }
private func pyEio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
private func pyEo(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
/// A pop: overshoots a little, then settles at 1.
private func pyPop(_ x: Double) -> Double { let c1 = 1.70158, c3 = c1 + 1; return x <= 0 ? 0 : x >= 1 ? 1 : 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }
/// A short bump, 1 at x = 0 and 0 beyond `r`.
private func pyBump(_ x: Double, _ r: Double) -> Double { max(0, 1 - abs(x) / r) }
private func pyLerp(_ a: CGPoint, _ b: CGPoint, _ k: Double) -> CGPoint { CGPoint(x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k) }

/// Blend between two hex colours.
private func pyMix(_ a: UInt32, _ b: UInt32, _ k: Double) -> Color {
    func ch(_ v: UInt32, _ shift: UInt32) -> Double { Double((v >> shift) & 0xFF) }
    let k = pyCl(k)
    return Color(red: (ch(a, 16) + (ch(b, 16) - ch(a, 16)) * k) / 255,
                 green: (ch(a, 8) + (ch(b, 8) - ch(a, 8)) * k) / 255,
                 blue: (ch(a, 0) + (ch(b, 0) - ch(a, 0)) * k) / 255)
}

private enum PY {
    static let sky: [UInt32] = [0xFFF4D6, 0xFFE8BD, 0xFFDAA6]
    static let coral = Color(hex: 0xFF6B4A), orange = Color(hex: 0xFF9A3C), gold = Color(hex: 0xFFC83D), goldDark = Color(hex: 0xD98E12)
    static let green = Color(hex: 0x2FB567), greenDark = Color(hex: 0x1E8C4C), greenText = Color(hex: 0x8EEBB0)
    static let teal = Color(hex: 0x2BB5A6), blue = Color(hex: 0x3F7DDB), plum = Color(hex: 0x4A3B5C), plumDark = Color(hex: 0x33283F)
    static let purple = Color(hex: 0x7A5CE0), cream = Color(hex: 0xFFFBF0), ink = Color(hex: 0x3A2A1E)
    static let wood = Color(hex: 0xB9733A), woodLight = Color(hex: 0xDB9A5C)
    static let coralText = Color(hex: 0xFFAE98), goldText = Color(hex: 0xFFE08A)
}

/// Keep a centred chip inside a width.
private func pyFit(_ x: Double, _ text: String, _ size: Double, _ w: Double) -> Double {
    let half = (Double(text.count) * size * 0.66 + 18) / 2
    return min(max(x, half + 4), w - half - 4)
}

/// Text drawn in the picture itself (numbers and short words that sit on shapes).
private func pyText(_ ctx: inout GraphicsContext, _ s: String, _ p: CGPoint, size: Double, color: Color, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    var l = ctx; l.opacity = alpha
    l.draw(Text(s).font(.system(size: size, weight: .heavy, design: .rounded)).foregroundColor(color), at: p, anchor: .center)
}

/// An arc as a sampled path (angles in degrees, y down).
private func pyArc(_ c: CGPoint, _ r: Double, _ a0: Double, _ a1: Double) -> Path {
    var p = Path()
    for i in 0...12 {
        let a = (a0 + (a1 - a0) * Double(i) / 12) * .pi / 180
        let q = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
        if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
    }
    return p
}

/// A route made of straight legs: where a packet is, and the part already travelled.
private struct PYRoute {
    let pts: [CGPoint]
    private let lens: [Double]
    let total: Double
    init(_ pts: [CGPoint]) {
        self.pts = pts
        var ls: [Double] = []
        for i in 1..<pts.count { ls.append(hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)) }
        lens = ls; total = ls.reduce(0, +)
    }
    /// Fraction of the route where leg boundary `i` sits.
    func at(_ i: Int) -> Double { lens.prefix(i).reduce(0, +) / total }
    func point(_ f: Double) -> CGPoint {
        var d = pyCl(f) * total
        for (i, l) in lens.enumerated() {
            if d <= l || i == lens.count - 1 { return pyLerp(pts[i], pts[i + 1], l > 0 ? min(1, d / l) : 0) }
            d -= l
        }
        return pts[pts.count - 1]
    }
    func path(_ f: Double) -> Path {
        var d = pyCl(f) * total
        var p = Path(); p.move(to: pts[0])
        for (i, l) in lens.enumerated() {
            if d <= 0 { break }
            let k = l > 0 ? min(1, d / l) : 0
            p.addLine(to: pyLerp(pts[i], pts[i + 1], k))
            d -= l
        }
        return p
    }
    var full: Path { path(1) }
}

// MARK: - Icons

/// A shiny gold coin.
private func pyCoin(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, alpha: Double = 1, ring: Color? = nil) {
    guard alpha > 0.01, r > 0.5 else { return }
    var l = ctx; l.opacity = alpha
    let rect = CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
    l.fill(Path(ellipseIn: rect.offsetBy(dx: 0, dy: r * 0.14)), with: .color(.black.opacity(0.14)))
    l.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(colors: [Color(hex: 0xFFE680), PY.gold, Color(hex: 0xF0A818)]), center: CGPoint(x: c.x - r * 0.3, y: c.y - r * 0.35), startRadius: 0, endRadius: r * 1.3))
    l.stroke(Path(ellipseIn: rect), with: .color(ring ?? PY.goldDark), lineWidth: max(1, r * 0.14))
    l.stroke(Path(ellipseIn: rect.insetBy(dx: r * 0.34, dy: r * 0.34)), with: .color(PY.goldDark.opacity(0.55)), lineWidth: max(0.8, r * 0.1))
}

/// A tower of flat coins standing on `base`.
private func pyStack(_ ctx: inout GraphicsContext, _ base: CGPoint, _ n: Int, _ rw: Double, alpha: Double = 1) {
    guard n > 0, alpha > 0.01 else { return }
    var l = ctx; l.opacity = alpha
    let th = rw * 0.32, ry = rw * 0.36
    l.fill(Path(ellipseIn: CGRect(x: base.x - rw * 1.15, y: base.y - ry * 0.9, width: rw * 2.3, height: ry * 1.8)), with: .color(.black.opacity(0.12)))
    for i in 0..<n {
        let cy = base.y - Double(i) * th
        let body = Path(CGRect(x: base.x - rw, y: cy - th, width: 2 * rw, height: th))
        l.fill(Path(ellipseIn: CGRect(x: base.x - rw, y: cy - ry, width: 2 * rw, height: 2 * ry)), with: .color(PY.goldDark))
        l.fill(body, with: .color(PY.goldDark))
        let top = CGRect(x: base.x - rw, y: cy - th - ry, width: 2 * rw, height: 2 * ry)
        l.fill(Path(ellipseIn: top), with: .color(PY.gold))
        l.stroke(Path(ellipseIn: top), with: .color(Color(hex: 0xB8780A)), lineWidth: 1)
    }
}

/// A message: a small envelope.
private func pyEnvelope(_ ctx: inout GraphicsContext, _ c: CGPoint, _ w: Double, angle: Double = 0, alpha: Double = 1, color: Color = PY.coral) {
    guard alpha > 0.01, w > 1 else { return }
    var l = ctx; l.opacity = alpha
    l.translateBy(x: c.x, y: c.y); l.rotate(by: .radians(angle))
    let r = CGRect(x: -w / 2, y: -w * 0.34, width: w, height: w * 0.68)
    l.fill(Path(roundedRect: r.offsetBy(dx: 0, dy: w * 0.05), cornerRadius: w * 0.1), with: .color(.black.opacity(0.14)))
    l.fill(Path(roundedRect: r, cornerRadius: w * 0.1), with: .color(.white))
    l.stroke(Path(roundedRect: r, cornerRadius: w * 0.1), with: .color(color), lineWidth: max(1.4, w * 0.07))
    var flap = Path()
    flap.move(to: CGPoint(x: r.minX + w * 0.03, y: r.minY + w * 0.04)); flap.addLine(to: CGPoint(x: 0, y: w * 0.06)); flap.addLine(to: CGPoint(x: r.maxX - w * 0.03, y: r.minY + w * 0.04))
    l.stroke(flap, with: .color(color), style: StrokeStyle(lineWidth: max(1.4, w * 0.07), lineCap: .round, lineJoin: .round))
}

/// A bank card.
private func pyCard(_ ctx: inout GraphicsContext, _ c: CGPoint, _ w: Double, angle: Double = 0, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    var l = ctx; l.opacity = alpha
    l.translateBy(x: c.x, y: c.y); l.rotate(by: .radians(angle))
    let h = w * 0.63
    let r = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
    l.fill(Path(roundedRect: r.offsetBy(dx: 0, dy: h * 0.07), cornerRadius: h * 0.14), with: .color(.black.opacity(0.16)))
    l.fill(Path(roundedRect: r, cornerRadius: h * 0.14), with: .linearGradient(Gradient(colors: [PY.teal, PY.blue]), startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    l.fill(Path(CGRect(x: r.minX, y: r.minY + h * 0.2, width: w, height: h * 0.14)), with: .color(.white.opacity(0.35)))
    l.fill(Path(roundedRect: CGRect(x: r.minX + w * 0.09, y: r.minY + h * 0.46, width: w * 0.2, height: h * 0.24), cornerRadius: h * 0.05), with: .color(PY.gold))
    l.fill(Path(roundedRect: CGRect(x: r.minX + w * 0.09, y: r.maxY - h * 0.17, width: w * 0.42, height: h * 0.07), cornerRadius: h * 0.03), with: .color(.white.opacity(0.7)))
    for i in 0..<3 { l.stroke(pyArc(CGPoint(x: r.maxX - w * 0.16, y: r.minY + h * 0.6), w * (0.05 + 0.04 * Double(i)), -50, 50), with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: max(1, w * 0.02), lineCap: .round)) }
}

/// The three curved lines that mean "tap here".
private func pyWaves(_ ctx: inout GraphicsContext, _ c: CGPoint, _ k: Double, color: Color) {
    for i in 0..<3 {
        ctx.stroke(pyArc(CGPoint(x: c.x, y: c.y + 7 * k), (6 + 5.5 * Double(i)) * k, -135, -45), with: .color(color), style: StrokeStyle(lineWidth: 2.4 * k, lineCap: .round))
    }
}

/// A card reader standing on `base`. `glow` 0...1 turns the tap pad and screen green. Returns the centre of the tap pad.
@discardableResult
private func pyReader(_ ctx: inout GraphicsContext, base: CGPoint, k: Double, glow: Double = 0, alpha: Double = 1) -> CGPoint {
    var l = ctx; l.opacity = alpha
    let bw = 84 * k, bh = 118 * k
    let body = CGRect(x: base.x - bw / 2, y: base.y - bh, width: bw, height: bh)
    l.fill(Path(ellipseIn: CGRect(x: body.minX - 6 * k, y: base.y - 5 * k, width: bw + 12 * k, height: 10 * k)), with: .color(.black.opacity(0.14)))
    l.fill(Path(roundedRect: body, cornerRadius: 14 * k), with: .linearGradient(Gradient(colors: [PY.plum, PY.plumDark]), startPoint: CGPoint(x: body.minX, y: body.minY), endPoint: CGPoint(x: body.maxX, y: body.maxY)))
    let pad = CGRect(x: body.minX + 9 * k, y: body.minY + 9 * k, width: bw - 18 * k, height: 30 * k)
    l.fill(Path(roundedRect: pad, cornerRadius: 8 * k), with: .color(pyMix(0x6E5C80, 0x5BE08F, glow)))
    pyWaves(&l, CGPoint(x: pad.midX, y: pad.midY - 6 * k), k, color: .white.opacity(0.95))
    let scr = CGRect(x: body.minX + 12 * k, y: pad.maxY + 9 * k, width: bw - 24 * k, height: 20 * k)
    l.fill(Path(roundedRect: scr, cornerRadius: 4 * k), with: .color(pyMix(0x8FD8CA, 0x6BF0A0, glow)))
    l.fill(Path(roundedRect: CGRect(x: scr.minX + 5 * k, y: scr.midY - 2 * k, width: (scr.width - 10 * k) * 0.55, height: 4 * k), cornerRadius: 2 * k), with: .color(PY.plumDark.opacity(0.55)))
    let kp = body.minY + 82 * k
    for r in 0..<3 {
        for c in 0..<3 {
            l.fill(Path(roundedRect: CGRect(x: base.x - 19 * k + Double(c) * 14 * k, y: kp + Double(r) * 11 * k - 6 * k, width: 10 * k, height: 7 * k), cornerRadius: 2 * k), with: .color(.white.opacity(0.28)))
        }
    }
    return CGPoint(x: pad.midX, y: pad.midY - 2 * k)
}

/// A bank: a roof, columns and steps. `tint` colours the roof and the steps.
private func pyBank(_ ctx: inout GraphicsContext, _ r: CGRect, tint: Color, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    var l = ctx; l.opacity = alpha
    let roofH = r.height * 0.30, capH = r.height * 0.07, stepH = r.height * 0.11
    var roof = Path()
    roof.move(to: CGPoint(x: r.midX, y: r.minY)); roof.addLine(to: CGPoint(x: r.maxX, y: r.minY + roofH)); roof.addLine(to: CGPoint(x: r.minX, y: r.minY + roofH)); roof.closeSubpath()
    l.fill(roof, with: .color(tint))
    let cc = CGPoint(x: r.midX, y: r.minY + roofH * 0.68)
    l.fill(Path(ellipseIn: CGRect(x: cc.x - roofH * 0.2, y: cc.y - roofH * 0.2, width: roofH * 0.4, height: roofH * 0.4)), with: .color(PY.gold))
    l.fill(Path(CGRect(x: r.minX - r.width * 0.03, y: r.minY + roofH, width: r.width * 1.06, height: capH)), with: .color(PY.cream))
    l.stroke(Path(CGRect(x: r.minX - r.width * 0.03, y: r.minY + roofH, width: r.width * 1.06, height: capH)), with: .color(PY.ink.opacity(0.25)), lineWidth: 1)
    let colTop = r.minY + roofH + capH, colBot = r.maxY - stepH
    for i in 0..<4 {
        let x = r.minX + r.width * (0.11 + 0.255 * Double(i))
        l.fill(Path(roundedRect: CGRect(x: x, y: colTop, width: r.width * 0.12, height: colBot - colTop), cornerRadius: r.width * 0.03), with: .color(.white))
        l.fill(Path(CGRect(x: x + r.width * 0.075, y: colTop, width: r.width * 0.045, height: colBot - colTop)), with: .color(PY.ink.opacity(0.1)))
    }
    l.fill(Path(CGRect(x: r.minX - r.width * 0.04, y: colBot, width: r.width * 1.08, height: stepH * 0.5)), with: .color(tint.opacity(0.65)))
    l.fill(Path(CGRect(x: r.minX - r.width * 0.08, y: colBot + stepH * 0.5, width: r.width * 1.16, height: stepH * 0.5)), with: .color(tint))
}

/// A tiny bank symbol for a dot.
private func pyBankGlyph(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, color: Color) {
    var roof = Path()
    roof.move(to: CGPoint(x: c.x, y: c.y - r)); roof.addLine(to: CGPoint(x: c.x + r, y: c.y - r * 0.35)); roof.addLine(to: CGPoint(x: c.x - r, y: c.y - r * 0.35)); roof.closeSubpath()
    ctx.fill(roof, with: .color(color))
    for i in 0..<3 { ctx.fill(Path(CGRect(x: c.x - r * 0.72 + Double(i) * r * 0.58, y: c.y - r * 0.2, width: r * 0.28, height: r * 0.78)), with: .color(color)) }
    ctx.fill(Path(CGRect(x: c.x - r, y: c.y + r * 0.7, width: 2 * r, height: r * 0.26)), with: .color(color))
}

/// A little shop with a striped awning.
private func pyShop(_ ctx: inout GraphicsContext, _ r: CGRect, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    var l = ctx; l.opacity = alpha
    let aw = r.height * 0.34
    l.fill(Path(roundedRect: CGRect(x: r.minX + r.width * 0.06, y: r.minY + aw * 0.6, width: r.width * 0.88, height: r.height - aw * 0.6), cornerRadius: 3), with: .color(PY.cream))
    l.stroke(Path(roundedRect: CGRect(x: r.minX + r.width * 0.06, y: r.minY + aw * 0.6, width: r.width * 0.88, height: r.height - aw * 0.6), cornerRadius: 3), with: .color(PY.ink.opacity(0.3)), lineWidth: 1)
    l.fill(Path(roundedRect: CGRect(x: r.midX - r.width * 0.12, y: r.minY + r.height * 0.58, width: r.width * 0.24, height: r.height * 0.42), cornerRadius: 2), with: .color(PY.wood))
    for i in 0..<4 {
        let x = r.minX + r.width * Double(i) / 4
        l.fill(Path(CGRect(x: x, y: r.minY, width: r.width / 4 + 0.4, height: aw)), with: .color(i % 2 == 0 ? PY.coral : PY.cream))
        l.fill(Path(ellipseIn: CGRect(x: x, y: r.minY + aw * 0.65, width: r.width / 4, height: aw * 0.7)), with: .color(i % 2 == 0 ? PY.coral : PY.cream))
    }
}

/// A green circle with a white tick; `k` 0...1 pops it in.
private func pyTick(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, k: Double = 1, color: Color = PY.green) {
    let s = pyPop(k)
    guard s > 0.01 else { return }
    let rr = r * s
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: 2 * rr, height: 2 * rr)), with: .color(color))
    var tk = Path()
    tk.move(to: CGPoint(x: c.x - rr * 0.42, y: c.y + rr * 0.02)); tk.addLine(to: CGPoint(x: c.x - rr * 0.1, y: c.y + rr * 0.36)); tk.addLine(to: CGPoint(x: c.x + rr * 0.46, y: c.y - rr * 0.34))
    ctx.stroke(tk, with: .color(.white), style: StrokeStyle(lineWidth: max(1.6, rr * 0.22), lineCap: .round, lineJoin: .round))
}

/// An arrow from a to b.
private func pyArrow(_ ctx: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ color: Color, width: Double = 3, alpha: Double = 1) {
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

// MARK: - Card 1: you tap a card on a reader; a beep, a message flies out, and the money stays put

struct PayTap: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 9, still: 3.4, cues: [Cue(1.6, .rigid), Cue(2.2, .soft)], replayOnTap: true, sky: PY.sky,
                    label: "A shop counter. A card is tapped on a card reader, and the reader beeps, with rings spreading out from it. A small message, drawn as an envelope, flies away from the reader. Beside it, the coins sit still in a wallet on the counter: the money stays put. Only a message goes out.") { ctx, s, t, _ in
            let w = s.width, h = s.height, u = min(w / 360, h / 345)
            let out = 1 - pyPr(t, 8.3, 8.9)
            let counterY = h * 0.70

            // the shop: a striped awning and a warm counter
            let awn = 34 * u, n = 8, sw = w / Double(n)
            for i in 0..<n {
                let x = Double(i) * sw
                let col = i % 2 == 0 ? PY.coral : PY.cream
                ctx.fill(Path(CGRect(x: x, y: 0, width: sw + 0.5, height: awn)), with: .color(col))
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: awn - sw * 0.3, width: sw, height: sw * 0.6)), with: .color(col))
            }
            let slab = 14 * u
            ctx.fill(Path(CGRect(x: 0, y: counterY + slab, width: w, height: h - counterY - slab)), with: .linearGradient(Gradient(colors: [PY.wood, Color(hex: 0x9A5C2C)]), startPoint: CGPoint(x: 0, y: counterY), endPoint: CGPoint(x: 0, y: h)))
            for i in 1..<6 { ctx.fill(Path(CGRect(x: w * Double(i) / 6, y: counterY + slab, width: 1.2, height: h - counterY - slab)), with: .color(.black.opacity(0.08))) }
            ctx.fill(Path(CGRect(x: 0, y: counterY, width: w, height: slab)), with: .linearGradient(Gradient(colors: [PY.woodLight, Color(hex: 0xC98744)]), startPoint: CGPoint(x: 0, y: counterY), endPoint: CGPoint(x: 0, y: counterY + slab)))

            // the wallet with its coins: they never move
            let wal = CGPoint(x: w * 0.2, y: counterY + 2 * u)
            let ww = 104 * u
            ctx.fill(Path(ellipseIn: CGRect(x: wal.x - ww * 0.58, y: wal.y - 5 * u, width: ww * 1.16, height: 10 * u)), with: .color(.black.opacity(0.14)))
            ctx.fill(Path(roundedRect: CGRect(x: wal.x - ww / 2, y: wal.y - 62 * u, width: ww, height: 62 * u), cornerRadius: 14 * u), with: .color(Color(hex: 0xA8402A)))
            let coinSpots: [(Double, Double, Double)] = [(-26, -58, 15), (4, -62, 16), (30, -56, 14), (-10, -50, 15), (16, -48, 14)]
            for (dx, dy, r) in coinSpots { pyCoin(&ctx, CGPoint(x: wal.x + dx * u, y: wal.y + dy * u), r * u) }
            ctx.fill(Path(roundedRect: CGRect(x: wal.x - ww / 2, y: wal.y - 40 * u, width: ww, height: 40 * u), cornerRadius: 12 * u), with: .linearGradient(Gradient(colors: [PY.coral, Color(hex: 0xE5522F)]), startPoint: CGPoint(x: 0, y: wal.y - 40 * u), endPoint: CGPoint(x: 0, y: wal.y)))
            ctx.fill(Path(CGRect(x: wal.x - ww / 2 + 8 * u, y: wal.y - 36 * u, width: ww - 16 * u, height: 2 * u)), with: .color(.white.opacity(0.35)))
            ctx.fill(Path(ellipseIn: CGRect(x: wal.x + ww * 0.3, y: wal.y - 26 * u, width: 12 * u, height: 12 * u)), with: .color(PY.gold))
            let sparkle = 0.5 + 0.5 * sin(t * 2.2)
            pyText(&ctx, "✦", CGPoint(x: wal.x - 14 * u, y: wal.y - 76 * u), size: 12 * u, color: .white, alpha: 0.35 + 0.5 * sparkle)

            // the reader and where the tap pad is
            let rb = CGPoint(x: w * 0.66, y: counterY + 2 * u)
            let k = u * 1.0
            let glow = pyPr(t, 1.7, 1.9) * (1 - pyPr(t, 3.2, 3.6))
            let pad = pyReader(&ctx, base: rb, k: k, glow: glow)
            let top = rb.y - 118 * k

            // the card: from the wallet side, taps the reader, goes back
            let rest = CGPoint(x: w * 0.23, y: counterY - 150 * u + 3 * sin(t * 1.6) * u)
            let tapAt = CGPoint(x: pad.x - 6 * u, y: top - 16 * u)
            let go = pyEio(pyPr(t, 0.7, 1.6)) - pyEio(pyPr(t, 2.5, 3.4))
            let dip = sin(.pi * pyPr(t, 1.55, 1.95)) * 5 * u
            let cp = CGPoint(x: rest.x + (tapAt.x - rest.x) * go, y: rest.y + (tapAt.y - rest.y) * go + dip)
            let ca = -0.17 * (1 - go) - 0.05 * go

            // the beep: rings spreading out of the tap pad
            for i in 0..<3 {
                let r = pyPr(t, 1.7 + 0.28 * Double(i), 2.9 + 0.28 * Double(i))
                Kit.ring(&ctx, CGPoint(x: pad.x, y: pad.y - 2 * u), (14 + 78 * pyEo(r)) * u, PY.orange, alpha: (1 - r) * out, width: 2.2)
            }
            pyCard(&ctx, cp, 92 * u, angle: ca)

            // the message: an envelope flying out of the reader, up and away
            let e = pyPr(t, 2.2, 5.0)
            if e > 0 && e < 1 {
                let p0 = CGPoint(x: pad.x, y: top + 50 * k), p1 = CGPoint(x: pad.x - 14 * u, y: h * 0.30), p2 = CGPoint(x: w + 40 * u, y: h * 0.10)
                func bez(_ q: Double) -> CGPoint {
                    CGPoint(x: (1 - q) * (1 - q) * p0.x + 2 * (1 - q) * q * p1.x + q * q * p2.x, y: (1 - q) * (1 - q) * p0.y + 2 * (1 - q) * q * p1.y + q * q * p2.y)
                }
                let q = pow(e, 1.5)
                for j in 1...7 {
                    let qj = max(0, q - Double(j) * 0.035)
                    let pj = bez(qj)
                    ctx.fill(Path(ellipseIn: CGRect(x: pj.x - 2.4 * u, y: pj.y - 2.4 * u, width: 4.8 * u, height: 4.8 * u)), with: .color(PY.coral.opacity(0.5 * (1 - Double(j) / 8))))
                }
                let sz = 36 * u * (0.55 + 0.45 * pyPop(pyPr(e, 0, 0.2))) * (1 - 0.3 * e)
                pyEnvelope(&ctx, bez(q), sz, angle: -0.35 + 0.5 * e)
            }

            // labels
            let cl = "CARD", rl = "CARD READER", bl = "BEEP", ml = "MESSAGE GOES OUT", sl = "MONEY STAYS PUT"
            Kit.chip(&ctx, cl, CGPoint(x: pyFit(cp.x, cl, 8, w), y: cp.y - 40 * u), color: .white, size: 8, alpha: pyPr(t, 0.2, 0.6) * (1 - pyPr(t, 1.1, 1.4) + pyPr(t, 3.6, 4.0)) * out)
            Kit.chip(&ctx, rl, CGPoint(x: pyFit(rb.x, rl, 8, w), y: counterY + slab + 26 * u), color: .white, size: 8, alpha: pyPr(t, 0.4, 0.8) * out)
            Kit.chip(&ctx, bl, CGPoint(x: pyFit(pad.x + 64 * u, bl, 8, w), y: top + 4 * u), color: PY.goldText, size: 8, alpha: pyPr(t, 1.8, 2.2) * out)
            Kit.chip(&ctx, ml, CGPoint(x: pyFit(w * 0.72, ml, 8, w), y: h * 0.19), color: PY.coralText, size: 8, alpha: pyPr(t, 2.7, 3.1) * out)
            Kit.chip(&ctx, sl, CGPoint(x: pyFit(wal.x, sl, 8, w), y: counterY + slab + 26 * u), color: PY.greenText, size: 8, alpha: pyPr(t, 3.0, 3.4) * out)
        }
    }
}

// MARK: - Card 2: the message hops reader -> shop's bank -> card network -> your bank; the yes comes back

struct PayHops: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 12, still: 6.4, cues: [Cue(0.9, .light), Cue(2.1, .light), Cue(3.2, .light), Cue(4.5, .rigid), Cue(5.2, .success), Cue(8.4, .success)], replayOnTap: true, sky: PY.sky,
                    label: "Four boxes in a chain: a card reader, the shop's bank, a card network, and your bank. A message, an envelope, runs out along one lane from the card reader through the shop's bank and the card network to your bank. Your bank answers yes. A green yes then runs back along the other lane, through the same places, to the card reader.") { ctx, s, t, _ in
            let w = s.width, h = s.height, u = min(w / 360, h / 345)
            let cxL = w * 0.19, cxR = w * 0.81, bw = w * 0.30, bh = 112 * u
            let rowT = h * 0.25, rowB = h * 0.75, d = 13 * u
            let out = 1 - pyPr(t, 11.2, 11.8)

            let outR = PYRoute([CGPoint(x: cxL, y: rowT - d), CGPoint(x: cxR - d, y: rowT - d), CGPoint(x: cxR - d, y: rowB - d), CGPoint(x: cxL, y: rowB - d)])
            let backR = PYRoute([CGPoint(x: cxL, y: rowB + d), CGPoint(x: cxR + d, y: rowB + d), CGPoint(x: cxR + d, y: rowT + d), CGPoint(x: cxL, y: rowT + d)])
            let f = pyPr(t, 0.9, 4.2), g = pyPr(t, 5.3, 8.5)

            // the two lanes: a faint road, then the part already travelled
            for (route, col, prog) in [(outR, PY.coral, f), (backR, PY.green, g)] {
                ctx.stroke(route.full, with: .color(col.opacity(0.22)), style: StrokeStyle(lineWidth: 9 * u, lineCap: .round, lineJoin: .round))
                ctx.stroke(route.full, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 1.6 * u, lineCap: .round, dash: [3 * u, 6 * u]))
                if prog > 0 { ctx.stroke(route.path(prog), with: .color(col), style: StrokeStyle(lineWidth: 5 * u, lineCap: .round, lineJoin: .round)) }
            }
            // the packets (they slip behind the boxes, then come out again)
            if f > 0 && f < 1 { let p = outR.point(f); pyEnvelope(&ctx, p, 30 * u, angle: sin(t * 7) * 0.08) }
            if g > 0 && g < 1 {
                let p = backR.point(g)
                let pill = CGRect(x: p.x - 24 * u, y: p.y - 12 * u, width: 48 * u, height: 24 * u)
                ctx.fill(Path(roundedRect: pill.offsetBy(dx: 0, dy: 2 * u), cornerRadius: 12 * u), with: .color(.black.opacity(0.18)))
                ctx.fill(Path(roundedRect: pill, cornerRadius: 12 * u), with: .color(PY.green))
                pyText(&ctx, "YES", p, size: 13 * u, color: .white)
            }

            // the four boxes
            let yb = (pyBump(f - 1, 0.1) * (1 - pyPr(t, 4.4, 4.9)) + pyBump(g, 0.06)) * pyPr(t, 3.6, 3.9)
            let boxes: [(String, CGPoint, Color, Double, Double)] = [
                ("CARD READER", CGPoint(x: cxL, y: rowT), PY.orange, pyBump(f, 0.07) * (1 - pyPr(t, 1.4, 2.0)) + pyBump(g - 1, 0.06), pyPr(t, 8.4, 8.9) * (1 - pyPr(t, 10.6, 11.4))),
                ("SHOP'S BANK", CGPoint(x: cxR, y: rowT), PY.coral, pyBump(f - outR.at(1), 0.07) + pyBump(g - backR.at(2), 0.07), 0),
                ("CARD NETWORK", CGPoint(x: cxR, y: rowB), PY.purple, pyBump(f - outR.at(2), 0.07) + pyBump(g - backR.at(1), 0.07), 0),
                ("YOUR BANK", CGPoint(x: cxL, y: rowB), PY.teal, yb, pyPr(t, 4.4, 4.9) * (1 - pyPr(t, 10.6, 11.4)))]
            for (i, b) in boxes.enumerated() {
                let pulse = pyCl(b.3), ok = b.4
                let sc = 1 + 0.05 * pulse
                let r = CGRect(x: b.1.x - bw / 2 * sc, y: b.1.y - bh / 2 * sc, width: bw * sc, height: bh * sc)
                ctx.fill(Path(roundedRect: r.offsetBy(dx: 0, dy: 4 * u), cornerRadius: 16 * u), with: .color(.black.opacity(0.14)))
                ctx.fill(Path(roundedRect: r, cornerRadius: 16 * u), with: .color(pyMix(0xFFFBF0, 0xD6F5E0, ok)))
                ctx.stroke(Path(roundedRect: r, cornerRadius: 16 * u), with: .color(ok > 0.5 ? PY.green : b.2), lineWidth: (2.4 + 2 * pulse) * u)
                let ic = CGPoint(x: b.1.x, y: r.minY + 10 * u)
                switch i {
                case 0: pyReader(&ctx, base: CGPoint(x: ic.x, y: ic.y + 62 * u), k: 0.5 * u)
                case 1: pyBank(&ctx, CGRect(x: ic.x - 26 * u, y: ic.y + 2 * u, width: 52 * u, height: 54 * u), tint: PY.coral)
                case 2:
                    let c = CGPoint(x: ic.x, y: ic.y + 30 * u)
                    for j in 0..<6 {
                        let a = Double(j) / 6 * 2 * .pi - .pi / 2
                        let q = CGPoint(x: c.x + 24 * u * cos(a), y: c.y + 24 * u * sin(a))
                        var sp = Path(); sp.move(to: c); sp.addLine(to: q)
                        ctx.stroke(sp, with: .color(PY.purple.opacity(0.7)), lineWidth: 2 * u)
                        ctx.fill(Path(ellipseIn: CGRect(x: q.x - 5 * u, y: q.y - 5 * u, width: 10 * u, height: 10 * u)), with: .color(PY.purple))
                    }
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 10 * u, y: c.y - 10 * u, width: 20 * u, height: 20 * u)), with: .color(PY.gold))
                    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 10 * u, y: c.y - 10 * u, width: 20 * u, height: 20 * u)), with: .color(PY.goldDark), lineWidth: 1.6 * u)
                default: pyBank(&ctx, CGRect(x: ic.x - 26 * u, y: ic.y + 2 * u, width: 52 * u, height: 54 * u), tint: PY.teal)
                }
                let lab = b.0
                Kit.chip(&ctx, lab, CGPoint(x: b.1.x, y: r.maxY - 20 * u), color: .white, size: 8, alpha: pyPr(t, 0.1 + 0.15 * Double(i), 0.5 + 0.15 * Double(i)) * out)
                if ok > 0.5, i == 0 || i == 3 { pyTick(&ctx, CGPoint(x: r.maxX - 4 * u, y: r.minY + 4 * u), 12 * u, k: pyPr(t, i == 3 ? 4.5 : 8.5, i == 3 ? 4.9 : 8.9)) }
            }

            // which lane is which
            let gx = w / 2
            Kit.chip(&ctx, "MESSAGE OUT", CGPoint(x: gx, y: rowT - d - 28 * u), color: PY.coralText, size: 8, alpha: pyPr(t, 0.9, 1.3) * out)
            Kit.chip(&ctx, "ANSWER BACK", CGPoint(x: gx, y: rowT + d + 28 * u), color: PY.greenText, size: 8, alpha: pyPr(t, 5.3, 5.7) * out)
        }
    }
}

// MARK: - Card 3 (hands-on): ten banks joined pair by pair (45 links), then all through one network (10 links)

struct PayNetwork: View {
    let active: Bool
    @State private var tangle = 0.0       // how much of the pair-by-pair web is drawn, 0...1
    @State private var hub = 0.0          // how much of the network is drawn, 0...1
    @State private var touched = false
    @State private var netOn = false
    @State private var t0 = Date()
    @Environment(\.accessibilityReduceMotion) private var reduce

    /// All 45 pairs of the ten banks, in a scrambled order so the web looks tangled as it grows.
    private static let pairs: [(Int, Int)] = {
        var p: [(Int, Int)] = []
        for i in 0..<10 { for j in (i + 1)..<10 { p.append((i, j)) } }
        return p.sorted { ($0.0 * 37 + $0.1 * 53) % 91 < ($1.0 * 37 + $1.1 * 53) % 91 }
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            TimelineView(.animation(paused: !active || reduce)) { tl in
                Canvas { ctx, s in draw(&ctx, s, tl.date.timeIntervalSince(t0)) }
            }
            let net = touched ? netOn : hub > 0.5
            HStack(spacing: 2) {
                seg("45 LINKS", on: !net) { choose(false) }
                seg("WITH A NETWORK", on: net) { choose(true) }
            }
            .padding(3)
            .background(Capsule().fill(Pal.night.opacity(0.6)))
            .padding(.bottom, 10)
        }
        .background(LinearGradient(colors: PY.sky.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
        .task(id: "\(active)-\(touched)-\(netOn)-\(reduce)") {
            guard active else { return }
            if reduce { tangle = (touched && netOn) ? 0 : 1; hub = (touched && netOn) ? 1 : 0; return }
            if !touched {
                t0 = Date()
                while !Task.isCancelled {
                    let t = Date().timeIntervalSince(t0).truncatingRemainder(dividingBy: 13)
                    tangle = pyPr(t, 0.8, 4.8) * (1 - pyPr(t, 6.2, 7.2))
                    hub = pyPr(t, 7.0, 8.8) * (1 - pyPr(t, 12.2, 12.8))
                    try? await Task.sleep(for: .milliseconds(33))
                }
                return
            }
            var last = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                let now = Date(), dt = now.timeIntervalSince(last); last = now
                if netOn {
                    tangle = max(0, tangle - dt / 1.0)
                    if tangle < 0.3 { hub = min(1, hub + dt / 1.4) }
                    if tangle == 0 && hub == 1 { break }
                } else {
                    hub = max(0, hub - dt / 0.6)
                    if hub < 0.4 { tangle = min(1, tangle + dt / 3.2) }
                    if hub == 0 && tangle == 1 { break }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ten banks drawn as dots in a ring. A switch below flips between two ways of linking them. Joined pair by pair, the banks need 45 links, a tangle of lines. With a card network, a hub in the middle, each bank needs just one link to it: 10 links. Untouched, the picture plays both, one after the other.")
    }

    private func seg(_ text: String, on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(T.mono(10)).tracking(0.6)
                .foregroundStyle(on ? Color.white : Pal.signal)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(on ? PY.coral : Color.clear))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    private func choose(_ net: Bool) {
        if touched && netOn == net { return }
        Haptic.fire(.light)
        touched = true
        netOn = net
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ time: Double) {
        let w = s.width, h = s.height, u = min(w / 360, h / 345)
        let c = CGPoint(x: w / 2, y: h * 0.48)
        let R = min(w * 0.36, h * 0.27)
        let dots: [CGPoint] = (0..<10).map { i in
            let a = Double(i) / 10 * 2 * .pi - .pi / 2
            return CGPoint(x: c.x + R * cos(a), y: c.y + R * sin(a))
        }
        let palette: [Color] = [PY.coral, PY.orange, PY.teal, PY.blue, PY.purple]

        // the tangle: every pair of banks, one line each
        let lit = 45 * tangle
        let fade = hub > 0.3 ? 1 - pyPr(hub, 0.3, 0.6) : 1
        for (k, pr) in Self.pairs.enumerated() {
            let p = pyPr(lit, Double(k), Double(k) + 1)
            guard p > 0 else { continue }
            var ln = Path(); ln.move(to: dots[pr.0]); ln.addLine(to: pyLerp(dots[pr.0], dots[pr.1], p))
            ctx.stroke(ln, with: .color(palette[(pr.0 + pr.1) % 5].opacity(0.68 * fade)), style: StrokeStyle(lineWidth: 1.7 * u, lineCap: .round))
        }
        // the network: one line from each bank to the hub
        for i in 0..<10 {
            let p = pyEo(pyPr(hub, 0.06 * Double(i), 0.06 * Double(i) + 0.46))
            guard p > 0 else { continue }
            var sp = Path(); sp.move(to: dots[i]); sp.addLine(to: pyLerp(dots[i], c, p))
            ctx.stroke(sp, with: .color(PY.purple.opacity(0.85)), style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
            let dot = pyLerp(dots[i], c, (time * 0.5 + Double(i) * 0.1).truncatingRemainder(dividingBy: 1))
            ctx.fill(Path(ellipseIn: CGRect(x: dot.x - 2.6 * u, y: dot.y - 2.6 * u, width: 5.2 * u, height: 5.2 * u)), with: .color(.white.opacity(0.9 * pyPr(hub, 0.9, 1))))
        }
        // the hub
        let hs = pyPop(pyPr(hub, 0.2, 0.7))
        if hs > 0.01 {
            let hr = 25 * u * hs
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - hr * 1.5, y: c.y - hr * 1.5, width: hr * 3, height: hr * 3)), with: .radialGradient(Gradient(colors: [PY.purple.opacity(0.3), .clear]), center: c, startRadius: hr * 0.6, endRadius: hr * 1.5))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - hr, y: c.y - hr, width: 2 * hr, height: 2 * hr)), with: .linearGradient(Gradient(colors: [Color(hex: 0x9C82F0), PY.purple]), startPoint: CGPoint(x: c.x, y: c.y - hr), endPoint: CGPoint(x: c.x, y: c.y + hr)))
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - hr, y: c.y - hr, width: 2 * hr, height: 2 * hr)), with: .color(.white.opacity(0.9)), lineWidth: 2 * u)
            for j in 0..<6 {
                let a = Double(j) / 6 * 2 * .pi
                let q = CGPoint(x: c.x + hr * 0.6 * cos(a), y: c.y + hr * 0.6 * sin(a))
                var sp = Path(); sp.move(to: c); sp.addLine(to: q)
                ctx.stroke(sp, with: .color(.white.opacity(0.85)), lineWidth: 1.6 * u)
                ctx.fill(Path(ellipseIn: CGRect(x: q.x - 2.4 * u, y: q.y - 2.4 * u, width: 4.8 * u, height: 4.8 * u)), with: .color(.white))
            }
        }
        // the ten banks
        for (i, p) in dots.enumerated() {
            let joined = pyPr(hub, 0.06 * Double(i) + 0.3, 0.06 * Double(i) + 0.5)
            let r = (13 + 1.8 * joined) * u
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r + 2 * u, width: 2 * r, height: 2 * r)), with: .color(.black.opacity(0.14)))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)), with: .color(PY.teal))
            ctx.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)), with: .color(.white), lineWidth: 2 * u)
            pyBankGlyph(&ctx, p, 6.4 * u, color: .white)
        }

        // labels: the count climbs while lines are drawn, then falls away and climbs to 10
        let n = Int((45 * tangle + 10 * hub).rounded())
        let net = hub > 0.5
        Kit.chip(&ctx, "10 BANKS", CGPoint(x: w / 2, y: h * 0.055), color: .white, size: 9)
        let cnt = net ? "WITH A NETWORK: \(n) LINKS" : "\(n) LINKS"
        Kit.chip(&ctx, cnt, CGPoint(x: w / 2, y: h * 0.12), color: net ? PY.greenText : PY.coralText, size: 11)
        Kit.chip(&ctx, "CARD NETWORK", CGPoint(x: w / 2, y: c.y + 24 * u + 24 * u), color: .white, size: 8, alpha: pyPr(hub, 0.7, 1))
    }
}

// MARK: - Card 4: your bank checks two things, then sets 20 of your 50 aside for the shop

struct PayDecide: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 12, still: 8.0, cues: [Cue(1.8, .light), Cue(3.0, .light), Cue(4.2, .soft), Cue(5.6, .success)], replayOnTap: true, sky: PY.sky,
                    label: "A bank computer receives the message and shows two ticks: the card is real, and there is enough money. Below, your account is drawn as a purse holding 50 coins. Twenty of the coins slide into a box marked for the shop, still inside the purse outline: they are set aside, not gone. Thirty coins stay in the purse, so you can spend 30. The shop is not paid yet.") { ctx, s, t, _ in
            let w = s.width, h = s.height, u = min(w / 360, h / 345)
            let out = 1 - pyPr(t, 11.2, 11.8)

            // the bank computer, and the message arriving at it
            let sl = max(0, h - 345 * u)
            let mon = CGRect(x: w * 0.06, y: 10 * u + sl * 0.1, width: w * 0.40, height: 56 * u)
            ctx.fill(Path(roundedRect: CGRect(x: mon.midX - 7 * u, y: mon.maxY - 2, width: 14 * u, height: 14 * u), cornerRadius: 2), with: .color(PY.plumDark))
            ctx.fill(Path(roundedRect: CGRect(x: mon.midX - 30 * u, y: mon.maxY + 10 * u, width: 60 * u, height: 7 * u), cornerRadius: 3.5 * u), with: .color(PY.plum))
            ctx.fill(Path(roundedRect: mon.offsetBy(dx: 0, dy: 3 * u), cornerRadius: 12 * u), with: .color(.black.opacity(0.14)))
            ctx.fill(Path(roundedRect: mon, cornerRadius: 12 * u), with: .color(PY.plum))
            let scr = mon.insetBy(dx: 7 * u, dy: 7 * u)
            ctx.fill(Path(roundedRect: scr, cornerRadius: 7 * u), with: .color(PY.cream))
            pyBank(&ctx, CGRect(x: scr.midX - 22 * u, y: scr.minY + 6 * u, width: 44 * u, height: scr.height - 12 * u), tint: PY.teal)
            let think = pyPr(t, 0.9, 1.1) * (1 - pyPr(t, 1.8, 2.0))
            for j in 0..<3 {
                let b = 0.5 + 0.5 * sin(t * 8 - Double(j) * 0.9)
                ctx.fill(Path(ellipseIn: CGRect(x: scr.maxX - 30 * u + Double(j) * 9 * u, y: scr.maxY - 12 * u - 2 * u * b, width: 5.5 * u, height: 5.5 * u)), with: .color(PY.plum.opacity(think)))
            }
            let fly = pyPr(t, 0.1, 0.9)
            if fly > 0 && fly < 1 { pyEnvelope(&ctx, CGPoint(x: -20 * u + (mon.midX + 20 * u) * pyEio(fly), y: mon.midY - 20 * u * sin(.pi * fly)), 30 * u * (1 - 0.4 * fly), angle: -0.3 * (1 - fly), alpha: 1 - pyPr(fly, 0.85, 1)) }

            // the two ticks
            let tx = w * 0.54
            for (i, txt) in ["CARD IS REAL", "ENOUGH MONEY"].enumerated() {
                let at = 1.8 + 1.2 * Double(i)
                let ty = mon.minY + (15 + 26 * Double(i)) * u
                ctx.fill(Path(ellipseIn: CGRect(x: tx, y: ty - 11 * u, width: 22 * u, height: 22 * u)), with: .color(.black.opacity(0.1 * pyPr(t, at, at + 0.2))))
                pyTick(&ctx, CGPoint(x: tx + 11 * u, y: ty), 11 * u, k: pyPr(t, at, at + 0.45))
                Kit.chip(&ctx, txt, CGPoint(x: tx + 32 * u, y: ty), anchor: .leading, color: PY.greenText, size: 8, alpha: pyPr(t, at + 0.1, at + 0.5) * out)
            }

            // the purse: your account, 50 coins
            let p = 24 * u, py = 20 * u, gap = 12 * u, bpad = 7 * u
            let purse = CGRect(x: w * 0.05, y: 92 * u + sl * 0.3, width: w * 0.9, height: 28 * u + 8 * u + 5 * py + 10 * u)
            let x0 = purse.minX + (purse.width - (10 * p + gap + 2 * bpad)) / 2
            ctx.fill(Path(roundedRect: purse.offsetBy(dx: 0, dy: 4 * u), cornerRadius: 22 * u), with: .color(.black.opacity(0.14)))
            ctx.fill(Path(roundedRect: purse, cornerRadius: 22 * u), with: .color(PY.cream))
            ctx.drawLayer { l in
                l.clip(to: Path(roundedRect: purse, cornerRadius: 22 * u))
                l.fill(Path(CGRect(x: purse.minX, y: purse.minY, width: purse.width, height: 28 * u)), with: .linearGradient(Gradient(colors: [PY.coral, Color(hex: 0xE5522F)]), startPoint: CGPoint(x: 0, y: purse.minY), endPoint: CGPoint(x: 0, y: purse.minY + 28 * u)))
            }
            ctx.stroke(Path(roundedRect: purse, cornerRadius: 22 * u), with: .color(Color(hex: 0xC8472B)), lineWidth: 3 * u)
            ctx.fill(Path(ellipseIn: CGRect(x: purse.maxX - 32 * u, y: purse.minY + 6 * u, width: 16 * u, height: 16 * u)), with: .color(PY.gold))
            ctx.stroke(Path(ellipseIn: CGRect(x: purse.maxX - 32 * u, y: purse.minY + 6 * u, width: 16 * u, height: 16 * u)), with: .color(PY.goldDark), lineWidth: 1.6 * u)

            // the box for the shop, inside the purse outline
            let boxR = CGRect(x: x0 + 6 * p + gap, y: purse.minY + 28 * u + 4 * u, width: 4 * p + 2 * bpad, height: 5 * py + 10 * u)
            let boxA = pyPr(t, 3.6, 4.0)
            ctx.fill(Path(roundedRect: boxR, cornerRadius: 10 * u), with: .color(PY.coral.opacity(0.14 * boxA + 0.12 * pyPr(t, 4.6, 5.6))))
            ctx.stroke(Path(roundedRect: boxR, cornerRadius: 10 * u), with: .color(PY.coral.opacity(boxA)), style: StrokeStyle(lineWidth: 2.2 * u, dash: [6 * u, 4 * u]))

            // the 50 coins; the last 20 slide into the box
            for r in 0..<5 {
                for cIdx in 0..<10 {
                    var x = x0 + p * Double(cIdx) + p / 2
                    var ring: Color? = nil
                    if cIdx >= 6 {
                        let sl = pyEio(pyPr(t, 4.2 + 0.1 * Double(cIdx - 6), 5.0 + 0.1 * Double(cIdx - 6)))
                        x += (gap + bpad) * sl
                        if sl > 0.9 { ring = PY.coral }
                    }
                    pyCoin(&ctx, CGPoint(x: x, y: boxR.minY + 5 * u + py * Double(r) + py / 2), 9 * u, ring: ring)
                }
            }

            // labels
            Kit.chip(&ctx, "YOUR ACCOUNT: 50", CGPoint(x: purse.minX + 18 * u, y: purse.minY + 14 * u), anchor: .leading, color: .white, size: 8, alpha: pyPr(t, 0.3, 0.7) * out)
            Kit.chip(&ctx, "FOR THE SHOP", CGPoint(x: boxR.midX, y: boxR.minY), color: PY.coralText, size: 8, alpha: boxA * out)
            let sp = "YOU CAN SPEND: 30", sa = "20 SET ASIDE FOR THE SHOP"
            Kit.chip(&ctx, sp, CGPoint(x: pyFit(x0 + 3 * p, sp, 8, w), y: purse.maxY + 22 * u + sl * 0.3), color: PY.greenText, size: 8, alpha: pyPr(t, 5.6, 6.0) * out)
            Kit.chip(&ctx, sa, CGPoint(x: pyFit(boxR.midX, sa, 8, w), y: purse.maxY + 22 * u + sl * 0.3), color: PY.coralText, size: 8, alpha: pyPr(t, 5.8, 6.2) * out)

            // the shop has not been paid yet
            let shop = CGRect(x: w * 0.5 - 104 * u, y: purse.maxY + 40 * u + sl * 0.5, width: 42 * u, height: 38 * u)
            let sh = pyPr(t, 7.0, 7.5)
            pyShop(&ctx, shop, alpha: sh)
            ctx.stroke(Path(ellipseIn: CGRect(x: shop.maxX + 8 * u, y: shop.midY - 9 * u, width: 18 * u, height: 18 * u)), with: .color(PY.coral.opacity(sh)), style: StrokeStyle(lineWidth: 1.8 * u, dash: [3 * u, 3 * u]))
            Kit.chip(&ctx, "SHOP NOT PAID YET", CGPoint(x: shop.maxX + 40 * u, y: shop.midY), anchor: .leading, color: PY.goldText, size: 8, alpha: sh * out)
        }
    }
}

// MARK: - Card 5: the tap is a yes on day 0; payments pile up; one big stack moves bank to bank in 1 to 3 working days

struct PayLater: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 14, still: 10.4, cues: [Cue(0.9, .light), Cue(1.1, .success), Cue(3.3, .soft), Cue(9.7, .success)], replayOnTap: true, sky: PY.sky,
                    label: "A calendar strip of six days. The tap happens on day 0 and gets a yes. Small payments from the day drop as coins and pile up beside your bank. Then one big stack of coins moves from your bank to the shop's bank, arriving 1 to 3 working days later, and the shop is paid. The two weekend squares are greyed out because weekends don't count.") { ctx, s, t, _ in
            let w = s.width, h = s.height, u = min(w / 360, h / 345)
            let out = 1 - pyPr(t, 13.2, 13.8)

            // the calendar: six squares, two of them a weekend
            let mar = 14 * u, gp = 5 * u
            let sqW = (w - 2 * mar - 5 * gp) / 6, sqH = 44 * u
            let top = 48 * u
            func sq(_ i: Int) -> CGRect { CGRect(x: mar + Double(i) * (sqW + gp), y: top, width: sqW, height: sqH) }
            let nums: [Int: String] = [0: "0", 1: "1", 4: "2", 5: "3"]
            for i in 0..<6 {
                let r = sq(i)
                let weekend = i == 2 || i == 3
                ctx.fill(Path(roundedRect: r.offsetBy(dx: 0, dy: 2.5 * u), cornerRadius: 10 * u), with: .color(.black.opacity(0.12)))
                ctx.fill(Path(roundedRect: r, cornerRadius: 10 * u), with: .color(weekend ? Color(hex: 0xCFC6BA) : PY.cream))
                if weekend {
                    ctx.drawLayer { l in
                        l.clip(to: Path(roundedRect: r, cornerRadius: 10 * u))
                        var hatch = Path()
                        var x = r.minX - r.height
                        while x < r.maxX { hatch.move(to: CGPoint(x: x, y: r.maxY)); hatch.addLine(to: CGPoint(x: x + r.height, y: r.minY)); x += 9 * u }
                        l.stroke(hatch, with: .color(.white.opacity(0.55)), lineWidth: 2 * u)
                    }
                } else if let n = nums[i] {
                    pyText(&ctx, n, CGPoint(x: r.midX, y: r.midY), size: 24 * u, color: i == 0 ? PY.coral : PY.ink.opacity(0.78))
                }
                ctx.stroke(Path(roundedRect: r, cornerRadius: 10 * u), with: .color(weekend ? Color(hex: 0x9C9285).opacity(0.7) : PY.orange.opacity(0.7)), lineWidth: 1.8 * u)
            }
            // today moves along the strip
            let cur = pyPr(t, 1.2, 10.0) * 5          // square by square, with a short slide between
            let ci = min(4.0, cur.rounded(.down))
            let curX = sq(0).midX + (sq(5).midX - sq(0).midX) * (ci + pyEio(pyPr(cur - ci, 0.6, 1))) / 5
            let hl = CGRect(x: curX - sqW / 2 - 3 * u, y: top - 3 * u, width: sqW + 6 * u, height: sqH + 6 * u)
            ctx.stroke(Path(roundedRect: hl, cornerRadius: 12 * u), with: .color(PY.gold), lineWidth: 3.4 * u)

            // day 0: the tap and its yes
            let tapA = pyPr(t, 0.3, 0.7)
            Kit.chip(&ctx, "TAP", CGPoint(x: sq(0).minX, y: top - 24 * u), anchor: .leading, color: .white, size: 9, alpha: tapA * out)
            let ys = pyPop(pyPr(t, 1.0, 1.4)) * out
            if ys > 0.01 {
                let yr = CGRect(x: sq(0).minX + 52 * u, y: top - 35 * u, width: 44 * u, height: 22 * u)
                ctx.fill(Path(roundedRect: yr, cornerRadius: 11 * u), with: .color(PY.green))
                pyText(&ctx, "YES", CGPoint(x: yr.midX, y: yr.midY), size: 12 * u, color: .white, alpha: ys)
            }

            // weekend and working-day marks under the strip
            let bot = top + sqH
            let wk = "WEEKENDS DON'T COUNT"
            Kit.chip(&ctx, wk, CGPoint(x: pyFit((sq(2).midX + sq(3).midX) / 2, wk, 8, w), y: bot + 22 * u), color: Color(hex: 0xE9E0D2), size: 8, alpha: pyPr(t, 4.0, 4.4) * out)
            for i in [2, 3] {
                var ld = Path(); ld.move(to: CGPoint(x: sq(i).midX, y: bot + 2 * u)); ld.addLine(to: CGPoint(x: sq(i).midX, y: bot + 12 * u))
                ctx.stroke(ld, with: .color(Color(hex: 0x9C9285).opacity(pyPr(t, 4.0, 4.4))), style: StrokeStyle(lineWidth: 1.6 * u, lineCap: .round))
            }
            let by = bot + 46 * u, ba = pyPr(t, 3.0, 3.5)
            var br = Path()
            br.move(to: CGPoint(x: sq(1).minX, y: by - 8 * u)); br.addLine(to: CGPoint(x: sq(1).minX, y: by)); br.addLine(to: CGPoint(x: sq(5).maxX, y: by)); br.addLine(to: CGPoint(x: sq(5).maxX, y: by - 8 * u))
            ctx.stroke(br, with: .color(PY.coral.opacity(ba)), style: StrokeStyle(lineWidth: 2.4 * u, lineCap: .round, lineJoin: .round))
            Kit.chip(&ctx, "1 TO 3 WORKING DAYS →", CGPoint(x: w / 2, y: by), color: PY.coralText, size: 8, alpha: ba * out)

            // the two banks and the road between their coin piles
            let ground = h - 38 * u, bkW = 86 * u, bkH = 78 * u
            let bl = CGRect(x: w * 0.04 + 6 * u, y: ground - bkH, width: bkW, height: bkH)
            let br2 = CGRect(x: w - w * 0.04 - 6 * u - bkW, y: ground - bkH, width: bkW, height: bkH)
            let pileA = CGPoint(x: bl.maxX + 36 * u, y: ground), pileB = CGPoint(x: br2.minX - 36 * u, y: ground)
            var road = Path(); road.move(to: CGPoint(x: pileA.x + 24 * u, y: ground + 2 * u)); road.addLine(to: CGPoint(x: pileB.x - 24 * u, y: ground + 2 * u))
            ctx.stroke(road, with: .color(PY.wood.opacity(0.55)), style: StrokeStyle(lineWidth: 2 * u, lineCap: .round, dash: [2 * u, 7 * u]))
            pyBank(&ctx, bl, tint: PY.teal)
            pyBank(&ctx, br2, tint: PY.coral)
            Kit.chip(&ctx, "YOUR BANK", CGPoint(x: bl.midX, y: ground + 22 * u), color: .white, size: 8, alpha: pyPr(t, 0.2, 0.6) * out)
            Kit.chip(&ctx, "SHOP'S BANK", CGPoint(x: pyFit(br2.midX, "SHOP'S BANK", 8, w), y: ground + 22 * u), color: .white, size: 8, alpha: pyPr(t, 0.2, 0.6) * out)

            // small payments drop onto a pile beside your bank, then the pile becomes one big stack and travels
            let rw = 20 * u
            let leave = pyEio(pyPr(t, 3.5, 9.6))
            var landed = 0
            for i in 0..<8 {
                let st = 0.9 + 0.22 * Double(i), k = pyPr(t, st, st + 0.5)
                if k >= 1 { landed += 1; continue }
                guard k > 0 else { continue }
                let y0 = by + 24 * u, y1 = ground - Double(landed) * rw * 0.32 - rw * 0.4
                pyCoin(&ctx, CGPoint(x: pileA.x + Double(i % 3 - 1) * 2 * u, y: y0 + (y1 - y0) * k * k), 11 * u, alpha: pyPr(k, 0, 0.2))
            }
            let boost = pyEio(pyPr(t, 2.9, 3.4))
            let discs = landed + Int((4 * boost).rounded())
            let stackP = CGPoint(x: pileA.x + (pileB.x - pileA.x) * leave, y: ground - sin(.pi * leave) * 14 * u)
            if boost > 0 { pyStack(&ctx, CGPoint(x: stackP.x, y: stackP.y + 0), min(discs, 12), rw * (1 + 0.18 * boost)) }
            else { pyStack(&ctx, stackP, discs, rw) }
            let paid = pyPr(t, 9.6, 10.0)
            Kit.chip(&ctx, "PAYMENTS ADDED UP", CGPoint(x: pyFit(pileA.x + 40 * u, "PAYMENTS ADDED UP", 8, w), y: ground - 128 * u), color: PY.goldText, size: 8, alpha: pyPr(t, 1.6, 2.0) * (1 - pyPr(t, 4.4, 4.8)) * out)
            pyTick(&ctx, CGPoint(x: br2.maxX - 2 * u, y: br2.minY + 2 * u), 13 * u, k: paid)
            Kit.chip(&ctx, "SHOP PAID", CGPoint(x: pyFit(br2.midX, "SHOP PAID", 8, w), y: br2.minY - 18 * u), color: PY.greenText, size: 8, alpha: paid * out)
        }
    }
}
