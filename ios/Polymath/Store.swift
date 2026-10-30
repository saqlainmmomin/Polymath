import SwiftUI
import Observation

/// Launch arguments for headless screenshots: `--topic <id>` puts a topic first, `--card <n>` opens card n (1-based) of it, `--index` opens the Index sheet.
enum Launch {
    private static func value(_ flag: String) -> String? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: flag), i + 1 < a.count else { return nil }
        return a[i + 1]
    }
    static var topic: String? { value("--topic") }
    static var card: Int? { value("--card").flatMap(Int.init).map { max(0, $0 - 1) } }
    static var showIndex: Bool { ProcessInfo.processInfo.arguments.contains("--index") }
}

/// Per-launch state shared by all pictures: once the reader has touched any picture, the cue pill stays away.
@Observable final class Session { var learned = false }

@Observable final class Store {
    let topics: [Topic]
    private let shades: [String: Int]

    init() {
        let url = Bundle.main.url(forResource: "topics", withExtension: "json")!
        var all = (try! JSONDecoder().decode(Library.self, from: Data(contentsOf: url))).topics.shuffled()
        if let first = Launch.topic, let i = all.firstIndex(where: { $0.id == first }) { all.insert(all.remove(at: i), at: 0) }
        topics = all
        // Each topic keeps one gradient across launches (sorted by id, not by the shuffled order); all differ while there are fewer topics than gradients.
        shades = Dictionary(uniqueKeysWithValues: all.map(\.id).sorted().enumerated().map { ($1, $0) })
    }

    /// Every topic sits on blueprint paper. The per-topic gradients (`shades`) are kept for now but unused.
    func shade(_ t: Topic) -> Int { S.paper }
    /// Topics drawn on blueprint paper (a flat colour with a grid) instead of a gradient.
    func isPaper(_ t: Topic) -> Bool { shade(t) == S.paper }

    func topic(_ id: String) -> Topic? { topics.first { $0.id == id } }

    /// Links for a `more` card: the listed topics that exist, else up to 3 others (same theme first).
    func related(to t: Topic, links: [String]) -> [Topic] {
        let listed = links.compactMap(topic).filter { $0.id != t.id }
        if !listed.isEmpty { return listed }
        let rest = topics.filter { $0.id != t.id }
        return Array((rest.filter { $0.theme == t.theme } + rest.filter { $0.theme != t.theme }).prefix(3))
    }
}
