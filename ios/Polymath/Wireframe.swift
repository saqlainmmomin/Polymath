import SwiftUI

// Wireframe style: a 3D wire illustrator on black. Fine white lines only, objects as wire meshes (globes with latitude and longitude,
// surfaces of revolution), long thin guide lines running off the page, lowercase monospaced labels on short horizontal leaders, and
// ONE pastel pink accent as a solid fill on the thing that matters. The far side of a mesh shows faintly through. Motion is slow and
// orbital: lines draw on, meshes turn. Same 343 x 320 design space and timing shell as the other styles (`BlueprintStage`).

enum WF {
    static let paper = Color(hex: 0x09090A)
    static let ink = Color.white
    static let accent = Color(hex: 0xF2A9F2)
    static let line = 0.9, fine = 0.55
    static let backAlpha = 0.16     // how faintly a mesh's far side shows

    /// An orthographic camera tilted down onto the ground plane: x right, y up, z toward the viewer.
    struct Cam {
        var origin: CGPoint
        var scale: Double = 1
        var pitch: Double = 0.42     // radians the camera looks down by

        func p(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + (z * sin(pitch) - y * cos(pitch)) * scale)
        }
        /// How far toward the viewer a direction points: above 0 faces us.
        func facing(_ x: Double, _ y: Double, _ z: Double) -> Double { z * cos(pitch) + y * sin(pitch) }
    }

    /// Strokes `path` drawn on from its start: `p` 0...1.
    static func draw(_ c: inout GraphicsContext, _ path: Path, p: Double, width: Double = line, alpha: Double = 1, dash: [CGFloat] = []) {
        guard p > 0, alpha > 0 else { return }
        c.stroke(path.trimmedPath(from: 0, to: BP.cl(p)), with: .color(ink.opacity(alpha)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
    }

    /// A wire globe: `lat` rings and `lon` meridians, spun about its own axis by `spin` and leaning by `tilt` (radians, toward +x).
    /// The near side is bright, the far side faint. `fill` paints the disc first (paper to hide what's behind, or the accent).
    static func globe(_ c: inout GraphicsContext, _ cam: Cam, x: Double, y: Double, z: Double, r: Double, spin: Double = 0, tilt: Double = 0,
                      lat: Int = 5, lon: Int = 8, fill: Color? = paper, color: Color = ink, axis: Bool = false, alpha: Double = 1) {
        guard alpha > 0.01 else { return }
        var g = c
        g.opacity = alpha
        let ctr = cam.p(x, y, z), rr = r * cam.scale
        if let fill { g.fill(Path(ellipseIn: CGRect(x: ctr.x - rr, y: ctr.y - rr, width: 2 * rr, height: 2 * rr)), with: .color(fill)) }
        func world(_ phi: Double, _ lam: Double) -> (Double, Double, Double) {
            let bx = cos(phi) * cos(lam + spin), by = sin(phi), bz = cos(phi) * sin(lam + spin)
            return (bx * cos(tilt) - by * sin(tilt), bx * sin(tilt) + by * cos(tilt), bz)
        }
        var front = Path(), back = Path()
        func curve(_ pts: [(Double, Double)]) {
            for i in 1..<pts.count {
                let a = world(pts[i - 1].0, pts[i - 1].1), b = world(pts[i].0, pts[i].1)
                let m = ((a.0 + b.0) / 2, (a.1 + b.1) / 2, (a.2 + b.2) / 2)
                let pa = cam.p(x + r * a.0, y + r * a.1, z + r * a.2), pb = cam.p(x + r * b.0, y + r * b.1, z + r * b.2)
                if cam.facing(m.0, m.1, m.2) >= 0 { front.move(to: pa); front.addLine(to: pb) } else { back.move(to: pa); back.addLine(to: pb) }
            }
        }
        for i in 1...lat {
            let phi = -Double.pi / 2 + .pi * Double(i) / Double(lat + 1)
            var ring: [(Double, Double)] = []
            for k in 0...48 { ring.append((phi, 2 * Double.pi * Double(k) / 48)) }
            curve(ring)
        }
        for j in 0..<lon {
            let lam = .pi * Double(j) / Double(lon)
            var pts: [(Double, Double)] = []
            for k in 0...48 { pts.append((-Double.pi / 2 + Double.pi * Double(k) / 48, lam)) }
            for k in 0...48 { pts.append((Double.pi / 2 - Double.pi * Double(k) / 48, lam + Double.pi)) }
            curve(pts)
        }
        g.stroke(back, with: .color(color.opacity(backAlpha)), lineWidth: fine)
        g.stroke(front, with: .color(color), lineWidth: fine)
        g.stroke(Path(ellipseIn: CGRect(x: ctr.x - rr, y: ctr.y - rr, width: 2 * rr, height: 2 * rr)), with: .color(color), lineWidth: line)
        if axis {
            let top = world(.pi / 2, 0), k = 1.45
            var a = Path()
            a.move(to: cam.p(x - r * k * top.0, y - r * k * top.1, z - r * k * top.2)); a.addLine(to: cam.p(x + r * k * top.0, y + r * k * top.1, z + r * k * top.2))
            g.stroke(a, with: .color(color), style: StrokeStyle(lineWidth: fine, dash: [2, 2]))
        }
    }

    /// A lowercase mono label on a short horizontal leader from `anchor`, to the left or right. `p` 0...1 draws it on.
    static func label(_ c: inout GraphicsContext, _ text: String, anchor: CGPoint, length: Double = 26, left: Bool = false, p: Double) {
        guard p > 0 else { return }
        let k = BP.eout(BP.cl(p))
        var g = c
        g.opacity = k
        let end = CGPoint(x: anchor.x + (left ? -length : length) * k, y: anchor.y)
        var l = Path(); l.move(to: anchor); l.addLine(to: end)
        g.stroke(l, with: .color(ink), lineWidth: fine)
        let t = g.resolve(Text(text).font(.system(size: 9.5, weight: .regular, design: .monospaced)).foregroundColor(ink))
        let size = t.measure(in: CGSize(width: 400, height: 40)), at = CGPoint(x: end.x + (left ? -6 : 6), y: end.y)
        let box = CGRect(x: left ? at.x - size.width - 3 : at.x - 3, y: at.y - size.height / 2 - 2, width: size.width + 6, height: size.height + 4)
        g.fill(Path(box), with: .color(paper))      // a knockout, so guide lines never run through the words
        g.draw(t, at: at, anchor: left ? .trailing : .leading)
    }
}

// MARK: - Seasons, card 1 (Wireframe pilot)

/// Earth's orbit seen at a low angle: long guide lines cross at the Sun, a pink disc wrapped in its own wire mesh. A wire Earth, leaning
/// on its axis and turning, starts in front at January, closest, and travels round to the far side at July, farthest. The Sun sits a
/// touch off centre, toward January, as it really does.
struct SeasonsWFFar: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.6, tick: 3.0,
                       label: "A wireframe drawing on black. Earth's path around the Sun, seen from a low angle, with long thin guide lines crossing at the Sun, a pink disc. A small wire globe of Earth, leaning and turning, starts at the front of its path, labelled january, closest, and travels round to the far side, labelled july, farthest. The Sun sits a little off centre, nearer January.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }

    private static let cam = WF.Cam(origin: CGPoint(x: 171.5, y: 150), scale: 1, pitch: 0.58)
    private static let R = 128.0, sunZ = 4.0       // the Sun sits about 3% off centre: Earth is that much closer in January

    private static func earthAt(_ theta: Double) -> (x: Double, z: Double) { (R * cos(theta), R * sin(theta)) }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        let on = BP.pr(t, 0, 1.0)

        // long guide lines through the Sun, running off the page, like a drafting table's axes
        var guides = Path()
        guides.move(to: cam.p(-300, 0, sunZ)); guides.addLine(to: cam.p(300, 0, sunZ))
        guides.move(to: cam.p(-190, 0, -420)); guides.addLine(to: cam.p(190, 0, 420))
        guides.move(to: cam.p(190, 0, -420)); guides.addLine(to: cam.p(-190, 0, 420))
        WF.draw(&c, guides, p: on, width: WF.fine, alpha: 0.4)

        // the orbit: far half first (behind the Sun), near half after
        func arc(_ a0: Double, _ a1: Double) -> Path {
            var p = Path()
            for i in 0...60 { let a = a0 + (a1 - a0) * Double(i) / 60; let e = earthAt(a); let q = cam.p(e.x, 0, e.z); if i == 0 { p.move(to: q) } else { p.addLine(to: q) } }
            return p
        }
        WF.draw(&c, arc(.pi, 2 * .pi), p: on, alpha: 0.85)

        // Earth's position: January (front), round the left side, to July (far side)
        let travel = BP.eio(BP.pr(t, 1.4, 3.0))
        let theta = .pi / 2 + .pi * travel
        let e = earthAt(theta), behind = e.z < sunZ
        let earthIn = BP.pr(t, 0.9, 1.2)
        func earth() { WF.globe(&c, cam, x: e.x, y: 14, z: e.z, r: 14, spin: clock * 0.9, tilt: 0.41, lat: 4, lon: 6, axis: true, alpha: earthIn) }
        if behind { earth() }

        // the Sun: a solid pink disc wrapped in its own fine mesh, popping in
        let sunIn = BP.eout(BP.pr(t, 0.3, 0.8))
        if sunIn > 0 {
            WF.globe(&c, cam, x: 0, y: 22, z: sunZ, r: 22 * sunIn, spin: clock * 0.25, lat: 5, lon: 8, fill: WF.accent, color: WF.paper)
            let ring = cam.p(0, 22, sunZ)
            WF.draw(&c, Path(ellipseIn: CGRect(x: ring.x - 29 * sunIn, y: ring.y - 29 * sunIn, width: 58 * sunIn, height: 58 * sunIn)), p: 1, width: WF.fine, alpha: 0.5)
        }

        WF.draw(&c, arc(0, .pi), p: on, alpha: 0.85)
        if !behind { earth() }

        // a faint ghost where January was, once Earth has moved on
        if travel > 0.08 {
            let j = cam.p(earthAt(.pi / 2).x, 14, earthAt(.pi / 2).z)
            WF.draw(&c, Path(ellipseIn: CGRect(x: j.x - 14, y: j.y - 14, width: 28, height: 28)), p: 1, width: WF.fine, alpha: 0.45, dash: [2, 3])
        }

        // distances, dashed from the Sun, and the labels
        let sunC = cam.p(0, 22, sunZ)
        let jan = cam.p(earthAt(.pi / 2).x, 14, earthAt(.pi / 2).z), jul = cam.p(earthAt(1.5 * .pi).x, 14, earthAt(1.5 * .pi).z)
        var dj = Path(); dj.move(to: CGPoint(x: sunC.x, y: sunC.y + 22)); dj.addLine(to: CGPoint(x: jan.x, y: jan.y - 14))
        WF.draw(&c, dj, p: BP.pr(t, 1.0, 1.4), width: WF.fine, alpha: 0.7, dash: [3, 3])
        WF.label(&c, "january · closest", anchor: CGPoint(x: jan.x + 20, y: jan.y), length: 30, p: BP.pr(t, 1.0, 1.5))
        var dl = Path(); dl.move(to: CGPoint(x: sunC.x, y: sunC.y - 22)); dl.addLine(to: CGPoint(x: jul.x, y: jul.y + 14))
        WF.draw(&c, dl, p: BP.pr(t, 3.0, 3.4), width: WF.fine, alpha: 0.7, dash: [3, 3])
        WF.label(&c, "july · farthest", anchor: CGPoint(x: jul.x + 20, y: jul.y), length: 30, p: BP.pr(t, 3.0, 3.5))
    }
}

