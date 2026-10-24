import SwiftUI

/// The real Polymath feed (compiled from ../Polymath) with the GPS pictures swapped for RealityKit scenes.
@main
struct PolymathSpikeApp: App {
    @State private var store = Store()
    @State private var session = Session()

    init() {
        PictureHook.make = { topic, index, active in
            guard topic.id == "gps", index < 4 else { return nil }
            return AnyView(GPSPicture(mode: index, active: active))
        }
    }

    var body: some Scene {
        WindowGroup { FeedView().environment(store).environment(session) }
    }
}
