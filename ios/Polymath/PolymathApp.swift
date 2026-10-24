import SwiftUI

@main
struct PolymathApp: App {
    @State private var store = Store()
    @State private var session = Session()

    var body: some Scene {
        WindowGroup {
            FeedView()
                .environment(store)
                .environment(session)
        }
    }
}
