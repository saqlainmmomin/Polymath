import SwiftUI
import UIKit

// MARK: - Palette, easing, haptics

enum Pal {
    static let skyTop: UInt32 = 0x070B24, skyMid: UInt32 = 0x16225A, skyLow: UInt32 = 0x2E4590
    static let signal = Color(hex: 0xFFD98A), coral = Color(hex: 0xFF6B4A), ice = Color(hex: 0x9CCBFF)
    static let ringA = Color(hex: 0x7FB8FF), ringB = Color(hex: 0x7CE0C3), ringC = Color(hex: 0xC59BFF)
    static let night = Color(hex: 0x050818)
}

private func clamp(_ x: Double) -> Double { min(1, max(0, x)) }
/// 0 before `a`, 1 after `b`, linear between.
private func prog(_ t: Double, _ a: Double, _ b: Double) -> Double { clamp((t - a) / (b - a)) }
private func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
private func easeInOut(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
private func backOut(_ x: Double) -> Double { let c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }

struct Cue {
    enum Kind { case soft, light, rigid, heavy, success }
    let at: Double; let kind: Kind
    init(_ at: Double, _ kind: Kind) { self.at = at; self.kind = kind }
}

enum Haptic {
    static func fire(_ k: Cue.Kind) {
        switch k {
        case .soft: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .rigid: UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .heavy: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Picture shell: one Canvas on one TimelineView, looping choreography, haptic cues, tap

struct FlatPicture: View {
    let active: Bool
    let period: Double          // loop length, seconds
    let still: Double           // moment shown when Reduce Motion is on
    var cues: [Cue] = []
    var replayOnTap = false     // tap restarts the card's story; otherwise the scene gets seconds-since-tap
    var sky: [UInt32] = [Pal.skyTop, Pal.skyMid, Pal.skyLow]
    var onStart: (() -> Void)? = nil   // runs once each time the story starts (card appears or is tapped to replay)
    let label: String
    let draw: (inout GraphicsContext, CGSize, Double, Double?) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var start = Date()
    @State private var run = 0
    @State private var tapAt: Date?

    var body: some View {
        TimelineView(.animation(paused: !active || reduce)) { tl in
            Canvas { ctx, size in
                let el = max(0, tl.date.timeIntervalSince(start))
                let t = reduce ? still : el.truncatingRemainder(dividingBy: period)
                draw(&ctx, size, t, tapAt.map { tl.date.timeIntervalSince($0) })
            }
        }
        .background(LinearGradient(colors: sky.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture {
            Haptic.fire(.soft)
            if replayOnTap { start = Date(); run += 1 } else { tapAt = Date() }
        }
        .onChange(of: active) { _, a in if a { start = Date(); run += 1 } }
        .task(id: "\(active)-\(run)-\(reduce)") { await runCues() }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityHint("Tap to replay")
    }

    private func runCues() async {
        guard active, !reduce, !cues.isEmpty else { return }
        onStart?()
        var base = start
        let sorted = cues.sorted { $0.at < $1.at }
        while !Task.isCancelled {
            for c in sorted {
                let wait = base.addingTimeInterval(c.at).timeIntervalSinceNow
                if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
                if Task.isCancelled { return }
                Haptic.fire(c.kind)
            }
            base = base.addingTimeInterval(period)
        }
    }
}

// MARK: - Drawing kit

enum Kit {
    enum Glyph { case pin, clock }

    /// Pill label with a dark backing so it reads over any picture.
    static func chip(_ ctx: inout GraphicsContext, _ text: String, _ p: CGPoint, anchor: UnitPoint = .center, color: Color = .white, size: CGFloat = 10, alpha: Double = 1, glyph: Glyph? = nil) {
        guard alpha > 0.01 else { return }
        let r = ctx.resolve(Text(text).font(T.mono(size)).tracking(0.9).foregroundColor(color))
        let sz = r.measure(in: CGSize(width: 600, height: 60))
        let gw: CGFloat = glyph == nil ? 0 : 14
        let w = sz.width + gw, h = sz.height
        let o = CGPoint(x: p.x - w * anchor.x, y: p.y - h * anchor.y)
        let rect = CGRect(x: o.x - 8, y: o.y - 4, width: w + 16, height: h + 8)
        var l = ctx
        l.opacity = alpha
        l.fill(Path(roundedRect: rect, cornerRadius: rect.height / 2), with: .color(Pal.night.opacity(0.66)))
        l.stroke(Path(roundedRect: rect, cornerRadius: rect.height / 2), with: .color(color.opacity(0.32)), lineWidth: 1)
        if let g = glyph { glyphDraw(&l, g, CGPoint(x: o.x + 5, y: o.y + h / 2), color) }
        l.draw(r, at: CGPoint(x: o.x + gw, y: o.y), anchor: .topLeading)
    }

    static func glyphDraw(_ ctx: inout GraphicsContext, _ g: Glyph, _ c: CGPoint, _ color: Color) {
        switch g {
        case .pin:
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 3.2, y: c.y - 4.7, width: 6.4, height: 6.4)), with: .color(color))
            var tri = Path(); tri.move(to: CGPoint(x: c.x - 2.7, y: c.y - 0.6)); tri.addLine(to: CGPoint(x: c.x + 2.7, y: c.y - 0.6)); tri.addLine(to: CGPoint(x: c.x, y: c.y + 4.6)); tri.closeSubpath()
            ctx.fill(tri, with: .color(color))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 1.1, y: c.y - 2.6, width: 2.2, height: 2.2)), with: .color(Pal.night))
        case .clock:
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 4.2, y: c.y - 4.2, width: 8.4, height: 8.4)), with: .color(color), lineWidth: 1.4)
            var h = Path(); h.move(to: CGPoint(x: c.x, y: c.y - 2.6)); h.addLine(to: c); h.addLine(to: CGPoint(x: c.x + 2.2, y: c.y + 1))
            ctx.stroke(h, with: .color(color), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        }
    }

    /// Drifting stars in three depth layers plus two faint colour clouds.
    static func stars(_ ctx: inout GraphicsContext, _ s: CGSize, _ t: Double) {
        let pts: [(Double, Double, Double, Int)] = [
            (0.08, 0.05, 0.0, 0), (0.30, 0.03, 1.3, 1), (0.66, 0.05, 2.1, 0), (0.92, 0.08, 0.7, 2), (0.05, 0.30, 2.7, 1), (0.36, 0.27, 0.4, 2),
            (0.64, 0.31, 1.9, 0), (0.95, 0.34, 3.1, 1), (0.22, 0.47, 1.1, 2), (0.78, 0.50, 2.4, 0), (0.50, 0.38, 0.9, 1), (0.12, 0.60, 1.7, 0),
            (0.88, 0.62, 0.2, 2), (0.42, 0.12, 2.0, 2), (0.58, 0.22, 1.4, 1), (0.18, 0.18, 0.6, 1), (0.75, 0.15, 2.8, 2), (0.30, 0.55, 3.3, 1)]
        ctx.fill(Path(ellipseIn: CGRect(x: -s.width * 0.2, y: -s.height * 0.1, width: s.width * 0.9, height: s.height * 0.6)),
                 with: .radialGradient(Gradient(colors: [Color(hex: 0x7A5BD6).opacity(0.20), .clear]), center: CGPoint(x: s.width * 0.25, y: s.height * 0.2), startRadius: 0, endRadius: s.width * 0.45))
        ctx.fill(Path(ellipseIn: CGRect(x: s.width * 0.4, y: s.height * 0.3, width: s.width * 0.8, height: s.height * 0.5)),
                 with: .radialGradient(Gradient(colors: [Color(hex: 0x3FA7D6).opacity(0.16), .clear]), center: CGPoint(x: s.width * 0.8, y: s.height * 0.5), startRadius: 0, endRadius: s.width * 0.4))
        for (x, y, ph, layer) in pts {
            let drift = t * [1.5, 3.0, 5.0][layer]
            let px = (x * s.width + drift).truncatingRemainder(dividingBy: s.width)
            let a = 0.30 + 0.45 * (0.5 + 0.5 * sin(t * 1.3 + ph))
            let r = [0.9, 1.3, 1.8][layer]
            ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: y * s.height - r, width: 2 * r, height: 2 * r)), with: .color(.white.opacity(a)))
            if layer == 2 {
                var cross = Path(); cross.move(to: CGPoint(x: px - 4, y: y * s.height)); cross.addLine(to: CGPoint(x: px + 4, y: y * s.height)); cross.move(to: CGPoint(x: px, y: y * s.height - 4)); cross.addLine(to: CGPoint(x: px, y: y * s.height + 4))
                ctx.stroke(cross, with: .color(.white.opacity(a * 0.35)), lineWidth: 0.7)
            }
        }
    }

    /// The top of the Earth seen from space: terminator shading, land, drifting cloud, glowing air.
    static func earth(_ ctx: inout GraphicsContext, _ s: CGSize, horizonY: Double, t: Double) {
        let R = s.width * 1.6
        let c = CGPoint(x: s.width / 2, y: horizonY + R)
        let disc = Path(ellipseIn: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R))
        let halo = Path(ellipseIn: CGRect(x: c.x - R - 26, y: c.y - R - 26, width: 2 * R + 52, height: 2 * R + 52))
        ctx.fill(halo, with: .radialGradient(Gradient(stops: [.init(color: .clear, location: 0.0), .init(color: .clear, location: R / (R + 26) - 0.001), .init(color: Color(hex: 0x6FB4FF).opacity(0.34), location: R / (R + 26) + 0.004), .init(color: .clear, location: 1)]),
                                             center: c, startRadius: 0, endRadius: R + 26))
        ctx.fill(disc, with: .radialGradient(Gradient(colors: [Color(hex: 0x0A1A3A), Color(hex: 0x123A7A), Color(hex: 0x2D82C8)]), center: c, startRadius: R * 0.55, endRadius: R))
        ctx.drawLayer { l in
            l.clip(to: disc)
            let u = s.width / 100
            // land
            for (x, dy, rx, ry) in [(0.10, 0.060, 0.30, 0.040), (0.16, 0.075, 0.18, 0.030), (0.60, 0.100, 0.26, 0.036), (0.72, 0.085, 0.16, 0.028), (0.40, 0.140, 0.12, 0.022)] {
                let r = CGRect(x: s.width * x, y: horizonY + s.height * dy, width: s.width * rx, height: s.height * ry)
                l.fill(Path(ellipseIn: r), with: .color(Color(hex: 0x2E9366)))
                l.fill(Path(ellipseIn: r.insetBy(dx: r.width * 0.18, dy: r.height * 0.25).offsetBy(dx: r.width * 0.05, dy: -r.height * 0.1)), with: .color(Color(hex: 0x62B67A)))
            }
            // cloud streaks
            for (i, (x, dy, w)) in [(0.05, 0.035, 0.30), (0.50, 0.060, 0.38), (0.30, 0.115, 0.22)].enumerated() {
                let px = (x * s.width + t * (2.0 + Double(i))).truncatingRemainder(dividingBy: s.width * 1.3) - s.width * 0.15
                l.fill(Path(roundedRect: CGRect(x: px, y: horizonY + s.height * dy, width: s.width * w, height: 5 * u / 3 * 2), cornerRadius: 4), with: .color(.white.opacity(0.17)))
            }
            // terminator shade, left side falls into night
            l.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(Gradient(colors: [Color(hex: 0x050A22).opacity(0.55), .clear]), startPoint: .zero, endPoint: CGPoint(x: s.width * 0.55, y: 0)))
        }
        // crisp bright rim
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R)), with: .color(Color(hex: 0xA8D4FF).opacity(0.55)), lineWidth: 1.4)
    }

    /// Side-on satellite: gold-foil body, dish, solar panels with cells and a sweeping highlight.
    static func satellite(_ ctx: inout GraphicsContext, _ p: CGPoint, _ u: Double, _ t: Double, phase: Double = 0) {
        let body = CGRect(x: p.x - 3.4 * u, y: p.y - 3.4 * u, width: 6.8 * u, height: 6.8 * u)
        let pw = 9.0 * u, ph = 4.8 * u
        for side in [-1.0, 1.0] {
            let x = side < 0 ? body.minX - 1.4 * u - pw : body.maxX + 1.4 * u
            let r = CGRect(x: x, y: p.y - ph / 2, width: pw, height: ph)
            var arm = Path(); arm.move(to: CGPoint(x: side < 0 ? body.minX : body.maxX, y: p.y)); arm.addLine(to: CGPoint(x: side < 0 ? r.maxX : r.minX, y: p.y))
            ctx.stroke(arm, with: .color(Color(hex: 0xC9D2F5)), lineWidth: 1.5)
            ctx.fill(Path(roundedRect: r, cornerRadius: 1.2), with: .linearGradient(Gradient(colors: [Color(hex: 0x4E68C8), Color(hex: 0x8AA4F4)]), startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
            var cells = Path()
            for i in 1..<4 { let gx = r.minX + pw * Double(i) / 4; cells.move(to: CGPoint(x: gx, y: r.minY)); cells.addLine(to: CGPoint(x: gx, y: r.maxY)) }
            cells.move(to: CGPoint(x: r.minX, y: r.midY)); cells.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            ctx.stroke(cells, with: .color(Color(hex: 0x0B1030).opacity(0.5)), lineWidth: 0.8)
            ctx.drawLayer { l in
                l.clip(to: Path(roundedRect: r, cornerRadius: 1.2))
                let sweep = ((t * 0.35 + phase).truncatingRemainder(dividingBy: 1.6)) - 0.3
                let x0 = r.minX + sweep * pw * 1.4
                var band = Path(); band.move(to: CGPoint(x: x0, y: r.maxY)); band.addLine(to: CGPoint(x: x0 + pw * 0.18, y: r.maxY)); band.addLine(to: CGPoint(x: x0 + pw * 0.38, y: r.minY)); band.addLine(to: CGPoint(x: x0 + pw * 0.2, y: r.minY)); band.closeSubpath()
                l.fill(band, with: .color(.white.opacity(0.32)))
            }
            ctx.stroke(Path(roundedRect: r, cornerRadius: 1.2), with: .color(.white.opacity(0.35)), lineWidth: 0.8)
        }
        // dish
        var mast = Path(); mast.move(to: CGPoint(x: p.x, y: body.minY)); mast.addLine(to: CGPoint(x: p.x, y: body.minY - 2.4 * u))
        ctx.stroke(mast, with: .color(Color(hex: 0xC9D2F5)), lineWidth: 1.3)
        var dish = Path(); dish.addArc(center: CGPoint(x: p.x, y: body.minY - 2.4 * u), radius: 2.4 * u, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false); dish.closeSubpath()
        ctx.fill(dish, with: .color(Color(hex: 0xE8ECFA)))
        // foil body
        ctx.fill(Path(roundedRect: body, cornerRadius: 1.8 * u), with: .linearGradient(Gradient(colors: [Color(hex: 0xF7F3EA), Color(hex: 0xC4CADF)]), startPoint: CGPoint(x: body.minX, y: body.minY), endPoint: CGPoint(x: body.maxX, y: body.maxY)))
        ctx.fill(Path(CGRect(x: body.minX, y: body.minY + 0.62 * body.height, width: body.width, height: 0.2 * body.height)), with: .color(Color(hex: 0xE2B64C).opacity(0.9)))
        ctx.stroke(Path(roundedRect: body, cornerRadius: 1.8 * u), with: .color(.white.opacity(0.5)), lineWidth: 0.8)
        // beacon
        let blink = 0.55 + 0.45 * sin(t * 4 + phase * 6)
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 3 * u, y: p.y - 3 * u - 0.4 * u, width: 6 * u, height: 6 * u)), with: .radialGradient(Gradient(colors: [Pal.signal.opacity(0.5 * blink), .clear]), center: CGPoint(x: p.x, y: p.y - 0.4 * u), startRadius: 0, endRadius: 3 * u))
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 0.9 * u, y: p.y - 1.3 * u, width: 1.8 * u, height: 1.8 * u)), with: .color(Pal.signal))
    }

    /// Side-on phone with its screen showing a tiny map and a pulsing blue dot. `glow` 0...1 lights it up.
    static func phone(_ ctx: inout GraphicsContext, _ c: CGPoint, _ u: Double, _ t: Double, glow: Double) {
        let r = CGRect(x: c.x - 3.8 * u, y: c.y - 6.4 * u, width: 7.6 * u, height: 12.8 * u)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 11 * u, y: c.y - 11 * u, width: 22 * u, height: 22 * u)), with: .radialGradient(Gradient(colors: [Pal.coral.opacity(0.22 + 0.35 * glow), .clear]), center: c, startRadius: 0, endRadius: 11 * u))
        ctx.fill(Path(roundedRect: r, cornerRadius: 2 * u), with: .color(Pal.coral))
        let scr = r.insetBy(dx: 0.8 * u, dy: 1.2 * u)
        ctx.fill(Path(roundedRect: scr, cornerRadius: 1.2 * u), with: .linearGradient(Gradient(colors: [Color(hex: 0x14234F), Color(hex: 0x0B1030)]), startPoint: CGPoint(x: scr.midX, y: scr.minY), endPoint: CGPoint(x: scr.midX, y: scr.maxY)))
        var map = Path()
        map.move(to: CGPoint(x: scr.minX, y: scr.minY + scr.height * 0.35)); map.addLine(to: CGPoint(x: scr.maxX, y: scr.minY + scr.height * 0.45))
        map.move(to: CGPoint(x: scr.minX + scr.width * 0.4, y: scr.minY)); map.addLine(to: CGPoint(x: scr.minX + scr.width * 0.55, y: scr.maxY))
        ctx.stroke(map, with: .color(.white.opacity(0.14)), lineWidth: 0.8)
        let d = CGPoint(x: scr.midX + scr.width * 0.06, y: scr.midY)
        let pulse = (t * 1.2).truncatingRemainder(dividingBy: 1)
        ctx.stroke(Path(ellipseIn: CGRect(x: d.x - (1 + 3 * pulse) * u * 0.6, y: d.y - (1 + 3 * pulse) * u * 0.6, width: (1 + 3 * pulse) * u * 1.2, height: (1 + 3 * pulse) * u * 1.2)), with: .color(Pal.ice.opacity(0.8 * (1 - pulse))), lineWidth: 1)
        ctx.fill(Path(ellipseIn: CGRect(x: d.x - 0.9 * u, y: d.y - 0.9 * u, width: 1.8 * u, height: 1.8 * u)), with: .color(Pal.ice))
    }

    /// Glowing ring in three strokes.
    static func ring(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: Double, _ color: Color, alpha: Double = 1, width: Double = 1.8) {
        guard r > 0.5, alpha > 0.01 else { return }
        let p = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        ctx.stroke(p, with: .color(color.opacity(0.10 * alpha)), lineWidth: width * 4.5)
        ctx.stroke(p, with: .color(color.opacity(0.32 * alpha)), lineWidth: width * 1.8)
        ctx.stroke(p, with: .color(color.opacity(0.95 * alpha)), lineWidth: width)
    }

    static func softDot(_ ctx: inout GraphicsContext, _ p: CGPoint, _ r: Double, _ color: Color, alpha: Double = 1) {
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r * 2.4, y: p.y - r * 2.4, width: r * 4.8, height: r * 4.8)), with: .radialGradient(Gradient(colors: [color.opacity(0.55 * alpha), .clear]), center: p, startRadius: 0, endRadius: r * 2.4))
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(alpha)))
    }

    /// Faint map graticule for the from-above scenes.
    static func graticule(_ ctx: inout GraphicsContext, _ s: CGSize) {
        var g = Path()
        let step = s.width / 10
        var x = step / 2; while x < s.width { g.move(to: CGPoint(x: x, y: 0)); g.addLine(to: CGPoint(x: x, y: s.height)); x += step }
        var y = step / 2; while y < s.height { g.move(to: CGPoint(x: 0, y: y)); g.addLine(to: CGPoint(x: s.width, y: y)); y += step }
        ctx.stroke(g, with: .color(Color(hex: 0x6F8CE0).opacity(0.10)), lineWidth: 0.7)
        ctx.fill(Path(CGRect(origin: .zero, size: s)), with: .radialGradient(Gradient(colors: [.clear, Pal.night.opacity(0.65)]), center: CGPoint(x: s.width / 2, y: s.height / 2), startRadius: s.width * 0.35, endRadius: s.width * 0.8))
    }

    /// Satellite seen from straight above: small body, two thin panels, a coloured halo.
    static func topSat(_ ctx: inout GraphicsContext, _ p: CGPoint, _ u: Double, _ color: Color, alpha: Double = 1, t: Double = 0) {
        guard alpha > 0.01 else { return }
        var l = ctx; l.opacity = alpha
        let pulse = 0.5 + 0.5 * sin(t * 3)
        l.fill(Path(ellipseIn: CGRect(x: p.x - 7 * u, y: p.y - 7 * u, width: 14 * u, height: 14 * u)), with: .radialGradient(Gradient(colors: [color.opacity(0.32 + 0.18 * pulse), .clear]), center: p, startRadius: 0, endRadius: 7 * u))
        for side in [-1.0, 1.0] {
            let r = CGRect(x: p.x + (side < 0 ? -6.6 * u : 2.2 * u), y: p.y - 1.4 * u, width: 4.4 * u, height: 2.8 * u)
            l.fill(Path(roundedRect: r, cornerRadius: 0.6 * u), with: .color(Color(hex: 0x7C96EA)))
        }
        l.fill(Path(roundedRect: CGRect(x: p.x - 2 * u, y: p.y - 2 * u, width: 4 * u, height: 4 * u), cornerRadius: 1 * u), with: .color(Color(hex: 0xF4F1EA)))
        l.fill(Path(ellipseIn: CGRect(x: p.x - 0.8 * u, y: p.y - 0.8 * u, width: 1.6 * u, height: 1.6 * u)), with: .color(color))
    }
}

