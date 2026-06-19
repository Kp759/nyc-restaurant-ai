/**
 * Generates pgvector embeddings for restaurants using OpenAI
 * text-embedding-3-small (1536 dims). Builds content rows for the restaurant
 * profile, editorial note, each dish, and any video transcripts; then fills in
 * any pre-existing rows (e.g. Yelp review summaries) that still lack an
 * embedding. Idempotent: regenerates the built content types each run.
 *
 * Usage: pnpm --filter @bitenyc/scripts embeddings [--all]
 *        (default: published only; --all: every restaurant)
 * Requires: OPENAI_API_KEY
 */
import OpenAI from "openai";
import { getServiceClient, scriptEnv } from "./lib/env.js";

const BUILT_TYPES = ["restaurant_profile", "editorial_note", "dish", "video_transcript"];

interface Input {
  content_type: string;
  content: string;
}

function buildInputs(r: any): Input[] {
  const inputs: Input[] = [];
  const profile = [
    r.name,
    `${r.neighborhood}, ${r.borough}`,
    (r.cuisine_tags ?? []).join(", "),
    `Vibe: ${(r.vibe_tags ?? []).join(", ")}`,
    `Good for: ${(r.occasion_tags ?? []).join(", ")}`,
    r.description,
  ]
    .filter(Boolean)
    .join(". ");
  if (profile) inputs.push({ content_type: "restaurant_profile", content: profile });
  if (r.editorial_summary)
    inputs.push({ content_type: "editorial_note", content: r.editorial_summary });
  for (const d of r.dishes ?? []) {
    const t = [d.name, d.description, d.why_try].filter(Boolean).join(". ");
    if (t) inputs.push({ content_type: "dish", content: t });
  }
  for (const m of r.media ?? []) {
    if (m.transcript) inputs.push({ content_type: "video_transcript", content: m.transcript });
  }
  return inputs;
}

async function main() {
  if (!scriptEnv.openaiApiKey) {
    console.error("OPENAI_API_KEY is not set.");
    process.exit(1);
  }
  const includeAll = process.argv.includes("--all");
  const supabase = getServiceClient();
  const openai = new OpenAI({ apiKey: scriptEnv.openaiApiKey });

  async function embed(text: string): Promise<number[]> {
    const res = await openai.embeddings.create({
      model: scriptEnv.openaiEmbeddingModel,
      input: text,
    });
    return res.data[0]!.embedding;
  }

  let query = supabase.from("restaurants").select("*, dishes(*), media:media_items(*)");
  if (!includeAll) query = query.eq("status", "published");
  const { data: restaurants, error } = await query;
  if (error) throw error;

  let written = 0;
  for (const r of restaurants ?? []) {
    // Rebuild the standard content types.
    await supabase
      .from("restaurant_embeddings")
      .delete()
      .eq("restaurant_id", r.id)
      .in("content_type", BUILT_TYPES);

    for (const input of buildInputs(r)) {
      const embedding = await embed(input.content);
      await supabase.from("restaurant_embeddings").insert({
        restaurant_id: r.id,
        content_type: input.content_type,
        content: input.content,
        embedding: embedding as unknown as string,
      });
      written += 1;
    }
    console.log(`  ~ embedded ${r.name}`);
  }

  // Fill any rows left without an embedding (e.g. Yelp review summaries).
  const { data: pending } = await supabase
    .from("restaurant_embeddings")
    .select("id, content")
    .is("embedding", null);
  for (const row of pending ?? []) {
    const embedding = await embed(row.content);
    await supabase
      .from("restaurant_embeddings")
      .update({ embedding: embedding as unknown as string })
      .eq("id", row.id);
    written += 1;
  }

  console.log(`\nDone. Wrote ${written} embeddings.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
