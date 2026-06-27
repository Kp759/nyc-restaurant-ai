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
    var googlePlaceId: String?
    var phone: String?
    var instagramUrl: String?
    var xUrl: String?
    var facebookUrl: String?
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
        (dishes ?? [])
            .filter { $0.isMustTry == true }
            .sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }
    }

    var mustTryFood: [Dish] {
        mustTryDishes.filter { !Self.isDrinkDish($0) }
    }

    var mustTryDrinks: [Dish] {
        mustTryDishes.filter { Self.isDrinkDish($0) }
    }

    /// All dishes for the dedicated menu screen.
    var allMenuDishes: [Dish] {
        (dishes ?? []).sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }
    }

    /// Non–must-try items (shown on the full menu screen only).
    var menuDishes: [Dish] {
        (dishes ?? [])
            .filter { $0.isMustTry != true }
            .sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }
    }

    /// Phone number for dialing when available.
    var dialPhoneNumber: String? {
        if let phone, !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return phone
        }
        if let tel = bookingLinks?.first(where: { $0.provider == "phone" })?.url {
            return tel
                .replacingOccurrences(of: "tel:", with: "")
                .replacingOccurrences(of: "tel://", with: "")
        }
        return nil
    }

    var hasCallAction: Bool { callURL != nil }

    /// Booking links from API, or built locally when the payload omits them.
    var effectiveBookingLinks: [BookingLink] {
        var links = bookingLinks ?? []
        if links.isEmpty {
            links = buildLocalBookingLinks()
        } else if dialPhoneNumber == nil, let phone, !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let digits = phone.filter { $0.isNumber || $0 == "+" }
            if digits.count >= 7 {
                links.append(BookingLink(provider: "phone", label: "Call restaurant", url: "tel:\(digits)"))
            }
        }
        return links
    }

    /// Opens Phone app when a number exists; otherwise Google Maps place page for the listing.
    var callURL: URL? {
        if let raw = dialPhoneNumber {
            let digits = raw.filter { $0.isNumber || $0 == "+" }
            if digits.count >= 7 { return URL(string: "tel:\(digits)") }
        }
        return mapsPlaceURL
    }

    var usesMapsCallFallback: Bool {
        dialPhoneNumber == nil && mapsPlaceURL != nil
    }

    private var mapsPlaceURL: URL? {
        guard let id = googlePlaceId, !id.isEmpty else { return nil }
        let q = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(q)&query_place_id=\(id)")
    }

    private func buildLocalBookingLinks() -> [BookingLink] {
        var links: [BookingLink] = []
        if let resyUrl, !resyUrl.isEmpty {
            links.append(BookingLink(provider: "resy", label: "Reserve on Resy", url: resyUrl))
        }
        if let opentableId, !opentableId.isEmpty {
            links.append(BookingLink(provider: "opentable", label: "Reserve on OpenTable", url: "https://www.opentable.com/r/\(opentableId)"))
        }
        if let tockUrl, !tockUrl.isEmpty {
            links.append(BookingLink(provider: "tock", label: "Book on Tock", url: tockUrl))
        }
        if let directBookingUrl, !directBookingUrl.isEmpty {
            links.append(BookingLink(provider: "direct", label: "Book Direct", url: directBookingUrl))
        }
        if let phone, !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let digits = phone.filter { $0.isNumber || $0 == "+" }
            if digits.count >= 7 {
                links.append(BookingLink(provider: "phone", label: "Call restaurant", url: "tel:\(digits)"))
            }
        }
        return links
    }

    private static func isDrinkDish(_ dish: Dish) -> Bool {
        switch (dish.dishType ?? "").lowercased() {
        case "drink", "cocktail", "beverage", "wine", "beer": return true
        default: return false
        }
    }

    /// Combined display tags: vibe + occasion + dietary, de-duplicated.
    var displayTags: [String] {
        var seen = Set<String>()
        return (vibeTags + occasionTags + dietaryTags).filter { seen.insert($0).inserted }
    }

    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct SocialLink: Identifiable, Hashable {
    let platform: String   // instagram | x | facebook
    let url: String
    var id: String { platform }
}

extension Restaurant {
    /// Direct social profile if known, else a reliable web search for the
    /// restaurant on that platform (we never fabricate handles).
    var socialLinks: [SocialLink] {
        func search(_ platformQuery: String) -> String {
            let q = "\(name) \(neighborhood) NYC \(platformQuery)"
            let enc = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
            return "https://www.google.com/search?q=\(enc)"
        }
        return [
            SocialLink(platform: "instagram", url: instagramUrl ?? search("instagram")),
            SocialLink(platform: "x", url: xUrl ?? search("x twitter")),
            SocialLink(platform: "facebook", url: facebookUrl ?? search("facebook")),
        ]
    }
}

struct SimilarRestaurant: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    var neighborhood: String?
    var borough: String?
    var priceTier: Int?
    var rating: Double?
    var heroImageUrl: String?
    var cuisineTags: [String]?
    var vibeTags: [String]?

    /// A couple of representative tags (cuisine first, then vibe).
    var previewTags: [String] {
        let cuisine = (cuisineTags ?? []).prefix(1)
        let vibe = (vibeTags ?? []).prefix(2)
        return Array(cuisine) + Array(vibe)
    }
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
