import SwiftUI

// "Why do you see spots after looking at a bright light?" pictures in the airbrush style on paper (2026-11-03), all four cards.
// Thin black line; sprayed blue for the wall and its clouds, orange for the person and the floor, an airbrushed yellow-green glow for the flash and the
// spot's halo. Labels are the slide's own words in green condensed capitals. On a swipeable card each picture loops; narrated it plays once with the voice
// and holds. Drawn in the default 343 x 320 design space.

// MARK: - Card 1: the flash, then the spot on the wall and the floor

struct AfterABSpot: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 5.8

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 3.0,
                       label: "First, a round person stands facing a camera on a tripod that fires a flash, glowing yellow and green, at their face. Then a frame shows a plain blue wall with a dark spot hanging in the middle of it, with a yellow-green halo. The view swings down to an orange floor, and the dark spot stays in the same place on screen while the wall slides up and the floor comes into view. Labels say: flash, wall, dark spot, floor.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u, clock, held) }
                       })
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ clock: Double, _ still: Bool) {
        let ink = AB.ink
        func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        func pts(_ a: [(Double, Double)]) -> [CGPoint] { a.map { CGPoint(x: $0.0, y: $0.1) } }

        // part one: the flash
        let aIn = BP.eout(BP.pr(u, 0, 0.5)), aOut = 1 - BP.pr(u, 1.9, 2.3)
        AB.group(&c, alpha: aIn * aOut) { g in
            g.translateBy(x: 6, y: 14)
            g.scaleBy(x: 1.1, y: 1.1)
            let on = BP.pr(u, 0, 0.8)

            // the clouds sit low behind the person and high behind the camera, clear of the head, the camera and the flash
            AB.spray(&g, at: pt(92, 204), rx: 104, ry: 38, color: AB.blue, grow: BP.eout(BP.pr(u, 0, 0.9)), seed: 11)
            AB.spray(&g, at: pt(250, 62), rx: 60, ry: 30, color: AB.blue, grow: BP.eout(BP.pr(u, 0.1, 1.0)), seed: 23)
            AB.stroke(&g, pts([(-4, 138), (50, 126), (120, 142), (190, 118), (240, 100), (280, 94), (304, 98)]), clock: clock, seed: 1, p: on)
            AB.stroke(&g, pts([(-4, 224), (70, 240), (160, 218), (304, 198)]), clock: clock, seed: 2, p: on)
            AB.stroke(&g, pts([(20, 241), (150, 242)]), clock: clock, seed: 3, p: on)
            AB.stroke(&g, pts([(176, 241), (286, 239)]), clock: clock, seed: 4, p: on)
            AB.stroke(&g, pts([(44, 241), (46, 232), (50, 230), (52, 241), (55, 234), (58, 235), (59, 241)]), clock: clock, seed: 5, p: on, amp: 0.3)

            AB.person(&g, feet: pt(98, 238), clock: clock, seed: 10, p: on, blink: u > 1.1)

            // the camera on its tripod
            AB.stroke(&g, [pt(231, 152), pt(213, 238)], clock: clock, seed: 30, p: on)
            AB.stroke(&g, [pt(231, 152), pt(249, 237)], clock: clock, seed: 31, p: on)
            AB.stroke(&g, [pt(231, 152), pt(232, 238)], clock: clock, seed: 32, p: on)
            let body = AB.box(CGRect(x: 204, y: 120, width: 50, height: 33), radius: 4), lens = AB.box(CGRect(x: 192, y: 128, width: 12, height: 18), radius: 2)
            AB.paint(&g, body, clock: clock, seed: 33, p: on, with: .color(AB.paper))     // paper-filled, so nothing shows through the camera
            AB.paint(&g, lens, clock: clock, seed: 34, p: on, with: .color(AB.paper))
            AB.stroke(&g, body, closed: true, clock: clock, seed: 33, p: on)
            AB.stroke(&g, lens, closed: true, clock: clock, seed: 34, p: on)

            // the flash and its light, travelling to the face
            let pop = BP.eout(BP.pr(u, 0.7, 0.95))
            AB.glow(&g, at: pt(174, 136), r: 28 * pop, inner: AB.yellow, outer: AB.lime, alpha: pop)
            if pop > 0.05 {
                var star = Path()
                for (a, b) in [((174.0, 121.0), (174.0, 151.0)), ((159, 136), (189, 136)), ((164, 126), (184, 146)), ((184, 126), (164, 146))] {
                    let m = pt(174, 136)
                    star.move(to: pt(m.x + (a.0 - m.x) * pop, m.y + (a.1 - m.y) * pop)); star.addLine(to: pt(m.x + (b.0 - m.x) * pop, m.y + (b.1 - m.y) * pop))
                }
                g.stroke(star, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            let ph = still ? 0 : clock * 16
            for y in [112.0, 118.0] {
                g.stroke(AB.dashPath(pt(152, y + 18), pt(128, y), p: BP.pr(u, 0.8, 1.3), on: 3, off: 7, phase: ph), with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            AB.label(&g, "FLASH", anchor: pt(174, 112), to: pt(174, 92), side: 0, clock: clock, seed: 50, p: BP.pr(u, 0.4, 1.0))
        }

        // part two: a frame showing the wall, with the spot, and the view swinging down to the floor
        let frame = CGRect(x: 36, y: 26, width: 204, height: 196)
        let fa = BP.eout(BP.pr(u, 2.2, 2.7))
        let pan = BP.eio(BP.pr(u, 3.9, 5.3))
        let bd = BP.mix(280, 74, pan)          // where the wall meets the floor, on screen
        AB.group(&c, alpha: fa) { g in
            AB.spray(&g, at: pt(138, 128), rx: 88, ry: 90, color: AB.blue, grow: BP.eout(BP.pr(u, 2.2, 3.0)), seed: 61)

            var s = g
            s.clip(to: Path(roundedRect: frame, cornerRadius: 8))
            s.fill(Path(CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: max(0, bd - frame.minY))), with: .color(AB.blue))
            s.fill(Path(CGRect(x: frame.minX, y: bd, width: frame.width, height: 300)), with: AB.vgrad(AB.orange, AB.salmon, y0: bd, y1: bd + 200))

            // wall: courses of bricks, anchored to the floor line so they travel with it
            var bricks: [(CGPoint, CGPoint)] = []
            var j = 1
            while bd - 24 * Double(j) > frame.minY - 24 {
                let y = bd - 24 * Double(j)
                bricks.append((pt(frame.minX, y), pt(frame.maxX, y)))
                let off = j % 2 == 0 ? 0.0 : 20.0
                for k in 0..<6 { let x = frame.minX + off + 40 * Double(k); bricks.append((pt(x, y), pt(x, y + 24))) }
                j += 1
            }
            AB.lines(&s, bricks, color: Color.white.opacity(0.28))

            // floor: boards running away from the wall
            var boards: [(CGPoint, CGPoint)] = []
            for k in -6...6 { let kx = Double(k); boards.append((pt(138 + kx * 14, bd), pt(138 + kx * 64, bd + 230))) }
            for d in [14.0, 34.0, 64.0, 104.0, 158.0, 226.0] { boards.append((pt(frame.minX, bd + d), pt(frame.maxX, bd + d))) }
            AB.lines(&s, boards, color: ink.opacity(0.4))
            AB.lines(&s, [(pt(frame.minX, bd), pt(frame.maxX, bd))], color: ink, width: 2)

            AB.stroke(&g, AB.box(frame, radius: 8), closed: true, clock: clock, seed: 81, offset: CGSize(width: 3, height: -3))

            // the spot: it never moves on screen
            let k = BP.eout(BP.pr(u, 2.8, 3.3))
            AB.glow(&g, at: pt(138, 128), r: 40 * k, inner: AB.yellow, outer: AB.lime, alpha: 0.9)
            AB.glow(&g, at: pt(138, 128), r: 24 * k, inner: ink.opacity(0.95), outer: ink.opacity(0.9))

            // the swing: an arrow down beside the frame
            let ap = BP.pr(u, 3.8, 4.3)
            if ap > 0.01 {
                let tip = pt(20, 176)
                g.stroke(AB.dashPath(pt(20, 72), tip, p: 1, phase: still ? 0 : clock * 14), with: .color(ink.opacity(0.85 * ap)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                g.stroke(AB.headPath(pt(20, 150), tip), with: .color(ink.opacity(0.85 * ap)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            }

            AB.label(&g, "WALL", anchor: pt(216, 50), to: pt(254, 50), clock: clock, seed: 100, p: BP.pr(u, 3.6, 4.2))
            AB.label(&g, "DARK SPOT", anchor: pt(160, 128), to: pt(254, 128), clock: clock, seed: 110, p: BP.pr(u, 3.2, 3.9))
            AB.label(&g, "FLOOR", anchor: pt(216, 190), to: pt(254, 190), clock: clock, seed: 120, p: BP.pr(u, 5.0, 5.6))
        }
    }
}

// MARK: - Shared pieces for cards 2 to 4

/// An eye-local point `deg` degrees round from the front (clockwise), `rad` from the centre. The front is straight up.
private func abPol(_ deg: Double, _ rad: Double) -> CGPoint {
    let a = deg * Double.pi / 180
    return CGPoint(x: rad * sin(a), y: -rad * cos(a))
}

/// One cell of the layer at the back of the eye: k 0...10, centred on the back (k 5), ten degrees apart.
private func abCell(_ k: Int, r: Double, th: Double) -> Path {
    let mid = 180 + Double(k - 5) * 10, hw = 4.3
    var p = Path()
    for i in 0...3 {
        let q = abPol(mid - hw + 2 * hw * Double(i) / 3, r)
        if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
    }
    for i in stride(from: 3, through: 0, by: -1) { p.addLine(to: abPol(mid - hw + 2 * hw * Double(i) / 3, r - th)) }
    p.closeSubpath()
    return p
}

/// Thin diagonal ink hatching inside `clip`: the mark for tired cells.
private func abHatch(_ c: inout GraphicsContext, clip: Path, alpha: Double, step: Double = 3.2) {
    guard alpha > 0.01 else { return }
    var g = c
    g.clip(to: clip)
    let b = clip.boundingRect.insetBy(dx: -2, dy: -2)
    var h = Path()
    var x = b.minX - b.height
    while x < b.maxX { h.move(to: CGPoint(x: x, y: b.maxY)); h.addLine(to: CGPoint(x: x + b.height, y: b.minY)); x += step }
    g.stroke(h, with: .color(AB.ink.opacity(alpha)), lineWidth: 1.1)
}

/// A dashed ray along `pts`, drawn on by `p`; `phase` marches the dashes.
private func abRay(_ c: inout GraphicsContext, _ pts: [CGPoint], p: Double, alpha: Double = 1, phase: Double = 0) {
    guard p > 0.001, alpha > 0.01, pts.count > 1 else { return }
    var path = Path(); path.addLines(pts)
    c.stroke(path.trimmedPath(from: 0, to: BP.cl(p)), with: .color(AB.ink.opacity(alpha)),
             style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round, dash: [3, 7], dashPhase: -phase))
}

/// The dark spot: an airbrushed dark disc, with a yellow-green halo round it when `halo` is above 0 (its radius as a multiple of `r`).
private func abSpot(_ c: inout GraphicsContext, at m: CGPoint, r: Double, halo: Double = 1.7, alpha: Double = 1) {
    guard alpha > 0.01, r > 0.5 else { return }
    if halo > 0 { AB.glow(&c, at: m, r: r * halo, inner: AB.yellow, outer: AB.lime, alpha: 0.9 * alpha) }
    AB.glow(&c, at: m, r: r, inner: AB.ink.opacity(0.95), outer: AB.ink.opacity(0.9), alpha: alpha)
}

/// A cutaway eye (cornea and iris at the front, lens, a thick layer of cells on the back wall), centred at `e`, radius `r`, its front pointing `ang`
/// radians clockwise from straight up. The middle three cells of the layer are `tired` 0...1: they go pale, hatched, with a yellow-green glow behind.
/// `p` draws the eye on.
private func abEye(_ c: inout GraphicsContext, at e: CGPoint, r: Double, ang: Double, tired: Double, p: Double, clock: Double, seed: Int) {
    guard p > 0.001 else { return }
    var g = c
    g.translateBy(x: e.x, y: e.y)
    g.rotate(by: .radians(ang))
    let th = r * 0.17, fa = BP.pr(p, 0.3, 0.8)

    // the ball, with the cornea bulging at the front
    var ball: [CGPoint] = (0...74).map { abPol(32 + 296 * Double($0) / 74, r) }
    let p0 = abPol(328, r), p1 = abPol(32, r), ctl = CGPoint(x: 0, y: -1.5 * r)
    for i in 1..<10 {
        let t = Double(i) / 10
        ball.append(CGPoint(x: (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * ctl.x + t * t * p1.x, y: (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * ctl.y + t * t * p1.y))
    }
    AB.paint(&g, ball, clock: clock, seed: seed, p: fa, with: .color(.white))
    AB.stroke(&g, ball, closed: true, clock: clock, seed: seed, p: p, offset: CGSize(width: 3, height: -3))

    // the tired patch's glow, behind the cells
    AB.glow(&g, at: abPol(180, r - th / 2), r: 30 * tired, inner: AB.yellow, outer: AB.lime, alpha: tired * fa)

    // the layer of cells on the back wall
    var cg = g
    cg.opacity = g.opacity * fa
    for k in 0..<11 {
        let k3 = (4...6).contains(k) ? tired : 0.0
        let cell = abCell(k, r: r - 0.5, th: th)
        cg.fill(cell, with: .color(.white))
        cg.fill(cell, with: .color(AB.orange.opacity(1 - 0.78 * k3)))
        cg.stroke(cell, with: .color(AB.ink), lineWidth: 1.2)
        if k3 > 0.01 { abHatch(&cg, clip: cell, alpha: 0.75 * k3) }
    }

    // iris and lens
    var iris = Path()
    for s in [-1.0, 1.0] { iris.move(to: CGPoint(x: s * 0.545 * r, y: -0.80 * r)); iris.addLine(to: CGPoint(x: s * 0.2 * r, y: -0.74 * r)) }
    cg.stroke(iris, with: .color(AB.ink), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
    let lens = Path(ellipseIn: CGRect(x: -0.3 * r, y: -0.71 * r, width: 0.6 * r, height: 0.26 * r))
    cg.fill(lens, with: .color(AB.blue.opacity(0.4)))
    cg.stroke(lens, with: .color(AB.ink), lineWidth: 1.4)
}

// MARK: - Card 2: the flash lands on the layer of cells at the back of the eye, and one patch of it tires

struct AfterABEye: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 5.0

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 3.5,
                       label: "A cutaway eye seen from the side, its front on the left, with a thick layer of orange cells on the back wall on the right. A flash on the left sends rays in through the front and through the lens, and they meet at the middle of the layer of cells. Then that patch of cells goes pale and hatched, with a yellow-green glow, tired, while the cells around it stay bright orange. Labels say: flash, layer of cells at the back of your eye, tired cells.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u, clock, held) }
                       })
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ clock: Double, _ still: Bool) {
        func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        let e = pt(140, 156), r = 64.0, th = r * 0.17
        let tired = BP.eio(BP.pr(u, 3.5, 4.4))

        AB.spray(&c, at: pt(150, 198), rx: 108, ry: 32, color: AB.blue, grow: BP.eout(BP.pr(u, 0, 0.8)), seed: 31)
        AB.spray(&c, at: pt(268, 70), rx: 50, ry: 26, color: AB.blue, grow: BP.eout(BP.pr(u, 0.1, 0.9)), seed: 33)

        abEye(&c, at: e, r: r, ang: -Double.pi / 2, tired: tired, p: BP.pr(u, 0, 0.7), clock: clock, seed: 40)

        // the flash
        let sa = BP.pr(u, 2.0, 2.4), bump = sin(Double.pi * BP.pr(u, 2.6, 3.1))
        let fr = 11 * (1 + 0.4 * bump) * sa
        AB.glow(&c, at: pt(26, 156), r: 2.4 * fr, inner: AB.yellow, outer: AB.lime, alpha: sa)
        if fr > 0.5 {
            var star = Path()
            for (dx, dy) in [(0.0, -1.0), (1.0, 0.0), (0.7, -0.7), (0.7, 0.7)] {
                star.move(to: pt(26 - dx * fr, 156 - dy * fr)); star.addLine(to: pt(26 + dx * fr, 156 + dy * fr))
            }
            c.stroke(star, with: .color(AB.ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // its light: in through the front, bent by the lens, meeting at the back of the layer of cells
        let ph = still ? 0 : clock * 14
        let rayA = (1 - 0.65 * BP.pr(u, 3.5, 4.2)) * 0.95
        for a in [-12.0, -6.0, 0.0, 6.0, 12.0] {
            abRay(&c, [pt(44, 156), pt(e.x - 0.58 * r, 156 + a), pt(e.x + r - th - 1, 156)], p: BP.pr(u, 2.4, 3.3), alpha: rayA, phase: ph)
        }

        AB.label(&c, "FLASH", anchor: pt(26, 142), to: pt(26, 116), side: 0, clock: clock, seed: 50, p: BP.pr(u, 1.9, 2.5))
        AB.label(&c, "LAYER OF CELLS\nAT THE BACK\nOF YOUR EYE", anchor: pt(184.9, 193.7), to: pt(185, 238), side: 0, below: true, size: 18, clock: clock, seed: 55, p: BP.pr(u, 0.9, 1.6))
        AB.label(&c, "TIRED CELLS", anchor: pt(e.x + r - th / 2, 156), to: pt(232, 156), clock: clock, seed: 60, p: BP.pr(u, 4.0, 4.6))
    }
}

// MARK: - Card 3: tired cells send weaker signals, so the picture has a dark spot over them

struct AfterABCells: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 5.0

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 2.4,
                       label: "A row of eleven cells, lit evenly by a plain blue wall below them. The three in the middle are tired, pale and hatched, with a yellow-green glow. Each cell sends a line up to a picture frame at the top: the eight normal cells send thick bright blue lines, strong signals, and the three tired cells send thin faint dashed lines, weak signals. The frame fills in column by column, blue above the normal cells and with a dark spot above the three tired ones, exactly as wide as they are. Labels say: normal cells, strong signal; tired cells, weak signal; what you see.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u, clock, held) }
                       })
    }

    private static func cx(_ i: Int) -> Double { 25.5 + 18 * Double(i) }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ clock: Double, _ still: Bool) {
        func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        let ink = AB.ink
        let cellTop = 168.0
        let frame = CGRect(x: 16.5, y: 14, width: 198, height: 78)
        let spotRect = CGRect(x: 88.5, y: 24, width: 54, height: 58)       // exactly the width of columns 4...6
        let tired = BP.eio(BP.pr(u, 1.3, 2.0))

        // the plain wall below, and the even light it sends up into every cell
        AB.group(&c, alpha: BP.eout(BP.pr(u, 0.3, 0.8))) { g in
            let wall = AB.box(CGRect(x: 16.5, y: 214, width: 198, height: 12), radius: 2)
            AB.paint(&g, wall, clock: clock, seed: 71, with: .color(AB.blue))
            AB.stroke(&g, wall, closed: true, clock: clock, seed: 71, offset: CGSize(width: 3, height: -3))
            var arrows = Path()
            for k in 0...11 {
                let x = 16.5 + 18 * Double(k)
                arrows.move(to: pt(x, 210)); arrows.addLine(to: pt(x, 199))
                arrows.addPath(AB.headPath(pt(x, 210), pt(x, 199), size: 5))
            }
            g.stroke(arrows, with: .color(AB.blue), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        }

        // the row of cells; the middle three tire, with a glow behind them
        AB.glow(&c, at: pt(cx(5), cellTop + 13), r: 38 * tired, inner: AB.yellow, outer: AB.lime, alpha: BP.eout(BP.pr(u, 0, 0.6)))
        for i in 0..<11 {
            let k = (4...6).contains(i) ? tired : 0.0
            let pts = AB.box(CGRect(x: cx(i) - 7.5, y: cellTop, width: 15, height: 26), radius: 3)
            AB.group(&c, alpha: BP.eout(BP.pr(u, 0, 0.6))) { g in
                AB.paint(&g, pts, clock: clock, seed: 80 + i, with: .color(.white))
                AB.paint(&g, pts, clock: clock, seed: 80 + i, with: .color(AB.orange.opacity(1 - 0.78 * k)))
                AB.stroke(&g, pts, closed: true, clock: clock, seed: 80 + i, width: 1.6, offset: CGSize(width: 1.5, height: -1.5), amp: 0.4)
                if k > 0.01 { abHatch(&g, clip: Path(roundedRect: CGRect(x: cx(i) - 7.5, y: cellTop, width: 15, height: 26), cornerRadius: 3), alpha: 0.75 * k) }
            }
        }

        // the signals: thick and bright from normal cells, thin and faint from tired ones
        for i in 0..<11 {
            let p = BP.pr(u, 2.2 + 0.05 * Double(i), 2.9 + 0.05 * Double(i))
            var line = Path(); line.move(to: pt(cx(i), cellTop - 1)); line.addLine(to: pt(cx(i), frame.maxY + 1))
            if (4...6).contains(i) { bpTrace(&c, line, p: p, color: ink.opacity(0.7), width: 1.2, dash: [3, 4]) }
            else { bpTrace(&c, line, p: p, color: AB.blue, width: 3.4) }
        }

        // the picture frame, filled column by column from the same cells
        let box = Path(roundedRect: frame, cornerRadius: 5)
        AB.group(&c, alpha: BP.eout(BP.pr(u, 2.4, 2.9))) { g in g.fill(box, with: .color(.white)) }
        for i in 0..<11 {
            let rv = BP.eout(BP.pr(u, 2.9 + 0.12 * Double(i), 3.4 + 0.12 * Double(i)))
            guard rv > 0.001 else { continue }
            var s = c
            s.clip(to: box)
            let col = CGRect(x: 16.5 + 18 * Double(i), y: frame.maxY - frame.height * rv, width: 18, height: frame.height * rv)
            s.clip(to: Path(col))
            s.fill(Path(col), with: .color(AB.blue.opacity(0.85)))
            if (4...6).contains(i) { s.fill(Path(ellipseIn: spotRect), with: .color(ink.opacity(0.93))) }
        }
        AB.group(&c, alpha: BP.eout(BP.pr(u, 2.4, 2.9))) { g in
            AB.stroke(&g, AB.box(frame, radius: 5), closed: true, clock: clock, seed: 90, offset: CGSize(width: 3, height: -3))
        }
        AB.group(&c, alpha: BP.pr(u, 4.2, 4.7)) { g in g.stroke(Path(ellipseIn: spotRect), with: .color(AB.lime), lineWidth: 2.6) }

        AB.label(&c, "NORMAL CELLS:\nSTRONG SIGNAL", anchor: pt(cx(10), 181), to: pt(226, 181), size: 18, clock: clock, seed: 100, p: BP.pr(u, 0.8, 1.4))
        AB.label(&c, "TIRED CELLS:\nWEAK SIGNAL", anchor: pt(cx(5), 194), to: pt(cx(5), 244), side: 0, below: true, size: 18, clock: clock, seed: 110, p: BP.pr(u, 1.9, 2.5))
        AB.label(&c, "WHAT YOU SEE", anchor: pt(210, 53), to: pt(226, 53), size: 18, clock: clock, seed: 120, p: BP.pr(u, 3.0, 3.6))
    }
}

// MARK: - Card 4: the spot follows the eyes; then the cells recover and it fades

struct AfterABTurn: View {
    let active: Bool
    @Environment(\.pictureClock) private var narrated
    private static let story = 6.5

    var body: some View {
        let isNarrated = narrated != nil
        return BlueprintStage(active: active, length: Self.story, tick: 1.0,
                       label: "At the top, a still scene on a blue sky: a house, a tree with a yellow-green crown and a lamp post along a horizon. Below it, an eye seen from above, with a tired patch of cells, pale and hatched, on its back wall. A dark spot sits on the scene along the line from the tired patch through the eye. The eye turns left, then right, then back to the middle, and the dark spot slides across the still scene with it, because the patch turns with the eye. Then the cells recover, the patch goes bright, and the spot fades away. Labels say: tired cells; cells recover, spot fades.",
                       draw: { c, t, _, clock in
                           let (u, held) = AB.time(t, clock, story: Self.story, narrated: isNarrated)
                           AB.group(&c, alpha: held ? 1 : AB.fade(u, Self.story, narrated: isNarrated)) { g in Self.draw(&g, u, clock, held) }
                       })
    }

    private static func draw(_ c: inout GraphicsContext, _ u: Double, _ clock: Double, _ still: Bool) {
        func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        func pts(_ a: [(Double, Double)]) -> [CGPoint] { a.map { CGPoint(x: $0.0, y: $0.1) } }
        let ink = AB.ink
        let e = pt(171, 186), r = 42.0, th = r * 0.17
        let turn = 0.7
        let k1 = BP.eio(BP.pr(u, 1.0, 2.0)), k2 = BP.eio(BP.pr(u, 2.2, 3.8)), k3 = BP.eio(BP.pr(u, 4.0, 5.0))
        let ang = turn * (-k1 + 2 * k2 - k3)
        let tired = 1 - BP.eio(BP.pr(u, 5.3, 6.1))

        // the scene, which never moves
        AB.group(&c, alpha: BP.eout(BP.pr(u, 0, 0.6))) { g in
            let panelRect = CGRect(x: 22, y: 26, width: 299, height: 92)
            let panel = Path(roundedRect: panelRect, cornerRadius: 8)
            g.fill(panel, with: .color(.white.opacity(0.7)))
            var s = g
            s.clip(to: panel)
            AB.spray(&s, at: pt(150, 54), rx: 130, ry: 34, color: AB.blue, seed: 131)
            s.fill(Path(CGRect(x: 22, y: 104, width: 299, height: 14)), with: AB.vgrad(AB.orange, AB.salmon, y0: 104, y1: 118))
            s.stroke(Path { $0.move(to: pt(22, 104)); $0.addLine(to: pt(321, 104)) }, with: .color(ink), lineWidth: 1.6)

            // house
            let roof = pts([(45, 76), (70, 56), (95, 76)]), houseBody = AB.box(CGRect(x: 50, y: 76, width: 40, height: 28), radius: 1)
            AB.paint(&s, houseBody, clock: clock, seed: 140, with: .color(AB.salmon))
            AB.paint(&s, roof, clock: clock, seed: 141, with: .color(AB.orange))
            AB.stroke(&s, houseBody, closed: true, clock: clock, seed: 140, offset: CGSize(width: -2, height: -2))
            AB.stroke(&s, roof, closed: true, clock: clock, seed: 141, offset: CGSize(width: -2, height: -2))
            AB.stroke(&s, AB.box(CGRect(x: 65, y: 88, width: 10, height: 16), radius: 1), closed: true, clock: clock, seed: 142, width: 1.6)

            // tree: an airbrushed crown on a trunk
            AB.glow(&s, at: pt(171, 70), r: 25, inner: AB.yellow, outer: AB.lime)
            let trunk = AB.box(CGRect(x: 167, y: 86, width: 8, height: 18), radius: 1)
            AB.paint(&s, trunk, clock: clock, seed: 143, with: AB.vgrad(AB.orange, AB.salmon, y0: 86, y1: 104))
            AB.stroke(&s, trunk, closed: true, clock: clock, seed: 143, width: 1.8, offset: CGSize(width: -1.5, height: -1))

            // lamp post
            AB.stroke(&s, pts([(272, 104), (272, 60), (282, 60)]), clock: clock, seed: 144)
            AB.paint(&s, AB.box(CGRect(x: 279, y: 60, width: 10, height: 5), radius: 1.5), clock: clock, seed: 145, with: .color(AB.orange))
        }
        AB.group(&c, alpha: BP.eout(BP.pr(u, 0, 0.6))) { g in
            AB.stroke(&g, AB.box(CGRect(x: 22, y: 26, width: 299, height: 92), radius: 8), closed: true, clock: clock, seed: 150, offset: CGSize(width: 3, height: -3))
        }

        // the eye turns, carrying its tired patch with it
        abEye(&c, at: e, r: r, ang: ang, tired: tired, p: BP.pr(u, 0, 0.7), clock: clock, seed: 160)

        // the spot lies along the line from the patch, through the eye, out to the scene
        let sp = BP.pr(u, 0.6, 1.0)
        let sa = sp * tired
        let m = r - th / 2
        let patch = pt(e.x - m * sin(ang), e.y + m * cos(ang))
        let spotAt = pt(e.x + (e.y - 74) * tan(ang), 74)
        abRay(&c, [patch, spotAt], p: sp, alpha: 0.85 * tired, phase: still ? 0 : clock * 12)
        abSpot(&c, at: spotAt, r: 15 * BP.eout(sp), alpha: tired)

        // labels: the first rides on the rim of the patch, the second shows once the cells have recovered
        let rim = pt(e.x - (r + 1) * sin(ang), e.y + (r + 1) * cos(ang))
        AB.group(&c, alpha: 1 - BP.pr(u, 5.2, 5.7)) { g in
            AB.label(&g, "TIRED CELLS", anchor: rim, to: pt(198, 258), clock: clock, seed: 170, p: BP.pr(u, 0.5, 1.1))
        }
        AB.label(&c, "CELLS RECOVER:\nSPOT FADES", anchor: pt(e.x, e.y + r + 1), to: pt(134, 258), side: -1, size: 20, clock: clock, seed: 180, p: BP.pr(u, 5.5, 6.2))
    }
}
