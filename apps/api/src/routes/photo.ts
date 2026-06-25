import type { FastifyInstance } from "fastify";
import { env } from "../env.js";

/**
 * Proxies Google Places "Place Photos" so the API key stays server-side.
 * The importer stores media URLs like `/photo?name=places/XXX/photos/YYY`,
 * and this route fetches the actual image bytes from Google on demand.
 */
export async function photoRoutes(app: FastifyInstance) {
  app.get("/photo", async (request, reply) => {
    const { name, maxwidth } = request.query as {
      name?: string;
      maxwidth?: string;
    };

    if (!env.GOOGLE_PLACES_API_KEY) {
      return reply.status(503).send({ error: "Photo proxy not configured" });
    }

    // Only allow well-formed Google Places photo resource names.
    if (!name || !/^places\/[^/]+\/photos\/[^/]+$/.test(name)) {
      return reply.status(400).send({ error: "Invalid photo name" });
    }

    const width = Math.min(Math.max(Number(maxwidth) || 1200, 100), 1600);
    const url =
      `https://places.googleapis.com/v1/${name}/media` +
      `?maxWidthPx=${width}&key=${env.GOOGLE_PLACES_API_KEY}`;

    const res = await fetch(url);
    if (!res.ok) {
      return reply.status(res.status).send({ error: "Upstream photo error" });
    }

    const contentType = res.headers.get("content-type") ?? "image/jpeg";
    const buffer = Buffer.from(await res.arrayBuffer());

    reply
      .header("content-type", contentType)
      .header("cache-control", "public, max-age=86400")
      .send(buffer);
  });
}
