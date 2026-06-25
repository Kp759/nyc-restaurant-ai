/**
 * Fetches short food clips ("reels") for each restaurant via the YouTube Data
 * API v3 and stores them as embeddable media_items (source='youtube'). This is
 * the App-Store-safe alternative to scraping TikTok/Instagram: we only store
 * official, embeddable YouTube video references + thumbnails.
 *
 * Quota note: each search costs 100 units; the default daily quota is 10,000
 * (~100 restaurants/day). The script is idempotent - it skips restaurants that
 * already have YouTube media and stops cleanly on quota errors, so you can
 * re-run it across days to finish the catalog.
 *
 * Usage: pnpm --filter @bitenyc/scripts fetch:reels [--all] [--force] [--limit N] [--per N]
 *   --all:   include drafts/archived too (default: published)
 *   --force: refetch even if YouTube media already exists
 *   --limit: cap restaurants processed this run (default 90, to stay under quota)
 *   --per:   clips per restaurant (default 2, max 5)
 * Requires: YOUTUBE_API_KEY (or a GOOGLE_PLACES_API_KEY with YouTube Data API enabled)
 */
import { getServiceClient, scriptEnv } from "./lib/env.js";

const SEARCH_URL = "https://www.googleapis.com/youtube/v3/search";

function argValue(flag: string): string | undefined {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

class QuotaError extends Error {}

async function searchYouTube(query: string, max: number): Promise<any[]> {
  const url =
    `${SEARCH_URL}?part=snippet&type=video&videoEmbeddable=true` +
    `&maxResults=${max}&q=${encodeURIComponent(query)}&key=${scriptEnv.youtubeApiKey}`;
  const res = await fetch(url);
  if (res.status === 403) {
    const body = await res.text();
    throw new QuotaError(`YouTube 403 (quota/permission): ${body.slice(0, 300)}`);
  }
  if (!res.ok) {
    throw new Error(`YouTube error ${res.status}: ${(await res.text()).slice(0, 300)}`);
  }
  const json = (await res.json()) as { items?: any[] };
  return json.items ?? [];
}

async function main() {
  if (!scriptEnv.youtubeApiKey) {
    console.error("YOUTUBE_API_KEY (or GOOGLE_PLACES_API_KEY) is not set.");
    process.exit(1);
  }
  const includeAll = process.argv.includes("--all");
  const force = process.argv.includes("--force");
  const limit = Number(argValue("--limit")) || 90;
  const per = Math.min(Math.max(Number(argValue("--per")) || 2, 1), 5);

  const supabase = getServiceClient();

  let query = supabase.from("restaurants").select("id, name, neighborhood, borough, status");
  if (!includeAll) query = query.eq("status", "published");
  const { data: restaurants, error } = await query;
  if (error) throw error;

  let added = 0;
  let processed = 0;
  let skipped = 0;

  for (const r of restaurants ?? []) {
    if (processed >= limit) break;

    if (!force) {
      const { count } = await supabase
        .from("media_items")
        .select("id", { count: "exact", head: true })
        .eq("restaurant_id", r.id)
        .eq("source", "youtube");
      if ((count ?? 0) > 0) {
        skipped += 1;
        continue;
      }
    }

    let items: any[] = [];
    try {
      items = await searchYouTube(`${r.name} ${r.neighborhood} NYC food`, per);
    } catch (err) {
      if (err instanceof QuotaError) {
        console.error(`\nStopping: ${err.message}`);
        break;
      }
      console.error(`  ! ${r.name}: ${(err as Error).message}`);
      continue;
    }
    processed += 1;

    const rows = items
      .filter((it) => it.id?.videoId)
      .map((it) => {
        const s = it.snippet ?? {};
        const thumb =
          s.thumbnails?.high?.url ?? s.thumbnails?.medium?.url ?? s.thumbnails?.default?.url ?? null;
        return {
          restaurant_id: r.id,
          media_type: "video" as const,
          source: "youtube" as const,
          url: `https://www.youtube.com/watch?v=${it.id.videoId}`,
          thumbnail_url: thumb,
          caption: s.title ? String(s.title).slice(0, 200) : null,
          creator_name: s.channelTitle ?? null,
          creator_url: s.channelId ? `https://www.youtube.com/channel/${s.channelId}` : null,
          rights_status: "embedded" as const,
          moderation_status: "approved" as const,
        };
      });

    if (rows.length) {
      const { error: insErr } = await supabase.from("media_items").insert(rows);
      if (insErr) {
        console.error(`  ! ${r.name} insert: ${insErr.message}`);
      } else {
        added += rows.length;
        console.log(`  + ${r.name}: ${rows.length} clips`);
      }
    } else {
      console.log(`  . ${r.name}: no clips found`);
    }
  }

  console.log(
    `\nDone. Added ${added} clips across ${processed} restaurants, skipped ${skipped} existing.`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