// MARK: - Card 1: satellites broadcast, the phone only listens

struct FlatBroadcast: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 6, still: 2.4, cues: [], label: "Three satellites broadcast signals down to a phone. Each signal carries where the satellite is and when it was sent. The phone only listens.") { ctx, s, t, tap in
            let u = s.width / 100
            let horizonY = s.height * 0.80
            let phone = CGPoint(x: s.width * 0.5, y: horizonY - s.height * 0.075)
            let sats = [CGPoint(x: s.width * 0.17, y: s.height * 0.22), CGPoint(x: s.width * 0.5, y: s.height * 0.12), CGPoint(x: s.width * 0.83, y: s.height * 0.22)]

            Kit.stars(&ctx, s, t)
            Kit.earth(&ctx, s, horizonY: horizonY, t: t)

            var arrive = 0.0
            for (i, p) in sats.enumerated() {
                let ph = ((t + Double(i) * 1.0) / 3.0).truncatingRemainder(dividingBy: 1)
                Kit.ring(&ctx, p, 14 + easeOut(ph) * s.width * 0.3, Pal.signal, alpha: (1 - ph) * 0.38, width: 1.3)
                if let tap, tap < 1.6 { let q = tap / 1.6; Kit.ring(&ctx, p, 14 + easeOut(q) * s.width * 0.42, Pal.signal, alpha: (1 - q) * 0.9, width: 2) }

                // the packet: a lit capsule carrying a pin (where) and a clock (when)
                let q = ((t + Double(i) * 0.9) / 2.7).truncatingRemainder(dividingBy: 1)
                let e = easeInOut(q)
                let a = p, b = CGPoint(x: phone.x, y: phone.y - 8 * u)
                func at(_ k: Double) -> CGPoint { CGPoint(x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k) }
                var guide = Path(); guide.move(to: a); guide.addLine(to: b)
                ctx.stroke(guide, with: .color(Pal.signal.opacity(0.10)), style: StrokeStyle(lineWidth: 1, dash: [2, 5]))
                let tail = max(0, e - 0.22)
                if e > tail {
                    var seg = Path(); seg.move(to: at(tail)); seg.addLine(to: at(e))
                    ctx.stroke(seg, with: .linearGradient(Gradient(colors: [Pal.signal.opacity(0), Pal.signal.opacity(0.9)]), startPoint: at(tail), endPoint: at(e)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                let h = at(e)
                let fade = min(prog(e, 0.04, 0.14), 1 - prog(e, 0.93, 1))
                var l = ctx; l.opacity = fade
                let cap = CGRect(x: h.x - 15, y: h.y - 8.5, width: 30, height: 17)
                l.fill(Path(roundedRect: cap, cornerRadius: 8.5), with: .color(Pal.night.opacity(0.85)))
                l.stroke(Path(roundedRect: cap, cornerRadius: 8.5), with: .color(Pal.signal), lineWidth: 1.2)
                Kit.glyphDraw(&l, .pin, CGPoint(x: h.x - 6.5, y: h.y), Pal.signal)
                Kit.glyphDraw(&l, .clock, CGPoint(x: h.x + 7, y: h.y), Pal.signal)
                if q > 0.93 { arrive = max(arrive, sin((q - 0.93) / 0.07 * .pi)) }
                if q < 0.06 { arrive = max(arrive, sin(.pi * (1 - q / 0.06)) * 0.0) }
            }

            for (i, p) in sats.enumerated() { Kit.satellite(&ctx, p, u, t, phase: Double(i) * 0.37) }

            // the phone listens: rings contract toward it, nothing leaves
            for k in 0..<2 {
                let ph = ((t + Double(k) * 1.1) / 2.2).truncatingRemainder(dividingBy: 1)
                let rr = 8 * u * (1 + (1 - ph) * 1.2)
                ctx.stroke(Path(ellipseIn: CGRect(x: phone.x - rr, y: phone.y - rr, width: 2 * rr, height: 2 * rr)), with: .color(Pal.coral.opacity(ph * 0.55)), lineWidth: 1.4)
            }
            Kit.phone(&ctx, phone, u, t, glow: arrive)

            Kit.chip(&ctx, "SATELLITES", CGPoint(x: sats[1].x, y: sats[1].y + 9 * u), color: .white.opacity(0.85))
            Kit.chip(&ctx, "YOUR PHONE · LISTENING", CGPoint(x: phone.x, y: s.height * 0.915), color: .white)
            Kit.chip(&ctx, "WHERE I AM", CGPoint(x: 12, y: 14), anchor: .topLeading, color: Pal.signal, size: 9, glyph: .pin)
            Kit.chip(&ctx, "TIME SENT", CGPoint(x: 12, y: 38), anchor: .topLeading, color: Pal.signal, size: 9, glyph: .clock)
        }
    }
}

// MARK: - Card 2: lightning, then thunder

struct FlatStorm: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 9.5, still: 5.6, cues: [Cue(0.6, .rigid), Cue(3.6, .heavy), Cue(3.78, .soft), Cue(3.95, .soft)], replayOnTap: true,
                    sky: [0x0A0E26, 0x1B2150, 0x2B3166], label: "A lightning bolt flashes and you see it at once. The thunder takes three seconds to arrive, which means the storm is about one kilometre away.") { ctx, s, t, _ in
            let u = s.width / 100
            let gy = s.height * 0.80
            let strike = CGPoint(x: s.width * 0.19, y: gy)
            let person = CGPoint(x: s.width * 0.84, y: gy)
            let tf = t - 0.6
            // flash envelope with a flicker
            var f = 0.0
            if tf >= 0 { f = tf < 0.08 ? tf / 0.08 : tf < 0.2 ? 1 : tf < 0.3 ? 0.35 : tf < 0.38 ? 0.9 : 0.9 * exp(-(tf - 0.38) * 5) }

            Kit.stars(&ctx, s, t)
            ctx.fill(Path(CGRect(origin: .zero, size: s)), with: .color(.white.opacity(0.20 * f)))

            // storm cloud
            let cc = CGPoint(x: s.width * 0.30, y: s.height * 0.15)
            let lobes: [(Double, Double, Double)] = [(-15, 3, 11), (-5, -3, 13), (7, -2, 12), (16, 3, 10), (0, 5, 14)]
            for (dx, dy, r) in lobes {
                let rect = CGRect(x: cc.x + dx * u - r * u, y: cc.y + dy * u - r * u * 0.7, width: 2 * r * u, height: 1.4 * r * u)
                ctx.fill(Path(ellipseIn: rect), with: .linearGradient(Gradient(colors: [Color(hex: 0x4A527F), Color(hex: 0x262B4E)]), startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: cc.x - 22 * u, y: cc.y - 8 * u, width: 44 * u, height: 22 * u)), with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF0B8).opacity(0.85 * f), .clear]), center: CGPoint(x: cc.x, y: cc.y + 4 * u), startRadius: 0, endRadius: 22 * u))
            // rain
            for i in 0..<16 {
                let x = cc.x + (Double(i) - 8) * 2.4 * u + sin(Double(i) * 1.7) * u
                let y0 = cc.y + 12 * u + ((t * 70 + Double(i) * 23).truncatingRemainder(dividingBy: gy - cc.y - 14 * u))
                var d = Path(); d.move(to: CGPoint(x: x, y: y0)); d.addLine(to: CGPoint(x: x - 2, y: y0 + 9))
                ctx.stroke(d, with: .color(Pal.ice.opacity(0.22)), lineWidth: 1)
            }

            // ground: far ridge, near field, grass edge
            var ridge = Path(); ridge.move(to: CGPoint(x: 0, y: gy - 4 * u))
            for x in stride(from: 0.0, through: 1.0, by: 0.1) { ridge.addLine(to: CGPoint(x: x * s.width, y: gy - (4 + 3.5 * sin(x * 9 + 1)) * u)) }
            ridge.addLine(to: CGPoint(x: s.width, y: gy)); ridge.addLine(to: CGPoint(x: 0, y: gy)); ridge.closeSubpath()
            ctx.fill(ridge, with: .color(Color(hex: 0x16204A).opacity(0.9)))
            ctx.fill(Path(CGRect(x: 0, y: gy, width: s.width, height: s.height - gy)), with: .linearGradient(Gradient(colors: [Color(hex: 0x14355A), Color(hex: 0x081326)]), startPoint: CGPoint(x: 0, y: gy), endPoint: CGPoint(x: 0, y: s.height)))
            ctx.fill(Path(CGRect(x: 0, y: gy, width: s.width, height: 1.6)), with: .color(Color(hex: 0x6FB4FF).opacity(0.5)))

            // bolt
            if f > 0.01 {
                let pts: [(Double, Double)] = [(0.235, 0.255), (0.215, 0.37), (0.262, 0.42), (0.20, 0.57), (0.238, 0.61), (0.19, 0.80)]
                var bolt = Path(); bolt.move(to: CGPoint(x: pts[0].0 * s.width, y: pts[0].1 * s.height))
                for p in pts.dropFirst() { bolt.addLine(to: CGPoint(x: p.0 * s.width, y: p.1 * s.height)) }
                var branch = Path(); branch.move(to: CGPoint(x: 0.20 * s.width, y: 0.57 * s.height)); branch.addLine(to: CGPoint(x: 0.145 * s.width, y: 0.69 * s.height))
                for path in [bolt, branch] {
                    ctx.stroke(path, with: .color(Pal.signal.opacity(0.28 * f)), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                    ctx.stroke(path, with: .color(Pal.signal.opacity(0.9 * f)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    ctx.stroke(path, with: .color(.white.opacity(f)), style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
                }
                Kit.softDot(&ctx, strike, 6, Pal.signal, alpha: f)
            }

            // you
            let lit = f
            ctx.fill(Path(ellipseIn: CGRect(x: person.x - 4 * u, y: person.y - 0.8 * u, width: 8 * u, height: 1.6 * u)), with: .color(.black.opacity(0.35)))
            ctx.fill(Path(roundedRect: CGRect(x: person.x - 1.7 * u, y: person.y - 8.2 * u, width: 3.4 * u, height: 8.2 * u), cornerRadius: 1.5 * u), with: .color(Pal.coral))
            ctx.fill(Path(ellipseIn: CGRect(x: person.x - 1.6 * u, y: person.y - 11.6 * u, width: 3.2 * u, height: 3.2 * u)), with: .color(Color(hex: 0xF2C9A8)))
            ctx.fill(Path(ellipseIn: CGRect(x: person.x - 9 * u, y: person.y - 18 * u, width: 18 * u, height: 22 * u)), with: .radialGradient(Gradient(colors: [Pal.signal.opacity(0.22 * lit), .clear]), center: CGPoint(x: person.x, y: person.y - 7 * u), startRadius: 0, endRadius: 11 * u))
            Kit.chip(&ctx, "YOU", CGPoint(x: person.x, y: person.y + 8 * u), color: .white)

            // light: instant, a lit line of sight
            if f > 0.01 {
                var los = Path(); los.move(to: CGPoint(x: 0.225 * s.width, y: 0.48 * s.height)); los.addLine(to: CGPoint(x: person.x - 2 * u, y: person.y - 10 * u))
                ctx.stroke(los, with: .color(Pal.signal.opacity(0.55 * f)), style: StrokeStyle(lineWidth: 1.3, dash: [3, 4]))
            }
            Kit.chip(&ctx, "LIGHT: ARRIVES AT ONCE", CGPoint(x: s.width * 0.60, y: s.height * 0.31), color: Pal.signal, alpha: prog(tf, 0.1, 0.4) * (1 - prog(t, 8.6, 9.2)))

            // sound: a slow wave leaving the strike point and crawling to you
            let D = person.x - strike.x
            let ta = 3.6
            let v = D / (ta - 0.6)
            let rFront = v * max(0, tf)
            if tf > 0, rFront < D + 8 {
                for k in 0..<4 {
                    let r = rFront - Double(k) * 0.055 * s.width
                    guard r > 4 else { continue }
                    var arc = Path()
                    for i in 0...16 {
                        let e = Double(i) / 16 * (36 * .pi / 180)
                        let pt = CGPoint(x: strike.x + r * cos(e), y: strike.y - r * sin(e))
                        i == 0 ? arc.move(to: pt) : arc.addLine(to: pt)
                    }
                    ctx.stroke(arc, with: .color(Pal.ice.opacity(0.85 / (1 + Double(k) * 0.9))), style: StrokeStyle(lineWidth: 2.4 - Double(k) * 0.4, lineCap: .round))
                }
                let ch = CGPoint(x: strike.x + rFront * cos(0.35), y: strike.y - rFront * sin(0.35) - 12)
                Kit.chip(&ctx, "SOUND: MUCH SLOWER", ch, anchor: .bottom, color: Pal.ice, alpha: prog(rFront, 0.14 * s.width, 0.2 * s.width) * (rFront < D - 30 ? 1 : 0))
            }

            // arrival: boom
            let tb = t - ta
            if tb > 0 {
                for k in 0..<3 {
                    let q = prog(tb, Double(k) * 0.14, 0.9 + Double(k) * 0.14)
                    Kit.ring(&ctx, CGPoint(x: person.x, y: person.y - 5 * u), 5 * u + q * 22 * u, Pal.ice, alpha: (1 - q) * 0.8, width: 1.6)
                }
                let sc = backOut(min(1, tb / 0.28))
                var l = ctx; l.translateBy(x: person.x, y: person.y - 20 * u); l.scaleBy(x: sc, y: sc)
                Kit.chip(&l, "BOOM", .zero, color: Pal.ice, size: 17, alpha: 1 - prog(t, 8.7, 9.3))
            }

            // the counter, and the distance it measures
            let secs = min(3.0, max(0, tf))
            Kit.chip(&ctx, "SECONDS SINCE FLASH", CGPoint(x: s.width - 12, y: 12), anchor: .topTrailing, color: .white.opacity(0.8), alpha: prog(tf, 0, 0.3) * (1 - prog(t, 8.6, 9.2)))
            Kit.chip(&ctx, String(format: "%.1f s", secs), CGPoint(x: s.width - 12, y: 40), anchor: .topTrailing, color: tb > 0 ? Pal.ice : .white, size: 20, alpha: prog(tf, 0, 0.3) * (1 - prog(t, 8.6, 9.2)))
            let by = gy + 14 * u
            let bp = easeOut(prog(t, 4.2, 4.9))
            if bp > 0 {
                let x1 = strike.x, x2 = strike.x + (person.x - strike.x) * bp
                var br = Path(); br.move(to: CGPoint(x: x1, y: by - 5)); br.addLine(to: CGPoint(x: x1, y: by + 5)); br.move(to: CGPoint(x: x1, y: by)); br.addLine(to: CGPoint(x: x2, y: by))
                br.move(to: CGPoint(x: x2, y: by - 5)); br.addLine(to: CGPoint(x: x2, y: by + 5))
                ctx.stroke(br, with: .color(Pal.ice), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                Kit.chip(&ctx, "3 s  ≈  1 km AWAY", CGPoint(x: (x1 + x2) / 2, y: by + 19), color: .white, alpha: prog(t, 4.7, 5.2) * (1 - prog(t, 8.6, 9.2)))
            }
        }
    }
}

// MARK: - Card 3: a signal is a very fast thunderclap

struct FlatDelay: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 9, still: 6.0, cues: [Cue(1.2, .soft), Cue(3.6, .rigid)], replayOnTap: true,
                    label: "A signal leaves a satellite directly overhead and reaches the phone 0.07 seconds later. That tiny delay measures a distance of about 20,200 kilometres.") { ctx, s, t, _ in
            let u = s.width / 100
            let horizonY = s.height * 0.80
            let sat = CGPoint(x: s.width * 0.5, y: s.height * 0.15)
            let phone = CGPoint(x: s.width * 0.5, y: horizonY - s.height * 0.075)
            let top = CGPoint(x: sat.x, y: sat.y + 6 * u), bot = CGPoint(x: phone.x, y: phone.y - 8 * u)
            let t0 = 1.2, t1 = 3.6
            let fl = prog(t, t0, t1)
            let fadeOut = 1 - prog(t, 8.4, 9)

            Kit.stars(&ctx, s, t)
            Kit.earth(&ctx, s, horizonY: horizonY, t: t)

            // launch ring from the satellite
            let lq = prog(t, t0, t0 + 1.0)
            if lq > 0 && lq < 1 { Kit.ring(&ctx, sat, 12 + easeOut(lq) * 26 * u, Pal.signal, alpha: (1 - lq) * 0.9, width: 1.8) }

            // distance bracket, drawn after arrival
            let bx = sat.x - 16 * u
            let bp = easeOut(prog(t, 3.9, 4.6))
            if bp > 0 {
                let y2 = top.y + (bot.y - top.y) * bp
                var br = Path(); br.move(to: CGPoint(x: bx - 5, y: top.y)); br.addLine(to: CGPoint(x: bx + 5, y: top.y)); br.move(to: CGPoint(x: bx, y: top.y)); br.addLine(to: CGPoint(x: bx, y: y2))
                br.move(to: CGPoint(x: bx - 5, y: y2)); br.addLine(to: CGPoint(x: bx + 5, y: y2))
                ctx.stroke(br, with: .color(Pal.signal), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                Kit.chip(&ctx, "20,200 KM", CGPoint(x: bx - 10, y: (top.y + y2) / 2), anchor: .trailing, color: Pal.signal, alpha: prog(t, 4.4, 4.9) * fadeOut)
            }

            // the signal falling
            var guide = Path(); guide.move(to: top); guide.addLine(to: bot)
            ctx.stroke(guide, with: .color(Pal.signal.opacity(0.14)), style: StrokeStyle(lineWidth: 1, dash: [2, 5]))
            if t >= t0 {
                let e = fl
                let h = CGPoint(x: top.x, y: top.y + (bot.y - top.y) * e)
                let tailY = top.y + (bot.y - top.y) * max(0, e - 0.2)
                var seg = Path(); seg.move(to: CGPoint(x: top.x, y: tailY)); seg.addLine(to: h)
                ctx.stroke(seg, with: .linearGradient(Gradient(colors: [Pal.signal.opacity(0), Pal.signal]), startPoint: CGPoint(x: top.x, y: tailY), endPoint: h), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                Kit.softDot(&ctx, h, 4.5, Pal.signal, alpha: 1 - prog(t, t1, t1 + 0.35))
                // running clock rides along, counts the tiny delay
                let tick = 0.07 * fl
                Kit.chip(&ctx, String(format: "%.2f s", tick), CGPoint(x: h.x + 16, y: h.y), anchor: .leading, color: .white, size: 11, alpha: (1 - prog(t, t1, t1 + 0.3)))
            }
            // arrival burst
            let aq = prog(t, t1, t1 + 0.9)
            if aq > 0 && aq < 1 { Kit.ring(&ctx, CGPoint(x: phone.x, y: phone.y - 5 * u), 6 * u + easeOut(aq) * 18 * u, Pal.coral, alpha: (1 - aq) * 0.9, width: 1.8) }

            Kit.satellite(&ctx, sat, u, t)
            Kit.phone(&ctx, phone, u, t, glow: t >= t1 ? max(0, 1 - (t - t1) / 0.8) : 0)

            Kit.chip(&ctx, "SENT 0.00 s", CGPoint(x: sat.x + 18 * u, y: sat.y), anchor: .leading, color: Pal.signal, alpha: prog(t, t0 - 0.1, t0 + 0.3) * fadeOut, glyph: .clock)
            Kit.chip(&ctx, "ARRIVED 0.07 s", CGPoint(x: phone.x + 11 * u, y: phone.y), anchor: .leading, color: Pal.coral, alpha: prog(t, t1, t1 + 0.3) * fadeOut, glyph: .clock)
            Kit.chip(&ctx, "SLOWED WAY DOWN", CGPoint(x: 12, y: 14), anchor: .topLeading, color: .white.opacity(0.8), alpha: prog(t, 0.6, 1.0) * (1 - prog(t, t1 + 0.4, t1 + 0.8)))
            Kit.chip(&ctx, "0.07 s TRIP  =  20,200 KM AWAY", CGPoint(x: s.width / 2, y: s.height * 0.915), color: .white, alpha: prog(t, 5.0, 5.6) * fadeOut)
        }
    }
}

// MARK: - Card 4: one distance, a ring of places

struct FlatRing: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 12, still: 6, cues: [Cue(0.5, .soft), Cue(2.1, .rigid)], replayOnTap: true, sky: [0x0A1030, 0x0F1A48, 0x14225A],
                    label: "A map seen from above. One satellite sits in the middle with a ring around it. You could be anywhere on the ring, because every point on it is the same distance away.") { ctx, s, t, _ in
            let u = s.width / 100
            let c = CGPoint(x: s.width * 0.5, y: s.height * 0.47)
            let R = s.width * 0.34
            let fade = 1 - prog(t, 11.3, 12)
            Kit.stars(&ctx, s, t)
            Kit.graticule(&ctx, s)

            let g = easeInOut(prog(t, 0.5, 2.1))
            // signal spreading out: a soft disc leading the ring
            if g > 0 && g < 1 {
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - R * g, y: c.y - R * g, width: 2 * R * g, height: 2 * R * g)), with: .radialGradient(Gradient(colors: [Pal.signal.opacity(0.0), Pal.signal.opacity(0.16)]), center: c, startRadius: 0, endRadius: max(1, R * g)))
            }
            Kit.ring(&ctx, c, R * g, Pal.signal, alpha: fade, width: 2.2)
            // ticks
            let tk = prog(t, 2.0, 2.8)
            if tk > 0 {
                var ticks = Path()
                for i in 0..<48 { let a = Double(i) / 48 * 2 * .pi; ticks.move(to: CGPoint(x: c.x + (R - 4) * cos(a), y: c.y + (R - 4) * sin(a))); ticks.addLine(to: CGPoint(x: c.x + (R + 4) * cos(a), y: c.y + (R + 4) * sin(a))) }
                ctx.stroke(ticks, with: .color(Pal.signal.opacity(0.35 * tk * fade)), lineWidth: 0.9)
            }
            // you: somewhere on the ring, drifting round it
            if t > 2.3 {
                let ang = -.pi / 2 + (t - 2.3) * 0.85
                let on = prog(t, 2.3, 2.8) * fade
                for k in 1...18 {
                    let a = ang - Double(k) * 0.045
                    Kit.softDot(&ctx, CGPoint(x: c.x + R * cos(a), y: c.y + R * sin(a)), 2.6 * (1 - Double(k) / 20), Pal.coral, alpha: on * (1 - Double(k) / 20) * 0.7)
                }
                let d = CGPoint(x: c.x + R * cos(ang), y: c.y + R * sin(ang))
                var spoke = Path(); spoke.move(to: c); spoke.addLine(to: d)
                ctx.stroke(spoke, with: .color(Pal.coral.opacity(0.45 * on)), style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
                Kit.softDot(&ctx, d, 5.5, Pal.coral, alpha: on)
                let out = CGPoint(x: d.x + 22 * cos(ang), y: d.y + 22 * sin(ang))
                Kit.chip(&ctx, "YOU?", out, color: Pal.coral, alpha: on)
                let mid = CGPoint(x: c.x + R * 0.5 * cos(ang), y: c.y + R * 0.5 * sin(ang))
                Kit.chip(&ctx, "SAME DISTANCE", mid, color: .white, size: 9, alpha: prog(t, 3.0, 3.6) * fade)
            }
            Kit.topSat(&ctx, c, u, Pal.signal, alpha: prog(t, 0, 0.4), t: t)
            Kit.chip(&ctx, "SATELLITE", CGPoint(x: c.x, y: c.y - 11 * u), color: .white.opacity(0.85), alpha: prog(t, 0.3, 0.8) * fade)
            Kit.chip(&ctx, "A MAP FROM ABOVE", CGPoint(x: 12, y: s.height - 12), anchor: .bottomLeading, color: .white.opacity(0.7))
        }
    }
}

