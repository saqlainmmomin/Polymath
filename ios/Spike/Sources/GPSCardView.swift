import SwiftUI
import RealityKit

/// Picture panel for a GPS card: same panel treatment as the shared VisualPanel (2pt corners, rule stroke), 3D scene inside.
/// Only the card on screen gets a live RealityView: with one per lazily built card, the newest view stalled (frozen, black globe) while the others kept rendering.
struct GPSPicture: View {
    let mode: Int
    let active: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.02, green: 0.03, blue: 0.10), Color(red: 0.08, green: 0.11, blue: 0.27)], startPoint: .top, endPoint: .bottom)
            if active { GPSLive(mode: mode) }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
    }
}

/// The scene itself, created fresh each time its card becomes the current one.
private struct GPSLive: View {
    let mode: Int
    @StateObject private var scene: GPSScene
    @Environment(\.accessibilityReduceMotion) private var reduce

    init(mode: Int) {
        self.mode = mode
        _scene = StateObject(wrappedValue: GPSScene(mode: mode))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RealityView { content in await scene.build(content) }
                ForEach(scene.labels) { l in
                    Text(l.text).font(T.mono(11)).textCase(.uppercase).tracking(0.9)
                        .foregroundStyle(l.you ? Color.black.opacity(0.85) : .white)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(l.you ? Color(red: 1, green: 0.42, blue: 0.29) : Color(red: 0.03, green: 0.05, blue: 0.13).opacity(0.8)))
                        .fixedSize()
                        .opacity(l.opacity)
                        .position(x: l.x * geo.size.width + l.dx, y: l.y * geo.size.height + l.dy)
                }
                if let clock = scene.clock {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(clock.title).font(T.mono(10)).textCase(.uppercase).tracking(0.9).foregroundStyle(.white.opacity(0.65))
                        Text(clock.text).font(T.mono(17)).foregroundStyle(.white)
                    }
                    .opacity(clock.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(14)
                }
            }
            .onAppear { scene.aspect = Float(geo.size.width / max(geo.size.height, 1)); scene.setActive(true, reduce: reduce) }
            .onChange(of: geo.size) { _, s in scene.aspect = Float(s.width / max(s.height, 1)) }
        }
        .onChange(of: reduce) { _, r in scene.setActive(true, reduce: r) }
    }
}
