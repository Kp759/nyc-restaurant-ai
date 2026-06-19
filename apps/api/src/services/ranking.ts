import type { RestaurantDetail, ScoreBreakdown, SearchFilters } from "@bitenyc/shared";
import { hasReservation } from "./booking.js";

/** Weights for the BiteNYC ranking formula (must sum to 1.0). */
export const WEIGHTS = {
  semantic_similarity: 0.25,
  vibe_match: 0.2,
  neighborhood_match: 0.15,
  dish_quality: 0.1,
  editorial_score: 0.1,
  review_sentiment: 0.08,
  reservation_available: 0.05,
  media_quality: 0.04,
  health_grade_signal: 0.03,
} as const;

const clamp01 = (n: number) => Math.max(0, Math.min(1, n));

function vibeMatch(restaurant: RestaurantDetail, filters: SearchFilters): number {
  const wanted = new Set<string>([
    ...filters.vibe.map((v) => v.toLowerCase()),
    ...(filters.occasion ? [filters.occasion.toLowerCase()] : []),
  ]);
  if (wanted.size === 0) return 0.5; // neutral when the user expressed no vibe
  const have = new Set<string>([
    ...restaurant.vibe_tags.map((t) => t.toLowerCase()),
    ...restaurant.occasion_tags.map((t) => t.toLowerCase()),
  ]);
  let hits = 0;
  for (const w of wanted) if (have.has(w)) hits += 1;
  return clamp01(hits / wanted.size);
}

function neighborhoodMatch(restaurant: RestaurantDetail, filters: SearchFilters): number {
  if (filters.neighborhood) {
    if (restaurant.neighborhood.toLowerCase() === filters.neighborhood.toLowerCase()) return 1;
    if (filters.borough && restaurant.borough === filters.borough) return 0.4;
    return 0;
  }
  if (filters.borough) return restaurant.borough === filters.borough ? 1 : 0;
  return 0.5; // no geo preference
}

function dishQuality(restaurant: RestaurantDetail): number {
  const dishes = restaurant.dishes ?? [];
  if (dishes.length === 0) return 0;
  const mustTry = dishes.filter((d) => d.is_must_try).length;
  // Reward having must-try dishes plus a baseline for any documented dishes.
  return clamp01(0.4 + 0.2 * Math.min(mustTry, 3));
}

function reviewSentiment(restaurant: RestaurantDetail): number {
  const rating = restaurant.rating ?? 0;
  const base = rating / 5;
  // confidence factor: ramps toward full weight by ~200 reviews
  const confidence = clamp01((restaurant.review_count ?? 0) / 200);
  return clamp01(base * (0.6 + 0.4 * confidence));
}

function mediaQuality(restaurant: RestaurantDetail): number {
  const media = restaurant.media ?? [];
  const approved = media.filter((m) => m.moderation_status === "approved");
  const hasPhoto = approved.some((m) => m.media_type === "photo");
  const hasClip = approved.some((m) => m.media_type === "video" || m.media_type === "embed");
  return clamp01((hasPhoto ? 0.5 : 0) + (hasClip ? 0.5 : 0));
}

function healthGradeSignal(restaurant: RestaurantDetail): number {
  switch ((restaurant.health_grade ?? "").toUpperCase()) {
    case "A":
      return 1;
    case "B":
      return 0.6;
    case "C":
      return 0.3;
    default:
      return 0.5; // unknown / not yet matched -> neutral
  }
}

function reservationScore(restaurant: RestaurantDetail, filters: SearchFilters): number {
  const has = hasReservation(restaurant);
  if (filters.reservation_available) return has ? 1 : 0;
  return has ? 0.7 : 0.4; // mild preference for bookable places
}

/**
 * Scores a candidate restaurant. `semanticSimilarity` is the cosine similarity
 * (0-1) returned by match_restaurant_embeddings.
 */
export function scoreRestaurant(
  restaurant: RestaurantDetail,
  filters: SearchFilters,
  semanticSimilarity: number,
): ScoreBreakdown {
  const components = {
    semantic_similarity: clamp01(semanticSimilarity),
    vibe_match: vibeMatch(restaurant, filters),
    neighborhood_match: neighborhoodMatch(restaurant, filters),
    dish_quality: dishQuality(restaurant),
    editorial_score: clamp01((restaurant.editorial_score ?? 0) / 100),
    review_sentiment: reviewSentiment(restaurant),
    reservation_available: reservationScore(restaurant, filters),
    media_quality: mediaQuality(restaurant),
    health_grade_signal: healthGradeSignal(restaurant),
  };

  const final_score = (Object.keys(WEIGHTS) as Array<keyof typeof WEIGHTS>).reduce(
    (sum, key) => sum + WEIGHTS[key] * components[key],
    0,
  );

  return { ...components, final_score };
}
