import Foundation

/// Navigation route to a restaurant detail screen (by slug).
struct RestaurantRoute: Hashable {
    let slug: String
}

/// Navigation route to AI search results for a free-text query.
struct SearchRoute: Hashable {
    let query: String
}

/// Home prompt chips ("What are you looking for?").
enum HomePrompts {
    static let chips: [(label: String, icon: String)] = [
        ("Date night", "heart"),
        ("Cozy cafe", "cup.and.saucer"),
        ("Birthday dinner", "gift"),
        ("Rooftop", "building.2"),
        ("Walk-in friendly", "figure.walk"),
        ("Best pizza", "flame"),
        ("Best ramen", "takeoutbag.and.cup.and.straw"),
        ("Under $50", "dollarsign.circle"),
        ("Open late", "moon.stars"),
    ]
}
