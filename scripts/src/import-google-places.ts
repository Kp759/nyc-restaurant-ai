/**
 * Imports candidate restaurants from the Google Places API (Text Search, new
 * v1 endpoint) for the MVP 1 launch area, writing them as `status='draft'`.
 * Idempotent: dedupes on google_place_id (skips rows that already exist).
 *
 * Usage: pnpm --filter @bitenyc/scripts import:places
 * Requires: GOOGLE_PLACES_API_KEY
 */
import { NEIGHBORHOODS } from "@bitenyc/shared";
import { getServiceClient, scriptEnv } from "./lib/env.js";

const TEXT_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText";
const FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.location",
  "places.priceLevel",
  "places.rating",
  "places.userRatingCount",
  "places.primaryTypeDisplayName",
  "places.editorialSummary",
].join(",");

const PRICE_LEVEL_MAP: Record<string, number> = {
  PRICE_LEVEL_INEXPENSIVE: 1,
  PRICE_LEVEL_MODERATE: 2,
  PRICE_LEVEL_EXPENSIVE: 3,
  PRICE_LEVEL_VERY_EXPENSIVE: 4,
};

function slugify(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

async function textSearch(query: string) {
  const res = await fetch(TEXT_SEARCH_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": scriptEnv.googlePlacesApiKey,
      "X-Goog-FieldMask": FIELD_MASK,
    },
    body: JSON.stringify({ textQuery: query, includedType: "restaurant", maxResultCount: 20 }),
  });
  if (!res.ok) {
    throw new Error(`Google Places error ${res.status}: ${await res.text()}`);
  }
  const json = (await res.json()) as { places?: any[] };
  return json.places ?? [];
}

async function main() {
  if (!scriptEnv.googlePlacesApiKey) {
    console.error("GOOGLE_PLACES_API_KEY is not set.");
    process.exit(1);
  }
  const supabase = getServiceClient();
  const phase1 = NEIGHBORHOODS.filter((n) => n.mvpPhase === 1);

  let inserted = 0;
  let skipped = 0;

  for (const hood of phase1) {
    const query = `restaurants and cafes in ${hood.name}, ${hood.borough}, New York City`;
    console.log(`\nSearching: ${query}`);
    let places: any[] = [];
    try {
      places = await textSearch(query);
    } catch (err) {
      console.error((err as Error).message);
      continue;
    }

    for (const p of places) {
      const placeId = p.id as string;
      const { data: existing } = await supabase
        .from("restaurants")
        .select("id")
        .eq("google_place_id", placeId)
        .maybeSingle();
      if (existing) {
        skipped += 1;
        continue;
      }

      const name = p.displayName?.text ?? "Unknown";
      const baseSlug = slugify(`${name}-${hood.name}`);
      const row = {
        name,
        slug: `${baseSlug}-${placeId.slice(-6)}`,
        address: p.formattedAddress ?? "",
        neighborhood: hood.name,
        borough: hood.borough,
        latitude: p.location?.latitude ?? 0,
        longitude: p.location?.longitude ?? 0,
        cuisine_tags: p.primaryTypeDisplayName?.text
          ? [slugify(p.primaryTypeDisplayName.text)]
          : [],
        price_tier: p.priceLevel ? PRICE_LEVEL_MAP[p.priceLevel] ?? null : null,
        rating: p.rating ?? null,
        review_count: p.userRatingCount ?? 0,
        editorial_summary: p.editorialSummary?.text ?? null,
        google_place_id: placeId,
        status: "draft" as const,
      };

      const { error } = await supabase.from("restaurants").insert(row);
      if (error) {
        console.error(`  ! ${name}: ${error.message}`);
        continue;
      }
      inserted += 1;
      console.log(`  + ${name}`);
    }
  }

  console.log(`\nDone. Inserted ${inserted} drafts, skipped ${skipped} existing.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
