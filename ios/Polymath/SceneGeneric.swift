import SwiftUI

// Parts every style can draw (2026-11-04): arrows, a dimension line, a wave, an arc and travelling rings. They draw in whatever style the
// topic has (`ScenePart.line`), and take a colour by number (`col`, see `SceneLook.palette`) where the picture wants a second ink.

extension SceneLook {
    /// A colour by number: 0 ink, 1 the accent, then (Airbrush only, otherwise ink) 2 blue, 3 orange, 4 salmon, 5 skin, 6 yellow, 7 lime, 8 green, 9 red.
    func palette(_ n: Double) -> Color {
        switch Int(n.rounded()) {
        case 1: return accent
        case 2: return brush ? AB.blue : ink
        case 3: return brush ? AB.orange : ink
        case 4: return brush ? AB.salmon : ink
        case 5: return brush ? AB.skin : ink
        case 6: return brush ? AB.yellow : ink
        case 7: return brush ? AB.lime : ink
        case 8: return brush ? AB.green : ink
        case 9: return brush ? AB.red : ink
        case 10: return .white
        case 11: return brush ? AB.pink : ink
        case 12: return brush ? AB.violet : ink
        case 13: return brush ? AB.teal : ink
        case 14: return brush ? AB.brown : ink
        default: return ink
        }
    }
}

enum SceneGeneric {
    static let names = ["arrow", "dim", "wave", "arc", "rings"]

    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    /// True if `name` was one of these (and has been drawn).
    static func draw(_ name: String, _ c: inout GraphicsContext, _ q: ScenePart) -> Bool {
        let col = q.look.palette(q["col", default: 0])
        let w = q["w", default: q.look.line + (q.look.brush ? 0.4 : 0.15)]
        switch name {
        case "arrow":      // from the origin along +x, `len` long; `head` the size of its head; `col` colour; `w` line width; `both` 1 for a head at each end
            let len = q["len", default: 40], head = q["head", default: q.look.brush ? 8 : 6]
            var l = Path(); l.move(to: pt(0, 0)); l.addLine(to: pt(len, 0))
            q.line(&c, l, width: w, color: col)
            var h = Path(); h.move(to: pt(len - head, -head * 0.55)); h.addLine(to: pt(len, 0)); h.addLine(to: pt(len - head, head * 0.55))
            if q["both", default: 0] > 0.5 { h.move(to: pt(head, -head * 0.55)); h.addLine(to: pt(0, 0)); h.addLine(to: pt(head, head * 0.55)) }
            q.line(&c, h, width: w, color: col, p: BP.pr(q.on, 0.6, 1), k: 1)
        case "dim":        // a dimension line: end bars and heads, from the origin along +x, `len` long
            let len = q["len", default: 60], head = q["head", default: 5]
            var l = Path(); l.move(to: pt(0, 0)); l.addLine(to: pt(len, 0))
            l.move(to: pt(0, -6)); l.addLine(to: pt(0, 6)); l.move(to: pt(len, -6)); l.addLine(to: pt(len, 6))
            q.line(&c, l, width: q.look.hair + 0.2, color: col)
            var h = Path()
            h.move(to: pt(head, -head * 0.5)); h.addLine(to: pt(0, 0)); h.addLine(to: pt(head, head * 0.5))
            h.move(to: pt(len - head, -head * 0.5)); h.addLine(to: pt(len, 0)); h.addLine(to: pt(len - head, head * 0.5))
            q.line(&c, h, width: q.look.hair + 0.2, color: col, p: BP.pr(q.on, 0.6, 1), k: 1)
        case "wave":       // a sine wave from the origin along +x: `w` wide... `len` long, `amp` tall, `wl` the wavelength, `phase` radians, `upto` 0...1 how much is drawn
            let len = q["len", default: 120], amp = q["amp", default: 8], wl = q["wl", default: 30], ph = q["phase", default: 0] + q["speed", default: 0] * q.clock
            let upto = BP.cl(q["upto", default: 1])
            var p = Path()
            let n = max(8, Int(len / 3))
            for i in 0...n {
                let x = len * Double(i) / Double(n)
                let y = amp * sin(x / wl * 2 * .pi + ph)
                if i == 0 { p.move(to: pt(x, y)) } else { p.addLine(to: pt(x, y)) }
            }
            q.line(&c, p.trimmedPath(from: 0, to: upto), width: q["w", default: q.look.line + 0.4], color: col)
        case "arc":        // an ellipse arc about the origin: `rx`, `ry`, from `a0` to `a1` degrees (0 is right, clockwise on screen), `dash` 0 or 1
            let rx = q["rx", default: 40], ry = q["ry", default: rx], a0 = q["a0", default: 0], a1 = q["a1", default: 360]
            var p = Path()
            let n = max(12, Int(abs(a1 - a0) / 5))
            for i in 0...n {
                let a = (a0 + (a1 - a0) * Double(i) / Double(n)) * .pi / 180
                let v = pt(rx * cos(a), ry * sin(a))
                if i == 0 { p.move(to: v) } else { p.addLine(to: v) }
            }
            q.line(&c, p, width: q["w", default: q.look.hair + 0.2], color: col, dash: q["dash", default: 0] > 0.5 ? [3, 3] : [])
        case "rings":      // `n` arcs travelling outward from the origin, `span` degrees wide centred on `rot` (0 is right), spaced `gap`, fading out; `speed` rings a second
            let n = Int(q["n", default: 3]), r0 = q["r0", default: 10], gap = q["gap", default: 12], span = q["span", default: 70] * .pi / 180
            let rot = q["rot", default: 0] * .pi / 180, speed = q["speed", default: 0.7]
            let phase = q["phase", default: 0] + q.clock * speed
            for i in 0..<n {
                let f = (Double(i) + phase).truncatingRemainder(dividingBy: Double(n)) / Double(n)
                let r = r0 + gap * Double(n) * f
                var g = c; g.opacity *= (1 - f) * BP.cl(q.on * 2)
                var p = Path()
                for k in 0...10 { let a = rot - span / 2 + span * Double(k) / 10; let v = pt(r * cos(a), r * sin(a)); if k == 0 { p.move(to: v) } else { p.addLine(to: v) } }
                q.line(&g, p, width: q.look.hair + 0.3, color: col, p: 1, k: i)
            }
        default: return false
        }
        return true
    }
}
