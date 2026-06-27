import Foundation

/// Loads "Places you may like" from the Explore endpoint using the user's vibe.
@MainActor
final class AccountViewModel: ObservableObject {
    @Published private(set) var recommendations: [Restaurant] = []
    @Published private(set) var isLoading = false

    private var lastQueryKey: String?

    func loadRecommendations(query: RestaurantQuery, force: Bool = false) async {
        let key = "\(query.maxPriceTier ?? 0)|\(query.vibe.joined(separator: ","))|\(query.cuisine.joined(separator: ","))"
        if !force, key == lastQueryKey, !recommendations.isEmpty { return }
        lastQueryKey = key
        isLoading = true
        defer { isLoading = false }
        do {
            recommendations = try await APIClient.shared.restaurants(query)
        } catch {
            recommendations = []
        }
    }
}
