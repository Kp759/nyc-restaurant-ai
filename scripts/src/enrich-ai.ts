/**
 * AI-enriches imported restaurants: generates NYC-native vibe/occasion/dietary
 * tags (constrained to the shared taxonomy), "good for" boolean facets, a short
 * editorial summary, and a curated menu of must-try + regular dishes.
 *
 * Uses OpenAI chat with JSON output, grounded only on the place's own factual
 * fields (name, neighborhood, cuisine, price, rating) - it does not invent
 * addresses or contact info. Generated dishes are representative suggestions.
 *
 * Usage: pnpm --filter @bitenyc/scripts enrich:ai [--all] [--force] [--limit N]
 *   default: published restaurants that aren't enriched yet
 *   --all:   include drafts/archived too
 *   --force: re-enrich even if tags/dishes already exist
 *   --limit: cap how many restaurants to process this run
 * Requires: OPENAI_API_KEY
 */
import OpenAI from "openai";
import { VIBE_TAGS, OCCASION_TAGS, DIETARY_TAGS } from "@bitenyc/shared";
import { getServiceClient, scriptEnv } from "./lib/env.js";

const VIBE = new Set<string>(VIBE_TAGS);
const OCCASION = new Set<string>(OCCASION_TAGS);
const DIETARY = new Set<string>(DIETARY_TAGS);

function argValue(flag: string): string | undefined {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

function onlyAllowed(values: unknown, allowed: Set<string>): string[] {
  if (!Array.isArray(values)) return [];
  return [...new Set(values.map(String).filter((v) => allowed.has(v)))];
}

function buildPrompt(r: any): string {
  const facts = [
    `Name: ${r.name}`,
    `Neighborhood: ${r.neighborhood}, ${r.borough}`,
    `Cuisine: ${(r.cuisine_tags ?? []).join(", ") || "unknown"}`,
    `Price tier (1-4): ${r.price_tier ?? "unknown"}`,
    `Rating: ${r.rating ?? "unknown"} (${r.review_count ?? 0} reviews)`,
    r.editorial_summary ? `Editorial: ${r.editorial_summary}` : "",
  ]
    .filter(Boolean)
    .join("\n");

  return `You are a NYC dining editor. Based ONLY on the factual details below, infer a tasteful, realistic profile for this restaurant. Do not invent addresses, phone numbers, or awards.

${facts}

Return STRICT JSON with this shape:
{
  "editorial_summary": "1-2 sentence editor's take on the vibe and who it's for",
  "vibe_tags": ["from this list only: ${VIBE_TAGS.join(", ")}"],
  "occasion_tags": ["from this list only: ${OCCASION_TAGS.join(", ")}"],
  "dietary_tags": ["from this list only: ${DIETARY_TAGS.join(", ")}"],
  "is_good_for_date": boolean,
  "is_good_for_groups": boolean,
  "is_good_for_working": boolean,
  "is_walk_in_friendly": boolean,
  "is_open_late": boolean,
  "is_tourist_friendly": boolean,
  "dishes": [
    { "name": "dish name", "description": "short menu description", "why_try": "why it's worth ordering", "dish_type": "appetizer|main|dessert|drink|small_plate", "is_must_try": boolean, "rank": 1 }
  ]
}

Rules:
- 4-8 vibe_tags, 1-4 occasion_tags, 0-3 dietary_tags. Use ONLY tags from the provided lists (snake_case, exact).
- Provide 6-8 dishes appropriate to the cuisine; mark 3-4 of them is_must_try=true and rank them 1..N (must-try first).
- Keep descriptions concise. Output JSON only.`;
}

async function main() {
  if (!scriptEnv.openaiApiKey || scriptEnv.openaiApiKey === "dummy") {
    console.error("OPENAI_API_KEY is not set to a real key.");
    process.exit(1);
  }
  const includeAll = process.argv.includes("--all");
  const force = process.argv.includes("--force");
  const limit = Number(argValue("--limit")) || Infinity;

  const supabase = getServiceClient();
  const openai = new OpenAI({ apiKey: scriptEnv.openaiApiKey });

  let query = supabase.from("restaurants").select("*, dishes(id), media:media_items(id)");
  if (!includeAll) query = query.eq("status", "published");
  const { data: restaurants, error } = await query;
  if (error) throw error;

  let enriched = 0;
  let skipped = 0;

  for (const r of restaurants ?? []) {
    if (enriched >= limit) break;

    const alreadyTagged = (r.vibe_tags ?? []).length > 0;
    const hasDishes = (r.dishes ?? []).length > 0;
    if (!force && alreadyTagged && hasDishes) {
      skipped += 1;
      continue;
    }

    let parsed: any;
    try {
      const res = await openai.chat.completions.create({
        model: scriptEnv.openaiChatModel,
        temperature: 0.7,
        response_format: { type: "json_object" },
        messages: [{ role: "user", content: buildPrompt(r) }],
      });
      parsed = JSON.parse(res.choices[0]?.message?.content ?? "{}");
    } catch (err) {
      console.error(`  ! ${r.name}: ${(err as Error).message}`);
      continue;
    }

    const vibe_tags = onlyAllowed(parsed.vibe_tags, VIBE);
    const occasion_tags = onlyAllowed(parsed.occasion_tags, OCCASION);
    const dietary_tags = onlyAllowed(parsed.dietary_tags, DIETARY);

    const update = {
      editorial_summary: r.editorial_summary || parsed.editorial_summary || null,
      vibe_tags,
      occasion_tags,
      dietary_tags,
      is_good_for_date: Boolean(parsed.is_good_for_date),
      is_good_for_groups: Boolean(parsed.is_good_for_groups),
      is_good_for_working: Boolean(parsed.is_good_for_working),
      is_walk_in_friendly: Boolean(parsed.is_walk_in_friendly),
      is_open_late: Boolean(parsed.is_open_late),
      is_tourist_friendly: Boolean(parsed.is_tourist_friendly),
    };

    const { error: upErr } = await supabase.from("restaurants").update(update).eq("id", r.id);
    if (upErr) {
      console.error(`  ! ${r.name} update: ${upErr.message}`);
      continue;
    }

    const dishes = Array.isArray(parsed.dishes) ? parsed.dishes.slice(0, 8) : [];
    if (dishes.length) {
      if (force && hasDishes) {
        await supabase.from("dishes").delete().eq("restaurant_id", r.id);
      }
      const dishRows = dishes.map((d: any, idx: number) => ({
        restaurant_id: r.id,
        name: String(d.name ?? "").slice(0, 120) || "Menu item",
        description: d.description ? String(d.description) : null,
        why_try: d.why_try ? String(d.why_try) : null,
        dish_type: d.dish_type ? String(d.dish_type) : null,
        is_must_try: Boolean(d.is_must_try),
        rank: Number.isFinite(d.rank) ? Number(d.rank) : idx + 1,
      }));
      const { error: dishErr } = await supabase.from("dishes").insert(dishRows);
      if (dishErr) console.error(`  ! ${r.name} dishes: ${dishErr.message}`);
    }

    enriched += 1;
    console.log(`  ~ ${r.name}: ${vibe_tags.length} vibe tags, ${dishes.length} dishes`);
  }

  console.log(`\nDone. Enriched ${enriched}, skipped ${skipped} already-enriched.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
