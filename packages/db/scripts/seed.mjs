// Loads packages/db/seed.sql (neighborhoods + sample restaurants/dishes/media).
// Idempotent: seed.sql uses upserts / on-conflict guards.
import { dirname, join } from "node:path";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import pg from "pg";
import dotenv from "dotenv";

dotenv.config();
dotenv.config({ path: join(process.cwd(), "../../.env") });

const __dirname = dirname(fileURLToPath(import.meta.url));
const seedFile = join(__dirname, "..", "seed.sql");

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error("DATABASE_URL is not set. Add it to your .env file.");
  process.exit(1);
}

const client = new pg.Client({
  connectionString,
  ssl: connectionString.includes("supabase.co") ? { rejectUnauthorized: false } : undefined,
});

async function main() {
  await client.connect();
  const sql = await readFile(seedFile, "utf8");
  console.log("Seeding database...");
  await client.query(sql);
  console.log("Seed complete.");
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => client.end());
