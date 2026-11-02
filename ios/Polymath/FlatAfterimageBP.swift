import SwiftUI

// "Why do you see spots after looking at a bright light?" pictures, drawn as blueprint technical illustrations (2026-11-02).
// Chalk linework, flat tints only. One mustard accent per card, used only for the tired patch of cells, its weak signals and the dark spot.
// The dark spot is a solid disc darker than the paper with a mustard outline. Labels are mono uppercase, the slide's own words.
// Every picture loops: it plays on the stage's free clock, holds about a second and fades. Reduce Motion shows the held end state.
// Drawn in the default 343 x 320 design space; keep clear of the bottom-right corner (x > 288, y > 235).

private let afDark = Color(hex: 0x050A1E)

// MARK: - Shared helpers

/// Loop time plus whether the picture is held (Reduce Motion: the stage clock stands still behind `t`, so show the end state).
private func afCycle(_ t: Double, _ clock: Double, story: Double, extra: Double = 1.5) -> (Double, Bool) {
    if clock < t { return (story, true) }
    return (clock.truncatingRemainder(dividingBy: story + extra), false)
}

/// 1 while the picture plays and holds, then fades to 0 over the last half second of the loop.
private func afFade(_ u: Double, _ story: Double) -> Double { 1 - BP.pr(u, story + 1.0, story + 1.5) }

/// Like bpGroup, but multiplies with the opacity already set, so a group can sit inside the picture's overall fade.
private func afGroup(_ c: inout GraphicsContext, alpha: Double, _ body: (inout GraphicsContext) -> Void) {
    guard alpha > 0.01 else { return }
    var g = c; g.opacity = c.opacity * alpha; body(&g)
}

/// A short arrow head at `b` pointing along a to b.
private func afHead(_ p: inout Path, _ a: CGPoint, _ b: CGPoint) {
    let len = hypot(b.x - a.x, b.y - a.y)
    guard len > 0.1 else { return }
    let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    p.move(to: BP.pt(b.x - ux * 5 - uy * 3, b.y - uy * 5 + ux * 3)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * 5 + uy * 3, b.y - uy * 5 - ux * 3))
}

/// A dashed polyline drawn on by `p`; `phase` makes the dashes march.
private func afRay(_ c: inout GraphicsContext, _ pts: [CGPoint], p: Double, color: Color, alpha: Double = 1, phase: Double = 0) {
    guard p > 0.001, alpha > 0.01, pts.count > 1 else { return }
    var path = Path(); path.addLines(pts)
    c.stroke(path.trimmedPath(from: 0, to: BP.cl(p)), with: .color(color.opacity(alpha)),
             style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round, dash: [5, 4], dashPhase: -phase))
}

/// Diagonal hatching inside `clip`.
private func afHatch(_ c: inout GraphicsContext, clip: Path, color: Color, alpha: Double, step: Double = 3) {
    guard alpha > 0.01 else { return }
    var g = c
    g.clip(to: clip)
    let b = clip.boundingRect.insetBy(dx: -2, dy: -2)
    var h = Path()
    var x = b.minX - b.height
    while x < b.maxX { h.move(to: BP.pt(x, b.maxY)); h.addLine(to: BP.pt(x + b.height, b.minY)); x += step }
    g.stroke(h, with: .color(color.opacity(alpha)), lineWidth: BP.hair)
}

