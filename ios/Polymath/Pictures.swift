import SwiftUI

/// Real animated pictures, by topic and card index. Anything not listed here falls back to the wireframe VisualPanel.
enum Pictures {
    static func view(topic: Topic, index: Int, active: Bool) -> AnyView? {
        if topic.id == "shazam" {
            switch index {
            case 0: return AnyView(ShazamHear(active: active))
            case 1: return AnyView(ShazamStack(active: active))
            case 2: return AnyView(ShazamClip(active: active))
            case 3: return AnyView(ShazamPeaks(active: active))
            case 5: return AnyView(ShazamPairs(active: active))   // card 4 is a text-only bridge
            case 6: return AnyView(ShazamLookup(active: active))
            default: return nil
            }
        }
        if topic.id == "moon-tides" {
            switch index {
            case 0: return AnyView(TidesBeach(active: active))
            case 1: return AnyView(TidesPull(active: active))
            case 2: return AnyView(TidesTwo(active: active))
            case 3: return AnyView(TidesSpin(active: active))
            case 5: return AnyView(TidesSun(active: active))      // card 4 is a text-only bridge
            case 6: return AnyView(TidesCoast(active: active))
            default: return nil
            }
        }
        guard topic.id == "gps" else { return nil }
        switch index {
        case 0: return AnyView(FlatBlueDot(active: active))
        case 1: return AnyView(FlatBroadcast(active: active))
        case 2: return AnyView(FlatStorm(active: active))
        case 3: return AnyView(FlatDelay(active: active))
        case 4: return AnyView(FlatRing(active: active))
        case 5: return AnyView(FlatMeet(active: active))
        default: return nil
        }
    }
}
