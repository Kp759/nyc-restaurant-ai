import Foundation
import Combine

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Filter metadata
    @Published var boroughs: [String] = []
    @Published var neighborhoods: [Neighborhood] = []
    @Published var vibeTags: [String] = []
    @Published var vibeCategories: [VibeCategory] = []

    // Active filters
    @Published var borough: String? { didSet { if borough != oldValue { neighborhood = nil } } }
    @Published var neighborhood: String?
    @Published var maxPriceTier: Int?
    @Published var selectedVibes: Set<String> = []
    @Published var openNow = false
    @Published var reservationAvailable = false

    private var didLoadMetadata = false

    var neighborhoodOptions: [Neighborhood] {
        guard let borough else { return neighborhoods }
        return neighborhoods.filter { $0.borough == borough }
    }

    var activeFilterCount: Int {
        var n = 0
        if borough != nil { n += 1 }
        if neighborhood != nil { n += 1 }
        if maxPriceTier != nil { n += 1 }
        n += selectedVibes.count
        if openNow { n += 1 }
        if reservationAvailable { n += 1 }
        return n
    }

    func loadMetadataIfNeeded() async {
        guard !didLoadMetadata else { return }
        do {
            async let filters = APIClient.shared.filters()
            async let hoods = APIClient.shared.neighborhoods()
            let (f, h) = try await (filters, hoods)
            boroughs = f.boroughs
            vibeTags = f.vibeTags
            vibeCategories = f.vibeCategories
            neighborhoods = h
            didLoadMetadata = true
        } catch {
            // Non-fatal: filters just won't populate.
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        var query = RestaurantQuery()
        query.borough = borough
        query.neighborhood = neighborhood
        query.maxPriceTier = maxPriceTier
        query.vibe = Array(selectedVibes)
        query.openNow = openNow
        query.reservationAvailable = reservationAvailable
        query.limit = 50
        do {
            restaurants = try await APIClient.shared.restaurants(query)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func resetFilters() {
        borough = nil
        neighborhood = nil
        maxPriceTier = nil
        selectedVibes = []
        openNow = false
        reservationAvailable = false
    }
}