// MARK: - Card 5: three rings, one spot

struct FlatMeet: View {
    let active: Bool
    var body: some View {
        FlatPicture(active: active, period: 12.5, still: 11.0, cues: [Cue(0.3, .soft), Cue(1.9, .soft), Cue(3.2, .light), Cue(4.6, .soft), Cue(6.8, .success), Cue(8.7, .light)], replayOnTap: true, sky: [0x0A1030, 0x0F1A48, 0x14225A],
                    label: "A map from above. Rings from two satellites cross at two places. A third ring goes through only one of them, and that place is you. At the end, more satellites add more rings through the same place, because real phones use four or more.") { ctx, s, t, _ in
            let k = min(s.width / 100, s.height / 96) * 0.88
            let ox = (s.width - 100 * k) / 2, oy = (s.height - 96 * k) / 2 - 8
            func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + x * k, y: oy + y * k) }
            let A = P(50, 28), B = P(27.5, 67), Cc = P(72.5, 67)
            let r = 26 * k
            let x1 = P(50, 54), x2 = P(27.5, 41)
            let fade = 1 - prog(t, 11.8, 12.5)

            Kit.stars(&ctx, s, t)
            Kit.graticule(&ctx, s)

            let ga = easeInOut(prog(t, 0.3, 1.6)), gb = easeInOut(prog(t, 1.9, 3.2)), gc = easeInOut(prog(t, 4.6, 5.9))
            Kit.ring(&ctx, A, r * ga, Pal.ringA, alpha: fade)
            Kit.ring(&ctx, B, r * gb, Pal.ringB, alpha: fade)
            Kit.ring(&ctx, Cc, r * gc, Pal.ringC, alpha: fade)

