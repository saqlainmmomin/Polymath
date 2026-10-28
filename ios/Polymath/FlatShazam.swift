import SwiftUI

// "How can your phone name a song from a few noisy seconds?" pictures, drawn as blueprint technical illustrations (2026-10-28).
// Each card is one picture on blueprint paper: one chalk-ink colour, one mustard accent (music, and the codes), thin even lines,
// flat tints, mono uppercase labels that use the slide text's own words. Built from the shared pieces in Blueprint.swift.
// A picture starts once its card has settled, plays one action (about 2-3.4 s), then holds; tap replays, Reduce Motion shows the end state.
// Card 1 is the exception: its sounds keep flowing until the song is found. Drawn in a 343 x 340 design space (card 1: 330 x 340);
// keep clear of the bottom-right corner (x > 285, y > 255), where like and save sit.

// MARK: - Blueprint cards 1-3 share a 343 x 340 design space (keep clear of x > 285, y > 255, where like and save sit)

private let bpSize = CGSize(width: 343, height: 340)

/// A fixed pseudo-random number 0...1 for a cell or dot, so pictures never shimmer between frames.
private func hash2(_ a: Int, _ b: Int) -> Double {
    let v = sin(Double(a) * 12.9898 + Double(b) * 78.233) * 43758.5453
    return abs(v - v.rounded(.down))
}

/// The loudest dots, as (column, row) cells of the time-pitch chart; row 0 is the highest note. Cards 2 and 3 both draw these.
private let peakCells: [(c: Int, r: Int)] = [(1, 5), (2, 2), (4, 8), (5, 4), (7, 1), (8, 6), (10, 3), (11, 8), (13, 5), (14, 2)]

// MARK: - Card 1: a café corner; chatter comes from the left tables, music from the speaker on the right, both flow into the phone

