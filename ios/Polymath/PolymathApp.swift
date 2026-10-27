import SwiftUI

@main
struct PolymathApp: App {
    @State private var store = Store()
    @State private var session = Session()
    @State private var profile = Profile()
    @State private var shelf = Shelf()

    var body: some Scene {
        WindowGroup {
            Group {
                if profile.onboarded { FeedView() } else { OnboardingView() }
            }
            .environment(store)
            .environment(session)
            .environment(profile)
            .environment(shelf)
        }
    }
}
