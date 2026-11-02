import Foundation

/// One topic, read from Topics/<id>.json in the app bundle. Those files are the source of truth for every topic's words.
struct Topic: Decodable, Identifiable {
    let id: String
    let title: String      // the topic's question
    let kind: String
    let theme: String
    let style: TopicStyle?   // see TopicStyle; read through `look`
    let cards: [Card]
    var contentCardCount: Int { cards.filter { $0.type != "more" }.count }
}

/// One struct for every card type ("card", "guess", "bridge", "more"); fields not used by a type are nil.
struct Card: Decodable {
    let type: String
    let title: String?
    let text: String?
    let takeaway: String?
    let hook: String?        // last line, set apart in bold so the pull to the next card is easy to find
    let marks: [String]?     // words coloured T.mark, the same colour as that thing in the picture
    let options: [String]?
    let answer: Int?
    let why: String?
    let links: [String]?
    let note: String?
    let visual: Visual?
}

/// A short description of a card's picture, for cards without a native picture: what it is, its step notes and labels, and its interaction cue.
struct Visual: Decodable {
    let type: String
    let tip: String?
    let notes: [String]    // step notes, in order
    let labels: [String]   // on-picture labels

    private enum K: String, CodingKey { case type, tip, notes, labels }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        type = try c.decode(String.self, forKey: .type)
        tip = try c.decodeIfPresent(String.self, forKey: .tip)
        notes = try c.decodeIfPresent([String].self, forKey: .notes) ?? []
        labels = try c.decodeIfPresent([String].self, forKey: .labels) ?? []
    }
}
