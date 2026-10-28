import SwiftUI

// "How do the gears on your bike work?" topic: five flat Canvas scenes. Second build, 2026-10-26 (copy rewritten: numbered gears, no spanner, no car).
// Warm, cheerful colours: a steep hill, a bike side-on, teal rings for big ones and orange rings for small ones.
// Nothing is to scale: the hill is steeper than most, the bike's rings are bigger than real ones, the stack has 7 rings of simple sizes
// (30, 25, 21, 17, 14, 12 and 10 teeth) and the rear derailleur is a simple arm. The accessibility label of every card says so.
// Cards 2, 3 and 5 are hands-on (one lever, one toggle, one picker) and play a silent demo until they are touched.
// Gear 1 = biggest back ring (easiest: light push, many pedal turns). Gear 7 = smallest back ring (hardest: hard push, few turns, fastest).

private func bkCl(_ x: Double) -> Double { min(1, max(0, x)) }
private func bkPr(_ t: Double, _ a: Double, _ b: Double) -> Double { bkCl((t - a) / (b - a)) }
private func bkEio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
private func bkEo(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
private func bkSmooth(_ x: Double) -> Double { let k = bkCl(x); return k * k * (3 - 2 * k) }
private func bkLerp(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }
/// x folded into -pitch/2 ... pitch/2.
private func bkWrap(_ x: Double, _ pitch: Double) -> Double { x - pitch * (x / pitch).rounded() }

/// Blend between two hex colours.
private func bkMix(_ a: UInt32, _ b: UInt32, _ k: Double) -> Color {
    func ch(_ v: UInt32, _ shift: UInt32) -> Double { Double((v >> shift) & 0xFF) }
    let k = bkCl(k)
    return Color(red: (ch(a, 16) + (ch(b, 16) - ch(a, 16)) * k) / 255,
                 green: (ch(a, 8) + (ch(b, 8) - ch(a, 8)) * k) / 255,
                 blue: (ch(a, 0) + (ch(b, 0) - ch(a, 0)) * k) / 255)
}

private enum BK {
    static let skyOut: [UInt32] = [0xBFE6FF, 0xDDF2FF, 0xFFF1CC]
    static let coral = Color(hex: 0xFF6B4A), orange = Color(hex: 0xFF9A3C), orangeDark = Color(hex: 0xD9701A)
    static let gold = Color(hex: 0xFFD84A), goldDark = Color(hex: 0xD98E12)
    static let teal = Color(hex: 0x2BB5A6), tealDark = Color(hex: 0x1C8A7E), blue = Color(hex: 0x3F7DDB), green = Color(hex: 0x2FB567)
    static let cream = Color(hex: 0xFFFBF0), ink = Color(hex: 0x3A2A1E), rim = Color(hex: 0xF2E8D6)
    static let grass = Color(hex: 0x6FBE6A), grassDark = Color(hex: 0x4A9B55), soil = Color(hex: 0xB9733A), road = Color(hex: 0x8A7A68)
    static let shirt = Color(hex: 0x3F7DDB), trousers = Color(hex: 0x4A5A8A)
    static let steel = Color(hex: 0x9FB0C4), steelDark = Color(hex: 0x4D6078)
    static let coralText = Color(hex: 0xFFAE98), greenText = Color(hex: 0x8EEBB0), goldText = Color(hex: 0xFFE08A), tealText = Color(hex: 0x8FE6DC)
    /// Teeth on the 7 back rings, gear 1 (biggest) to gear 7 (smallest). The pedal ring has 30 teeth.
    static let teeth = [30, 25, 21, 17, 14, 12, 10]
    /// The three colours of the counted links (10 links each).
    static let group = [Color(hex: 0x3F7DDB), Color(hex: 0x2FB567), Color(hex: 0xFF6B4A)]
}

/// Keep a centred chip inside a width.
private func bkFit(_ x: Double, _ text: String, _ size: Double, _ w: Double) -> Double {
    let half = (Double(text.count) * (size * 0.6 + 0.9) + 16) / 2
    return min(max(x, half + 4), w - half - 4)
}

/// An arc as a sampled path (angles in radians, y down).
private func bkArc(_ c: CGPoint, _ r: Double, _ a0: Double, _ a1: Double, steps: Int = 28) -> Path {
    var p = Path()
    for i in 0...steps {
        let a = a0 + (a1 - a0) * Double(i) / Double(steps)
        let q = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
        if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
    }
    return p
}

private func bkDot(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, _ color: Color) {
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(color))
}

private func bkLine(_ ctx: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ color: Color, _ width: Double, dash: [CGFloat] = []) {
    var p = Path(); p.move(to: a); p.addLine(to: b)
    ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
}

private extension View {
    /// The panel every hands-on picture sits in: sky, rounded corner, hairline.
    func bkPanel(_ sky: [UInt32]) -> some View {
        self.background(LinearGradient(colors: sky.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
    }
}

/// One option of a small picker that sits at the bottom of a hands-on picture.
private struct BKSegButton: View {
    let text: String
    let on: Bool
    var pad: Double = 16
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(T.mono(10)).tracking(0.6)
                .foregroundStyle(on ? Color.white : Pal.signal)
                .padding(.horizontal, pad).padding(.vertical, 8)
                .background(Capsule().fill(on ? BK.coral : Color.clear))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }
}

// MARK: - A closed loop around circles (the chain): straight runs and arcs, and a way to walk along it

private struct BKCircle { var c: CGPoint; var r: Double; var cw: Bool }

private struct BKLoop {
    enum Seg { case line(CGPoint, CGPoint), arc(CGPoint, Double, Double, Double) }   // arc: centre, radius, start angle, signed sweep
    private(set) var segs: [Seg] = []
    private(set) var ends: [Double] = []
    /// For every circle: where along the loop the chain arrives on it, and at which angle.
    private(set) var arrive: [(q: Double, a: Double)] = []
    var length: Double { ends.last ?? 1 }

    /// The straight run from circle a to circle b. A circle with `cw` is travelled clockwise on screen, otherwise anticlockwise.
    private static func tangent(_ a: BKCircle, _ b: BKCircle) -> (CGPoint, CGPoint) {
        let ra = a.cw ? a.r : -a.r, rb = b.cw ? b.r : -b.r
        let dx = b.c.x - a.c.x, dy = b.c.y - a.c.y, d = max(0.001, hypot(dx, dy)), phi = atan2(dy, dx)
        let k = acos(max(-1, min(1, (ra - rb) / d)))
        var best = (a.c, b.c), score = -Double.infinity
        for sgn in [-1.0, 1.0] {
            let al = phi + sgn * k
            let n = CGPoint(x: cos(al), y: sin(al)), u = CGPoint(x: -sin(al), y: cos(al))
            let pa = CGPoint(x: a.c.x + ra * n.x, y: a.c.y + ra * n.y), pb = CGPoint(x: b.c.x + rb * n.x, y: b.c.y + rb * n.y)
            let sc = (pb.x - pa.x) * u.x + (pb.y - pa.y) * u.y
            if sc > score { score = sc; best = (pa, pb) }
        }
        return best
    }

    init(_ cs: [BKCircle]) {
        let n = cs.count
        var leave = [CGPoint](repeating: .zero, count: n), arr = [CGPoint](repeating: .zero, count: n)
        for i in 0..<n {
            let j = (i + 1) % n
            let (p, q) = Self.tangent(cs[i], cs[j])
            leave[i] = p; arr[j] = q
        }
        var q = 0.0
        for i in 0..<n {
            let c = cs[i]
            let a0 = atan2(arr[i].y - c.c.y, arr[i].x - c.c.x), a1 = atan2(leave[i].y - c.c.y, leave[i].x - c.c.x)
            var sw = c.cw ? a1 - a0 : a0 - a1
            sw = sw.truncatingRemainder(dividingBy: 2 * .pi)
            if sw < 0 { sw += 2 * .pi }
            if sw > 2 * .pi - 0.01 { sw = 0 }
            arrive.append((q, a0))
            segs.append(.arc(c.c, c.r, a0, c.cw ? sw : -sw)); q += c.r * sw; ends.append(q)
            let nxt = arr[(i + 1) % n]
            segs.append(.line(leave[i], nxt)); q += hypot(nxt.x - leave[i].x, nxt.y - leave[i].y); ends.append(q)
        }
    }

    /// The point at distance q along the loop, and the direction of travel there.
    func at(_ q0: Double) -> (p: CGPoint, a: Double) {
        let total = length
        var q = q0.truncatingRemainder(dividingBy: total)
        if q < 0 { q += total }
        var lo = 0.0
        for i in 0..<segs.count {
            let e = ends[i]
            if q <= e || i == segs.count - 1 {
                let f = e - lo > 1e-9 ? bkCl((q - lo) / (e - lo)) : 0
                switch segs[i] {
                case .line(let a, let b):
                    return (CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f), atan2(b.y - a.y, b.x - a.x))
                case .arc(let c, let r, let a0, let sw):
                    let ang = a0 + sw * f
                    return (CGPoint(x: c.x + r * cos(ang), y: c.y + r * sin(ang)), ang + (sw >= 0 ? .pi / 2 : -.pi / 2))
                }
            }
            lo = e
        }
        return (.zero, 0)
    }

    func path() -> Path {
        var p = Path()
        var first = true
        for seg in segs {
            switch seg {
            case .line(let a, let b):
                if first { p.move(to: a); first = false }
                p.addLine(to: b)
            case .arc(let c, let r, let a0, let sw):
                let steps = max(2, Int(abs(sw) / 0.1) + 1)
                for k in 0...steps {
                    let ang = a0 + sw * Double(k) / Double(steps)
                    let q = CGPoint(x: c.x + r * cos(ang), y: c.y + r * sin(ang))
                    if first { p.move(to: q); first = false } else { p.addLine(to: q) }
                }
            }
        }
        p.closeSubpath()
        return p
    }
}

