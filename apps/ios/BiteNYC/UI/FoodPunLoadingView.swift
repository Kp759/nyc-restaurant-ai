import SwiftUI
import Combine

struct LoadingQuote: Identifiable, Hashable {
    let id: String
    let emoji: String
    let text: String
}

enum LoadingQuotes {
    static let general: [LoadingQuote] = [
        LoadingQuote(id: "g1", emoji: "🍕", text: "Good things rise like dough — almost ready…"),
        LoadingQuote(id: "g2", emoji: "🥟", text: "Steaming up something tasty for you…"),
        LoadingQuote(id: "g3", emoji: "🍜", text: "Slurping up the best NYC picks…"),
        LoadingQuote(id: "g4", emoji: "🥂", text: "Setting the table — this'll be good…"),
        LoadingQuote(id: "g5", emoji: "🌮", text: "Seasoning the results with love…"),
        LoadingQuote(id: "g6", emoji: "☕️", text: "Brewing something warm and wonderful…"),
    ]

    static let search: [LoadingQuote] = [
        LoadingQuote(id: "s1", emoji: "🔍", text: "Hunting for your perfect bite…"),
        LoadingQuote(id: "s2", emoji: "🗽", text: "Scanning the city one delicious block at a time…"),
        LoadingQuote(id: "s3", emoji: "✨", text: "Finding spots that match your vibe…"),
        LoadingQuote(id: "s4", emoji: "🍽️", text: "Curating only the good stuff — promise…"),
    ]

    static let detail: [LoadingQuote] = [
        LoadingQuote(id: "d1", emoji: "📋", text: "Pulling up the menu and the vibes…"),
        LoadingQuote(id: "d2", emoji: "📸", text: "Framing the photos and the must-try dishes…"),
        LoadingQuote(id: "d3", emoji: "⭐", text: "Gathering the details worth knowing…"),
    ]

    static let chat: [LoadingQuote] = [
        LoadingQuote(id: "c1", emoji: "🧠", text: "Thinking with my taste buds…"),
        LoadingQuote(id: "c2", emoji: "🍷", text: "Pairing your mood with the perfect spot…"),
        LoadingQuote(id: "c3", emoji: "💡", text: "Cooking up a recommendation…"),
    ]

    static let auth: [LoadingQuote] = [
        LoadingQuote(id: "a1", emoji: "🪑", text: "Saving your seat at the table…"),
        LoadingQuote(id: "a2", emoji: "🎉", text: "Welcome to the good-food club…"),
        LoadingQuote(id: "a3", emoji: "🥡", text: "Getting your NYC passport ready…"),
    ]

    static let image: [LoadingQuote] = [
        LoadingQuote(id: "i1", emoji: "📷", text: "Plating the photo…"),
        LoadingQuote(id: "i2", emoji: "🍰", text: "Almost ready to serve…"),
    ]
}

/// Friendly rotating food puns instead of a bare spinner.
struct FoodPunLoadingView: View {
    let quotes: [LoadingQuote]
    var minHeight: CGFloat = 240
    var rotateEvery: TimeInterval = 2.8

    @State private var index = 0
    @State private var emojiPulse = false
    private let timer = Timer.publish(every: 2.8, on: .main, in: .common).autoconnect()

    private var activeQuotes: [LoadingQuote] {
        quotes.isEmpty ? LoadingQuotes.general : quotes
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(activeQuotes[index].emoji)
                .font(.system(size: 54))
                .scaleEffect(emojiPulse ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: emojiPulse)

            Text(activeQuotes[index].text)
                .font(.display(.body, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .animation(.easeInOut(duration: 0.35), value: index)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .onAppear {
            emojiPulse = true
            index = Int.random(in: 0..<activeQuotes.count)
        }
        .onReceive(timer) { _ in
            guard activeQuotes.count > 1 else { return }
            withAnimation(.easeInOut) {
                index = (index + 1) % activeQuotes.count
            }
        }
    }
}

/// Compact inline loader for chat rows and thumbnails.
struct FoodPunInlineLoadingView: View {
    let quote: LoadingQuote

    var body: some View {
        HStack(spacing: 10) {
            Text(quote.emoji).font(.title3)
            Text(quote.text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
