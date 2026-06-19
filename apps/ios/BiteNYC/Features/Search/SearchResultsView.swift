import SwiftUI

struct SearchResultsView: View {
    let query: String

    @State private var results: [SearchResult] = []
    @State private var resolvedFilters: SearchFilters?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Finding the best NYC spots…")
                    .frame(maxWidth: .infinity, minHeight: 240)
            } else if let errorMessage {
                ErrorBanner(message: errorMessage) { Task { await load() } }
            } else if results.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 16) {
                    if let chips = filterSummary, !chips.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(chips, id: \.self) { TagChip(text: $0, selected: true) }
                            }
                            .padding(.horizontal)
                        }
                    }
                    ForEach(results) { result in
                        NavigationLink(value: RestaurantRoute(slug: result.restaurant.slug)) {
                            RestaurantCard(restaurant: result.restaurant, whyItFits: result.whyItFits)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(query)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: query) { await load() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.largeTitle).foregroundStyle(.secondary)
            Text("No matches in the BiteNYC catalog yet.")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("Try a different neighborhood or loosen the budget.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding()
    }

    private var filterSummary: [String]? {
        guard let f = resolvedFilters else { return nil }
        var chips: [String] = []
        if let n = f.neighborhood { chips.append(n) }
        else if let b = f.borough { chips.append(b) }
        if let o = f.occasion { chips.append(prettyTag(o)) }
        chips.append(contentsOf: (f.vibe ?? []).prefix(3).map(prettyTag))
        if let tier = f.maxPriceTier { chips.append("≤ " + String(repeating: "$", count: tier)) }
        return chips
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIClient.shared.search(query: query, limit: 10)
            results = response.results
            resolvedFilters = response.filters
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
