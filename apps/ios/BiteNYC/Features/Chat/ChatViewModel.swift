import Foundation
import Combine

struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let role: String   // "user" | "assistant"
    var text: String
    var results: [SearchResult] = []
    /// How many result cards are visible during the reveal animation.
    var visibleResultCount: Int = 0
    var isError = false
    var isStreaming = false

    init(
        id: UUID = UUID(),
        role: String,
        text: String,
        results: [SearchResult] = [],
        visibleResultCount: Int? = nil,
        isError: Bool = false,
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.results = results
        self.visibleResultCount = visibleResultCount ?? results.count
        self.isError = isError
        self.isStreaming = isStreaming
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input = ""
    @Published var isSending = false

    /// Newest conversation turns appear first in the UI.
    var latestTurnID: UUID? { messages.first?.id }

    var newestAssistant: ChatMessage? {
        guard messages.count > 1, messages[1].role == "assistant" else { return nil }
        return messages[1]
    }

    private var revealTask: Task<Void, Never>?

    let starters = [
        "Best first-date spots in the West Village?",
        "Cozy aesthetic cafes in SoHo?",
        "Best omakase under $150?",
        "Rooftop dinner for a birthday?",
    ]

    func send(_ textOverride: String? = nil) async {
        let text = (textOverride ?? input).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        revealTask?.cancel()
        messages.insert(ChatMessage(role: "user", text: text), at: 0)
        input = ""
        isSending = true

        let history = chronologicalHistory(excludingLatestUser: true)

        do {
            let response = try await APIClient.shared.chat(message: text, history: history)
            isSending = false
            await revealAssistantResponse(text: response.reply, results: response.results)
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? error.localizedDescription
            messages.insert(ChatMessage(role: "assistant", text: msg, isError: true), at: 1)
            isSending = false
        }
    }

    /// Gradually reveals the assistant reply word-by-word, then staggers cards.
    private func revealAssistantResponse(text: String, results: [SearchResult]) async {
        let messageID = UUID()
        messages.insert(
            ChatMessage(
                id: messageID,
                role: "assistant",
                text: "",
                results: results,
                visibleResultCount: 0,
                isStreaming: true
            ),
            at: 1
        )

        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        var built = ""
        for (index, word) in words.enumerated() {
            if Task.isCancelled { return }
            if index > 0 { built += " " }
            built += word
            if index % 2 == 0 || index == words.count - 1 {
                updateMessage(messageID) { $0.text = built }
            }
            try? await Task.sleep(nanoseconds: 45_000_000)
        }
        updateMessage(messageID) { $0.text = text; $0.isStreaming = false }

        for count in 1...results.count {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 450_000_000)
            updateMessage(messageID) { $0.visibleResultCount = count }
        }
    }

    private func chronologicalHistory(excludingLatestUser: Bool) -> [ChatTurn] {
        let slice = excludingLatestUser ? messages.dropFirst() : messages[...]
        return slice
            .reversed()
            .filter { !$0.isError && !$0.isStreaming }
            .map { ChatTurn(role: $0.role, content: $0.text) }
    }

    private func updateMessage(_ id: UUID, mutate: (inout ChatMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        mutate(&messages[index])
    }
}
