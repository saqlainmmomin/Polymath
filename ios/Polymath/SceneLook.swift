import SwiftUI

// The drawing vocabulary of a scene, per style (2026-11-04). The renderer (Scene.swift) and the generic parts ask a `SceneLook` how to
// stroke a shape, fill it, hatch it, write text and draw a label, so one scene format serves all four styles while each keeps its own
// ink, line weights, label look and way of drawing a line: Drafting crisp black, Wireframe fine white on black, Airbrush a hand line that
// wobbles and sits a little off its colour. Drafting scenes go through exactly the calls they used before.

struct SceneLook {
    let style: TopicStyle
    /// Blueprint has no scene kit; it draws as Drafting.
    init(_ s: TopicStyle) { style = s == .blueprint ? .drafting : s }

    var wire: Bool { style == .wireframe }
    var brush: Bool { style == .airbrush }

    var ink: Color { wire ? WF.ink : brush ? AB.ink : DR.ink }
    var paper: Color { wire ? WF.paper : brush ? AB.paper : DR.paper }
    var accent: Color { wire ? WF.accent : brush ? AB.yellow : DR.accent }
    /// Default outline width.
    var line: Double { wire ? WF.line : brush ? 1.9 : DR.line }
    var hair: Double { wire ? WF.fine : brush ? 1.2 : DR.hair }

    /// Kit colours by name, with an optional alpha ("ink@0.4"). Shared: ink accent face side paper white mid dim. Drafting adds accentSide;
    /// Airbrush adds blue orange salmon skin yellow lime green red pink violet teal brown.
    func color(_ name: String) -> Color? {
        let bits = name.split(separator: "@"), a = bits.count > 1 ? Double(bits[1]) ?? 1 : 1
        let base: Color
        switch bits.first ?? "" {
        case "ink": base = ink
        case "accent": base = accent
        case "accentSide": base = wire ? WF.accent.opacity(0.6) : brush ? AB.orange : DR.accentSide
        case "face": base = wire ? WF.paper : brush ? AB.paper : DR.face
        case "side": base = wire ? WF.ink.opacity(0.09) : brush ? AB.ink.opacity(0.07) : DR.side
        case "paper": base = paper
        case "white": base = .white
        case "mid": base = ink.opacity(0.55)
        case "dim": base = ink.opacity(0.28)
        case "blue": base = AB.blue
        case "orange": base = AB.orange
        case "salmon": base = AB.salmon
        case "skin": base = AB.skin
        case "yellow": base = AB.yellow
        case "lime": base = AB.lime
        case "green": base = AB.green
        case "red": base = AB.red
        case "pink": base = AB.pink
        case "violet": base = AB.violet
        case "teal": base = AB.teal
        case "brown": base = AB.brown
        default: return nil
        }
        return a == 1 ? base : base.opacity(a)
    }

    /// A fill: a colour name, or "vg:orange:salmon" for a top to bottom gradient across `rect` (Airbrush).
    func shading(_ name: String, in rect: CGRect) -> GraphicsContext.Shading? {
        let bits = name.split(separator: ":").map(String.init)
        if bits.count == 3, bits[0] == "vg", let a = color(bits[1]), let b = color(bits[2]) {
            return AB.vgrad(a, b, y0: rect.minY, y1: rect.maxY)
        }
        return color(name).map { .color($0) }
    }

    // MARK: stroking

    /// Outlines `path`, drawn on from its start by `p` (0...1). Airbrush inks it by hand: a wobble that boils, and `offset` slides the line off
    /// its colour. `seed` keeps each shape's wobble its own.
    func stroke(_ g: inout GraphicsContext, _ path: Path, p: Double, width: Double? = nil, color: Color? = nil, dash: [CGFloat] = [],
                seed: Int = 0, clock: Double = 0, offset: CGSize = .zero) {
        guard p > 0 else { return }
        let col = color ?? ink
        switch style {
        case .wireframe:
            g.stroke(path.trimmedPath(from: 0, to: BP.cl(p)), with: .color(col),
                     style: StrokeStyle(lineWidth: width ?? WF.line, lineCap: .round, lineJoin: .round, dash: dash))
        case .airbrush:
            if !dash.isEmpty {
                g.stroke(path.offsetBy(dx: offset.width, dy: offset.height).trimmedPath(from: 0, to: BP.cl(p)), with: .color(col),
                         style: StrokeStyle(lineWidth: width ?? 1.9, lineCap: .round, lineJoin: .round, dash: dash))
                return
            }
            for (k, sub) in path.subpaths().enumerated() where sub.pts.count > 1 {
                AB.stroke(&g, sub.pts, closed: sub.closed, clock: clock, seed: seed &+ k &* 7, p: p, width: width ?? 1.9, color: col, offset: offset,
                          amp: sub.length < 30 ? 0.3 : 0.6)
            }
        default:
            DR.draw(&g, path, p: p, width: width ?? DR.line, color: col, dash: dash)
        }
    }

