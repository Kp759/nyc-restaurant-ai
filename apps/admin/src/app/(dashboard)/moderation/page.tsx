import { createServiceClient } from "@/lib/supabase/service";
import { resolveReport, resolveTakedown } from "./actions";

export const dynamic = "force-dynamic";

async function getQueue() {
  const service = createServiceClient();
  const [reports, takedowns] = await Promise.all([
    service
      .from("content_reports")
      .select("*")
      .in("status", ["open", "reviewing"])
      .order("created_at", { ascending: true }),
    service
      .from("takedown_requests")
      .select("*, restaurants(name)")
      .in("status", ["open", "reviewing"])
      .order("created_at", { ascending: true }),
  ]);
  return { reports: reports.data ?? [], takedowns: takedowns.data ?? [] };
}

export default async function ModerationPage() {
  const { reports, takedowns } = await getQueue();

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Moderation</h1>
          <p className="subtitle">
            User reports and owner takedowns (App Store Guideline 1.2)
          </p>
        </div>
      </div>

      <div className="card">
        <h2>Content reports ({reports.length})</h2>
        <table>
          <thead>
            <tr>
              <th>Target</th>
              <th>Reason</th>
              <th>Details</th>
              <th>Reported</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {reports.map((r) => (
              <tr key={r.id}>
                <td>
                  {r.target_type}
                  <div className="muted" style={{ fontSize: 11 }}>
                    {r.target_id}
                  </div>
                </td>
                <td>
                  <span className="badge">{r.reason}</span>
                </td>
                <td className="muted">{r.details ?? "—"}</td>
                <td className="muted">{new Date(r.created_at).toLocaleDateString()}</td>
                <td>
                  <div className="btn-row">
                    <form action={resolveReport.bind(null, r.id, "resolved")}>
                      <button className="btn btn-primary" type="submit">
                        Resolve
                      </button>
                    </form>
                    <form action={resolveReport.bind(null, r.id, "dismissed")}>
                      <button className="btn" type="submit">
                        Dismiss
                      </button>
                    </form>
                  </div>
                </td>
              </tr>
            ))}
            {reports.length === 0 ? (
              <tr>
                <td colSpan={5} className="muted">
                  No open reports.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Takedown requests ({takedowns.length})</h2>
        <table>
          <thead>
            <tr>
              <th>Restaurant</th>
              <th>Requester</th>
              <th>Relationship</th>
              <th>Details</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {takedowns.map((t: any) => (
              <tr key={t.id}>
                <td>{t.restaurants?.name ?? t.restaurant_id}</td>
                <td>
                  {t.requester_name}
                  <div className="muted" style={{ fontSize: 11 }}>
                    {t.requester_email}
                  </div>
                </td>
                <td>
                  <span className="badge">{t.relationship}</span>
                </td>
                <td className="muted">{t.details ?? "—"}</td>
                <td>
                  <div className="btn-row">
                    <form action={resolveTakedown.bind(null, t.id, "resolved")}>
                      <button className="btn btn-primary" type="submit">
                        Resolve
                      </button>
                    </form>
                    <form action={resolveTakedown.bind(null, t.id, "dismissed")}>
                      <button className="btn" type="submit">
                        Dismiss
                      </button>
                    </form>
                  </div>
                </td>
              </tr>
            ))}
            {takedowns.length === 0 ? (
              <tr>
                <td colSpan={5} className="muted">
                  No open takedown requests.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}
