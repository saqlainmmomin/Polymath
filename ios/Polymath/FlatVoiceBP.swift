import SwiftUI

// "Why does your voice sound different on a recording?" pictures, drawn as blueprint technical illustrations (2026-11-02).
// Chalk linework, flat tints only. One mustard accent per card, used for the thing the card is about: the voice you hear when you talk (card 1),
// the inside route (cards 2 to 4). Labels are mono uppercase, the slide's own words. Nothing is labelled higher or lower in pitch.
// Every picture loops: it plays on the stage's free clock, holds about a second and fades. Reduce Motion shows the held end state.
// Drawn in the default 343 x 320 design space; keep clear of the bottom-right corner (x > 288, y > 235).

// MARK: - Shared helpers

/// Loop time plus whether the picture is held (Reduce Motion: the stage clock stands still behind `t`, so show the end state).
private func voCycle(_ t: Double, _ clock: Double, story: Double, extra: Double = 1.5, narrated: Bool = false) -> (Double, Bool) {
    if narrated { return (t, false) }      // the voice sets the picture time through its cues, so the picture never loops on its own
    if clock < t { return (story, true) }
    return (clock.truncatingRemainder(dividingBy: story + extra), false)
}

/// 1 while the picture plays and holds, then fades to 0 over the last half second of the loop.
private func voFade(_ u: Double, _ story: Double) -> Double { 1 - BP.pr(u, story + 1.0, story + 1.5) }

/// Like bpGroup, but multiplies with the opacity already set, so a group can sit inside the picture's overall fade.
private func voGroup(_ c: inout GraphicsContext, alpha: Double, _ body: (inout GraphicsContext) -> Void) {
    guard alpha > 0.01 else { return }
    var g = c; g.opacity = c.opacity * alpha; body(&g)
}

/// A short arrow head at `b` pointing along a to b.
private func voHead(_ p: inout Path, _ a: CGPoint, _ b: CGPoint, size: Double = 5) {
    let len = hypot(b.x - a.x, b.y - a.y)
    guard len > 0.1 else { return }
    let ux = (b.x - a.x) / len, uy = (b.y - a.y) / len
    p.move(to: BP.pt(b.x - ux * size - uy * size * 0.6, b.y - uy * size + ux * size * 0.6)); p.addLine(to: b)
    p.addLine(to: BP.pt(b.x - ux * size + uy * size * 0.6, b.y - uy * size - ux * size * 0.6))
}

/// A dashed path drawn on by `p`; `phase` makes the dashes march.
private func voDash(_ c: inout GraphicsContext, _ path: Path, p: Double, color: Color, alpha: Double = 1, width: Double = BP.hair, phase: Double = 0) {
    guard p > 0.001, alpha > 0.01 else { return }
    c.stroke(path.trimmedPath(from: 0, to: BP.cl(p)), with: .color(color.opacity(alpha)),
             style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: [5, 4], dashPhase: -phase))
}

/// A sound wave along y = `y` from x0 to x1: a main sine plus an optional second, faster one. `ph` moves it to the right.
/// The ends taper over `ramp` points (the left end always, the right end when `taperR`).
private func voWave(_ x0: Double, _ x1: Double, y: Double, amp: Double, wl: Double, ph: Double,
                    amp2: Double = 0, wl2: Double = 10, ph2: Double = 0, ramp: Double = 10, taperR: Bool = false) -> Path {
    var p = Path()
    var x = x0
    var first = true
    while x <= x1 + 0.001 {
        var env = min(1, (x - x0) / ramp)
        if taperR { env = min(env, (x1 - x) / ramp) }
        let v = (amp * sin(2 * Double.pi * (x - x0) / wl - ph) + amp2 * sin(2 * Double.pi * (x - x0) / wl2 - ph2)) * max(0, env)
        let q = BP.pt(x, y + v)
        if first { p.move(to: q); first = false } else { p.addLine(to: q) }
        x += 1.5
    }
    return p
}

/// Diagonal hatching inside `clip`.
private func voHatch(_ c: inout GraphicsContext, clip: Path, color: Color, alpha: Double, step: Double = 4) {
    guard alpha > 0.01 else { return }
    var g = c
    g.clip(to: clip)
    let b = clip.boundingRect.insetBy(dx: -2, dy: -2)
    var h = Path()
    var x = b.minX - b.height
    while x < b.maxX { h.move(to: BP.pt(x, b.maxY)); h.addLine(to: BP.pt(x + b.height, b.minY)); x += step }
    g.stroke(h, with: .color(color.opacity(alpha)), lineWidth: BP.hair)
}

/// A point on a cubic curve.
private func voCubic(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint, _ t: Double) -> CGPoint {
    let m = 1 - t
    return BP.pt(m * m * m * a.x + 3 * m * m * t * b.x + 3 * m * t * t * c.x + t * t * t * d.x,
                 m * m * m * a.y + 3 * m * m * t * b.y + 3 * m * t * t * c.y + t * t * t * d.y)
}

