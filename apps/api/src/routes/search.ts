import type { FastifyInstance } from "fastify";
import { searchRequestSchema } from "@bitenyc/shared";
import { runSearch } from "../services/search.js";

export async function searchRoutes(app: FastifyInstance) {
  app.post("/search", async (request, reply) => {
    const parsed = searchRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }
    const { query, filters, limit } = parsed.data;
    const { filters: resolved, results } = await runSearch({
      query,
      overrides: filters,
      limit,
    });
    return { query, filters: resolved, results };
  });
}
