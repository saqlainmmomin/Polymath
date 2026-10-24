import SwiftUI

/// One topic slot: a small bar (the topic question on cards 2+), a row of cards that pages sideways, then page dots.
struct TopicView: View {
    @Environment(Store.self) private var store
    let topic: Topic
    let isCurrent: Bool
    let openIndex: () -> Void
    let jump: (String) -> Void
    @State private var card: Int? = 0

    var body: some View {
        VStack(spacing: 0) {
            bar
            Rectangle().fill(T.rule).frame(height: 1)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(topic.cards.enumerated()), id: \.offset) { i, c in
                        CardView(topic: topic, card: c, index: i, isActive: isCurrent && card == i, jump: jump)
                            .containerRelativeFrame(.horizontal)
                            .id(i)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $card)
            .scrollIndicators(.hidden)
            dots
        }
        .onAppear {
            if Launch.topic == topic.id, let n = Launch.card, n < topic.cards.count { card = n }
        }
    }

    private var bar: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(topic.title)
                .font(T.serif(14, .medium)).foregroundStyle(T.ink2).lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity((card ?? 0) == 0 ? 0 : 1)
                .animation(.easeOut(duration: 0.25), value: card)
            Button("Index", action: openIndex)
                .monoLabel().foregroundStyle(T.ink2).underline(color: T.rule)
                .buttonStyle(.plain).padding(8)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 48)
    }

    private var dots: some View {
        let cur = card ?? 0
        return ZStack {
            HStack(spacing: 7) {
                ForEach(0..<topic.cards.count, id: \.self) { i in
                    Capsule().fill(i == cur ? T.accent : T.rule).frame(width: i == cur ? 20 : 7, height: 7)
                }
            }
            .animation(.easeOut(duration: 0.25), value: cur)
            if cur == 0 && topic.cards.count > 1 {
                HStack { Spacer(); NudgeSwipe() }.padding(.trailing, 20)
            }
        }
        .frame(height: 34)
    }
}

/// "Swipe →" with the arrow nudging, shown on card 1 only.
struct NudgeSwipe: View {
    @State private var out = false
    var body: some View {
        HStack(spacing: 6) {
            Text("Swipe")
            Text("→").offset(x: out ? 5 : 0)
        }
        .monoLabel().foregroundStyle(T.ink2)
        .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { out = true } }
    }
}
