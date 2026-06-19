import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "sparkles") }

            ExploreView()
                .tabItem { Label("Explore", systemImage: "map") }

            ChatView()
                .tabItem { Label("Ask AI", systemImage: "bubble.left.and.text.bubble.right") }

            SavedListsView()
                .tabItem { Label("Saved", systemImage: "bookmark") }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SavedListsStore())
        .preferredColorScheme(.dark)
}
