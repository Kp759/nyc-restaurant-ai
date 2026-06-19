import Link from "next/link";
import { notFound } from "next/navigation";
import { createServiceClient } from "@/lib/supabase/service";
import { RestaurantForm } from "../restaurant-form";
import {
  addDish,
  addMedia,
  deleteDish,
  deleteMedia,
  deleteRestaurant,
  generateEmbeddings,
  setMediaModeration,
  setStatus,
  updateRestaurant,
} from "../actions";

export const dynamic = "force-dynamic";

async function getData(id: string) {
  const service = createServiceClient();
  const [{ data: restaurant }, { data: neighborhoods }, embeddings] = await Promise.all([
    service
      .from("restaurants")
      .select("*, dishes(*), media:media_items(*)")
      .eq("id", id)
      .maybeSingle(),
    service.from("neighborhoods").select("name, borough").eq("is_active", true).order("name"),
    service
      .from("restaurant_embeddings")
      .select("id", { count: "exact", head: true })
      .eq("restaurant_id", id),
  ]);
  return {
    restaurant,
    neighborhoods: neighborhoods ?? [],
    embeddingCount: embeddings.count ?? 0,
  };
}

export default async function EditRestaurantPage({ params }: { params: { id: string } }) {
  const { restaurant, neighborhoods, embeddingCount } = await getData(params.id);
  if (!restaurant) notFound();

  const dishes = (restaurant.dishes ?? []).sort((a: any, b: any) => (a.rank ?? 0) - (b.rank ?? 0));
  const media = restaurant.media ?? [];

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>{restaurant.name}</h1>
          <p className="subtitle">
            <span className={`badge badge-${restaurant.status}`}>{restaurant.status}</span>{" "}
            · {restaurant.neighborhood}, {restaurant.borough} · {embeddingCount} embeddings
          </p>
        </div>
        <Link className="btn" href="/restaurants">
          Back
        </Link>
      </div>

      <div className="card">
        <h2>Status & actions</h2>
        <div className="btn-row">
          <form action={setStatus.bind(null, restaurant.id, "published")}>
            <button className="btn btn-primary" type="submit">
              Publish
            </button>
          </form>
          <form action={setStatus.bind(null, restaurant.id, "draft")}>
            <button className="btn" type="submit">
              Unpublish (draft)
            </button>
          </form>
          <form action={setStatus.bind(null, restaurant.id, "archived")}>
            <button className="btn" type="submit">
              Archive
            </button>
          </form>
          <form action={generateEmbeddings.bind(null, restaurant.id)}>
            <button className="btn" type="submit">
              Generate embeddings
            </button>
          </form>
          <form action={deleteRestaurant.bind(null, restaurant.id)}>
            <button className="btn btn-danger" type="submit">
              Delete
            </button>
          </form>
        </div>
      </div>

      <RestaurantForm
        action={updateRestaurant.bind(null, restaurant.id)}
        neighborhoods={neighborhoods}
        submitLabel="Save changes"
        values={restaurant}
      />

      <div className="card">
        <h2>Dishes ({dishes.length})</h2>
        <table>
          <thead>
            <tr>
              <th>Rank</th>
              <th>Name</th>
              <th>Type</th>
              <th>Must-try</th>
              <th>Why try</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {dishes.map((d: any) => (
              <tr key={d.id}>
                <td>{d.rank}</td>
                <td>{d.name}</td>
                <td>{d.dish_type ?? "—"}</td>
                <td>{d.is_must_try ? "★" : ""}</td>
                <td className="muted">{d.why_try ?? ""}</td>
                <td>
                  <form action={deleteDish.bind(null, d.id, restaurant.id)}>
                    <button className="btn btn-danger" type="submit">
                      Remove
                    </button>
                  </form>
                </td>
              </tr>
            ))}
            {dishes.length === 0 ? (
              <tr>
                <td colSpan={6} className="muted">
                  No dishes yet. Aim for 3-5 must-try dishes.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>

        <form action={addDish.bind(null, restaurant.id)} style={{ marginTop: 14 }}>
          <div className="grid grid-3">
            <div className="field">
              <label>Name</label>
              <input name="name" required />
            </div>
            <div className="field">
              <label>Type</label>
              <input name="dish_type" placeholder="pasta, dessert, cocktail..." />
            </div>
            <div className="field">
              <label>Rank</label>
              <input name="rank" type="number" defaultValue={dishes.length + 1} />
            </div>
          </div>
          <div className="field">
            <label>Why try</label>
            <input name="why_try" />
          </div>
          <div className="grid grid-2">
            <div className="field">
              <label>Tags (comma-separated)</label>
              <input name="tags" />
            </div>
            <div className="field">
              <label>Photo URL</label>
              <input name="photo_url" />
            </div>
          </div>
          <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <input type="checkbox" name="is_must_try" style={{ width: "auto" }} /> Must-try
          </label>
          <div className="btn-row" style={{ marginTop: 10 }}>
            <button className="btn btn-primary" type="submit">
              Add dish
            </button>
          </div>
        </form>
      </div>

      <div className="card">
        <h2>Media ({media.length})</h2>
        <table>
          <thead>
            <tr>
              <th>Type</th>
              <th>Source</th>
              <th>URL</th>
              <th>Rights</th>
              <th>Moderation</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {media.map((m: any) => (
              <tr key={m.id}>
                <td>{m.media_type}</td>
                <td>{m.source}</td>
                <td className="muted" style={{ maxWidth: 240, overflow: "hidden", textOverflow: "ellipsis" }}>
                  <a href={m.url} target="_blank" rel="noreferrer">
                    {m.url}
                  </a>
                </td>
                <td>{m.rights_status}</td>
                <td>
                  <span className="badge">{m.moderation_status}</span>
                </td>
                <td>
                  <div className="btn-row">
                    <form action={setMediaModeration.bind(null, m.id, restaurant.id, "approved")}>
                      <button className="btn" type="submit">
                        Approve
                      </button>
                    </form>
                    <form action={setMediaModeration.bind(null, m.id, restaurant.id, "rejected")}>
                      <button className="btn" type="submit">
                        Reject
                      </button>
                    </form>
                    <form action={deleteMedia.bind(null, m.id, restaurant.id)}>
                      <button className="btn btn-danger" type="submit">
                        Remove
                      </button>
                    </form>
                  </div>
                </td>
              </tr>
            ))}
            {media.length === 0 ? (
              <tr>
                <td colSpan={6} className="muted">
                  No media yet. Add 5 photos + 1 clip per the listing checklist.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>

        <form action={addMedia.bind(null, restaurant.id)} style={{ marginTop: 14 }}>
          <div className="grid grid-3">
            <div className="field">
              <label>Media type</label>
              <select name="media_type" defaultValue="photo">
                <option value="photo">photo</option>
                <option value="video">video</option>
                <option value="embed">embed</option>
              </select>
            </div>
            <div className="field">
              <label>Source</label>
              <select name="source" defaultValue="restaurant">
                <option value="own_upload">own_upload</option>
                <option value="restaurant">restaurant</option>
                <option value="creator">creator</option>
                <option value="tiktok">tiktok</option>
                <option value="youtube">youtube</option>
                <option value="instagram">instagram</option>
                <option value="licensed_api">licensed_api</option>
              </select>
            </div>
            <div className="field">
              <label>Rights status</label>
              <select name="rights_status" defaultValue="unknown">
                <option value="owned">owned</option>
                <option value="licensed">licensed</option>
                <option value="embedded">embedded</option>
                <option value="unknown">unknown</option>
              </select>
            </div>
          </div>
          <div className="grid grid-2">
            <div className="field">
              <label>URL</label>
              <input name="url" required />
            </div>
            <div className="field">
              <label>Thumbnail URL</label>
              <input name="thumbnail_url" />
            </div>
            <div className="field">
              <label>Caption</label>
              <input name="caption" />
            </div>
            <div className="field">
              <label>Creator name</label>
              <input name="creator_name" />
            </div>
            <div className="field">
              <label>Creator URL</label>
              <input name="creator_url" />
            </div>
            <div className="field">
              <label>Initial moderation</label>
              <select name="moderation_status" defaultValue="pending">
                <option value="pending">pending</option>
                <option value="approved">approved</option>
                <option value="rejected">rejected</option>
              </select>
            </div>
          </div>
          <div className="field">
            <label>Transcript (for video search)</label>
            <textarea name="transcript" />
          </div>
          <div className="btn-row">
            <button className="btn btn-primary" type="submit">
              Add media
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
