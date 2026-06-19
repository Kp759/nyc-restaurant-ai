import { createServiceClient } from "@/lib/supabase/service";
import { RestaurantForm } from "../restaurant-form";
import { createRestaurant } from "../actions";

export const dynamic = "force-dynamic";

async function getNeighborhoods() {
  const service = createServiceClient();
  const { data } = await service
    .from("neighborhoods")
    .select("name, borough")
    .eq("is_active", true)
    .order("name");
  return data ?? [];
}

export default async function NewRestaurantPage() {
  const neighborhoods = await getNeighborhoods();
  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Add restaurant</h1>
          <p className="subtitle">Saved as a draft — publish after adding dishes & media.</p>
        </div>
      </div>
      <RestaurantForm
        action={createRestaurant}
        neighborhoods={neighborhoods}
        submitLabel="Create draft"
      />
    </div>
  );
}