// MARK: - More of the kit (from the owner's references): bracket frames, grey levels, end dots, hatching

extension WF {
    /// Three levels of white: the subject, its supports, construction lines.
    static let mid = 0.55, dim = 0.28

    /// A frame of four corner brackets with dotted ticks along the edges, like a viewfinder. `p` draws it on.
    static func frame(_ c: inout GraphicsContext, _ r: CGRect, arm: Double = 14, p: Double) {
        guard p > 0 else { return }
        var b = Path()
        for (x, y, dx, dy) in [(r.minX, r.minY, 1.0, 1.0), (r.maxX, r.minY, -1.0, 1.0), (r.minX, r.maxY, 1.0, -1.0), (r.maxX, r.maxY, -1.0, -1.0)] {
            b.move(to: CGPoint(x: x + dx * arm, y: y)); b.addLine(to: CGPoint(x: x, y: y)); b.addLine(to: CGPoint(x: x, y: y + dy * arm))
        }
        draw(&c, b, p: p, width: line)
        var dots = Path()
        let n = 5
        for i in 1..<n {
            let fx = r.minX + r.width * Double(i) / Double(n), fy = r.minY + r.height * Double(i) / Double(n)
            for q in [CGPoint(x: fx, y: r.minY), CGPoint(x: fx, y: r.maxY), CGPoint(x: r.minX, y: fy), CGPoint(x: r.maxX, y: fy)] {
                dots.addEllipse(in: CGRect(x: q.x - 0.8, y: q.y - 0.8, width: 1.6, height: 1.6))
            }
        }
        var g = c; g.opacity = BP.cl(p * 2 - 1)
        g.fill(dots, with: .color(ink.opacity(mid)))
    }

