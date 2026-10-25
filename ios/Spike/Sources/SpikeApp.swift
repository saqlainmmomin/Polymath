import SwiftUI

/// The real Polymath feed (compiled from ../Polymath) with the GPS pictures swapped for RealityKit scenes.
@main
struct PolymathSpikeApp: App {
    @State private var store = Store()
    @State private var session = Session()

    private let meter = FrameMeter()

    init() {
        if ProcessInfo.processInfo.arguments.contains("--fps") { meter.start(label: ProcessInfo.processInfo.arguments.contains("--rk") ? "rk" : "flat") }
        PictureHook.make = { topic, index, active in
            guard topic.id == "gps", index < 5 else { return nil }
            // Cards 1-5 are the flat 2D pictures unless launched with --rk (the RealityKit versions, for comparison).
            if !ProcessInfo.processInfo.arguments.contains("--rk") {
                switch index {
                case 0: return AnyView(FlatBroadcast(active: active))
                case 1: return AnyView(FlatStorm(active: active))
                case 2: return AnyView(FlatDelay(active: active))
                case 3: return AnyView(FlatRing(active: active))
                default: return AnyView(FlatMeet(active: active))
                }
            }
            return AnyView(GPSPicture(mode: index, active: active))
        }
    }

    var body: some Scene {
        WindowGroup { FeedView().environment(store).environment(session) }
    }
}