    /// Fills `path` with `shading`, faded in by `k`. Airbrush fills the same wobbled outline its `stroke` draws (use the same seed).
    func fill(_ g: inout GraphicsContext, _ path: Path, _ shading: GraphicsContext.Shading, k: Double = 1, seed: Int = 0, clock: Double = 0) {
        guard k > 0.001 else { return }
        var f = g; f.opacity *= k
        if brush {
            for (j, sub) in path.subpaths().enumerated() where sub.pts.count > 2 {
                AB.paint(&f, sub.pts, closed: true, clock: clock, seed: seed &+ j &* 7, p: 1, with: shading, amp: sub.length < 30 ? 0.3 : 0.6)
            }
        } else {
            f.fill(path, with: shading)
        }
    }

    /// Parallel stripes inside `shape`, for shade.
    func hatch(_ g: inout GraphicsContext, _ shape: Path, _ h: SceneHatch) {
        let r = h.band.map { CGRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]) } ?? shape.boundingRect
        if wire { WF.hatch(&g, shape, spacing: h.spacing ?? 3.4, alpha: h.alpha ?? 0.55); return }
        var c = g
        c.clip(to: shape)
        var path = Path(), x = r.minX - r.height
        let step = h.spacing ?? 4
        while x < r.maxX { path.move(to: CGPoint(x: x, y: r.maxY)); path.addLine(to: CGPoint(x: x + r.height, y: r.minY)); x += step }
        c.stroke(path, with: .color(ink.opacity(h.alpha ?? (brush ? 0.3 : 0.35))), lineWidth: hair)
    }

    /// A circle, rect or path element: fill, hatch, outline.
    func shape(_ g: inout GraphicsContext, _ shape: Path, _ e: SceneElement, on: Double, fillIn: Double, seed: Int, clock: Double) {
        let box = shape.boundingRect
        if let name = e.fill, let sh = shading(name, in: box) {
            fill(&g, shape, sh, k: fillIn, seed: seed, clock: clock)
            if let h = e.hatch { var fg = g; fg.opacity *= fillIn; hatch(&fg, shape, h) }
        } else if let h = e.hatch {
            var fg = g; fg.opacity *= fillIn; hatch(&fg, shape, h)
        }
        if e.stroke != "none" {
            // Airbrush: a coloured shape's line sits a little off its colour
            let off: CGSize = brush && e.fill != nil && min(box.width, box.height) > 24 ? CGSize(width: -2.5, height: -2) : .zero
            stroke(&g, shape, p: on, width: e.width, color: color(e.stroke ?? "ink") ?? ink, dash: (e.dash ?? []).map { CGFloat($0) },
                   seed: seed, clock: clock, offset: off)
        }
    }

    // MARK: words

    /// A label with a leader from the dot on the part (`anchor`) to where the words sit (`at`). `\n` breaks the line.
    func label(_ g: inout GraphicsContext, _ text: String, anchor: CGPoint, at: CGPoint, align: HorizontalAlignment, p: Double, size: Double?, seed: Int, clock: Double) {
        switch style {
        case .wireframe:
            guard p > 0 else { return }
            let k = BP.eout(BP.cl(p))
            var c = g; c.opacity *= k
            let lines = text.lowercased().components(separatedBy: "\n"), lh = (size ?? 9.5) * 1.25
            let end = BP.mixp(anchor, at, k)
            var l = Path(); l.move(to: anchor); l.addLine(to: end)
            c.stroke(l, with: .color(WF.ink), lineWidth: WF.fine)
            WF.dot(&c, anchor, r: 1.6)
            for (i, line) in lines.enumerated() {
                let t = c.resolve(Text(line).font(.system(size: size ?? 9.5, weight: .regular, design: .monospaced)).foregroundColor(WF.ink))
                let dy = (Double(i) - Double(lines.count - 1) / 2) * lh
                let ax: UnitPoint = align == .leading ? .leading : align == .trailing ? .trailing : .center
                let pos = CGPoint(x: at.x + (align == .leading ? 6 : align == .trailing ? -6 : 0), y: at.y + dy + (align == .center ? 9 : 0))
                let sz = t.measure(in: CGSize(width: 400, height: 40))
                let bx = align == .leading ? pos.x : align == .trailing ? pos.x - sz.width : pos.x - sz.width / 2
                c.fill(Path(CGRect(x: bx - 3, y: pos.y - sz.height / 2 - 1.5, width: sz.width + 6, height: sz.height + 3)), with: .color(WF.paper))
                c.draw(t, at: pos, anchor: ax)
            }
        case .airbrush:
            let side: Double = align == .center ? 0 : align == .trailing ? -1 : 1
            AB.label(&g, text.uppercased(), anchor: anchor, to: at, side: side, below: at.y >= anchor.y, size: size ?? 19, clock: clock, seed: seed, p: p)
        default:
            DR.label(&g, text, anchor: anchor, at: at, align: align, p: p)
        }
    }

    /// Plain words at the element's own origin (no leader).
    func text(_ g: inout GraphicsContext, _ text: String, size: Double?, weight: String?, align: String?, color: Color?, p: Double, seed: Int, clock: Double) {
        let ax: UnitPoint = align == "leading" ? .leading : align == "trailing" ? .trailing : .center
        switch style {
        case .wireframe:
            var tg = g; tg.opacity *= p
            let r = tg.resolve(Text(text.lowercased()).font(.system(size: size ?? 9.5, weight: weight == "bold" ? .bold : .regular, design: .monospaced)).foregroundColor(color ?? WF.ink))
            tg.draw(r, at: .zero, anchor: ax)
        case .airbrush:
            AB.say(&g, text.uppercased(), .zero, size: size ?? 22, color: color ?? AB.green, alpha: p, anchor: ax, clock: clock, seed: seed)
        default:
            let w: Font.Weight = weight == "bold" ? .bold : weight == "regular" ? .regular : .semibold
            let r = g.resolve(Text(text).font(.system(size: size ?? 8.5, weight: w, design: .rounded)).tracking(0.6).foregroundColor(color ?? DR.ink))
            var tg = g; tg.opacity *= p
            tg.draw(r, at: .zero, anchor: ax)
        }
    }
}