/// Angle of "tooth 0" so that the teeth of a ring sit between the pins of the chain. The pins are at i * pitch + s along the loop.
private func bkAlign(_ loop: BKLoop, _ idx: Int, r: Double, pitch: Double, s: Double) -> Double {
    let (qa, a0) = loop.arrive[idx]
    var d = (s - qa).truncatingRemainder(dividingBy: pitch)
    if d < 0 { d += pitch }
    return a0 + (d + pitch / 2) / r
}

/// The chain: a dark band with `n` links on it, sliding along by `offset`. `tint` may colour a link.
private func bkLinks(_ ctx: inout GraphicsContext, _ loop: BKLoop, offset: Double, pitch p: Double, count n: Int, thick: Double, tint: ((Int) -> Color?)? = nil) {
    ctx.stroke(loop.path(), with: .color(BK.ink.opacity(0.92)), style: StrokeStyle(lineWidth: thick + 2.4, lineCap: .round, lineJoin: .round))
    for i in 0..<n {
        let (pt, a) = loop.at(offset + Double(i) * p)
        var l = ctx
        l.translateBy(x: pt.x, y: pt.y); l.rotate(by: .radians(a))
        let col = tint?(i) ?? (i % 2 == 0 ? Color(hex: 0xDCD4C6) : Color(hex: 0xB5AC9B))
        l.fill(Path(roundedRect: CGRect(x: -p * 0.46, y: -thick / 2, width: p * 0.92, height: thick), cornerRadius: thick * 0.38), with: .color(col))
        bkDot(&l, CGPoint(x: p / 2, y: 0), thick * 0.2, BK.ink.opacity(0.75))
    }
}

// MARK: - Rings with real teeth

/// The points of one tooth: a trapezoid standing on the root circle, centred on angle `a`.
private func bkTooth(_ c: CGPoint, r: Double, m: Double, n: Int, a: Double) -> [CGPoint] {
    let tip = r + 0.5 * m, root = r - 0.6 * m, p = 2 * Double.pi / Double(n)
    return [(root, a - 0.30 * p), (tip, a - 0.15 * p), (tip, a + 0.15 * p), (root, a + 0.30 * p)].map {
        CGPoint(x: c.x + $0.0 * cos($0.1), y: c.y + $0.0 * sin($0.1))
    }
}

private func bkGearPath(_ c: CGPoint, teeth n: Int, r: Double, angle: Double) -> Path {
    let m = 2 * r / Double(n)
    var path = Path()
    for i in 0..<n {
        for (j, q) in bkTooth(c, r: r, m: m, n: n, a: angle + Double(i) * 2 * Double.pi / Double(n)).enumerated() {
            if i == 0 && j == 0 { path.move(to: q) } else { path.addLine(to: q) }
        }
    }
    path.closeSubpath()
    return path
}

/// The body of a ring: its disc and teeth. `r` is the radius at the middle of the teeth (where the chain runs).
/// `mark`: tooth 0 and a hand from the middle are gold, so every turn can be counted. `glow` 0...1 lights the edge gold.
private func bkRingBody(_ ctx: inout GraphicsContext, _ c: CGPoint, teeth n: Int, r: Double, angle: Double, body: Color, dark: Color, glow: Double = 0, mark: Bool = false, alpha: Double = 1) {
    guard alpha > 0.01, r > 1 else { return }
    var l = ctx; l.opacity = alpha
    let m = 2 * r / Double(n), root = r - 0.6 * m
    let path = bkGearPath(c, teeth: n, r: r, angle: angle)
    l.fill(path.offsetBy(dx: 0, dy: 2.5), with: .color(.black.opacity(0.16)))
    l.fill(path, with: .color(body))
    l.stroke(path, with: .color(glow > 0.01 ? BK.goldDark : dark), style: StrokeStyle(lineWidth: max(1.2, m * 0.2) + 1.8 * glow, lineJoin: .round))
    if glow > 0.01 { l.stroke(path, with: .color(BK.gold.opacity(glow)), style: StrokeStyle(lineWidth: max(1, m * 0.12) + 1.2 * glow, lineJoin: .round)) }
    l.stroke(Path(ellipseIn: CGRect(x: c.x - root * 0.84, y: c.y - root * 0.84, width: root * 1.68, height: root * 1.68)), with: .color(.white.opacity(0.35)), lineWidth: max(1, m * 0.2))
    if r > 28 {
        for i in 0..<5 {
            let a = angle + Double(i) / 5 * 2 * .pi + .pi / 5
            bkDot(&l, CGPoint(x: c.x + root * 0.56 * cos(a), y: c.y + root * 0.56 * sin(a)), r * 0.12, dark.opacity(0.4))
        }
    }
    let hr = max(r * 0.24, 4.5)
    if mark {
        var hand = Path()
        hand.move(to: CGPoint(x: c.x + hr * 0.5 * cos(angle), y: c.y + hr * 0.5 * sin(angle)))
        hand.addLine(to: CGPoint(x: c.x + root * 0.78 * cos(angle), y: c.y + root * 0.78 * sin(angle)))
        l.stroke(hand, with: .color(BK.gold), style: StrokeStyle(lineWidth: max(2, m * 0.5), lineCap: .round))
    }
    bkDot(&l, c, hr, dark)
    bkDot(&l, c, hr * 0.55, body)
}

/// The teeth only, drawn over the chain so the links show between them.
private func bkTeethCaps(_ ctx: inout GraphicsContext, _ c: CGPoint, teeth n: Int, r: Double, angle: Double, body: Color, dark: Color, mark: Bool = false, alpha: Double = 1) {
    guard alpha > 0.01, r > 1 else { return }
    var l = ctx; l.opacity = alpha
    let m = 2 * r / Double(n)
    var all = Path()
    for i in 0..<n {
        let tp = bkTooth(c, r: r, m: m, n: n, a: angle + Double(i) * 2 * Double.pi / Double(n))
        all.move(to: tp[0]); for q in tp.dropFirst() { all.addLine(to: q) }; all.closeSubpath()
    }
    l.fill(all, with: .color(body))
    l.stroke(all, with: .color(dark), style: StrokeStyle(lineWidth: max(1.1, m * 0.18), lineJoin: .round))
    if mark {
        let tp = bkTooth(c, r: r, m: m, n: n, a: angle)
        var tooth = Path(); tooth.move(to: tp[0]); for q in tp.dropFirst() { tooth.addLine(to: q) }; tooth.closeSubpath()
        l.fill(tooth, with: .color(BK.gold))
        l.stroke(tooth, with: .color(BK.goldDark), style: StrokeStyle(lineWidth: max(1, m * 0.16), lineJoin: .round))
    }
}

/// A wheel: tyre, rim and spokes. One spoke is coral, so a turn can be seen.
private func bkWheel(_ ctx: inout GraphicsContext, _ c: CGPoint, _ R: Double, rot: Double) {
    bkDot(&ctx, c, R * 0.9, .white.opacity(0.28))
    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - R * 0.94, y: c.y - R * 0.94, width: R * 1.88, height: R * 1.88)), with: .color(BK.ink), lineWidth: R * 0.13)
    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - R * 0.84, y: c.y - R * 0.84, width: R * 1.68, height: R * 1.68)), with: .color(BK.rim), lineWidth: max(1, R * 0.04))
    for i in 0..<8 {
        let a = rot + Double(i) * .pi / 4
        var sp = Path(); sp.move(to: c); sp.addLine(to: CGPoint(x: c.x + R * 0.84 * cos(a), y: c.y + R * 0.84 * sin(a)))
        ctx.stroke(sp, with: .color(i == 0 ? BK.coral : BK.rim.opacity(0.85)), style: StrokeStyle(lineWidth: max(0.8, R * (i == 0 ? 0.05 : 0.025)), lineCap: .round))
    }
    bkDot(&ctx, c, R * 0.1, BK.ink)
}

// MARK: - The bike side-on, and the rider (cards 1, 4, 5)

/// Where the parts of the bike sit, in wheel radii: x forward, y down, ground at y = 0, back wheel's bottom at x = 0.
private enum BKB {
    static let rh = CGPoint(x: 0, y: -1), fh = CGPoint(x: 3, y: -1), bb = CGPoint(x: 1.2, y: -0.8)
    static let st = CGPoint(x: 0.95, y: -1.95), htT = CGPoint(x: 2.5, y: -2.0), htB = CGPoint(x: 2.42, y: -1.72)
}

