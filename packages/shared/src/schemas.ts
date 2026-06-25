import { z } from "zod";
import { BOROUGHS } from "./boroughs.js";

// ---------------------------------------------------------------------------
// Enums shared with the database check constraints
// ---------------------------------------------------------------------------

export const boroughSchema = z.enum(BOROUGHS);
export const restaurantStatusSchema = z.enum(["draft", "published", "archived"]);
export const mediaTypeSchema = z.enum(["photo", "video", "embed"]);
export const mediaSourceSchema = z.enum([
  "own_upload",
  "restaurant",
  "creator",
  "tiktok",
  "youtube",
  "instagram",
  "licensed_api",
]);
export const rightsStatusSchema = z.enum(["owned", "licensed", "embedded", "unknown"]);
export const moderationStatusSchema = z.enum(["pending", "approved", "rejected"]);
export const embeddingContentTypeSchema = z.enum([
  "restaurant_profile",
  "dish",
  "review_summary",
  "video_transcript",
  "editorial_note",
]);

// ---------------------------------------------------------------------------
// Core entities
// ---------------------------------------------------------------------------

export const dishSchema = z.object({
  id: z.string().uuid(),
  restaurant_id: z.string().uuid(),
  name: z.string().min(1),
  description: z.string().nullable().optional(),
  why_try: z.string().nullable().optional(),
  dish_type: z.string().nullable().optional(),
  tags: z.array(z.string()).default([]),
  is_must_try: z.boolean().default(false),
  rank: z.number().int().default(0),
  photo_url: z.string().url().nullable().optional(),
  created_at: z.string().optional(),
});

export const mediaItemSchema = z.object({
  id: z.string().uuid(),
  restaurant_id: z.string().uuid(),
  dish_id: z.string().uuid().nullable().optional(),
  media_type: mediaTypeSchema,
  source: mediaSourceSchema,
  url: z.string().url(),
  thumbnail_url: z.string().url().nullable().optional(),
  caption: z.string().nullable().optional(),
  transcript: z.string().nullable().optional(),
  creator_name: z.string().nullable().optional(),
  creator_url: z.string().url().nullable().optional(),
  rights_status: rightsStatusSchema.default("unknown"),
  moderation_status: moderationStatusSchema.default("pending"),
  created_at: z.string().optional(),
});

export const restaurantSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  slug: z.string().min(1),
  description: z.string().nullable().optional(),
  editorial_summary: z.string().nullable().optional(),
  address: z.string().min(1),
  neighborhood: z.string().min(1),
  borough: boroughSchema,
  city: z.string().default("New York"),
  state: z.string().default("NY"),
  country: z.string().default("USA"),
  latitude: z.number(),
  longitude: z.number(),
  cuisine_tags: z.array(z.string()).default([]),
  vibe_tags: z.array(z.string()).default([]),
  occasion_tags: z.array(z.string()).default([]),
  dietary_tags: z.array(z.string()).default([]),
  price_tier: z.number().int().min(1).max(4).nullable().optional(),
  rating: z.number().min(0).max(5).nullable().optional(),
  review_count: z.number().int().default(0),
  google_place_id: z.string().nullable().optional(),
  yelp_business_id: z.string().nullable().optional(),
  opentable_id: z.string().nullable().optional(),
  resy_url: z.string().url().nullable().optional(),
  tock_url: z.string().url().nullable().optional(),
  direct_booking_url: z.string().url().nullable().optional(),
  instagram_url: z.string().url().nullable().optional(),
  x_url: z.string().url().nullable().optional(),
  facebook_url: z.string().url().nullable().optional(),
  health_grade: z.string().nullable().optional(),
  health_grade_date: z.string().nullable().optional(),
  health_inspection_score: z.number().int().nullable().optional(),
  is_walk_in_friendly: z.boolean().default(false),
  is_good_for_date: z.boolean().default(false),
  is_good_for_groups: z.boolean().default(false),
  is_good_for_working: z.boolean().default(false),
  is_open_late: z.boolean().default(false),
  is_tourist_friendly: z.boolean().default(false),
  popularity_score: z.number().default(0),
  editorial_score: z.number().default(0),
  status: restaurantStatusSchema.default("draft"),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
});

export type Dish = z.infer<typeof dishSchema>;
export type MediaItem = z.infer<typeof mediaItemSchema>;
export type Restaurant = z.infer<typeof restaurantSchema>;