            // the ending: real phones use more satellites, and every extra ring goes through the same place
            if t > 8.6 {
                let extras: [(Double, Double)] = [(8, 10), (93, 12), (92, 90), (8, 88)]
                for (i, e) in extras.enumerated() {
                    let sp = P(e.0, e.1)
                    let g2 = easeInOut(prog(t, 8.6 + Double(i) * 0.25, 10.2 + Double(i) * 0.25))
                    let rr = hypot(sp.x - x1.x, sp.y - x1.y)
                    ctx.drawLayer { l in
                        l.clip(to: Path(ellipseIn: CGRect(x: x1.x - 30 * k, y: x1.y - 30 * k, width: 60 * k, height: 60 * k)))
                        l.stroke(Path(ellipseIn: CGRect(x: sp.x - rr * g2, y: sp.y - rr * g2, width: 2 * rr * g2, height: 2 * rr * g2)), with: .color(Color(hex: 0xBFD2FF).opacity(0.55 * fade)), lineWidth: 1.2)
                    }
                    Kit.topSat(&ctx, sp, k * 0.7, Color(hex: 0xBFD2FF), alpha: prog(t, 8.6 + Double(i) * 0.25, 9.0 + Double(i) * 0.25) * 0.8 * fade, t: t + Double(i))
                }
            }