/// A bike seen from the side: two wheels, a frame, a saddle, handlebars and the pedal cranks. Drawn with its origin on the ground under the back wheel.
private func bkBike(_ ctx: inout GraphicsContext, R: Double, rot: Double, crank: Double, frame: Color) {
    func P(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * R, y: p.y * R) }
    func line(_ pts: [CGPoint], _ wd: Double, _ color: Color) {
        var p = Path(); p.move(to: P(pts[0])); for q in pts.dropFirst() { p.addLine(to: P(q)) }
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: wd, lineCap: .round, lineJoin: .round))
    }
    bkWheel(&ctx, P(BKB.rh), R, rot: rot)
    bkWheel(&ctx, P(BKB.fh), R, rot: rot)
    let tubes: [[CGPoint]] = [[BKB.rh, BKB.bb, BKB.st, BKB.rh], [BKB.st, BKB.htT, BKB.htB, BKB.bb], [BKB.htT, BKB.htB, BKB.fh]]
    for t in tubes { line(t, R * 0.15, BK.ink) }
    for t in tubes { line(t, R * 0.095, frame) }
    line([CGPoint(x: 0.62, y: -2.2), CGPoint(x: 1.2, y: -2.2)], R * 0.15, BK.ink)
    line([BKB.st, CGPoint(x: 0.9, y: -2.15)], R * 0.07, BK.ink)
    line([BKB.htT, CGPoint(x: 2.46, y: -2.34), CGPoint(x: 2.76, y: -2.28), CGPoint(x: 2.84, y: -2.1)], R * 0.07, BK.ink)
    let bb = P(BKB.bb)
    bkDot(&ctx, bb, R * 0.09, BK.ink)
    for k in 0..<2 {
        let a = crank + Double(k) * .pi
        let e = CGPoint(x: bb.x + R * 0.5 * cos(a), y: bb.y + R * 0.5 * sin(a))
        var arm = Path(); arm.move(to: bb); arm.addLine(to: e)
        ctx.stroke(arm, with: .color(BK.ink), style: StrokeStyle(lineWidth: R * 0.09, lineCap: .round))
        ctx.fill(Path(roundedRect: CGRect(x: e.x - R * 0.13, y: e.y - R * 0.04, width: R * 0.26, height: R * 0.08), cornerRadius: R * 0.03), with: .color(BK.ink))
    }
}

/// The rider: part 0 is the far leg (drawn behind the bike), part 1 is the near leg, body, arm, hand and head with two eyes.
/// `effort` 0...1: 1 is red-faced and straining.
private func bkRider(_ ctx: inout GraphicsContext, R: Double, crank: Double, effort: Double, t: Double, part: Int) {
    func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * R, y: y * R) }
    let bb = BKB.bb
    func foot(_ a: Double) -> CGPoint { P(bb.x + 0.5 * cos(a) + 0.12, bb.y + 0.5 * sin(a) - 0.05) }
    let hip = P(0.72, -2.3)
    func leg(_ f: CGPoint, _ color: Color) {
        let d = min(max(hypot(f.x - hip.x, f.y - hip.y), 0.3 * R), 2.2 * R - 0.02 * R)
        let dir = CGPoint(x: (f.x - hip.x) / max(0.001, hypot(f.x - hip.x, f.y - hip.y)), y: (f.y - hip.y) / max(0.001, hypot(f.x - hip.x, f.y - hip.y)))
        let along = d / 2, hgt = sqrt(max(0, pow(1.1 * R, 2) - along * along))
        let k1 = CGPoint(x: hip.x + dir.x * along - dir.y * hgt, y: hip.y + dir.y * along + dir.x * hgt)
        let k2 = CGPoint(x: hip.x + dir.x * along + dir.y * hgt, y: hip.y + dir.y * along - dir.x * hgt)
        let knee = k1.x > k2.x ? k1 : k2
        var p = Path(); p.move(to: hip); p.addLine(to: knee); p.addLine(to: f)
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: R * 0.32, lineCap: .round, lineJoin: .round))
        ctx.fill(Path(ellipseIn: CGRect(x: f.x - R * 0.05, y: f.y - R * 0.12, width: R * 0.4, height: R * 0.24)), with: .color(BK.ink))
    }
    if part == 0 { leg(foot(crank + .pi), BK.trousers.opacity(0.7)); return }
    leg(foot(crank), BK.trousers)
    // body, arm, hand, head
    let bob = effort * 0.07 * sin(crank * 2)
    let shoulder = P(1.62, -3.2 + bob), hand = P(2.62, -2.36), hc = P(1.98, -3.72 + bob)
    var torso = Path(); torso.move(to: hip); torso.addLine(to: shoulder)
    ctx.stroke(torso, with: .color(BK.shirt), style: StrokeStyle(lineWidth: R * 0.68, lineCap: .round))
    var arm = Path(); arm.move(to: shoulder); arm.addQuadCurve(to: hand, control: P(2.25, -2.95))
    ctx.stroke(arm, with: .color(BK.shirt), style: StrokeStyle(lineWidth: R * 0.26, lineCap: .round))
    bkDot(&ctx, hand, R * 0.15, bkMix(0xF4B48C, 0xE0402E, effort))
    let hr = R * 0.52
    bkDot(&ctx, hc, hr, bkMix(0xF4B48C, 0xE0402E, effort))
    // helmet
    var helmet = bkArc(hc, hr * 1.06, 0.92 * .pi, 2.08 * .pi, steps: 16); helmet.closeSubpath()
    ctx.fill(helmet, with: .color(BK.gold))
    ctx.stroke(helmet, with: .color(BK.goldDark), lineWidth: max(1, R * 0.05))
    // face: two eyes and a mouth, looking forward
    let eyes = [CGPoint(x: hc.x + hr * 0.18, y: hc.y - hr * 0.12), CGPoint(x: hc.x + hr * 0.64, y: hc.y - hr * 0.12)]
    for e in eyes {
        if effort > 0.5 {
            var sq = Path()
            sq.move(to: CGPoint(x: e.x - hr * 0.14, y: e.y - hr * 0.13)); sq.addLine(to: CGPoint(x: e.x + hr * 0.12, y: e.y)); sq.addLine(to: CGPoint(x: e.x - hr * 0.14, y: e.y + hr * 0.13))
            ctx.stroke(sq, with: .color(BK.ink), style: StrokeStyle(lineWidth: max(1.1, hr * 0.1), lineCap: .round, lineJoin: .round))
        } else {
            bkDot(&ctx, e, hr * 0.15, .white)
            bkDot(&ctx, CGPoint(x: e.x + hr * 0.04, y: e.y), hr * 0.085, BK.ink)
        }
    }
    var mouth = Path()
    if effort > 0.5 {
        mouth.move(to: CGPoint(x: hc.x + hr * 0.2, y: hc.y + hr * 0.5)); mouth.addLine(to: CGPoint(x: hc.x + hr * 0.62, y: hc.y + hr * 0.5))
        ctx.fill(Path(roundedRect: CGRect(x: hc.x + hr * 0.2, y: hc.y + hr * 0.38, width: hr * 0.42, height: hr * 0.22), cornerRadius: hr * 0.05), with: .color(.white))
    } else {
        mouth.move(to: CGPoint(x: hc.x + hr * 0.15, y: hc.y + hr * 0.38)); mouth.addQuadCurve(to: CGPoint(x: hc.x + hr * 0.7, y: hc.y + hr * 0.36), control: CGPoint(x: hc.x + hr * 0.45, y: hc.y + hr * 0.78))
    }
    ctx.stroke(mouth, with: .color(BK.ink), style: StrokeStyle(lineWidth: max(1.1, hr * 0.1), lineCap: .round))
    // sweat when straining
    if effort > 0.5 {
        for i in 0..<3 {
            let k = (t * 0.9 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            let p = CGPoint(x: hc.x - hr * (0.7 + 0.5 * Double(i)) - k * R * 0.5, y: hc.y - hr * (0.2 + 0.3 * Double(i)) + k * R * 0.9)
            bkDot(&ctx, p, R * 0.1, Color(hex: 0x7CC4FA).opacity(1 - k))
        }
    }
}

/// A gauge: a track that goes green, then gold, then coral, filled up to `level`.
private func bkGauge(_ ctx: inout GraphicsContext, _ r: CGRect, level: Double, alpha: Double = 1) {
    guard alpha > 0.01 else { return }
    var c = ctx; c.opacity = alpha
    let rr = r.height / 2
    c.fill(Path(roundedRect: r.offsetBy(dx: 0, dy: 2), cornerRadius: rr), with: .color(.black.opacity(0.14)))
    c.fill(Path(roundedRect: r, cornerRadius: rr), with: .color(BK.cream))
    c.drawLayer { l in
        l.clip(to: Path(roundedRect: r, cornerRadius: rr))
        l.fill(Path(CGRect(x: r.minX, y: r.minY, width: r.width * level, height: r.height)),
               with: .linearGradient(Gradient(colors: [BK.green, BK.gold, BK.coral]), startPoint: CGPoint(x: r.minX, y: 0), endPoint: CGPoint(x: r.maxX, y: 0)))
    }
    c.stroke(Path(roundedRect: r, cornerRadius: rr), with: .color(BK.ink.opacity(0.4)), lineWidth: 1.6)
    let k = CGPoint(x: r.minX + rr + (r.width - 2 * rr) * level, y: r.midY)
    bkDot(&c, k, rr + 2, .white)
    c.stroke(Path(ellipseIn: CGRect(x: k.x - rr - 2, y: k.y - rr - 2, width: 2 * rr + 4, height: 2 * rr + 4)), with: .color(BK.ink.opacity(0.5)), lineWidth: 1.6)
}

/// A small upright gauge, filled from the bottom up to `level`.
private func bkVGauge(_ ctx: inout GraphicsContext, _ r: CGRect, level: Double) {
    let rr = r.width / 2
    ctx.fill(Path(roundedRect: r, cornerRadius: rr), with: .color(BK.cream.opacity(0.92)))
    ctx.drawLayer { l in
        l.clip(to: Path(roundedRect: r, cornerRadius: rr))
        let hgt = r.height * level
        l.fill(Path(CGRect(x: r.minX, y: r.maxY - hgt, width: r.width, height: hgt)),
               with: .linearGradient(Gradient(colors: [BK.green, BK.gold, BK.coral]), startPoint: CGPoint(x: 0, y: r.maxY), endPoint: CGPoint(x: 0, y: r.minY)))
    }
    ctx.stroke(Path(roundedRect: r, cornerRadius: rr), with: .color(BK.ink.opacity(0.45)), lineWidth: 1.2)
}

