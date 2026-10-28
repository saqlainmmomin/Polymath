import SwiftUI

/// Dispatches on card type. A card is the headline and paragraph at the top and, on the lower stage, a picture drawn straight onto the screen's gradient.
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
    @Environment(Store.self) private var store
    let topic: Topic
    let card: Card
    let index: Int
    let opener: Bool
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Card 1's headline is the topic's question; the card's own title becomes the setup line under it.
            // Text first, then the picture (owner, 2026-10-27): no panel, the whole screen is the canvas. The stage takes all the room
            // left under the text and the picture sits centred in it, as big as fits; pictures read their colours from the gradient (`\.stage`).
            Lead(headline: opener ? topic.title : (card.title ?? ""), setup: opener ? card.title : nil, opener: opener)
            paragraph
                .padding(.horizontal, 21).padding(.top, 12)
            Group {
                if let custom = Pictures.view(topic: topic, index: index, active: isActive) { custom } else { VisualPanel(visual: card.visual, active: isActive) }
            }
                .environment(\.stage, S.stage(store.shade(topic)))
                .frame(maxWidth: .infinity, minHeight: Self.stageMin, maxHeight: .infinity)
                .padding(.horizontal, 8).padding(.top, 8).padding(.bottom, Self.dotsClearance)
        }
    }

    /// The stage never shrinks below this, so a long card's picture stays readable.
    static let stageMin: CGFloat = 300
    /// Room kept free under the stage for the page dots and "Swipe".
    static let dotsClearance: CGFloat = 52

    private var paragraph: some View {
        var t = Text(marked(card.text ?? ""))
        if let take = card.takeaway { t = t + Text(" ") + Text(marked(take)).fontWeight(.semibold) }
        return VStack(alignment: .leading, spacing: 10) {
            t.font(S.rounded(16)).lineSpacing(5).foregroundStyle(S.text)
                .fixedSize(horizontal: false, vertical: true)
            if let hook = card.hook {
                Text(marked(hook)).font(S.rounded(16, .semibold)).lineSpacing(5).foregroundStyle(S.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Colours each whole-word, case-insensitive match of the card's `marks`.
    private func marked(_ s: String) -> AttributedString {
        var a = AttributedString(s)
        for w in card.marks ?? [] {
            var from = a.startIndex
            while let r = a[from...].range(of: w, options: .caseInsensitive) {
                let before = r.lowerBound == a.startIndex ? nil : a.characters[a.characters.index(before: r.lowerBound)]
                let after = r.upperBound == a.endIndex ? nil : a.characters[r.upperBound]
                if !(before?.isLetter ?? false) && !(after?.isLetter ?? false) { a[r].foregroundColor = T.mark; a[r].inlinePresentationIntent = .stronglyEmphasized }
                from = r.upperBound
            }
        }
        return a
    }
}

/// A text-only pause between two cards: closes one idea and sets up the next. No headline, no picture.
struct BridgeCard: View {
    let card: Card
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(card.text ?? "").font(S.rounded(24)).lineSpacing(7).tracking(-0.2)
            if let hook = card.hook { Text(hook).font(S.rounded(24, .semibold)).lineSpacing(7).tracking(-0.2) }
        }
            .foregroundStyle(S.text)
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
