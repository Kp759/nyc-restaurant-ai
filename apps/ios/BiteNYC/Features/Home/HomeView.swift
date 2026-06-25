import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var queryText = ""
    @State private var vibeCategories: [VibeCategory] = []
    @State private var path = NavigationPath()
    @State private var exampleIndex = 0
    @State private var showAllVibes = false
    @FocusState private var askFocused: Bool

    private let vibePreviewCount = 4

    private let examples = [
        "Cozy date-night spot in the West Village…",
        "Aesthetic cafe to work from in SoHo…",
        "Rooftop for a birthday with great cocktails…",
        "Best omakase under $150…",
        "Late-night noodles in the East Village…",
        "Where should I take someone visiting NYC?",
    ]
    private let rotation = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    askHero
                    promptChips
                    vibeCategoriesSection
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationDestination(for: SearchRoute.self) { route in
                SearchResultsView(query: route.query)
            }
            .navigationDestination(for: RestaurantRoute.self) { route in
                RestaurantDetailView(slug: route.slug)
            }
            .task { await loadVibeCategories() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bite").font(.display(.largeTitle, weight: .heavy))
                + Text("NYC").font(.display(.largeTitle, weight: .heavy)).foregroundColor(Theme.accent)
            Text("Your AI dining concierge for New York City")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var askGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.accent, Color(red: 0.96, green: 0.18, blue: 0.55)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var askHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(askGradient)
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.bold)).foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                .shadow(color: Theme.accent.opacity(0.4), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask BiteNYC").font(.display(.title2, weight: .bold))
                    Text("Your AI dining concierge")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(alignment: .top, spacing: 12) {
                TextField(
                    "Ask anything",
                    text: $queryText,
                    prompt: Text(examples[exampleIndex]).foregroundColor(.secondary),
                    axis: .vertical
                )
                .font(.title3)
                .lineLimit(2...6)
                .focused($askFocused)
                .submitLabel(.search)
                .onSubmit(submit)
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(askGradient)
                }
                .disabled(queryText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(askGradient, lineWidth: 2)
            )

            Button(action: submit) {
                Label("Ask BiteNYC", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(askGradient)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 4)
            }
            .opacity(queryText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1)
            .disabled(queryText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.22), Color(red: 0.96, green: 0.18, blue: 0.55).opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                Image(systemName: "fork.knife")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundStyle(.white.opacity(0.05))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: 20, y: 16)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24).stroke(askGradient.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onReceive(rotation) { _ in
            guard queryText.isEmpty, !askFocused else { return }
            withAnimation(.easeInOut) { exampleIndex = (exampleIndex + 1) % examples.count }
        }
    }

    private var promptChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick ideas").sectionHeaderStyle()
            FlowLayout(spacing: 8) {
                ForEach(HomePrompts.chips, id: \.label) { chip in
                    NavigationLink(value: SearchRoute(query: chip.label)) {
                        QuickIdeaChip(label: chip.label, emoji: ideaEmoji(chip.label))
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
        }
    }

    private func ideaEmoji(_ label: String) -> String {
        switch label.lowercased() {
        case "date night": return "💕"
        case "cozy cafe": return "☕️"
        case "birthday dinner": return "🎂"
        case "rooftop": return "🌆"
        case "walk-in friendly": return "🚶"
        case "best pizza": return "🍕"
        case "best ramen": return "🍜"
        case "under $50": return "💵"
        case "open late": return "🌙"
        default: return "✨"
        }
    }

    @ViewBuilder
    private var vibeCategoriesSection: some View {
        if !vibeCategories.isEmpty {
            let shown = showAllVibes ? vibeCategories : Array(vibeCategories.prefix(vibePreviewCount))
            VStack(alignment: .leading, spacing: 14) {
                Text("NYC vibes").sectionHeaderStyle()
                ForEach(Array(shown.enumerated()), id: \.element.id) { index, category in
                    NavigationLink(value: SearchRoute(query: category.label)) {
                        FeatureVibeCard(
                            category: category,
                            palette: VibePalette.make(for: category.label, index: index)
                        )
                    }
                    .buttonStyle(CardPressStyle())
                }

                if vibeCategories.count > vibePreviewCount {
                    Button {
                        withAnimation(.easeInOut) { showAllVibes.toggle() }
                    } label: {
                        HStack {
                            Spacer()
                            Text(showAllVibes ? "Show less" : "See all \(vibeCategories.count) vibes")
                            Image(systemName: showAllVibes ? "chevron.up" : "chevron.down")
                            Spacer()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Theme.accent.opacity(0.10))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func submit() {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        router.askInChat(trimmed)
        queryText = ""
        askFocused = false
    }

    private func loadVibeCategories() async {
        guard vibeCategories.isEmpty else { return }
        do {
            vibeCategories = try await APIClient.shared.filters().vibeCategories
        } catch {
            vibeCategories = []
        }
    }
}

// MARK: - Quick idea chip

/// Pill-shaped quick-search chip with an emoji and a soft accent gradient.
struct QuickIdeaChip: View {
    let label: String
    let emoji: String

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Theme.accent, Color(red: 0.96, green: 0.18, blue: 0.55)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji).font(.subheadline)
            Text(label).font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Capsule().fill(Theme.accent.opacity(0.10)))
        .overlay(Capsule().stroke(gradient.opacity(0.45), lineWidth: 1))
    }
}

// MARK: - Vibe feature card

/// Subtle press feedback for large tappable cards.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

/// Large, full-width magazine-style card for an NYC vibe category.
struct FeatureVibeCard: View {
    let category: VibeCategory
    let palette: VibePalette

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: palette.colors,
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            Image(systemName: palette.icon)
                .font(.system(size: 96, weight: .semibold))
                .foregroundStyle(.white.opacity(0.16))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 20, y: 4)

            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(.white.opacity(0.22))
                    Text(palette.emoji).font(.title)
                }
                .frame(width: 52, height: 52)
                .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))

                VStack(alignment: .leading, spacing: 5) {
                    if let hood = category.neighborhood, !hood.isEmpty {
                        Text(hood.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Text(category.label)
                        .font(.display(.title3, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 4) {
                        Text("Explore")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.top, 1)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 116)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: (palette.colors.last ?? .black).opacity(0.28), radius: 6, y: 4)
    }
}