/** Restaurant with its nested dishes + media (detail endpoint payload). */
export const restaurantDetailSchema = restaurantSchema.extend({
  dishes: z.array(dishSchema).default([]),
  media: z.array(mediaItemSchema).default([]),
});
export type RestaurantDetail = z.infer<typeof restaurantDetailSchema>;

// ---------------------------------------------------------------------------
// Booking
// ---------------------------------------------------------------------------

/** Provider order matters: Resy -> OpenTable -> Tock -> SevenRooms -> Direct -> Phone. */
export const bookingLinkSchema = z.object({
  provider: z.enum(["resy", "opentable", "tock", "sevenrooms", "direct", "phone"]),
  label: z.string(),
  url: z.string(),
});
export type BookingLink = z.infer<typeof bookingLinkSchema>;

// ---------------------------------------------------------------------------
// Search + AI contracts
// ---------------------------------------------------------------------------

/** Structured filters the model extracts from a natural-language NYC query. */
export const searchFiltersSchema = z.object({
  city: z.literal("New York").default("New York"),
  borough: boroughSchema.nullable().optional(),
  neighborhood: z.string().nullable().optional(),
  occasion: z.string().nullable().optional(),
  vibe: z.array(z.string()).default([]),
  cuisine: z.array(z.string()).default([]),
  budget: z
    .enum(["cheap", "budget", "affordable", "moderate", "upscale", "splurge", "any"])
    .default("any"),
  max_price_tier: z.number().int().min(1).max(4).nullable().optional(),
  party_size: z.number().int().min(1).default(2),
  open_now: z.boolean().default(false),
  reservation_available: z.boolean().default(false),
});
export type SearchFilters = z.infer<typeof searchFiltersSchema>;

export const searchRequestSchema = z.object({
  query: z.string().min(1),
  /** Optional pre-set filters from UI chips that override extraction. */
  filters: searchFiltersSchema.partial().optional(),
  limit: z.number().int().min(1).max(25).default(5),
});
export type SearchRequest = z.infer<typeof searchRequestSchema>;

/** Per-component ranking breakdown for transparency/debugging. */
export const scoreBreakdownSchema = z.object({
  semantic_similarity: z.number(),
  vibe_match: z.number(),
  neighborhood_match: z.number(),
  dish_quality: z.number(),
  editorial_score: z.number(),
  review_sentiment: z.number(),
  reservation_available: z.number(),
  media_quality: z.number(),
  health_grade_signal: z.number(),
  final_score: z.number(),
});
export type ScoreBreakdown = z.infer<typeof scoreBreakdownSchema>;

export const searchResultSchema = z.object({
  restaurant: restaurantDetailSchema,
  why_it_fits: z.string().optional(),
  booking_links: z.array(bookingLinkSchema).default([]),
  score: scoreBreakdownSchema,
});
export type SearchResult = z.infer<typeof searchResultSchema>;

export const searchResponseSchema = z.object({
  query: z.string(),
  filters: searchFiltersSchema,
  results: z.array(searchResultSchema),
});
export type SearchResponse = z.infer<typeof searchResponseSchema>;

export const chatRequestSchema = z.object({
  message: z.string().min(1),
  history: z
    .array(z.object({ role: z.enum(["user", "assistant"]), content: z.string() }))
    .default([]),
});
export type ChatRequest = z.infer<typeof chatRequestSchema>;

export const chatResponseSchema = z.object({
  reply: z.string(),
  results: z.array(searchResultSchema).default([]),
});
export type ChatResponse = z.infer<typeof chatResponseSchema>;

// ---------------------------------------------------------------------------
// Moderation (App Store Guideline 1.2)
// ---------------------------------------------------------------------------

export const contentReportSchema = z.object({
  target_type: z.enum(["restaurant", "media_item", "dish", "review"]),
  target_id: z.string().uuid(),
  reason: z.enum(["spam", "nsfw", "inaccurate", "abusive", "copyright", "other"]),
  details: z.string().max(2000).optional(),
  reporter_id: z.string().optional(),
});
export type ContentReport = z.infer<typeof contentReportSchema>;

export const takedownRequestSchema = z.object({
  restaurant_id: z.string().uuid(),
  requester_name: z.string().min(1),
  requester_email: z.string().email(),
  relationship: z.enum(["owner", "manager", "legal", "other"]),
  details: z.string().max(2000).optional(),
});
export type TakedownRequest = z.infer<typeof takedownRequestSchema>;
