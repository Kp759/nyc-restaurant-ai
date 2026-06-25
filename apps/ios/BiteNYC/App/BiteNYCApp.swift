import SwiftUI

@main
struct BiteNYCApp: App {
    @StateObject private var savedStore = SavedListsStore()
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(savedStore)
                .environmentObject(router)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
        }
    }
}
