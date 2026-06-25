import Foundation
import Combine

// MARK: - Models

struct UserProfile: Codable, Hashable {
    var name: String
    var tagline: String
    var homeNeighborhood: String
    var memberSince: Date

    static let `default` = UserProfile(
        name: "Guest",
        tagline: "NYC food explorer",
        homeNeighborhood: "",
        memberSince: Date()
    )

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init)
        let joined = letters.joined().uppercased()
        return joined.isEmpty ? "🙂" : joined
    }
}

/// The user's taste profile — "What's your vibe".
struct VibeProfile: Codable, Hashable {
    var vibes: [String] = []
    var cuisines: [String] = []
    var priceCeiling: Int = 4   // 1...4, 4 == any

    var isEmpty: Bool { vibes.isEmpty && cuisines.isEmpty && priceCeiling == 4 }

    /// Curated options for the editor (kept local so the screen works offline).
    static let vibeOptions = [
        "cozy", "romantic", "aesthetic", "trendy", "lively", "quiet",
        "rooftop", "outdoor", "date_night", "group_friendly", "solo_friendly",
        "work_friendly", "cocktails", "hidden_gem", "late_night",
    ]
    static let cuisineOptions = [
        "italian", "japanese", "pizza", "ramen", "mexican", "thai",
        "korean", "french", "american", "mediterranean", "indian",
        "cafe", "dessert", "vegan", "seafood",
    ]
}

struct VisitedPlace: Codable, Identifiable, Hashable {
    let id: String          // restaurant id
    var name: String
    var slug: String
    var neighborhood: String
    var borough: String
    var heroImageURL: String?
    var visitedOn: Date

    init(_ r: Restaurant, visitedOn: Date = Date()) {
        id = r.id
        name = r.name
        slug = r.slug
        neighborhood = r.neighborhood
        borough = r.borough
        heroImageURL = r.heroImageURL
        self.visitedOn = visitedOn
    }
}

struct UserReview: Codable, Identifiable, Hashable {
    let id: UUID
    let restaurantId: String
    var restaurantName: String
    var slug: String
    var rating: Int         // 1...5
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), restaurant: Restaurant, rating: Int, text: String) {
        self.id = id
        restaurantId = restaurant.id
        restaurantName = restaurant.name
        slug = restaurant.slug
        self.rating = rating
        self.text = text
        createdAt = Date()
    }
}

struct Reservation: Codable, Identifiable, Hashable {
    let id: UUID
    let restaurantId: String
    var restaurantName: String
    var slug: String
    var neighborhood: String
    var heroImageURL: String?
    var date: Date
    var partySize: Int
    var occasion: String?
    var isCancelled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        restaurant: Restaurant,
        date: Date,
        partySize: Int,
        occasion: String?
    ) {
        self.id = id
        restaurantId = restaurant.id
        restaurantName = restaurant.name
        slug = restaurant.slug
        neighborhood = restaurant.neighborhood
        heroImageURL = restaurant.heroImageURL
        self.date = date
        self.partySize = partySize
        self.occasion = occasion
        isCancelled = false
        createdAt = Date()
    }

    var isUpcoming: Bool { !isCancelled && date >= Date() }
}

// MARK: - Store

@MainActor
final class AccountStore: ObservableObject {
    @Published var profile: UserProfile = .default
    @Published var vibe: VibeProfile = VibeProfile()
    @Published private(set) var visited: [VisitedPlace] = []
    @Published private(set) var reviews: [UserReview] = []
    @Published private(set) var reservations: [Reservation] = []

    private let key = "bitenyc.account.v1"

    init() { load() }

    // MARK: Derived

    var upcomingReservations: [Reservation] {
        reservations.filter(\.isUpcoming).sorted { $0.date < $1.date }
    }
    var pastReservations: [Reservation] {
        reservations.filter { !$0.isUpcoming }.sorted { $0.date > $1.date }
    }
    var sortedVisited: [VisitedPlace] { visited.sorted { $0.visitedOn > $1.visitedOn } }
    var sortedReviews: [UserReview] { reviews.sorted { $0.createdAt > $1.createdAt } }

    func hasVisited(_ r: Restaurant) -> Bool { visited.contains { $0.id == r.id } }
    func review(for r: Restaurant) -> UserReview? { reviews.first { $0.restaurantId == r.id } }

    /// Builds an Explore query from the saved taste profile for "places you may like".
    var recommendationQuery: RestaurantQuery {
        RestaurantQuery(
            maxPriceTier: vibe.priceCeiling < 4 ? vibe.priceCeiling : nil,
            vibe: vibe.vibes,
            cuisine: vibe.cuisines,
            limit: 10
        )
    }

    // MARK: Mutations

    func updateProfile(_ p: UserProfile) { profile = p; persist() }
    func updateVibe(_ v: VibeProfile) { vibe = v; persist() }

    func toggleVisited(_ r: Restaurant) {
        if let idx = visited.firstIndex(where: { $0.id == r.id }) {
            visited.remove(at: idx)
        } else {
            visited.insert(VisitedPlace(r), at: 0)
        }
        persist()
    }

    func saveReview(for r: Restaurant, rating: Int, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let idx = reviews.firstIndex(where: { $0.restaurantId == r.id }) {
            reviews[idx].rating = rating
            reviews[idx].text = trimmed
            reviews[idx].createdAt = Date()
        } else {
            reviews.insert(UserReview(restaurant: r, rating: rating, text: trimmed), at: 0)
        }
        // Reviewing a place implies you've been there.
        if !hasVisited(r) { visited.insert(VisitedPlace(r), at: 0) }
        persist()
    }

    func deleteReview(_ id: UUID) {
        reviews.removeAll { $0.id == id }
        persist()
    }

    func addReservation(for r: Restaurant, date: Date, partySize: Int, occasion: String?) {
        reservations.insert(
            Reservation(restaurant: r, date: date, partySize: partySize, occasion: occasion),
            at: 0
        )
        persist()
    }

    func cancelReservation(_ id: UUID) {
        guard let idx = reservations.firstIndex(where: { $0.id == id }) else { return }
        reservations[idx].isCancelled = true
        persist()
    }

    func removeReservation(_ id: UUID) {
        reservations.removeAll { $0.id == id }
        persist()
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var profile: UserProfile
        var vibe: VibeProfile
        var visited: [VisitedPlace]
        var reviews: [UserReview]
        var reservations: [Reservation]
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        profile = s.profile
        vibe = s.vibe
        visited = s.visited
        reviews = s.reviews
        reservations = s.reservations
    }

    private func persist() {
        let snapshot = Snapshot(
            profile: profile, vibe: vibe, visited: visited,
            reviews: reviews, reservations: reservations
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
