// Applies SQL migrations in packages/db/migrations in lexical order.
// Tracks applied files in a schema_migrations table so it is idempotent.
import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";
import dotenv from "dotenv";

dotenv.config();
dotenv.config({ path: join(process.cwd(), "../../.env") });

const __dirname = dirname(fileURLToPath(import.meta.url));
const migrationsDir = join(__dirname, "..", "migrations");

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error("DATABASE_URL is not set. Add it to your .env file.");
  process.exit(1);
}

const client = new pg.Client({
  connectionString,
  ssl: /supabase\.(co|com)/.test(connectionString) ? { rejectUnauthorized: false } : undefined,
});

async function main() {
  await client.connect();
  await client.query(`
    create table if not exists schema_migrations (
      filename text primary key,
      applied_at timestamptz default now()
    );
  `);

  const files = (await readdir(migrationsDir))
    .filter((f) => f.endsWith(".sql"))
    .sort();

  const { rows } = await client.query("select filename from schema_migrations");
  const applied = new Set(rows.map((r) => r.filename));

  for (const file of files) {
    if (applied.has(file)) {
      console.log(`= skip   ${file}`);
      continue;
    }
    const sql = await readFile(join(migrationsDir, file), "utf8");
    console.log(`+ apply  ${file}`);
    try {
      await client.query("begin");
      await client.query(sql);
      await client.query("insert into schema_migrations (filename) values ($1)", [file]);
      await client.query("commit");
    } catch (err) {
      await client.query("rollback");
      console.error(`Failed on ${file}:`, err.message);
      throw err;
    }
  }
  console.log("Migrations complete.");
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => client.end());
