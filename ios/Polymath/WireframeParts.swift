import SwiftUI

// Wireframe parts for scene topics (2026-11-04). Fine white lines on black, objects as meshes with their far side faintly showing through,
// one pink accent. Standing parts have their bottom centre at the origin; round ones (globe, moon, satellite, clock) are centred on it.
// `on` draws the outlines (and lets meshes in), `fill` fades the black fills that hide what is behind them.

enum WFParts {
    static let names = ["ground", "globe", "moon", "tideEarth", "satellite", "wfPhone", "magnet", "pin", "clock", "tower", "dial", "router", "earbud"]

    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
    private static func ink(_ a: Double) -> Color { WF.ink.opacity(a) }

    static func draw(_ name: String, _ c: inout GraphicsContext, _ q: ScenePart) {
        switch name {
        case "ground":       // a firm line with a dim one under it and dotted ticks below, `w` wide, centred on the origin
            let w = q["w", default: 280]
            var a = Path(); a.move(to: pt(-w / 2, 0)); a.addLine(to: pt(w / 2, 0))
            var b = Path(); b.move(to: pt(-w / 2, 6)); b.addLine(to: pt(w / 2, 6))
            q.line(&c, a, width: WF.line)
            q.line(&c, b, width: WF.fine, color: ink(WF.dim))
            var dots = Path(); var x = -w / 2 + 6
            while x < w / 2 { dots.addEllipse(in: CGRect(x: x - 0.8, y: 11.2, width: 1.6, height: 1.6)); x += 14 }
            var g = c; g.opacity *= BP.cl(q.on * 2 - 1)
            g.fill(dots, with: .color(ink(WF.dim)))
        case "globe":        // centred; r radius, spin radians, tilt radians, pitch (0.3), lat and lon counts, pink 1 = solid pink (a Sun), axis 1 = dashed axis
            let cam = WF.Cam(origin: .zero, scale: 1, pitch: q["pitch", default: 0.3])
            let pink = q["pink", default: 0] > 0.5
            WF.globe(&c, cam, x: 0, y: 0, z: 0, r: q["r", default: 30], spin: q["spin", default: 0] + q["turn", default: 0] * q.clock, tilt: q["tilt", default: 0],
                     lat: Int(q["lat", default: 5]), lon: Int(q["lon", default: 8]), fill: pink ? WF.accent : WF.paper, color: pink ? WF.paper : WF.ink,
                     axis: q["axis", default: 0] > 0.5, alpha: BP.cl(q.on * 1.6))
            if pink {      // a faint ring round a Sun
                let r = q["r", default: 30] + 7
                var g = c; g.opacity *= BP.cl(q.on * 1.6)
                g.stroke(Path(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r)), with: .color(ink(0.4)), lineWidth: WF.fine)
            }
        case "moon": moon(&c, q)
        case "tideEarth": tideEarth(&c, q)
        case "satellite": satellite(&c, q)
        case "wfPhone": phone(&c, q)
        case "magnet": magnet(&c, q)
        case "pin": pin(&c, q)
        case "clock": clock(&c, q)
        case "tower": tower(&c, q)
        case "dial": dial(&c, q)
        case "router": router(&c, q)
        case "earbud": earbud(&c, q)
        default: break
        }
    }

    // MARK: moon

    /// A wire Moon: a mesh globe with a few craters, centred. r radius; spin radians; lit 0...1 fills it pink.
    private static func moon(_ c: inout GraphicsContext, _ q: ScenePart) {
        let r = q["r", default: 20], a = BP.cl(q.on * 1.6)
        let cam = WF.Cam(origin: .zero, scale: 1, pitch: 0.25)
        let lit = q["lit", default: 0]
        WF.globe(&c, cam, x: 0, y: 0, z: 0, r: r, spin: q["spin", default: 0] + q["turn", default: 0] * q.clock, tilt: 0.1, lat: 3, lon: 5,
                 fill: lit > 0.5 ? WF.accent : WF.paper, color: lit > 0.5 ? WF.paper : WF.ink, alpha: a)
        var g = c; g.opacity *= a
        for (dx, dy, rr) in [(-0.35, -0.3, 0.2), (0.3, 0.1, 0.16), (-0.1, 0.42, 0.12)] {
            let cx = dx * r, cy = dy * r, k = rr * r
            g.stroke(Path(ellipseIn: CGRect(x: cx - k, y: cy - k * 0.8, width: 2 * k, height: 1.6 * k)), with: .color(lit > 0.5 ? WF.paper : ink(0.7)),
                     style: StrokeStyle(lineWidth: WF.fine, dash: [2, 1.6]))
        }
    }

    // MARK: Earth from above the north pole, with its sea

    /// Earth seen from above its pole, centred. The sea is a pink shell round a wire disc (concentric rings, meridians turning by `spin`).
    /// `bulge` 0...1 pulls the sea out into two bulges on the line `dir` degrees (0 is right, 180 left: where the Moon is) and its far side.
    /// `sea` 1 (default) makes the sea pink, 0 a pale white. `beach` 1 puts a dot on the shore that rides round with `spin`; `beachAt` its starting angle in degrees. r radius.
    private static func tideEarth(_ c: inout GraphicsContext, _ q: ScenePart) {
        let r = q["r", default: 56], th = q["shell", default: 7], bulge = q["bulge", default: 1], dir = q["dir", default: 180] * .pi / 180
        let spin = q["spin", default: 0], a = BP.cl(q.on * 1.6)
        func outer(_ t: Double) -> Double { r + th + 15 * bulge * (0.5 + 0.5 * cos(2 * (t - dir))) }
        var g = c; g.opacity *= a
        // the sea: a pink ring from the land out to its surface
        var sea = Path()
        for i in 0...90 { let t = 2 * .pi * Double(i) / 90; let v = pt(outer(t) * cos(t), outer(t) * sin(t)); if i == 0 { sea.move(to: v) } else { sea.addLine(to: v) } }
        sea.closeSubpath()
        sea.addEllipse(in: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r))
        g.fill(sea, with: .color(q["sea", default: 1] > 0.5 ? WF.accent : ink(0.2)), style: FillStyle(eoFill: true))
        var surf = Path()
        for i in 0...90 { let t = 2 * .pi * Double(i) / 90; let v = pt(outer(t) * cos(t), outer(t) * sin(t)); if i == 0 { surf.move(to: v) } else { surf.addLine(to: v) } }
        surf.closeSubpath()
        g.stroke(surf, with: .color(WF.ink), lineWidth: WF.line)
        // the land: a black disc with rings and meridians
        let disc = Path(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r))
        g.fill(disc, with: .color(WF.paper))
        var mesh = Path()
        for k in [0.3, 0.6] { mesh.addEllipse(in: CGRect(x: -r * k, y: -r * k, width: 2 * r * k, height: 2 * r * k)) }
        for j in 0..<12 { let t = spin + Double(j) * .pi / 6; mesh.move(to: pt(r * 0.1 * cos(t), r * 0.1 * sin(t))); mesh.addLine(to: pt(r * cos(t), r * sin(t))) }
        g.stroke(mesh, with: .color(ink(0.45)), lineWidth: WF.fine)
        g.stroke(disc, with: .color(WF.ink), lineWidth: WF.line)
        WF.dot(&g, .zero, r: 1.6)
        if q["beach", default: 0] > 0.5 {
            let t = q["beachAt", default: 90] * .pi / 180 + spin
            let p = pt((r + 1) * cos(t), (r + 1) * sin(t))
            g.fill(Path(ellipseIn: CGRect(x: p.x - 3.4, y: p.y - 3.4, width: 6.8, height: 6.8)), with: .color(WF.ink))
            g.stroke(Path(ellipseIn: CGRect(x: p.x - 6.4, y: p.y - 6.4, width: 12.8, height: 12.8)), with: .color(WF.paper), lineWidth: 2.4)
            g.stroke(Path(ellipseIn: CGRect(x: p.x - 6.4, y: p.y - 6.4, width: 12.8, height: 12.8)), with: .color(WF.ink), lineWidth: WF.fine)
        }
    }

    // MARK: satellite

    /// A wire satellite, centred: a box body, two solar panels with grids, and a dish on a mast. `s` scale (1 is about 86 wide), `yaw` degrees
    /// it is turned, `lit` 0...1 turns the dish pink as it transmits.
    private static func satellite(_ c: inout GraphicsContext, _ q: ScenePart) {
        let s = q["s", default: 1], yaw = (q["yaw", default: 28] + q["turn", default: 0] * q.clock) * .pi / 180, a = BP.cl(q.on * 1.6)
        let cam = WF.Cam(origin: .zero, scale: s, pitch: 0.5)
        func P(_ x: Double, _ y: Double, _ z: Double) -> CGPoint { cam.p(x * cos(yaw) + z * sin(yaw), y, -x * sin(yaw) + z * cos(yaw)) }
        func depth(_ x: Double, _ z: Double) -> Double { -x * sin(yaw) + z * cos(yaw) }
        func poly(_ p: [CGPoint]) -> Path { var path = Path(); path.addLines(p); path.closeSubpath(); return path }
        var g = c; g.opacity *= a
        let hx = 8.0, hy = 7.0, hz = 10.0
        // panels, each a flat quad with a grid, drawn back to front around the body
        func panel(_ side: Double) {
            let x0 = side * (hx + 5), x1 = side * (hx + 5 + 34), z0 = -9.0, z1 = 9.0
            let quad = poly([P(x0, 0, z0), P(x1, 0, z0), P(x1, 0, z1), P(x0, 0, z1)])
            g.fill(quad, with: .color(WF.paper))
            var grid = Path()
            for i in 1..<4 { let x = x0 + (x1 - x0) * Double(i) / 4; grid.move(to: P(x, 0, z0)); grid.addLine(to: P(x, 0, z1)) }
            for i in 1..<3 { let z = z0 + (z1 - z0) * Double(i) / 3; grid.move(to: P(x0, 0, z)); grid.addLine(to: P(x1, 0, z)) }
            g.stroke(grid, with: .color(ink(0.4)), lineWidth: WF.fine * 0.9)
            g.stroke(quad, with: .color(WF.ink), lineWidth: WF.line)
            var boom = Path(); boom.move(to: P(side * hx, 0, 0)); boom.addLine(to: P(x0, 0, 0))
            g.stroke(boom, with: .color(WF.ink), lineWidth: WF.line)
        }
        let order = [-1.0, 1.0].sorted { depth($0 * 20, 0) < depth($1 * 20, 0) }
        panel(order[0])
        // body: hidden faces dim, then the faces toward us on black with white edges
        let v: [[Double]] = [[-hx, -hy, -hz], [hx, -hy, -hz], [hx, hy, -hz], [-hx, hy, -hz], [-hx, -hy, hz], [hx, -hy, hz], [hx, hy, hz], [-hx, hy, hz]]
        let faces: [([Int], [Double])] = [([0, 1, 2, 3], [0, 0, -1]), ([4, 5, 6, 7], [0, 0, 1]), ([0, 3, 7, 4], [-1, 0, 0]), ([1, 2, 6, 5], [1, 0, 0]),
                                          ([3, 2, 6, 7], [0, 1, 0]), ([0, 1, 5, 4], [0, -1, 0])]
        func facing(_ n: [Double]) -> Double { cam.facing(n[0] * cos(yaw) + n[2] * sin(yaw), n[1], -n[0] * sin(yaw) + n[2] * cos(yaw)) }
        for (idx, n) in faces where facing(n) <= 0 { g.stroke(poly(idx.map { P(v[$0][0], v[$0][1], v[$0][2]) }), with: .color(ink(0.2)), lineWidth: WF.fine) }
        for (idx, n) in faces where facing(n) > 0 {
            let f = poly(idx.map { P(v[$0][0], v[$0][1], v[$0][2]) })
            g.fill(f, with: .color(WF.paper)); g.stroke(f, with: .color(WF.ink), lineWidth: WF.line)
        }
        // a stripe and a small plate on the front-facing side
        var band = Path(); band.move(to: P(-hx, 0, hz)); band.addLine(to: P(hx, 0, hz))
        g.stroke(band, with: .color(ink(0.5)), lineWidth: WF.fine)
        panel(order[1])
        // the dish on its mast: a disc seen from a little above, spokes and a feed
        let top = hy, mast = 8.0, dr = 9.0
        var m = Path(); m.move(to: P(0, top, 0)); m.addLine(to: P(0, top + mast, 0))
        g.stroke(m, with: .color(WF.ink), lineWidth: WF.line)
        var dish = Path(), spokes = Path()
        for i in 0...24 { let t = 2 * .pi * Double(i) / 24; let p = P(dr * cos(t), top + mast, dr * sin(t)); if i == 0 { dish.move(to: p) } else { dish.addLine(to: p) } }
        for i in 0..<6 { let t = .pi * Double(i) / 3; spokes.move(to: P(dr * cos(t), top + mast, dr * sin(t))); spokes.addLine(to: P(0, top + mast - 3, 0)) }
        let lit = q["lit", default: 0]
        g.fill(dish, with: .color(WF.paper)); if lit > 0 { var lg = g; lg.opacity *= lit; lg.fill(dish, with: .color(WF.accent)) }
        g.stroke(spokes, with: .color(lit > 0.5 ? WF.paper : ink(0.5)), lineWidth: WF.fine)
        g.stroke(dish, with: .color(WF.ink), lineWidth: WF.line)
    }

    // MARK: phone

    /// A phone standing on its bottom edge, 70 wide and 136 tall, with a slab's thickness behind it, a screen with a faint map grid, side buttons and signal bars.
    /// `bars` 0...4 lights that many; `cross` 0...1 draws a slash through the bars; `pin` 0...1 drops a pink pin on the screen; `glow` 0...1 fills the screen pink.
    private static func phone(_ c: inout GraphicsContext, _ q: ScenePart) {
        let w = 70.0, h = 136.0, dx = 9.0, dy = -7.0, a = BP.cl(q.on * 1.6)
        let r = CGRect(x: -w / 2, y: -h, width: w, height: h)
        var g = c; g.opacity *= a
        let back = Path(roundedRect: r.offsetBy(dx: dx, dy: dy), cornerRadius: 11)
        g.fill(back, with: .color(WF.paper)); g.stroke(back, with: .color(ink(0.55)), lineWidth: WF.fine)
        var join = Path()
        for (x, y) in [(r.maxX - 3, r.minY + 3), (r.maxX - 3, r.maxY - 3), (r.minX + 3, r.minY + 3)] { join.move(to: pt(x, y)); join.addLine(to: pt(x + dx, y + dy)) }
        g.stroke(join, with: .color(ink(0.55)), lineWidth: WF.fine)
        for (y0, hh) in [(-100.0, 16.0), (-78.0, 12.0)] {       // side buttons on the left
            let b = Path(roundedRect: CGRect(x: r.minX - 2.5, y: y0, width: 2.5, height: hh), cornerRadius: 1)
            g.fill(b, with: .color(WF.paper)); g.stroke(b, with: .color(WF.ink), lineWidth: WF.fine)
        }
        let front = Path(roundedRect: r, cornerRadius: 11)
        g.fill(front, with: .color(WF.paper)); g.stroke(front, with: .color(WF.ink), lineWidth: WF.line)
        let sc = r.insetBy(dx: 5, dy: 8)
        let screen = Path(roundedRect: sc, cornerRadius: 6)
        let glow = q["glow", default: 0]
        if glow > 0 { var lg = g; lg.opacity *= glow; lg.fill(screen, with: .color(WF.accent)) }
        var grid = Path()                                  // a faint map grid
        for i in 1..<5 { let x = sc.minX + sc.width * Double(i) / 5; grid.move(to: pt(x, sc.minY + 18)); grid.addLine(to: pt(x, sc.maxY)) }
        for i in 1..<6 { let y = sc.minY + 18 + (sc.height - 18) * Double(i) / 6; grid.move(to: pt(sc.minX, y)); grid.addLine(to: pt(sc.maxX, y)) }
        var gg = g; gg.clip(to: screen)
        gg.stroke(grid, with: .color(ink(glow > 0.5 ? 0.0 : 0.22)), lineWidth: WF.fine * 0.8)
        g.stroke(screen, with: .color(ink(0.8)), lineWidth: WF.fine)
        g.fill(Path(roundedRect: CGRect(x: -9, y: sc.minY + 3, width: 18, height: 5), cornerRadius: 2.5), with: .color(WF.ink))   // the island
        // signal bars at the top left of the screen
        let bars = q["bars", default: 0]
        let base = sc.minY + 13                             // bars sit on this line, left of the island
        for i in 0..<4 {
            let bh = 2.6 + Double(i) * 1.5, bx = sc.minX + 4 + Double(i) * 3.2
            let b = Path(CGRect(x: bx, y: base - bh, width: 2, height: bh))
            if bars > Double(i) + 0.5 { g.fill(b, with: .color(WF.ink)) }
            g.stroke(b, with: .color(ink(bars > Double(i) + 0.5 ? 1 : 0.55)), lineWidth: WF.fine * 0.8)
        }
        let cross = q["cross", default: 0]
        if cross > 0.01 {                                   // a short slash through the bars only, clear of the island
            var s = Path(); s.move(to: pt(sc.minX + 2, base + 1)); s.addLine(to: pt(sc.minX + 2 + 14 * cross, base + 1 - 9.5 * cross))
            g.stroke(s, with: .color(WF.ink), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
        let pinK = BP.eout(q["pin", default: 0])
        if pinK > 0.01 {
            var pg = g; pg.translateBy(x: 0, y: -h * 0.42 - 12 * (1 - pinK)); pg.opacity *= pinK
            drawPin(&pg, size: 9, pinkFill: glow < 0.5)
        }
    }

    // MARK: pin

    private static func drawPin(_ g: inout GraphicsContext, size s: Double, pinkFill: Bool) {
        // a map pin whose point is at the origin
        var p = Path()
        p.move(to: pt(0, 0))
        p.addCurve(to: pt(-s, -s * 1.7), control1: pt(-s * 0.15, -s * 0.5), control2: pt(-s, -s * 1.0))
        p.addArc(center: pt(0, -s * 1.7), radius: s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: pt(0, 0), control1: pt(s, -s * 1.0), control2: pt(s * 0.15, -s * 0.5))
        p.closeSubpath()
        g.fill(p, with: .color(pinkFill ? WF.accent : WF.paper))
        g.stroke(p, with: .color(pinkFill ? WF.ink : WF.ink), lineWidth: WF.line)
        g.fill(Path(ellipseIn: CGRect(x: -s * 0.36, y: -s * 2.06, width: s * 0.72, height: s * 0.72)), with: .color(pinkFill ? WF.paper : WF.ink))
        var base = Path(ellipseIn: CGRect(x: -s * 1.1, y: -s * 0.18, width: s * 2.2, height: s * 0.36))
        base.closeSubpath()
        g.stroke(base, with: .color(ink(0.6)), lineWidth: WF.fine)
    }

    /// A map pin, its point at the origin, `s` its size (9). Pink.
    private static func pin(_ c: inout GraphicsContext, _ q: ScenePart) {
        var g = c; g.opacity *= BP.cl(q.on * 1.6)
        let s = q["s", default: 9]
        drawPin(&g, size: s, pinkFill: q["hollow", default: 0] < 0.5)
    }

    // MARK: magnet

    /// A horseshoe magnet pointing right: bottom of the U at the left, two arms 46 long, poles at the right end. Centred on the origin.
    private static func magnet(_ c: inout GraphicsContext, _ q: ScenePart) {
        var g = c; g.opacity *= BP.cl(q.on * 1.6)
        let arm = 40.0, gap = 11.0, thick = 7.0
        var u = Path()                                         // outer U
        u.move(to: pt(arm, -gap - thick))
        u.addLine(to: pt(-6, -gap - thick))
        u.addArc(center: pt(-6, 0), radius: gap + thick, startAngle: .degrees(-90), endAngle: .degrees(-270), clockwise: true)
        u.addLine(to: pt(arm, gap + thick)); u.addLine(to: pt(arm, gap)); u.addLine(to: pt(-6, gap))
        u.addArc(center: pt(-6, 0), radius: gap, startAngle: .degrees(-270), endAngle: .degrees(-90), clockwise: false)
        u.addLine(to: pt(arm, -gap)); u.closeSubpath()
        g.fill(u, with: .color(WF.paper)); g.stroke(u, with: .color(WF.ink), lineWidth: WF.line)
        for s in [-1.0, 1.0] {                                 // pink poles
            let pole = Path(CGRect(x: arm - 12, y: s > 0 ? gap : -gap - thick, width: 12, height: thick))
            g.fill(pole, with: .color(WF.accent)); g.stroke(pole, with: .color(WF.ink), lineWidth: WF.fine)
        }
        var rib = Path()
        for x in stride(from: -2.0, through: 20, by: 6) { for s in [-1.0, 1.0] { rib.move(to: pt(x, s * (gap + 1.5))); rib.addLine(to: pt(x, s * (gap + thick - 1.5))) } }
        g.stroke(rib, with: .color(ink(0.4)), lineWidth: WF.fine)
    }

    // MARK: clock

    /// A small wire clock, centred: `r` radius, `turn` the hand's angle in turns from 12, `pink` 1 for a pink face (the exact one).
    private static func clock(_ c: inout GraphicsContext, _ q: ScenePart) {
        let r = q["r", default: 16], a = BP.cl(q.on * 1.6), pink = q["pink", default: 0] > 0.5
        var g = c; g.opacity *= a
        let face = Path(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r))
        g.fill(face, with: .color(pink ? WF.accent : WF.paper))
        let col = pink ? WF.paper : WF.ink
        var ticks = Path()
        for i in 0..<12 { let t = Double(i) / 12 * 2 * .pi; let k = i % 3 == 0 ? 0.74 : 0.86; ticks.move(to: pt(r * k * sin(t), -r * k * cos(t))); ticks.addLine(to: pt(r * 0.94 * sin(t), -r * 0.94 * cos(t))) }
        g.stroke(ticks, with: .color(col.opacity(0.8)), lineWidth: WF.fine)
        g.stroke(face, with: .color(WF.ink), lineWidth: WF.line)
        let t = q["turn", default: 0] * 2 * .pi
        var h = Path(); h.move(to: .zero); h.addLine(to: pt(r * 0.7 * sin(t), -r * 0.7 * cos(t)))
        g.stroke(h, with: .color(col), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        var h2 = Path(); h2.move(to: .zero); h2.addLine(to: pt(r * 0.45 * sin(t * 0.083 + 1), -r * 0.45 * cos(t * 0.083 + 1)))
        g.stroke(h2, with: .color(col), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        WF.dot(&g, .zero, r: 1.4, alpha: 1)
    }

    // MARK: tower

    /// A mobile phone mast, standing on the origin, 110 tall: a lattice of crossed wires tapering up to three antennas. `fade` 0...1 dims it (for "no signal").
    private static func tower(_ c: inout GraphicsContext, _ q: ScenePart) {
        var g = c; g.opacity *= BP.cl(q.on * 1.6) * (1 - 0.7 * q["dim", default: 0])
        let h = 110.0
        var legs = Path()
        legs.move(to: pt(-16, 0)); legs.addLine(to: pt(-3, -h)); legs.move(to: pt(16, 0)); legs.addLine(to: pt(3, -h))
        g.stroke(legs, with: .color(WF.ink), lineWidth: WF.line)
        var lat = Path()
        for i in 0..<6 {
            let y0 = -Double(i) * h / 6, y1 = -Double(i + 1) * h / 6
            let x0 = 16 - 13 * Double(i) / 6, x1 = 16 - 13 * Double(i + 1) / 6
            lat.move(to: pt(-x0, y0)); lat.addLine(to: pt(x1, y1)); lat.move(to: pt(x0, y0)); lat.addLine(to: pt(-x1, y1))
            lat.move(to: pt(-x1, y1)); lat.addLine(to: pt(x1, y1))
        }
        g.stroke(lat, with: .color(ink(0.55)), lineWidth: WF.fine)
        for dx in [-8.0, 0, 8] {
            let b = Path(roundedRect: CGRect(x: dx - 2.5, y: -h - 16, width: 5, height: 16), cornerRadius: 1.5)
            g.fill(b, with: .color(WF.paper)); g.stroke(b, with: .color(WF.ink), lineWidth: WF.fine)
        }
    }

    // MARK: dial

    /// A radio dial lying flat, centred on the origin: a slab `w` wide (294) and `h` (52) tall with a back slab behind it and `n` (40) fine ticks, every fifth longer.
    /// `ticks` 0...1 how many ticks are drawn (left to right); `wifi` 0...1 a hatched block over the left quarter (a Wi-Fi network); `chanOn` 0...1 a pink channel
    /// at `chan` 0...1 along the ticks, with a pointer above it; `hit` 0...1 hollows that channel and crosses it (it landed on Wi-Fi); `piece` 0...1 a small pink square under the channel (below the dial's Wi-Fi block).
    private static func dial(_ c: inout GraphicsContext, _ q: ScenePart) {
        let w = q["w", default: 294], h = q["h", default: 52], dx = 7.0, dy = -6.0, n = Int(q["n", default: 40]), a = BP.cl(q.on * 1.6)
        var g = c; g.opacity *= a
        let r = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
        let back = Path(roundedRect: r.offsetBy(dx: dx, dy: dy), cornerRadius: 7)
        g.fill(back, with: .color(WF.paper)); g.stroke(back, with: .color(ink(0.55)), lineWidth: WF.fine)
        var join = Path()
        for (x, y) in [(r.maxX - 3, r.minY + 3), (r.maxX - 3, r.maxY - 3), (r.minX + 3, r.minY + 3)] { join.move(to: pt(x, y)); join.addLine(to: pt(x + dx, y + dy)) }
        g.stroke(join, with: .color(ink(0.55)), lineWidth: WF.fine)
        let front = Path(roundedRect: r, cornerRadius: 7)
        g.fill(front, with: .color(WF.paper)); g.stroke(front, with: .color(WF.ink), lineWidth: WF.line)
        let x0 = -w / 2 + 8, span = w - 16, step = span / Double(n)
        func tx(_ i: Int) -> Double { x0 + (Double(i) + 0.5) * step }
        let shown = Int((q["ticks", default: 0] * Double(n)).rounded())
        var ticks = Path()
        for i in 0..<shown { let hh = i % 5 == 0 ? h * 0.3 : h * 0.18; ticks.move(to: pt(tx(i), -hh)); ticks.addLine(to: pt(tx(i), hh)) }
        g.stroke(ticks, with: .color(ink(0.8)), lineWidth: WF.fine)
        let wifi = BP.cl(q["wifi", default: 0])
        if wifi > 0.01 {
            let bw = span * 0.26
            let blk = CGRect(x: x0 - 4, y: -h / 2 - 12, width: bw + 8, height: h + 24)
            var wg = g; wg.opacity *= wifi
            wg.fill(Path(roundedRect: blk, cornerRadius: 3), with: .color(WF.paper.opacity(0.7)))
            var hatch = Path(); var hx = blk.minX - blk.height
            while hx < blk.maxX { hatch.move(to: pt(hx, blk.maxY)); hatch.addLine(to: pt(hx + blk.height, blk.minY)); hx += 5.5 }
            var hg = wg; hg.clip(to: Path(roundedRect: blk, cornerRadius: 3))
            hg.stroke(hatch, with: .color(ink(0.55)), lineWidth: WF.fine)
            wg.stroke(Path(roundedRect: blk, cornerRadius: 3), with: .color(WF.ink), lineWidth: WF.line)
        }
        let on = BP.cl(q["chanOn", default: 0])
        if on > 0.01 {
            var cg = g; cg.opacity *= on
            let cx = x0 + step / 2 + BP.cl(q["chan", default: 0]) * (span - step)
            let hit = BP.cl(q["hit", default: 0])
            let col = CGRect(x: cx - step * 0.45, y: -h / 2 + 3, width: step * 0.9, height: h - 6)
            if hit < 0.5 {
                cg.fill(Path(col), with: .color(WF.accent))
            } else {
                cg.fill(Path(col), with: .color(WF.paper))
                cg.stroke(Path(col), with: .color(WF.accent), lineWidth: WF.line)
                var x = Path(); let m = 6.0
                x.move(to: pt(cx - m, -m)); x.addLine(to: pt(cx + m, m)); x.move(to: pt(cx - m, m)); x.addLine(to: pt(cx + m, -m))
                cg.stroke(x, with: .color(WF.accent), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
            var ptr = Path(); ptr.move(to: pt(cx, -h / 2 - 1)); ptr.addLine(to: pt(cx - 4, -h / 2 - 9)); ptr.addLine(to: pt(cx + 4, -h / 2 - 9)); ptr.closeSubpath()
            cg.fill(ptr, with: .color(WF.accent))
            let piece = BP.cl(q["piece", default: 0])
            if piece > 0.01 {
                var pg = cg; pg.opacity *= piece
                pg.fill(Path(roundedRect: CGRect(x: cx - 7, y: h / 2 + 15, width: 14, height: 14), cornerRadius: 3), with: .color(WF.accent))
            }
        }
    }

    // MARK: router

    /// A Wi-Fi box standing on the origin, 62 wide and 24 tall with a back slab, three antennas (the middle one taller) and a row of lights. `lit` 0...1 turns the lights white.
    private static func router(_ c: inout GraphicsContext, _ q: ScenePart) {
        var g = c; g.opacity *= BP.cl(q.on * 1.6)
        let w = 62.0, h = 24.0, dx = 8.0, dy = -6.0
        let r = CGRect(x: -w / 2, y: -h, width: w, height: h)
        for (ax, ah) in [(-20.0, 30.0), (0.0, 38.0), (20.0, 30.0)] {          // antennas stand behind the box
            var s = Path(); s.move(to: pt(ax + dx * 0.6, -h + dy * 0.6)); s.addLine(to: pt(ax + dx * 0.6, -h + dy * 0.6 - ah))
            g.stroke(s, with: .color(WF.ink), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            g.stroke(s, with: .color(WF.paper), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
        }
        let back = Path(roundedRect: r.offsetBy(dx: dx, dy: dy), cornerRadius: 4)
        g.fill(back, with: .color(WF.paper)); g.stroke(back, with: .color(ink(0.55)), lineWidth: WF.fine)
        var join = Path()
        for (x, y) in [(r.maxX - 2, r.minY + 2), (r.maxX - 2, r.maxY - 2), (r.minX + 2, r.minY + 2)] { join.move(to: pt(x, y)); join.addLine(to: pt(x + dx, y + dy)) }
        g.stroke(join, with: .color(ink(0.55)), lineWidth: WF.fine)
        let front = Path(roundedRect: r, cornerRadius: 4)
        g.fill(front, with: .color(WF.paper)); g.stroke(front, with: .color(WF.ink), lineWidth: WF.line)
        let lit = BP.cl(q["lit", default: 0])
        for i in 0..<4 {
            let p = pt(r.minX + 10 + Double(i) * 8, -h / 2)
            let d = Path(ellipseIn: CGRect(x: p.x - 1.8, y: p.y - 1.8, width: 3.6, height: 3.6))
            g.fill(d, with: .color(WF.ink.opacity(0.25 + 0.75 * lit)))
            g.stroke(d, with: .color(WF.ink), lineWidth: WF.fine * 0.8)
        }
        var vent = Path(); for i in 0..<3 { let y = -h / 2 - 4 + Double(i) * 4; vent.move(to: pt(r.maxX - 16, y)); vent.addLine(to: pt(r.maxX - 6, y)) }
        g.stroke(vent, with: .color(ink(0.5)), lineWidth: WF.fine)
    }

    // MARK: earbud

    /// An earbud standing on the origin, 14 wide and 36 tall: a round bud with a mesh grille, a flat back disc behind it and a stem. `glow` 0...1 fills the grille pink.
    private static func earbud(_ c: inout GraphicsContext, _ q: ScenePart) {
        var g = c; g.opacity *= BP.cl(q.on * 1.6)
        let stem = Path(roundedRect: CGRect(x: -3, y: -24, width: 6, height: 24), cornerRadius: 3)
        g.fill(stem, with: .color(WF.paper)); g.stroke(stem, with: .color(WF.ink), lineWidth: WF.line)
        let back = Path(ellipseIn: CGRect(x: -7 + 4, y: -36 - 3, width: 14, height: 14))
        g.fill(back, with: .color(WF.paper)); g.stroke(back, with: .color(ink(0.55)), lineWidth: WF.fine)
        let bud = Path(ellipseIn: CGRect(x: -9, y: -35, width: 18, height: 18))
        g.fill(bud, with: .color(WF.paper)); g.stroke(bud, with: .color(WF.ink), lineWidth: WF.line)
        let grille = Path(ellipseIn: CGRect(x: -4.5, y: -30.5, width: 9, height: 9))
        let glow = BP.cl(q["glow", default: 0])
        if glow > 0.01 { var gg = g; gg.opacity *= glow; gg.fill(grille, with: .color(WF.accent)) }
        g.stroke(grille, with: .color(ink(0.7)), lineWidth: WF.fine)
        var mesh = Path(); mesh.move(to: pt(-4, -26)); mesh.addLine(to: pt(4, -26)); mesh.move(to: pt(0, -30)); mesh.addLine(to: pt(0, -22))
        g.stroke(mesh, with: .color(ink(0.5)), lineWidth: WF.fine * 0.8)
    }
}
