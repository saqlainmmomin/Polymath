import SwiftUI

// Airbrush style (owner, 2026-11-03, from a tree illustration and a set of loose line drawings): thin near-black line with its colour sitting
// a little off the outline, sprayed blue clouds with grainy edges, soft airbrushed glows, a round simple figure, and green condensed words.
// It sits on a photo of real paper (`PaperTexture`). Same 343 x 320 design space and timing shell as the other styles (`BlueprintStage`), so
// pictures follow the narration's clock too. Keep clear of the bottom-right corner (x > 288, y > 235).

enum AB {
    static let paper = Color(hex: 0xEBE3D7)         // the average colour of the paper photo (paper.jpg)
    static let ink = Color(hex: 0x1B1B1B)
    static let blue = Color(hex: 0x2F86F2)
    static let orange = Color(hex: 0xF7924A)
    static let salmon = Color(hex: 0xF7B494)
    static let skin = Color(hex: 0xF9CDAA)
    static let yellow = Color(hex: 0xFFF23C)
    static let lime = Color(hex: 0xB6E32B)
    static let green = Color(hex: 0x6DB33F)         // the words
    static let line = 2.3
    static let font = "DINCondensed-Bold"           // ships with iOS

    // MARK: time

    /// Picture time `u` and whether the picture is held. Narrated, the voice's clock already is the time: play once and hold the end.
    /// On a swipeable card the picture loops on the stage's free clock; with Reduce Motion that clock stands still, so show the end state.
    static func time(_ t: Double, _ clock: Double, story: Double, narrated: Bool, extra: Double = 1.5) -> (u: Double, held: Bool) {
        if narrated { return (t, false) }
        if clock < t { return (story, true) }
        return (clock.truncatingRemainder(dividingBy: story + extra), false)
    }

    /// 1 while a looping picture plays and holds, then 0 over the last half second of the loop (always 1 when narrated).
    static func fade(_ u: Double, _ story: Double, narrated: Bool) -> Double { narrated ? 1 : 1 - BP.pr(u, story + 1.0, story + 1.5) }

    /// Runs `body` with everything drawn at `alpha` times the opacity already set, so a group can sit inside the picture's overall fade.
    static func group(_ c: inout GraphicsContext, alpha: Double, _ body: (inout GraphicsContext) -> Void) {
        guard alpha > 0.01 else { return }
        var g = c; g.opacity = c.opacity * alpha; body(&g)
    }

    // MARK: line and paint