/// A flash: a small starburst of chalk spikes round a bright core.
private func afStar(_ c: inout GraphicsContext, at m: CGPoint, r: Double, ink: Color, alpha: Double) {
    guard alpha > 0.01, r > 0.5 else { return }
    var s = Path()
    for i in 0..<8 {
        let a = Double(i) * Double.pi / 4
        let len = i % 2 == 0 ? r : r * 0.6
        s.move(to: BP.pt(m.x + cos(a) * r * 0.32, m.y + sin(a) * r * 0.32))
        s.addLine(to: BP.pt(m.x + cos(a) * len, m.y + sin(a) * len))
    }
    c.stroke(s, with: .color(ink.opacity(alpha)), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
    c.fill(Path(ellipseIn: CGRect(x: m.x - r * 0.18, y: m.y - r * 0.18, width: r * 0.36, height: r * 0.36)), with: .color(ink.opacity(alpha)))
}

/// The dark spot: a solid disc darker than the paper, ringed in the accent.
private func afSpot(_ c: inout GraphicsContext, at m: CGPoint, r: Double, acc: Color, alpha: Double = 1) {
    guard alpha > 0.01, r > 0.5 else { return }
    let disc = Path(ellipseIn: CGRect(x: m.x - r, y: m.y - r, width: 2 * r, height: 2 * r))
    c.fill(disc, with: .color(afDark.opacity(alpha)))
    c.stroke(disc, with: .color(acc.opacity(alpha)), lineWidth: 1.6)
}

/// An eye-local point `deg` degrees round from the front (clockwise), `rad` from the centre. The front is straight up.
private func afPol(_ deg: Double, _ rad: Double) -> CGPoint {
    let a = deg * Double.pi / 180
    return BP.pt(rad * sin(a), -rad * cos(a))
}

/// One cell of the layer at the back of the eye: k 0...10, centred on the back (k 5), ten degrees apart.
private func afCell(_ k: Int, r: Double, th: Double) -> Path {
    let mid = 180 + Double(k - 5) * 10, hw = 4.3
    var p = Path()
    for i in 0...3 {
        let q = afPol(mid - hw + 2 * hw * Double(i) / 3, r)
        if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
    }
    for i in stride(from: 3, through: 0, by: -1) { p.addLine(to: afPol(mid - hw + 2 * hw * Double(i) / 3, r - th)) }
    p.closeSubpath()
    return p
}

/// A cutaway eye (cornea and iris at the front, lens, a thick layer of cells on the back wall), centred at `e`, radius `r`, with its front
/// pointing `ang` radians clockwise from straight up. The middle three cells of the layer are `tired` 0...1 (hatched, accent outline).
/// `p` draws the eye on.
private func afEye(_ c: inout GraphicsContext, at e: CGPoint, r: Double, ang: Double, ink: Color, acc: Color, tired: Double, p: Double, cellHue: Color? = nil) {
    guard p > 0.001 else { return }
    var g = c
    g.translateBy(x: e.x, y: e.y)
    g.rotate(by: .radians(ang))
    let th = r * 0.17
    let fa = BP.pr(p, 0.3, 0.8)

    // the ball, with the cornea bulging at the front
    var ball = Path()
    for i in 0...74 {
        let q = afPol(32 + 296 * Double(i) / 74, r)
        if i == 0 { ball.move(to: q) } else { ball.addLine(to: q) }
    }
    ball.addQuadCurve(to: afPol(32, r), control: BP.pt(0, -1.5 * r))
    ball.closeSubpath()
    g.fill(ball, with: .color(BP.paper.opacity(fa)))
    g.fill(ball, with: .color(ink.opacity(0.07 * fa)))
    bpTrace(&g, ball, p: p, color: ink)

    // the layer of cells on the back wall
    for k in 0..<11 {
        let k3 = (4...6).contains(k) ? tired : 0.0
        let cell = afCell(k, r: r - 0.5, th: th)
        g.fill(cell, with: .color(BP.paper.opacity(fa)))
        g.fill(cell, with: .color((cellHue ?? ink).opacity(fa * ((cellHue == nil ? 0.6 : 0.18) - (cellHue == nil ? 0.54 : 0.16) * k3))))
        g.stroke(cell, with: .color((cellHue ?? ink).opacity(fa * (1 - k3))), lineWidth: BP.hair)
        if k3 > 0.01 {
            afHatch(&g, clip: cell, color: acc, alpha: k3 * fa)
            g.stroke(cell, with: .color(acc.opacity(k3 * fa)), lineWidth: BP.edge)
        }
    }

    // iris and lens
    var iris = Path()
    for s in [-1.0, 1.0] {
        iris.move(to: BP.pt(s * 0.545 * r, -0.80 * r)); iris.addLine(to: BP.pt(s * 0.2 * r, -0.74 * r))
    }
    g.stroke(iris, with: .color(ink.opacity(fa)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    let lens = Path(ellipseIn: CGRect(x: -0.3 * r, y: -0.71 * r, width: 0.6 * r, height: 0.26 * r))
    g.fill(lens, with: .color(BP.paper.opacity(fa)))
    g.fill(lens, with: .color(ink.opacity(0.22 * fa)))
    g.stroke(lens, with: .color(ink.opacity(fa)), lineWidth: BP.hair)
}

// MARK: - Card 0: a flash, then a dark spot that stays put on screen while the view swings from wall to floor

struct AfterBPSpot: View {
    let active: Bool
    private static let story = 5.8

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.0,
                       label: "First, a person stands in profile and a camera on a tripod fires a flash at their face. Then a frame shows a plain wall with a dark spot hanging in the middle of it, ringed in gold. The view swings down to the floor, and the dark spot stays in the same place on screen while the wall slides up and the floor comes into view. Labels say: flash, dark spot, wall, floor.",
                       draw: { c, t, pal, clock in
                           let (u, still) = afCycle(t, clock, story: Self.story)
                           afGroup(&c, alpha: still ? 1 : afFade(u, Self.story)) { g in Self.draw(&g, u, pal, clock, still) }
                       })
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ pal: StagePalette, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent

        // part one: the flash
        let aIn = BP.eout(BP.pr(u, 0, 0.5)), aOut = 1 - BP.pr(u, 1.9, 2.3)
        afGroup(&c, alpha: aIn * aOut) { g in
            var ground = Path(); ground.move(to: BP.pt(30, 191)); ground.addLine(to: BP.pt(300, 191))
            g.stroke(ground, with: .color(ink.opacity(0.45)), lineWidth: BP.hair)
            bpPerson(&g, base: BP.pt(80, 168), facing: 1, ink: ink, shirt: 0.14, hair: 0, talk: false)

            // the camera on its tripod
            var legs = Path()
            legs.move(to: BP.pt(267, 144)); legs.addLine(to: BP.pt(251, 191))
            legs.move(to: BP.pt(267, 144)); legs.addLine(to: BP.pt(283, 191))
            legs.move(to: BP.pt(267, 144)); legs.addLine(to: BP.pt(267, 191))
            g.stroke(legs, with: .color(ink), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
            let lens = Path(roundedRect: CGRect(x: 232, y: 120, width: 12, height: 16), cornerRadius: 2)
            g.fill(lens, with: .color(BP.paper)); g.fill(lens, with: .color(ink.opacity(0.22)))
            g.stroke(lens, with: .color(ink), lineWidth: BP.edge)
            let body = Path(roundedRect: CGRect(x: 244, y: 112, width: 46, height: 32), cornerRadius: 4)
            g.fill(body, with: .color(BP.paper)); g.fill(body, with: .color(ink.opacity(0.14)))
            g.stroke(body, with: .color(ink), lineWidth: BP.edge)

            // the flash and its light, travelling to the face
            let pop = BP.eout(BP.pr(u, 0.7, 0.95))
            afStar(&g, at: BP.pt(216, 128), r: 12 * pop, ink: ink, alpha: pop)
            let ph = still ? 0 : clock * 16
            for y in [121.0, 128.0, 135.0] {
                afRay(&g, [BP.pt(200, 128), BP.pt(101, y)], p: BP.pr(u, 0.8, 1.3), color: BP.Hue.ice, alpha: 0.95, phase: ph)
            }
            bpLeader(&g, anchor: BP.pt(216, 116), elbow: BP.pt(216, 86), tail: 0, text: "FLASH", ink: ink, p: BP.pr(u, 0.4, 1.0))
        }

        // part two: a frame showing the wall, with the spot, and the view swinging down to the floor
        let frame = CGRect(x: 36, y: 26, width: 204, height: 196)
        let fa = BP.eout(BP.pr(u, 2.2, 2.7))
        let pan = BP.eio(BP.pr(u, 3.9, 5.3))
        let bd = BP.mix(280, 74, pan)          // where the wall meets the floor, on screen
        afGroup(&c, alpha: fa) { g in
            let box = Path(roundedRect: frame, cornerRadius: 6)
            var s = g
            s.clip(to: box)
            s.fill(Path(CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: max(0, bd - frame.minY))), with: .color(BP.Hue.peach.opacity(0.10)))
            s.fill(Path(CGRect(x: frame.minX, y: bd, width: frame.width, height: 300)), with: .color(BP.Hue.peach.opacity(0.18)))

            // wall: courses of bricks, anchored to the floor line so they travel with it
            var bricks = Path()
            var j = 1
            while bd - 24 * Double(j) > frame.minY - 24 {
                let y = bd - 24 * Double(j)
                bricks.move(to: BP.pt(frame.minX, y)); bricks.addLine(to: BP.pt(frame.maxX, y))
                let off = j % 2 == 0 ? 0.0 : 20.0
                for k in 0..<6 {
                    let x = frame.minX + off + 40 * Double(k)
                    bricks.move(to: BP.pt(x, y)); bricks.addLine(to: BP.pt(x, y + 24))
                }
                j += 1
            }
            s.stroke(bricks, with: .color(BP.Hue.peach.opacity(0.7)), lineWidth: BP.hair)

            // floor: boards running away from the wall
            var boards = Path()
            for k in -6...6 {
                let kx = Double(k)
                boards.move(to: BP.pt(138 + kx * 14, bd)); boards.addLine(to: BP.pt(138 + kx * 64, bd + 230))
            }
            for d in [14.0, 34.0, 64.0, 104.0, 158.0, 226.0] { boards.move(to: BP.pt(frame.minX, bd + d)); boards.addLine(to: BP.pt(frame.maxX, bd + d)) }
            s.stroke(boards, with: .color(BP.Hue.peach.opacity(0.75)), lineWidth: BP.hair)

            // skirting board where they meet
            let skirt = CGRect(x: frame.minX, y: bd - 8, width: frame.width, height: 8)
            s.fill(Path(skirt), with: .color(BP.paper)); s.fill(Path(skirt), with: .color(BP.Hue.peach.opacity(0.18)))
            var sk = Path()
            sk.move(to: BP.pt(frame.minX, bd - 8)); sk.addLine(to: BP.pt(frame.maxX, bd - 8))
            sk.move(to: BP.pt(frame.minX, bd)); sk.addLine(to: BP.pt(frame.maxX, bd))
            s.stroke(sk, with: .color(ink), lineWidth: BP.hair)

            g.stroke(box, with: .color(ink), lineWidth: BP.edge)

            // the spot: it never moves on screen
            afSpot(&g, at: BP.pt(138, 128), r: 22 * BP.eout(BP.pr(u, 2.8, 3.3)), acc: acc)

            // the swing: an arrow down beside the frame
            let ap = BP.pr(u, 3.8, 4.3)
            if ap > 0.01 {
                var arrow = Path(); arrow.move(to: BP.pt(20, 72)); arrow.addLine(to: BP.pt(20, 172))
                afHead(&arrow, BP.pt(20, 150), BP.pt(20, 176))
                g.stroke(arrow, with: .color(ink.opacity(0.8 * ap)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round, dash: [5, 4], dashPhase: still ? 0 : -clock * 14))
            }

            bpLeader(&g, anchor: BP.pt(216, 50), elbow: BP.pt(252, 50), tail: 0, text: "WALL", ink: BP.Hue.peach, p: BP.pr(u, 2.5, 3.1))
            bpLeader(&g, anchor: BP.pt(160, 128), elbow: BP.pt(252, 128), tail: 0, text: "DARK SPOT", ink: acc, p: BP.pr(u, 3.2, 3.9))
            bpLeader(&g, anchor: BP.pt(216, 190), elbow: BP.pt(252, 190), tail: 0, text: "FLOOR", ink: BP.Hue.peach, p: BP.pr(u, 5.0, 5.6))
        }
    }
}

// MARK: - Card 1: the flash lands on the layer of cells at the back of the eye, and one patch of it tires

struct AfterBPEye: View {
    let active: Bool
    private static let story = 4.2

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.1,
                       label: "A cutaway eye seen from the side, its front on the left, with a thick layer of cells on the back wall on the right. A flash on the left sends rays in through the front and through the lens, and they meet at the middle of the layer of cells. Then that patch of cells goes hatched and gold, tired, while the cells around it stay bright. Labels say: flash, layer of cells at the back of your eye, tired cells.",
                       draw: { c, t, pal, clock in
                           let (u, still) = afCycle(t, clock, story: Self.story)
                           afGroup(&c, alpha: still ? 1 : afFade(u, Self.story)) { g in Self.draw(&g, u, pal, clock, still) }
                       })
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ pal: StagePalette, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let e = BP.pt(140, 156), r = 64.0, th = r * 0.17
        let tired = BP.eio(BP.pr(u, 2.1, 3.0))

        afEye(&c, at: e, r: r, ang: -Double.pi / 2, ink: ink, acc: acc, tired: tired, p: BP.pr(u, 0, 0.7), cellHue: BP.Hue.pistachio)

        // the flash
        let sa = BP.pr(u, 0.3, 0.7)
        let bump = sin(Double.pi * BP.pr(u, 1.0, 1.5))
        afStar(&c, at: BP.pt(26, 156), r: 10 * (1 + 0.4 * bump), ink: ink, alpha: sa)

        // its light: in through the front, bent by the lens, meeting at the back of the layer of cells
        let ph = still ? 0 : clock * 14
        let rayA = (1 - 0.65 * BP.pr(u, 2.3, 3.0)) * 0.95
        for a in [-12.0, -6.0, 0.0, 6.0, 12.0] {
            let pts = [BP.pt(40, 156), BP.pt(e.x - 0.58 * r, 156 + a), BP.pt(e.x + r - th - 1, 156)]
            afRay(&c, pts, p: BP.pr(u, 0.9, 1.9), color: BP.Hue.ice, alpha: rayA, phase: ph)
        }

        bpLeader(&c, anchor: BP.pt(26, 145), elbow: BP.pt(26, 118), tail: 0, text: "FLASH", ink: ink, p: BP.pr(u, 0.4, 1.0))
        bpLeader(&c, anchor: BP.pt(184.9, 193.7), elbow: BP.pt(185, 252), tail: -4, text: "LAYER OF CELLS AT THE\nBACK OF YOUR EYE", ink: BP.Hue.pistachio, p: BP.pr(u, 0.9, 1.6))
        bpLeader(&c, anchor: BP.pt(e.x + r - th / 2, 156), elbow: BP.pt(226, 156), tail: 0, text: "TIRED CELLS", ink: acc, p: BP.pr(u, 2.6, 3.2))
    }
}

