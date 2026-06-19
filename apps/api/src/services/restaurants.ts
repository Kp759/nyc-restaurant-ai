import type { RestaurantDetail } from "@bitenyc/shared";
import { supabase } from "../supabase.js";

const DETAIL_SELECT =
  "*, dishes(*), media:media_items(*)";

export interface ListParams {
  borough?: string;
  neighborhood?: string;
  maxPriceTier?: number;
  vibe?: string[];
  occasion?: string[];
  cuisine?: string[];
  openNow?: boolean;
  reservationAvailable?: boolean;
  limit: number;
  offset: number;
}

/** Public list of published restaurants with hard filters + pagination. */
export async function listRestaurants(params: ListParams): Promise<RestaurantDetail[]> {
  let query = supabase
    .from("restaurants")
    .select(DETAIL_SELECT)
    .eq("status", "published")
    .order("popularity_score", { ascending: false })
    .range(params.offset, params.offset + params.limit - 1);

  if (params.borough) query = query.eq("borough", params.borough);
  if (params.neighborhood) query = query.eq("neighborhood", params.neighborhood);
  if (params.maxPriceTier) query = query.lte("price_tier", params.maxPriceTier);
  if (params.vibe?.length) query = query.overlaps("vibe_tags", params.vibe);
  if (params.occasion?.length) query = query.overlaps("occasion_tags", params.occasion);
  if (params.cuisine?.length) query = query.overlaps("cuisine_tags", params.cuisine);
  if (params.openNow) query = query.eq("is_open_late", true);
  if (params.reservationAvailable) {
    query = query.or(
      "resy_url.not.is.null,opentable_id.not.is.null,tock_url.not.is.null,direct_booking_url.not.is.null",
    );
  }

  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []).map(normalizeDetail);
}

export async function getRestaurantBySlug(slug: string): Promise<RestaurantDetail | null> {
  const { data, error } = await supabase
    .from("restaurants")
    .select(DETAIL_SELECT)
    .eq("status", "published")
    .eq("slug", slug)
    .maybeSingle();
  if (error) throw error;
  return data ? normalizeDetail(data) : null;
}

export async function getRestaurantsByIds(ids: string[]): Promise<RestaurantDetail[]> {
  if (ids.length === 0) return [];
  const { data, error } = await supabase
    .from("restaurants")
    .select(DETAIL_SELECT)
    .eq("status", "published")
    .in("id", ids);
  if (error) throw error;
  return (data ?? []).map(normalizeDetail);
}

/** Similar published places: same neighborhood (fallback borough), excluding self. */
export async function getSimilarRestaurants(
  restaurant: RestaurantDetail,
  limit = 4,
): Promise<RestaurantDetail[]> {
  const { data, error } = await supabase
    .from("restaurants")
    .select(DETAIL_SELECT)
    .eq("status", "published")
    .eq("neighborhood", restaurant.neighborhood)
    .neq("id", restaurant.id)
    .order("popularity_score", { ascending: false })
    .limit(limit);
  if (error) throw error;
  return (data ?? []).map(normalizeDetail);
}

/** Keep only approved media in public payloads and sort dishes by rank. */
function normalizeDetail(row: any): RestaurantDetail {
  const media = (row.media ?? []).filter(
    (m: any) => m.moderation_status === "approved",
  );
  const dishes = (row.dishes ?? []).sort(
    (a: any, b: any) => (a.rank ?? 0) - (b.rank ?? 0),
  );
  return { ...row, media, dishes } as RestaurantDetail;
}
