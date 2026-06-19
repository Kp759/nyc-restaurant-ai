import type { FastifyInstance } from "fastify";
import { env, aiEnabled } from "../env.js";
import { generateRestaurantEmbeddings } from "../services/embeddings.js";

/**
 * Admin-only endpoints. Guarded by a shared service key passed from the
 * server-side admin app (never exposed to the browser).
 */
export async function adminRoutes(app: FastifyInstance) {
  app.addHook("onRequest", async (request, reply) => {
    const provided = request.headers["x-service-key"];
    if (!provided || provided !== env.SUPABASE_SERVICE_ROLE_KEY) {
      return reply.status(401).send({ error: "Unauthorized" });
    }
  });

  app.post<{ Params: { id: string } }>(
    "/admin/restaurants/:id/embeddings",
    async (request, reply) => {
      if (!aiEnabled) {
        return reply.status(503).send({ error: "OPENAI_API_KEY is not configured" });
      }
      const count = await generateRestaurantEmbeddings(request.params.id);
      return { restaurant_id: request.params.id, embeddings_written: count };
    },
  );
}