    /// A thin hand line through `pts`, drawn on by `p`. `offset` slides it off its colour, as in the references.
    static func stroke(_ c: inout GraphicsContext, _ pts: [CGPoint], closed: Bool = false, clock: Double, seed: Int, p: Double = 1,
                       width: Double = line, color: Color = ink, offset: CGSize = .zero, amp: Double = 0.6) {
        guard p > 0.001 else { return }
        var path = Sketch.path(pts, closed: closed, t: clock, seed: seed, amp: amp)
        if offset != .zero { path = path.offsetBy(dx: offset.width, dy: offset.height) }
        c.stroke(p < 1 ? path.trimmedPath(from: 0, to: p) : path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    /// Flat or gradient colour inside the same outline `stroke` would draw (use the same `seed`), faded in by `p`.
    static func paint(_ c: inout GraphicsContext, _ pts: [CGPoint], closed: Bool = true, clock: Double, seed: Int, p: Double = 1,
                      with shading: GraphicsContext.Shading, amp: Double = 0.6) {
        guard p > 0.01 else { return }
        var g = c
        g.opacity = c.opacity * p
        g.fill(Sketch.path(pts, closed: closed, t: clock, seed: seed, amp: amp), with: shading)
    }

    static func vgrad(_ a: Color, _ b: Color, y0: Double, y1: Double) -> GraphicsContext.Shading {
        .linearGradient(Gradient(colors: [a, b]), startPoint: CGPoint(x: 0, y: y0), endPoint: CGPoint(x: 0, y: y1))
    }

    static func oval(_ m: CGPoint, _ rx: Double, _ ry: Double) -> [CGPoint] { Sketch.oval(m, rx, ry, n: 24) }

    /// A rounded rectangle as points, for closed `stroke` and `paint`.
    static func box(_ r: CGRect, radius: Double = 4) -> [CGPoint] {
        let k = min(radius, r.width / 2, r.height / 2)
        let corners: [(CGPoint, Double)] = [(CGPoint(x: r.maxX - k, y: r.minY + k), -90), (CGPoint(x: r.maxX - k, y: r.maxY - k), 0),
                                            (CGPoint(x: r.minX + k, y: r.maxY - k), 90), (CGPoint(x: r.minX + k, y: r.minY + k), 180)]
        var out: [CGPoint] = []
        for (m, a0) in corners {
            for i in 0...3 {
                let a = (a0 + 90 * Double(i) / 3) * .pi / 180
                out.append(CGPoint(x: m.x + k * cos(a), y: m.y + k * sin(a)))
            }
        }
        return out
    }

    /// Straight strokes (no wobble, one path), for texture lines like boards and brick courses.
    static func lines(_ c: inout GraphicsContext, _ segs: [(CGPoint, CGPoint)], color: Color, width: Double = 1.2) {
        var path = Path()
        for s in segs { path.move(to: s.0); path.addLine(to: s.1) }
        c.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// A dashed line from `a` toward `b`, drawn on by `p`; `phase` marches the dashes.
    static func dashPath(_ a: CGPoint, _ b: CGPoint, p: Double, on: Double = 8, off: Double = 6, phase: Double = 0) -> Path {
        var path = Path()
        let len = hypot(b.x - a.x, b.y - a.y), end = len * BP.cl(p)
        guard len > 0.1, end > 0.1 else { return path }
        func at(_ d: Double) -> CGPoint { CGPoint(x: a.x + (b.x - a.x) * d / len, y: a.y + (b.y - a.y) * d / len) }
        var s = -phase.truncatingRemainder(dividingBy: on + off)
        while s < end {
            let from = max(0, s), to = min(end, s + on)
            if to > from { path.move(to: at(from)); path.addLine(to: at(to)) }
            s += on + off
        }
        return path
    }

    /// The two short strokes of an arrow head at `b`, pointing along a to b.
    static func headPath(_ a: CGPoint, _ b: CGPoint, size: Double = 7) -> Path {
        var path = Path()
        let len = hypot(b.x - a.x, b.y - a.y)
        guard len > 0.1 else { return path }
        let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
        path.move(to: CGPoint(x: b.x - ux * size - uy * size * 0.55, y: b.y - uy * size + ux * size * 0.55)); path.addLine(to: b)
        path.addLine(to: CGPoint(x: b.x - ux * size + uy * size * 0.55, y: b.y - uy * size - ux * size * 0.55))
        return path
    }

    // MARK: spray and airbrush

    private static var haloCache: [String: Path] = [:]

    /// The grainy edge of a spray cloud: dots round an ellipse, dense near the core and thinning out. Built once per size, centred on the origin.
    private static func halo(rx: Double, ry: Double, seed: Int) -> Path {
        let key = "\(seed)-\(Int(rx))-\(Int(ry))"
        if let hit = haloCache[key] { return hit }
        var path = Path()
        for i in 0..<Int((rx + ry) * 2.2) {
            let a = Sketch.rnd(seed &+ i &* 3) * 2 * .pi, t = Sketch.rnd(seed &+ i &* 3 &+ 1), r = 0.4 + 0.7 * Sketch.rnd(seed &+ i &* 3 &+ 2)
            let f = 0.72 + 0.46 * t * t
            path.addEllipse(in: CGRect(x: cos(a) * rx * f - r, y: sin(a) * ry * f - r, width: 2 * r, height: 2 * r))
        }
        haloCache[key] = path
        return path
    }

    /// A spray-paint cloud: a solid core, a faint wash and a grainy edge. `grow` scales it about its centre (0...1 to spray it in).
    static func spray(_ c: inout GraphicsContext, at m: CGPoint, rx: Double, ry: Double, color: Color, alpha: Double = 1, grow: Double = 1, seed: Int) {
        guard alpha > 0.01, grow > 0.02 else { return }
        var g = c
        g.opacity = c.opacity * alpha
        g.translateBy(x: m.x, y: m.y)
        g.scaleBy(x: grow, y: grow)
        g.fill(Path(ellipseIn: CGRect(x: -rx * 0.88, y: -ry * 0.88, width: rx * 1.76, height: ry * 1.76)), with: .color(color.opacity(0.3)))
        g.fill(Path(ellipseIn: CGRect(x: -rx * 0.74, y: -ry * 0.74, width: rx * 1.48, height: ry * 1.48)), with: .color(color))
        g.fill(halo(rx: rx, ry: ry, seed: seed), with: .color(color))
    }

    /// A soft airbrushed disc: `inner` at the centre, `outer` from 60% out, then fading to nothing at the edge.
    static func glow(_ c: inout GraphicsContext, at m: CGPoint, r: Double, inner: Color, outer: Color, alpha: Double = 1) {
        guard alpha > 0.01, r > 0.5 else { return }
        var g = c
        g.opacity = c.opacity * alpha
        let shading = GraphicsContext.Shading.radialGradient(Gradient(stops: [.init(color: inner, location: 0), .init(color: outer, location: 0.6), .init(color: outer.opacity(0), location: 1)]),
                                                              center: m, startRadius: 0, endRadius: r)
        g.fill(Path(ellipseIn: CGRect(x: m.x - r, y: m.y - r, width: 2 * r, height: 2 * r)), with: shading)
    }

    // MARK: words

    /// Condensed capitals in green, tilted a hair differently each boil frame.
    static func say(_ c: inout GraphicsContext, _ text: String, _ at: CGPoint, size: Double = 22, color: Color = green, alpha: Double = 1,
                    anchor: UnitPoint = .center, clock: Double, seed: Int) {
        Sketch.say(&c, text, at, size: size, t: clock, seed: seed, font: font, color: color, alpha: alpha, anchor: anchor)
    }

    /// A leader: a thin line from a dot on the part to `end`, then the words. The line draws first (`p` 0...0.6), the words fade in after.
    /// `side` +1 puts the words right of `end`, -1 left, 0 above it (or below it with `below`). `\n` in the text starts a new line.
    static func label(_ c: inout GraphicsContext, _ text: String, anchor: CGPoint, to end: CGPoint, side: Double = 1, below: Bool = false, size: Double = 22,
                      clock: Double, seed: Int, p: Double) {
        guard p > 0.001 else { return }
        stroke(&c, [anchor, end], clock: clock, seed: seed, p: BP.pr(p, 0, 0.6), width: 1.4, amp: 0.4)
        c.fill(Path(ellipseIn: CGRect(x: anchor.x - 2.4, y: anchor.y - 2.4, width: 4.8, height: 4.8)), with: .color(ink.opacity(BP.pr(p, 0, 0.1))))
        let a = BP.pr(p, 0.6, 1)
        let lines = text.components(separatedBy: "\n"), lh = size * 0.95
        for (i, l) in lines.enumerated() {
            if side == 0 {
                let y = below ? end.y + 3 + Double(i) * lh : end.y - 2 - Double(lines.count - 1 - i) * lh
                say(&c, l, CGPoint(x: end.x, y: y), size: size, alpha: a, anchor: below ? .top : .bottom, clock: clock, seed: seed &+ 3 &+ i)
            } else {
                let y = end.y + (Double(i) - Double(lines.count - 1) / 2) * lh
                say(&c, l, CGPoint(x: end.x + side * 5, y: y), size: size, alpha: a, anchor: side > 0 ? .leading : .trailing, clock: clock, seed: seed &+ 3 &+ i)
            }
        }
    }

    // MARK: the figure

    /// A round, simple person standing on `feet`, facing right: a gradient body and a skin-coloured head, each a little off its outline.
    /// `blink` closes the eyes.
    static func person(_ c: inout GraphicsContext, feet f: CGPoint, clock: Double, seed: Int, p: Double = 1, blink: Bool = false) {
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: f.x + x, y: f.y + y) }
        let body = [P(-28, -20), P(-32, -48), P(-30, -78), P(-22, -100), P(-12, -108), P(14, -108), P(24, -96), P(30, -68), P(28, -20)]
        paint(&c, body, clock: clock, seed: seed, p: p, with: vgrad(orange, salmon, y0: f.y - 108, y1: f.y - 20))
        stroke(&c, body, closed: true, clock: clock, seed: seed, p: p, offset: CGSize(width: -4, height: -3))
        let hc = P(1, -130)
        paint(&c, Sketch.oval(hc, 21, 21, n: 24), clock: clock, seed: seed &+ 1, p: p, with: .color(skin))
        stroke(&c, Sketch.oval(hc, 21, 21, n: 24), closed: true, clock: clock, seed: seed &+ 1, p: p, offset: CGSize(width: 3, height: -3))
        if blink {
            stroke(&c, [P(5, -131), P(11, -131)], clock: clock, seed: seed &+ 2, p: p, width: 2, amp: 0.2)
            stroke(&c, [P(15, -131), P(21, -131)], clock: clock, seed: seed &+ 3, p: p, width: 2, amp: 0.2)
        } else if p > 0.5 {
            for x in [8.0, 18.0] { c.fill(Path(ellipseIn: CGRect(x: f.x + x - 2.2, y: f.y - 132 - 2.2, width: 4.4, height: 4.4)), with: .color(ink)) }
        }
        stroke(&c, [P(-10, -154), P(-12, -162)], clock: clock, seed: seed &+ 4, p: p, amp: 0.2)
        stroke(&c, [P(1, -156), P(2, -165)], clock: clock, seed: seed &+ 5, p: p, amp: 0.2)
        stroke(&c, [P(12, -153), P(16, -160)], clock: clock, seed: seed &+ 6, p: p, amp: 0.2)
        stroke(&c, [P(-14, -20), P(-16, 0), P(-4, 0)], clock: clock, seed: seed &+ 7, p: p)
        stroke(&c, [P(14, -20), P(16, 0), P(28, 0)], clock: clock, seed: seed &+ 8, p: p)
    }
}

/// The paper behind an airbrush topic: a photo of real paper (owner's, 2026-11-03), cropped to the sheet and filling the screen.
/// Falls back to the plain paper colour if the file is missing.
struct PaperTexture: View {
    private static let image: UIImage? = Bundle.main.path(forResource: "paper", ofType: "jpg").flatMap { UIImage(contentsOfFile: $0) }

    var body: some View {
        GeometryReader { g in
            ZStack {
                AB.paper
                if let img = Self.image { Image(uiImage: img).resizable().scaledToFill().frame(width: g.size.width, height: g.size.height).clipped() }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