/// A speech bubble: a rounded box with a tail on its bottom edge from x = `tl`...`tr` down to `tip`.
private func voBubble(_ r: CGRect, radius k: Double, tl: Double, tr: Double, tip: CGPoint) -> Path {
    var p = Path()
    p.move(to: BP.pt(r.minX + k, r.minY)); p.addLine(to: BP.pt(r.maxX - k, r.minY))
    p.addQuadCurve(to: BP.pt(r.maxX, r.minY + k), control: BP.pt(r.maxX, r.minY))
    p.addLine(to: BP.pt(r.maxX, r.maxY - k))
    p.addQuadCurve(to: BP.pt(r.maxX - k, r.maxY), control: BP.pt(r.maxX, r.maxY))
    p.addLine(to: BP.pt(tr, r.maxY)); p.addLine(to: tip); p.addLine(to: BP.pt(tl, r.maxY))
    p.addLine(to: BP.pt(r.minX + k, r.maxY))
    p.addQuadCurve(to: BP.pt(r.minX, r.maxY - k), control: BP.pt(r.minX, r.maxY))
    p.addLine(to: BP.pt(r.minX, r.minY + k))
    p.addQuadCurve(to: BP.pt(r.minX + k, r.minY), control: BP.pt(r.minX, r.minY))
    p.closeSubpath()
    return p
}

// MARK: - Heads in profile

/// A point in a head's own frame: x runs forward (the face is at +1), y down, both in head radii `R` from the centre `o`; `f` mirrors it.
private func voPt(_ o: CGPoint, _ R: Double, _ f: Double, _ x: Double, _ y: Double) -> CGPoint { BP.pt(o.x + f * x * R, o.y + y * R) }

/// The outline of a head in profile with a neck, open at the bottom (a cutaway). Skull a circle of radius R at `o`; the face looks towards `f`.
private func voHeadOutline(_ o: CGPoint, _ R: Double, _ f: Double) -> Path {
    func q(_ x: Double, _ y: Double) -> CGPoint { voPt(o, R, f, x, y) }
    var p = Path()
    p.move(to: q(-0.42, 1.62))
    p.addLine(to: q(-0.44, 0.98))
    p.addQuadCurve(to: q(-0.99, 0.15), control: q(-0.99, 0.74))
    let sweep = Double.pi - 0.40
    for i in 0...32 {
        let a = Double.pi + sweep * Double(i) / 32
        p.addLine(to: q(cos(a), sin(a)))
    }
    p.addLine(to: q(0.97, -0.12))          // brow
    p.addLine(to: q(0.93, 0.04))           // top of the nose
    p.addLine(to: q(1.24, 0.38))           // nose tip
    p.addLine(to: q(0.96, 0.47))
    p.addLine(to: q(1.01, 0.58))           // upper lip
    p.addLine(to: q(0.93, 0.65))           // mouth
    p.addLine(to: q(0.98, 0.74))           // lower lip
    p.addLine(to: q(0.88, 1.0))            // chin
    p.addQuadCurve(to: q(0.36, 1.06), control: q(0.66, 1.1))
    p.addLine(to: q(0.34, 1.62))
    return p
}