    /// A small dot at a line's end.
    static func dot(_ c: inout GraphicsContext, _ q: CGPoint, r: Double = 1.8, alpha: Double = 1) {
        c.fill(Path(ellipseIn: CGRect(x: q.x - r, y: q.y - r, width: 2 * r, height: 2 * r)), with: .color(ink.opacity(alpha)))
    }

    /// Parallel stripes inside `shape` at `angle` (radians from horizontal), `spacing` apart.
    static func hatch(_ c: inout GraphicsContext, _ shape: Path, spacing: Double = 3.2, angle: Double = .pi / 4, width: Double = fine, alpha: Double = 0.8, color: Color = ink) {
        let r = shape.boundingRect.insetBy(dx: -2, dy: -2)
        var g = c
        g.clip(to: shape)
        let d = hypot(r.width, r.height), cx = r.midX, cy = r.midY
        let ux = cos(angle), uy = sin(angle), vx = -uy, vy = ux
        var h = Path(), s = -d / 2
        while s <= d / 2 {
            h.move(to: CGPoint(x: cx + vx * s - ux * d, y: cy + vy * s - uy * d)); h.addLine(to: CGPoint(x: cx + vx * s + ux * d, y: cy + vy * s + uy * d))
            s += spacing
        }
        g.stroke(h, with: .color(color.opacity(alpha)), lineWidth: width)
    }

