import Foundation
import Combine

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let role: String   // "user" | "assistant"
    var text: String
    var results: [SearchResult] = []
    var isError = false
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input = ""
    @Published var isSending = false

    let starters = [
        "Best first-date spots in the West Village?",
        "Cozy aesthetic cafes in SoHo?",
        "Best omakase under $150?",
        "Rooftop dinner for a birthday?",
    ]

    func send(_ textOverride: String? = nil) async {
        let text = (textOverride ?? input).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        messages.append(ChatMessage(role: "user", text: text))
        input = ""
        isSending = true

        let history = messages
            .filter { !$0.isError }
            .dropLast()
            .map { ChatTurn(role: $0.role, content: $0.text) }

        do {
            let response = try await APIClient.shared.chat(message: text, history: Array(history))
            messages.append(ChatMessage(role: "assistant", text: response.reply, results: response.results))
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? error.localizedDescription
            messages.append(ChatMessage(role: "assistant", text: msg, isError: true))
        }
        isSending = false
    }
}
