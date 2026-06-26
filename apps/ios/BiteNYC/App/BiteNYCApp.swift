import SwiftUI

@main
struct BiteNYCApp: App {
    @StateObject private var savedStore = SavedListsStore()
    @StateObject private var accountStore = AccountStore()
    @StateObject private var authStore = AuthStore()
    @StateObject private var router = AppRouter()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authStore.canEnterApp {
                    RootView()
                        .environmentObject(savedStore)
                        .environmentObject(accountStore)
                        .environmentObject(authStore)
                        .environmentObject(router)
                        .tint(Theme.accent)
                        .transition(.opacity)
                } else if !showSplash {
                    AuthView()
                        .environmentObject(authStore)
                        .environmentObject(accountStore)
                        .transition(.opacity)
                }

                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: authStore.canEnterApp)
            .animation(.easeInOut(duration: 0.35), value: showSplash)
            .preferredColorScheme(.dark)
            .onOpenURL { authStore.handleOpenURL($0) }
        }
    }
}
