import { config } from "dotenv";
import { z } from "zod";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load .env from the app first, then fall back to the monorepo root.
config();
config({ path: join(__dirname, "..", "..", "..", ".env") });

const envSchema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  OPENAI_API_KEY: z.string().min(1).optional(),
  OPENAI_EMBEDDING_MODEL: z.string().default("text-embedding-3-small"),
  OPENAI_CHAT_MODEL: z.string().default("gpt-4o-mini"),
  API_PORT: z.coerce.number().default(4000),
  API_HOST: z.string().default("0.0.0.0"),
  API_CORS_ORIGINS: z.string().default("http://localhost:3000"),
  GOOGLE_PLACES_API_KEY: z.string().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error("Invalid API environment configuration:");
  console.error(parsed.error.flatten().fieldErrors);
  throw new Error("Missing required environment variables. See .env.example.");
}

export const env = parsed.data;

export const corsOrigins = env.API_CORS_ORIGINS.split(",")
  .map((o) => o.trim())
  .filter(Boolean);

/** OpenAI features degrade gracefully when no key is configured. */
export const aiEnabled = Boolean(env.OPENAI_API_KEY);
