/**
 * Enriches restaurants with Yelp Fusion data: matches a business, then pulls
 * details (price, rating, photos) and up to 3 review excerpts. Photos are added
 * as pending media; review excerpts are saved as a review_summary embedding
 * source row (content only; embeddings are generated separately).
 * Idempotent: only processes restaurants without a yelp_business_id.
 *
 * Usage: pnpm --filter @bitenyc/scripts match:yelp
 * Requires: YELP_API_KEY
 */
import { getServiceClient, scriptEnv } from "./lib/env.js";

const BATCH = 50;

async function yelp(path: string): Promise<any> {
  const res = await fetch(`https://api.yelp.com/v3${path}`, {
    headers: { Authorization: `Bearer ${scriptEnv.yelpApiKey}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Yelp error ${res.status}: ${await res.text()}`);
  return res.json();
}

function priceToTier(price?: string): number | null {
  if (!price) return null;
  return price.length >= 1 && price.length <= 4 ? price.length : null;
}

async function main() {
  if (!scriptEnv.yelpApiKey) {
    console.error("YELP_API_KEY is not set.");
    process.exit(1);
  }
  const supabase = getServiceClient();

  const { data: restaurants, error } = await supabase
    .from("restaurants")
    .select("id, name, address, neighborhood, rating, price_tier")
    .is("yelp_business_id", null)
    .limit(BATCH);
  if (error) throw error;

  let matched = 0;
  for (const r of restaurants ?? []) {
    const params = new URLSearchParams({
      name: r.name,
      address1: r.address ?? "",
      city: "New York",
      state: "NY",
      country: "US",
    });
    const match = await yelp(`/businesses/matches?${params.toString()}`);
    const business = match?.businesses?.[0];
    if (!business) {
      console.log(`  ? no match: ${r.name}`);
      continue;
    }

    const details = await yelp(`/businesses/${business.id}`);
    const reviews = await yelp(`/businesses/${business.id}/reviews?limit=3&sort_by=yelp_sort`);

    await supabase
      .from("restaurants")
      .update({
        yelp_business_id: business.id,
        rating: r.rating ?? details?.rating ?? null,
        review_count: details?.review_count ?? undefined,
        price_tier: r.price_tier ?? priceToTier(details?.price),
      })
      .eq("id", r.id);

    // Add up to 3 Yelp photos as pending, licensed media.
    const photos: string[] = details?.photos ?? [];
    for (const url of photos.slice(0, 3)) {
      await supabase.from("media_items").insert({
        restaurant_id: r.id,
        media_type: "photo",
        source: "licensed_api",
        url,
        rights_status: "licensed",
        moderation_status: "pending",
      });
    }

    // Save review excerpts as embedding source content.
    const excerpts: string[] = (reviews?.reviews ?? [])
      .map((rev: any) => rev.text as string)
      .filter(Boolean);
    if (excerpts.length) {
      await supabase.from("restaurant_embeddings").insert({
        restaurant_id: r.id,
        content_type: "review_summary",
        content: excerpts.join(" \n "),
        embedding: null,
      });
    }

    matched += 1;
    console.log(`  + ${r.name} -> ${business.id}`);
  }

  console.log(`\nDone. Matched ${matched}/${(restaurants ?? []).length}.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