            // two crossings after two rings; the right one is kept after the third
            let pp = backOut(prog(t, 3.2, 3.7))
            let keep = prog(t, 6.8, 7.2)        // 0 until the spot is chosen
            let drop = 1 - prog(t, 6.6, 7.1)
            if t > 3.2 {
                Kit.softDot(&ctx, x2, 4.2 * pp, .white, alpha: drop * fade)
                if t > 6.6 {} else if t > 5.9 { Kit.chip(&ctx, "NOT HERE", CGPoint(x: x2.x - 14, y: x2.y - 4), anchor: .trailing, color: Pal.coral, size: 9, alpha: prog(t, 5.9, 6.2)) }
                if keep == 0 { Kit.softDot(&ctx, x1, 4.2 * pp, .white, alpha: fade) }
            }
            if keep > 0 {
                for q in 0..<3 {
                    let w = prog(t, 6.8 + Double(q) * 0.22, 7.9 + Double(q) * 0.22)
                    Kit.ring(&ctx, x1, 6 + w * 30, Pal.coral, alpha: (1 - w) * 0.9 * fade, width: 1.6)
                }
                Kit.softDot(&ctx, x1, 6.2 * backOut(keep), Pal.coral, alpha: fade)
                Kit.chip(&ctx, "YOU", CGPoint(x: x1.x + 20, y: x1.y + 6), anchor: .leading, color: Pal.coral, size: 13, alpha: keep * fade)
            }

