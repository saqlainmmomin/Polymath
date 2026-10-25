import SwiftUI

/// Real animated pictures, by topic and card index. Anything not listed here falls back to the wireframe VisualPanel.
enum Pictures {
    static func view(topic: Topic, index: Int, active: Bool) -> AnyView? {
        guard topic.id == "gps" else { return nil }
        switch index {
        case 0: return AnyView(FlatBroadcast(active: active))
        case 1: return AnyView(FlatStorm(active: active))
        case 2: return AnyView(FlatDelay(active: active))
        case 3: return AnyView(FlatRing(active: active))
        case 4: return AnyView(FlatMeet(active: active))
        default: return nil
        }
    }
}
