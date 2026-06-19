import Link from "next/link";
import { createServiceClient } from "@/lib/supabase/service";

export const dynamic = "force-dynamic";

interface SearchParams {
  status?: string;
  q?: string;
}

async function getRestaurants(params: SearchParams) {
  const service = createServiceClient();
  let query = service
    .from("restaurants")
    .select("id, name, neighborhood, borough, price_tier, rating, status, health_grade")
    .order("updated_at", { ascending: false })
    .limit(200);

  if (params.status && params.status !== "all") query = query.eq("status", params.status);
  if (params.q) query = query.ilike("name", `%${params.q}%`);

  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return data ?? [];
}

const statusBadge = (s: string) =>
  s === "published" ? "badge-published" : s === "draft" ? "badge-draft" : "badge-archived";

export default async function RestaurantsPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const rows = await getRestaurants(searchParams);
  const activeStatus = searchParams.status ?? "all";

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Restaurants</h1>
          <p className="subtitle">{rows.length} listings</p>
        </div>
        <Link className="btn btn-primary" href="/restaurants/new">
          Add restaurant
        </Link>
      </div>

      <div className="card">
        <form className="btn-row" style={{ marginBottom: 14 }}>
          <input
            name="q"
            placeholder="Search by name..."
            defaultValue={searchParams.q ?? ""}
            style={{ maxWidth: 260 }}
          />
          <select name="status" defaultValue={activeStatus} style={{ maxWidth: 160 }}>
            <option value="all">All statuses</option>
            <option value="published">Published</option>
            <option value="draft">Draft</option>
            <option value="archived">Archived</option>
          </select>
          <button className="btn" type="submit">
            Filter
          </button>
        </form>

        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Neighborhood</th>
              <th>Borough</th>
              <th>Price</th>
              <th>Rating</th>
              <th>Health</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td>
                  <Link href={`/restaurants/${r.id}`}>{r.name}</Link>
                </td>
                <td>{r.neighborhood}</td>
                <td>{r.borough}</td>
                <td>{r.price_tier ? "$".repeat(r.price_tier) : "—"}</td>
                <td>{r.rating ?? "—"}</td>
                <td>{r.health_grade ?? "—"}</td>
                <td>
                  <span className={`badge ${statusBadge(r.status)}`}>{r.status}</span>
                </td>
              </tr>
            ))}
            {rows.length === 0 ? (
              <tr>
                <td colSpan={7} className="muted">
                  No restaurants yet. Add one to get started.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}
