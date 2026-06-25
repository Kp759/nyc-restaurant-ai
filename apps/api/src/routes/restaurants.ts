import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { buildBookingLinks } from "../services/booking.js";
import {
  getRestaurantBySlug,
  getSimilarRestaurants,
  listRestaurants,
} from "../services/restaurants.js";

const listQuerySchema = z.object({
  borough: z.string().optional(),
  neighborhood: z.string().optional(),
  max_price_tier: z.coerce.number().int().min(1).max(4).optional(),
  vibe: z.string().optional(),
  occasion: z.string().optional(),
  cuisine: z.string().optional(),
  open_now: z.coerce.boolean().optional(),
  reservation_available: z.coerce.boolean().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

const csv = (v?: string) =>
  v ? v.split(",").map((s) => s.trim()).filter(Boolean) : undefined;

export async function restaurantRoutes(app: FastifyInstance) {
  app.get("/restaurants", async (request, reply) => {
    const parsed = listQuerySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }
    const q = parsed.data;
    const restaurants = await listRestaurants({
      borough: q.borough,
      neighborhood: q.neighborhood,
      maxPriceTier: q.max_price_tier,
      vibe: csv(q.vibe),
      occasion: csv(q.occasion),
      cuisine: csv(q.cuisine),
      openNow: q.open_now,
      reservationAvailable: q.reservation_available,
      limit: q.limit,
      offset: q.offset,
    });

    return {
      count: restaurants.length,
      offset: q.offset,
      limit: q.limit,
      restaurants: restaurants.map((r) => ({
        ...r,
        booking_links: buildBookingLinks(r),
      })),
    };
  });

  app.get<{ Params: { slug: string } }>("/restaurants/:slug", async (request, reply) => {
    const restaurant = await getRestaurantBySlug(request.params.slug);
    if (!restaurant) {
      return reply.status(404).send({ error: "Restaurant not found" });
    }
    const similar = await getSimilarRestaurants(restaurant);
    return {
      ...restaurant,
      booking_links: buildBookingLinks(restaurant),
      similar: similar.map((s) => ({
        id: s.id,
        name: s.name,
        slug: s.slug,
        neighborhood: s.neighborhood,
        borough: s.borough,
        price_tier: s.price_tier,
        rating: s.rating,
        hero_image_url: heroImageUrl(s),
        cuisine_tags: s.cuisine_tags ?? [],
        vibe_tags: s.vibe_tags ?? [],
      })),
    };
  });
}

/** First approved photo (thumbnail preferred) for a compact card image. */
function heroImageUrl(r: any): string | null {
  const media = r.media ?? [];
  const photo = media.find((m: any) => m.media_type === "photo");
  if (photo) return photo.thumbnail_url ?? photo.url ?? null;
  const anyThumb = media.find((m: any) => m.thumbnail_url);
  return anyThumb?.thumbnail_url ?? null;
}
