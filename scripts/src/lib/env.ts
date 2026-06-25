import { config } from "dotenv";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load .env from scripts/, then fall back to the monorepo root.
config();
config({ path: join(__dirname, "..", "..", "..", ".env") });

export const scriptEnv = {
  supabaseUrl: requireEnv("SUPABASE_URL"),
  supabaseServiceRoleKey: requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
  openaiApiKey: process.env.OPENAI_API_KEY ?? "",
  openaiEmbeddingModel: process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small",
  googlePlacesApiKey: process.env.GOOGLE_PLACES_API_KEY ?? "",
  // YouTube Data API v3 key (for reels). Falls back to the Google key if it has
  // the YouTube Data API enabled and isn't API-restricted to Places only.
  youtubeApiKey: process.env.YOUTUBE_API_KEY ?? process.env.GOOGLE_PLACES_API_KEY ?? "",
  // Public base URL of the API, used to build proxied photo URLs stored in media_items.
  apiPublicUrl: process.env.API_PUBLIC_URL ?? "http://localhost:4000",
  openaiChatModel: process.env.OPENAI_CHAT_MODEL ?? "gpt-4o-mini",
  yelpApiKey: process.env.YELP_API_KEY ?? "",
  nycDohmhSodaUrl:
    process.env.NYC_DOHMH_SODA_URL ?? "https://data.cityofnewyork.us/resource/43nn-pn8j.json",
  nycOpenDataAppToken: process.env.NYC_OPEN_DATA_APP_TOKEN ?? "",
};

function requireEnv(key: string): string {
  const v = process.env[key];
  if (!v) {
    console.error(`Missing required env var: ${key}. See .env.example.`);
    process.exit(1);
  }
  return v;
}

export function getServiceClient(): SupabaseClient {
  return createClient(scriptEnv.supabaseUrl, scriptEnv.supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
