import SwiftUI

@main
struct BiteNYCApp: App {
    @StateObject private var savedStore = SavedListsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(savedStore)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
        }
    }
}
