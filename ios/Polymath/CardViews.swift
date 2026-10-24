import SwiftUI

/// Dispatches on card type. Every card is three zones, headline above, picture in the middle (takes all spare height), paragraph below.
struct CardView: View {
    let topic: Topic
    let card: Card
    let index: Int
    let isActive: Bool
    let jump: (String) -> Void

    var body: some View {
        switch card.type {
        case "more": MoreCard(topic: topic, card: card, jump: jump)
        case "guess": GuessCard(card: card, isActive: isActive)
        default: StandardCard(topic: topic, card: card, opener: index == 0, isActive: isActive)
        }
    }
}

private struct Lead: View {
    let headline: String
    var setup: String? = nil
    var opener = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(headline)
                .font(T.serif(opener ? 33 : 26, opener ? .semibold : .medium))
                .tracking(opener ? -0.7 : -0.4)
                .lineSpacing(opener ? -2 : 0)
                .foregroundStyle(T.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let setup {
                Text(setup).font(T.serif(18)).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, opener ? 12 : 14)
    }
}

struct StandardCard: View {
    let topic: Topic
    let card: Card
    let opener: Bool
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Card 1's headline is the topic's question; the card's own title becomes the setup line under it.
            Lead(headline: opener ? topic.title : (card.title ?? ""), setup: opener ? card.title : nil, opener: opener)
            VisualPanel(visual: card.visual, active: isActive)
                .padding(.horizontal, 16).padding(.top, 14)
                .frame(maxHeight: .infinity)
            paragraph
                .padding(.horizontal, 20).padding(.top, 30).padding(.bottom, 14)   // room for the cue pill that straddles the picture's bottom edge
        }
    }

    private var paragraph: some View {
        var t = Text(card.text ?? "")
        if let take = card.takeaway { t = t + Text(" ") + Text(take).fontWeight(.semibold) }
        return t.font(T.serif(17)).lineSpacing(5).foregroundStyle(T.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Unscored guess: tap an option and the right one is underlined, the others dim, the reason and the picture appear.
struct GuessCard: View {
    let card: Card
    let isActive: Bool
    @State private var picked = false

    var body: some View {
        VStack(spacing: 0) {
            Lead(headline: card.title ?? "")
            if let v = card.visual {
                ZStack {
                    VisualPanel(visual: v, active: isActive && picked).opacity(picked ? 1 : 0)
                    if !picked {
                        RoundedRectangle(cornerRadius: 2).fill(T.panel).overlay(RoundedRectangle(cornerRadius: 2).stroke(T.rule, lineWidth: 1))
                        Text("Pick an answer to see it").monoLabel().foregroundStyle(T.ink2)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 14).frame(maxHeight: .infinity)
            }
            VStack(spacing: 0) {
                ForEach(Array((card.options ?? []).enumerated()), id: \.offset) { i, o in
                    Button { withAnimation(.easeInOut(duration: 0.5)) { picked = true } } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(o).font(T.serif(17)).foregroundStyle(T.ink)
                                .underline(picked && i == card.answer, color: T.accent)
                            Spacer()
                            Text("This one").monoLabel().foregroundStyle(T.accent).opacity(picked && i == card.answer ? 1 : 0)
                        }
                        .padding(.vertical, 12)
                        .overlay(alignment: .top) { Rectangle().fill(T.rule).frame(height: 1) }
                        .opacity(picked && i != card.answer ? 0.4 : 1)
                    }
                    .buttonStyle(.plain).disabled(picked)
                }
                Rectangle().fill(T.rule).frame(height: 1)
                Text(card.why ?? "").font(T.serif(17)).lineSpacing(5).foregroundStyle(T.ink)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)
                    .opacity(picked ? 1 : 0)
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)
            if card.visual == nil { Spacer(minLength: 0) }
        }
    }
}

/// Last card: "Go deeper" rows for related topics.
struct MoreCard: View {
    @Environment(Store.self) private var store
    let topic: Topic
    let card: Card
    let jump: (String) -> Void

    var body: some View {
        let rows = store.related(to: topic, links: card.links ?? [])
        VStack(alignment: .leading, spacing: 0) {
            Text("Go deeper").font(T.serif(26, .medium)).foregroundStyle(T.ink)
            if let n = card.note { Text(n).font(T.serif(17)).lineSpacing(5).foregroundStyle(T.ink2).padding(.top, 10) }
            VStack(spacing: 0) {
                ForEach(rows) { t in
                    Button { jump(t.id) } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text(t.title).font(T.serif(20, .medium)).foregroundStyle(T.ink).multilineTextAlignment(.leading)
                            Spacer(minLength: 6)
                            Text("\(t.cards.count) cards →").monoLabel().foregroundStyle(T.ink2)
                        }
                        .padding(.vertical, 14)
                        .overlay(alignment: .top) { Rectangle().fill(T.rule).frame(height: 1) }
                    }
                    .buttonStyle(.plain)
                }
                Rectangle().fill(T.rule).frame(height: 1)
            }
            .padding(.top, 18)
            Spacer(minLength: 0)
            Text("Swipe up for something new").monoLabel().foregroundStyle(T.ink2).frame(maxWidth: .infinity).padding(.bottom, 6)
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 8)
    }
}