    /// The Sun as this style draws it: a pink disc wrapped in a fine dark mesh, with a faint ring.
    static func sun(_ c: inout GraphicsContext, at q: CGPoint, r: Double, spin: Double, alpha: Double = 1) {
        guard alpha > 0.01 else { return }
        var g = c; g.opacity = alpha
        let cam = Cam(origin: q, scale: 1, pitch: 0.3)
        globe(&g, cam, x: 0, y: 0, z: 0, r: r, spin: spin, lat: 4, lon: 6, fill: accent, color: paper)
        g.stroke(Path(ellipseIn: CGRect(x: q.x - r - 7, y: q.y - r - 7, width: 2 * r + 14, height: 2 * r + 14)), with: .color(ink.opacity(0.4)), lineWidth: fine)
    }

    static func text(_ c: inout GraphicsContext, _ s: String, at q: CGPoint, anchor: UnitPoint = .center, size: Double = 9.5, alpha: Double = 1) {
        guard alpha > 0 else { return }
        var g = c; g.opacity = alpha
        g.draw(g.resolve(Text(s).font(.system(size: size, weight: .regular, design: .monospaced)).foregroundColor(ink)), at: q, anchor: anchor)
    }
}

// MARK: - Seasons, card 2: only about 3 percent farther

/// Inside a bracket frame: the Sun at the left and two measuring rods out to Earth, January's 100 steps and July's 103, the three extra
/// steps in pink. Below, one wire Earth at a single distance: its north half labelled canada, winter, its south half australia, summer.
struct SeasonsWFSteps: View {
    let active: Bool
    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 1.9,
                       label: "A wireframe drawing on black inside a frame of corner brackets. The Sun, a pink disc, at the left, and two measuring rods out to Earth: January's is 100 steps long, July's is 103, with the three extra steps in pink, about 3 percent. Below, one Earth at a single distance from the Sun, with its north half labelled Canada, winter, and its south half Australia, summer.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        WF.frame(&c, CGRect(x: 18, y: 22, width: 307, height: 270), p: BP.pr(t, 0, 0.6))
        let sunQ = pt(48, 92)
        WF.sun(&c, at: sunQ, r: 15, spin: clock * 0.3, alpha: BP.pr(t, 0.2, 0.5))