/// An ear, centred at `at`, `h` high: the rim runs round the back, the opening faces forward.
private func voEar(_ c: inout GraphicsContext, at: CGPoint, h: Double, f: Double, ink: Color, tint: Double = 0.07, mark: Color? = nil) {
    let k = h / 0.55
    func q(_ x: Double, _ y: Double) -> CGPoint { BP.pt(at.x - f * x * k, at.y + y * k) }
    var rim = Path()
    rim.move(to: q(0.0, 0.29))
    rim.addCurve(to: q(-0.10, 0.04), control1: q(-0.10, 0.27), control2: q(-0.13, 0.16))
    rim.addCurve(to: q(-0.07, -0.20), control1: q(-0.08, -0.04), control2: q(-0.10, -0.14))
    rim.addCurve(to: q(0.14, -0.15), control1: q(-0.03, -0.31), control2: q(0.12, -0.30))
    rim.addCurve(to: q(0.10, 0.12), control1: q(0.19, -0.04), control2: q(0.16, 0.05))
    rim.addCurve(to: q(0.0, 0.29), control1: q(0.07, 0.20), control2: q(0.07, 0.29))
    c.fill(rim, with: .color(BP.paper)); c.fill(rim, with: .color(ink.opacity(tint)))
    if let m = mark { c.fill(rim, with: .color(m.opacity(0.18))) }
    c.stroke(rim, with: .color(mark ?? ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
    var inner = Path()
    inner.move(to: q(-0.02, -0.18))
    inner.addCurve(to: q(0.07, -0.01), control1: q(0.08, -0.20), control2: q(0.12, -0.10))
    inner.addCurve(to: q(0.00, 0.14), control1: q(0.04, 0.06), control2: q(0.06, 0.12))
    c.stroke(inner, with: .color(ink.opacity(0.8)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
    let hole = q(-0.04, 0.05)
    c.fill(Path(ellipseIn: CGRect(x: hole.x - 1.5, y: hole.y - 1.5, width: 3, height: 3)), with: .color(mark ?? ink))
}

/// A head in profile, centre `o`, skull radius `R`, looking towards `f` (+1 right, -1 left): paper fill, hair, eye, ear, outline.
/// `bone` > 0 hatches the head (a cutaway through bone and flesh).
private func voPerson(_ c: inout GraphicsContext, at o: CGPoint, R: Double, f: Double, ink: Color, bone: Double = 0, earMark: Color? = nil) {
    let outline = voHeadOutline(o, R, f)
    var shape = outline; shape.closeSubpath()
    c.fill(shape, with: .color(BP.paper)); c.fill(shape, with: .color(ink.opacity(0.07)))
    if bone > 0.01 { voHatch(&c, clip: shape, color: ink, alpha: 0.30 * bone, step: 4) }
    // hair: a solid band round the back and top of the skull
    var hair = Path()
    for i in 0...20 {
        let a = Double.pi + 0.10 + (Double.pi - 0.95) * Double(i) / 20
        let q = voPt(o, R, f, 0.91 * cos(a), 0.91 * sin(a))
        if i == 0 { hair.move(to: q) } else { hair.addLine(to: q) }
    }
    c.stroke(hair, with: .color(ink), style: StrokeStyle(lineWidth: max(4, R * 0.17), lineCap: .round))
    let e = voPt(o, R, f, 0.62, -0.01)
    c.fill(Path(ellipseIn: CGRect(x: e.x - R * 0.055, y: e.y - R * 0.055, width: R * 0.11, height: R * 0.11)), with: .color(ink))
    c.stroke(outline, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round, lineJoin: .round))
    voEar(&c, at: voPt(o, R, f, -0.12, 0.18), h: R * 0.55, f: f, ink: ink, mark: earMark)
}

/// Shoulders under a head, ending flat on a line at `floor`.
private func voShoulders(_ c: inout GraphicsContext, at o: CGPoint, R: Double, f: Double, floor: Double, ink: Color) {
    func q(_ x: Double, _ y: Double) -> CGPoint { voPt(o, R, f, x, y) }
    var t = Path()
    t.move(to: q(-0.42, 1.30))
    t.addQuadCurve(to: q(-1.55, 1.95), control: q(-0.95, 1.36))
    t.addLine(to: BP.pt(q(-1.55, 0).x, floor)); t.addLine(to: BP.pt(q(1.55, 0).x, floor)); t.addLine(to: q(1.55, 1.95))
    t.addQuadCurve(to: q(0.34, 1.30), control: q(0.95, 1.36))
    c.fill(t, with: .color(BP.paper)); c.fill(t, with: .color(ink.opacity(0.14)))
    c.stroke(t, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
}

/// A mouth on a head: 0 closed, 1 open (talking), 2 a frown with a lowered brow.
private func voMouth(_ c: inout GraphicsContext, at o: CGPoint, R: Double, f: Double, kind: Int, ink: Color) {
    func q(_ x: Double, _ y: Double) -> CGPoint { voPt(o, R, f, x, y) }
    switch kind {
    case 1:
        let m = q(0.90, 0.67)
        c.fill(Path(ellipseIn: CGRect(x: m.x - R * 0.07, y: m.y - R * 0.07, width: R * 0.14, height: R * 0.15)), with: .color(ink))
    case 2:
        var m = Path(); m.move(to: q(0.76, 0.76)); m.addQuadCurve(to: q(1.0, 0.76), control: q(0.88, 0.56))
        c.stroke(m, with: .color(ink), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        var b = Path(); b.move(to: q(0.46, -0.20)); b.addLine(to: q(0.78, -0.09))
        c.stroke(b, with: .color(ink), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
    default:
        var m = Path(); m.move(to: q(0.78, 0.69)); m.addLine(to: q(0.98, 0.69))
        c.stroke(m, with: .color(ink), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }
}

/// Sound leaving the mouth: three little arcs that grow and fade in turn.
private func voRipples(_ c: inout GraphicsContext, mouth m: CGPoint, f: Double, ink: Color, clock: Double, still: Bool, alpha: Double, color: Color? = nil) {
    guard alpha > 0.01 else { return }
    for k in 0..<3 {
        let ph = still ? (Double(k) * 0.3 + 0.2) : (clock * 0.9 - Double(k) * 0.3).truncatingRemainder(dividingBy: 1)
        let s = ph < 0 ? ph + 1 : ph
        let r = 5 + 15 * s
        var arc = Path()
        for i in 0...10 {
            let a = (-48 + 96 * Double(i) / 10) * Double.pi / 180
            let q = BP.pt(m.x + f * r * cos(a), m.y + r * sin(a))
            if i == 0 { arc.move(to: q) } else { arc.addLine(to: q) }
        }
        c.stroke(arc, with: .color((color ?? ink).opacity(alpha * (1 - s) * 0.9)), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round))
    }
}

/// A speaker, drawn as a head with both routes to its own ear: the air route curves outside the face (dashed chalk, ink), and the inside route
/// runs through the head in a tunnel through the hatching (the accent, with a pulse running along it).
/// `air` and `inside` draw the routes on (0...1); `glow` 0...1 makes the inside route flash (a flat double stroke and sparkle ticks).
private func voSpeaker(_ c: inout GraphicsContext, at o: CGPoint, R: Double, ink: Color, acc: Color,
                       air: Double, inside: Double, glow: Double = 0, clock: Double, still: Bool, ripples: Double = 1,
                       airColor: Color? = nil, earMark: Color? = nil) {
    voPerson(&c, at: o, R: R, f: 1, ink: ink, bone: 1, earMark: earMark)
    let mouth = voPt(o, R, 1, 1.0, 0.65), ear = voPt(o, R, 1, -0.12, 0.18)
    voRipples(&c, mouth: BP.pt(mouth.x + 3, mouth.y), f: 1, ink: ink, clock: clock, still: still, alpha: ripples, color: airColor)

    // inside route: a clear tunnel through the hatching, the accent line along it
    let i0 = voPt(o, R, 1, 0.88, 0.66), i1 = voPt(o, R, 1, 0.40, 0.86), i2 = voPt(o, R, 1, 0.10, 0.62), i3 = voPt(o, R, 1, -0.06, 0.24)
    var tunnel = Path(); tunnel.move(to: i0); tunnel.addCurve(to: i3, control1: i1, control2: i2)
    if inside > 0.001 {
        c.stroke(tunnel.trimmedPath(from: 0, to: BP.cl(inside)), with: .color(BP.paper), style: StrokeStyle(lineWidth: R * 0.24, lineCap: .round))
        let pulse = still ? 0.8 : 0.65 + 0.35 * sin(clock * 5)
        if glow > 0.01 {
            c.stroke(tunnel.trimmedPath(from: 0, to: BP.cl(inside)), with: .color(acc.opacity(0.40 * glow * pulse)), style: StrokeStyle(lineWidth: R * 0.30, lineCap: .round))
        }
        c.stroke(tunnel.trimmedPath(from: 0, to: BP.cl(inside)), with: .color(acc), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        if inside > 0.98 {
            var head = Path(); voHead(&head, voCubic(i0, i1, i2, i3, 0.9), i3, size: 5.5)
            c.stroke(head, with: .color(acc), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            // a pulse running mouth to ear, three at a time
            for k in 0..<3 {
                let s = still ? (0.15 + 0.3 * Double(k)) : (clock * 0.5 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                var seg = Path()
                for j in 0...6 { let q = voCubic(i0, i1, i2, i3, min(1, s + 0.07 * Double(j) / 6)); if j == 0 { seg.move(to: q) } else { seg.addLine(to: q) } }
                c.stroke(seg, with: .color(acc), style: StrokeStyle(lineWidth: 4.4, lineCap: .round))
            }
            // sparkle ticks round the ear while it glows
            if glow > 0.01 {
                var ticks = Path()
                for k in 0..<7 {
                    let a = (-150 + Double(k) * 42) * Double.pi / 180
                    ticks.move(to: BP.pt(ear.x + cos(a) * R * 0.40, ear.y + sin(a) * R * 0.40))
                    ticks.addLine(to: BP.pt(ear.x + cos(a) * R * 0.40 + cos(a) * 5, ear.y + sin(a) * R * 0.40 + sin(a) * 5))
                }
                c.stroke(ticks, with: .color(acc.opacity(glow * (still ? 1 : 0.65 + 0.35 * sin(clock * 5 + 1.5)))), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
        }
    }

    // air route: out of the mouth, round the face, into the ear from above
    let a0 = voPt(o, R, 1, 1.12, 0.66), a1 = voPt(o, R, 1, 1.8, 0.45), a2 = voPt(o, R, 1, 1.25, -0.9), a3 = voPt(o, R, 1, 0.02, 0.10)
    var route = Path(); route.move(to: a0); route.addCurve(to: a3, control1: a1, control2: a2)
    voDash(&c, route, p: air, color: airColor ?? ink, phase: still ? 0 : clock * 14)
    if air > 0.98 {
        var head = Path(); voHead(&head, voCubic(a0, a1, a2, a3, 0.93), a3)
        c.stroke(head, with: .color(airColor ?? ink), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round))
    }
}

/// A straight dashed air route from `a` to `b` with a head, drawn on by `p`.
private func voAirLine(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, p: Double, ink: Color, clock: Double, still: Bool, color: Color? = nil) {
    var line = Path(); line.move(to: a); line.addLine(to: b)
    voDash(&c, line, p: p, color: color ?? ink, phase: still ? 0 : clock * 14)
    if p > 0.98 {
        var head = Path(); voHead(&head, a, b)
        c.stroke(head, with: .color(color ?? ink), style: StrokeStyle(lineWidth: BP.hair, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Card 1: you talk, then hear the recording

struct VoiceBPTalk: View {
    @Environment(\.pictureClock) private var narrated
    let active: Bool
    private static let story = 4.8

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.2,
                       label: "A person in profile is talking. A speech bubble from their mouth, in gold, holds a full, thick sound wave: the voice you hear when you talk. Then a phone with a play button stands beside them and a second speech bubble comes out of it, holding a thinner, smaller sound wave: the recording. The phone and the recording are peach, and the person's ear is marked in green. The person's mouth turns into a frown as they listen. Labels say: the voice you hear when you talk; the recording.",
                       draw: { c, t, pal, clock in
                           let (u, still) = voCycle(t, clock, story: Self.story, narrated: narrated != nil)
                           voGroup(&c, alpha: still ? 1 : voFade(u, Self.story)) { g in Self.draw(&g, u, pal, clock, still) }
                       })
    }

    static func draw(_ c: inout GraphicsContext, _ u: Double, _ pal: StagePalette, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let ph = still ? 0 : clock
        let head = BP.pt(82, 156), hR = 30.0

        // ground and the person
        let aIn = BP.eout(BP.pr(u, 0, 0.5))
        voGroup(&c, alpha: aIn) { g in
            var ground = Path(); ground.move(to: BP.pt(24, 228)); ground.addLine(to: BP.pt(292, 228))
            g.stroke(ground, with: .color(ink.opacity(0.45)), lineWidth: BP.hair)
            voShoulders(&g, at: head, R: hR, f: 1, floor: 228, ink: ink)
            voPerson(&g, at: head, R: hR, f: 1, ink: ink, earMark: BP.Hue.pistachio)
            let talking = u > 0.8 && u < 3.2 && (still || (clock * 5).truncatingRemainder(dividingBy: 1) < 0.65)
            voMouth(&g, at: head, R: hR, f: 1, kind: u >= 3.2 ? 2 : (talking ? 1 : 0), ink: ink)
        }

        // bubble 1: the voice you hear when you talk (the accent)
        let r1 = CGRect(x: 56, y: 52, width: 110, height: 66)
        let b1 = voBubble(r1, radius: 14, tl: 108, tr: 130, tip: BP.pt(134, 178))
        let p1 = BP.pr(u, 0.5, 1.3)
        if p1 > 0.001 {
            voGroup(&c, alpha: BP.pr(p1, 0, 0.3)) { g in g.fill(b1, with: .color(BP.paper)); g.fill(b1, with: .color(BP.Hue.mustard.opacity(0.15))) }
            bpTrace(&c, b1, p: p1, color: acc)
            voGroup(&c, alpha: BP.pr(u, 0.9, 1.5)) { g in
                // a full ribbon of sound: the wave and its mirror
                for sgn in [1.0, -1.0] {
                    let wave = voWave(68, 154, y: 85, amp: 14 * sgn, wl: 44, ph: ph * 6, amp2: 5 * sgn, wl2: 14, ph2: ph * 10, taperR: true)
                    g.stroke(wave, with: .color(acc), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                }
            }
        }
        bpLeader(&c, anchor: BP.pt(74, 52), elbow: BP.pt(74, 28), tail: 0, text: "THE VOICE YOU HEAR\nWHEN YOU TALK", ink: acc, p: BP.pr(u, 1.2, 1.9))

        // the phone, with a play button
        voGroup(&c, alpha: BP.eout(BP.pr(u, 2.3, 2.9))) { g in
            let phone = Path(roundedRect: CGRect(x: 222, y: 150, width: 44, height: 78), cornerRadius: 7)
            g.fill(phone, with: .color(BP.paper)); g.fill(phone, with: .color(BP.Hue.peach.opacity(0.18)))
            g.stroke(phone, with: .color(BP.Hue.peach), lineWidth: BP.edge)
            let screen = Path(roundedRect: CGRect(x: 227, y: 156, width: 34, height: 58), cornerRadius: 2)
            g.stroke(screen, with: .color(BP.Hue.peach.opacity(0.7)), lineWidth: BP.hair)
            var play = Path(); play.move(to: BP.pt(237, 175)); play.addLine(to: BP.pt(237, 195)); play.addLine(to: BP.pt(253, 185)); play.closeSubpath()
            g.fill(play, with: .color(BP.Hue.peach))
            g.fill(Path(ellipseIn: CGRect(x: 242, y: 219, width: 4, height: 4)), with: .color(BP.Hue.peach.opacity(0.8)))
        }

        // bubble 2: the recording (thin, small wave)
        let r2 = CGRect(x: 196, y: 74, width: 104, height: 60)
        let b2 = voBubble(r2, radius: 14, tl: 232, tr: 256, tip: BP.pt(244, 146))
        let p2 = BP.pr(u, 2.9, 3.6)
        if p2 > 0.001 {
            voGroup(&c, alpha: BP.pr(p2, 0, 0.3)) { g in g.fill(b2, with: .color(BP.paper)); g.fill(b2, with: .color(BP.Hue.peach.opacity(0.15))) }
            bpTrace(&c, b2, p: p2, color: BP.Hue.peach)
            voGroup(&c, alpha: BP.pr(u, 3.3, 3.9)) { g in
                let wave = voWave(208, 288, y: 104, amp: 6, wl: 13, ph: ph * 10, taperR: true)
                g.stroke(wave, with: .color(BP.Hue.peach), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
            }
        }
        bpLeader(&c, anchor: BP.pt(244, 216), elbow: BP.pt(244, 258), tail: -4, text: "THE RECORDING", ink: BP.Hue.peach, p: BP.pr(u, 3.6, 4.3))
    }
}

// MARK: - Card 2: two routes to your own ear

struct VoiceBPRoutes: View {
    @Environment(\.pictureClock) private var narrated
    let active: Bool
    private static let story = 6.6

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 2.8,
                       label: "A head in profile on the left, cut away and hatched like bone and flesh, with an ear. Sound leaves the mouth along two routes to the ear. One route, in pale dashes, curves out through the air round the face. The other, in gold, runs inside the head from the mouth to the ear. Then a friend's head faces the speaker from the right, and only a straight dashed route through the air reaches them. Labels say: air route; inside route, bone and flesh; your friend gets only the air route.",
                       draw: { c, t, pal, clock in
                           let (u, still) = voCycle(t, clock, story: Self.story, narrated: narrated != nil)
                           voGroup(&c, alpha: still ? 1 : voFade(u, Self.story)) { g in Self.draw(&g, u, pal, clock, still) }
                       })
    }

    static func draw(_ c: inout GraphicsContext, _ u: Double, _ pal: StagePalette, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let so = BP.pt(88, 162), sR = 42.0
        let fo = BP.pt(268, 162), fR = 36.0

        voGroup(&c, alpha: BP.eout(BP.pr(u, 0, 0.6))) { g in
            voSpeaker(&g, at: so, R: sR, ink: ink, acc: acc,
                      air: BP.eio(BP.pr(u, 0.9, 2.2)), inside: BP.eio(BP.pr(u, 2.7, 3.8)), clock: clock, still: still,
                      ripples: BP.pr(u, 0.5, 0.9), airColor: BP.Hue.ice, earMark: BP.Hue.pistachio)
        }

        // the friend: only the air route reaches them
        voGroup(&c, alpha: BP.eout(BP.pr(u, 4.2, 4.8))) { g in
            voPerson(&g, at: fo, R: fR, f: -1, ink: ink, earMark: BP.Hue.pistachio)
        }
        let mouth = voPt(so, sR, 1, 1.0, 0.65)
        let earF = voPt(fo, fR, -1, -0.12, 0.18)
        voAirLine(&c, BP.pt(mouth.x + 14, mouth.y + 1), BP.pt(fo.x, earF.y), p: BP.eio(BP.pr(u, 4.9, 5.7)), ink: ink, clock: clock, still: still, color: BP.Hue.ice)

        // labels
        let airMid = voPt(so, sR, 1, 1.27, -0.09)
        bpLeader(&c, anchor: airMid, elbow: BP.pt(airMid.x, 100), tail: -4, text: "AIR ROUTE", ink: BP.Hue.ice, p: BP.pr(u, 1.9, 2.6))
        bpLeader(&c, anchor: BP.pt(111, 192.5), elbow: BP.pt(111, 262), tail: 0, text: "INSIDE ROUTE:\nBONE AND FLESH", ink: acc, p: BP.pr(u, 3.4, 4.1))
        bpLeader(&c, anchor: BP.pt(200, 183), elbow: BP.pt(200, 62), tail: 0, text: "YOUR FRIEND\nGETS ONLY THE\nAIR ROUTE", ink: BP.Hue.pistachio, p: BP.pr(u, 5.5, 6.2))
    }
}

// MARK: - Card 3: low part and high part, then fingers in the ears

struct VoiceBPBands: View {
    @Environment(\.pictureClock) private var narrated
    let active: Bool
    private static let story = 8.0

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 5.0,
                       label: "A voice drawn as two bands of sound wave. A thick, long, slow wave is the low, deep part, and a thin, small, fast wave is the high part. Both travel along the air route, in a pale dashed box at the top, to a green ear on the right. Below, in a gold box, the inside route carries the thick low part clearly, in gold, but a hatched block stops almost all of the thin high part. The ear's picture of what it hears is a full pale wave. Then two fingers slide in to plug the ear: the air route is crossed out, the gold low part gets bigger and louder, and the wave grows boomy. Labels say: low, deep part; high part; inside route; fingers in ears, boomy.",
                       draw: { c, t, pal, clock in
                           let (u, still) = voCycle(t, clock, story: Self.story, narrated: narrated != nil)
                           voGroup(&c, alpha: still ? 1 : voFade(u, Self.story)) { g in Self.draw(&g, u, pal, clock, still) }
                       })
    }

    static func draw(_ c: inout GraphicsContext, _ u: Double, _ pal: StagePalette, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let sky = BP.Hue.ice, lime = BP.Hue.pistachio
        let phL = still ? 0 : clock * 3.2, phH = still ? 0 : clock * 9
        let slide = BP.eio(BP.pr(u, 5.0, 5.9))
        let dim = 1 - 0.78 * BP.eio(BP.pr(u, 5.7, 6.3))        // the air route closes
        let boom = BP.eio(BP.pr(u, 6.1, 7.0))                   // the inside low part gets louder
        let ear = BP.pt(262, 150)

        // the two boxes: the air route (dashed) and the inside route (solid, tinted)
        let slabA = CGRect(x: 20, y: 70, width: 180, height: 76)
        let slabI = CGRect(x: 20, y: 172, width: 180, height: 76)
        voGroup(&c, alpha: BP.eout(BP.pr(u, 0, 0.6))) { g in
            let a = Path(roundedRect: slabA, cornerRadius: 8)
            g.fill(a, with: .color(sky.opacity(0.12 * dim)))
            g.stroke(a, with: .color(sky.opacity(0.8 * dim)), style: StrokeStyle(lineWidth: BP.hair, dash: [3, 4]))
            let i = Path(roundedRect: slabI, cornerRadius: 8)
            g.fill(i, with: .color(acc.opacity(0.10)))
            g.stroke(i, with: .color(acc.opacity(0.85)), lineWidth: BP.hair)
        }

        // air route: both parts pass
        voGroup(&c, alpha: dim) { g in
            let pA = BP.pr(u, 0.6, 1.7)
            bpTrace(&g, voWave(24, 196, y: 93, amp: 13, wl: 64, ph: phL), p: pA, color: sky, width: 3.6)
            bpTrace(&g, voWave(24, 196, y: 128, amp: 4, wl: 12.5, ph: phH), p: pA, color: sky, width: 1.1)
        }

        // inside route: the low part passes, the high part meets a block
        let pI = BP.pr(u, 2.0, 3.0)
        let lowAmp = 14 + 5 * boom
        if boom > 0.01 {
            voGroup(&c, alpha: 0.16 * boom) { g in
                g.stroke(voWave(24, 196, y: 198, amp: lowAmp, wl: 64, ph: phL), with: .color(acc), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
            }
        }
        bpTrace(&c, voWave(24, 196, y: 198, amp: lowAmp, wl: 64, ph: phL), p: pI, color: acc, width: 3.6 + 1.2 * boom)
        bpTrace(&c, voWave(24, 122, y: 232, amp: 4, wl: 12.5, ph: phH), p: BP.pr(u, 2.2, 3.0), color: acc, width: 1.1)
        voGroup(&c, alpha: BP.eout(BP.pr(u, 2.4, 3.0))) { g in
            let block = Path(CGRect(x: 126, y: 221, width: 12, height: 22))
            g.fill(block, with: .color(BP.paper)); g.fill(block, with: .color(ink.opacity(0.12)))
            voHatch(&g, clip: block, color: ink, alpha: 0.85, step: 3.5)
            g.stroke(block, with: .color(ink), lineWidth: BP.edge)
        }
        bpTrace(&c, voWave(142, 196, y: 232, amp: 1.3, wl: 12.5, ph: phH, ramp: 4), p: BP.pr(u, 3.0, 3.6), color: acc.opacity(0.4), width: 1.0, dash: [3, 3])

        // the ear and its picture of what it hears
        voGroup(&c, alpha: BP.eout(BP.pr(u, 3.4, 4.0))) { g in
            voEar(&g, at: ear, h: 56, f: -1, ink: ink, mark: lime)
            let tile = Path(roundedRect: CGRect(x: 226, y: 36, width: 98, height: 50), cornerRadius: 8)
            var tail = Path(); tail.move(to: BP.pt(252, 85.5)); tail.addLine(to: BP.pt(262, 120)); tail.addLine(to: BP.pt(272, 85.5))
            g.fill(tail, with: .color(BP.paper)); g.stroke(tail, with: .color(lime), style: StrokeStyle(lineWidth: BP.edge, lineJoin: .round))
            g.fill(tile, with: .color(BP.paper)); g.fill(tile, with: .color(lime.opacity(0.10)))
            g.stroke(tile, with: .color(lime), lineWidth: BP.edge)
            var seam = Path(); seam.move(to: BP.pt(253, 86)); seam.addLine(to: BP.pt(271, 86))
            g.stroke(seam, with: .color(BP.paper), lineWidth: 2.4)
            // before: low part with the high part riding on it; after the plug: the low part alone, bigger
            let a1 = 11 + 9 * boom, a2 = 2.8 * (1 - boom)
            let tw = voWave(236, 314, y: 61, amp: a1, wl: 36, ph: phL, amp2: a2, wl2: 9, ph2: phH, ramp: 6, taperR: true)
            g.stroke(tw, with: .color(sky.opacity(1 - boom)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            if boom > 0.01 { g.stroke(tw, with: .color(acc.opacity(boom)), style: StrokeStyle(lineWidth: 2.6 + 0.8 * boom, lineCap: .round, lineJoin: .round)) }
        }

        // the two routes arrive at the ear
        let pArr = BP.pr(u, 3.4, 4.0)
        if pArr > 0.001 {
            let a0 = BP.pt(204, 108), a1 = BP.pt(238, 136)
            var air = Path(); air.move(to: a0); air.addLine(to: a1); voHead(&air, a0, a1)
            bpTrace(&c, air, p: pArr, color: sky.opacity(dim), width: BP.hair)
            let i0 = BP.pt(204, 210), i1 = BP.pt(240, 168)
            var ins = Path(); ins.move(to: i0); ins.addLine(to: i1); voHead(&ins, i0, i1, size: 6)
            bpTrace(&c, ins, p: pArr, color: acc, width: 2.0 + 0.8 * boom)
            // the stop mark on the air route
            let sm = BP.pr(u, 5.6, 6.1)
            if sm > 0.01 {
                var x = Path()
                x.move(to: BP.pt(215, 111)); x.addLine(to: BP.pt(227, 123)); x.move(to: BP.pt(227, 111)); x.addLine(to: BP.pt(215, 123))
                c.stroke(x, with: .color(sky.opacity(sm)), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
            }
        }

        // the fingers slide in from the right and plug the ear
        if slide > 0.001 {
            let dx = (1 - slide) * 78
            voGroup(&c, alpha: BP.pr(slide, 0, 0.25)) { g in
                for y in [144.0, 158.0] {
                    let finger = Path(roundedRect: CGRect(x: 268 + dx, y: y - 5.5, width: 62, height: 11), cornerRadius: 5.5)
                    g.fill(finger, with: .color(BP.paper)); g.fill(finger, with: .color(ink.opacity(0.2)))
                    g.stroke(finger, with: .color(ink), lineWidth: BP.edge)
                }
                let palm = Path(roundedRect: CGRect(x: 322 + dx, y: 136, width: 14, height: 30), cornerRadius: 5)
                g.fill(palm, with: .color(BP.paper)); g.fill(palm, with: .color(ink.opacity(0.2)))
                g.stroke(palm, with: .color(ink), lineWidth: BP.edge)
            }
        }

        // labels
        bpLeader(&c, anchor: BP.pt(44, 93), elbow: BP.pt(44, 48), tail: 0, text: "LOW, DEEP PART", ink: sky, p: BP.pr(u, 1.3, 2.0))
        bpLeader(&c, anchor: BP.pt(44, 128), elbow: BP.pt(44, 159), tail: 0, text: "HIGH PART", ink: sky, p: BP.pr(u, 1.6, 2.3))
        bpLeader(&c, anchor: BP.pt(132, 243), elbow: BP.pt(132, 268), tail: -4, text: "INSIDE ROUTE", ink: acc, p: BP.pr(u, 3.0, 3.7))
        bpLeader(&c, anchor: BP.pt(240, 36), elbow: BP.pt(240, 22), tail: -4, text: "FINGERS IN EARS: BOOMY", ink: acc, p: BP.pr(u, 6.6, 7.3))
    }
}

// MARK: - Card 4: the microphone and your friend only get the air route

struct VoiceBPMic: View {
    @Environment(\.pictureClock) private var narrated
    let active: Bool
    private static let story = 6.2

    var body: some View {
        BlueprintStage(active: active, length: Self.story, tick: 3.0,
                       label: "A speaker's head in profile on the left, cut away and hatched. Sound leaves the mouth along pale dashed air routes to three listeners, whose ears are green. A microphone on a stand at the top right gets only the air route. A friend's head facing the speaker at the right gets only the air route. The speaker's own ear gets the air route and, in gold, the extra inside route through the head, which flashes. Labels say: microphone, air route only; your friend, air route only; you, air route and inside route.",
                       draw: { c, t, pal, clock in
                           let (u, still) = voCycle(t, clock, story: Self.story, narrated: narrated != nil)
                           voGroup(&c, alpha: still ? 1 : voFade(u, Self.story)) { g in Self.draw(&g, u, pal, clock, still) }
                       })
    }

    static func draw(_ c: inout GraphicsContext, _ u: Double, _ pal: StagePalette, _ clock: Double, _ still: Bool) {
        let ink = pal.ink, acc = pal.accent
        let sky = BP.Hue.ice, lime = BP.Hue.pistachio
        let so = BP.pt(84, 172), sR = 38.0
        let fo = BP.pt(262, 184), fR = 30.0
        let mouth = voPt(so, sR, 1, 1.0, 0.65)

        // the listeners
        voGroup(&c, alpha: BP.eout(BP.pr(u, 0.2, 0.8))) { g in
            voPerson(&g, at: fo, R: fR, f: -1, ink: ink, earMark: lime)
            // microphone on a stand
            let cap = Path(roundedRect: CGRect(x: 261, y: 65, width: 18, height: 32), cornerRadius: 9)
            g.fill(cap, with: .color(BP.paper)); g.fill(cap, with: .color(ink.opacity(0.10)))
            voHatch(&g, clip: cap, color: ink, alpha: 0.6, step: 4)
            g.stroke(cap, with: .color(ink), lineWidth: BP.edge)
            var stand = Path()
            stand.move(to: BP.pt(270, 97)); stand.addLine(to: BP.pt(270, 128))
            stand.move(to: BP.pt(256, 128)); stand.addLine(to: BP.pt(284, 128))
            g.stroke(stand, with: .color(ink), style: StrokeStyle(lineWidth: BP.edge, lineCap: .round))
        }
        voGroup(&c, alpha: BP.eout(BP.pr(u, 0, 0.6))) { g in
            voSpeaker(&g, at: so, R: sR, ink: ink, acc: acc,
                      air: BP.eio(BP.pr(u, 0.9, 2.0)), inside: BP.eio(BP.pr(u, 3.0, 3.9)),
                      glow: BP.pr(u, 3.8, 4.4), clock: clock, still: still, ripples: BP.pr(u, 0.4, 0.8),
                      airColor: sky, earMark: lime)
        }

        // air routes to the microphone and the friend
        let earF = voPt(fo, fR, -1, -0.12, 0.18)
        let pAir = BP.eio(BP.pr(u, 1.2, 2.3))
        voAirLine(&c, BP.pt(mouth.x + 14, mouth.y - 4), BP.pt(254, 98), p: pAir, ink: ink, clock: clock, still: still, color: sky)
        voAirLine(&c, BP.pt(mouth.x + 14, mouth.y + 1), BP.pt(fo.x, earF.y), p: pAir, ink: ink, clock: clock, still: still, color: sky)

        // labels
        bpLeader(&c, anchor: BP.pt(270, 65), elbow: BP.pt(270, 36), tail: -4, text: "MICROPHONE:\nAIR ROUTE ONLY", ink: ink, p: BP.pr(u, 1.9, 2.6))
        bpLeader(&c, anchor: BP.pt(262, 222), elbow: BP.pt(262, 262), tail: -4, text: "YOUR FRIEND:\nAIR ROUTE ONLY", ink: lime, p: BP.pr(u, 2.2, 2.9))
        bpLeader(&c, anchor: voPt(so, sR, 1, 0.0, -1.0), elbow: BP.pt(84, 100), tail: 0, text: "YOU: AIR ROUTE\nAND INSIDE ROUTE", ink: acc, p: BP.pr(u, 4.0, 4.8))
    }
}