struct ShazamListen: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 3.0,
                       label: "A cutaway café. One person sits alone at a small table in the middle, holding up a phone that is listening. At the tables on either side, two people chat, with speech bubbles above them, and broken grey rings of sound drift to the phone. Speakers high on the two back walls send gold music notes and smooth waves to the same phone. A ring fills around the phone and a measuring line grows along the floor, for a few seconds. Then a gold tag with a note pops up: the song was found.",
                       draw: { c, t, pal, clock in Self.draw(&c, t, pal, clock) }, size: CGSize(width: 330, height: 340))
    }

    private static let iso = Iso(origin: BP.pt(157.6, 146), scale: 16)
    private static let zf = 0.8, seatZ = 2.2, tableZ = 2.8
    private static let ex = SIMD3(1.0, 0, 0), ey = SIMD3(0, 1.0, 0), ez = SIMD3(0, 0, 1.0)

    private static func quad(_ pts: [CGPoint]) -> Path { var q = Path(); q.addLines(pts); q.closeSubpath(); return q }

    /// A chair with legs, a seat and a back on one side (`back` 0: toward -y, 1: toward -x). (x, y) is the middle of the seat.
    private static func chair(_ c: inout GraphicsContext, _ x: Double, _ y: Double, back: Int, ink: Color) {
        var legs = Path()
        for (dx, dy) in [(-0.5, -0.5), (0.5, -0.5), (-0.5, 0.5), (0.5, 0.5)] { legs.move(to: iso.p(x + dx, y + dy, zf)); legs.addLine(to: iso.p(x + dx, y + dy, seatZ - 0.18)) }
        c.stroke(legs, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        if back == 0 { bpSlab(&c, iso, x: x - 0.6, y: y - 0.8, z: seatZ, w: 1.2, d: 0.16, h: 1.7, ink: ink) }
        else { bpSlab(&c, iso, x: x - 0.8, y: y - 0.6, z: seatZ, w: 0.16, d: 1.2, h: 1.7, ink: ink) }
        bpSlab(&c, iso, x: x - 0.6, y: y - 0.6, z: seatZ - 0.18, w: 1.2, d: 1.2, h: 0.18, ink: ink)
    }

    /// A small square café table whose corner is (x, y) and side `s`.
    private static func table(_ c: inout GraphicsContext, _ x: Double, _ y: Double, s: Double, ink: Color) {
        bpSlab(&c, iso, x: x + s / 2 - 0.5, y: y + s / 2 - 0.5, z: zf, w: 1, d: 1, h: 0.1, ink: ink)
        bpSlab(&c, iso, x: x + s / 2 - 0.15, y: y + s / 2 - 0.15, z: zf + 0.1, w: 0.3, d: 0.3, h: 1.7, ink: ink)
        bpSlab(&c, iso, x: x, y: y, z: tableZ - 0.2, w: s, d: s, h: 0.2, ink: ink)
    }

    /// A cup on a table at (x, y), with two curls of steam.
    private static func cup(_ c: inout GraphicsContext, _ x: Double, _ y: Double, ink: Color, clock: Double) {
        bpSlab(&c, iso, x: x, y: y, z: tableZ, w: 0.5, d: 0.5, h: 0.55, ink: ink)
        let top = iso.p(x + 0.25, y + 0.25, tableZ + 0.55)
        for k in 0..<2 {
            var w = Path()
            for i in 0...8 { let f = Double(i) / 8; let q = BP.pt(top.x + (Double(k) - 0.5) * 5 + sin(clock * 1.6 + Double(k) * 2.2 + f * 5) * 2.2, top.y - 2 - f * 12); if i == 0 { w.move(to: q) } else { w.addLine(to: q) } }
            c.stroke(w, with: .color(ink.opacity(0.45)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
    }

    /// A speech bubble: rounded box, a tail whose tip sits `tail` points from its left edge, and three dots that take turns to swell.
    private static func bubble(_ c: inout GraphicsContext, _ r: CGRect, tail: Double, ink: Color, clock: Double) {
        let k = 8.0
        var path = Path()
        path.move(to: BP.pt(r.minX + k, r.minY))
        path.addArc(tangent1End: BP.pt(r.maxX, r.minY), tangent2End: BP.pt(r.maxX, r.maxY), radius: k)
        path.addArc(tangent1End: BP.pt(r.maxX, r.maxY), tangent2End: BP.pt(r.minX, r.maxY), radius: k)
        path.addLine(to: BP.pt(r.minX + tail + 7, r.maxY)); path.addLine(to: BP.pt(r.minX + tail, r.maxY + 8)); path.addLine(to: BP.pt(r.minX + tail - 5, r.maxY))
        path.addArc(tangent1End: BP.pt(r.minX, r.maxY), tangent2End: BP.pt(r.minX, r.minY), radius: k)
        path.addArc(tangent1End: BP.pt(r.minX, r.minY), tangent2End: BP.pt(r.maxX, r.minY), radius: k)
        path.closeSubpath()
        c.fill(path, with: .color(BP.paper)); c.fill(path, with: .color(ink.opacity(0.08)))
        c.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
        for i in -1...1 {
            let rad = 2.0 + 0.8 * max(0, sin(clock * 5 - Double(i) * 1.3))
            c.fill(Path(ellipseIn: CGRect(x: r.midX + Double(i) * 8 - rad, y: r.midY - rad, width: 2 * rad, height: 2 * rad)), with: .color(ink.opacity(0.7)))
        }
    }

    /// 1 while a speaker's bubble is up (it is up 2.4 s of every 4, offset by `phase`), eased at both ends.
    private static func speaking(_ clock: Double, _ phase: Double) -> Double {
        let m = (clock + phase).truncatingRemainder(dividingBy: 4)
        return BP.pr(m, 0, 0.2) * (1 - BP.pr(m, 2.2, 2.4))
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette, _ clock: Double) {
        c.translateBy(x: -6.5, y: 0)                         // trims the side margin so the room fills the stage
        let ink = pal.ink
        func ps(_ a: Double, _ b: Double) -> Double { BP.eout(BP.pr(t, a, b)) }
        func wall(_ pts: [CGPoint], tint: Double, p: Double) {
            let q = quad(pts); c.fill(q, with: .color(ink.opacity(tint * p))); bpTrace(&c, q, p: p, color: ink)
        }

        // the room, a cutaway box: floor slab with a thick front edge, checker tiles, two back walls
        let pRoom = ps(0, 0.9)
        wall([iso.p(0, 0, zf), iso.p(0, 10, zf), iso.p(0, 10, zf + 7.5), iso.p(0, 0, zf + 7.5)], tint: 0.05, p: pRoom)
        wall([iso.p(0, 0, zf), iso.p(12, 0, zf), iso.p(12, 0, zf + 7.5), iso.p(0, 0, zf + 7.5)], tint: 0.09, p: pRoom)
        bpSlab(&c, iso, x: 0, y: 0, z: 0, w: 12, d: 10, h: zf, ink: ink, p: pRoom)
        for i in 0..<6 { for j in 0..<5 where (i + j) % 2 == 0 {
            let x = Double(i) * 2, y = Double(j) * 2
            c.fill(quad([iso.p(x, y, zf), iso.p(x + 2, y, zf), iso.p(x + 2, y + 2, zf), iso.p(x, y + 2, zf)]), with: .color(ink.opacity(0.07 * pRoom)))
        } }
        let pDeco = ps(0.4, 1.1)
        bpGroup(&c, alpha: pDeco) { g in
            // stipple along the foot of the left wall, and on a rug under the middle table
            for i in 0..<18 { for j in 0..<3 {
                let q = iso.p(0, 0.3 + Double(i) * 0.55 + hash2(i, j) * 0.3, zf + 0.25 + Double(j) * 0.4 + hash2(j, i + 7) * 0.2)
                g.fill(Path(ellipseIn: CGRect(x: q.x - 0.8, y: q.y - 0.8, width: 1.6, height: 1.6)), with: .color(ink.opacity(0.4)))
            } }
            for i in 0..<7 { for j in 0..<7 {
                let q = iso.p(4.6 + Double(i) * 0.6 + hash2(i + 20, j) * 0.3, 5.0 + Double(j) * 0.6 + hash2(j + 20, i) * 0.3, zf)
                g.fill(Path(ellipseIn: CGRect(x: q.x - 0.9, y: q.y - 0.9, width: 1.8, height: 1.8)), with: .color(ink.opacity(0.4)))
            } }
            g.stroke(quad([iso.p(4.4, 4.8, zf), iso.p(8.6, 4.8, zf), iso.p(8.6, 9.2, zf), iso.p(4.4, 9.2, zf)]), with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 3]))
            // window on the left wall, near the back
            let win = quad([iso.p(0, 0.8, 4.4), iso.p(0, 3.4, 4.4), iso.p(0, 3.4, 6.4), iso.p(0, 0.8, 6.4)])
            g.fill(win, with: .color(BP.paper)); g.fill(win, with: .color(ink.opacity(0.06)))
            var fr = win; fr.move(to: iso.p(0, 2.1, 4.4)); fr.addLine(to: iso.p(0, 2.1, 6.4)); fr.move(to: iso.p(0, 0.8, 5.4)); fr.addLine(to: iso.p(0, 3.4, 5.4))
            g.stroke(fr, with: .color(ink), style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
            // menu board on the right wall: an outline with a light tint and a few short ink lines
            let board = quad([iso.p(5.6, 0, 5.2), iso.p(8.4, 0, 5.2), iso.p(8.4, 0, 7.0), iso.p(5.6, 0, 7.0)])
            g.fill(board, with: .color(BP.paper)); g.fill(board, with: .color(ink.opacity(0.12)))
            g.stroke(board, with: .color(ink), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))
            var ln = Path()
            for (z, a, b) in [(6.5, 5.9, 7.6), (6.1, 5.9, 6.9), (5.7, 5.9, 7.3)] { ln.move(to: iso.p(a, 0, z)); ln.addLine(to: iso.p(b, 0, z)) }
            g.stroke(ln, with: .color(ink), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            // pendant lamp, hanging above our person's table
            var cord = Path(); cord.move(to: BP.pt(165, 0)); cord.addLine(to: BP.pt(165, 50))
            let shade = quad([BP.pt(154, 66), BP.pt(176, 66), BP.pt(171, 50), BP.pt(159, 50)])
            g.stroke(cord, with: .color(ink), lineWidth: BP.hair)
            g.fill(shade, with: .color(BP.paper)); g.fill(shade, with: .color(ink.opacity(0.18)))
            g.stroke(shade, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
            let bulb = Path(ellipseIn: CGRect(x: 161.5, y: 66, width: 7, height: 5))
            g.fill(bulb, with: .color(BP.paper)); g.stroke(bulb, with: .color(ink), lineWidth: BP.hair)
        }

        // two speakers high at the far ends of the back walls: the music
        let spkL = SIMD3(0.7, 9.0, 7.0), spkR = SIMD3(10.4, 0.7, 7.0)
        bpGroup(&c, alpha: ps(0.5, 1.1)) { g in
            bpSlab(&g, iso, x: 0, y: 9.0, z: 7.0, w: 0.7, d: 1.0, h: 1.2, ink: ink)
            bpTrace(&g, bpFacePath(iso, o: spkL, ux: ey, vx: ez, u: 0.15, v: 0.1, w: 0.7, h: 0.7, r: 0.35), p: 1, color: ink)
            bpTrace(&g, bpFacePath(iso, o: spkL, ux: ey, vx: ez, u: 0.35, v: 0.85, w: 0.3, h: 0.3, r: 0.15), p: 1, color: ink, width: BP.hair)
            bpSlab(&g, iso, x: 10.4, y: 0, z: 7.0, w: 1.1, d: 0.7, h: 1.2, ink: ink)
            bpTrace(&g, bpFacePath(iso, o: spkR, ux: ex, vx: ez, u: 0.2, v: 0.1, w: 0.7, h: 0.7, r: 0.35), p: 1, color: ink)
            bpTrace(&g, bpFacePath(iso, o: spkR, ux: ex, vx: ez, u: 0.4, v: 0.85, w: 0.3, h: 0.3, r: 0.15), p: 1, color: ink, width: BP.hair)
        }

        // the left table: two people chatting (the second one gestures)
        let tl = (x: 2.8, y: 6.8), trc = (x: 10.3, y: 2.0)
        let l1 = iso.p(1.6, 8.0, seatZ), l2 = iso.p(4.0, 5.6, seatZ), r1 = iso.p(9.4, 2.7, seatZ), r2 = iso.p(11.2, 1.3, seatZ)
        let vL1 = speaking(clock, 0), vL2 = speaking(clock, 2), vR1 = speaking(clock, 3.5), vR2 = speaking(clock, 1.5)
        func hand(_ tc: (x: Double, y: Double), _ dx: Double, _ dy: Double, _ side: Double) -> CGPoint {
            iso.p(tc.x + dx * 0.4 - side * 0.3 * dy, tc.y + dy * 0.4 + side * 0.3 * dx, tableZ)
        }
        bpGroup(&c, alpha: ps(0.5, 1.1)) { g in
            chair(&g, 1.6, 8.0, back: 1, ink: ink); chair(&g, 4.0, 5.6, back: 0, ink: ink)
            bpPerson(&g, base: l1, facing: 1, ink: ink, shirt: 0.16, hair: 1, talk: vL1 > 0.5)
            bpPerson(&g, base: l2, facing: -1, ink: ink, shirt: 0.28, hair: 0, talk: vL2 > 0.5)
            table(&g, tl.x - 0.9, tl.y - 0.9, s: 1.8, ink: ink)
            cup(&g, tl.x - 0.25, tl.y - 0.25, ink: ink, clock: clock)
            for s in [-1.0, 1.0] { bpArm(&g, from: BP.pt(l1.x, l1.y - 24), elbow: BP.pt(l1.x + 10, l1.y - 6 + s * 2), to: hand(tl, -1.2, 1.2, s), ink: ink) }
            bpArm(&g, from: BP.pt(l2.x, l2.y - 24), elbow: BP.pt(l2.x - 14, l2.y - 8), to: hand(tl, 1.2, -1.2, 1), ink: ink)
            let wave = sin(clock * 3.2) * 3
            bpArm(&g, from: BP.pt(l2.x, l2.y - 24), elbow: BP.pt(l2.x - 12, l2.y - 14), to: BP.pt(l2.x - 24 + wave, l2.y - 40 + wave), ink: ink)

            // the right table: another pair (the first one gestures, the second holds a cup)
            chair(&g, 9.4, 2.7, back: 1, ink: ink); chair(&g, 11.2, 1.3, back: 0, ink: ink)
            bpPerson(&g, base: r1, facing: 1, ink: ink, shirt: 0.3, hair: 0, talk: vR1 > 0.5)
            bpPerson(&g, base: r2, facing: -1, ink: ink, shirt: 0.14, hair: 1, talk: vR2 > 0.5)
            table(&g, trc.x - 0.7, trc.y - 0.7, s: 1.4, ink: ink)
            cup(&g, trc.x - 0.25, trc.y - 0.25, ink: ink, clock: clock + 1)
            bpArm(&g, from: BP.pt(r1.x, r1.y - 24), elbow: BP.pt(r1.x + 10, r1.y - 6), to: hand(trc, -1.0, 1.0, 1), ink: ink)
            bpArm(&g, from: BP.pt(r1.x, r1.y - 24), elbow: BP.pt(r1.x + 14, r1.y - 16), to: BP.pt(r1.x + 24 + sin(clock * 3.6 + 1) * 3, r1.y - 38), ink: ink)
            bpArm(&g, from: BP.pt(r2.x, r2.y - 24), elbow: BP.pt(r2.x - 12, r2.y - 8), to: hand(trc, 1.0, -1.0, -1), ink: ink)
        }

        let b = iso.p(6.3, 5.3, seatZ), phone = BP.pt(b.x + 28, b.y - 56)
        // once the song is found (3.0 s) the waves into the phone fade out over 0.4 s and stop; the talking carries on
        let wf = 1 - BP.pr(t, 3.0, 3.4)

        // speech bubbles, taking turns
        for (p, ctr, v, tail) in [(l1, 1.0, vL1, 20.0), (l2, 1.0, vL2, 20.0), (r1, 1.0, vR1, 20.0), (r2, 1.0, vR2, 20.0)] {
            _ = ctr
            let s = BP.mix(0.7, 1, v)
            guard v > 0.01 else { continue }
            var g = c; g.opacity = v
            let o = BP.pt(p.x, p.y - 58)                         // bottom middle, above the head
            g.translateBy(x: o.x, y: o.y); g.scaleBy(x: s, y: s); g.translateBy(x: -o.x, y: -o.y)
            bubble(&g, CGRect(x: p.x - 20, y: p.y - 80, width: 40, height: 22), tail: tail, ink: ink, clock: clock)
        }

        // chatter: bold broken grey arcs from the two side tables toward the phone
        if clock > 0.9 && wf > 0.01 {
            for (src, life, vis) in [(BP.pt(l2.x, l2.y - 69), 1.9, max(vL2, vL1)), (BP.pt(r1.x, r1.y - 69), 1.5, max(vR1, vR2))] {
                let far = hypot(phone.x - src.x, phone.y - src.y) - 9, dir = atan2(phone.y - src.y, phone.x - src.x)
                for j in 0..<3 {
                    let u = (clock - 0.9) / life - Double(j) / 3
                    guard u >= 0 else { continue }
                    let k = u - u.rounded(.down), rad = BP.mix(23, far, k), alpha = BP.pr(k, 0, 0.12) * (1 - BP.pr(k, 0.8, 1)) * BP.mix(0.6, 1, vis) * wf
                    var arc = Path()
                    for i in 0...14 { let a = dir - 0.42 + 0.84 * Double(i) / 14; let q = BP.pt(src.x + rad * cos(a), src.y + rad * sin(a)); if i == 0 { arc.move(to: q) } else { arc.addLine(to: q) } }
                    c.stroke(arc, with: .color(ink.opacity(0.95 * alpha)), style: StrokeStyle(lineWidth: 2, lineCap: .butt, dash: [6, 3]))
                }
            }
        }

        // our person, alone at the small middle table, holding a phone up
        bpGroup(&c, alpha: ps(0.6, 1.2)) { g in
            chair(&g, 6.3, 5.3, back: 0, ink: ink)
            bpPerson(&g, base: b, facing: 0, ink: ink, shirt: 0.34, hair: 0, talk: false)
            table(&g, 5.7, 6.2, s: 1.6, ink: ink)
            cup(&g, 6.9, 6.7, ink: ink, clock: clock + 2)
            bpArm(&g, from: BP.pt(b.x - 11, b.y - 24), elbow: BP.pt(b.x - 20, b.y - 6), to: iso.p(6.1, 6.7, tableZ), ink: ink)
            bpArm(&g, from: BP.pt(b.x + 11, b.y - 24), elbow: BP.pt(b.x + 25, b.y - 14), to: BP.pt(b.x + 27, b.y - 43), ink: ink)
            let body = Path(roundedRect: CGRect(x: phone.x - 6.5, y: phone.y - 11, width: 13, height: 22), cornerRadius: 3)
            g.fill(body, with: .color(BP.paper)); g.stroke(body, with: .color(ink), lineWidth: 1.6)
            g.fill(Path(roundedRect: CGRect(x: phone.x - 4.8, y: phone.y - 8.6, width: 9.6, height: 15.6), cornerRadius: 1.8), with: .color(ink.opacity(0.1)))
            for k in 0..<2 {
                let f = (clock * 0.8 + Double(k) / 2).truncatingRemainder(dividingBy: 1), r = 1.2 + 3.6 * f
                g.stroke(Path(ellipseIn: CGRect(x: phone.x - r, y: phone.y - 1 - r, width: 2 * r, height: 2 * r)), with: .color(pal.accent.opacity(BP.pr(clock, 0.9, 1.3) * (1 - f))), lineWidth: 1.2)
            }
            g.fill(Path(ellipseIn: CGRect(x: phone.x - 1.6, y: phone.y - 2.6, width: 3.2, height: 3.2)), with: .color(pal.accent))
        }

        // the few seconds: a measuring line just outside the front-left edge of the floor, with extension lines, growing left to right
        let fill = BP.eio(BP.pr(t, 0.9, 3.0))
        let ext = BP.pr(t, 0.7, 1.0)
        for x in [2.0, 12.0] { bpGuide(&c, iso.p(x, 10.2, 0), iso.p(x, 11.7, 0), p: ext, color: ink) }
        let tk = iso.p(0, 0.4, 0), t0 = iso.p(0, 0, 0)
        bpDimension(&c, from: iso.p(2, 11.4, 0), to: iso.p(12, 11.4, 0), tick: BP.pt(tk.x - t0.x, tk.y - t0.y), text: "", labelWidth: 0, ink: ink, p: fill)
        bpText(&c, "A FEW SECONDS", BP.pt(70, 312), ink: ink, alpha: BP.pr(t, 0.9, 1.3))

        // music: smooth gold waves and notes from the far end of each back wall into the phone, along curved paths that stay over the tables
        if clock > 0.9 && wf > 0.01 {
            let routes = [(BP.pt(44, 106), BP.pt(64, 24), BP.pt(phone.x - 3, phone.y - 12), 0.0), (BP.pt(288, 118), BP.pt(270, 40), BP.pt(phone.x + 5, phone.y - 12), 0.25)]
            for (p0, p1, p2, off) in routes {
                var pts: [CGPoint] = [], cum: [Double] = [0]
                for i in 0...60 {
                    let u = Double(i) / 60, v = 1 - u
                    pts.append(BP.pt(v * v * p0.x + 2 * u * v * p1.x + u * u * p2.x, v * v * p0.y + 2 * u * v * p1.y + u * u * p2.y))
                    if i > 0 { cum.append(cum[i - 1] + hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)) }
                }
                let len = cum.last!
                func at(_ d: Double) -> (CGPoint, CGPoint) {
                    var i = 1; while i < 60 && cum[i] < d { i += 1 }
                    let seg = max(0.001, cum[i] - cum[i - 1]), f = BP.cl((d - cum[i - 1]) / seg), a = pts[i - 1], b2 = pts[i]
                    return (BP.pt(a.x + (b2.x - a.x) * f, a.y + (b2.y - a.y) * f), BP.pt((b2.x - a.x) / seg, (b2.y - a.y) / seg))
                }
                for j in 0..<2 {
                    let u = (clock - 0.9) / 2.2 - Double(j) / 2 - off
                    guard u >= 0 else { continue }
                    let k = u - u.rounded(.down), alpha = BP.pr(k, 0, 0.1) * (1 - BP.pr(k, 0.85, 1)) * wf, pos = k * len
                    var w = Path(); var first = true
                    for d in stride(from: max(0, pos - 16), through: min(len, pos + 16), by: 1) {
                        let (q, n) = at(d), off2 = 3.8 * sin(d * 2 * .pi / 13)
                        let pt2 = BP.pt(q.x - n.y * off2, q.y + n.x * off2)
                        if first { w.move(to: pt2); first = false } else { w.addLine(to: pt2) }
                    }
                    c.stroke(w, with: .color(pal.accent.opacity(alpha)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    let (q, n) = at(pos)
                    var g = c; g.opacity = alpha
                    bpNote(&g, BP.pt(q.x + n.y * 11, q.y - n.x * 11), s: 10, color: pal.accent)
                }
            }
        }

        // found it: a gold tag with a note pops above the phone once the ring is full
        let pop = BP.pr(t, 3.0, 3.3)
        if pop > 0.001 {
            let s = BP.eout(pop) * (1 + 0.18 * sin(pop * .pi)), tip = BP.pt(phone.x, phone.y - 16 - 7 * BP.eout(pop))
            var g = c; g.translateBy(x: tip.x, y: tip.y); g.scaleBy(x: s, y: s)
            var tag = Path(roundedRect: CGRect(x: -13, y: -24, width: 26, height: 19), cornerRadius: 6)
            tag.move(to: BP.pt(-4, -5)); tag.addLine(to: BP.pt(0, 0)); tag.addLine(to: BP.pt(4, -5)); tag.closeSubpath()
            g.fill(tag, with: .color(pal.accent))
            g.translateBy(x: -2, y: -9)
            bpNote(&g, BP.pt(0, 0), s: 9, color: BP.paper)
        }

        // leader labels, in open space: CHATTER points at whichever left-table bubble is up, MUSIC at the right speaker
        let wl = vL2 / max(0.001, vL1 + vL2), tl1 = BP.pt(l1.x, l1.y - 80), tl2 = BP.pt(l2.x, l2.y - 80)
        bpLeader(&c, anchor: BP.mixp(tl1, tl2, wl), elbow: BP.pt(114, 97), tail: -1, text: "CHATTER", ink: ink, p: BP.pr(t, 1.0, 1.5))
        bpLeader(&c, anchor: iso.p(10.95, 0.35, 8.2), elbow: BP.pt(300, 58), tail: -10, text: "MUSIC", ink: ink, p: BP.pr(t, 1.1, 1.6))
    }
}

// MARK: - Card 2: a sound becomes a time-pitch chart; the dim dots empty out and only the loudest stay

struct ShazamDraw: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 2.1,
                       label: "A phone on the left sends a strip of sound across the top. Under it a chart with time along the bottom and high notes going up fills with many small squares, bigger where the sound is louder. Then the dim ones empty out and a few of the loudest become solid gold dots. A dashed box around one shows it is brighter than everything right around it.",
                       draw: { c, t, pal, _ in Self.draw(&c, t, pal) }, size: bpSize)
    }

    private static let cols = 15, rows = 11
    private static func x(_ i: Int) -> Double { 52 + 15.5 * Double(i) }
    private static func y(_ j: Int) -> Double { 134 + 15 * Double(j) }
    private static func isPeak(_ i: Int, _ j: Int) -> Bool { peakCells.contains { $0.c == i && $0.r == j } }
    private static func loud(_ i: Int, _ j: Int) -> Double {
        if isPeak(i, j) { return 1 }
        if peakCells.contains(where: { abs($0.c - i) <= 1 && abs($0.r - j) <= 1 }) { return 0.42 + 0.18 * hash2(i, j) }
        return 0.08 + 0.34 * hash2(i, j)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette) {
        let ink = pal.ink
        let a = BP.eout(BP.pr(t, 0, 0.5)), fade = BP.eio(BP.pr(t, 2.0, 2.6)), hot = BP.eout(BP.pr(t, 2.1, 2.7))

        // the phone, with a few sound arcs leaving it
        let iso = Iso(origin: BP.pt(14, 66), scale: 13)
        bpSlab(&c, iso, x: 0, y: 0, z: 0, w: 1.8, d: 0.3, h: 3.6, ink: ink, p: a)
        bpTrace(&c, bpFacePath(iso, o: SIMD3(0, 0.3, 0), ux: SIMD3(1, 0, 0), vx: SIMD3(0, 0, 1), u: 0.2, v: 0.4, w: 1.4, h: 2.8, r: 0.2), p: a, color: ink, width: BP.hair)
        for k in 0..<2 {
            var arc = Path()
            for i in 0...8 { let ang = -0.7 + 1.4 * Double(i) / 8; let q = BP.pt(40 + Double(k) * 5 + cos(ang) * 3, 46 + sin(ang) * (8 + Double(k) * 4)); if i == 0 { arc.move(to: q) } else { arc.addLine(to: q) } }
            bpTrace(&c, arc, p: BP.pr(t, 0.3 + Double(k) * 0.1, 0.7), color: ink)
        }

        // axes
        let ax = BP.pr(t, 0.1, 0.6)
        var axes = Path()
        axes.move(to: BP.pt(40, 296)); axes.addLine(to: BP.pt(40, 122)); axes.move(to: BP.pt(34, 129)); axes.addLine(to: BP.pt(40, 121)); axes.addLine(to: BP.pt(46, 129))
        axes.move(to: BP.pt(40, 296)); axes.addLine(to: BP.pt(282, 296)); axes.move(to: BP.pt(274, 290)); axes.addLine(to: BP.pt(282, 296)); axes.addLine(to: BP.pt(274, 302))
        for i in 0..<cols { axes.move(to: BP.pt(x(i), 296)); axes.addLine(to: BP.pt(x(i), 299)) }
        for j in 0..<rows { axes.move(to: BP.pt(40, y(j))); axes.addLine(to: BP.pt(37, y(j))) }
        bpTrace(&c, axes, p: ax, color: ink)
        bpText(&c, "TIME", BP.pt(161, 318), ink: ink, alpha: ax)
        bpText(&c, "HIGH NOTES", BP.pt(46, 112), ink: ink, alpha: ax, anchor: .leading)

        // the strip of sound and the chart fill together, left to right; a dashed scan line travels with them
        for i in 0..<cols {
            let start = 0.5 + 0.09 * Double(i), s = BP.eout(BP.pr(t, start, start + 0.35))
            guard s > 0.01 else { continue }
            let env = (0..<rows).map { loud(i, $0) }.max()! * 0.6 + 0.3 * hash2(i, 99)
            let h = (4 + 22 * env) * s
            var bar = Path(); bar.move(to: BP.pt(x(i), 46 - h / 2)); bar.addLine(to: BP.pt(x(i), 46 + h / 2))
            c.stroke(bar, with: .color(ink.opacity(0.75)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            for j in 0..<rows {
                let v = loud(i, j), side = (2.5 + 9 * v) * s, peak = isPeak(i, j)
                let r = CGRect(x: x(i) - side / 2, y: y(j) - side / 2, width: side, height: side)
                if peak {
                    c.fill(Path(r), with: .color(ink.opacity((0.2 + 0.5 * v) * (1 - hot))))
                    let rad = BP.mix(side / 2, 5.5, hot)
                    c.fill(Path(ellipseIn: CGRect(x: x(i) - rad, y: y(j) - rad, width: 2 * rad, height: 2 * rad)), with: .color(pal.accent.opacity(hot)))
                    let rr = 9.0
                    c.stroke(Path(ellipseIn: CGRect(x: x(i) - rr, y: y(j) - rr, width: 2 * rr, height: 2 * rr)), with: .color(pal.accent.opacity(0.8 * hot)), lineWidth: BP.hair)
                } else {
                    let sh = side * BP.mix(1, 0.7, fade), q = CGRect(x: x(i) - sh / 2, y: y(j) - sh / 2, width: sh, height: sh)
                    c.fill(Path(q), with: .color(ink.opacity((0.2 + 0.5 * v) * (1 - fade))))
                    c.stroke(Path(q), with: .color(ink.opacity(0.3 * fade)), lineWidth: 0.8)
                }
            }
        }
        let scanT = BP.pr(t, 0.5, 0.5 + 0.09 * Double(cols - 1) + 0.35)
        if scanT > 0.001 && scanT < 0.999 {
            let sx = BP.mix(x(0), x(cols - 1), scanT)
            bpGuide(&c, BP.pt(sx, 70), BP.pt(sx, 294), color: ink.opacity(0.35))
        }

        // one loud dot and the dashed neighbourhood it beats
        let (pc, pr) = (10, 3), cx = x(pc), cy = y(pr)
        var box = Path(); box.addRect(CGRect(x: cx - 23, y: cy - 22, width: 46, height: 44))
        bpTrace(&c, box, p: BP.pr(t, 2.6, 3.0), color: pal.accent, width: 1.2, dash: [4, 3])
        bpLeader(&c, anchor: BP.pt(cx + 23, cy - 22), elbow: BP.pt(246, 98), tail: 0, text: "BRIGHTER THAN\nEVERYTHING\nRIGHT AROUND\nTHEM", ink: ink, p: BP.pr(t, 2.8, 3.4))
    }
}

// MARK: - Card 3: one loud dot joins the few just after it; each pair is written down as note, note, gap

struct ShazamPair: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.8, tick: 3.5,
                       label: "The same loud dots spread across the page. One is marked as one note, with a dashed zone after it. Measuring lines join it to three dots in the zone, and the gap along the bottom is marked. Then each pair is written into a table as note, note and gap, the picked pair in gold.",
                       draw: { c, t, pal, _ in Self.draw(&c, t, pal) }, size: bpSize)
    }

    private static func at(_ k: Int) -> CGPoint { BP.pt(36 + 20.5 * Double(peakCells[k].c), 40 + 17 * Double(peakCells[k].r)) }
    private static let anchor = 3, after = [4, 5, 6], chosen = 5
    private static let cols: [Double] = [16, 102, 188, 274]
    private static let top = 250.0, rowH = 26.0

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette) {
        let ink = pal.ink, a = at(anchor)
        let dim = BP.eio(BP.pr(t, 0.9, 1.3))

        // the loud dots
        for k in peakCells.indices {
            let s = BP.eout(BP.pr(t, 0.05 + 0.06 * Double(k), 0.4 + 0.06 * Double(k)))
            let p = at(k), r = 4.6 * s, inZone = k == anchor || after.contains(k)
            let al = inZone ? 1 : BP.mix(1, 0.45, dim)
            let e = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
            c.fill(e, with: .color(BP.paper.opacity(s))); c.fill(e, with: .color(ink.opacity(0.18 * al)))
            c.stroke(e, with: .color(ink.opacity(al)), lineWidth: BP.edge)
        }
        // one note, and the dashed zone just after it
        let pa = BP.pr(t, 0.7, 1.1)
        c.stroke(Path(ellipseIn: CGRect(x: a.x - 9, y: a.y - 9, width: 18, height: 18)), with: .color(pal.accent.opacity(pa)), lineWidth: 1.6)
        var zone = Path(); zone.addRect(CGRect(x: 156, y: 34, width: 106, height: 126))
        bpTrace(&c, zone, p: BP.pr(t, 0.6, 1.1), color: ink, width: BP.hair, dash: [4, 4])
        bpLeader(&c, anchor: BP.pt(a.x - 4, a.y - 7), elbow: BP.pt(120, 50), tail: -10, text: "ONE NOTE", ink: ink, p: BP.pr(t, 1.0, 1.5))

        // dimension lines to the dots just after it; the picked pair is gold and labelled
        for (n, k) in after.enumerated() {
            let b = at(k), len = hypot(b.x - a.x, b.y - a.y), ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
            let from = BP.pt(a.x + ux * 7, a.y + uy * 7), to = BP.pt(b.x - ux * 7, b.y - uy * 7)
            let isPick = k == chosen
            bpDimension(&c, from: from, to: to, tick: BP.pt(-uy * 3.5, ux * 3.5), text: isPick ? "A PAIR" : "", labelWidth: isPick ? 44 : 0,
                        ink: isPick ? pal.accent : ink.opacity(0.75), p: BP.eio(BP.pr(t, 1.3 + 0.3 * Double(n), 1.7 + 0.3 * Double(n))))
        }
        // the gap of the picked pair: along the time axis
        let b = at(chosen), pg = BP.pr(t, 1.9, 2.4)
        bpGuide(&c, BP.pt(a.x, a.y + 9), BP.pt(a.x, 176), p: pg, color: ink.opacity(0.6))
        bpGuide(&c, BP.pt(b.x, b.y + 9), BP.pt(b.x, 176), p: pg, color: ink.opacity(0.6))
        bpDimension(&c, from: BP.pt(a.x, 176), to: BP.pt(b.x, 176), tick: BP.pt(0, 4), text: "GAP", labelWidth: 30, ink: ink, p: BP.eio(BP.pr(t, 2.0, 2.5)))

        // the table: a header row, then one row per pair, each written as note, note, gap
        let pt0 = BP.pr(t, 2.0, 2.5), rows = Double(after.count)
        let frame = CGRect(x: cols[0], y: top - 20, width: cols[3] - cols[0], height: 20 + rowH * rows)
        if pt0 > 0.001 {
            c.fill(Path(CGRect(x: cols[0], y: top - 20, width: cols[3] - cols[0], height: 20)), with: .color(ink.opacity(0.14 * pt0)))
            var grid = Path(); grid.addRect(frame)
            grid.move(to: BP.pt(cols[0], top)); grid.addLine(to: BP.pt(cols[3], top))
            for x in cols[1...2] { grid.move(to: BP.pt(x, top - 20)); grid.addLine(to: BP.pt(x, frame.maxY)) }
            for r in 1..<after.count { grid.move(to: BP.pt(cols[0], top + rowH * Double(r))); grid.addLine(to: BP.pt(cols[3], top + rowH * Double(r))) }
            bpTrace(&c, grid, p: pt0, color: ink, width: 1.2)
            for (i, h) in ["NOTE", "NOTE", "GAP"].enumerated() { bpText(&c, h, BP.pt((cols[i] + cols[i + 1]) / 2, top - 10), ink: ink, alpha: BP.pr(pt0, 0.6, 1)) }
            bpText(&c, "CODE", BP.pt(cols[0], top - 30), ink: ink, alpha: BP.pr(pt0, 0.6, 1), anchor: .leading)
        }
        for (n, k) in after.enumerated() {
            let q = BP.eio(BP.pr(t, 2.4 + 0.3 * Double(n), 3.0 + 0.3 * Double(n)))
            guard q > 0.001 else { continue }
            let pick = k == chosen, col = pick ? pal.accent : ink, b = at(k)
            let rowTop = top + rowH * Double(n)
            if pick { c.fill(Path(CGRect(x: cols[0], y: rowTop, width: cols[3] - cols[0], height: rowH)), with: .color(pal.accent.opacity(0.14 * q))) }
            func cell(_ p: CGPoint, _ colIdx: Int) -> CGPoint { BP.pt((cols[colIdx] + cols[colIdx + 1]) / 2, rowTop + 5 + (p.y - 40) / 170 * (rowH - 10)) }
            for (src, i) in [(a, 0), (b, 1)] {
                let p = BP.mixp(src, cell(src, i), q), r = BP.mix(4.6, 3.2, q)
                c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)), with: .color(col))
            }
            let gx = (b.x - a.x) / 102.5 * 60, cy = rowTop + rowH / 2, mid = (cols[2] + cols[3]) / 2, ga = BP.pr(q, 0.6, 1)
            var g = Path()
            g.move(to: BP.pt(mid - gx / 2, cy)); g.addLine(to: BP.pt(mid + gx / 2, cy))
            for s in [-1.0, 1.0] { g.move(to: BP.pt(mid + s * gx / 2, cy - 4)); g.addLine(to: BP.pt(mid + s * gx / 2, cy + 4)) }
            c.stroke(g, with: .color(col.opacity(ga)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
    }
}

