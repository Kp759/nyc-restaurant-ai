/**
 * Matches restaurants to the official NYC DOHMH Restaurant Inspection Results
 * dataset (NYC Open Data, Socrata) by name + borough, and writes the most
 * recent letter grade, grade date, and inspection score.
 * Idempotent: only processes restaurants without a health_grade.
 *
 * Usage: pnpm --filter @bitenyc/scripts match:health
 * (NYC_OPEN_DATA_APP_TOKEN is optional but raises rate limits.)
 */
import { getServiceClient, scriptEnv } from "./lib/env.js";

const BATCH = 100;

function sanitize(name: string): string {
  // Keep it simple for a SoQL `like` clause; strip quotes/punctuation.
  return name.replace(/['"%]/g, "").trim().toUpperCase();
}

async function fetchGrade(name: string, borough: string) {
  const cleaned = sanitize(name);
  if (!cleaned) return null;
  const where = `upper(dba) like '%${cleaned}%' AND boro='${borough}' AND grade IS NOT NULL`;
  const url = new URL(scriptEnv.nycDohmhSodaUrl);
  url.searchParams.set("$where", where);
  url.searchParams.set("$order", "grade_date DESC");
  url.searchParams.set("$limit", "1");

  const headers: Record<string, string> = {};
  if (scriptEnv.nycOpenDataAppToken) headers["X-App-Token"] = scriptEnv.nycOpenDataAppToken;

  const res = await fetch(url, { headers });
  if (!res.ok) throw new Error(`DOHMH error ${res.status}: ${await res.text()}`);
  const rows = (await res.json()) as any[];
  return rows[0] ?? null;
}

async function main() {
  const supabase = getServiceClient();
  const { data: restaurants, error } = await supabase
    .from("restaurants")
    .select("id, name, borough")
    .is("health_grade", null)
    .limit(BATCH);
  if (error) throw error;

  let matched = 0;
  for (const r of restaurants ?? []) {
    let record: any = null;
    try {
      record = await fetchGrade(r.name, r.borough);
    } catch (err) {
      console.error(`  ! ${r.name}: ${(err as Error).message}`);
      continue;
    }
    if (!record) {
      console.log(`  ? no grade: ${r.name}`);
      continue;
    }

    await supabase
      .from("restaurants")
      .update({
        health_grade: record.grade ?? null,
        health_grade_date: record.grade_date ? record.grade_date.slice(0, 10) : null,
        health_inspection_score: record.score ? Number(record.score) : null,
      })
      .eq("id", r.id);

    matched += 1;
    console.log(`  + ${r.name}: grade ${record.grade}`);
  }

  console.log(`\nDone. Graded ${matched}/${(restaurants ?? []).length}.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
