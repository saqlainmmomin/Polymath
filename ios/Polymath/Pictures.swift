import SwiftUI

/// Real animated pictures, by topic and card index. Anything not listed here falls back to the wireframe VisualPanel.
enum Pictures {
    static func view(topic: Topic, index: Int, active: Bool) -> AnyView? {
        if topic.id == "shazam" {
            switch index {
            case 0: return AnyView(ShazamListen(active: active))
            case 1: return AnyView(ShazamDraw(active: active))
            case 2: return AnyView(ShazamPair(active: active))
            case 3: return AnyView(ShazamIndex(active: active))
            case 4: return AnyView(ShazamMatch(active: active))
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
        if topic.id == "sky-blue" {
            switch index {
            case 0: return AnyView(SkyTwo(active: active))
            case 1: return AnyView(SkyColours(active: active))
            case 2: return AnyView(SkyBounce(active: active))
            case 3: return AnyView(SkyEverywhere(active: active))
            case 4: return AnyView(SkySunset(active: active))
            default: return nil
            }
        }
        if topic.id == "card-payment" {
            switch index {
            case 0: return AnyView(PayTap(active: active))
            case 1: return AnyView(PayHops(active: active))
            case 2: return AnyView(PayNetwork(active: active))
            case 3: return AnyView(PayDecide(active: active))
            case 4: return AnyView(PayLater(active: active))
            default: return nil
            }
        }
        if topic.id == "bike-gears" {
            switch index {
            case 0: return AnyView(BikeHill(active: active))
            case 1: return AnyView(BikeRings(active: active))
            case 2: return AnyView(BikeCount(active: active))
            case 3: return AnyView(BikeSteps(active: active))
            case 4: return AnyView(BikeRoads(active: active))
            default: return nil
            }
        }
        if topic.id == "feel-wet" {
            switch index {
            case 0: return AnyView(WetNoSensor(active: active))
            case 1: return AnyView(WetCooling(active: active))
            case 2: return AnyView(WetGuess(active: active))
            case 3: return AnyView(WetBag(active: active))
            default: return nil
            }
        }
        if topic.id == "birthday" {
            switch index {
            case 0: return AnyView(BirthRoom(active: active))
            case 1: return AnyView(BirthYours(active: active))
            case 2: return AnyView(BirthPairs(active: active))
            case 3: return AnyView(BirthRooms(active: active))
            case 4: return AnyView(BirthCurve(active: active))
            default: return nil
            }
        }
        if topic.id == "seasons" {
            switch index {
            case 0: return AnyView(SeasonsFar(active: active))
            case 1: return AnyView(SeasonsSteps(active: active))
            case 2: return AnyView(SeasonsLean(active: active))
            case 3: return AnyView(SeasonsTorch(active: active))
            case 4: return AnyView(SeasonsDay(active: active))
            default: return nil
            }
        }
        if topic.id == "superglue" {
            switch index {
            case 0: return AnyView(GlueTube(active: active))
            case 1: return AnyView(GlueTwo(active: active))
            case 2: return AnyView(GlueFilm(active: active))
            case 3: return AnyView(GlueCap(active: active))
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
