import type { FastifyInstance } from "fastify";
import {
  BOROUGHS,
  DIETARY_TAGS,
  NYC_FILTERS,
  OCCASION_TAGS,
  PRICE_TIERS,
  VIBE_CATEGORIES,
  VIBE_TAGS,
} from "@bitenyc/shared";

/** Static filter metadata for client UIs (Explore filters + prompt chips). */
export async function filterRoutes(app: FastifyInstance) {
  app.get("/filters", async () => ({
    boroughs: BOROUGHS,
    vibe_tags: VIBE_TAGS,
    occasion_tags: OCCASION_TAGS,
    dietary_tags: DIETARY_TAGS,
    nyc_filters: NYC_FILTERS,
    price_tiers: PRICE_TIERS,
    vibe_categories: VIBE_CATEGORIES,
  }));
}
