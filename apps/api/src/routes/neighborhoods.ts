import type { FastifyInstance } from "fastify";
import { supabase } from "../supabase.js";

export async function neighborhoodRoutes(app: FastifyInstance) {
  app.get("/neighborhoods", async () => {
    const { data, error } = await supabase
      .from("neighborhoods")
      .select("name, borough, mvp_phase")
      .eq("is_active", true)
      .order("borough", { ascending: true })
      .order("name", { ascending: true });
    if (error) throw error;
    return { neighborhoods: data ?? [] };
  });
}