// MARK: - Card 4: a filing cabinet of drawers, like a book's index; your code goes to one drawer, which opens onto every song with that code

struct ShazamIndex: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.4, tick: 2.4,
                       label: "A filing cabinet of drawers, like the index of a book. A small code in gold slides along a dashed line to one drawer, the drawer pulls out, and a card lists every song with that code, each with the moment it turns up: Song A at 0:49, Song B at 1:43, Song C at 2:35.",
                       draw: { c, t, pal, _ in Self.draw(&c, t, pal) }, size: bpSize)
    }

    private static let iso = Iso(origin: BP.pt(110, 228), scale: 15)
    private static let W = 3.2, D = 7.4, H = 8.0, rowH = 1.6
    private static let ex = SIMD3(1.0, 0, 0), ey = SIMD3(0, 1.0, 0), ez = SIMD3(0, 0, 1.0)
    private static let songs = ["SONG A \u{00B7} 0:49", "SONG B \u{00B7} 1:43", "SONG C \u{00B7} 2:35"]

    /// A drawer front on a face of the cabinet: a rounded panel, a handle, and a label slot with two short lines in it.
    private static func front(_ c: inout GraphicsContext, o: SIMD3<Double>, ux: SIMD3<Double>, w: Double, hh: Double, ink: Color, p: Double, slot: Bool = true) {
        bpTrace(&c, bpFacePath(iso, o: o, ux: ux, vx: ez, u: 0, v: 0, w: w, h: hh, r: 0.12), p: p, color: ink, width: 1.2)
        bpTrace(&c, bpFacePath(iso, o: o, ux: ux, vx: ez, u: w / 2 - 0.5, v: 0.22, w: 1.0, h: 0.2, r: 0.1), p: p, color: ink, width: 1.2)
        guard slot else { return }
        bpTrace(&c, bpFacePath(iso, o: o, ux: ux, vx: ez, u: w / 2 - 0.9, v: hh - 0.6, w: 1.8, h: 0.4, r: 0.08), p: p, color: ink.opacity(0.7), width: BP.hair)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette) {
        let ink = pal.ink
        func ps(_ a: Double, _ b: Double) -> Double { BP.eout(BP.pr(t, a, b)) }
        let pCab = ps(0, 0.9)

        // the cabinet: a tall box of drawers, five rows, two columns on the right face and one on the left
        bpSlab(&c, iso, x: 0, y: 0, z: 0, w: W, d: D, h: H, ink: ink, p: pCab)
        for i in 0..<5 { for j in 0..<12 {
            let q = iso.p(0.4 + Double(i) * 0.6 + hash2(i, j) * 0.15, 0.3 + Double(j) * 0.6 + hash2(j, i + 5) * 0.15, H)
            c.fill(Path(ellipseIn: CGRect(x: q.x - 0.8, y: q.y - 0.8, width: 1.6, height: 1.6)), with: .color(ink.opacity(0.35 * pCab)))
        } }
        let hh = rowH - 0.24, z0c = H - rowH * 2 + 0.12                    // the chosen drawer: column 0, row 1
        for r in 0..<5 {
            let z0 = H - rowH * Double(r + 1) + 0.12, pd = ps(0.2 + 0.08 * Double(r), 0.8 + 0.08 * Double(r))
            front(&c, o: SIMD3(0.15, D, z0), ux: ex, w: W - 0.3, hh: hh, ink: ink, p: pd)
            for col in 0..<2 where !(col == 0 && r == 1) {
                front(&c, o: SIMD3(W, 3.7 * Double(col) + 0.15, z0), ux: ey, w: 3.4, hh: hh, ink: ink, p: pd)
            }
        }

        // your code, in a frame at the top left, and a dashed guide down to the chosen drawer
        let chip = CGRect(x: 18, y: 40, width: 104, height: 34), ctr = BP.pt(70, 57)
        let pChip = ps(0.3, 0.8)
        bpGroup(&c, alpha: pChip) { g in
            g.fill(Path(roundedRect: chip, cornerRadius: 8), with: .color(BP.paper)); g.fill(Path(roundedRect: chip, cornerRadius: 8), with: .color(ink.opacity(0.08)))
            g.stroke(Path(roundedRect: chip, cornerRadius: 8), with: .color(ink), lineWidth: BP.edge)
            bpCode(&g, ctr, width: 56, a: -0.1, b: 0.08, r: 4, color: pal.accent)
        }
        bpText(&c, "CODE", BP.pt(18, 30), ink: ink, alpha: pChip, anchor: .leading)

        let slide = BP.eio(BP.pr(t, 1.5, 2.2)) * 3.5
        func glyphAt(_ s: Double) -> CGPoint { iso.p(W + 0.12 + s, 1.85, z0c + hh * 0.55) }
        let g0 = glyphAt(0)
        bpGuide(&c, BP.pt(70, 76), BP.pt(g0.x, g0.y - 8), p: BP.pr(t, 0.8, 1.2), color: pal.accent)
        bpGuide(&c, BP.pt(g0.x + 6, g0.y), BP.pt(glyphAt(4.3).x + 6, glyphAt(4.3).y), p: BP.pr(t, 1.3, 1.8), color: pal.accent)

        // the chosen drawer slides out along the dashed guide, carrying the code
        bpSlab(&c, iso, x: W, y: 0.15, z: z0c, w: 0.12 + slide, d: 3.4, h: hh, ink: ink, p: ps(0.3, 0.9))
        let fo = SIMD3(W + 0.12 + slide, 0.15, z0c)
        bpTrace(&c, bpFacePath(iso, o: fo, ux: ey, vx: ez, u: 1.2, v: 0.22, w: 1.0, h: 0.2, r: 0.1), p: ps(0.3, 0.9), color: ink, width: 1.2)
        let tr = BP.eio(BP.pr(t, 0.9, 1.5))
        if t > 0.9 {
            let at = t < 1.5 ? BP.mixp(ctr, g0, tr) : glyphAt(slide)
            bpCode(&c, at, width: BP.mix(56, 26, tr), a: -0.1, b: 0.08, r: BP.mix(4, 2.6, tr), color: pal.accent)
        }

        // the card of songs: every song with this code and the moment it turns up; none stands out
        let panel = CGRect(x: 198, y: 92, width: 130, height: 96), pp = BP.pr(t, 2.1, 2.6)
        if pp > 0.001 {
            var frame = Path(roundedRect: panel, cornerRadius: 6)
            for k in 1..<3 { frame.move(to: BP.pt(panel.minX, panel.minY + 32 * Double(k))); frame.addLine(to: BP.pt(panel.maxX, panel.minY + 32 * Double(k))) }
            c.fill(Path(roundedRect: panel, cornerRadius: 6), with: .color(BP.paper.opacity(pp))); c.fill(Path(roundedRect: panel, cornerRadius: 6), with: .color(ink.opacity(0.08 * pp)))
            bpTrace(&c, frame, p: pp, color: ink)
        }
        bpText(&c, "EVERY SONG", BP.pt(202, 56), ink: ink, alpha: pp, anchor: .leading)
        bpText(&c, "WITH THAT CODE", BP.pt(202, 69), ink: ink, alpha: pp, anchor: .leading)
        let gs = glyphAt(3.5)
        for (i, s) in songs.enumerated() {
            let q = BP.eout(BP.pr(t, 2.2 + 0.15 * Double(i), 2.6 + 0.15 * Double(i))), y = panel.minY + 16 + 32 * Double(i) + (1 - q) * 14
            var l = Path(); l.move(to: BP.pt(gs.x + 16, gs.y - 2)); l.addLine(to: BP.pt(204, panel.minY + 16 + 32 * Double(i)))
            bpTrace(&c, l, p: BP.pr(t, 2.3 + 0.1 * Double(i), 2.8 + 0.1 * Double(i)), color: pal.accent.opacity(0.8), width: BP.hair)
            bpCode(&c, BP.pt(218, y), width: 18, a: [-0.1, 0.1, 0.0][i], b: [0.08, -0.08, 0.1][i], r: 2.2, color: pal.accent, alpha: q)
            bpText(&c, s, BP.pt(236, y), ink: ink, alpha: q, anchor: .leading)
        }
        let pm = BP.pr(t, 2.6, 3.0)      // under the times column, clear of the drawer
        bpText(&c, "THE MOMENT", BP.pt(panel.maxX, 204), ink: ink, alpha: pm, anchor: .trailing)
        bpText(&c, "IT TURNS UP", BP.pt(panel.maxX, 217), ink: ink, alpha: pm, anchor: .trailing)
    }
}

