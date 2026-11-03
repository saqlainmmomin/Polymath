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
        if topic.id == "car-engine" {
            switch index {
            case 0: return AnyView(CarStart(active: active))
            case 1: return AnyView(CarPiston(active: active))
            case 2: return AnyView(CarStrokes(active: active))
            case 3: return AnyView(CarDrag(active: active))
            case 4: return AnyView(CarFlywheel(active: active))
            default: return nil
            }
        }
        if topic.id == "moon-tides" {
            switch index {
            case 0: return AnyView(TidesBPBeach(active: active))
            case 1: return AnyView(TidesBPPull(active: active))
            case 2: return AnyView(TidesBPBulges(active: active))
            case 3: return AnyView(TidesBPTurn(active: active))
            case 4: return AnyView(TidesBPLater(active: active))
            default: return nil
            }
        }
        if topic.id == "sky-blue" {
            switch index {
            case 0: return AnyView(SkyBPSun(active: active))
            case 1: return AnyView(SkyBPWave(active: active))
            case 2: return AnyView(SkyBPAll(active: active))
            case 3: return AnyView(SkyBPSunset(active: active))
            default: return nil
            }
        }
        if topic.id == "card-payment" {
            switch index {
            case 0: return AnyView(PayBPTap(active: active))
            case 1: return AnyView(PayBPHops(active: active))
            case 2: return AnyView(PayBPPromise(active: active))
            case 3: return AnyView(PayBPTotals(active: active))
            default: return nil
            }
        }
        if topic.id == "bike-gears" {
            switch index {
            case 0: return AnyView(BikeBPHill(active: active))
            case 1: return AnyView(BikeBPRings(active: active))
            case 2: return AnyView(BikeBPCarry(active: active))
            case 3: return AnyView(BikeBPWalk(active: active))
            case 4: return AnyView(BikeBPFlat(active: active))
            default: return nil
            }
        }
        if topic.id == "feel-wet" {
            switch index {
            case 0: return AnyView(WetBPSensors(active: active))
            case 1: return AnyView(WetBPCold(active: active))
            case 2: return AnyView(WetBPTouch(active: active))
            case 3: return AnyView(WetBPSheath(active: active))
            default: return nil
            }
        }
        if topic.id == "birthday" {
            switch index {
            case 0: return AnyView(BirthBPRoom(active: active))
            case 1: return AnyView(BirthBPYours(active: active))
            case 2: return AnyView(BirthBPPairs(active: active))
            case 3: return AnyView(BirthBPRooms(active: active))
            case 4: return AnyView(BirthBPCurve(active: active))
            default: return nil
            }
        }
        if topic.id == "seasons" {
            switch index {
            case 0: return topic.look == .wireframe ? AnyView(SeasonsWFFar(active: active)) : AnyView(SeasonsBPFar(active: active))
            case 1: return topic.look == .wireframe ? AnyView(SeasonsWFSteps(active: active)) : AnyView(SeasonsBPSteps(active: active))
            case 2: return topic.look == .wireframe ? AnyView(SeasonsWFLean(active: active)) : AnyView(SeasonsBPLean(active: active))
            case 3: return topic.look == .wireframe ? AnyView(SeasonsWFTorch(active: active)) : AnyView(SeasonsBPTorch(active: active))
            case 4: return topic.look == .wireframe ? AnyView(SeasonsWFDay(active: active)) : AnyView(SeasonsBPDay(active: active))
            default: return nil
            }
        }
        if topic.id == "superglue" {
            switch index {
            case 0: return topic.look == .drafting ? AnyView(GlueDRFast(active: active)) : AnyView(GlueBPFast(active: active))
            case 1: return topic.look == .drafting ? AnyView(GlueDRWater(active: active)) : AnyView(GlueBPWater(active: active))
            case 2: return topic.look == .drafting ? AnyView(GlueDRFilm(active: active)) : AnyView(GlueBPFilm(active: active))
            case 3: return topic.look == .drafting ? AnyView(GlueDRCap(active: active)) : AnyView(GlueBPCap(active: active))
            default: return nil
            }
        }
        if topic.id == "afterimage" {
            switch index {
            case 0: return topic.look == .airbrush ? AnyView(AfterABSpot(active: active)) : AnyView(AfterBPSpot(active: active))
            case 1: return topic.look == .airbrush ? AnyView(AfterABEye(active: active)) : AnyView(AfterBPEye(active: active))
            case 2: return topic.look == .airbrush ? AnyView(AfterABCells(active: active)) : AnyView(AfterBPCells(active: active))
            case 3: return topic.look == .airbrush ? AnyView(AfterABTurn(active: active)) : AnyView(AfterBPTurn(active: active))
            default: return nil
            }
        }
        if topic.id == "own-voice" {
            switch index {
            case 0: return AnyView(VoiceBPTalk(active: active))
            case 1: return AnyView(VoiceBPRoutes(active: active))
            case 2: return AnyView(VoiceBPBands(active: active))
            case 3: return AnyView(VoiceBPMic(active: active))
            default: return nil
            }
        }
        guard topic.id == "gps" else { return nil }
        switch index {
        case 0: return AnyView(GpBPSilent(active: active))
        case 1: return AnyView(GpBPSend(active: active))
        case 2: return AnyView(GpBPGap(active: active))
        case 3: return AnyView(GpBPSpots(active: active))
        case 4: return AnyView(GpBPClock(active: active))
        default: return nil
        }
    }
}