/// Mood-matched icon + a varied gradient for each vibe tile.
struct VibePalette {
    let colors: [Color]
    let icon: String
    let emoji: String

    private static let gradients: [[Color]] = [
        [Color(red: 1.00, green: 0.36, blue: 0.42), Color(red: 0.96, green: 0.16, blue: 0.55)], // pink/red
        [Color(red: 1.00, green: 0.55, blue: 0.20), Color(red: 1.00, green: 0.30, blue: 0.28)], // orange
        [Color(red: 0.40, green: 0.50, blue: 0.98), Color(red: 0.60, green: 0.32, blue: 0.92)], // indigo/violet
        [Color(red: 0.18, green: 0.72, blue: 0.62), Color(red: 0.12, green: 0.52, blue: 0.74)], // teal/blue
        [Color(red: 0.95, green: 0.45, blue: 0.30), Color(red: 0.72, green: 0.22, blue: 0.55)], // sunset
        [Color(red: 0.36, green: 0.42, blue: 0.78), Color(red: 0.20, green: 0.24, blue: 0.45)], // dusk
        [Color(red: 0.20, green: 0.62, blue: 0.40), Color(red: 0.10, green: 0.42, blue: 0.36)], // green
        [Color(red: 0.85, green: 0.30, blue: 0.42), Color(red: 0.55, green: 0.18, blue: 0.50)], // berry
    ]

    static func make(for label: String, index: Int) -> VibePalette {
        VibePalette(
            colors: gradients[index % gradients.count],
            icon: icon(for: label),
            emoji: emoji(for: label)
        )
    }

    private static func emoji(for label: String) -> String {
        let l = label.lowercased()
        switch true {
        case l.contains("date"), l.contains("romantic"): return "💕"
        case l.contains("cafe"), l.contains("coffee"), l.contains("work"): return "☕️"
        case l.contains("rooftop"): return "🌆"
        case l.contains("late"), l.contains("night"): return "🌙"
        case l.contains("trendy"), l.contains("hot"): return "🔥"
        case l.contains("cozy"): return "🕯️"
        case l.contains("waterfront"), l.contains("dumbo"): return "🌊"
        case l.contains("group"), l.contains("crawl"), l.contains("dinner"): return "🥂"
        case l.contains("upscale"), l.contains("michelin"), l.contains("tribeca"): return "✨"
        case l.contains("aesthetic"), l.contains("gallery"), l.contains("art"): return "📸"
        case l.contains("must-eat"), l.contains("food"), l.contains("flushing"): return "🍜"
        case l.contains("cocktail"), l.contains("bar"): return "🍸"
        default: return "🍽️"
        }
    }

    private static func icon(for label: String) -> String {
        let l = label.lowercased()
        switch true {
        case l.contains("date"), l.contains("romantic"): return "heart.fill"
        case l.contains("cafe"), l.contains("coffee"), l.contains("work"): return "cup.and.saucer.fill"
        case l.contains("rooftop"): return "building.2.fill"
        case l.contains("late"), l.contains("night"): return "moon.stars.fill"
        case l.contains("trendy"), l.contains("hot"): return "flame.fill"
        case l.contains("cozy"): return "flame"
        case l.contains("waterfront"), l.contains("dumbo"): return "water.waves"
        case l.contains("group"), l.contains("crawl"), l.contains("dinner"): return "person.3.fill"
        case l.contains("upscale"), l.contains("michelin"), l.contains("tribeca"): return "star.fill"
        case l.contains("aesthetic"), l.contains("gallery"), l.contains("art"): return "camera.fill"
        case l.contains("must-eat"), l.contains("food"), l.contains("flushing"): return "fork.knife"
        case l.contains("cocktail"), l.contains("bar"): return "wineglass.fill"
        default: return "sparkles"
        }
    }
}
