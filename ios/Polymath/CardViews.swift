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
        case "bridge": BridgeCard(card: card)
        default: StandardCard(topic: topic, card: card, index: index, opener: index == 0, isActive: isActive)
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
                .font(S.rounded(24, .bold)).lineSpacing(2)
                .foregroundStyle(S.text)
                .fixedSize(horizontal: false, vertical: true)
            if let setup {
                Text(setup).font(S.rounded(16, .medium)).foregroundStyle(S.text2).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 21)
        .padding(.top, 4)
    }
}

struct StandardCard: View {
    let topic: Topic
    let card: Card
    let index: Int
    let opener: Bool
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Card 1's headline is the topic's question; the card's own title becomes the setup line under it.
            // Text first, then the picture: the reader gets the idea before they watch or touch it.
            Lead(headline: opener ? topic.title : (card.title ?? ""), setup: opener ? card.title : nil, opener: opener)
            paragraph
                .padding(.horizontal, 21).padding(.top, 12)
            Group {
                if let custom = Pictures.view(topic: topic, index: index, active: isActive) { custom } else { VisualPanel(visual: card.visual, active: isActive) }
            }
                .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 24)   // room for the cue pill that straddles the picture's bottom edge
                .frame(maxHeight: .infinity)
        }
    }

    private var paragraph: some View {
        var t = Text(card.text ?? "")
        if let take = card.takeaway { t = t + Text(" ") + Text(take).fontWeight(.semibold) }
        return t.font(S.rounded(16)).lineSpacing(5).foregroundStyle(S.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A text-only pause between two cards: closes one idea and sets up the next. No headline, no picture.
struct BridgeCard: View {
    let card: Card
    var body: some View {
        Text(card.text ?? "")
            .font(S.rounded(24)).lineSpacing(7).tracking(-0.2).foregroundStyle(S.text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
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
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(S.veil)
                        Text("Pick an answer to see it").font(S.rounded(13, .medium)).foregroundStyle(S.text2)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 14).frame(maxHeight: .infinity)
            }
            VStack(spacing: 0) {
                ForEach(Array((card.options ?? []).enumerated()), id: \.offset) { i, o in
                    Button { withAnimation(.easeInOut(duration: 0.5)) { picked = true } } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(o).font(S.rounded(17)).foregroundStyle(S.text)
                                .underline(picked && i == card.answer, color: T.accent)
                            Spacer()
                            Text("This one").font(S.rounded(13, .medium)).foregroundStyle(T.accent).opacity(picked && i == card.answer ? 1 : 0)
                        }
                        .padding(.vertical, 12)
                        .overlay(alignment: .top) { Rectangle().fill(S.line).frame(height: 1) }
                        .opacity(picked && i != card.answer ? 0.4 : 1)
                    }
                    .buttonStyle(.plain).disabled(picked)
                }
                Rectangle().fill(S.line).frame(height: 1)
                Text(card.why ?? "").font(S.rounded(17)).lineSpacing(5).foregroundStyle(S.text)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)
                    .opacity(picked ? 1 : 0)
            }
            .padding(.horizontal, 21).padding(.top, 20).padding(.bottom, 14)
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
            Text("Go deeper").font(S.rounded(26, .medium)).foregroundStyle(S.text)
            if let n = card.note { Text(n).font(S.rounded(17)).lineSpacing(5).foregroundStyle(S.text2).padding(.top, 10) }
            VStack(spacing: 0) {
                ForEach(rows) { t in
                    Button { jump(t.id) } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text(t.title).font(S.rounded(20, .medium)).foregroundStyle(S.text).multilineTextAlignment(.leading)
                            Spacer(minLength: 6)
                            Text("\(t.cards.count) cards →").font(S.rounded(13, .medium)).foregroundStyle(S.text2)
                        }
                        .padding(.vertical, 14)
                        .overlay(alignment: .top) { Rectangle().fill(S.line).frame(height: 1) }
                    }
                    .buttonStyle(.plain)
                }
                Rectangle().fill(S.line).frame(height: 1)
            }
            .padding(.top, 18)
            Spacer(minLength: 0)
            Text("Swipe up for something new").font(S.rounded(13, .medium)).foregroundStyle(S.text2).frame(maxWidth: .infinity).padding(.bottom, 6)
        }
        .padding(.horizontal, 21).padding(.top, 24).padding(.bottom, 8)
    }
}