// MARK: - Card 5: your codes drop onto three songs; in the right one they land in the same order and spacing

struct ShazamMatch: View {
    let active: Bool

    var body: some View {
        BlueprintStage(active: active, length: 3.2, tick: 2.6,
                       label: "Three song timelines stacked like an exploded drawing, with the strip of your few seconds above them. Your three gold codes drop onto each song. On Song A and Song C they land scattered at uneven spacing. On Song B they land in the same order and the same distance apart, in a straight line under dashed guides. Song B is then outlined in gold with a note tag and the others dim.",
                       draw: { c, t, pal, _ in Self.draw(&c, t, pal) }, size: bpSize)
    }

    private static let iso = Iso(origin: BP.pt(100, 185), scale: 14)
    private static let L = 12.0, d = 2.6
    private static let zC = 0.0, zB = 3.6, zA = 7.2, zR = 10.8
    private static let recX = [5.7, 6.8, 8.4]
    private static let pitch: [(Double, Double)] = [(-0.1, 0.08), (0.1, -0.08), (0.0, 0.1)]
    private static let destA = [(1.4, 0.7), (3.8, 2.0), (10.3, 0.8)], destC = [(2.5, 2.0), (3.2, 0.6), (9.7, 1.9)]

    /// One song strip with timeline ticks along its front edge.
    private static func strip(_ c: inout GraphicsContext, z: Double, x0: Double = 0, len: Double = L, ink: Color, p: Double) {
        bpSlab(&c, iso, x: x0, y: 0, z: z, w: len, d: d, h: 0.4, ink: ink, p: p)
        var ticks = Path()
        for k in 1..<Int(len) { let x = x0 + Double(k); ticks.move(to: iso.p(x, d, z + 0.4)); ticks.addLine(to: iso.p(x, d - 0.4, z + 0.4)) }
        bpTrace(&c, ticks, p: p, color: ink.opacity(0.6), width: 0.8)
    }

