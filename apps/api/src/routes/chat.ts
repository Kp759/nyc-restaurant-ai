import type { FastifyInstance } from "fastify";
import { chatRequestSchema } from "@bitenyc/shared";
import { runChat } from "../services/chat.js";

export async function chatRoutes(app: FastifyInstance) {
  app.post("/chat", async (request, reply) => {
    const parsed = chatRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }
    return runChat(parsed.data);
  });
}
