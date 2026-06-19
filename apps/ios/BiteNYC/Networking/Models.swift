import Foundation

// MARK: - Restaurant

struct Restaurant: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    var description: String?
    var editorialSummary: String?
    var address: String
    var neighborhood: String
    var borough: String
    var latitude: Double
    var longitude: Double
    var cuisineTags: [String]
    var vibeTags: [String]
    var occasionTags: [String]
    var dietaryTags: [String]
    var priceTier: Int?
    var rating: Double?
    var reviewCount: Int?
    var resyUrl: String?
    var opentableId: String?
    var tockUrl: String?
    var directBookingUrl: String?
    var healthGrade: String?
    var healthGradeDate: String?
    var healthInspectionScore: Int?
    var isWalkInFriendly: Bool?
    var isGoodForDate: Bool?
    var isGoodForGroups: Bool?
    var isGoodForWorking: Bool?
    var isOpenLate: Bool?
    var isTouristFriendly: Bool?

    // Present on detail / list / search payloads
    var dishes: [Dish]?
    var media: [MediaItem]?
    var bookingLinks: [BookingLink]?
    var similar: [SimilarRestaurant]?

    var priceLabel: String {
        guard let tier = priceTier, tier > 0 else { return "" }
        return String(repeating: "$", count: min(tier, 4))
    }

    var mustTryDishes: [Dish] {
        (dishes ?? []).filter { $0.isMustTry == true }
    }

    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct SimilarRestaurant: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    var neighborhood: String?
    var borough: String?
    var priceTier: Int?
    var rating: Double?
}

// MARK: - Dish

struct Dish: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var description: String?
    var whyTry: String?
    var dishType: String?
    var tags: [String]?
    var isMustTry: Bool?
    var rank: Int?
    var photoUrl: String?
}

// MARK: - Media

struct MediaItem: Codable, Identifiable, Hashable {
    let id: String
    var mediaType: String   // photo | video | embed
    var source: String
    var url: String
    var thumbnailUrl: String?
    var caption: String?
    var creatorName: String?
    var creatorUrl: String?
}

// MARK: - Booking

struct BookingLink: Codable, Hashable, Identifiable {
    var provider: String   // resy | opentable | tock | sevenrooms | direct | phone
    var label: String
    var url: String
    var id: String { provider + url }
}

// MARK: - Search / AI

struct ScoreBreakdown: Codable, Hashable {
    var semanticSimilarity: Double
    var vibeMatch: Double
    var neighborhoodMatch: Double
    var dishQuality: Double
    var editorialScore: Double
    var reviewSentiment: Double
    var reservationAvailable: Double
    var mediaQuality: Double
    var healthGradeSignal: Double
    var finalScore: Double
}

struct SearchResult: Codable, Identifiable, Hashable {
    var restaurant: Restaurant
    var whyItFits: String?
    var bookingLinks: [BookingLink]?
    var score: ScoreBreakdown?
    var id: String { restaurant.id }
}

struct SearchFilters: Codable, Hashable {
    var city: String?
    var borough: String?
    var neighborhood: String?
    var occasion: String?
    var vibe: [String]?
    var cuisine: [String]?
    var budget: String?
    var maxPriceTier: Int?
    var partySize: Int?
    var openNow: Bool?
    var reservationAvailable: Bool?
}

struct SearchResponse: Codable {
    var query: String
    var filters: SearchFilters?
    var results: [SearchResult]
}

struct ChatResponse: Codable {
    var reply: String
    var results: [SearchResult]
}

// MARK: - Lists / metadata

struct RestaurantListResponse: Codable {
    var count: Int
    var offset: Int
    var limit: Int
    var restaurants: [Restaurant]
}

struct Neighborhood: Codable, Identifiable, Hashable {
    var name: String
    var borough: String
    var mvpPhase: Int?
    var id: String { name + borough }
}

struct NeighborhoodsResponse: Codable {
    var neighborhoods: [Neighborhood]
}

struct PriceTierMeta: Codable, Hashable {
    var tier: Int
    var label: String
    var hint: String
}

struct VibeCategory: Codable, Identifiable, Hashable {
    var id: String
    var label: String
    var neighborhood: String?
}

struct FiltersResponse: Codable {
    var boroughs: [String]
    var vibeTags: [String]
    var occasionTags: [String]
    var dietaryTags: [String]
    var nycFilters: [String]
    var priceTiers: [PriceTierMeta]
    var vibeCategories: [VibeCategory]
}
