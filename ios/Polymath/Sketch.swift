import SwiftUI

// Hand-drawn style for topic pictures (owner approved 2026-10-27 on the superglue opener). Use with FlatPicture(sky: Sketch.paper).
// Every shape is inked with a wobble that "boils" eight times a second, plus a faint second pencil line; words are handwritten.

/// Hand-drawn ink. Every shape is resampled, pushed sideways by a slow wave whose phase changes each boil frame, then
/// drawn with a soft curve. A second, fainter pass with a different wobble gives the pencil double line.
enum Sketch {
    static let inkColor = Color(hex: 0x2B2420)
    /// Warm paper for every hand-drawn scene (FlatPicture `sky`).
    static let paper: [UInt32] = [0xFCF8EE, 0xF8F0DF, 0xF3E7D0]

    static func frame(_ t: Double) -> Int { Int(t * 8) }

    static func rnd(_ i: Int) -> Double {
        var x = UInt64(truncatingIfNeeded: i &* 2654435761 &+ 0x9E3779B9)
        x ^= x >> 33; x &*= 0xff51afd7ed558ccd; x ^= x >> 33
        return Double(x % 10_000) / 10_000
    }

    static func resample(_ pts: [CGPoint], closed: Bool, step: Double) -> [CGPoint] {
        var src = pts
        if closed, let f = pts.first { src.append(f) }
        var out: [CGPoint] = []
        for i in 0..<(src.count - 1) {
            let a = src[i], b = src[i + 1]
            let n = max(1, Int(hypot(b.x - a.x, b.y - a.y) / step))
            for k in 0..<n {
                let f = Double(k) / Double(n)
                out.append(CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))
            }
        }
        if !closed, let l = src.last { out.append(l) }
        return out
    }

    static func wobble(_ pts: [CGPoint], amp: Double, seed: Int) -> [CGPoint] {
        let s1 = rnd(seed) * 6.28, s2 = rnd(seed + 1) * 6.28, s3 = rnd(seed + 2) * 6.28
        return pts.enumerated().map { i, p in
            let k = Double(i)
            return CGPoint(x: p.x + amp * (0.65 * sin(k * 0.55 + s1) + 0.35 * sin(k * 0.21 + s2)),
                           y: p.y + amp * (0.65 * sin(k * 0.47 + s3) + 0.35 * sin(k * 0.19 + s1)))
        }
    }

    static func smooth(_ p: [CGPoint], closed: Bool) -> Path {
        var path = Path()
        guard p.count > 2 else { if let f = p.first { path.move(to: f); p.dropFirst().forEach { path.addLine(to: $0) } }; return path }
        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
        if closed {
            path.move(to: mid(p[p.count - 1], p[0]))
            for i in 0..<p.count { path.addQuadCurve(to: mid(p[i], p[(i + 1) % p.count]), control: p[i]) }
            path.closeSubpath()
        } else {
            path.move(to: p[0])
            for i in 1..<(p.count - 1) { path.addQuadCurve(to: mid(p[i], p[i + 1]), control: p[i]) }
            path.addLine(to: p[p.count - 1])
        }
        return path
    }

    /// The wobbled path for this boil frame, so a fill and a clip can share the outline.
    static func path(_ pts: [CGPoint], closed: Bool, t: Double, seed: Int, amp: Double = 1.1, still: Bool = false) -> Path {
        let f = still ? 0 : frame(t)
        return smooth(wobble(resample(pts, closed: closed, step: 5), amp: amp, seed: seed &+ f &* 37), closed: closed)
    }

    /// Ink a shape: optional fill, the main line, then a faint second line. `drawn` (0-1) draws the line on, like a pen.
    static func ink(_ ctx: inout GraphicsContext, _ pts: [CGPoint], closed: Bool, t: Double, seed: Int, width: Double = 2.4,
                    color: Color = Sketch.inkColor, fill: Color? = nil, drawn: Double = 1, amp: Double = 1.1, still: Bool = false) {
        let main = path(pts, closed: closed, t: t, seed: seed, amp: amp, still: still)
        if let fill { ctx.fill(main, with: .color(fill)) }
        guard drawn > 0.01 else { return }
        let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        ctx.stroke(drawn < 1 ? main.trimmedPath(from: 0, to: drawn) : main, with: .color(color), style: style)
        let ghost = path(pts, closed: closed, t: t, seed: seed &+ 7, amp: amp * 1.4, still: still)
        ctx.stroke(drawn < 1 ? ghost.trimmedPath(from: 0, to: drawn) : ghost, with: .color(color.opacity(0.28)),
                   style: StrokeStyle(lineWidth: width * 0.45, lineCap: .round, lineJoin: .round))
    }

    static func oval(_ c: CGPoint, _ rx: Double, _ ry: Double, n: Int = 30) -> [CGPoint] {
        (0..<n).map { i in
            let a = Double(i) / Double(n) * 2 * .pi - .pi / 2
            return CGPoint(x: c.x + rx * cos(a), y: c.y + ry * sin(a))
        }
    }

    /// Handwritten words, tilted a hair differently each boil frame.
    static func say(_ ctx: inout GraphicsContext, _ text: String, _ p: CGPoint, size: Double, t: Double, seed: Int,
                    font: String = "Noteworthy-Bold", color: Color = Sketch.inkColor, alpha: Double = 1, anchor: UnitPoint = .center, angle: Double = 0) {
        guard alpha > 0.01 else { return }
        var l = ctx
        l.opacity = alpha
        l.translateBy(x: p.x, y: p.y)
        l.rotate(by: .degrees(angle + (rnd(seed &+ frame(t) &* 13) - 0.5) * 2.2))
        l.draw(l.resolve(Text(text).font(.custom(font, size: size)).foregroundColor(color)), at: .zero, anchor: anchor)
    }

    /// A finger or thumb from `base`, `len` long and `wd` wide, leaning `angle` degrees from straight up (positive leans right).
    /// An open outline: up one side, round the tip, down the other, with no line across the base.
    static func digit(_ base: CGPoint, len: Double, wd: Double, angle: Double) -> [CGPoint] {
        let a = angle * .pi / 180, r = wd / 2
        let ux = sin(a), uy = -cos(a), nx = cos(a), ny = sin(a)
        let tc = CGPoint(x: base.x + ux * (len - r), y: base.y + uy * (len - r))
        var pts = [CGPoint(x: base.x - nx * r, y: base.y - ny * r), CGPoint(x: tc.x - nx * r, y: tc.y - ny * r)]
        pts += (1..<10).map { i in
            let phi = Double.pi - Double(i) / 10 * .pi
            return CGPoint(x: tc.x + nx * r * cos(phi) + ux * r * sin(phi), y: tc.y + ny * r * cos(phi) + uy * r * sin(phi))
        }
        pts += [CGPoint(x: tc.x + nx * r, y: tc.y + ny * r), CGPoint(x: base.x + nx * r, y: base.y + ny * r)]
        return pts
    }
}
