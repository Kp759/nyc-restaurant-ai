import type {
  RestaurantDetail,
  SearchFilters,
  SearchResult,
} from "@bitenyc/shared";
import { aiEnabled } from "../env.js";
import { supabase } from "../supabase.js";
import { embedText } from "../openai.js";
import { extractFilters } from "./extract.js";
import { buildBookingLinks } from "./booking.js";
import { scoreRestaurant } from "./ranking.js";
import { getRestaurantsByIds, listRestaurants } from "./restaurants.js";

const CANDIDATE_POOL = 30;

export interface RunSearchOptions {
  query: string;
  overrides?: Partial<SearchFilters>;
  limit: number;
}

export interface RunSearchOutput {
  filters: SearchFilters;
  results: SearchResult[];
}

/**
 * The grounded BiteNYC search flow:
 *   1. extract structured filters (AI function calling or heuristic)
 *   2. retrieve candidates (pgvector similarity, or hard-filter fallback)
 *   3. re-rank with the weighted formula
 *   4. attach booking links
 * Recommendations only ever come from the database.
 */
export async function runSearch(opts: RunSearchOptions): Promise<RunSearchOutput> {
  const filters = await extractFilters(opts.query, opts.overrides);

  const candidates = aiEnabled
    ? await retrieveByVector(opts.query, filters)
    : await retrieveByFilters(filters);

  const results: SearchResult[] = candidates
    .map(({ restaurant, similarity }) => ({
      restaurant,
      booking_links: buildBookingLinks(restaurant),
      score: scoreRestaurant(restaurant, filters, similarity),
    }))
    .sort((a, b) => b.score.final_score - a.score.final_score)
    .slice(0, opts.limit);

  return { filters, results };
}

interface Candidate {
  restaurant: RestaurantDetail;
  similarity: number;
}

async function retrieveByVector(
  query: string,
  filters: SearchFilters,
): Promise<Candidate[]> {
  const embedding = await embedText(query);

  const { data, error } = await supabase.rpc("match_restaurant_embeddings", {
    query_embedding: embedding,
    match_count: CANDIDATE_POOL,
    filters: {
      borough: filters.borough ?? null,
      neighborhood: filters.neighborhood ?? null,
      max_price_tier: filters.max_price_tier ?? null,
      open_now: filters.open_now,
      reservation_available: filters.reservation_available,
    },
  });
  if (error) throw error;

  const rows = (data ?? []) as Array<{ restaurant_id: string; similarity: number }>;
  if (rows.length === 0) return retrieveByFilters(filters);

  const simById = new Map(rows.map((r) => [r.restaurant_id, r.similarity]));
  const restaurants = await getRestaurantsByIds(rows.map((r) => r.restaurant_id));
  return restaurants.map((restaurant) => ({
    restaurant,
    similarity: simById.get(restaurant.id) ?? 0,
  }));
}

/** Fallback when embeddings are unavailable: hard filters, neutral similarity. */
async function retrieveByFilters(filters: SearchFilters): Promise<Candidate[]> {
  const restaurants = await listRestaurants({
    borough: filters.borough ?? undefined,
    neighborhood: filters.neighborhood ?? undefined,
    maxPriceTier: filters.max_price_tier ?? undefined,
    vibe: filters.vibe,
    occasion: filters.occasion ? [filters.occasion] : undefined,
    cuisine: filters.cuisine,
    openNow: filters.open_now,
    reservationAvailable: filters.reservation_available,
    limit: CANDIDATE_POOL,
    offset: 0,
  });
  return restaurants.map((restaurant) => ({ restaurant, similarity: 0.5 }));
}
