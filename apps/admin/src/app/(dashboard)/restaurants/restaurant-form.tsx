"use client";

import { useFormStatus } from "react-dom";
import { BOROUGHS, OCCASION_TAGS, VIBE_TAGS } from "@bitenyc/shared";

export interface RestaurantFormValues {
  name?: string;
  slug?: string;
  description?: string | null;
  editorial_summary?: string | null;
  address?: string | null;
  neighborhood?: string | null;
  borough?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  cuisine_tags?: string[];
  vibe_tags?: string[];
  occasion_tags?: string[];
  dietary_tags?: string[];
  price_tier?: number | null;
  rating?: number | null;
  review_count?: number | null;
  resy_url?: string | null;
  opentable_id?: string | null;
  tock_url?: string | null;
  direct_booking_url?: string | null;
  google_place_id?: string | null;
  yelp_business_id?: string | null;
  health_grade?: string | null;
  health_grade_date?: string | null;
  health_inspection_score?: number | null;
  editorial_score?: number | null;
  popularity_score?: number | null;
  is_walk_in_friendly?: boolean;
  is_good_for_date?: boolean;
  is_good_for_groups?: boolean;
  is_good_for_working?: boolean;
  is_open_late?: boolean;
  is_tourist_friendly?: boolean;
}

function SaveButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button className="btn btn-primary" type="submit" disabled={pending}>
      {pending ? "Saving..." : label}
    </button>
  );
}

const csv = (v?: string[]) => (v ?? []).join(", ");

