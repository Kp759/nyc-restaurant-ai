import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @AppStorage("bitenyc.homeLayout") private var layoutStyle: HomeLayoutStyle = .editorial

    @State private var queryText = ""
    @State private var vibeCategories: [VibeCategory] = []
    @State private var path = NavigationPath()
    @State private var exampleIndex = 0
    @FocusState private var askFocused: Bool

    private let editorialVibeCount = 4
    private let minimalVibeCount = 6

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
                VStack(alignment: .leading, spacing: 0) {
                    layoutSwitcher
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    Group {
                        switch layoutStyle {
                        case .classic: classicContent
                        case .editorial: editorialContent
                        case .minimal: minimalContent
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { layoutPicker }
            .navigationDestination(for: RestaurantRoute.self) { route in
                RestaurantDetailView(slug: route.slug)
            }
            .task { await loadVibeCategories() }
        }
    }

    // MARK: - Layout picker (compare layouts)

    private var horizontalPadding: CGFloat {
        switch layoutStyle {
        case .editorial: return 18
        case .minimal: return 20
        case .classic: return 16
        }
    }

    private var verticalPadding: CGFloat {
        switch layoutStyle {
        case .editorial, .minimal: return 12
        case .classic: return 16
        }
    }

    /// Visible A/B switcher so you can compare layouts without hunting in the menu.
    private var layoutSwitcher: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Compare layouts")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.6)

            Picker("Layout", selection: $layoutStyle) {
                ForEach(HomeLayoutStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }
            .pickerStyle(.segmented)

            Text(layoutStyle.blurb)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ToolbarContentBuilder
    private var layoutPicker: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Home layout", selection: $layoutStyle) {
                    ForEach(HomeLayoutStyle.allCases) { style in
                        Text("\(style.label) — \(style.blurb)").tag(style)
                    }
                }
            } label: {
                Label(layoutStyle.label, systemImage: "square.2.layers.3d")
                    .font(.caption.weight(.semibold))
            }
        }
    }

    // MARK: - Classic (current bulky layout)

    private var classicContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            classicHeader
            classicAskHero
            classicPromptChips
        }
    }

    private var classicHeader: some View {
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

    private var classicAskHero: some View {
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
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(askGradient, lineWidth: 2))

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
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(askGradient.opacity(0.25), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onReceive(rotation) { _ in rotateExamplesIfNeeded() }
    }

    private var classicPromptChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Occasions & dishes").sectionHeaderStyle()
            FlowLayout(spacing: 8) {
                ForEach(HomePrompts.chips, id: \.label) { chip in
                    Button { ask(chip.label) } label: {
                        QuickIdeaChip(label: chip.label, emoji: ideaEmoji(chip.label))
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
        }
    }

    // MARK: - Editorial (light, airy layout)

    private var editorialContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            editorialHeader
            editorialAskBar
            editorialQuickRail
            editorialVibeRail
        }
    }

    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Bite").font(.display(.title, weight: .bold))
                Text("NYC").font(.display(.title, weight: .bold)).foregroundStyle(Theme.accent)
            }
            Text("Find the right spot by vibe, dish, or neighborhood.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var editorialAskBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Text("Ask BiteNYC")
                    .font(.display(.title3, weight: .bold))
            }

            HStack(alignment: .top, spacing: 12) {
                TextField(
                    "",
                    text: $queryText,
                    prompt: Text(examples[exampleIndex]).foregroundColor(.secondary),
                    axis: .vertical
                )
                .font(.title3)
                .lineLimit(2...5)
                .focused($askFocused)
                .submitLabel(.send)
                .onSubmit(submit)

                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Theme.accent)
                }
                .disabled(queryText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        askFocused ? Theme.accent.opacity(0.55) : Theme.accent.opacity(0.2),
                        lineWidth: askFocused ? 2 : 1
                    )
            )

            Text("Describe a vibe, dish, neighborhood, or occasion.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Theme.accent.opacity(0.08))
        )
        .onReceive(rotation) { _ in rotateExamplesIfNeeded() }
    }

    private var editorialQuickRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Occasions & dishes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HomePrompts.chips, id: \.label) { chip in
                        Button { ask(chip.label) } label: {
                            EditorialPill(label: chip.label, emoji: ideaEmoji(chip.label))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var editorialVibeRail: some View {
        if !vibeCategories.isEmpty {
            let shown = Array(vibeCategories.prefix(editorialVibeCount))
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Explore neighborhoods")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if vibeCategories.count > editorialVibeCount {
                        Button("See all") { router.openExplore() }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { index, category in
                            Button { ask(category.label) } label: {
                                EditorialVibeCard(
                                    category: category,
                                    palette: VibePalette.make(for: category.label, index: index)
                                )
                            }
                            .buttonStyle(CardPressStyle())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Minimal (compact, clean)

    private let minimalVibeColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    private var minimalContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            minimalHeader
            minimalAskBar
            minimalQuickChips
            minimalVibeGrid
        }
    }

    private var minimalHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Bite").font(.display(.title2, weight: .bold))
                Text("NYC").font(.display(.title2, weight: .bold)).foregroundStyle(Theme.accent)
            }
            Text("Where should you eat tonight?")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var minimalAskBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(
                "",
                text: $queryText,
                prompt: Text(examples[exampleIndex]).foregroundColor(.secondary),
                axis: .vertical
            )
            .font(.body)
            .lineLimit(1...2)
            .focused($askFocused)
            .submitLabel(.send)
            .onSubmit(submit)

            if !queryText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(.tertiarySystemBackground))
        .clipShape(Capsule())
        .onReceive(rotation) { _ in rotateExamplesIfNeeded() }
    }

    private var minimalQuickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HomePrompts.chips.prefix(6), id: \.label) { chip in
                    Button { ask(chip.label) } label: {
                        HStack(spacing: 4) {
                            Text(ideaEmoji(chip.label))
                            Text(chip.label).font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Theme.chipBackground)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var minimalVibeGrid: some View {
        if !vibeCategories.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Explore neighborhoods")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if vibeCategories.count > minimalVibeCount {
                        Button("See all") { router.openExplore() }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }

                LazyVGrid(columns: minimalVibeColumns, spacing: 10) {
                    ForEach(Array(vibeCategories.prefix(minimalVibeCount).enumerated()), id: \.element.id) { index, category in
                        Button { ask(category.label) } label: {
                            MinimalVibeTile(
                                category: category,
                                palette: VibePalette.make(for: category.label, index: index)
                            )
                        }
                        .buttonStyle(CardPressStyle())
                    }
                }
            }
        }
    }

    // MARK: - Shared

    private func rotateExamplesIfNeeded() {
        guard queryText.isEmpty, !askFocused else { return }
        withAnimation(.easeInOut) { exampleIndex = (exampleIndex + 1) % examples.count }
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

    private func ask(_ prompt: String) {
        router.askInChat(prompt)
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

// MARK: - Editorial components

struct EditorialPill: View {
    let label: String
    let emoji: String

    var body: some View {
        HStack(spacing: 5) {
            Text(emoji).font(.caption)
            Text(label).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.chipBackground)
        .clipShape(Capsule())
    }
}

/// Landscape editorial card — accent stripe, emoji badge, serif title.
struct EditorialVibeCard: View {
    let category: VibeCategory
    let palette: VibePalette

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: palette.colors, startPoint: .top, endPoint: .bottom))
                .frame(width: 4)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: palette.colors.map { $0.opacity(0.85) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(palette.emoji).font(.title2)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    if let hood = category.neighborhood, !hood.isEmpty {
                        Text(hood.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(Theme.accent)
                    }
                    Text(category.label)
                        .font(.display(.subheadline, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Theme.chipBackground)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .frame(width: 248, height: 88)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

/// Small square tile for the minimal 2-column vibe grid.
struct MinimalVibeTile: View {
    let category: VibeCategory
    let palette: VibePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(palette.emoji).font(.title2)
            Spacer(minLength: 0)
            Text(category.label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let hood = category.neighborhood, !hood.isEmpty {
                Text(hood)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: palette.colors.map { $0.opacity(0.18) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(palette.colors.first?.opacity(0.25) ?? .clear, lineWidth: 1)
        )
    }
}

// MARK: - Classic components (unchanged)

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

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct VibePalette {
    let colors: [Color]
    let icon: String
    let emoji: String

    private static let gradients: [[Color]] = [
        [Color(red: 1.00, green: 0.36, blue: 0.42), Color(red: 0.96, green: 0.16, blue: 0.55)],
        [Color(red: 1.00, green: 0.55, blue: 0.20), Color(red: 1.00, green: 0.30, blue: 0.28)],
        [Color(red: 0.40, green: 0.50, blue: 0.98), Color(red: 0.60, green: 0.32, blue: 0.92)],
        [Color(red: 0.18, green: 0.72, blue: 0.62), Color(red: 0.12, green: 0.52, blue: 0.74)],
        [Color(red: 0.95, green: 0.45, blue: 0.30), Color(red: 0.72, green: 0.22, blue: 0.55)],
        [Color(red: 0.36, green: 0.42, blue: 0.78), Color(red: 0.20, green: 0.24, blue: 0.45)],
        [Color(red: 0.20, green: 0.62, blue: 0.40), Color(red: 0.10, green: 0.42, blue: 0.36)],
        [Color(red: 0.85, green: 0.30, blue: 0.42), Color(red: 0.55, green: 0.18, blue: 0.50)],
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
