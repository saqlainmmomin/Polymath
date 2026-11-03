import SwiftUI

// Drafting style: a clean technical illustrator. Plain white paper, crisp near-black outlines with round joins, real objects drawn
// realistically in side or three-quarter view (not blocks), white fills with light hatching for shade, dashed lines for cutaways and
// hidden edges, and ONE solid yellow accent for the thing that matters. Few labels. Lines draw themselves on, then things move calmly.
// Rounded slabs (`slab`, `puck`) are there for diagrams that want them. Same 343 x 320 design space and timing shell as blueprint
// (`BlueprintStage`), so pictures follow the narration's clock too.

enum DR {
    static let paper = Color(hex: 0xFBFBF8)
    static let ink = Color(hex: 0x1C1C1E)
    static let face = Color.white
    static let side = Color(hex: 0xF1F1EE)
    static let accent = Color(hex: 0xF7D25C)
    static let accentSide = Color(hex: 0xE7BE45)
    static let line = 1.25, hair = 0.7

    /// Soft ease used for drops and snaps: a little overshoot, then settle.
    static func snap(_ x: Double) -> Double {
        let p = BP.cl(x)
        return 1 + 2.2 * pow(p - 1, 3) + 1.2 * pow(p - 1, 2)
    }

    // MARK: rounded slab

    /// A point on a rounded rectangle in the floor plane and its outward normal, walking the outline once.
    private struct RimPoint { let x: Double; let y: Double; let nx: Double; let ny: Double }
    /// `back` (if set) is the radius of the two corners at the low-x end, so one end can be round and the other nearly square.
    private static func rim(_ x: Double, _ y: Double, _ w: Double, _ d: Double, _ r: Double, back: Double? = nil, steps: Int = 7) -> [RimPoint] {
        let r = min(r, w / 2, d / 2), rb = min(back ?? r, w / 2, d / 2)
        let corners: [(Double, Double, Double, Double)] = [(x + w - r, y + r, -.pi / 2, r), (x + w - r, y + d - r, 0, r),
                                                           (x + rb, y + d - rb, .pi / 2, rb), (x + rb, y + rb, .pi, rb)]
        var out: [RimPoint] = []
        for (cx, cy, a0, r) in corners {
            for i in 0...steps {
                let a = a0 + .pi / 2 * Double(i) / Double(steps)
                out.append(RimPoint(x: cx + r * cos(a), y: cy + r * sin(a), nx: cos(a), ny: sin(a)))
            }
        }
        return out
    }

    private static func hull(_ pts: [CGPoint]) -> [CGPoint] {
        let p = pts.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x }
        guard p.count > 2 else { return p }
        func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> Double { (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) }
        var lower: [CGPoint] = [], upper: [CGPoint] = []
        for q in p { while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], q) <= 0 { lower.removeLast() }; lower.append(q) }
        for q in p.reversed() { while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], q) <= 0 { upper.removeLast() }; upper.append(q) }
        return Array(lower.dropLast() + upper.dropLast())
    }

    private static func closed(_ pts: [CGPoint]) -> Path { var p = Path(); p.addLines(pts); p.closeSubpath(); return p }

    /// A rounded slab standing on the floor plane at height `z`: (x, y) its corner, w x d its footprint, h its height, r its corner radius.
    /// `seams` adds the stitched look: a dashed line inset on the top and one around the visible sides.
    static func slab(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, z: Double, w: Double, d: Double, h: Double, r: Double,
                     back: Double? = nil, accent: Bool = false, seams: Bool = true, alpha: Double = 1) {
        guard alpha > 0.001 else { return }
        let ring = rim(x, y, w, d, r, back: back)
        let top = ring.map { iso.p($0.x, $0.y, z + h) }, bottom = ring.map { iso.p($0.x, $0.y, z) }
        var g = c
        g.opacity = alpha
        let body = closed(hull(top + bottom))
        g.fill(body, with: .color(accent ? accentSide : side))
        g.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: line, lineJoin: .round))
        let lid = closed(top)
        g.fill(lid, with: .color(accent ? DR.accent : face))
        g.stroke(lid, with: .color(ink), style: StrokeStyle(lineWidth: line, lineJoin: .round))
        guard seams else { return }
        let dash = StrokeStyle(lineWidth: hair, lineCap: .round, dash: [2.6, 2.2])
        let inset = min(0.32, w / 4, d / 4)
        g.stroke(closed(rim(x + inset, y + inset, w - 2 * inset, d - 2 * inset, max(0.05, r - inset), back: back.map { max(0.05, $0 - inset) }).map { iso.p($0.x, $0.y, z + h) }),
                 with: .color(ink.opacity(0.55)), style: dash)
        // the side seam: only where the side faces the viewer (outward normal toward +x+y)
        var s = Path(), pen = false
        for q in ring {
            let pt = iso.p(q.x, q.y, z + h * 0.45)
            if q.nx + q.ny > 0.05 { if pen { s.addLine(to: pt) } else { s.move(to: pt); pen = true } } else { pen = false }
        }
        g.stroke(s, with: .color(ink.opacity(0.5)), style: dash)
    }

    /// The outline of a rounded rectangle lying flat at height z, for marks drawn on a face (a nail, a window).
    static func rimPath(_ iso: Iso, x: Double, y: Double, z: Double, w: Double, d: Double, r: Double, back: Double? = nil) -> Path {
        closed(rim(x, y, w, d, r, back: back).map { iso.p($0.x, $0.y, z) })
    }

    /// A round puck (a slab with fully round corners), centred on (x, y).
    static func puck(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, z: Double, radius: Double, h: Double,
                     accent: Bool = false, seams: Bool = true, alpha: Double = 1) {
        slab(&c, iso, x: x - radius, y: y - radius, z: z, w: 2 * radius, d: 2 * radius, h: h, r: radius, accent: accent, seams: seams, alpha: alpha)
    }

    /// A soft ground shadow under something hovering: an ellipse on the floor that tightens as it comes down.
    static func shadow(_ c: inout GraphicsContext, _ iso: Iso, x: Double, y: Double, z: Double, radius: Double, lift: Double) {
        let k = 1 + lift * 0.25, rr = radius * k
        let pts = rim(x - rr, y - rr, 2 * rr, 2 * rr, rr).map { iso.p($0.x, $0.y, z) }
        c.fill(closed(pts), with: .color(ink.opacity(0.10 / k)))
    }

    // MARK: labels

    /// A small label with a thin leader: a dot on the part, a line to the text. `p` 0...1 draws it on.
    static func label(_ c: inout GraphicsContext, _ text: String, anchor: CGPoint, at: CGPoint, align: HorizontalAlignment = .leading, p: Double) {
        guard p > 0 else { return }
        let k = BP.eout(BP.cl(p))
        var g = c
        g.opacity = k
        let lineEnd = align == .center ? CGPoint(x: at.x, y: at.y - 14) : at      // centred labels hang below the line's end
        var l = Path(); l.move(to: anchor); l.addLine(to: BP.mixp(anchor, lineEnd, k))
        g.stroke(l, with: .color(ink), lineWidth: hair)
        g.fill(Path(ellipseIn: CGRect(x: anchor.x - 1.8, y: anchor.y - 1.8, width: 3.6, height: 3.6)), with: .color(ink))
        let t = g.resolve(Text(text).font(.system(size: 8.5, weight: .semibold, design: .rounded)).tracking(0.6).foregroundColor(ink))
        let anchorPt: UnitPoint = align == .leading ? .leading : align == .trailing ? .trailing : .center
        let off: Double = align == .leading ? 4 : align == .trailing ? -4 : 0
        g.draw(t, at: CGPoint(x: at.x + off, y: at.y), anchor: anchorPt)
    }
}

// MARK: - Line-art helpers

