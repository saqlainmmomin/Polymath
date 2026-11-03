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
    /// `--preview` shows a topic without a narration as its picture alone, laid out like the Narrated screen (see PicturePreview).
    static var preview: Bool { ProcessInfo.processInfo.arguments.contains("--preview") }
}

/// Per-launch state shared by all pictures: once the reader has touched any picture, the cue pill stays away.
@Observable final class Session { var learned = false }

@Observable final class Store {
    let topics: [Topic]

    init() {
        // Every Topics/<id>.json in the bundle that has a narration is a topic in the feed (owner, 2026-11-03: Narrated only).
        // Topics without one stay in the bundle, hidden, until they are narrated.
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Topics") ?? []
        var all = urls.map { try! JSONDecoder().decode(Topic.self, from: Data(contentsOf: $0)) }
            .filter { Narration.load($0.id) != nil || $0.id == Launch.topic }.shuffled()   // `--topic <id>` previews a topic that has no narration yet, as Cards
        if let first = Launch.topic, let i = all.firstIndex(where: { $0.id == first }) { all.insert(all.remove(at: i), at: 0) }
        topics = all
    }

    func topic(_ id: String) -> Topic? { topics.first { $0.id == id } }

    /// Links for a `more` card: the listed topics that exist, else up to 3 others (same theme first).
    func related(to t: Topic, links: [String]) -> [Topic] {
        let listed = links.compactMap(topic).filter { $0.id != t.id }
        if !listed.isEmpty { return listed }
        let rest = topics.filter { $0.id != t.id }
        return Array((rest.filter { $0.theme == t.theme } + rest.filter { $0.theme != t.theme }).prefix(3))
    }
}
