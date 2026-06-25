import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "sparkles") }
                .tag(AppRouter.Tab.home)

            ExploreView()
                .tabItem { Label("Explore", systemImage: "map") }
                .tag(AppRouter.Tab.explore)

            ChatView()
                .tabItem { Label("Ask AI", systemImage: "bubble.left.and.text.bubble.right") }
                .tag(AppRouter.Tab.chat)

            AccountView()
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(AppRouter.Tab.account)
        }
        .sheet(item: $router.reservationTarget) { restaurant in
            ReserveSheet(restaurant: restaurant)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SavedListsStore())
        .environmentObject(AppRouter())
        .environmentObject(AccountStore())
        .preferredColorScheme(.dark)
}
