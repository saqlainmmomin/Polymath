import Foundation

/// topics.json, written by tools/export-topics.mjs from topics/*.js.
struct Library: Decodable { let topics: [Topic] }

struct Topic: Decodable, Identifiable {
    let id: String
    let title: String      // the topic's question
    let kind: String
    let theme: String
    let cards: [Card]
    var contentCardCount: Int { cards.filter { $0.type != "more" }.count }
}

/// One struct for every card type ("card", "guess", "more"); fields not used by a type are nil.
struct Card: Decodable {
    let type: String
    let title: String?
    let text: String?
    let takeaway: String?
    let options: [String]?
    let answer: Int?
    let why: String?
    let links: [String]?
    let note: String?
    let visual: Visual?
}

/// Wireframe view of a picture: what it is, what it would say on screen, and its interaction cue.
/// The full spec stays in topics.json for the native renderers that come later.
struct Visual: Decodable {
    let type: String
    let tip: String?
    let notes: [String]    // step notes, in order
    let labels: [String]   // on-picture labels

    private enum K: String, CodingKey { case type, tip, steps, parts, labels }
    private struct Step: Decodable { let note: String? }
    private struct Part: Decodable { let label: String?; let text: String? }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        type = try c.decode(String.self, forKey: .type)
        tip = try c.decodeIfPresent(String.self, forKey: .tip)
        // `parts` is a list for diagrams but a Bool for crank, `labels` a dictionary or false: decode leniently.
        notes = ((try? c.decode([Step].self, forKey: .steps)) ?? []).compactMap(\.note)
        var ls = ((try? c.decode([Part].self, forKey: .parts)) ?? []).compactMap { $0.label ?? $0.text }
        if let d = try? c.decode([String: String].self, forKey: .labels) { ls += d.keys.sorted().compactMap { d[$0] } }
        labels = ls
    }
}