// MARK: - Card 2: tired cells send weaker signals, so the picture has a dark spot over them

struct AfterBPCells: View {
    let active: Bool
    private static let story = 5.0

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.4,
                       label: "A row of eleven cells, lit evenly by a plain wall below them. The three in the middle are tired, hatched and gold. Each cell sends a line up to a picture frame at the top: the eight normal cells send thick bright lines, strong signals, and the three tired cells send thin faint dashed gold lines, weak signals. The frame fills in column by column, bright above the normal cells and with a dark spot above the three tired ones, exactly as wide as they are. Labels say: normal cells, strong signal; tired cells, weak signal; what you see.",
                       draw: { c, t, pal, clock in
                           let (u, still) = afCycle(t, clock, story: Self.story)
                           afGroup(&c, alpha: still ? 1 : afFade(u, Self.story)) { g in Self.draw(&g, u, pal, clock, still) }
                       })
    }

    private static func cx(_ i: Int) -> Double { 25.5 + 18 * Double(i) }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ pal: StagePalette, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let cellTop = 168.0
        let frame = CGRect(x: 16.5, y: 14, width: 198, height: 78)
        let spotRect = CGRect(x: 88.5, y: 24, width: 54, height: 58)       // exactly the width of columns 4...6
        let tired = BP.eio(BP.pr(u, 1.3, 2.0))

        // the plain wall below, and the even light it sends up into every cell
        afGroup(&c, alpha: BP.eout(BP.pr(u, 0.3, 0.8))) { g in
            let wall = Path(CGRect(x: 16.5, y: 214, width: 198, height: 10))
            g.fill(wall, with: .color(BP.paper)); g.fill(wall, with: .color(ink.opacity(0.14)))
            g.stroke(wall, with: .color(ink), lineWidth: BP.edge)
            var arrows = Path()
            for k in 0...11 {
                let x = 16.5 + 18 * Double(k)
                arrows.move(to: BP.pt(x, 211)); arrows.addLine(to: BP.pt(x, 199))
                afHead(&arrows, BP.pt(x, 211), BP.pt(x, 199))
            }
            g.stroke(arrows, with: .color(BP.Hue.ice.opacity(0.9)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round))
        }

        // the row of cells; the middle three tire
        for i in 0..<11 {
            let k = (4...6).contains(i) ? tired : 0.0
            let path = Path(roundedRect: CGRect(x: cx(i) - 7.5, y: cellTop, width: 15, height: 26), cornerRadius: 3)
            afGroup(&c, alpha: BP.eout(BP.pr(u, 0, 0.6))) { g in
                g.fill(path, with: .color(BP.paper))
                g.fill(path, with: .color(BP.Hue.pistachio.opacity(0.18 * (1 - k))))
                g.stroke(path, with: .color(BP.Hue.pistachio.opacity(1 - k)), lineWidth: BP.edge)
                if k > 0.01 {
                    afHatch(&g, clip: path, color: acc, alpha: k)
                    g.stroke(path, with: .color(acc.opacity(k)), lineWidth: BP.edge)
                }
            }
        }

        // the signals: thick and bright from normal cells, thin and faint from tired ones
        for i in 0..<11 {
            let p = BP.pr(u, 2.2 + 0.05 * Double(i), 2.9 + 0.05 * Double(i))
            var line = Path(); line.move(to: BP.pt(cx(i), cellTop - 1)); line.addLine(to: BP.pt(cx(i), frame.maxY + 1))
            if (4...6).contains(i) { bpTrace(&c, line, p: p, color: acc.opacity(0.85), width: 1.2, dash: [3, 4]) }
            else { bpTrace(&c, line, p: p, color: BP.Hue.ice, width: 3.4) }
        }

        // the picture frame, filled column by column from the same cells
        let box = Path(roundedRect: frame, cornerRadius: 5)
        for i in 0..<11 {
            let rv = BP.eout(BP.pr(u, 2.9 + 0.12 * Double(i), 3.4 + 0.12 * Double(i)))
            guard rv > 0.001 else { continue }
            var s = c
            s.clip(to: box)
            let col = CGRect(x: 16.5 + 18 * Double(i), y: frame.maxY - frame.height * rv, width: 18, height: frame.height * rv)
            s.clip(to: Path(col))
            s.fill(Path(col), with: .color(ink.opacity(0.12)))
            if (4...6).contains(i) { s.fill(Path(ellipseIn: spotRect), with: .color(afDark)) }
        }
        afGroup(&c, alpha: BP.eout(BP.pr(u, 2.4, 2.9))) { g in g.stroke(box, with: .color(ink), lineWidth: BP.edge) }
        afGroup(&c, alpha: BP.pr(u, 4.2, 4.7)) { g in g.stroke(Path(ellipseIn: spotRect), with: .color(acc), lineWidth: 1.6) }

        bpLeader(&c, anchor: BP.pt(cx(10), 181), elbow: BP.pt(226, 181), tail: 0, text: "NORMAL CELLS:\nSTRONG SIGNAL", ink: BP.Hue.pistachio, p: BP.pr(u, 0.8, 1.4))
        bpLeader(&c, anchor: BP.pt(cx(5), 190), elbow: BP.pt(cx(5), 252), tail: 0, text: "TIRED CELLS:\nWEAK SIGNAL", ink: acc, p: BP.pr(u, 1.9, 2.5))
        bpLeader(&c, anchor: BP.pt(210, 53), elbow: BP.pt(226, 53), tail: 0, text: "WHAT YOU SEE", ink: ink, p: BP.pr(u, 3.0, 3.6))
    }
}

