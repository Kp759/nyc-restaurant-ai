import Link from "next/link";
import { createServiceClient } from "@/lib/supabase/service";

export const dynamic = "force-dynamic";

async function getStats() {
  const service = createServiceClient();
  const [published, draft, openReports, openTakedowns, neighborhoods] = await Promise.all([
    service.from("restaurants").select("id", { count: "exact", head: true }).eq("status", "published"),
    service.from("restaurants").select("id", { count: "exact", head: true }).eq("status", "draft"),
    service.from("content_reports").select("id", { count: "exact", head: true }).eq("status", "open"),
    service.from("takedown_requests").select("id", { count: "exact", head: true }).eq("status", "open"),
    service.from("neighborhoods").select("id", { count: "exact", head: true }),
  ]);
  return {
    published: published.count ?? 0,
    draft: draft.count ?? 0,
    openReports: openReports.count ?? 0,
    openTakedowns: openTakedowns.count ?? 0,
    neighborhoods: neighborhoods.count ?? 0,
  };
}

export default async function DashboardHome() {
  const stats = await getStats();
  const openModeration = stats.openReports + stats.openTakedowns;

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p className="subtitle">Curated NYC dining concierge — MVP 1 coverage</p>
        </div>
        <Link className="btn btn-primary" href="/restaurants/new">
          Add restaurant
        </Link>
      </div>

      <div className="stat-grid">
        <div className="stat">
          <div className="num">{stats.published}</div>
          <div className="lbl">Published</div>
        </div>
        <div className="stat">
          <div className="num">{stats.draft}</div>
          <div className="lbl">Drafts</div>
        </div>
        <div className="stat">
          <div className="num">{stats.neighborhoods}</div>
          <div className="lbl">Neighborhoods</div>
        </div>
        <div className="stat">
          <div className="num">{openModeration}</div>
          <div className="lbl">Open moderation items</div>
        </div>
      </div>

      <div className="card" style={{ marginTop: 20 }}>
        <h2>MVP 1 target</h2>
        <p className="muted">
          Manhattan below 59th + Williamsburg + Greenpoint, 300-500 curated listings.
          Each published listing should have 5 photos, 1 clip, 3-5 must-try dishes,
          5-10 vibe tags, an editorial summary, a booking link, and a health grade
          where matched.
        </p>
      </div>
    </div>
  );
}
