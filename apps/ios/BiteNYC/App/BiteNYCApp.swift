import SwiftUI

@main
struct BiteNYCApp: App {
    @StateObject private var savedStore = SavedListsStore()
    @StateObject private var router = AppRouter()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(savedStore)
                    .environmentObject(router)
                    .tint(Theme.accent)

                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