extension DR {
    /// Strokes `path` drawn on from its start: `p` 0...1.
    static func draw(_ c: inout GraphicsContext, _ path: Path, p: Double, width: Double = line, color: Color = ink, dash: [CGFloat] = []) {
        guard p > 0 else { return }
        c.stroke(path.trimmedPath(from: 0, to: BP.cl(p)), with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
    }

    /// Parallel diagonal hatch lines inside `shape`, for shade: `spacing` apart, at 45 degrees.
    static func hatch(_ c: inout GraphicsContext, _ shape: Path, in r: CGRect, spacing: Double = 4, alpha: Double = 0.35) {
        var g = c
        g.clip(to: shape)
        var h = Path(), x = r.minX - r.height
        while x < r.maxX { h.move(to: CGPoint(x: x, y: r.maxY)); h.addLine(to: CGPoint(x: x + r.height, y: r.minY)); x += spacing }
        g.stroke(h, with: .color(ink.opacity(alpha)), lineWidth: hair)
    }
}

// MARK: - Shared superglue drawings

extension DR {
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    /// The superglue tube on its side, in its own frame (about x 22...187, y 89...151): crimped end, body with a dashed cut-away window
    /// of runny yellow glue, nozzle, ridged cap. `cap` moves the cap away (offset, then turn); `tipHard` 0...1 sets the glue in the nozzle.
    static func glueTube(_ c: inout GraphicsContext, on: Double, fill: Double, clock: Double,
                         capOffset: CGSize = .zero, capTurn: Double = 0, tipGlue: Double = 0, tipHard: Double = 0) {
        var body = Path()
        body.move(to: pt(22, 100)); body.addLine(to: pt(44, 100))
        body.addCurve(to: pt(128, 95), control1: pt(70, 89), control2: pt(108, 90))
        body.addCurve(to: pt(147, 110), control1: pt(139, 98), control2: pt(144, 104))
        body.addLine(to: pt(151, 112)); body.addLine(to: pt(151, 128)); body.addLine(to: pt(147, 130))
        body.addCurve(to: pt(128, 145), control1: pt(144, 136), control2: pt(139, 142))
        body.addCurve(to: pt(44, 140), control1: pt(108, 150), control2: pt(70, 151))
        body.addLine(to: pt(22, 140)); body.closeSubpath()
        var g = c; g.opacity = fill
        g.fill(body, with: .color(face))
        hatch(&g, body, in: CGRect(x: 22, y: 132, width: 130, height: 20))          // shade along the underside
        draw(&c, body, p: on)
        var crimp = Path()
        for x in stride(from: 26.0, through: 40, by: 3.5) { crimp.move(to: pt(x, 103)); crimp.addLine(to: pt(x, 137)) }
        draw(&c, crimp, p: on, width: hair)

        // the nozzle: glue reaches into it; when it sets there, it plugs the tip
        let nozzle = Path(roundedRect: CGRect(x: 151, y: 114, width: 9, height: 12), cornerRadius: 1.5)
        g.fill(nozzle, with: .color(face))
        if tipGlue > 0 {
            let plug = Path(CGRect(x: 151, y: 117, width: 9 * tipGlue, height: 6))
            c.fill(plug, with: .color(tipHard > 0.5 ? accentSide : accent))
            if tipHard > 0.2 { hatch(&c, plug, in: plug.boundingRect.insetBy(dx: -3, dy: -3), spacing: 2.2, alpha: 0.6 * tipHard) }
        }
        draw(&c, nozzle, p: on)

        // the cap, which can come off
        var cg = c
        cg.translateBy(x: 173 + capOffset.width, y: 120 + capOffset.height)
        cg.rotate(by: .radians(capTurn))
        let cap = Path(roundedRect: CGRect(x: -14, y: -14, width: 28, height: 28), cornerRadius: 5)
        var cf = cg; cf.opacity = fill
        cf.fill(cap, with: .color(face)); draw(&cg, cap, p: on)
        var ridges = Path()
        for x in stride(from: -9.0, through: 9, by: 4.5) { ridges.move(to: pt(x, -10)); ridges.addLine(to: pt(x, 10)) }   // grip ridges
        draw(&cg, ridges, p: on, width: hair, color: ink.opacity(0.6))

        // the cutaway: a dashed window into the tube, the glue inside always moving, always runny
        let win = Path(roundedRect: CGRect(x: 60, y: 103, width: 66, height: 35), cornerRadius: 7)
        if fill > 0 {
            var w = c; w.opacity = fill
            w.fill(win, with: .color(paper))
            w.clip(to: win)
            var glue = Path()
            glue.move(to: pt(58, 140))
            for i in 0...24 {
                let x = 58 + 70 * Double(i) / 24
                glue.addLine(to: pt(x, 114 + 3.2 * sin(clock * 1.8 + x * 0.06) + 2 * sin(clock * 1.1 - x * 0.03)))
            }
            glue.addLine(to: pt(130, 140)); glue.closeSubpath()
            w.fill(glue, with: .color(accent))
            var glint = Path(); glint.move(to: pt(74, 120)); glint.addQuadCurve(to: pt(90, 119), control: pt(82, 117))
            w.stroke(glint, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        draw(&c, win, p: on, width: hair, dash: [3, 2.5])
    }

    /// A drop of water (or moisture): a small outlined teardrop, white, with a glint. Never yellow: yellow is the glue.
    static func waterDrop(_ c: inout GraphicsContext, at p: CGPoint, size s: Double, alpha: Double = 1) {
        guard alpha > 0.01 else { return }
        var d = Path()
        d.move(to: pt(p.x, p.y - s))
        d.addCurve(to: pt(p.x, p.y + s * 0.7), control1: pt(p.x + s * 0.95, p.y + s * 0.05), control2: pt(p.x + s * 0.75, p.y + s * 0.7))
        d.addCurve(to: pt(p.x, p.y - s), control1: pt(p.x - s * 0.75, p.y + s * 0.7), control2: pt(p.x - s * 0.95, p.y + s * 0.05))
        var g = c; g.opacity = alpha
        g.fill(d, with: .color(face))
        g.stroke(d, with: .color(ink), style: StrokeStyle(lineWidth: hair + 0.25, lineJoin: .round))
        var gl = Path(); gl.move(to: pt(p.x - s * 0.35, p.y + s * 0.05)); gl.addQuadCurve(to: pt(p.x - s * 0.1, p.y + s * 0.4), control: pt(p.x - s * 0.4, p.y + s * 0.35))
        g.stroke(gl, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: hair, lineCap: .round))
    }

    /// A bead of glue sitting on a surface at `base` (its bottom centre): half-width w, height h, yellow (or white for other glue),
    /// glossy while runny, hatched and matt as `hard` goes to 1. `hardFrom` "bottom" sets it from the bottom up.
    static func bead(_ c: inout GraphicsContext, base: CGPoint, w: Double, h: Double, yellow: Bool = true, hard: Double, fromBottom: Bool = false) {
        var b = Path()
        b.move(to: pt(base.x - w, base.y))
        b.addCurve(to: pt(base.x + w, base.y), control1: pt(base.x - w, base.y - h * 1.33), control2: pt(base.x + w, base.y - h * 1.33))
        b.closeSubpath()
        c.fill(b, with: .color(yellow ? (hard > 0.6 && !fromBottom ? accentSide : accent) : face))
        if hard > 0.02 {
            let r = b.boundingRect.insetBy(dx: -2, dy: -2)
            if fromBottom {
                var g = c
                g.clip(to: Path(CGRect(x: r.minX, y: r.maxY - r.height * hard, width: r.width, height: r.height * hard)))
                g.fill(b, with: .color(yellow ? accentSide : side))
                hatch(&g, b, in: r, spacing: 2.6, alpha: 0.5)
            } else {
                hatch(&c, b, in: r, spacing: 2.6, alpha: 0.45 * hard)
            }
        }
        c.stroke(b, with: .color(ink), style: StrokeStyle(lineWidth: line, lineJoin: .round))
        if hard < 0.6 {
            var sh = Path(); sh.move(to: pt(base.x - w * 0.45, base.y - h * 0.55)); sh.addQuadCurve(to: pt(base.x - w * 0.05, base.y - h * 0.82), control: pt(base.x - w * 0.42, base.y - h * 0.85))
            c.stroke(sh, with: .color(yellow ? Color.white.opacity(1 - hard * 1.6) : ink.opacity(0.35 * (1 - hard))), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }
}

// MARK: - Superglue, card 2: two glues, opposite ways to go hard

/// A plank seen from the side with two beads on it. Left, white school glue: drops of water rise out of it and float away, and it
/// shrinks to a hard flat film. Right, yellow superglue: drops of moisture drift down out of the air into it, and it sets hard.
struct GlueDRWater: View {
    let active: Bool
    var body: some View {
        BlueprintStage(active: active, length: 3.6, tick: 2.6,
                       label: "A line drawing on white: a wooden plank seen from the side with two beads of glue on it. On the left, white school glue: little drops of water rise out of it and float away, and it shrinks into a hard flat film. On the right, yellow superglue: little drops of moisture drift down out of the air into it, and it goes hard. Labels say: school glue, water leaves; superglue, water arrives.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        let on = BP.pr(t, 0, 0.8), fill = BP.pr(t, 0.25, 0.7)
        // the plank, with wood grain
        let plank = Path(roundedRect: CGRect(x: 18, y: 196, width: 307, height: 26), cornerRadius: 3)
        var g = c; g.opacity = fill
        g.fill(plank, with: .color(DR.face)); DR.hatch(&g, plank, in: CGRect(x: 18, y: 214, width: 307, height: 8))
        DR.draw(&c, plank, p: on)
        var grain = Path()
        for (y0, k) in [(203.0, 0.0), (209.0, 1.3), (215.0, 2.4)] {
            grain.move(to: pt(30, y0))
            for i in 1...20 { let x = 30 + 283 * Double(i) / 20; grain.addLine(to: pt(x, y0 + 1.6 * sin(x * 0.045 + k))) }
        }
        DR.draw(&c, grain, p: on, width: DR.hair, color: DR.ink.opacity(0.4))
        // a dashed divider
        var div = Path(); div.move(to: pt(171.5, 48)); div.addLine(to: pt(171.5, 184))
        DR.draw(&c, div, p: on, width: DR.hair, color: DR.ink.opacity(0.35), dash: [3, 3])

        guard fill > 0 else { return }
        // LEFT: school glue dries: its water leaves, it shrinks flat and goes hard
        let dry = BP.eio(BP.pr(t, 0.9, 3.0))
        DR.bead(&c, base: pt(92, 196), w: 34 + 6 * dry, h: 26 - 20 * dry, yellow: false, hard: BP.pr(t, 2.4, 3.2))
        for i in 0..<5 {
            let start = 0.8 + 0.42 * Double(i), k = BP.pr(t, start, start + 1.3)
            guard k > 0, k < 1 else { continue }
            let x = 80 + Double(i % 3) * 12 + 6 * sin(clock * 2 + Double(i))
            DR.waterDrop(&c, at: pt(x, 182 - 130 * BP.eout(k)), size: 5, alpha: k < 0.15 ? k / 0.15 : 1 - BP.pr(k, 0.7, 1))
        }
        // RIGHT: superglue: moisture drifts in from the air, it sets hard
        let set = BP.eout(BP.pr(t, 2.2, 2.9))
        DR.bead(&c, base: pt(252, 196), w: 34, h: 26, hard: set)
        for i in 0..<5 {
            let start = 0.6 + 0.3 * Double(i), k = BP.pr(t, start, start + 1.1)
            guard k > 0, k < 1 else { continue }
            let x = 236 + Double(i % 3) * 14 + 5 * sin(clock * 1.6 + Double(i) * 2)
            DR.waterDrop(&c, at: pt(x, 54 + 118 * BP.eio(k)), size: 5, alpha: k < 0.15 ? k / 0.15 : 1 - BP.pr(k, 0.8, 1))
        }
        // arrows: up and away on the left, down and in on the right
        var up = Path(); up.move(to: pt(132, 160)); up.addLine(to: pt(132, 70)); up.move(to: pt(127, 77)); up.addLine(to: pt(132, 70)); up.addLine(to: pt(137, 77))
        var down = Path(); down.move(to: pt(296, 70)); down.addLine(to: pt(296, 160)); down.move(to: pt(291, 153)); down.addLine(to: pt(296, 160)); down.addLine(to: pt(301, 153))
        DR.draw(&c, up, p: BP.pr(t, 0.8, 1.3), width: DR.hair, color: DR.ink.opacity(0.55), dash: [3, 2.5])
        DR.draw(&c, down, p: BP.pr(t, 0.6, 1.1), width: DR.hair, color: DR.ink.opacity(0.55), dash: [3, 2.5])
        let air = c.resolve(Text("AIR").font(.system(size: 8.5, weight: .semibold, design: .rounded)).tracking(0.6).foregroundColor(DR.ink.opacity(0.6)))
        var ac = c; ac.opacity = BP.pr(t, 0.5, 0.9); ac.draw(air, at: pt(296, 58), anchor: .center)

        DR.label(&c, "SCHOOL GLUE\nWATER LEAVES", anchor: pt(92, 222), at: pt(92, 268), align: .center, p: BP.pr(t, 1.4, 1.9))
        DR.label(&c, "SUPERGLUE\nWATER ARRIVES", anchor: pt(252, 222), at: pt(252, 268), align: .center, p: BP.pr(t, 2.4, 2.9))
    }
}

// MARK: - Superglue, card 3: the film of water on your skin

/// A fingertip at the top left with a magnifier on one spot; the big lens shows a cut through the skin: soft ridges, and on top a thin
/// film of water. A yellow drop of glue falls onto the film and goes hard from the bottom up, where it touches the water.
struct GlueDRFilm: View {
    let active: Bool
    var body: some View {
        BlueprintStage(active: active, length: 3.6, tick: 2.5,
                       label: "A line drawing on white. A small fingertip at the top left, and a big magnifying circle showing a cut through its skin: soft ridges, with a thin film of water lying on top of them. A yellow drop of glue falls onto the film and goes hard from the bottom up, where it touches the water. Labels say: water film, glue, skin.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
    private static let lens = (c: CGPoint(x: 196, y: 148), r: 96.0)
    private static func surface(_ x: Double) -> Double { 178 + 5 * sin(x * 0.09) }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        let on = BP.pr(t, 0, 0.8), fill = BP.pr(t, 0.25, 0.7)
        // the small fingertip, pointing left, and the spot being looked at
        var f = Path()
        f.move(to: pt(110, 30)); f.addLine(to: pt(64, 32))
        f.addCurve(to: pt(30, 46), control1: pt(48, 32), control2: pt(35, 37))
        f.addCurve(to: pt(38, 68), control1: pt(25, 55), control2: pt(28, 66))
        f.addCurve(to: pt(76, 71), control1: pt(50, 72), control2: pt(64, 71))
        f.addLine(to: pt(110, 72))
        var g = c; g.opacity = fill
        var skin = f; skin.closeSubpath(); g.fill(skin, with: .color(DR.face))
        DR.draw(&c, f, p: on)
        var nail = Path(); nail.move(to: pt(62, 33)); nail.addCurve(to: pt(36, 41), control1: pt(52, 32), control2: pt(42, 35)); nail.addCurve(to: pt(44, 48), control1: pt(33, 45), control2: pt(38, 48)); nail.addCurve(to: pt(63, 41), control1: pt(52, 48), control2: pt(60, 45)); nail.closeSubpath()
        DR.draw(&c, nail, p: on, width: DR.hair + 0.2)
        let spot = pt(74, 32)
        let ring = Path(ellipseIn: CGRect(x: spot.x - 6, y: spot.y - 6, width: 12, height: 12))
        DR.draw(&c, ring, p: on, width: DR.hair)
        // lines from the spot to the lens
        var cone = Path()
        cone.move(to: pt(spot.x + 4, spot.y - 5)); cone.addLine(to: pt(lens.c.x - 30, lens.c.y - lens.r + 4))
        cone.move(to: pt(spot.x - 3, spot.y + 6)); cone.addLine(to: pt(lens.c.x - lens.r + 6, lens.c.y - 28))
        DR.draw(&c, cone, p: BP.pr(t, 0.3, 0.9), width: DR.hair, color: DR.ink.opacity(0.4), dash: [3, 2.5])

        // the lens
        let circle = Path(ellipseIn: CGRect(x: lens.c.x - lens.r, y: lens.c.y - lens.r, width: 2 * lens.r, height: 2 * lens.r))
        var inside = c; inside.opacity = fill
        inside.fill(circle, with: .color(DR.face))
        inside.clip(to: circle)
        // skin: ridged top, shaded deeper down, a few cell outlines
        var flesh = Path(); flesh.move(to: pt(90, 260))
        for i in 0...40 { let x = 90 + 214 * Double(i) / 40; flesh.addLine(to: pt(x, surface(x))) }
        flesh.addLine(to: pt(304, 260)); flesh.closeSubpath()
        inside.fill(flesh, with: .color(DR.side))
        DR.hatch(&inside, flesh, in: CGRect(x: 90, y: 214, width: 214, height: 46), spacing: 4, alpha: 0.3)
        var cells = Path()
        for (x, y) in [(130.0, 200.0), (165, 206), (200, 199), (236, 205), (270, 200), (148, 222), (218, 224), (252, 226)] { cells.addEllipse(in: CGRect(x: x - 11, y: y - 6, width: 22, height: 12)) }
        inside.stroke(cells, with: .color(DR.ink.opacity(0.25)), lineWidth: DR.hair)
        var top = Path()
        for i in 0...40 { let x = 90 + 214 * Double(i) / 40; let q = pt(x, surface(x)); if i == 0 { top.move(to: q) } else { top.addLine(to: q) } }
        inside.stroke(top, with: .color(DR.ink), lineWidth: DR.line)
        // the water film: a thin band hugging the ridges, gently shimmering
        var film = Path()
        for i in 0...40 { let x = 90 + 214 * Double(i) / 40; let q = pt(x, surface(x) - 4 - 0.6 * sin(clock * 2 + x * 0.2)); if i == 0 { film.move(to: q) } else { film.addLine(to: q) } }
        inside.stroke(film, with: .color(DR.ink.opacity(0.7)), style: StrokeStyle(lineWidth: DR.hair, dash: [2.5, 2]))
        var dots = Path()
        for i in 0..<14 { let x = 100 + Double(i) * 14.5; dots.addEllipse(in: CGRect(x: x - 0.9, y: surface(x) - 2.9, width: 1.8, height: 1.8)) }
        inside.fill(dots, with: .color(DR.ink.opacity(0.5)))
        DR.draw(&c, circle, p: on, width: DR.line + 0.6)

        // the drop: falls into the lens, lands on the film, sets from the bottom up
        let fall = BP.pr(t, 1.5, 2.0), land = pt(200, surface(200) - 4)
        var dc = c; dc.clip(to: circle)
        if t >= 1.5 && fall < 1 {
            let y = 60 + (land.y - 14 - 60) * fall * fall
            var tear = Path()
            tear.move(to: pt(land.x, y - 11))
            tear.addCurve(to: pt(land.x, y + 11), control1: pt(land.x + 11, y + 1), control2: pt(land.x + 9, y + 11))
            tear.addCurve(to: pt(land.x, y - 11), control1: pt(land.x - 9, y + 11), control2: pt(land.x - 11, y + 1))
            dc.fill(tear, with: .color(DR.accent)); dc.stroke(tear, with: .color(DR.ink), lineWidth: DR.line)
        } else if t >= 2.0 {
            let spread = BP.eout(BP.pr(t, 2.0, 2.25))
            DR.bead(&dc, base: land, w: 14 + 12 * spread, h: 22 - 6 * spread, hard: BP.eio(BP.pr(t, 2.4, 3.4)), fromBottom: true)
        }

        DR.label(&c, "WATER FILM", anchor: pt(128, surface(128) - 4), at: pt(66, 268), align: .center, p: BP.pr(t, 0.9, 1.4))
        DR.label(&c, "GLUE", anchor: pt(200, land.y - 10), at: pt(184, 280), align: .center, p: BP.pr(t, 2.6, 3.1))
        DR.label(&c, "SKIN", anchor: pt(262, 222), at: pt(290, 268), align: .center, p: BP.pr(t, 1.0, 1.5))
    }
}

// MARK: - Superglue, card 4: cap on, cap off

/// The tube again, bigger. Drops of moisture drift at it from the right and bounce off the cap: the glue stays runny. Then the cap
/// comes off, the moisture creeps into the nozzle, and the glue in the tip goes hard and plugs it.
struct GlueDRCap: View {
    let active: Bool
    var body: some View {
        BlueprintStage(active: active, length: 3.8, tick: 3.0,
                       label: "A line drawing on white: the tube of superglue on its side, cut away to show runny yellow glue. Little drops of moisture drift at it from the right and bounce off the cap, so the glue stays runny. Then the cap comes off and floats away, the moisture creeps into the nozzle, and the glue in the tip goes hard and blocks it. Labels say: cap, moisture, tip goes hard.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }
    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        let on = BP.pr(t, 0, 0.8), fill = BP.pr(t, 0.25, 0.7)
        // the tube, scaled up and placed left of centre
        let k = 1.35, ox = -18.0, oy = -10.0
        func T(_ p: CGPoint) -> CGPoint { pt(ox + p.x * k, oy + p.y * k) }
        let off = BP.eio(BP.pr(t, 1.5, 2.1))
        var tc = c
        tc.translateBy(x: ox, y: oy); tc.scaleBy(x: k, y: k)
        DR.glueTube(&tc, on: on, fill: fill, clock: clock,
                    capOffset: CGSize(width: 70 * off, height: -60 * off), capTurn: 0.6 * off,
                    tipGlue: 1, tipHard: BP.eout(BP.pr(t, 2.7, 3.4)))
        guard fill > 0 else { return }

        // moisture: before the cap comes off, drops drift in and bounce back; after, they drift into the open tip
        let tip = T(pt(160, 120))
        for i in 0..<4 {
            let phase = Double(i) * 0.25
            if t < 1.5 {
                let k = BP.pr(t, 0.3 + phase, 1.3 + phase)
                guard k > 0, k < 1 else { continue }
                let hit = pt(T(pt(187, 120)).x + 6, tip.y - 18 + Double(i) * 12)
                let from = pt(330, hit.y - 10 + Double(i) * 4)
                let x = k < 0.6 ? from.x + (hit.x - from.x) * (k / 0.6) : hit.x + 40 * BP.eout((k - 0.6) / 0.4)
                let y = k < 0.6 ? from.y + (hit.y - from.y) * (k / 0.6) : hit.y - 22 * BP.eout((k - 0.6) / 0.4)
                DR.waterDrop(&c, at: pt(x, y), size: 4.5, alpha: k > 0.85 ? (1 - k) / 0.15 : min(1, k * 6))
            } else {
                let k = BP.pr(t, 2.0 + phase * 0.8, 2.9 + phase * 0.8)
                guard k > 0, k < 1 else { continue }
                let from = pt(330, tip.y - 30 + Double(i) * 16)
                let e = BP.eio(k)
                DR.waterDrop(&c, at: pt(from.x + (tip.x + 6 - from.x) * e, from.y + (tip.y - from.y) * e + 3 * sin(clock * 3 + Double(i))),
                             size: 4.5 - 2 * e, alpha: k > 0.85 ? (1 - k) / 0.15 : min(1, k * 6))
            }
        }

        DR.label(&c, "CAP", anchor: T(pt(173 + 70 * off, 106 - 60 * off)), at: pt(T(pt(173, 106)).x + 40 * off, 40), align: .center, p: BP.pr(t, 0.8, 1.2) * (1 - BP.pr(t, 1.4, 1.6)))
        DR.label(&c, "IN THE TUBE\nRUNNY", anchor: T(pt(96, 140)), at: pt(110, 268), align: .center, p: BP.pr(t, 0.9, 1.4))
        DR.label(&c, "OPEN TIP\nGOES HARD", anchor: pt(tip.x, tip.y + 8), at: pt(262, 268), align: .center, p: BP.pr(t, 2.9, 3.4))
    }
}

// MARK: - Superglue, card 1 (Drafting pilot)

/// Left: a squeeze tube of superglue lying on its side, cut away to show the yellow glue inside sloshing, still runny, while a desk
/// calendar beside it flips from May to August. Right: a fingertip seen from the side; a yellow drop falls on it, spreads, and in
/// seconds turns hard and matt, while a stopwatch ticks to three seconds.
struct GlueDRFast: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.6, tick: 2.7,
                       label: "A line drawing on white. On the left, a tube of superglue lies on its side, cut away so you can see the yellow glue inside slowly sloshing, still runny, while a small desk calendar beside it flips from May to August. On the right, a fingertip seen from the side; a yellow drop of glue falls onto it, spreads, and within seconds goes hard and matt, while a stopwatch ticks to three seconds. Labels say: in the tube, runny for months; on your finger, hard in seconds.",
                       draw: { c, t, _, clock in Self.draw(&c, t, clock) })
    }

    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ clock: Double) {
        let on = BP.pr(t, 0, 0.9)          // outlines draw themselves on
        let fill = BP.pr(t, 0.3, 0.8)      // fills follow just behind

        // ── the tube, lying on its side: crimped end on the left, cap on the right
        DR.glueTube(&c, on: on, fill: fill, clock: clock)
        var g = c; g.opacity = fill

        // ── the desk calendar: two rings, a header band, the month, pages flipping over the top
        let months = ["MAY", "JUN", "JUL", "AUG"], flips = [1.1, 1.6, 2.1]
        let shown = flips.filter { t >= $0 + 0.25 }.count
        let cal = CGRect(x: 30, y: 36, width: 56, height: 50)      // top left, clear of the tube's label
        let page = Path(roundedRect: cal, cornerRadius: 4)
        g.fill(page, with: .color(DR.face)); DR.draw(&c, page, p: on)
        var band = Path(); band.move(to: pt(cal.minX, cal.minY + 12)); band.addLine(to: pt(cal.maxX, cal.minY + 12))
        DR.draw(&c, band, p: on)
        for x in [cal.minX + 15, cal.maxX - 15] {
            DR.draw(&c, Path(roundedRect: CGRect(x: x - 2.5, y: cal.minY - 5, width: 5, height: 10), cornerRadius: 2.5), p: on)
        }
        if fill > 0 {
            let m = c.resolve(Text(months[shown]).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(DR.ink))
            var mc = c; mc.opacity = fill
            mc.draw(m, at: pt(cal.midX, cal.minY + 31), anchor: .center)
        }
        for (i, f) in flips.enumerated() where t >= f && t < f + 0.25 {
            let k = BP.eio(BP.pr(t, f, f + 0.25))              // the old page lifts and folds back over the rings
            let h = (cal.height - 12) * (1 - k)
            let sheet = Path(roundedRect: CGRect(x: cal.minX, y: cal.minY + 12, width: cal.width, height: max(1, h)), cornerRadius: 3)
            c.fill(sheet, with: .color(DR.face)); c.stroke(sheet, with: .color(DR.ink), lineWidth: DR.line)
            if h > 20 {
                let m = c.resolve(Text(months[i]).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(DR.ink))
                c.draw(m, at: pt(cal.midX, cal.minY + 12 + h / 2), anchor: .center)
            }
        }

        // ── the fingertip, from the side: coming in from the right edge, nail on top, soft pad underneath
        var finger = Path()
        finger.move(to: pt(350, 124)); finger.addLine(to: pt(262, 128))
        finger.addCurve(to: pt(212, 148), control1: pt(238, 129), control2: pt(219, 136))
        finger.addCurve(to: pt(222, 186), control1: pt(203, 162), control2: pt(206, 181))
        finger.addCurve(to: pt(276, 192), control1: pt(240, 193), control2: pt(259, 192))
        finger.addLine(to: pt(350, 197))
        var ff = c; ff.opacity = fill
        var skin = finger; skin.closeSubpath()
        ff.fill(skin, with: .color(DR.face))
        DR.hatch(&ff, skin, in: CGRect(x: 205, y: 178, width: 150, height: 22))      // shade under the pad
        DR.draw(&c, finger, p: on)
        var nail = Path()
        nail.move(to: pt(258, 129)); nail.addCurve(to: pt(219, 141), control1: pt(242, 128), control2: pt(227, 132))
        nail.addCurve(to: pt(229, 152), control1: pt(215, 147), control2: pt(220, 152))
        nail.addCurve(to: pt(261, 140), control1: pt(242, 151), control2: pt(255, 146))
        nail.closeSubpath()
        ff.fill(nail, with: .color(DR.face)); DR.draw(&c, nail, p: on, width: DR.hair + 0.2)
        var marks = Path()
        marks.move(to: pt(300, 126)); marks.addQuadCurve(to: pt(303, 137), control: pt(304, 131))            // knuckle creases
        marks.move(to: pt(307, 126)); marks.addQuadCurve(to: pt(310, 135), control: pt(311, 130))
        for k in 0..<3 {                                                                                        // a few print lines on the pad
            let y = 174.0 + Double(k) * 4
            marks.move(to: pt(222 + Double(k) * 4, y)); marks.addQuadCurve(to: pt(246 + Double(k) * 3, y + 6), control: pt(232, y + 7))
        }
        DR.draw(&c, marks, p: on, width: DR.hair, color: DR.ink.opacity(0.55))

        // the drop: a teardrop falls onto the finger, spreads into a glossy bead, then sets hard and matt
        let fall = BP.pr(t, 1.3, 1.8), spread = BP.eout(BP.pr(t, 1.8, 2.0)), set = BP.eout(BP.pr(t, 2.2, 2.8))
        let landX = 282.0, landY = 127.3      // on the skin behind the nail
        if t >= 1.3 && fall < 1 {
            let y = 34 + (landY - 12 - 34) * fall * fall
            var tear = Path()
            tear.move(to: pt(landX, y - 9))
            tear.addCurve(to: pt(landX, y + 9), control1: pt(landX + 9, y + 1), control2: pt(landX + 7, y + 9))
            tear.addCurve(to: pt(landX, y - 9), control1: pt(landX - 7, y + 9), control2: pt(landX - 9, y + 1))
            c.fill(tear, with: .color(DR.accent)); c.stroke(tear, with: .color(DR.ink), lineWidth: DR.line)
        } else if t >= 1.8 {
            let wob = (1 - set) * 1.2 * sin((t - 1.8) * 20) * (1 - spread * 0.5)
            let half = 8 + 6 * spread, hgt = 13 - 4 * spread + wob
            var bead = Path()
            bead.move(to: pt(landX - half, landY + 0.5))
            bead.addCurve(to: pt(landX + half, landY - 1), control1: pt(landX - half, landY - hgt * 1.3), control2: pt(landX + half, landY - hgt * 1.3))
            bead.closeSubpath()
            c.fill(bead, with: .color(set > 0.5 ? DR.accentSide : DR.accent))
            if set > 0.3 { DR.hatch(&c, bead, in: bead.boundingRect.insetBy(dx: -2, dy: -2), spacing: 2.6, alpha: 0.45 * set) }   // matt and hard
            c.stroke(bead, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
            if set < 0.6 {                                                                                      // glossy while runny
                var shine = Path(); shine.move(to: pt(landX - half * 0.45, landY - hgt * 0.55)); shine.addQuadCurve(to: pt(landX - 1, landY - hgt * 0.8), control: pt(landX - half * 0.4, landY - hgt * 0.85))
                c.stroke(shine, with: .color(.white.opacity(1 - set * 1.6)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
        }

        // the stopwatch: its hand sweeps to three seconds as the drop sets
        let sw = pt(318, 52), r = 17.0
        let face = Path(ellipseIn: CGRect(x: sw.x - r, y: sw.y - r, width: 2 * r, height: 2 * r))
        g.fill(face, with: .color(DR.face)); DR.draw(&c, face, p: on)
        DR.draw(&c, Path(roundedRect: CGRect(x: sw.x - 3.5, y: sw.y - r - 6, width: 7, height: 5), cornerRadius: 1.5), p: on)
        var ticks = Path()
        for i in 0..<12 { let a = Double(i) / 12 * 2 * .pi; ticks.move(to: pt(sw.x + (r - 4) * sin(a), sw.y - (r - 4) * cos(a))); ticks.addLine(to: pt(sw.x + (r - 2) * sin(a), sw.y - (r - 2) * cos(a))) }
        DR.draw(&c, ticks, p: on, width: DR.hair)
        let sweep = BP.eio(BP.pr(t, 1.8, 2.8)) * 3 / 12 * 2 * .pi                        // three of twelve marks: three seconds
        if sweep > 0 {
            var wedge = Path(); wedge.move(to: sw); wedge.addArc(center: sw, radius: r - 5, startAngle: .radians(-.pi / 2), endAngle: .radians(-.pi / 2 + sweep), clockwise: false); wedge.closeSubpath()
            c.fill(wedge, with: .color(DR.accent.opacity(0.85)))
        }
        var hand = Path(); hand.move(to: sw); hand.addLine(to: pt(sw.x + (r - 5) * sin(sweep), sw.y - (r - 5) * cos(sweep)))
        DR.draw(&c, hand, p: on)
        if t >= 2.8 {
            let lbl = c.resolve(Text("3 s").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundColor(DR.ink))
            var lc = c; lc.opacity = BP.pr(t, 2.8, 3.0)
            lc.draw(lbl, at: pt(sw.x, sw.y + r + 9), anchor: .center)
        }

        // labels
        DR.label(&c, "IN THE TUBE\nRUNNY FOR MONTHS", anchor: pt(96, 146), at: pt(80, 268), align: .center, p: BP.pr(t, 1.6, 2.1))
        DR.label(&c, "ON YOUR FINGER\nHARD IN SECONDS", anchor: pt(270, 192), at: pt(276, 268), align: .center, p: BP.pr(t, 2.8, 3.3))
    }
}

// MARK: - Everyday objects (made for card payment, free for any drafting topic)

// A card terminal, a bank card, a hand holding a card (drawn after a line-art reference), an envelope, a bank, a card network, a shop,
// a yes pill and a payment slip. Each takes `on` (outline progress) and `fill` (white and hatching) like `glueTube`.
extension DR {
    /// The card terminal on its foot, front face with a little thickness to the right. Body 72 x 106 with its top left at `at`;
    /// the foot reaches 12 below. `on` draws the outlines, `fill` the white and the hatching.
    static func terminal(_ c: inout GraphicsContext, at o: CGPoint, on: Double, fill: Double) {
        var g = c; g.opacity = fill
        let r = CGRect(x: o.x, y: o.y, width: 72, height: 106)
        let dx = 10.0, dy = -7.0
        // thickness: the body again, up and to the right, with the corners joined
        let back = Path(roundedRect: r.offsetBy(dx: dx, dy: dy), cornerRadius: 9)
        g.fill(back, with: .color(DR.side))
        DR.hatch(&g, back, in: r.offsetBy(dx: dx, dy: dy), spacing: 3.2, alpha: 0.3)
        DR.draw(&c, back, p: on, width: DR.hair + 0.2)
        var join = Path()
        join.move(to: pt(r.maxX - 2.6, r.minY + 2.6)); join.addLine(to: pt(r.maxX - 2.6 + dx, r.minY + 2.6 + dy))
        join.move(to: pt(r.maxX - 2.6, r.maxY - 2.6)); join.addLine(to: pt(r.maxX - 2.6 + dx, r.maxY - 2.6 + dy))
        join.move(to: pt(r.minX + 2.6, r.minY + 2.6)); join.addLine(to: pt(r.minX + 2.6 + dx, r.minY + 2.6 + dy))
        DR.draw(&c, join, p: on, width: DR.hair + 0.2)
        // the foot
        var foot = Path()
        foot.move(to: pt(o.x + 12, r.maxY - 1)); foot.addLine(to: pt(o.x + 60, r.maxY - 1))
        foot.addLine(to: pt(o.x + 66, r.maxY + 12)); foot.addLine(to: pt(o.x + 6, r.maxY + 12)); foot.closeSubpath()
        g.fill(foot, with: .color(DR.side))
        DR.hatch(&g, foot, in: foot.boundingRect, spacing: 3, alpha: 0.35)
        DR.draw(&c, foot, p: on)
        // the front
        let front = Path(roundedRect: r, cornerRadius: 9)
        g.fill(front, with: .color(DR.face))
        DR.draw(&c, front, p: on, width: DR.line + 0.15)
        // contactless panel with the symbol
        let panel = CGRect(x: o.x + 8, y: o.y + 8, width: 56, height: 26)
        g.fill(Path(roundedRect: panel, cornerRadius: 4), with: .color(DR.side))
        DR.draw(&c, Path(roundedRect: panel, cornerRadius: 4), p: on, width: DR.hair)
        symbol(&c, at: pt(o.x + 21, o.y + 21), on: on)
        // screen: a dark glass with the amount as two short bars
        let screen = Path(roundedRect: CGRect(x: o.x + 8, y: o.y + 40, width: 56, height: 20), cornerRadius: 3)
        g.fill(screen, with: .color(DR.ink.opacity(0.88)))
        DR.draw(&c, screen, p: on, width: DR.hair + 0.2)
        if fill > 0 {
            var bars = Path()
            bars.addRoundedRect(in: CGRect(x: o.x + 14, y: o.y + 46, width: 22, height: 3), cornerSize: CGSize(width: 1.5, height: 1.5))
            bars.addRoundedRect(in: CGRect(x: o.x + 14, y: o.y + 52, width: 34, height: 2.4), cornerSize: CGSize(width: 1.2, height: 1.2))
            g.fill(bars, with: .color(.white.opacity(0.85)))
        }
        // keypad: three by four keys
        var keys = Path()
        for row in 0..<4 { for col in 0..<3 {
            keys.addRoundedRect(in: CGRect(x: o.x + 11 + 17.5 * Double(col), y: o.y + 66 + 9.5 * Double(row), width: 13, height: 6.5), cornerSize: CGSize(width: 2, height: 2))
        } }
        g.fill(keys, with: .color(DR.face))
        DR.draw(&c, keys, p: on, width: DR.hair)
    }

    /// The contactless symbol: a dot and three arcs opening to the right.
    static func symbol(_ c: inout GraphicsContext, at p: CGPoint, on: Double) {
        var s = Path()
        for r in [5.0, 9.0, 13.0] {
            for i in 0...8 {
                let a = -0.8 + 1.6 * Double(i) / 8
                let q = pt(p.x - 7 + r * cos(a), p.y + r * sin(a))
                if i == 0 { s.move(to: q) } else { s.addLine(to: q) }
            }
        }
        DR.draw(&c, s, p: on, width: DR.hair + 0.15)
        if on > 0.2 { c.fill(Path(ellipseIn: CGRect(x: p.x - 8.8, y: p.y - 1.8, width: 3.6, height: 3.6)), with: .color(DR.ink)) }
    }

    /// A bank card, 52 x 33, centred on `at`: magnetic stripe, chip and a few number marks.
    static func card(_ c: inout GraphicsContext, at: CGPoint, on: Double, fill: Double) {
        let r = CGRect(x: at.x - 26, y: at.y - 16.5, width: 52, height: 33)
        var g = c; g.opacity = fill
        let body = Path(roundedRect: r, cornerRadius: 3.5)
        g.fill(body, with: .color(DR.face))
        DR.draw(&c, body, p: on)
        g.fill(Path(CGRect(x: r.minX + 0.6, y: r.minY + 5.5, width: r.width - 1.2, height: 5.5)), with: .color(DR.ink.opacity(0.85)))
        let chip = Path(roundedRect: CGRect(x: r.minX + 6, y: r.minY + 15, width: 10, height: 8), cornerRadius: 1.2)
        DR.draw(&c, chip, p: on, width: DR.hair)
        var marks = Path()
        marks.move(to: pt(r.minX + 6, r.maxY - 4)); marks.addLine(to: pt(r.minX + 30, r.maxY - 4))
        marks.move(to: pt(r.minX + 34, r.maxY - 4)); marks.addLine(to: pt(r.minX + 44, r.maxY - 4))
        marks.move(to: pt(r.minX + 20, r.minY + 19)); marks.addLine(to: pt(r.minX + 44, r.minY + 19))
        DR.draw(&c, marks, p: on, width: DR.hair, color: DR.ink.opacity(0.55))
    }

    /// A hand holding a card by its lower right corner, as in a tap (drawn after a line-art reference, 2026-11-03): the thumb lies across the card with
    /// its nail, the back of the hand is a big rounded shape beside it, three curled fingers hang behind the card, then a cuff and the forearm
    /// running off down to the right. `at` is the card's centre. Draws the card too, so card and hand stack in the right order.
    static func heldCard(_ c: inout GraphicsContext, at: CGPoint, on: Double, fill: Double) {
        var h = c
        h.translateBy(x: at.x, y: at.y)
        var f = h; f.opacity = fill
        func fillDraw(_ p: Path, width: Double = DR.line + 0.1) { f.fill(p, with: .color(DR.face)); DR.draw(&h, p, p: on, width: width) }
        func capsule(_ top: CGPoint, _ tip: CGPoint, _ w: Double) -> Path {
            let len = hypot(tip.x - top.x, tip.y - top.y), ang = atan2(tip.y - top.y, tip.x - top.x)
            return Path(roundedRect: CGRect(x: 0, y: -w / 2, width: len, height: w), cornerRadius: w / 2)
                .applying(CGAffineTransform(translationX: top.x, y: top.y).rotated(by: ang).concatenating(.identity))
                .applying(.identity)
        }
        func rotated(_ p: Path, _ o: CGPoint, _ a: Double) -> Path {
            p.applying(CGAffineTransform(translationX: -o.x, y: -o.y).concatenating(CGAffineTransform(rotationAngle: a)).concatenating(CGAffineTransform(translationX: o.x, y: o.y)))
        }
        // three curled fingers and a fourth tip, hanging behind the card
        for (top, tip, w) in [(pt(11, 10), pt(7, 22), 7.0), (pt(24, 14), pt(14.5, 37), 7.5), (pt(30, 20), pt(19.5, 46), 7.5), (pt(36, 26), pt(25, 51), 7.5)] {
            let p = capsule(top, tip, w)
            f.fill(p, with: .color(DR.face)); DR.draw(&h, p, p: on)
        }
        DR.card(&h, at: .zero, on: on, fill: fill)
        // the forearm and cuff
        var arm = Path()
        arm.move(to: pt(95, 59)); arm.addLine(to: pt(150, 112)); arm.addLine(to: pt(118, 150)); arm.addLine(to: pt(79, 76))
        fillDraw(arm)
        DR.hatch(&f, arm, in: arm.boundingRect, spacing: 3.2, alpha: 0.3)
        var cuff = Path()
        cuff.move(to: pt(84, 50)); cuff.addLine(to: pt(95, 59)); cuff.addLine(to: pt(79, 76)); cuff.addLine(to: pt(66, 71)); cuff.closeSubpath()
        fillDraw(cuff)
        // the back of the hand
        var back = Path()
        back.move(to: pt(26, 6))
        back.addCurve(to: pt(42, 4), control1: pt(31, 4), control2: pt(36, 3.8))
        back.addLine(to: pt(58, 5))
        back.addCurve(to: pt(70, 12), control1: pt(66, 5), control2: pt(69, 7))
        back.addCurve(to: pt(76, 33), control1: pt(72, 19), control2: pt(73, 25))
        back.addCurve(to: pt(85, 52), control1: pt(78, 40), control2: pt(81, 46))
        back.addLine(to: pt(66, 71))
        back.addCurve(to: pt(46, 46), control1: pt(58, 64), control2: pt(50, 56))
        back.addCurve(to: pt(42, 30), control1: pt(44, 40), control2: pt(44, 34))
        back.addCurve(to: pt(24, 10), control1: pt(38, 24), control2: pt(30, 16))
        back.closeSubpath()
        fillDraw(back)
        DR.hatch(&f, back, in: back.boundingRect, spacing: 3.4, alpha: 0.0)
        var shade = Path()
        for i in 0..<7 { let x = 50.0 + 4 * Double(i); shade.move(to: pt(x + 2, 56 - Double(i) * 1.6 + 8)); shade.addLine(to: pt(x, 44 - Double(i) * 1.6 + 4)) }
        DR.draw(&h, shade, p: on, width: DR.hair, color: DR.ink.opacity(0.5))
        var knuckles = Path()
        knuckles.move(to: pt(46, 6)); knuckles.addCurve(to: pt(52, 14), control1: pt(46, 9), control2: pt(48, 12))
        knuckles.move(to: pt(56, 5)); knuckles.addCurve(to: pt(62, 12), control1: pt(56, 8), control2: pt(58, 11))
        DR.draw(&h, knuckles, p: on, width: DR.hair, color: DR.ink.opacity(0.6))
        // the thumb across the card, nail at its tip; the base melts into the hand, so only the outline is stroked
        var thumb = Path()
        thumb.move(to: pt(48, 31))
        thumb.addCurve(to: pt(20, 7.5), control1: pt(40, 24), control2: pt(24, 12))
        thumb.addCurve(to: pt(11.5, 12), control1: pt(16, 5), control2: pt(11, 8))
        thumb.addCurve(to: pt(22, 26), control1: pt(12, 15), control2: pt(16, 18))
        thumb.addCurve(to: pt(46, 41), control1: pt(28, 33), control2: pt(36, 38))
        f.fill(thumb, with: .color(DR.face))
        DR.draw(&h, thumb, p: on, width: DR.line + 0.1)
        let nail = rotated(Path(ellipseIn: CGRect(x: 11.5, y: 7.5, width: 9, height: 6.5)), pt(16, 10.8), 0.6)
        DR.draw(&h, nail, p: on, width: DR.hair + 0.1)
        var crease = Path(); crease.move(to: pt(30, 18)); crease.addCurve(to: pt(34, 26), control1: pt(32, 20), control2: pt(34, 23))
        DR.draw(&h, crease, p: on, width: DR.hair, color: DR.ink.opacity(0.6))
    }

    /// The message: an envelope in the accent, 34 x 24, with a question mark on it, centred on `at`.
    static func envelope(_ c: inout GraphicsContext, at: CGPoint, alpha: Double) {
        guard alpha > 0.01 else { return }
        var g = c; g.opacity = alpha
        let r = CGRect(x: at.x - 17, y: at.y - 12, width: 34, height: 24)
        let body = Path(roundedRect: r, cornerRadius: 2.5)
        g.fill(body, with: .color(DR.accent))
        g.stroke(body, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
        var flap = Path()
        flap.move(to: pt(r.minX, r.minY)); flap.addLine(to: pt(at.x, at.y - 1)); flap.addLine(to: pt(r.maxX, r.minY))
        g.stroke(flap, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.hair + 0.2, lineJoin: .round))
        let q = g.resolve(Text("?").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(DR.ink))
        g.draw(q, at: pt(at.x, at.y + 5.5), anchor: .center)
    }
}


// (more everyday objects)
extension DR {
    /// A bank, front-on: pediment, entablature, four fluted columns, two steps. 56 wide, 58 high, standing on `base` at x = `cx`.
    static func bank(_ c: inout GraphicsContext, cx: Double, base: Double, on: Double, fill: Double) {
        var g = c; g.opacity = fill
        func box(_ r: CGRect, _ shade: Bool = false, _ w: Double = DR.line) {
            let p = Path(r)
            g.fill(p, with: .color(shade ? DR.side : DR.face))
            DR.draw(&c, p, p: on, width: w)
        }
        box(CGRect(x: cx - 28, y: base - 5, width: 56, height: 5), true)
        box(CGRect(x: cx - 25, y: base - 10, width: 50, height: 5), true)
        for dx in [-18.0, -6, 6, 18] {
            box(CGRect(x: cx + dx - 3.5, y: base - 38, width: 7, height: 28), false, DR.hair + 0.3)
            var flute = Path()
            for fx in [-1.2, 1.2] { flute.move(to: pt(cx + dx + fx, base - 35)); flute.addLine(to: pt(cx + dx + fx, base - 13)) }
            DR.draw(&c, flute, p: on, width: DR.hair - 0.15, color: DR.ink.opacity(0.55))
            box(CGRect(x: cx + dx - 4.5, y: base - 40, width: 9, height: 2.5), false, DR.hair + 0.3)
            box(CGRect(x: cx + dx - 4.5, y: base - 12.5, width: 9, height: 2.5), false, DR.hair + 0.3)
        }
        box(CGRect(x: cx - 27, y: base - 46, width: 54, height: 6), true)
        var roof = Path()
        roof.move(to: pt(cx - 29, base - 46)); roof.addLine(to: pt(cx, base - 60)); roof.addLine(to: pt(cx + 29, base - 46)); roof.closeSubpath()
        g.fill(roof, with: .color(DR.face))
        DR.hatch(&g, roof, in: roof.boundingRect, spacing: 3.4, alpha: 0.28)
        DR.draw(&c, roof, p: on)
        DR.draw(&c, Path(ellipseIn: CGRect(x: cx - 3.5, y: base - 55, width: 7, height: 7)), p: on, width: DR.hair)
    }

    /// A card network: a little globe in the middle with spokes to five nodes. About 60 wide, 56 high, centred on `at`.
    static func network(_ c: inout GraphicsContext, at: CGPoint, on: Double, fill: Double) {
        var g = c; g.opacity = fill
        var nodes: [CGPoint] = []
        for i in 0..<5 {
            let a = -Double.pi / 2 + 2 * Double.pi * Double(i) / 5
            nodes.append(pt(at.x + 27 * cos(a) * 1.05, at.y + 25 * sin(a)))
        }
        var spokes = Path()
        for n in nodes { spokes.move(to: at); spokes.addLine(to: n) }
        DR.draw(&c, spokes, p: on, width: DR.hair + 0.2)
        for n in nodes {
            let d = Path(ellipseIn: CGRect(x: n.x - 5.5, y: n.y - 5.5, width: 11, height: 11))
            g.fill(d, with: .color(DR.face))
            DR.hatch(&g, d, in: d.boundingRect, spacing: 2.6, alpha: 0.3)
            DR.draw(&c, d, p: on)
        }
        let globe = Path(ellipseIn: CGRect(x: at.x - 11, y: at.y - 11, width: 22, height: 22))
        g.fill(globe, with: .color(DR.face))
        DR.hatch(&g, globe, in: globe.boundingRect, spacing: 3, alpha: 0.28)
        DR.draw(&c, globe, p: on, width: DR.line + 0.1)
        var lines = Path()
        lines.addEllipse(in: CGRect(x: at.x - 5, y: at.y - 11, width: 10, height: 22))
        lines.move(to: pt(at.x - 11, at.y)); lines.addLine(to: pt(at.x + 11, at.y))
        DR.draw(&c, lines, p: on, width: DR.hair, color: DR.ink.opacity(0.7))
    }

    /// A shop, front-on: striped scalloped awning, two posts, a counter with a till on it. 64 wide, 62 high, standing on `base` at x = `cx`.
    /// `tray` is an open, empty money tray in the counter's front.
    static func shop(_ c: inout GraphicsContext, cx: Double, base: Double, on: Double, fill: Double, tray: Bool = true) {
        var g = c; g.opacity = fill
        var posts = Path()
        for sx in [-1.0, 1.0] { posts.move(to: pt(cx + sx * 29, base - 48)); posts.addLine(to: pt(cx + sx * 29, base)) }
        DR.draw(&c, posts, p: on, width: DR.line)
        let counter = Path(CGRect(x: cx - 29, y: base - 24, width: 58, height: 24))
        g.fill(counter, with: .color(DR.side))
        DR.hatch(&g, counter, in: counter.boundingRect, spacing: 3.4, alpha: 0.25)
        DR.draw(&c, counter, p: on)
        let till = Path(roundedRect: CGRect(x: cx - 12, y: base - 38, width: 24, height: 14), cornerRadius: 2)
        g.fill(till, with: .color(DR.face)); DR.draw(&c, till, p: on)
        let screen = Path(roundedRect: CGRect(x: cx - 8, y: base - 36, width: 16, height: 5), cornerRadius: 1)
        g.fill(screen, with: .color(DR.ink.opacity(0.85)))
        var keys = Path()
        for k in 0..<4 { keys.addRect(CGRect(x: cx - 8 + 4.2 * Double(k), y: base - 28, width: 3, height: 2.4)) }
        g.fill(keys, with: .color(DR.ink.opacity(0.7)))
        if tray {
            let t = Path(roundedRect: CGRect(x: cx - 22, y: base - 17, width: 44, height: 10), cornerRadius: 2)
            g.fill(t, with: .color(DR.face)); DR.draw(&c, t, p: on)
            var mid = Path(); mid.move(to: pt(cx, base - 15)); mid.addLine(to: pt(cx, base - 9))
            DR.draw(&c, mid, p: on, width: DR.hair, color: DR.ink.opacity(0.5), dash: [2, 2])
        }
        for i in 0..<4 {
            let x0 = cx - 32 + 16 * Double(i), x1 = x0 + 16, yb = base - 48
            var p = Path()
            p.move(to: pt(x0, base - 62)); p.addLine(to: pt(x1, base - 62)); p.addLine(to: pt(x1, yb))
            for k in 0...10 { let a = Double.pi * Double(k) / 10; p.addLine(to: pt((x0 + x1) / 2 + 8 * cos(a), yb + 7 * sin(a))) }
            p.closeSubpath()
            g.fill(p, with: .color(DR.face))
            if i % 2 == 0 { DR.hatch(&g, p, in: p.boundingRect, spacing: 2.6, alpha: 0.5) }
            DR.draw(&c, p, p: on)
        }
    }

    /// The yes: a pill in the accent, with the word YES or a tick, centred on `at`.
    static func yes(_ c: inout GraphicsContext, at: CGPoint, alpha: Double, word: Bool) {
        guard alpha > 0.01 else { return }
        var g = c; g.opacity = alpha
        let pill = Path(roundedRect: CGRect(x: at.x - 18, y: at.y - 9, width: 36, height: 18), cornerRadius: 9)
        g.fill(pill, with: .color(DR.accent))
        g.stroke(pill, with: .color(DR.ink), style: StrokeStyle(lineWidth: DR.line, lineJoin: .round))
        if word {
            g.draw(g.resolve(Text("YES").font(.system(size: 9.5, weight: .bold, design: .rounded)).tracking(0.8).foregroundColor(DR.ink)), at: at, anchor: .center)
        } else {
            var tick = Path()
            tick.move(to: pt(at.x - 5, at.y)); tick.addLine(to: pt(at.x - 1.5, at.y + 3.5)); tick.addLine(to: pt(at.x + 6, at.y - 4))
            g.stroke(tick, with: .color(DR.ink), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }

    /// A slip of paper (a payment, or a total when `big`) with two lines on it; `set` turns it to the accent.
    static func slip(_ c: inout GraphicsContext, at: CGPoint, big: Bool, set: Double = 0, alpha: Double) {
        guard alpha > 0.01 else { return }
        var g = c; g.opacity = alpha
        let w = big ? 22.0 : 11.0, h = big ? 14.0 : 7.0
        let r = Path(roundedRect: CGRect(x: at.x - w / 2, y: at.y - h / 2, width: w, height: h), cornerRadius: big ? 2 : 1.2)
        g.fill(r, with: .color(DR.face))
        if set > 0 { g.fill(r, with: .color(DR.accent.opacity(set))) }
        g.stroke(r, with: .color(DR.ink), style: StrokeStyle(lineWidth: big ? DR.line : DR.hair + 0.2, lineJoin: .round))
        if big {
            var l = Path()
            for dy in [-2.0, 2.2] { l.move(to: pt(at.x - 6, at.y + dy)); l.addLine(to: pt(at.x + 6, at.y + dy)) }
            g.stroke(l, with: .color(DR.ink.opacity(0.7)), lineWidth: DR.hair)
        }
    }
}


// MARK: - People

// A standing person drawn front-on in clean line art (after a small line-figure prototype): round head with hair, neck, shirt or dress,
// two arms, trousers and shoes, and a party hat. Drawn in a 56-unit-tall space and scaled, so `s` 0.5 is about 28 points tall.
extension DR {
    /// `feet` is the middle of the ground under the person; `variant` 0 trousers, 1 dress; `hat` puts on a party hat (its pom takes the
    /// accent when `gold` is set, so one person can stand out). `fill` is the white and the hatching, `on` draws the outlines.
    static func person(_ c: inout GraphicsContext, x: Double, feet: Double, s: Double = 0.5, variant: Int = 0, hat: Bool = true, gold: Bool = false,
                       on: Double = 1, alpha: Double = 1) {
        guard alpha > 0.01, on > 0.001 else { return }
        var g = c
        g.opacity = c.opacity * alpha
        g.translateBy(x: x, y: feet); g.scaleBy(x: s, y: s)
        let w = max(0.7, 0.95 * s) / s                                  // keep the outline about the same thickness at any size
        let st = StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        func put(_ path: Path, fill: Color = .white) {
            g.fill(path, with: .color(fill))
            g.stroke(path, with: .color(DR.ink), style: st)
        }
        func arm(_ sx: Double) -> Path {
            var a = Path()
            a.move(to: p(sx * 8.2, -39)); a.addQuadCurve(to: p(sx * 11, -33), control: p(sx * 11.2, -38))
            a.addLine(to: p(sx * 10.8, -24)); a.addQuadCurve(to: p(sx * 9.2, -22.4), control: p(sx * 10.8, -22.4))
            a.addQuadCurve(to: p(sx * 7.6, -24), control: p(sx * 7.6, -22.4)); a.addLine(to: p(sx * 7.6, -34)); a.closeSubpath()
            return a
        }
        put(arm(-1)); put(arm(1))
        if variant == 0 {
            for sx in [-1.0, 1.0] {
                var l = Path()
                l.move(to: p(sx * 6.2, -24)); l.addLine(to: p(sx * 6.4, -3)); l.addQuadCurve(to: p(sx * 8.6, -0.6), control: p(sx * 6.4, -1))
                l.addLine(to: p(sx * 8.6, 0.8)); l.addLine(to: p(sx * 1, 0.8)); l.addLine(to: p(sx * 0.9, -24)); l.closeSubpath()
                put(l)
            }
            var t = Path()
            t.move(to: p(-3, -42)); t.addQuadCurve(to: p(-8.2, -37), control: p(-8.2, -41.4)); t.addLine(to: p(-7, -23)); t.addLine(to: p(7, -23)); t.addLine(to: p(8.2, -37))
            t.addQuadCurve(to: p(3, -42), control: p(8.2, -41.4)); t.addQuadCurve(to: p(-3, -42), control: p(0, -39.6)); t.closeSubpath()
            put(t)
            var h = Path()
            for (a, b) in [(-6.6, -4.2), (-4.0, -2.2), (-1.5, 0.0)] { h.move(to: p(a, -30 - 3 * (a + 6.6) / 5)); h.addLine(to: p(b, -23.4)) }
            g.stroke(h, with: .color(DR.ink.opacity(0.4)), lineWidth: w * 0.6)
        } else {
            for sx in [-1.0, 1.0] {
                var l = Path()
                l.move(to: p(sx * 4.4, -24)); l.addLine(to: p(sx * 4.6, -3)); l.addLine(to: p(sx * 6.6, -0.6)); l.addLine(to: p(sx * 0.8, 0.8)); l.addLine(to: p(sx * 0.8, -24)); l.closeSubpath()
                put(l)
            }
            var d = Path()
            d.move(to: p(-3, -42)); d.addQuadCurve(to: p(-7.2, -37), control: p(-7.2, -41.4)); d.addLine(to: p(-6, -31)); d.addLine(to: p(-10, -17)); d.addLine(to: p(10, -17)); d.addLine(to: p(6, -31))
            d.addLine(to: p(7.2, -37)); d.addQuadCurve(to: p(3, -42), control: p(7.2, -41.4)); d.addQuadCurve(to: p(-3, -42), control: p(0, -39.6)); d.closeSubpath()
            put(d)
            var h = Path()
            for (a, b) in [(-7.0, -5.0), (-3.6, -2.4), (0.0, 0.0), (3.6, 2.4), (7.0, 5.0)] { h.move(to: p(a, -18)); h.addLine(to: p(b, -25 - abs(b))) }
            g.stroke(h, with: .color(DR.ink.opacity(0.4)), lineWidth: w * 0.6)
        }
        var neck = Path()
        neck.move(to: p(-1.7, -43.5)); neck.addLine(to: p(-1.7, -41)); neck.move(to: p(1.7, -43.5)); neck.addLine(to: p(1.7, -41))
        g.stroke(neck, with: .color(DR.ink), style: st)
        put(Path(ellipseIn: CGRect(x: -4.4, y: -53.1, width: 8.8, height: 10.2)))
        var hair = Path()
        if variant == 0 {
            hair.move(to: p(-4.3, -49)); hair.addQuadCurve(to: p(0, -53.2), control: p(-4, -53.2)); hair.addQuadCurve(to: p(4.3, -49), control: p(4, -53.2))
            hair.addQuadCurve(to: p(-1.4, -50.6), control: p(2, -51.4)); hair.addQuadCurve(to: p(-4.3, -49), control: p(-3.6, -50.2))
        } else {
            hair.move(to: p(-4.6, -47)); hair.addQuadCurve(to: p(0, -54), control: p(-5, -54)); hair.addQuadCurve(to: p(4.6, -47), control: p(5, -54))
            hair.addQuadCurve(to: p(3.6, -41.6), control: p(4.8, -43)); hair.addQuadCurve(to: p(0, -49), control: p(3, -47)); hair.addQuadCurve(to: p(-3.6, -41.6), control: p(-3, -47))
            hair.addQuadCurve(to: p(-4.6, -47), control: p(-4.8, -43))
        }
        g.fill(hair, with: .color(DR.ink.opacity(0.78)))
        guard hat else { return }
        var cone = Path()
        cone.move(to: p(-4.6, -52.6)); cone.addQuadCurve(to: p(4.6, -52.6), control: p(0, -54)); cone.addLine(to: p(0.6, -66)); cone.addQuadCurve(to: p(-0.6, -66), control: p(0, -67)); cone.closeSubpath()
        put(cone, fill: gold ? DR.accent : .white)
        var band = Path()
        band.move(to: p(-2.6, -59)); band.addLine(to: p(2.2, -57.4)); band.move(to: p(-3.6, -55.6)); band.addLine(to: p(3.6, -54.9))
        g.stroke(band, with: .color(DR.ink), style: StrokeStyle(lineWidth: w * 0.75, lineCap: .round))
        put(Path(ellipseIn: CGRect(x: -1.5, y: -67.7, width: 3, height: 3)), fill: gold ? DR.accent : .white)
    }
}
