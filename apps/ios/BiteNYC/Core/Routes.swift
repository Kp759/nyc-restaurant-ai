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

/// Bundled presets when `/filters` is unreachable (mirrors `VIBE_CATEGORIES` in shared).
enum HomeVibeCategories {
    static let fallback: [VibeCategory] = [
        VibeCategory(id: "west_village_date_night", label: "West Village date night", neighborhood: "West Village"),
        VibeCategory(id: "soho_aesthetic_cafe", label: "SoHo aesthetic cafe", neighborhood: "SoHo"),
        VibeCategory(id: "east_village_casual_dinner", label: "East Village casual dinner", neighborhood: "East Village"),
        VibeCategory(id: "williamsburg_trendy", label: "Williamsburg trendy", neighborhood: "Williamsburg"),
        VibeCategory(id: "greenpoint_cozy", label: "Greenpoint cozy", neighborhood: "Greenpoint"),
        VibeCategory(id: "flushing_must_eat", label: "Flushing must-eat", neighborhood: "Flushing"),
        VibeCategory(id: "les_late_night", label: "LES late night", neighborhood: "Lower East Side"),
        VibeCategory(id: "tribeca_upscale", label: "Tribeca upscale", neighborhood: "Tribeca"),
        VibeCategory(id: "chelsea_gallery_day", label: "Chelsea gallery day", neighborhood: "Chelsea"),
        VibeCategory(id: "dumbo_waterfront", label: "Dumbo waterfront", neighborhood: "Dumbo"),
        VibeCategory(id: "astoria_group_dinner", label: "Astoria group dinner", neighborhood: "Astoria"),
        VibeCategory(id: "jackson_heights_food_crawl", label: "Jackson Heights food crawl", neighborhood: "Jackson Heights"),
    ]
}
