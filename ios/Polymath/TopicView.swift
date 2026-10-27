import SwiftUI

/// One topic slot on its own gradient: room at the top for the feed's fixed avatar, a row of cards that pages sideways, like and save on the right, page dots at the bottom.
struct TopicView: View {
    @Environment(Store.self) private var store
    @Environment(Shelf.self) private var shelf
    let topic: Topic
    let isCurrent: Bool
    let jump: (String) -> Void
    @State private var card = 0
    @State private var drag: CGFloat = 0
    @State private var axis: Axis?

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 42)   // under the avatar, which stays put while topics move
            // Cards side by side, slid by hand rather than a horizontal ScrollView, whose pan only caught swipes that started on text.
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Array(topic.cards.enumerated()), id: \.offset) { i, c in
                        CardView(topic: topic, card: c, index: i, isActive: isCurrent && card == i, jump: jump)
                            .frame(width: geo.size.width)
                    }
                }
                .offset(x: -CGFloat(card) * geo.size.width + drag)
                .frame(width: geo.size.width, alignment: .leading)
            }
            dots
        }
        .contentShape(Rectangle())
        .simultaneousGesture(swipe)
        .overlay(alignment: .bottomTrailing) { actions.padding(.trailing, 16).padding(.bottom, 52) }
        .onAppear {
            if Launch.topic == topic.id, let n = Launch.card, n < topic.cards.count { card = n }
        }
    }

    /// Any sideways swipe anywhere on the page changes card; the page follows the finger once the drag is mostly sideways.
    /// Mostly vertical drags are left to the feed, which changes topic.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { v in
                if axis == nil { axis = abs(v.translation.width) > abs(v.translation.height) ? .horizontal : .vertical }
                guard axis == .horizontal else { return }
                let atEnd = (v.translation.width < 0 && card == topic.cards.count - 1) || (v.translation.width > 0 && card == 0)
                drag = v.translation.width * (atEnd ? 0.25 : 1)   // rubber band past the first and last card
            }
            .onEnded { v in
                defer { axis = nil }
                guard axis == .horizontal else { return }
                let w = UIScreen.main.bounds.width
                let dx = v.translation.width, fling = v.predictedEndTranslation.width
                var next = card
                if dx < -40 || fling < -w * 0.25 { next = min(card + 1, topic.cards.count - 1) }
                else if dx > 40 || fling > w * 0.25 { next = max(card - 1, 0) }
                if next != card { UISelectionFeedbackGenerator().selectionChanged() }
                drag += CGFloat(next - card) * w   // keep the page where the finger left it, then spring to the new card
                card = next
                withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) { drag = 0 }
            }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            GlassButton(symbol: "heart", on: shelf.liked.contains(topic.id), tint: Color(hex: 0xF43F5E), label: "Like") { shelf.toggleLike(topic.id) }
            GlassButton(symbol: "bookmark", on: shelf.saved.contains(topic.id), tint: S.text, label: "Save") { shelf.toggleSave(topic.id) }
        }
    }

    private var dots: some View {
        let cur = card
        return ZStack {
            HStack(spacing: 6) {
                ForEach(0..<topic.cards.count, id: \.self) { i in
                    Capsule().fill(i == cur ? S.dotOn : S.dotOff).frame(width: i == cur ? 22 : 6, height: 6)
                }
            }
            .animation(.easeOut(duration: 0.25), value: cur)
            if cur == 0 && topic.cards.count > 1 {
                HStack { Spacer(); NudgeSwipe() }.padding(.trailing, 21)
            }
        }
        .frame(height: 30)
    }
}

/// 48pt Liquid Glass circle (Apple's interactive glass effect on iOS 26+, the hand-made glass before) with an outline icon; on, the icon fills with its tint.
struct GlassButton: View {
    let symbol: String
    let on: Bool
    let tint: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: on ? symbol + ".fill" : symbol)
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(on ? tint : S.text)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: on)
                .frame(width: 48, height: 48)
        }
        .modifier(NativeGlass())
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// The reader's first initial in a small Liquid Glass circle; opens their profile.
struct Avatar: View {
    let name: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(name.first.map { String($0).uppercased() } ?? "?")
                .font(S.rounded(17, .semibold)).foregroundStyle(S.text)
                .frame(width: 40, height: 40)
        }
        .modifier(NativeGlass())
        .accessibilityLabel("Profile")
    }
}

/// Apple's interactive Liquid Glass circle where the system has it (it lifts and shimmers under the finger); the hand-made glass otherwise.
private struct NativeGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.buttonStyle(.plain).glassEffect(.regular.interactive(), in: .circle)   // the effect, not .glass style, so the circle stays exactly 48pt
        } else {
            content.buttonStyle(.plain).glass()
        }
    }
}

/// Frosted-glass circle behind a button: material, a white sheen and rim, a soft warm shadow.
private struct Glass: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let k = scheme == .dark ? 0.25 : 1.0   // the sheen and rim, toned down on a dark gradient
        content.background {
            Circle().fill(.ultraThinMaterial)
                .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.45 * k), .white.opacity(0.12 * k)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                .overlay(Circle().strokeBorder(.white.opacity(0.55 * k), lineWidth: 1))
                .shadow(color: Color(red: 120 / 255, green: 80 / 255, blue: 60 / 255).opacity(0.12), radius: 10, y: 6)
        }
    }
}
extension View { func glass() -> some View { modifier(Glass()) } }

/// "Swipe →" with the arrow nudging, shown on card 1 only.
struct NudgeSwipe: View {
    @State private var out = false
    var body: some View {
        HStack(spacing: 6) {
            Text("Swipe")
            Text("→").offset(x: out ? 5 : 0)
        }
        .font(S.rounded(13, .medium)).foregroundStyle(S.faint)
        .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { out = true } }
    }
}
