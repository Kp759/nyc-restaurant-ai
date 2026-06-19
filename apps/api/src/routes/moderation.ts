import type { FastifyInstance } from "fastify";
import { contentReportSchema, takedownRequestSchema } from "@bitenyc/shared";
import { supabase } from "../supabase.js";

export async function moderationRoutes(app: FastifyInstance) {
  // Report a piece of content (App Store Guideline 1.2).
  app.post("/reports", async (request, reply) => {
    const parsed = contentReportSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }
    const { error, data } = await supabase
      .from("content_reports")
      .insert(parsed.data)
      .select("id")
      .single();
    if (error) throw error;
    return reply.status(201).send({ id: data.id, status: "open" });
  });

  // Restaurant owner / legal takedown request.
  app.post("/takedowns", async (request, reply) => {
    const parsed = takedownRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }
    const { error, data } = await supabase
      .from("takedown_requests")
      .insert(parsed.data)
      .select("id")
      .single();
    if (error) throw error;
    return reply.status(201).send({ id: data.id, status: "open" });
  });
}