        // two rods: 10 marks of 10 steps; July's runs on 3 steps more, in pink
        let x0 = 72.0, unit = 2.0
        for (row, y, steps, name) in [(0, 74.0, 100.0, "january · 100 steps"), (1, 112.0, 103.0, "july · 103 steps")] {
            let grow = BP.eio(BP.pr(t, 0.5 + 0.25 * Double(row), 1.5 + 0.25 * Double(row)))
            let len = 100 * unit * grow
            var rod = Path(); rod.move(to: pt(x0, y)); rod.addLine(to: pt(x0 + len, y))
            WF.draw(&c, rod, p: 1, width: WF.line, alpha: grow > 0 ? 1 : 0)
            var ticks = Path()
            for i in 0...10 where Double(i) * 20 <= len { let x = x0 + Double(i) * 20; ticks.move(to: pt(x, y - (i % 5 == 0 ? 5 : 3))); ticks.addLine(to: pt(x, y + (i % 5 == 0 ? 5 : 3))) }
            c.stroke(ticks, with: .color(WF.ink.opacity(WF.mid)), lineWidth: WF.fine)
            var end = x0 + len
            if steps > 100 {
                let extra = BP.eout(BP.pr(t, 1.9, 2.3))
                if extra > 0 {
                    var bar = Path(); bar.move(to: pt(end, y)); bar.addLine(to: pt(end + 3 * unit * extra, y))
                    c.stroke(bar, with: .color(WF.accent), style: StrokeStyle(lineWidth: 4, lineCap: .butt))
                    end += 3 * unit * extra
                    WF.text(&c, "+3%", at: pt(end - 3, y - 13), alpha: extra)
                }
            }
            if grow >= 1 {
                let cam = WF.Cam(origin: pt(end + 13, y), scale: 1, pitch: 0.3)
                WF.globe(&c, cam, x: 0, y: 0, z: 0, r: 9, spin: clock * 0.8, tilt: 0.41, lat: 3, lon: 5)
            }
            WF.text(&c, name, at: pt(x0, y + 13), anchor: .leading, size: 8.5, alpha: BP.pr(t, 0.9 + 0.25 * Double(row), 1.3 + 0.25 * Double(row)) * 0.75)
        }

        // below: one Earth, one distance, two seasons
        let k = BP.pr(t, 2.2, 2.7)
        guard k > 0 else { return }
        let ctr = pt(171.5, 208), r = 40.0
        var line = Path(); line.move(to: pt(sunQ.x, sunQ.y + 22)); line.addLine(to: pt(sunQ.x, ctr.y)); line.addLine(to: pt(ctr.x - r - 6, ctr.y))
        WF.draw(&c, line, p: k, width: WF.fine, alpha: WF.dim, dash: [3, 3])
        let cam = WF.Cam(origin: ctr, scale: 1, pitch: 0.3)
        WF.globe(&c, cam, x: 0, y: 0, z: 0, r: r, spin: clock * 0.5, tilt: 0.41, lat: 5, lon: 8, alpha: k)
        var eq = Path(); eq.move(to: pt(ctr.x - r, ctr.y + 4)); eq.addLine(to: pt(ctr.x + r, ctr.y - 4))
        WF.draw(&c, eq, p: k, width: WF.fine, alpha: 0.7, dash: [2, 2])
        WF.dot(&c, pt(ctr.x - 12, ctr.y - 22), alpha: k); WF.dot(&c, pt(ctr.x + 14, ctr.y + 22), alpha: k)
        WF.label(&c, "canada · winter", anchor: pt(ctr.x - 12, ctr.y - 22), length: 52, left: true, p: BP.pr(t, 2.5, 2.9))
        WF.label(&c, "australia · summer", anchor: pt(ctr.x + 14, ctr.y + 22), length: 40, p: BP.pr(t, 2.7, 3.1))
    }
}

// MARK: - Seasons, card 3: the lean always points the same way

