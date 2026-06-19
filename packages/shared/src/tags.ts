/**
 * NYC-native taxonomy: vibe tags, occasion tags, dietary tags, NYC-specific
 * filters, and the curated "vibe category" presets. These power both the admin
 * tag pickers and the AI search filter extraction.
 */

export const VIBE_TAGS = [
  "cozy",
  "aesthetic",
  "stylish",
  "quiet",
  "romantic",
  "lively",
  "trendy",
  "intimate",
  "casual",
  "upscale",
  "rooftop",
  "waterfront",
  "outdoor_seating",
  "great_cocktails",
  "good_wine_list",
  "dim_lighting",
  "instagrammable",
  "tiktok_popular",
  "hidden_gem",
  "michelin_style",
  "late_night",
  "good_for_working",
  "dessert_spot",
] as const;

export const OCCASION_TAGS = [
  "date_night",
  "first_date",
  "birthday",
  "solo_dining",
  "groups",
  "work_cafe",
  "visitor_dinner",
  "anniversary",
  "business_meal",
  "brunch",
] as const;

export const DIETARY_TAGS = [
  "vegetarian",
  "vegan",
  "gluten_free",
  "halal",
  "kosher",
  "dairy_free",
  "nut_free",
] as const;

/** Boolean "good for" facets that map to dedicated columns on `restaurants`. */
export const GOOD_FOR = [
  "date",
  "birthday",
  "solo_dining",
  "groups",
  "work_cafe",
  "visitor_dinner",
] as const;

/**
 * NYC-specific filters surfaced in the Explore screen. Some map to boolean
 * columns, some to tag membership, and some to derived signals.
 */
export const NYC_FILTERS = [
  "borough",
  "neighborhood",
  "subway_friendly",
  "open_late",
  "outdoor_seating",
  "date_night",
  "quiet_enough_to_talk",
  "walk_in_friendly",
  "hard_reservation",
  "good_for_visitors",
  "best_under_25",
  "best_under_50",
  "rooftop",
  "cocktails",
  "aesthetic_interiors",
  "tiktok_popular",
  "hidden_gem",
  "michelin_style",
  "cafe_work_spot",
  "dessert_after_dinner",
] as const;

/** Curated NYC "vibe category" presets used as home/explore prompt chips. */
export const VIBE_CATEGORIES = [
  { id: "west_village_date_night", label: "West Village date night", neighborhood: "West Village" },
  { id: "soho_aesthetic_cafe", label: "SoHo aesthetic cafe", neighborhood: "SoHo" },
  { id: "east_village_casual_dinner", label: "East Village casual dinner", neighborhood: "East Village" },
  { id: "williamsburg_trendy", label: "Williamsburg trendy", neighborhood: "Williamsburg" },
  { id: "greenpoint_cozy", label: "Greenpoint cozy", neighborhood: "Greenpoint" },
  { id: "flushing_must_eat", label: "Flushing must-eat", neighborhood: "Flushing" },
  { id: "les_late_night", label: "LES late night", neighborhood: "Lower East Side" },
  { id: "tribeca_upscale", label: "Tribeca upscale", neighborhood: "Tribeca" },
  { id: "chelsea_gallery_day", label: "Chelsea gallery day", neighborhood: "Chelsea" },
  { id: "dumbo_waterfront", label: "Dumbo waterfront", neighborhood: "Dumbo" },
  { id: "astoria_group_dinner", label: "Astoria group dinner", neighborhood: "Astoria" },
  { id: "jackson_heights_food_crawl", label: "Jackson Heights food crawl", neighborhood: "Jackson Heights" },
] as const;

export type VibeTag = (typeof VIBE_TAGS)[number];
export type OccasionTag = (typeof OCCASION_TAGS)[number];
export type DietaryTag = (typeof DIETARY_TAGS)[number];
export type GoodFor = (typeof GOOD_FOR)[number];
export type NycFilter = (typeof NYC_FILTERS)[number];

export const PRICE_TIERS = [
  { tier: 1, label: "$", hint: "Under $25" },
  { tier: 2, label: "$$", hint: "Under $50" },
  { tier: 3, label: "$$$", hint: "Under $100" },
  { tier: 4, label: "$$$$", hint: "Splurge" },
] as const;

export type PriceTier = 1 | 2 | 3 | 4;

/** Maps a casual budget word (used by AI extraction) to a price-tier ceiling. */
export const BUDGET_TO_MAX_TIER: Record<string, PriceTier> = {
  cheap: 1,
  budget: 1,
  affordable: 2,
  moderate: 3,
  upscale: 4,
  splurge: 4,
  any: 4,
};
