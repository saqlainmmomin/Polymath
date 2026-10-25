import SwiftUI

/// First launch only: a name, then interests, then straight to the feed.
struct OnboardingView: View {
    @Environment(Profile.self) private var profile
    @State private var step = 0
    @State private var name = ""
    @State private var picked: Set<String> = []

    var body: some View {
        ZStack {
            T.paper.ignoresSafeArea()
            if step == 0 {
                NameStep(name: $name) { withAnimation(.easeInOut(duration: 0.3)) { step = 1 } }
                    .transition(.asymmetric(insertion: .identity, removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                InterestsStep(name: name, picked: $picked,
                              back: { withAnimation(.easeInOut(duration: 0.3)) { step = 0 } },
                              done: { profile.finish(name: name, interests: picked) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
}

private struct NameStep: View {
    @Binding var name: String
    let next: () -> Void
    @FocusState private var focused: Bool
    private var ready: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Polymath").monoLabel().foregroundStyle(T.accent)
            Text("What should we call you?").font(T.serif(38, .medium)).foregroundStyle(T.ink)
                .padding(.top, 12).fixedSize(horizontal: false, vertical: true)
            Text("No sign-up. Just a name, kept on this phone.").font(T.serif(18)).foregroundStyle(T.ink2).padding(.top, 10)
            TextField("", text: $name, prompt: Text("Your first name").foregroundStyle(T.ink2.opacity(0.6)))
                .font(T.serif(28)).foregroundStyle(T.ink)
                .textContentType(.givenName).textInputAutocapitalization(.words).autocorrectionDisabled()
                .submitLabel(.continue).focused($focused)
                .onSubmit { if ready { next() } }
                .padding(.top, 32).padding(.bottom, 10)
                .overlay(alignment: .bottom) { Rectangle().fill(focused ? T.accent : T.rule).frame(height: 2) }
            Spacer()
            PrimaryButton(title: "Continue", enabled: ready, action: next)
        }
        .padding(.horizontal, 24).padding(.bottom, 16)
        .background {
            ZStack {
                Circle().fill(Color(hex: 0xFF8A3D).opacity(0.5)).frame(width: 300).blur(radius: 70).offset(x: 110, y: -260)
                Circle().fill(Color(hex: 0x6FAAE0).opacity(0.4)).frame(width: 260).blur(radius: 70).offset(x: -130, y: 220)
            }
            .allowsHitTesting(false)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true } }
    }
}

/// Watches the enclosing UIScrollView's offset frame by frame (SwiftUI's own scroll preferences only report when scrolling settles).
private struct ScrollWatcher: UIViewRepresentable {
    let onOffset: (CGFloat) -> Void
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.onOffset = onOffset
        guard context.coordinator.observation == nil else { return }
        DispatchQueue.main.async {
            var v: UIView? = view
            while let cur = v, !(cur is UIScrollView) { v = cur.superview }
            guard let sv = v as? UIScrollView else { return }
            context.coordinator.origin = sv.contentOffset.y
            context.coordinator.observation = sv.observe(\.contentOffset, options: [.new]) { sv, _ in
                context.coordinator.onOffset(sv.contentOffset.y - context.coordinator.origin)
            }
        }
    }
    final class Coordinator { var onOffset: (CGFloat) -> Void = { _ in }; var origin: CGFloat = 0; var observation: NSKeyValueObservation? }
}

/// Choices ride a circular arc on the right: the row at the middle of the screen sits furthest in, rows toward the top and bottom swing out to the corners.
private struct InterestsStep: View {
    let name: String
    @Binding var picked: Set<String>
    let back: () -> Void
    let done: () -> Void
    private let minimum = 3
    private let rowHeight: CGFloat = 96
    private let radius: CGFloat = 400
    private let tick = UISelectionFeedbackGenerator()
    @State private var lastIndex = -1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let cy = h * 0.55                    // the row at rest here is "in front of you"
            let restX = w * 0.60                 // its icon centre
            let railX = restX + 62               // where the rail passes at cy
            ZStack {
                Circle().stroke(T.rule, lineWidth: 1).frame(width: radius * 2, height: radius * 2)
                    .position(x: railX + radius, y: cy).allowsHitTesting(false)
                Capsule().fill(T.ink).frame(width: 7, height: 34).position(x: railX, y: cy).allowsHitTesting(false)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Subject.all, id: \.name) { s in
                            WheelRow(subject: s, on: picked.contains(s.name), trailing: w - restX - 33, cy: cy, radius: radius) {
                                if picked.contains(s.name) { picked.remove(s.name) } else { picked.insert(s.name) }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            .frame(height: rowHeight)
                        }
                    }
                    .scrollTargetLayout()
                    .background(ScrollWatcher { offset in
                        // The row on the middle at rest is index 2; each rowHeight of scroll moves one row through it.
                        let i = 2 + Int((offset / rowHeight).rounded())
                        guard i != lastIndex else { return }
                        if lastIndex != -1, Subject.all.indices.contains(i) { tick.selectionChanged(); tick.prepare() }
                        lastIndex = i
                    })
                }
                .coordinateSpace(name: "wheel")
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.top, cy - 2.5 * rowHeight, for: .scrollContent)      // rows 0 and 1 sit above the middle, row 2 on it
                .contentMargins(.bottom, h - cy - rowHeight / 2, for: .scrollContent)
                .scrollIndicators(.hidden)
            }
            .overlay(alignment: .top) { header }
            .overlay(alignment: .bottom) {
                PrimaryButton(title: picked.count >= minimum ? "Start exploring" : "Pick \(minimum - picked.count) more",
                              enabled: picked.count >= minimum, action: done)
                    .padding(.horizontal, 24).padding(.bottom, 16)
            }
            .onAppear { tick.prepare() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: back) { Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)).foregroundStyle(T.ink2).frame(width: 44, height: 44, alignment: .leading) }
                .accessibilityLabel("Back")
            Text("Hi \(name.trimmingCharacters(in: .whitespaces)). What pulls you in?").font(T.serif(30, .medium)).foregroundStyle(T.ink).padding(.top, 6).fixedSize(horizontal: false, vertical: true)
            Text("Scroll, tap \(minimum) or more").monoLabel().foregroundStyle(T.ink2).padding(.top, 10)
        }
        .padding(.horizontal, 24).padding(.bottom, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(stops: [.init(color: T.paper, location: 0), .init(color: T.paper, location: 0.78), .init(color: T.paper.opacity(0), location: 1)], startPoint: .top, endPoint: .bottom))
    }
}