/// Earth's path round the Sun seen from just above its edge. Earth carries its dashed axis, leaning 23 degrees, all the way round, and the
/// lean always points the same way: at June the north half leans toward the Sun, at December, on the far side, away.
struct SeasonsWFLean: View {
    let active: Bool
    var body: some View {
        BlueprintStage(active: active, length: 3.6, tick: 3.0,
                       label: "A wireframe drawing on black. Earth's path round the Sun, seen from just above, with the Sun as a pink disc in the middle. Earth travels round carrying its axis, a dashed line leaning 23 degrees, which always points the same way. At June, on the left, the north half leans toward the Sun; at December, on the right, it leans away.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }
    private static let cam = WF.Cam(origin: CGPoint(x: 171.5, y: 162), scale: 1, pitch: 0.3)
    private static let R = 122.0, tilt = 0.41

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        let on = BP.pr(t, 0, 0.9)
        func arc(_ a0: Double, _ a1: Double) -> Path {
            var p = Path()
            for i in 0...60 { let a = a0 + (a1 - a0) * Double(i) / 60; let q = cam.p(R * cos(a), 0, R * sin(a)); if i == 0 { p.move(to: q) } else { p.addLine(to: q) } }
            return p
        }
        var guide = Path(); guide.move(to: cam.p(-170, 0, 0)); guide.addLine(to: cam.p(170, 0, 0))
        WF.draw(&c, guide, p: on, width: WF.fine, alpha: WF.dim, dash: [3, 3])
        WF.draw(&c, arc(.pi, 2 * .pi), p: on, alpha: WF.mid)

        // Earth goes once round, starting at June (left, theta = pi), via the front, to December (right), and on
        let theta = .pi + .pi * BP.eio(BP.pr(t, 1.0, 3.2))      // half a trip, June (left) round the front to December (right)
        let ex = R * cos(theta), ez = R * sin(theta) * -1
        let behind = ez < 0
        let er = 17.0
        func earthAt(_ x: Double, _ z: Double, _ a: Double) { WF.globe(&c, cam, x: x, y: er, z: z, r: er, spin: clock * 0.9, tilt: tilt, lat: 4, lon: 6, axis: true, alpha: a) }
        // a ghost at June once Earth has left it
        if BP.pr(t, 1.0, 3.2) > 0.1 { earthAt(-R, 0, 0.35) }
        if behind { earthAt(ex, ez, BP.pr(t, 0.6, 1.0)) }
        WF.sun(&c, at: cam.p(0, 22, 0), r: 22, spin: clock * 0.25, alpha: BP.pr(t, 0.3, 0.7))
        WF.draw(&c, arc(0, .pi), p: on, alpha: WF.mid)
        if !behind { earthAt(ex, ez, BP.pr(t, 0.6, 1.0)) }

        // the 23 degree mark on June's Earth: upright dashed, the lean, an arc between
        let j = cam.p(-R, er, 0)
        var up = Path(); up.move(to: CGPoint(x: j.x, y: j.y - er - 14)); up.addLine(to: CGPoint(x: j.x, y: j.y - er - 2))
        WF.draw(&c, up, p: BP.pr(t, 0.8, 1.1), width: WF.fine, alpha: WF.mid, dash: [2, 2])
        var a = Path(); a.addArc(center: j, radius: er + 10, startAngle: .radians(-.pi / 2), endAngle: .radians(-.pi / 2 + tilt), clockwise: false)
        WF.draw(&c, a, p: BP.pr(t, 0.9, 1.2), width: WF.fine, alpha: 0.9)
        WF.text(&c, "23°", at: CGPoint(x: j.x + 12, y: j.y - er - 22), anchor: .leading, alpha: BP.pr(t, 1.0, 1.3))

        let d = cam.p(R, er, 0)
        WF.text(&c, "june", at: CGPoint(x: j.x, y: j.y + er + 16), alpha: BP.pr(t, 0.8, 1.2))
        WF.text(&c, "north leans in", at: CGPoint(x: j.x, y: j.y + er + 28), size: 8.5, alpha: BP.pr(t, 0.9, 1.3) * 0.7)
        let dk = BP.pr(t, 3.1, 3.5)
        WF.text(&c, "december", at: CGPoint(x: d.x, y: d.y + er + 16), alpha: dk)
        WF.text(&c, "north leans away", at: CGPoint(x: d.x - 8, y: d.y + er + 28), size: 8.5, alpha: dk * 0.7)
    }
}

// MARK: - Seasons, card 4: the torch

/// Two torches over one table, drawn as fans of light rays. Straight down, the rays land in a small, bright pink spot. Tilted, the same
/// rays spread into a long patch, paler as the light thins out.
struct SeasonsWFTorch: View {
    let active: Bool
    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 2.4,
                       label: "A wireframe drawing on black: two torches over one table, their light drawn as fans of fine rays. The left torch points straight down and its rays land in a small, bright pink spot. The right torch tilts, and the same rays spread into a long, paler patch.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    /// A torch at `tip` shining along angle `a` from straight down (positive tips the beam to the right), as a short wire tube.
    private static func torch(_ c: inout GraphicsContext, tip: CGPoint, a: Double, p: Double) {
        let dx = sin(a), dy = cos(a), nx = cos(a), ny = -sin(a)
        let back = CGPoint(x: tip.x - dx * 30, y: tip.y - dy * 30)
        var b = Path()
        b.move(to: CGPoint(x: tip.x + nx * 8, y: tip.y + ny * 8)); b.addLine(to: CGPoint(x: back.x + nx * 6, y: back.y + ny * 6))
        b.move(to: CGPoint(x: tip.x - nx * 8, y: tip.y - ny * 8)); b.addLine(to: CGPoint(x: back.x - nx * 6, y: back.y - ny * 6))
        b.move(to: CGPoint(x: back.x + nx * 6, y: back.y + ny * 6)); b.addLine(to: CGPoint(x: back.x - nx * 6, y: back.y - ny * 6))
        WF.draw(&c, b, p: p)
        var rim = Path(); rim.move(to: CGPoint(x: tip.x + nx * 8, y: tip.y + ny * 8)); rim.addLine(to: CGPoint(x: tip.x - nx * 8, y: tip.y - ny * 8))
        WF.draw(&c, rim, p: p, width: WF.line + 0.6)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        let on = BP.pr(t, 0, 0.8)
        // the table: a long slab seen from above the front edge, with dotted ticks
        let top = 214.0
        var table = Path(); table.move(to: pt(14, top)); table.addLine(to: pt(329, top))
        table.move(to: pt(14, top + 22)); table.addLine(to: pt(329, top + 22))
        WF.draw(&c, table, p: on, width: WF.fine, alpha: WF.mid)
        var ticks = Path()
        for i in 0..<20 { let x = 22 + Double(i) * 16; ticks.addEllipse(in: CGRect(x: x - 0.8, y: top + 10.2, width: 1.6, height: 1.6)) }
        c.fill(ticks, with: .color(WF.ink.opacity(WF.dim * BP.cl(on * 2 - 1))))

        let beam = BP.pr(t, 0.6, 1.2)
        // LEFT: straight down, a small bright spot
        let tl = pt(92, 92), half = 0.17
        torch(&c, tip: tl, a: 0, p: on)
        let spotL = (top - tl.y) * tan(half)
        var fanL = Path()
        for i in 0...10 { let f = -1 + 2 * Double(i) / 10; fanL.move(to: tl); fanL.addLine(to: pt(tl.x + f * spotL, tl.y + (top - tl.y) * beam)) }
        c.stroke(fanL, with: .color(WF.ink.opacity(0.7)), lineWidth: WF.fine)
        if beam >= 1 {
            let spot = Path(ellipseIn: CGRect(x: tl.x - spotL, y: top - 5, width: 2 * spotL, height: 10))
            c.fill(spot, with: .color(WF.accent))
            c.stroke(spot, with: .color(WF.ink), lineWidth: WF.line)
        }

        // RIGHT: the same torch tilting; its rays spread into a long patch that pales as it spreads
        let tilt = 0.85 * BP.eio(BP.pr(t, 1.5, 2.6)) * (1 - 0.06 * sin(clock * 0.8))
        let tr = pt(170, 120)      // lower and further left, so the spread patch stays on the table
        torch(&c, tip: tr, a: tilt, p: on)      // body up and to the left, so it shines down and to the right
        let h = top - tr.y
        let xa = tr.x + h * tan(tilt - half), xb = tr.x + h * tan(tilt + half)
        var fanR = Path()
        for i in 0...10 { let f = Double(i) / 10; let x = xa + (xb - xa) * f; fanR.move(to: tr); fanR.addLine(to: pt(tr.x + (x - tr.x) * beam, tr.y + h * beam)) }
        c.stroke(fanR, with: .color(WF.ink.opacity(0.7)), lineWidth: WF.fine)
        if beam >= 1 {
            let w = xb - xa, bright = BP.cl(2 * spotL / max(w, 1))
            let patch = Path(ellipseIn: CGRect(x: xa, y: top - 5, width: w, height: 10))
            c.fill(patch, with: .color(WF.accent.opacity(0.25 + 0.75 * bright)))
            c.stroke(patch, with: .color(WF.ink), lineWidth: WF.line)
        }

        WF.text(&c, "straight", at: pt(92, top + 40), alpha: BP.pr(t, 1.2, 1.6))
        WF.text(&c, "small · bright", at: pt(92, top + 53), size: 8.5, alpha: BP.pr(t, 1.3, 1.7) * 0.7)
        WF.text(&c, "tilted", at: pt(262, top + 40), alpha: BP.pr(t, 2.5, 2.9))
        WF.text(&c, "long · dim", at: pt(262, top + 53), size: 8.5, alpha: BP.pr(t, 2.6, 3.0) * 0.7)
    }
}

// MARK: - Seasons, card 5: longer summer days

/// Earth seen from above the north pole, twice: June and December, sunlight from the top. The night side is striped. London's circle of
/// latitude is drawn round each; the part of it in daylight is pink, about twice as long in June, and London's dot rides round as Earth spins.
struct SeasonsWFDay: View {
    let active: Bool
    var body: some View {
        BlueprintStage(active: active, length: 3.2, tick: 2.4,
                       label: "A wireframe drawing on black: Earth seen from above the north pole, twice, June on the left and December on the right, with sunlight coming from the top. The night side of each is striped. London's circle is drawn round each; the part in daylight is pink, and it is about twice as long in June as in December. A dot for London rides round as Earth spins.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    /// One Earth from above the pole. `june` decides which way the lean tips the day-night line.
    private static func earth(_ c: inout GraphicsContext, at q: CGPoint, r: Double, june: Bool, t: Double, clock: Double, delay: Double) {
        let on = BP.pr(t, delay, delay + 0.8)
        let disc = Path(ellipseIn: CGRect(x: q.x - r, y: q.y - r, width: 2 * r, height: 2 * r))
        // the day-night line seen from above the pole: half an ellipse, r wide and r sin(23 degrees) deep, bulging into the night in June
        let e = r * sin(0.41)
        var night = Path()
        night.move(to: pt(q.x - r, q.y))
        if june {
            night.addArc(center: q, radius: r, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: true)
            for i in 0...30 { let a = Double(i) / 30 * .pi; night.addLine(to: pt(q.x + r * cos(a), q.y + e * sin(a))) }
        } else {
            night.addArc(center: q, radius: r, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: true)
            for i in 0...30 { let a = Double(i) / 30 * .pi; night.addLine(to: pt(q.x + r * cos(a), q.y - e * sin(a))) }
        }
        night.closeSubpath()
        let shade = BP.pr(t, delay + 0.5, delay + 1.1)
        if shade > 0 { var g = c; g.opacity = shade; WF.hatch(&g, night, spacing: 3.4, alpha: 0.55) }
        WF.draw(&c, disc, p: on)
        // latitude rings, faint
        var rings = Path()
        for k in [0.33, 0.66] { rings.addEllipse(in: CGRect(x: q.x - r * k, y: q.y - r * k, width: 2 * r * k, height: 2 * r * k)) }
        WF.draw(&c, rings, p: on, width: WF.fine, alpha: WF.dim)
        WF.dot(&c, q, r: 1.6, alpha: on)

        // London's circle (about 62% of the way out from the pole), its daylight arc in pink: about 16 of 24 hours in June, 8 in December
        let lr = r * 0.62, day = (june ? 16.0 : 8.0) / 24 * 2 * .pi
        WF.draw(&c, Path(ellipseIn: CGRect(x: q.x - lr, y: q.y - lr, width: 2 * lr, height: 2 * lr)), p: on, width: WF.fine, alpha: WF.mid, dash: [2, 2])
        let arcK = BP.eio(BP.pr(t, delay + 1.0, delay + 1.7))
        if arcK > 0 {
            var a = Path()
            a.addArc(center: q, radius: lr, startAngle: .radians(-.pi / 2 - day / 2 * arcK), endAngle: .radians(-.pi / 2 + day / 2 * arcK), clockwise: false)
            c.stroke(a, with: .color(WF.accent), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        }
        // London itself, carried round by the spin (once every few seconds here)
        if t > delay + 1.0 {
            let ang = -.pi / 2 + clock * 0.9
            let lq = pt(q.x + lr * cos(ang), q.y + lr * sin(ang))
            c.fill(Path(ellipseIn: CGRect(x: lq.x - 3, y: lq.y - 3, width: 6, height: 6)), with: .color(WF.ink))
            c.stroke(Path(ellipseIn: CGRect(x: lq.x - 5.5, y: lq.y - 5.5, width: 11, height: 11)), with: .color(WF.ink.opacity(0.6)), lineWidth: WF.fine)
        }
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        // sunlight from the top: parallel rays with dots at their tails
        var rays = Path()
        let rk = BP.pr(t, 0, 0.7)
        for i in 0..<9 { let x = 30 + Double(i) * 35.5; rays.move(to: pt(x, 24)); rays.addLine(to: pt(x, 24 + 46 * rk)); WF.dot(&c, pt(x, 24), r: 1.4, alpha: rk) }
        c.stroke(rays, with: .color(WF.ink.opacity(WF.dim)), style: StrokeStyle(lineWidth: WF.fine, dash: [3, 3]))
        WF.text(&c, "sunlight", at: pt(171.5, 14), size: 8.5, alpha: rk * 0.7)

        let r = 62.0
        earth(&c, at: pt(90, 160), r: r, june: true, t: t, clock: clock, delay: 0.3)
        earth(&c, at: pt(254, 160), r: r, june: false, t: t, clock: clock, delay: 0.6)
        WF.text(&c, "june", at: pt(90, 248), alpha: BP.pr(t, 1.0, 1.4))
        WF.text(&c, "london · long day", at: pt(90, 262), size: 8.5, alpha: BP.pr(t, 2.0, 2.4) * 0.7)
        WF.text(&c, "december", at: pt(254, 248), alpha: BP.pr(t, 1.3, 1.7))
        WF.text(&c, "london · short day", at: pt(254, 262), size: 8.5, alpha: BP.pr(t, 2.3, 2.7) * 0.7)
    }
}