    private static func draw(_ c: inout GraphicsContext, _ t: Double, _ pal: StagePalette) {
        let ink = pal.ink
        func ps(_ a: Double, _ b: Double) -> Double { BP.eout(BP.pr(t, a, b)) }
        let e = BP.eio(BP.pr(t, 2.5, 3.0)), dim = BP.mix(1, 0.42, e)

        // the layers, bottom to top; the two wrong songs dim at the end
        bpGroup(&c, alpha: dim) { g in strip(&g, z: zC, ink: ink, p: ps(0, 0.5)) }
        strip(&c, z: zB, ink: ink, p: ps(0.1, 0.6))
        bpGroup(&c, alpha: e) { g in bpSlab(&g, iso, x: 0, y: 0, z: zB, w: L, d: d, h: 0.4, ink: pal.accent, p: 1) }
        bpGroup(&c, alpha: dim) { g in strip(&g, z: zA, ink: ink, p: ps(0.2, 0.7)) }
        strip(&c, z: zR, x0: 5, len: 4, ink: ink, p: ps(0.3, 0.8))

        // dashed vertical alignment guides down from your codes, and a straight guide along the right song
        let pg = BP.pr(t, 0.9, 1.4)
        for x in recX { bpGuide(&c, iso.p(x, d / 2, zR + 0.4), iso.p(x, d / 2, 0.4), p: pg, color: ink.opacity(0.7)) }
        bpGuide(&c, iso.p(4.8, d / 2, zB + 0.4), iso.p(9.3, d / 2, zB + 0.4), p: BP.pr(t, 2.2, 2.6), color: pal.accent)

        // your three codes on their strip, then dropping onto each song
        let pr0 = BP.pr(t, 0.6, 0.9)
        for i in 0..<3 { bpCode(&c, iso.p(recX[i], d / 2, zR + 0.4), width: 16, a: pitch[i].0, b: pitch[i].1, r: 2.2, color: pal.accent, alpha: pr0) }
        for (z, start, dest, al) in [(zA, 1.1, destA, dim), (zC, 1.4, destC, dim), (zB, 1.7, recX.map { ($0, d / 2) }, 1.0)] {
            for i in 0..<3 {
                let q = BP.eio(BP.pr(t, start + 0.1 * Double(i), start + 0.6 + 0.1 * Double(i)))
                guard q > 0.001 else { continue }
                let x = BP.mix(recX[i], dest[i].0, q), y = BP.mix(d / 2, dest[i].1, q), zz = BP.mix(zR + 0.4, z + 0.4, q * q)
                bpCode(&c, iso.p(x, y, zz), width: 13, a: pitch[i].0, b: pitch[i].1, r: 1.9, color: pal.accent, alpha: al)
            }
        }

        // labels: songs on the left, the recording and the verdicts on the right
        let lp = BP.pr(t, 0.9, 1.4)
        for (name, z) in [("SONG A", zA), ("SONG B", zB), ("SONG C", zC)] {
            let a = iso.p(0, d, z + 0.4)
            bpLeader(&c, anchor: a, elbow: BP.pt(a.x - 10, a.y), tail: -4, text: name, ink: ink, p: lp)
        }
        bpLeader(&c, anchor: iso.p(7, 0, zR + 0.4), elbow: BP.pt(196, 44), tail: 10, text: "THOSE FEW SECONDS", ink: ink, p: lp)
        let ra = iso.p(L, 0, zC + 0.4), rb = iso.p(L, 0, zB + 0.4)
        bpLeader(&c, anchor: ra, elbow: BP.pt(ra.x + 6, ra.y), tail: 0, text: "WRONG SONGS:\nSCATTERED", ink: ink, p: BP.pr(t, 1.9, 2.3))
        bpLeader(&c, anchor: rb, elbow: BP.pt(rb.x + 6, rb.y), tail: 0, text: "RIGHT SONG:\nSAME ORDER", ink: ink, p: BP.pr(t, 2.5, 2.9))

        // found: a gold tag with a note pops up by the right song
        let pop = BP.pr(t, 2.7, 3.0)
        if pop > 0.001 {
            let s = BP.eout(pop) * (1 + 0.18 * sin(pop * .pi)), tip = BP.pt(252, 199)
            var g = c; g.translateBy(x: tip.x, y: tip.y); g.scaleBy(x: s, y: s)
            var tag = Path(roundedRect: CGRect(x: -13, y: -24, width: 26, height: 19), cornerRadius: 6)
            tag.move(to: BP.pt(-4, -5)); tag.addLine(to: BP.pt(0, 0)); tag.addLine(to: BP.pt(4, -5)); tag.closeSubpath()
            g.fill(tag, with: .color(pal.accent))
            g.translateBy(x: -2, y: -9)
            bpNote(&g, BP.pt(0, 0), s: 9, color: BP.paper)
        }
    }
}
