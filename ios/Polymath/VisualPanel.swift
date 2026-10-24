import SwiftUI

/// Wireframe stand-in for a picture. It shows what the real picture is (its type), cycles the step notes the way the animation steps would,
/// lists the labels it would carry, and runs the real interaction-cue behaviour.
struct VisualPanel: View {
    @Environment(Session.self) private var session
    let visual: Visual?
    let active: Bool
    @State private var step = 0
    @State private var cueOn = false
    @State private var touched = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2).fill(T.panel)
            RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1)
            if let v = visual { placeholder(v) }
        }
        .overlay(alignment: .bottom) {
            if let tip = visual?.tip { CuePill(text: tip).opacity(cueOn ? 1 : 0).offset(y: cueOn ? 24 : 29).animation(.easeOut(duration: 0.4), value: cueOn) }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in touch() })
        .task(id: active) { await cueLoop() }
        .task(id: active) { await stepLoop() }
    }

    private func placeholder(_ v: Visual) -> some View {
        VStack(spacing: 12) {
            Image(systemName: Self.symbol(v.type)).font(.system(size: 34, weight: .light)).foregroundStyle(T.ink2)
            Text("\(v.type) picture").monoLabel().foregroundStyle(T.ink2)
            if !v.notes.isEmpty {
                Text(v.notes[step % v.notes.count]).monoLabel(12).foregroundStyle(T.ink)
                    .multilineTextAlignment(.center).padding(.horizontal, 24).id(step)
                    .transition(.opacity)
            }
            if !v.labels.isEmpty {
                Text(v.labels.prefix(6).joined(separator: "  ·  ")).monoLabel(10).foregroundStyle(T.ink2.opacity(0.8))
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
        }
        .overlay(alignment: .topLeading) {
            if v.notes.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<v.notes.count, id: \.self) { i in Circle().stroke(i == step % v.notes.count ? T.accent : T.ink2, lineWidth: 1.2).background(Circle().fill(i == step % v.notes.count ? T.accent : .clear)).frame(width: 8, height: 8) }
                }.padding(14)
            }
        }
    }

    static func symbol(_ type: String) -> String {
        switch type {
        case "gears": return "gearshape.2"
        case "crank": return "gearshape"
        case "strokes": return "arrow.up.arrow.down"
        case "cylinders": return "chart.bar"
        default: return "square.on.circle"
        }
    }

    private func touch() {
        guard !touched else { return }
        touched = true; session.learned = true; cueOn = false
    }

    /// Same timing as the web cue: in after 0.7 s, gone after about 6 s, never once touched or once the reader has used any picture.
    private func cueLoop() async {
        cueOn = false
        guard active, visual?.tip != nil else { return }
        try? await Task.sleep(for: .milliseconds(700))
        guard !Task.isCancelled, !touched, !session.learned else { return }
        cueOn = true
        try? await Task.sleep(for: .milliseconds(5500))
        if !Task.isCancelled { cueOn = false }
    }

    private func stepLoop() async {
        step = 0
        guard active, let n = visual?.notes.count, n > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(1100))
            if Task.isCancelled { break }
            withAnimation(.easeInOut(duration: 0.4)) { step = (step + 1) % n }
        }
    }
}

/// Dark pill on the picture's bottom edge: a pulsing dot and what can be touched.
struct CuePill: View {
    let text: String
    @State private var pulse = false
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(T.accent).frame(width: 8, height: 8)
                .overlay(Circle().stroke(T.accent, lineWidth: 1.5).scaleEffect(pulse ? 2.6 : 1).opacity(pulse ? 0 : 0.9))
            Text(text).monoLabel().foregroundStyle(T.paper).fixedSize()
        }
        .padding(.leading, 10).padding(.trailing, 13).padding(.vertical, 7)
        .background(Capsule().fill(T.ink))
        .allowsHitTesting(false)
        .onAppear { withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { pulse = true } }
    }
}