/// One choice: label left, app-icon style tile right. Picked = label in a chip, tile ringed with a tick.
private struct WheelRow: View {
    let subject: (name: String, icon: String, color: Color)
    let on: Bool
    let trailing: CGFloat
    let cy: CGFloat
    let radius: CGFloat
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 14) {
                Text(subject.name).font(T.serif(on ? 21 : 19, on ? .semibold : .medium)).foregroundStyle(on ? T.ink : T.ink2)
                    .padding(.horizontal, on ? 14 : 0).padding(.vertical, on ? 7 : 0)
                    .background { if on { Capsule().fill(T.panel).overlay(Capsule().stroke(T.rule, lineWidth: 1)) } }
                    .visualEffect { [cy, radius] c, proxy in   // the label leans along the arc; the tile stays upright
                        let dy = max(-radius * 0.95, min(radius * 0.95, proxy.frame(in: .named("wheel")).midY - cy))
                        return c.rotationEffect(.degrees(-Double(asin(dy / radius)) * 180 / .pi * 0.9), anchor: .trailing)
                    }
                // A soft grey blob with a thin coloured line icon; picked, it tints and gets a coloured outline.
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(on ? subject.color.opacity(0.14) : T.ink.opacity(0.055))
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(subject.color.opacity(on ? 1 : 0), lineWidth: 1.5)
                    Image(systemName: subject.icon).font(.system(size: 27, weight: .light)).foregroundStyle(subject.color)
                }
                .frame(width: on ? 80 : 72, height: on ? 66 : 62)
            }
            .contentShape(Rectangle())
            .visualEffect { [cy, radius] c, proxy in    // swing round the arc, shrink and fade away from the middle
                let dy = max(-radius * 0.95, min(radius * 0.95, proxy.frame(in: .named("wheel")).midY - cy))
                let swing = radius - (radius * radius - dy * dy).squareRoot()
                let t = abs(dy) / radius
                return c.offset(x: swing).scaleEffect(1 - 0.3 * t, anchor: .trailing).opacity(max(0.05, 1 - 0.95 * pow(t, 1.5)))
            }
            .padding(.trailing, trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: on)
        .accessibilityLabel(subject.name)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

private struct PrimaryButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(T.serif(19, .semibold)).foregroundStyle(enabled ? T.paper : T.ink2)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(enabled ? T.accent : Color(light: 0xCFC6B6, dark: 0x3A342C)))
        }
        .disabled(!enabled)
    }
}