// MARK: - Card 3: the spot follows the eyes; then the cells recover and it fades

struct AfterBPTurn: View {
    let active: Bool
    private static let story = 6.5

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 1.0,
                       label: "At the top, a still scene: a house, a tree and a lamp post along a horizon. Below it, an eye seen from above, with a tired patch of cells, gold, on its back wall. A dark spot, ringed in gold, sits on the scene along the line from the tired patch through the eye. The eye turns left, then right, then back to the middle, and the dark spot slides across the still scene with it, because the patch turns with the eye. Then the cells recover, the patch goes bright, and the spot fades away. Labels say: tired cells; cells recover, spot fades.",
                       draw: { c, t, pal, clock in
                           let (u, still) = afCycle(t, clock, story: Self.story)
                           afGroup(&c, alpha: still ? 1 : afFade(u, Self.story)) { g in Self.draw(&g, u, pal, clock, still) }
                       })
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ pal: StagePalette, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let e = BP.pt(171, 186), r = 42.0, th = r * 0.17
        let turn = 0.7
        let k1 = BP.eio(BP.pr(u, 1.0, 2.0)), k2 = BP.eio(BP.pr(u, 2.2, 3.8)), k3 = BP.eio(BP.pr(u, 4.0, 5.0))
        let ang = turn * (-k1 + 2 * k2 - k3)
        let tired = 1 - BP.eio(BP.pr(u, 5.3, 6.1))

        // the scene, which never moves
        afGroup(&c, alpha: BP.eout(BP.pr(u, 0, 0.6))) { g in
            let panel = Path(roundedRect: CGRect(x: 22, y: 26, width: 299, height: 92), cornerRadius: 6)
            g.fill(panel, with: .color(BP.Hue.peach.opacity(0.08)))
            var s = g
            s.clip(to: panel)
            s.fill(Path(CGRect(x: 22, y: 104, width: 299, height: 14)), with: .color(BP.Hue.peach.opacity(0.18)))
            var horizon = Path(); horizon.move(to: BP.pt(22, 104)); horizon.addLine(to: BP.pt(321, 104))
            s.stroke(horizon, with: .color(BP.Hue.peach.opacity(0.9)), lineWidth: BP.hair)

            // house
            var roof = Path(); roof.move(to: BP.pt(45, 76)); roof.addLine(to: BP.pt(70, 56)); roof.addLine(to: BP.pt(95, 76)); roof.closeSubpath()
            let houseBody = Path(CGRect(x: 50, y: 76, width: 40, height: 28))
            for part in [houseBody, roof] {
                s.fill(part, with: .color(BP.paper)); s.fill(part, with: .color(BP.Hue.peach.opacity(0.15)))
                s.stroke(part, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
            }
            s.stroke(Path(CGRect(x: 65, y: 88, width: 10, height: 16)), with: .color(ink), lineWidth: BP.hair)

            // tree
            let trunk = Path(CGRect(x: 167, y: 86, width: 8, height: 18))
            let crown = Path(ellipseIn: CGRect(x: 154, y: 53, width: 34, height: 34))
            for part in [trunk, crown] {
                s.fill(part, with: .color(BP.paper)); s.fill(part, with: .color(BP.Hue.peach.opacity(0.15)))
                s.stroke(part, with: .color(ink), lineWidth: BP.edge)
            }

            // lamp post
            var pole = Path()
            pole.move(to: BP.pt(272, 104)); pole.addLine(to: BP.pt(272, 60)); pole.addLine(to: BP.pt(282, 60))
            s.stroke(pole, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, lineJoin: .round))
            let lamp = Path(roundedRect: CGRect(x: 279, y: 60, width: 10, height: 4), cornerRadius: 1.5)
            s.fill(lamp, with: .color(BP.paper)); s.fill(lamp, with: .color(BP.Hue.peach.opacity(0.18)))
            s.stroke(lamp, with: .color(ink), lineWidth: BP.hair)

            g.stroke(panel, with: .color(BP.Hue.peach), lineWidth: BP.edge)
        }

        // the eye turns, carrying its tired patch with it
        afEye(&c, at: e, r: r, ang: ang, ink: ink, acc: acc, tired: tired, p: BP.pr(u, 0, 0.7))

        // colour on the cells that are not tired: lime, laid over the eye's own chalk cells (the tired three keep their mustard hatching)
        do {
            var g = c
            g.translateBy(x: e.x, y: e.y)
            g.rotate(by: .radians(ang))
            let la = BP.pr(u, 0.3, 0.8)
            for k in 0..<11 {
                let k3 = (4...6).contains(k) ? tired : 0.0
                let cell = afCell(k, r: r - 0.5, th: th)
                g.fill(cell, with: .color(BP.paper.opacity(la * (1 - k3))))
                g.fill(cell, with: .color(BP.Hue.pistachio.opacity(0.18 * la * (1 - k3))))
                g.stroke(cell, with: .color(BP.Hue.pistachio.opacity(la * (1 - k3))), lineWidth: BP.hair)
            }
        }

        // the spot lies along the line from the patch, through the eye, out to the scene
        let sp = BP.pr(u, 0.6, 1.0)
        let sa = sp * tired
        let m = r - th / 2
        let patch = BP.pt(e.x - m * sin(ang), e.y + m * cos(ang))
        let spotAt = BP.pt(e.x + (e.y - 74) * tan(ang), 74)
        afRay(&c, [patch, spotAt], p: sp, color: acc, alpha: 0.85 * tired, phase: still ? 0 : clock * 12)
        afSpot(&c, at: spotAt, r: 15 * BP.eout(sp), acc: acc, alpha: tired)

        // labels: the first rides on the rim of the patch, the second shows once the cells have recovered
        let rim = BP.pt(e.x - (r + 1) * sin(ang), e.y + (r + 1) * cos(ang))
        afGroup(&c, alpha: 1 - BP.pr(u, 5.2, 5.7)) { g in
            bpLeader(&g, anchor: rim, elbow: BP.pt(198, 260), tail: 0, text: "TIRED CELLS", ink: acc, p: BP.pr(u, 0.5, 1.1))
        }
        bpLeader(&c, anchor: BP.pt(e.x, e.y + r + 1), elbow: BP.pt(134, 260), tail: -4, text: "CELLS RECOVER:\nSPOT FADES", ink: BP.Hue.pistachio, p: BP.pr(u, 5.5, 6.2))
    }
}
