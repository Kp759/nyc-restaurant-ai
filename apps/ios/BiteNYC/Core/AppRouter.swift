import SwiftUI

/// App-level navigation state shared across tabs. Lets the Home hero hand a
/// natural-language prompt to the conversational Chat tab.
@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable { case home, explore, chat, saved }

    @Published var selectedTab: Tab = .home
    @Published var pendingChatPrompt: String?

    /// Switch to the Chat tab and queue a prompt for it to send.
    func askInChat(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pendingChatPrompt = trimmed
        selectedTab = .chat
    }
}
