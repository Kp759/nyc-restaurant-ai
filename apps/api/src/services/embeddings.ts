import { supabase } from "../supabase.js";
import { embedText } from "../openai.js";

interface EmbeddingInput {
  content_type:
    | "restaurant_profile"
    | "dish"
    | "review_summary"
    | "video_transcript"
    | "editorial_note";
  content: string;
}

/** Assemble the text snippets that get embedded for a restaurant. */
export function buildEmbeddingInputs(restaurant: any): EmbeddingInput[] {
  const inputs: EmbeddingInput[] = [];

  const profile = [
    restaurant.name,
    `${restaurant.neighborhood}, ${restaurant.borough}`,
    restaurant.cuisine_tags?.join(", "),
    `Vibe: ${restaurant.vibe_tags?.join(", ")}`,
    `Good for: ${restaurant.occasion_tags?.join(", ")}`,
    restaurant.description,
  ]
    .filter(Boolean)
    .join(". ");
  if (profile) inputs.push({ content_type: "restaurant_profile", content: profile });

  if (restaurant.editorial_summary) {
    inputs.push({ content_type: "editorial_note", content: restaurant.editorial_summary });
  }

  for (const dish of restaurant.dishes ?? []) {
    const text = [dish.name, dish.description, dish.why_try].filter(Boolean).join(". ");
    if (text) inputs.push({ content_type: "dish", content: text });
  }

  for (const media of restaurant.media ?? restaurant.media_items ?? []) {
    if (media.transcript) {
      inputs.push({ content_type: "video_transcript", content: media.transcript });
    }
  }

  return inputs;
}

/**
 * Regenerate all embeddings for a single restaurant (delete + re-insert).
 * Returns the number of embedding rows written.
 */
export async function generateRestaurantEmbeddings(restaurantId: string): Promise<number> {
  const { data: restaurant, error } = await supabase
    .from("restaurants")
    .select("*, dishes(*), media:media_items(*)")
    .eq("id", restaurantId)
    .single();
  if (error) throw error;
  if (!restaurant) throw new Error("Restaurant not found");

  const inputs = buildEmbeddingInputs(restaurant);
  if (inputs.length === 0) return 0;

  const rows = [];
  for (const input of inputs) {
    const embedding = await embedText(input.content);
    rows.push({
      restaurant_id: restaurantId,
      content_type: input.content_type,
      content: input.content,
      embedding: embedding as unknown as string,
    });
  }

  await supabase.from("restaurant_embeddings").delete().eq("restaurant_id", restaurantId);
  const { error: insertError } = await supabase.from("restaurant_embeddings").insert(rows);
  if (insertError) throw insertError;

  return rows.length;
}