// MARK: - Card 1: the same steep hill twice. Gear 7 crawls with a hard push, gear 1 climbs with a light push

struct BikeHill: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 12, still: 8.5, cues: [Cue(1.2, .rigid), Cue(3.4, .rigid), Cue(5.6, .rigid), Cue(8.0, .success)], replayOnTap: true, sky: BK.skyOut,
                    label: "The same steep hill drawn twice, side by side, and the hill is drawn steeper than most. On the left, a rider is in gear 7. They push hard, with a red face, a gritted mouth and sweat, and the bike barely creeps up the hill. A gauge below shows how hard they push: nearly full. On the right, the same rider is in gear 1. They push lightly with a smile, and the bike keeps climbing. Their gauge is only a quarter full.") { ctx, s, t, _ in
            let w = s.width, h = s.height, cw = w / 2
            let out = 1 - bkPr(t, 11.2, 11.8)
            for (i, hard) in [true, false].enumerated() {
                let r = CGRect(x: cw * Double(i), y: 0, width: cw, height: h)
                ctx.drawLayer { l in
                    l.clip(to: Path(r))
                    l.translateBy(x: r.minX, y: 0)
                    bkHillColumn(&l, CGSize(width: cw, height: h), t: t, hard: hard, out: out)
                }
            }
            // the dashed seam between the two hills, and what they share
            var seam = Path(); seam.move(to: CGPoint(x: cw, y: 40)); seam.addLine(to: CGPoint(x: cw, y: h - 96))
            ctx.stroke(seam, with: .color(BK.ink.opacity(0.28)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [2, 6]))
            Kit.chip(&ctx, "SAME HILL", CGPoint(x: cw, y: 20), color: BK.goldText, size: 10, alpha: bkPr(t, 0.1, 0.5) * out)
        }
    }
}

