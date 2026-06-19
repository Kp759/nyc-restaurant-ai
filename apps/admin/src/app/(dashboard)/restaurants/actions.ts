"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { BOROUGHS } from "@bitenyc/shared";
import { requireAdmin } from "@/lib/auth";
import { createServiceClient } from "@/lib/supabase/service";
import { adminEnv } from "@/lib/env";

function slugify(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function str(form: FormData, key: string): string | null {
  const v = form.get(key);
  const s = typeof v === "string" ? v.trim() : "";
  return s.length ? s : null;
}

function num(form: FormData, key: string): number | null {
  const s = str(form, key);
  if (s === null) return null;
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}

function bool(form: FormData, key: string): boolean {
  return form.get(key) === "on" || form.get(key) === "true";
}

function tags(form: FormData, key: string): string[] {
  const s = str(form, key);
  if (!s) return [];
  return s
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean);
}

function restaurantPayload(form: FormData) {
  const borough = str(form, "borough") ?? "Manhattan";
  return {
    name: str(form, "name") ?? "Untitled",
    description: str(form, "description"),
    editorial_summary: str(form, "editorial_summary"),
    address: str(form, "address") ?? "",
    neighborhood: str(form, "neighborhood") ?? "",
    borough: (BOROUGHS as readonly string[]).includes(borough) ? borough : "Manhattan",
    latitude: num(form, "latitude") ?? 0,
    longitude: num(form, "longitude") ?? 0,
    cuisine_tags: tags(form, "cuisine_tags"),
    vibe_tags: tags(form, "vibe_tags"),
    occasion_tags: tags(form, "occasion_tags"),
    dietary_tags: tags(form, "dietary_tags"),
    price_tier: num(form, "price_tier"),
    rating: num(form, "rating"),
    review_count: num(form, "review_count") ?? 0,
    google_place_id: str(form, "google_place_id"),
    yelp_business_id: str(form, "yelp_business_id"),
    opentable_id: str(form, "opentable_id"),
    resy_url: str(form, "resy_url"),
    tock_url: str(form, "tock_url"),
    direct_booking_url: str(form, "direct_booking_url"),
    health_grade: str(form, "health_grade"),
    health_grade_date: str(form, "health_grade_date"),
    health_inspection_score: num(form, "health_inspection_score"),
    is_walk_in_friendly: bool(form, "is_walk_in_friendly"),
    is_good_for_date: bool(form, "is_good_for_date"),
    is_good_for_groups: bool(form, "is_good_for_groups"),
    is_good_for_working: bool(form, "is_good_for_working"),
    is_open_late: bool(form, "is_open_late"),
    is_tourist_friendly: bool(form, "is_tourist_friendly"),
    editorial_score: num(form, "editorial_score") ?? 0,
    popularity_score: num(form, "popularity_score") ?? 0,
  };
}

export async function createRestaurant(formData: FormData) {
  await requireAdmin();
  const service = createServiceClient();
  const payload = restaurantPayload(formData);
  const slug = slugify(str(formData, "slug") ?? payload.name) || `restaurant-${Date.now()}`;

  const { data, error } = await service
    .from("restaurants")
    .insert({ ...payload, slug, status: "draft" })
    .select("id")
    .single();
  if (error) throw new Error(error.message);

  revalidatePath("/restaurants");
  redirect(`/restaurants/${data.id}`);
}

export async function updateRestaurant(id: string, formData: FormData) {
  await requireAdmin();
  const service = createServiceClient();
  const payload = restaurantPayload(formData);
  const slug = str(formData, "slug");

  const { error } = await service
    .from("restaurants")
    .update({ ...payload, ...(slug ? { slug: slugify(slug) } : {}) })
    .eq("id", id);
  if (error) throw new Error(error.message);

  revalidatePath(`/restaurants/${id}`);
  revalidatePath("/restaurants");
}

export async function setStatus(id: string, status: "draft" | "published" | "archived") {
  await requireAdmin();
  const service = createServiceClient();
  const { error } = await service.from("restaurants").update({ status }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(`/restaurants/${id}`);
  revalidatePath("/restaurants");
}

export async function deleteRestaurant(id: string) {
  await requireAdmin();
  const service = createServiceClient();
  const { error } = await service.from("restaurants").delete().eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/restaurants");
  redirect("/restaurants");
}

export async function addDish(restaurantId: string, formData: FormData) {
  await requireAdmin();
  const service = createServiceClient();
  const { error } = await service.from("dishes").insert({
    restaurant_id: restaurantId,
    name: str(formData, "name") ?? "Dish",
    description: str(formData, "description"),
    why_try: str(formData, "why_try"),
    dish_type: str(formData, "dish_type"),
    tags: tags(formData, "tags"),
    is_must_try: bool(formData, "is_must_try"),
    rank: num(formData, "rank") ?? 0,
    photo_url: str(formData, "photo_url"),
  });
  if (error) throw new Error(error.message);
  revalidatePath(`/restaurants/${restaurantId}`);
}

export async function deleteDish(id: string, restaurantId: string) {
  await requireAdmin();
  const service = createServiceClient();
  const { error } = await service.from("dishes").delete().eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(`/restaurants/${restaurantId}`);
}

export async function addMedia(restaurantId: string, formData: FormData) {
  await requireAdmin();
  const service = createServiceClient();
  const { error } = await service.from("media_items").insert({
    restaurant_id: restaurantId,
    media_type: str(formData, "media_type") ?? "photo",
    source: str(formData, "source") ?? "restaurant",
    url: str(formData, "url") ?? "",
    thumbnail_url: str(formData, "thumbnail_url"),
    caption: str(formData, "caption"),
    transcript: str(formData, "transcript"),
    creator_name: str(formData, "creator_name"),
    creator_url: str(formData, "creator_url"),
    rights_status: str(formData, "rights_status") ?? "unknown",
    moderation_status: str(formData, "moderation_status") ?? "pending",
  });
  if (error) throw new Error(error.message);
  revalidatePath(`/restaurants/${restaurantId}`);
}

export async function setMediaModeration(
  id: string,
  restaurantId: string,
  status: "pending" | "approved" | "rejected",
) {
  await requireAdmin();
  const service = createServiceClient();
  const { error } = await service
    .from("media_items")
    .update({ moderation_status: status })
    .eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(`/restaurants/${restaurantId}`);
}

export async function deleteMedia(id: string, restaurantId: string) {
  await requireAdmin();
  const service = createServiceClient();
  const { error } = await service.from("media_items").delete().eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath(`/restaurants/${restaurantId}`);
}

/** Calls the API admin endpoint to (re)generate embeddings for a restaurant. */
export async function generateEmbeddings(id: string) {
  await requireAdmin();
  const res = await fetch(`${adminEnv.apiBaseUrl}/admin/restaurants/${id}/embeddings`, {
    method: "POST",
    headers: { "x-service-key": adminEnv.supabaseServiceRoleKey },
    cache: "no-store",
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error ?? `Embedding generation failed (${res.status})`);
  }
  revalidatePath(`/restaurants/${id}`);
}