// MARK: - Paths as points

extension Path {
    /// The path's subpaths as polylines (curves sampled about every `step` points), for the hand-inked Airbrush line.
    func subpaths(step: Double = 5) -> [(pts: [CGPoint], closed: Bool, length: Double)] {
        var out: [(pts: [CGPoint], closed: Bool, length: Double)] = []
        var cur: [CGPoint] = []
        func flush(_ closed: Bool) {
            if cur.count > 1 {
                var len = 0.0
                for i in 1..<cur.count { len += hypot(cur[i].x - cur[i - 1].x, cur[i].y - cur[i - 1].y) }
                if closed, cur.count > 2, hypot(cur[0].x - cur[cur.count - 1].x, cur[0].y - cur[cur.count - 1].y) < 0.5 { cur.removeLast() }
                out.append((cur, closed, len))
            }
            cur = []
        }
        func seg(_ a: CGPoint, _ n: Int, _ f: (Double) -> CGPoint) { for i in 1...n { cur.append(f(Double(i) / Double(n))) }; _ = a }
        var pos = CGPoint.zero
        forEach { el in
            switch el {
            case .move(let to): flush(false); cur = [to]; pos = to
            case .line(let to): cur.append(to); pos = to
            case .quadCurve(let to, let c1):
                let a = pos, n = max(3, Int((hypot(c1.x - a.x, c1.y - a.y) + hypot(to.x - c1.x, to.y - c1.y)) / step))
                seg(a, n) { t in CGPoint(x: (1 - t) * (1 - t) * a.x + 2 * (1 - t) * t * c1.x + t * t * to.x, y: (1 - t) * (1 - t) * a.y + 2 * (1 - t) * t * c1.y + t * t * to.y) }
                pos = to
            case .curve(let to, let c1, let c2):
                let a = pos, n = max(4, Int((hypot(c1.x - a.x, c1.y - a.y) + hypot(c2.x - c1.x, c2.y - c1.y) + hypot(to.x - c2.x, to.y - c2.y)) / step))
                seg(a, n) { t in
                    let u = 1 - t
                    return CGPoint(x: u * u * u * a.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * to.x,
                                   y: u * u * u * a.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * to.y)
                }
                pos = to
            case .closeSubpath: if let f = cur.first { pos = f }; flush(true)
            }
        }
        flush(false)
        return out
    }
}