            Kit.topSat(&ctx, A, k, Pal.ringA, alpha: prog(t, 0, 0.3) * fade, t: t)
            Kit.topSat(&ctx, B, k, Pal.ringB, alpha: prog(t, 1.6, 1.9) * fade, t: t + 1)
            Kit.topSat(&ctx, Cc, k, Pal.ringC, alpha: prog(t, 4.3, 4.6) * fade, t: t + 2)

            let cap: String; let cp: Double
            if t < 1.9 { cap = "1 SATELLITE  →  A RING OF PLACES"; cp = prog(t, 0.2, 0.6) * (1 - prog(t, 1.6, 1.9)) }
            else if t < 4.6 { cap = "2 SATELLITES  →  TWO POSSIBLE PLACES"; cp = prog(t, 2.0, 2.4) * (1 - prog(t, 4.3, 4.6)) }
            else if t < 6.8 { cap = "3 SATELLITES  →  ONLY ONE FITS"; cp = prog(t, 4.7, 5.1) * (1 - prog(t, 6.5, 6.8)) }
            else if t < 8.5 { cap = "THAT PLACE IS YOU"; cp = prog(t, 6.9, 7.3) * (1 - prog(t, 8.2, 8.5)) }
            else { cap = "REAL PHONES USE 4 OR MORE"; cp = prog(t, 8.7, 9.1) * fade }
            Kit.chip(&ctx, cap, CGPoint(x: s.width / 2, y: s.height - 14), anchor: .bottom, color: (t >= 6.8 && t < 8.5) ? Pal.coral : .white, alpha: cp)
        }
    }
}

// MARK: - Support

extension Color {
    init(hex: UInt32) { self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255) }
}
