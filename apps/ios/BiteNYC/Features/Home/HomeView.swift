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
                Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                Text("Ask BiteNYC").font(.display(.title3, weight: .semibold))
            }
            Text("Describe the vibe, occasion, dish, or neighborhood — I'll find the spot.")
                .font(.subheadline).foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "text.bubble").foregroundStyle(Theme.accent).padding(.top, 2)
                TextField(
                    "Ask anything",
                    text: $queryText,
                    prompt: Text(examples[exampleIndex]).foregroundColor(.secondary),
                    axis: .vertical
                )
                .lineLimit(1...3)
                .focused($askFocused)
                .submitLabel(.search)
                .onSubmit(submit)
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill").font(.title)
                }
                .tint(Theme.accent)
                .disabled(queryText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent.opacity(0.55), lineWidth: 1.5))

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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("NYC vibes").sectionHeaderStyle()
                    Spacer()
                    Text("Scroll to zoom").font(.caption2).foregroundStyle(.secondary)
                }
                VibeHoneycomb(categories: vibeCategories)
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

// MARK: - Vibe honeycomb

/// Apple Watch–style honeycomb: circular vibe bubbles packed in offset rows.
/// Each bubble grows as it nears the vertical center of the screen and shrinks
/// toward the edges as the page scrolls.
struct VibeHoneycomb: View {
    let categories: [VibeCategory]

    private let diameter: CGFloat = 96
    private let hGap: CGFloat = 12

    /// Rows alternate 3 / 2 items for a hexagonal tessellation, while keeping
    /// each item's original index so the gradient palette stays varied.
    private var rows: [[(index: Int, category: VibeCategory)]] {
        var result: [[(Int, VibeCategory)]] = []
        var i = 0
        var wide = true
        while i < categories.count {
            let count = wide ? 3 : 2
            let slice = categories[i..<min(i + count, categories.count)]
            result.append(slice.enumerated().map { (i + $0.offset, $0.element) })
            i += count
            wide.toggle()
        }
        return result
    }

    var body: some View {
        let screenCenterY = UIScreen.main.bounds.midY
        VStack(spacing: -diameter * 0.08) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: hGap) {
                    ForEach(row, id: \.category.id) { item in
                        NavigationLink(value: SearchRoute(query: item.category.label)) {
                            HoneycombBubble(
                                category: item.category,
                                palette: VibePalette.make(for: item.category.label, index: item.index),
                                diameter: diameter,
                                screenCenterY: screenCenterY
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// A single circular vibe bubble that scales by its distance from screen center.
struct HoneycombBubble: View {
    let category: VibeCategory
    let palette: VibePalette
    let diameter: CGFloat
    let screenCenterY: CGFloat

    var body: some View {
        GeometryReader { geo in
            let midY = geo.frame(in: .global).midY
            let distance = abs(midY - screenCenterY)
            let t = min(distance / 280, 1)            // 0 at center → 1 far away
            let scale = 1.0 - t * 0.5                  // 1.0 → 0.5
            let focused = scale > 0.86

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: palette.colors,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1)

                VStack(spacing: 3) {
                    Image(systemName: palette.icon)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    if focused {
                        Text(category.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 8)
                    }
                }
            }
            .scaleEffect(scale)
            .shadow(color: (palette.colors.last ?? .black).opacity(0.3 * scale),
                    radius: 5, y: 3)
            .frame(width: diameter, height: diameter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: diameter, height: diameter)
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