export function RestaurantForm({
  action,
  values = {},
  neighborhoods,
  submitLabel,
}: {
  action: (formData: FormData) => void;
  values?: RestaurantFormValues;
  neighborhoods: Array<{ name: string; borough: string }>;
  submitLabel: string;
}) {
  return (
    <form action={action}>
      <div className="card">
        <h2>Basics</h2>
        <div className="grid grid-2">
          <div className="field">
            <label>Name</label>
            <input name="name" defaultValue={values.name ?? ""} required />
          </div>
          <div className="field">
            <label>Slug (leave blank to auto-generate)</label>
            <input name="slug" defaultValue={values.slug ?? ""} />
          </div>
        </div>
        <div className="field">
          <label>Short description</label>
          <textarea name="description" defaultValue={values.description ?? ""} />
        </div>
        <div className="field">
          <label>Editorial summary (the BiteNYC voice)</label>
          <textarea name="editorial_summary" defaultValue={values.editorial_summary ?? ""} />
        </div>
      </div>

      <div className="card">
        <h2>Location</h2>
        <div className="field">
          <label>Address</label>
          <input name="address" defaultValue={values.address ?? ""} />
        </div>
        <div className="grid grid-3">
          <div className="field">
            <label>Neighborhood</label>
            <input
              name="neighborhood"
              list="neighborhood-options"
              defaultValue={values.neighborhood ?? ""}
            />
            <datalist id="neighborhood-options">
              {neighborhoods.map((n) => (
                <option key={`${n.name}-${n.borough}`} value={n.name} />
              ))}
            </datalist>
          </div>
          <div className="field">
            <label>Borough</label>
            <select name="borough" defaultValue={values.borough ?? "Manhattan"}>
              {BOROUGHS.map((b) => (
                <option key={b} value={b}>
                  {b}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label>Price tier (1-4)</label>
            <select name="price_tier" defaultValue={values.price_tier ?? ""}>
              <option value="">—</option>
              <option value="1">$ (under $25)</option>
              <option value="2">$$ (under $50)</option>
              <option value="3">$$$ (under $100)</option>
              <option value="4">$$$$ (splurge)</option>
            </select>
          </div>
        </div>
        <div className="grid grid-2">
          <div className="field">
            <label>Latitude</label>
            <input name="latitude" type="number" step="any" defaultValue={values.latitude ?? ""} />
          </div>
          <div className="field">
            <label>Longitude</label>
            <input
              name="longitude"
              type="number"
              step="any"
              defaultValue={values.longitude ?? ""}
            />
          </div>
        </div>
      </div>

      <div className="card">
        <h2>Tags</h2>
        <p className="muted" style={{ marginTop: -6 }}>
          Comma-separated. Vibe options: {VIBE_TAGS.slice(0, 8).join(", ")}… · Occasion options:{" "}
          {OCCASION_TAGS.slice(0, 6).join(", ")}…
        </p>
        <div className="field">
          <label>Cuisine tags</label>
          <input name="cuisine_tags" defaultValue={csv(values.cuisine_tags)} />
        </div>
        <div className="field">
          <label>Vibe tags</label>
          <input name="vibe_tags" defaultValue={csv(values.vibe_tags)} />
        </div>
        <div className="field">
          <label>Occasion tags</label>
          <input name="occasion_tags" defaultValue={csv(values.occasion_tags)} />
        </div>
        <div className="field">
          <label>Dietary tags</label>
          <input name="dietary_tags" defaultValue={csv(values.dietary_tags)} />
        </div>
      </div>

      <div className="card">
        <h2>Good for</h2>
        <div className="grid grid-3">
          <Toggle name="is_good_for_date" label="Date" checked={values.is_good_for_date} />
          <Toggle name="is_good_for_groups" label="Groups" checked={values.is_good_for_groups} />
          <Toggle name="is_good_for_working" label="Work cafe" checked={values.is_good_for_working} />
          <Toggle name="is_walk_in_friendly" label="Walk-in friendly" checked={values.is_walk_in_friendly} />
          <Toggle name="is_open_late" label="Open late" checked={values.is_open_late} />
          <Toggle name="is_tourist_friendly" label="Good for visitors" checked={values.is_tourist_friendly} />
        </div>
      </div>

      <div className="card">
        <h2>Ratings & scores</h2>
        <div className="grid grid-3">
          <div className="field">
            <label>Rating (0-5)</label>
            <input name="rating" type="number" step="0.1" defaultValue={values.rating ?? ""} />
          </div>
          <div className="field">
            <label>Review count</label>
            <input name="review_count" type="number" defaultValue={values.review_count ?? 0} />
          </div>
          <div className="field">
            <label>Editorial score (0-100)</label>
            <input
              name="editorial_score"
              type="number"
              defaultValue={values.editorial_score ?? 0}
            />
          </div>
          <div className="field">
            <label>Popularity score</label>
            <input
              name="popularity_score"
              type="number"
              defaultValue={values.popularity_score ?? 0}
            />
          </div>
        </div>
      </div>

      <div className="card">
        <h2>Reservations (provider order: Resy → OpenTable → Tock → Direct)</h2>
        <div className="grid grid-2">
          <div className="field">
            <label>Resy URL</label>
            <input name="resy_url" defaultValue={values.resy_url ?? ""} />
          </div>
          <div className="field">
            <label>OpenTable ID</label>
            <input name="opentable_id" defaultValue={values.opentable_id ?? ""} />
          </div>
          <div className="field">
            <label>Tock URL</label>
            <input name="tock_url" defaultValue={values.tock_url ?? ""} />
          </div>
          <div className="field">
            <label>Direct booking URL</label>
            <input name="direct_booking_url" defaultValue={values.direct_booking_url ?? ""} />
          </div>
        </div>
      </div>

      <div className="card">
        <h2>External IDs & health grade</h2>
        <div className="grid grid-2">
          <div className="field">
            <label>Google Place ID</label>
            <input name="google_place_id" defaultValue={values.google_place_id ?? ""} />
          </div>
          <div className="field">
            <label>Yelp business ID</label>
            <input name="yelp_business_id" defaultValue={values.yelp_business_id ?? ""} />
          </div>
          <div className="field">
            <label>Health grade (A/B/C)</label>
            <input name="health_grade" defaultValue={values.health_grade ?? ""} />
          </div>
          <div className="field">
            <label>Health grade date</label>
            <input
              name="health_grade_date"
              type="date"
              defaultValue={values.health_grade_date ?? ""}
            />
          </div>
          <div className="field">
            <label>Health inspection score</label>
            <input
              name="health_inspection_score"
              type="number"
              defaultValue={values.health_inspection_score ?? ""}
            />
          </div>
        </div>
      </div>

      <div className="btn-row">
        <SaveButton label={submitLabel} />
      </div>
    </form>
  );
}

function Toggle({
  name,
  label,
  checked,
}: {
  name: string;
  label: string;
  checked?: boolean;
}) {
  return (
    <label style={{ display: "flex", alignItems: "center", gap: 8, color: "var(--text)" }}>
      <input type="checkbox" name={name} defaultChecked={checked} style={{ width: "auto" }} />
      {label}
    </label>
  );
}
