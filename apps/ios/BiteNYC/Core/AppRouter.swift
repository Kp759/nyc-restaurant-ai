import SwiftUI

/// App-level navigation state shared across tabs. Lets the Home hero hand a
/// natural-language prompt to the conversational Chat tab.
@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable { case home, explore, chat, saved, account }

    @Published var selectedTab: Tab = .home
    @Published var pendingChatPrompt: String?

    /// When set, the app presents the reservation sheet for this restaurant.
    @Published var reservationTarget: Restaurant?

    /// Switch to the Chat tab and queue a prompt for it to send.
    func askInChat(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pendingChatPrompt = trimmed
        selectedTab = .chat
    }

    /// Present the reservation flow for a restaurant from anywhere in the app.
    func reserve(_ restaurant: Restaurant) {
        reservationTarget = restaurant
    }
}
