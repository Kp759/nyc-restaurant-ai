import SwiftUI

struct HomeView: View {
    @State private var queryText = ""
    @State private var vibeCategories: [VibeCategory] = []
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    searchBar
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

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What are you looking for?").sectionHeaderStyle()
            HStack {
                Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                TextField("Cozy date-night spots in West Village…", text: $queryText)
                    .submitLabel(.search)
                    .onSubmit(submit)
                if !queryText.isEmpty {
                    Button(action: submit) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2).foregroundStyle(Theme.accent)
                    }
                }
            }
            .padding(12)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
            VStack(alignment: .leading, spacing: 10) {
                Text("NYC vibes").sectionHeaderStyle()
                ForEach(vibeCategories) { category in
                    NavigationLink(value: SearchRoute(query: category.label)) {
                        HStack {
                            Text(category.label).font(.subheadline).fontWeight(.medium)
                            Spacer()
                            if let hood = category.neighborhood {
                                Text(hood).font(.caption).foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func submit() {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        path.append(SearchRoute(query: trimmed))
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
