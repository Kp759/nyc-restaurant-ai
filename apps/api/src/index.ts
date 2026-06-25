import Fastify, { type FastifyError } from "fastify";
import cors from "@fastify/cors";
import { aiEnabled, corsOrigins, env } from "./env.js";
import { restaurantRoutes } from "./routes/restaurants.js";
import { neighborhoodRoutes } from "./routes/neighborhoods.js";
import { filterRoutes } from "./routes/filters.js";
import { searchRoutes } from "./routes/search.js";
import { chatRoutes } from "./routes/chat.js";
import { moderationRoutes } from "./routes/moderation.js";
import { adminRoutes } from "./routes/admin.js";
import { photoRoutes } from "./routes/photo.js";

async function main() {
  const app = Fastify({
    logger: {
      transport:
        process.env.NODE_ENV === "production"
          ? undefined
          : { target: "pino-pretty", options: { translateTime: "HH:MM:ss" } },
    },
  });

  await app.register(cors, { origin: corsOrigins.length ? corsOrigins : true });

  app.get("/health", async () => ({
    status: "ok",
    service: "bitenyc-api",
    ai_enabled: aiEnabled,
  }));

  await app.register(restaurantRoutes);
  await app.register(neighborhoodRoutes);
  await app.register(filterRoutes);
  await app.register(searchRoutes);
  await app.register(chatRoutes);
  await app.register(moderationRoutes);
  await app.register(adminRoutes);
  await app.register(photoRoutes);

  app.setErrorHandler((error: FastifyError, _request, reply) => {
    app.log.error(error);
    reply.status(error.statusCode ?? 500).send({
      error: error.message ?? "Internal Server Error",
    });
  });

  await app.listen({ port: env.API_PORT, host: env.API_HOST });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
