import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var queryText = ""
    @State private var vibeCategories: [VibeCategory] = []
    @State private var path = NavigationPath()
    @State private var exampleIndex = 0
    @FocusState private var askFocused: Bool

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

    private var askHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").font(.title3).foregroundStyle(Theme.accent)
                Text("Ask BiteNYC").font(.display(.title2, weight: .bold))
            }
            Text("Describe the vibe, occasion, dish, or neighborhood — I'll find the spot.")
                .font(.subheadline).foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "text.bubble").font(.title3).foregroundStyle(Theme.accent).padding(.top, 4)
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
                    Image(systemName: "arrow.up.circle.fill").font(.largeTitle)
                }
                .tint(Theme.accent)
                .disabled(queryText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.accent.opacity(0.55), lineWidth: 1.5))

            Button(action: submit) {
                Text("Ask").fontWeight(.semibold).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .controlSize(.large)
            .disabled(queryText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22).fill(
                LinearGradient(
                    colors: [Theme.accent.opacity(0.20), Theme.accent.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
        )
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
                        TagChip(text: chip.label, systemImage: chip.icon)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var vibeCategoriesSection: some View {
        if !vibeCategories.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("NYC vibes").sectionHeaderStyle()
                ForEach(Array(vibeCategories.enumerated()), id: \.element.id) { index, category in
                    NavigationLink(value: SearchRoute(query: category.label)) {
                        FeatureVibeCard(
                            category: category,
                            palette: VibePalette.make(for: category.label, index: index)
                        )
                    }
                    .buttonStyle(CardPressStyle())
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
        VibePalette(colors: gradients[index % gradients.count], icon: icon(for: label))
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