private func bkHillColumn(_ ctx: inout GraphicsContext, _ s: CGSize, t: Double, hard: Bool, out: Double) {
    let cw = s.width, h = s.height
    let slope = 0.5, ang = atan(slope)
    let base = h - 90                       // bottom of the hill block
    let yL = base - 16
    func line(_ x: Double) -> Double { yL - slope * x }
    let R = min(25, cw * 0.135)

    // a cloud or two, drifting
    for (i, cx) in [0.25, 0.8].enumerated() {
        let x = (cw * cx + t * (3 + Double(i))).truncatingRemainder(dividingBy: cw + 80) - 40
        let y = 84 + 26 * Double(i)
        for (dx, dy, rr) in [(-14.0, 2.0, 11.0), (0.0, -4.0, 14.0), (15.0, 2.0, 10.0)] { bkDot(&ctx, CGPoint(x: x + dx, y: y + dy), rr, .white.opacity(0.85)) }
    }

    // the hill
    var hill = Path()
    hill.move(to: CGPoint(x: 0, y: line(0))); hill.addLine(to: CGPoint(x: cw, y: line(cw))); hill.addLine(to: CGPoint(x: cw, y: base)); hill.addLine(to: CGPoint(x: 0, y: base)); hill.closeSubpath()
    ctx.fill(hill, with: .linearGradient(Gradient(colors: [BK.grass, BK.grassDark]), startPoint: CGPoint(x: 0, y: yL - slope * cw), endPoint: CGPoint(x: 0, y: base)))
    ctx.fill(Path(CGRect(x: 0, y: base - 9, width: cw, height: 9)), with: .color(BK.soil))
    var edge = Path(); edge.move(to: CGPoint(x: 0, y: line(0))); edge.addLine(to: CGPoint(x: cw, y: line(cw)))
    ctx.stroke(edge, with: .color(Color(hex: 0x9BE08F)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    for i in 0..<5 {
        let x = cw * (0.1 + 0.2 * Double(i)), y = line(x) + 22 + 9 * Double(i % 2)
        var tuft = Path(); tuft.move(to: CGPoint(x: x - 3, y: y)); tuft.addLine(to: CGPoint(x: x, y: y - 5)); tuft.addLine(to: CGPoint(x: x + 3, y: y))
        ctx.stroke(tuft, with: .color(BK.grassDark.opacity(0.9)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
    }

    // the bike: gear 7 creeps, gear 1 climbs
    let prog = bkPr(t, 0.8, 9.0)
    let creep = hard ? 10 * bkEio(prog) + 1.6 * abs(sin(t * 3.1)) * prog : 46 * bkEio(prog)
    let x = 34 + creep
    let rate = hard ? 0.45 : 1.1                                   // pedal turns per second
    let crank = t * rate * 2 * .pi
    let wheel = creep / R
    let effort = hard ? 1.0 : 0.0
    let fade = bkPr(t, 0, 0.5) * out
    var b = ctx; b.opacity = fade
    b.translateBy(x: x, y: line(x)); b.rotate(by: .radians(-ang))
    if !hard {                                                     // light push: little speed lines behind
        for i in 0..<3 {
            let k = (t * 1.3 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            var sp = Path(); sp.move(to: CGPoint(x: -R * (1.4 + 1.6 * k), y: -R * (0.7 + 0.5 * Double(i)))); sp.addLine(to: CGPoint(x: -R * (2.2 + 1.6 * k), y: -R * (0.7 + 0.5 * Double(i))))
            b.stroke(sp, with: .color(.white.opacity(0.9 * (1 - k))), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
    var jig = b
    if hard { jig.translateBy(x: 0, y: 0.8 * sin(t * 18)) }
    bkRider(&jig, R: R, crank: crank, effort: effort, t: t, part: 0)
    bkBike(&jig, R: R, rot: wheel, crank: crank, frame: hard ? BK.coral : BK.teal)
    bkRider(&jig, R: R, crank: crank, effort: effort, t: t, part: 1)

    // label and gauge: how hard you push
    let name = hard ? "GEAR 7: HARD PUSH" : "GEAR 1: LIGHT PUSH"
    Kit.chip(&ctx, name, CGPoint(x: cw / 2, y: h - 62), color: hard ? BK.coralText : BK.greenText, size: 9, alpha: bkPr(t, 0.2, 0.6) * out)
    let level = hard ? 0.9 + 0.05 * sin(t * 6) : 0.25
    let gl = bkEo(bkPr(t, 0.6, 1.8)) * level
    bkGauge(&ctx, CGRect(x: 16, y: h - 40, width: cw - 32, height: 16), level: gl, alpha: out)
}

// MARK: - Card 2 (hands-on): the back wheel's stack of 7 rings, the pedal ring and the chain. A gear lever slides the chain between the rings

private final class BKRingsState {
    var pos = 0.0               // 0 = gear 1 ... 6 = gear 7, eased
    var s = 0.0                 // how far the chain has run
    var wheel = 0.0             // how far the back wheel (and its rings) has turned
    var dc = 0.0, dp = 0.0      // little turns that keep the teeth between the chain's pins
    private(set) var dt = 0.0
    private var last: Date?

    func step(_ now: Date, target: Int, rf: Double, radius: (Double) -> Double, snap: Bool) {
        dt = min(0.1, max(0, now.timeIntervalSince(last ?? now)))
        last = now
        if snap { pos = Double(target); return }
        let d = Double(target) - pos
        pos = abs(d) < 0.003 ? Double(target) : pos + d * (1 - exp(-dt * 6))
        let v = 1.8 * rf                                  // the chain's speed, in points per second
        s += v * dt
        wheel += v / max(1, radius(pos)) * dt
    }
    func easeC(to target: Double, pitch: Double) { dc += bkWrap(target - dc, pitch) * (1 - exp(-dt * 9)) }
    func easeP(to target: Double, pitch: Double) { dp += bkWrap(target - dp, pitch) * (1 - exp(-dt * 9)) }
}

struct BikeRings: View {
    let active: Bool
    @State private var gear = 1             // 1...7
    @State private var touched = false
    @State private var st = BKRingsState()
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        ZStack(alignment: .bottom) {
            TimelineView(.animation(paused: !active || reduce)) { tl in
                Canvas { ctx, s in draw(&ctx, s, tl.date) }
            }
            HStack(spacing: 3) {
                Text("GEAR LEVER").font(T.mono(9)).tracking(0.6).foregroundStyle(Pal.signal).padding(.trailing, 4).accessibilityHidden(true)
                ForEach(1...7, id: \.self) { n in
                    Button { choose(n) } label: {
                        Text("\(n)").font(T.mono(12)).fontWeight(.bold)
                            .foregroundStyle(gear == n ? Color.white : Pal.signal)
                            .frame(width: 31, height: 31)
                            .background(Circle().fill(gear == n ? BK.coral : Color.clear))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Gear \(n)")
                    .accessibilityAddTraits(gear == n ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(Capsule().fill(Pal.night.opacity(0.6)))
            .padding(.bottom, 10)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Gear lever, gears 1 to 7")
        }
        .bkPanel(BK.skyOut)
        .task(id: "\(active)-\(touched)-\(reduce)") {
            guard active, !touched else { return }
            if reduce { gear = 1; return }
            let seq = [1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2], step = 1.3
            let t0 = Date()
            while !Task.isCancelled && !touched {
                let i = Int(Date().timeIntervalSince(t0) / step) % seq.count
                if gear != seq[i] { gear = seq[i] }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("The back wheel of a bike drawn from the side, with a stack of 7 rings of different sizes on its hub, and a pedal ring down at the pedals. The chain loops from the pedal ring to one of the back rings, and a rear derailleur arm under the stack holds it there. A gear lever with the numbers 1 to 7 moves the chain from one back ring to another. In gear 1 the chain sits on the biggest back ring. In gear 7 it sits on the smallest back ring. The stack is drawn slightly sideways so the rings can be told apart, and the rings are bigger than on a real bike. Untouched, the picture shifts up through all 7 gears and back by itself.")
    }

    private func choose(_ n: Int) {
        if touched && gear == n { return }
        Haptic.fire(.light)
        touched = true
        gear = n
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ now: Date) {
        let w = s.width, h = s.height
        let area = h - 64
        let Rw = max(60, min(118.0, (area - 74) / 2.12, (w - 16) / 2.86))
        let left = (w - 2.86 * Rw) / 2
        let hub = CGPoint(x: left + Rw, y: 36 + 1.14 * Rw + max(0, (area - 74 - 2.12 * Rw) / 2))
        let F = CGPoint(x: hub.x + 1.22 * Rw, y: hub.y + 0.2 * Rw)                  // the pedal ring's middle
        let r30 = 0.4 * Rw, p = 2 * .pi * r30 / 30
        let radii = BK.teeth.map { Double($0) * p / (2 * .pi) }
        let off = CGPoint(x: -0.03 * Rw, y: -0.02 * Rw)                          // each ring sits a little to one side of the one before
        func rAt(_ pos: Double) -> Double {
            let i0 = min(6, max(0, Int(pos))), i1 = min(6, i0 + 1)
            return bkLerp(radii[i0], radii[i1], pos - Double(i0))
        }
        st.step(now, target: gear - 1, rf: r30, radius: rAt, snap: reduce)
        let pos = st.pos
        let rk = rAt(pos)
        let Hk = CGPoint(x: hub.x + off.x * pos, y: hub.y + off.y * pos)
        let rg = 0.066 * Rw
        let gd = rk + rg + 7, ga = 1.18
        let G = CGPoint(x: Hk.x + gd * cos(ga), y: Hk.y + gd * sin(ga))
        let th = bkLerp(0.75, 0.2, pos / 6), lc = 0.26 * Rw
        let T = CGPoint(x: G.x + lc * sin(th), y: G.y + lc * cos(th))
        let loop = BKLoop([BKCircle(c: Hk, r: rk, cw: true), BKCircle(c: F, r: r30, cw: true), BKCircle(c: T, r: rg, cw: true), BKCircle(c: G, r: rg, cw: false)])
        let N = max(8, Int((loop.length / p).rounded())), pp = loop.length / Double(N)
        st.easeC(to: bkAlign(loop, 0, r: rk, pitch: pp, s: st.s) - st.wheel - 0.53 * pos, pitch: pp / rk)
        st.easeP(to: bkAlign(loop, 1, r: r30, pitch: pp, s: st.s) - st.s / r30, pitch: pp / r30)
        let angC = st.wheel + st.dc, angP = st.s / r30 + st.dp

        // soft hills, then the road sliding by at the wheel's speed
        let ground = hub.y + Rw
        for (cx, rr, col) in [(0.12, 70.0, 0xBFE6A8), (0.58, 95.0, 0xA9DB9A), (0.95, 65.0, 0xBFE6A8)] as [(Double, Double, UInt32)] {
            ctx.fill(Path(ellipseIn: CGRect(x: w * cx - rr, y: ground - rr * 0.55, width: 2 * rr, height: rr * 1.1)), with: .color(Color(hex: col)))
        }
        ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: 10)), with: .color(BK.road))
        let sp = 34.0, goff = (st.wheel * Rw).truncatingRemainder(dividingBy: sp)
        for i in -1...Int(w / sp) + 1 {
            ctx.fill(Path(roundedRect: CGRect(x: Double(i) * sp - goff, y: ground + 3.5, width: 16, height: 3), cornerRadius: 1.5), with: .color(BK.cream.opacity(0.85)))
        }
        ctx.fill(Path(CGRect(x: 0, y: ground + 10, width: w, height: h - ground - 10)), with: .color(BK.soil.opacity(0.3)))

        // the back wheel and the frame
        bkWheel(&ctx, hub, Rw, rot: st.wheel)
        let S = CGPoint(x: hub.x + 0.95 * Rw, y: hub.y - 0.95 * Rw)
        for (a, b) in [(hub, F), (hub, S), (F, S)] { bkLine(&ctx, a, b, BK.ink, 0.15 * Rw) }
        for (a, b) in [(hub, F), (hub, S), (F, S)] { bkLine(&ctx, a, b, BK.coral, 0.095 * Rw) }
        bkLine(&ctx, S, CGPoint(x: S.x - 0.03 * Rw, y: S.y - 0.14 * Rw), BK.ink, 0.07 * Rw)
        ctx.fill(Path(roundedRect: CGRect(x: S.x - 0.24 * Rw, y: S.y - 0.22 * Rw, width: 0.3 * Rw, height: 0.08 * Rw), cornerRadius: 0.04 * Rw), with: .color(BK.ink))

        // the stack of 7 rings, biggest at the back
        for i in 0..<7 {
            let k = Double(i) / 6
            let c = CGPoint(x: hub.x + off.x * Double(i), y: hub.y + off.y * Double(i))
            bkRingBody(&ctx, c, teeth: BK.teeth[i], r: radii[i], angle: angC + 0.53 * Double(i),
                       body: bkMix(0x2BB5A6, 0xFF9A3C, k), dark: bkMix(0x1C8A7E, 0xD9701A, k), glow: max(0, 1 - abs(pos - Double(i)) * 2.5))
        }
        // the pedal ring (30 teeth)
        bkRingBody(&ctx, F, teeth: 30, r: r30, angle: angP, body: BK.teal, dark: BK.tealDark)

        // the rear derailleur: an arm from the wheel's hub, and a cage with two small wheels that hold the chain
        let dropout = CGPoint(x: hub.x - 3, y: hub.y + 4)
        let pivot = CGPoint(x: G.x - 5, y: G.y - 7)
        bkLine(&ctx, dropout, pivot, BK.steelDark, 0.075 * Rw + 3)
        bkLine(&ctx, dropout, pivot, BK.steel, 0.075 * Rw)
        bkDot(&ctx, dropout, 0.06 * Rw, BK.steelDark)
        bkDot(&ctx, pivot, 0.05 * Rw, BK.steelDark)
        bkLine(&ctx, G, T, BK.steelDark, 2 * rg + 6)
        bkLine(&ctx, G, T, BK.steel, 2 * rg + 2.5)
        bkLine(&ctx, G, T, .white.opacity(0.28), 2.5)

        // the chain, on top of the rings it wraps
        bkLinks(&ctx, loop, offset: st.s, pitch: pp, count: N, thick: max(4, 0.045 * Rw))
        // the little wheels of the cage, over the chain
        for (c, dir) in [(G, -1.0), (T, 1.0)] {
            bkRingBody(&ctx, c, teeth: 8, r: rg - 1.5, angle: dir * st.s / rg, body: BK.steel, dark: BK.steelDark)
        }
        // teeth over the chain where it runs: the pedal ring, and the back ring it is on
        bkTeethCaps(&ctx, F, teeth: 30, r: r30, angle: angP, body: BK.teal, dark: BK.tealDark)
        let ia = min(6, max(0, Int(pos.rounded())))
        let k = Double(ia) / 6
        bkTeethCaps(&ctx, CGPoint(x: hub.x + off.x * Double(ia), y: hub.y + off.y * Double(ia)), teeth: BK.teeth[ia], r: radii[ia], angle: angC + 0.53 * Double(ia),
                    body: bkMix(0x2BB5A6, 0xFF9A3C, k), dark: bkMix(0x1C8A7E, 0xD9701A, k), alpha: 1 - bkCl(abs(pos - Double(ia)) * 2.4))

        // pedal cranks, over everything at the pedals
        for q in 0..<2 {
            let a = angP + Double(q) * .pi
            let e = CGPoint(x: F.x + 0.5 * Rw * cos(a), y: F.y + 0.5 * Rw * sin(a))
            bkLine(&ctx, F, e, BK.ink, 0.09 * Rw)
            ctx.fill(Path(roundedRect: CGRect(x: e.x - 0.14 * Rw, y: e.y - 0.045 * Rw, width: 0.28 * Rw, height: 0.09 * Rw), cornerRadius: 0.03 * Rw), with: .color(BK.coral))
        }
        bkDot(&ctx, F, 0.07 * Rw, BK.ink)
        bkDot(&ctx, hub, 0.05 * Rw, BK.ink)

        // what is what
        let cy = 26.0
        let backTarget = CGPoint(x: Hk.x - rk * 0.62, y: Hk.y - rk * 0.62)
        let backX = bkFit(hub.x - 0.3 * Rw, "BACK RINGS", 9, w)
        bkLine(&ctx, CGPoint(x: backX, y: cy + 11), backTarget, .white.opacity(0.85), 1.4, dash: [2, 3])
        bkDot(&ctx, backTarget, 2.6, .white)
        Kit.chip(&ctx, "BACK RINGS", CGPoint(x: backX, y: cy), color: BK.goldText, size: 9)
        let pedTarget = CGPoint(x: F.x + r30 * 0.7, y: F.y - r30 * 0.7)
        let pedX = bkFit(F.x + 0.2 * Rw, "PEDAL RING", 9, w)
        bkLine(&ctx, CGPoint(x: pedX, y: cy + 11), pedTarget, .white.opacity(0.85), 1.4, dash: [2, 3])
        bkDot(&ctx, pedTarget, 2.6, .white)
        Kit.chip(&ctx, "PEDAL RING", CGPoint(x: pedX, y: cy), color: BK.tealText, size: 9)
        let chainPt = loop.at(loop.ends[0] + (loop.ends[1] - loop.ends[0]) * 0.55).p
        let chX = bkFit(chainPt.x, "CHAIN", 9, w), chY = hub.y - 0.62 * Rw
        bkLine(&ctx, CGPoint(x: chX, y: chY + 11), chainPt, .white.opacity(0.85), 1.4, dash: [2, 3])
        bkDot(&ctx, chainPt, 2.6, .white)
        Kit.chip(&ctx, "CHAIN", CGPoint(x: chX, y: chY), color: .white, size: 9)

        // which gear
        let g1 = 1 - bkPr(pos, 0.04, 0.14), g7 = bkPr(pos, 5.86, 5.96), gm = bkPr(pos, 0.14, 0.3) * (1 - bkPr(pos, 5.7, 5.86))
        let gy = ground + 24
        Kit.chip(&ctx, "GEAR 1: BIGGEST BACK RING", CGPoint(x: w / 2, y: gy), color: BK.tealText, size: 9, alpha: g1)
        Kit.chip(&ctx, "GEAR 7: SMALLEST BACK RING", CGPoint(x: w / 2, y: gy), color: BK.goldText, size: 9, alpha: g7)
        Kit.chip(&ctx, "GEAR \(Int(pos.rounded()) + 1)", CGPoint(x: w / 2, y: gy), color: .white, size: 9, alpha: gm)
    }
}

// MARK: - Card 3 (hands-on): the pedal ring and the back ring with real teeth, and the chain's links counted as they pass

private final class BKCountState {
    var mix = 0.0               // 0 = gear 1 (30 teeth), 1 = gear 7 (10 teeth)
    var t0 = Date()             // when the current count started (it waits for the rings to change first)
    private var lastT = -1
    private var last: Date?

    func step(_ now: Date, target: Int, snap: Bool) {
        let dt = min(0.1, max(0, now.timeIntervalSince(last ?? now)))
        last = now
        if lastT != target {
            if lastT == -1 { mix = Double(target); t0 = now.addingTimeInterval(0.6) } else { t0 = now.addingTimeInterval(1.1) }
            lastT = target
        }
        let goal = Double(target)
        if snap { mix = goal; return }
        mix += max(-dt / 0.9, min(dt / 0.9, goal - mix))
    }
    /// Seconds since the current count began (negative while the rings are still changing).
    func clock(_ now: Date) -> Double { now.timeIntervalSince(t0) }
}

struct BikeCount: View {
    let active: Bool
    @State private var gear7 = false
    @State private var touched = false
    @State private var st = BKCountState()
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        ZStack(alignment: .bottom) {
            TimelineView(.animation(paused: !active || reduce)) { tl in
                Canvas { ctx, s in draw(&ctx, s, tl.date) }
            }
            HStack(spacing: 2) {
                BKSegButton(text: "GEAR 1", on: !gear7) { choose(false) }
                BKSegButton(text: "GEAR 7", on: gear7) { choose(true) }
            }
            .padding(3)
            .background(Capsule().fill(Pal.night.opacity(0.6)))
            .padding(.bottom, 10)
        }
        .bkPanel(BK.skyOut)
        .task(id: "\(active)-\(touched)-\(reduce)") {
            guard active, !touched else { return }
            if reduce { gear7 = false; return }
            let t0 = Date()
            while !Task.isCancelled && !touched {
                let t = Date().timeIntervalSince(t0).truncatingRemainder(dividingBy: 17)
                let g = t >= 8.4
                if g != gear7 { gear7 = g }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("The pedal ring and one back ring, drawn with real teeth, and the chain around them. The pedal ring has 30 teeth. In gear 1 the back ring also has 30 teeth. In gear 7 it has only 10 teeth. Each ring has one gold tooth and a gold hand so its turns can be counted. One pedal turn pulls 30 links of the chain past, and the links are counted as they pass in three coloured groups of 10. In gear 1, 30 links turn the 30-tooth back ring once, so 1 pedal turn gives 1 wheel turn. In gear 7, each group of 10 links turns the 10-tooth ring once, so 1 pedal turn gives 3 wheel turns. A toggle switches between gear 1 and gear 7. The rings are bigger than on a real bike and the chain is shown as a plain loop. Untouched, the picture counts gear 1, then gear 7, and repeats.")
    }

    private func choose(_ g7: Bool) {
        if touched && gear7 == g7 { return }
        Haptic.fire(.light)
        touched = true
        gear7 = g7
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ now: Date) {
        let w = s.width, h = s.height
        st.step(now, target: gear7 ? 1 : 0, snap: reduce)
        let e = bkEio(st.mix)
        let target = gear7 ? 1 : 0
        let settled = abs(st.mix - Double(target)) < 0.001
        let turnsB = target == 1 ? 3 : 1

        // layout: rings side by side, the same tooth size in both
        let area = h - 62
        let p = min(11.5, (w - 56) / 26.55)
        let r30 = 30 * p / (2 * .pi), r10 = 10 * p / (2 * .pi)
        let D = 17 * p
        let xb = (w - (D + 2 * r30)) / 2 + r30, xp = xb + D
        let ringTop = 68 + min(26, max(0, (area - 236) / 2))
        let cy = ringTop + r30
        let rb = bkLerp(r30, r10, e)
        let loop = BKLoop([BKCircle(c: CGPoint(x: xb, y: cy), r: rb, cw: true), BKCircle(c: CGPoint(x: xp, y: cy), r: r30, cw: true)])
        let L = loop.length
        let N = max(8, Int((L / p).rounded())), pp = L / Double(N)

        // the count: one pedal turn pulls 30 links past. It runs, rests so the numbers can be read, then starts again
        let c = st.clock(now)
        let u: Double
        if reduce { u = 1 } else if c < 0 { u = 0 } else { u = bkSmooth(bkPr(c.truncatingRemainder(dividingBy: 7.6), 0.3, 5.7)) }
        let sNow = u * 30 * pp

        // angles: the gold teeth start wherever they sit between the pins, then turn with the chain
        let a0b = bkAlign(loop, 0, r: rb, pitch: pp, s: 0), a0p = bkAlign(loop, 1, r: r30, pitch: pp, s: 0)
        let angB = a0b + sNow / rb, angP = a0p + sNow / r30
        let marks = settled

        // which links have passed the marker on the top run, and in which group of 10
        let qm = (loop.ends[0] + loop.ends[1]) / 2
        var passed = 0
        func order(_ i: Int) -> Int? {
            var sStar = (qm - Double(i) * pp).truncatingRemainder(dividingBy: L)
            if sStar < 0 { sStar += L }
            let k = Int(sStar / pp + 1e-9)
            return (sStar <= sNow + 1e-9 && k < 30) ? k : nil
        }
        if marks { for i in 0..<N where order(i) != nil { passed += 1 } }
        let lap = marks ? min(30, passed) : 0

        // the rings (the small one fades in as the big one fades out), then the chain, then the teeth over it
        let colB30 = (BK.teal, BK.tealDark), colB10 = (BK.orange, BK.orangeDark)
        let cb = CGPoint(x: xb, y: cy), cp = CGPoint(x: xp, y: cy)
        bkRingBody(&ctx, cb, teeth: 30, r: r30, angle: angB, body: colB30.0, dark: colB30.1, mark: marks, alpha: 1 - e)
        bkRingBody(&ctx, cb, teeth: 10, r: r10, angle: angB, body: colB10.0, dark: colB10.1, mark: marks, alpha: e)
        bkRingBody(&ctx, cp, teeth: 30, r: r30, angle: angP, body: BK.teal, dark: BK.tealDark, mark: marks)
        let tint: (Int) -> Color? = { i in
            guard marks, let k = order(i) else { return nil }
            return BK.group[k / 10]
        }
        bkLinks(&ctx, loop, offset: sNow, pitch: pp, count: N, thick: 0.5 * p, tint: tint)
        bkTeethCaps(&ctx, cb, teeth: 30, r: r30, angle: angB, body: colB30.0, dark: colB30.1, mark: marks, alpha: 1 - e)
        bkTeethCaps(&ctx, cb, teeth: 10, r: r10, angle: angB, body: colB10.0, dark: colB10.1, mark: marks, alpha: e)
        bkTeethCaps(&ctx, cp, teeth: 30, r: r30, angle: angP, body: BK.teal, dark: BK.tealDark, mark: marks)
        // the hubs over the chain
        bkDot(&ctx, cb, max(4.5, bkLerp(r30, r10, e) * 0.24), BK.ink)
        bkDot(&ctx, cp, r30 * 0.24, BK.ink)

        // the marker on the top run, and the count of links that have passed it
        let M = loop.at(qm).p
        bkLine(&ctx, CGPoint(x: M.x, y: M.y - 0.5 * p - 3), CGPoint(x: M.x, y: M.y + 0.5 * p + 3), BK.gold, 3)
        var tri = Path()
        tri.move(to: CGPoint(x: M.x, y: M.y - 0.5 * p - 4)); tri.addLine(to: CGPoint(x: M.x - 5, y: M.y - 0.5 * p - 12)); tri.addLine(to: CGPoint(x: M.x + 5, y: M.y - 0.5 * p - 12)); tri.closeSubpath()
        ctx.fill(tri, with: .color(BK.gold))
        Kit.chip(&ctx, "\(lap)", CGPoint(x: M.x, y: M.y - 0.5 * p - 28), color: lap >= 30 ? BK.goldText : .white, size: 12, alpha: marks ? 1 : 0)

        // labels over the rings
        let topY = 22.0
        let bx = bkFit(xb, "BACK RING: 30 TEETH", 9, w), px = bkFit(xp, "PEDAL RING: 30 TEETH", 9, w)
        Kit.chip(&ctx, "BACK RING: 30 TEETH", CGPoint(x: bx, y: topY), color: BK.tealText, size: 9, alpha: 1 - e)
        Kit.chip(&ctx, "BACK RING: 10 TEETH", CGPoint(x: bx, y: topY), color: BK.goldText, size: 9, alpha: e)
        Kit.chip(&ctx, "PEDAL RING: 30 TEETH", CGPoint(x: px, y: topY), color: BK.tealText, size: 9)

        // the counters under the rings: how many times each one has turned
        let iconY = cy + r30 + 30
        let pedalTurns = marks ? Int(u + 1e-6) : 0
        let wheelTurns = marks ? Int(u * Double(turnsB) + 1e-6) : 0
        var pedalIcon = ctx
        pedalIcon.translateBy(x: xp, y: iconY)
        bkDot(&pedalIcon, .zero, 15, .white.opacity(0.3))
        pedalIcon.stroke(Path(ellipseIn: CGRect(x: -15, y: -15, width: 30, height: 30)), with: .color(BK.ink.opacity(0.7)), lineWidth: 2)
        bkLine(&pedalIcon, .zero, CGPoint(x: 13 * cos(angP), y: 13 * sin(angP)), BK.ink, 3)
        bkDot(&pedalIcon, CGPoint(x: 13 * cos(angP), y: 13 * sin(angP)), 3.6, BK.coral)
        bkWheel(&ctx, CGPoint(x: xb, y: iconY), 15, rot: angB)
        Kit.chip(&ctx, pedalTurns == 1 ? "1 PEDAL TURN" : "\(pedalTurns) PEDAL TURNS", CGPoint(x: bkFit(xp, "0 PEDAL TURNS", 9, w), y: iconY + 36), color: pedalTurns > 0 ? BK.goldText : .white, size: 9)
        Kit.chip(&ctx, wheelTurns == 1 ? "1 WHEEL TURN" : "\(wheelTurns) WHEEL TURNS", CGPoint(x: bkFit(xb, "0 WHEEL TURNS", 9, w), y: iconY + 36), color: wheelTurns > 0 ? BK.tealText : .white, size: 9)
        // a dot for each turn still to come, lit as it is done
        for (cx, total, done, col) in [(xp, 1, pedalTurns, BK.gold), (xb, turnsB, wheelTurns, BK.teal)] as [(Double, Int, Int, Color)] {
            for i in 0..<total {
                let dx = cx + (Double(i) - Double(total - 1) / 2) * 18, dy = iconY + 60
                bkDot(&ctx, CGPoint(x: dx, y: dy), 6, BK.ink.opacity(0.25))
                if i < done { bkDot(&ctx, CGPoint(x: dx, y: dy), 6, col); ctx.stroke(Path(ellipseIn: CGRect(x: dx - 6, y: dy - 6, width: 12, height: 12)), with: .color(BK.ink.opacity(0.5)), lineWidth: 1.2) }
            }
        }
    }
}

// MARK: - Card 4: the same hill, climbed in short steps and in long ones. Same height either way

struct BikeSteps: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 13, still: 10, cues: [Cue(10.0, .success)], replayOnTap: true, sky: BK.skyOut,
                    label: "The same hill drawn twice, one above the other, each with a flag at the top and faint stair steps drawn on it. The same rider climbs both at the same speed and reaches the same height. Top: gear 1. The bike takes many short steps, nine pedal turns, and a small gauge under each step shows a light push. Bottom: gear 7. The bike takes only three long steps, three pedal turns, and the gauge under each step shows a much harder push. The hill is drawn steeper than a real road and the steps are only a picture of the pedal turns.") { ctx, s, t, _ in
            let w = s.width, h = s.height, hs = (h - 6) / 2
            let out = 1 - bkPr(t, 12.4, 13.0)
            for (i, one) in [true, false].enumerated() {
                let r = CGRect(x: 0, y: (hs + 6) * Double(i), width: w, height: hs)
                ctx.drawLayer { l in
                    l.clip(to: Path(r))
                    l.translateBy(x: 0, y: r.minY)
                    bkStepsScene(&l, CGSize(width: w, height: hs), t: t, gear1: one, out: out)
                }
            }
            Kit.chip(&ctx, "SAME HILL", CGPoint(x: w - 62, y: hs + 3), color: BK.goldText, size: 10, alpha: bkPr(t, 0.1, 0.5) * out)
        }
    }
}

private func bkStepsScene(_ ctx: inout GraphicsContext, _ s: CGSize, t: Double, gear1: Bool, out: Double) {
    let w = s.width, h = s.height
    let R = 15.0
    let n = gear1 ? 9 : 3
    let base = h - 3
    let y0 = base - 42                              // the flat start of the hill
    let xs = 140.0                                  // where the climb starts (and where the back wheel starts)
    let flagX = w - 30
    let yTop = max(76.0, h * 0.4)
    let slope = (y0 - yTop) / (flagX - xs)
    let ang = atan(slope)
    func surf(_ x: Double) -> Double { x <= xs ? y0 : y0 - slope * (x - xs) }
    let xe = flagX - 3.05 * R * cos(ang) - 4          // the back wheel's spot when the front wheel reaches the flag
    let dx = (xe - xs) / Double(n)

    // clouds
    for (i, cx) in [0.5, 0.78].enumerated() {
        let x = (w * cx + t * (3 + Double(i))).truncatingRemainder(dividingBy: w + 80) - 40
        let y = 30 + 14 * Double(i)
        for (ddx, ddy, rr) in [(-10.0, 2.0, 7.0), (0.0, -3.0, 10.0), (11.0, 2.0, 7.0)] { bkDot(&ctx, CGPoint(x: x + ddx, y: y + ddy), rr, .white.opacity(0.8)) }
    }

    // the hill
    var hill = Path()
    hill.move(to: CGPoint(x: 0, y: y0)); hill.addLine(to: CGPoint(x: xs, y: y0)); hill.addLine(to: CGPoint(x: w, y: surf(w))); hill.addLine(to: CGPoint(x: w, y: base)); hill.addLine(to: CGPoint(x: 0, y: base)); hill.closeSubpath()
    ctx.fill(hill, with: .linearGradient(Gradient(colors: [BK.grass, BK.grassDark]), startPoint: CGPoint(x: 0, y: yTop), endPoint: CGPoint(x: 0, y: base)))
    ctx.fill(Path(CGRect(x: 0, y: base - 6, width: w, height: 6)), with: .color(BK.soil))
    var edge = Path(); edge.move(to: CGPoint(x: 0, y: y0)); edge.addLine(to: CGPoint(x: xs, y: y0)); edge.addLine(to: CGPoint(x: w, y: surf(w)))
    ctx.stroke(edge, with: .color(Color(hex: 0x9BE08F)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

    // the bike climbs at one steady speed, the same for both gears
    let u = bkPr(t, 1.0, 9.0)
    let ue = 0.5 * u + 0.5 * bkSmooth(u)
    let x = xs + (xe - xs) * ue
    let turns = (x - xs) / dx                       // pedal turns so far: one per step

    // faint stair steps drawn on the hill, and a small push gauge under each one
    let inset = 3.0
    var stairs = Path()
    stairs.move(to: CGPoint(x: xs, y: surf(xs) + inset))
    for i in 0..<n {
        let xi = xs + Double(i) * dx, xj = xs + Double(i + 1) * dx
        stairs.addLine(to: CGPoint(x: xj, y: surf(xi) + inset))
        stairs.addLine(to: CGPoint(x: xj, y: surf(xj) + inset))
    }
    ctx.stroke(stairs, with: .color(.white.opacity(0.5 * out)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round, dash: [1, 0]))
    let target = gear1 ? 0.3 : 0.9
    let bw = min(15.0, dx * 0.5)
    for i in 0..<n {
        let xi = xs + Double(i) * dx, xj = xi + dx
        let pi = bkCl(turns - Double(i))
        if pi > 0 {                                  // the tread being climbed lights up
            let xm = xi + (xj - xi) * pi
            var tread = Path(); tread.move(to: CGPoint(x: xi, y: surf(xi) + inset)); tread.addLine(to: CGPoint(x: xm, y: surf(xi) + inset))
            ctx.stroke(tread, with: .color(BK.gold.opacity(out)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        let level = target * bkEo(pi)
        let gx = (xi + xj) / 2 - bw / 2
        let top = surf(xi) + inset + 7
        bkVGauge(&ctx, CGRect(x: gx, y: top, width: bw, height: 26), level: level)
    }

    // the flag at the top
    let fy = surf(flagX)
    let arrived = bkPr(u, 0.97, 1.0)
    bkLine(&ctx, CGPoint(x: flagX, y: fy), CGPoint(x: flagX, y: fy - 32), BK.ink, 2.4)
    var flag = Path()
    let wave = 2.5 + 3.5 * arrived
    flag.move(to: CGPoint(x: flagX, y: fy - 32))
    flag.addQuadCurve(to: CGPoint(x: flagX + 18, y: fy - 27 + wave * sin(t * 6)), control: CGPoint(x: flagX + 9, y: fy - 35 + wave * sin(t * 6 + 1)))
    flag.addLine(to: CGPoint(x: flagX, y: fy - 20)); flag.closeSubpath()
    ctx.fill(flag, with: .color(BK.coral))
    ctx.stroke(flag, with: .color(BK.ink.opacity(0.6)), lineWidth: 1)
    bkDot(&ctx, CGPoint(x: flagX, y: fy - 33), 2.6, BK.gold)

    // the bike
    let crank = turns * 2 * .pi
    let wheel = (x - xs) / cos(ang) / R
    let effort = gear1 ? 0.0 : 1.0
    var b = ctx; b.opacity = bkPr(t, 0, 0.5) * out
    b.translateBy(x: x, y: surf(x)); b.rotate(by: .radians(-ang))
    var jig = b
    if !gear1 { jig.translateBy(x: 0, y: 0.5 * sin(t * 12)) }
    bkRider(&jig, R: R, crank: crank, effort: effort, t: t, part: 0)
    bkBike(&jig, R: R, rot: wheel, crank: crank, frame: gear1 ? BK.teal : BK.coral)
    bkRider(&jig, R: R, crank: crank, effort: effort, t: t, part: 1)

    // the label
    let name = gear1 ? "GEAR 1: MANY TURNS, LIGHT PUSH" : "GEAR 7: FEW TURNS, HARD PUSH"
    Kit.chip(&ctx, name, CGPoint(x: 10, y: 17), anchor: .leading, color: gear1 ? BK.greenText : BK.coralText, size: 9, alpha: bkPr(t, 0.2, 0.6) * out)
}

// MARK: - Card 5 (hands-on): the right gear for the road. A steep hill, a flat road, a downhill

private final class BKRoadState {
    var p = 0.0                 // 0 = steep hill, 1 = flat road, 2 = downhill (eased)
    var dist = 0.0              // how far the road has slid under the bike
    var crank = 0.0, wheel = 0.0
    var wSpeed = 0.0            // the wheel's turning speed, radians per second
    private var last: Date?

    func step(_ now: Date, target: Int, ratios: [Double], R: Double, snap: Bool) {
        let dt = min(0.1, max(0, now.timeIntervalSince(last ?? now)))
        last = now
        if snap { p = Double(target); wSpeed = 2.4 * ratios[target]; return }
        let d = Double(target) - p
        p = abs(d) < 0.003 ? Double(target) : p + d * (1 - exp(-dt * 3.2))
        let i0 = min(1, max(0, Int(p))), f = p - Double(i0)
        let goal = 2.4 * bkLerp(ratios[i0], ratios[i0 + 1], f)
        wSpeed += (goal - wSpeed) * (1 - exp(-dt * 3))
        crank += 2.4 * dt                                  // the same calm pedalling in every gear
        wheel += wSpeed * dt                               // the wheel turns once per pedal turn in gear 1, 1.8 times in gear 4, 3 times in gear 7
        dist += wSpeed * R * dt
    }
}

struct BikeRoads: View {
    let active: Bool
    @State private var scene = 0            // 0 steep hill, 1 flat road, 2 downhill
    @State private var touched = false
    @State private var st = BKRoadState()
    @Environment(\.accessibilityReduceMotion) private var reduce

    private static let slopes = [0.5, 0.0, -0.34]
    private static let names = ["STEEP HILL", "FLAT ROAD", "DOWNHILL"]
    private static let gears = [1, 4, 7]
    private static let full = ["STEEP HILL: GEAR 1", "FLAT ROAD: GEAR 4", "DOWNHILL: GEAR 7"]

    var body: some View {
        ZStack(alignment: .bottom) {
            TimelineView(.animation(paused: !active || reduce)) { tl in
                Canvas { ctx, s in draw(&ctx, s, tl.date) }
            }
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in BKSegButton(text: Self.names[i], on: scene == i, pad: 11) { choose(i) } }
            }
            .padding(3)
            .background(Capsule().fill(Pal.night.opacity(0.6)))
            .padding(.bottom, 10)
        }
        .bkPanel(BK.skyOut)
        .task(id: "\(active)-\(touched)-\(reduce)") {
            guard active, !touched else { return }
            if reduce { scene = 0; return }
            let t0 = Date()
            while !Task.isCancelled && !touched {
                let i = Int(Date().timeIntervalSince(t0) / 5.0) % 3
                if scene != i { scene = i }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("A friendly rider on a bike, on a road that changes. A picker chooses a steep hill, a flat road or a downhill. On the steep hill the rider is in gear 1. On the flat road the rider is in gear 4. Downhill the rider is in gear 7. In all three the rider pedals at the same calm pace, and a gauge above the bike shows the same light push each time. The bike climbs slowly in gear 1, rolls along in gear 4 and speeds down in gear 7. The hill is drawn steeper than most. Untouched, the picture goes through the three roads by itself.")
    }

    private func choose(_ i: Int) {
        if touched && scene == i { return }
        Haptic.fire(.light)
        touched = true
        scene = i
    }

    private func draw(_ ctx: inout GraphicsContext, _ s: CGSize, _ now: Date) {
        let w = s.width, h = s.height
        let R = min(27.0, w * 0.074)
        let ratios = Self.gears.map { 30.0 / Double(BK.teeth[$0 - 1]) }
        st.step(now, target: scene, ratios: ratios, R: R, snap: reduce)
        let p = st.p
        let i0 = min(1, max(0, Int(p))), f = p - Double(i0)
        let a = bkLerp(Self.slopes[i0], Self.slopes[i0 + 1], f)
        let P = CGPoint(x: w / 2, y: h * 0.62)                    // where the bike touches the road

        // sun, clouds, far hills
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.88 - 20, y: 96 - 20, width: 40, height: 40)), with: .color(Color(hex: 0xFFE08A)))
        for (i, cx) in [0.15, 0.55, 0.9].enumerated() {
            let x = (w * cx + now.timeIntervalSinceReferenceDate * (3 + Double(i))).truncatingRemainder(dividingBy: w + 100) - 50
            let y = 88 + 22 * Double(i % 2)
            for (dx, dy, rr) in [(-14.0, 2.0, 10.0), (0.0, -4.0, 13.0), (15.0, 2.0, 9.0)] { bkDot(&ctx, CGPoint(x: x + dx, y: y + dy), rr, .white.opacity(0.85)) }
        }
        let layers: [(Double, UInt32, Double)] = [(16.0, 0xBFE6A8, 0.06), (11.0, 0xA9DB9A, 0.12)]
        for (k, layer) in layers.enumerated() {
            let (amp, col, sp) = layer
            var hills = Path()
            hills.move(to: CGPoint(x: 0, y: h))
            var x = 0.0
            while x <= w + 6 {
                hills.addLine(to: CGPoint(x: x, y: P.y - 26 - 10 * Double(k) - amp * sin((x + st.dist * sp) / 46 + Double(k) * 2) - 5 * sin((x + st.dist * sp) / 17)))
                x += 6
            }
            hills.addLine(to: CGPoint(x: w, y: h)); hills.closeSubpath()
            ctx.fill(hills, with: .color(Color(hex: col)))
        }

        // the road, the scenery and the bike, all tilted together
        ctx.drawLayer { l in
            l.translateBy(x: P.x, y: P.y)
            l.rotate(by: .radians(-a))
            let big = max(w, h) * 1.6
            l.fill(Path(CGRect(x: -big, y: 0, width: 2 * big, height: big)), with: .linearGradient(Gradient(colors: [BK.grass, BK.grassDark]), startPoint: .zero, endPoint: CGPoint(x: 0, y: 220)))
            l.fill(Path(CGRect(x: -big, y: 0, width: 2 * big, height: 13)), with: .color(BK.road))
            l.fill(Path(CGRect(x: -big, y: 13, width: 2 * big, height: 2.5)), with: .color(BK.soil))
            let sp = 44.0, off = st.dist.truncatingRemainder(dividingBy: sp)
            for i in -Int(big / sp)...Int(big / sp) {
                l.fill(Path(roundedRect: CGRect(x: Double(i) * sp - off, y: 5, width: 20, height: 3), cornerRadius: 1.5), with: .color(BK.cream.opacity(0.85)))
            }
            let ts = 150.0, toff = st.dist.truncatingRemainder(dividingBy: ts)
            for i in -Int(big / ts)...Int(big / ts) {
                let tx = Double(i) * ts - toff + 40
                l.fill(Path(roundedRect: CGRect(x: tx - 2.5, y: -22, width: 5, height: 22), cornerRadius: 2), with: .color(BK.soil))
                bkDot(&l, CGPoint(x: tx, y: -34), 13, BK.grassDark)
                bkDot(&l, CGPoint(x: tx - 4, y: -37), 6.5, BK.grass.opacity(0.75))
            }
            var b = l
            b.translateBy(x: -1.5 * R, y: 0)
            bkRider(&b, R: R, crank: st.crank, effort: 0, t: now.timeIntervalSinceReferenceDate, part: 0)
            bkBike(&b, R: R, rot: st.wheel, crank: st.crank, frame: BK.coral)
            bkRider(&b, R: R, crank: st.crank, effort: 0, t: now.timeIntervalSinceReferenceDate, part: 1)
        }

        // wind streaks when it is fast
        let fast = bkPr(st.wSpeed, 4.5, 7.0)
        if fast > 0.02 {
            for i in 0..<4 {
                let k = (now.timeIntervalSinceReferenceDate * 1.8 + Double(i) * 0.27).truncatingRemainder(dividingBy: 1)
                let y = P.y - 70 + 22 * Double(i) - 20 * a
                let x = w * 0.5 - 40 - k * 120 - Double(i) * 14
                bkLine(&ctx, CGPoint(x: x, y: y), CGPoint(x: x - 34, y: y), .white.opacity(0.85 * fast * (1 - k)), 2.6)
            }
        }

        // the push gauge: the same calm push in every road, and the label of the road
        bkGauge(&ctx, CGRect(x: w / 2 - 95, y: 46, width: 190, height: 16), level: 0.28 + 0.02 * sin(st.crank * 2))
        let cols = [BK.coralText, BK.tealText, BK.greenText]
        for i in 0..<3 {
            Kit.chip(&ctx, Self.full[i], CGPoint(x: w / 2, y: 20), color: cols[i], size: 10, alpha: bkCl(1 - abs(p - Double(i)) * 1.8))
        }
    }
}
