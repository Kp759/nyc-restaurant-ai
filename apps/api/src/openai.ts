import OpenAI from "openai";
import { env, aiEnabled } from "./env.js";

let client: OpenAI | null = null;

export function getOpenAI(): OpenAI {
  if (!aiEnabled) {
    throw new Error("OPENAI_API_KEY is not configured.");
  }
  if (!client) {
    client = new OpenAI({ apiKey: env.OPENAI_API_KEY });
  }
  return client;
}

/** Embed a single string with the configured embedding model (1536 dims). */
export async function embedText(text: string): Promise<number[]> {
  const openai = getOpenAI();
  const res = await openai.embeddings.create({
    model: env.OPENAI_EMBEDDING_MODEL,
    input: text,
  });
  return res.data[0]!.embedding;
}
