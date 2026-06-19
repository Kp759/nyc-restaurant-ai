import {
  SEARCH_RESTAURANTS_TOOL,
  searchFiltersSchema,
  type ChatRequest,
  type ChatResponse,
  type SearchResult,
} from "@bitenyc/shared";
import type OpenAI from "openai";
import { aiEnabled, env } from "../env.js";
import { getOpenAI } from "../openai.js";
import { runSearch } from "./search.js";

const SYSTEM_PROMPT = `You are BiteNYC, a curated New York City dining concierge.
You help people find the right NYC restaurant, cafe, or date-night spot by vibe,
dish, neighborhood, occasion, budget, and reservation availability.

Rules:
- BiteNYC is NYC-only. Never recommend places outside New York City.
- ALWAYS call the search_restaurants tool to ground recommendations. NEVER invent
  restaurants, dishes, ratings, or booking links.
- Recommend at most 5 places, only from the tool results.
- For each pick give: the name, a one-line "Why it fits", 1-2 must-try dishes
  (only those returned), and the best booking option (Resy > OpenTable > Tock >
  Direct). If a place has no booking link, say "Walk-in".
- Be concise and friendly. If the tool returns nothing, say so and suggest
  loosening the neighborhood or budget.`;

export async function runChat(req: ChatRequest): Promise<ChatResponse> {
  if (!aiEnabled) {
    return fallbackChat(req);
  }

  const openai = getOpenAI();
  const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
    { role: "system", content: SYSTEM_PROMPT },
    ...req.history.map((h) => ({ role: h.role, content: h.content })),
    { role: "user", content: req.message },
  ];

  const first = await openai.chat.completions.create({
    model: env.OPENAI_CHAT_MODEL,
    temperature: 0.3,
    messages,
    tools: [SEARCH_RESTAURANTS_TOOL],
    tool_choice: "auto",
  });

  const choice = first.choices[0]!.message;
  const toolCall = choice.tool_calls?.[0];

  if (!toolCall) {
    return { reply: choice.content ?? "", results: [] };
  }

  const overrides = parseToolArgs(toolCall.function.arguments);
  const { results } = await runSearch({
    query: req.message,
    overrides,
    limit: 5,
  });

  messages.push(choice);
  messages.push({
    role: "tool",
    tool_call_id: toolCall.id,
    content: JSON.stringify(toolResultPayload(results)),
  });

  const second = await openai.chat.completions.create({
    model: env.OPENAI_CHAT_MODEL,
    temperature: 0.4,
    messages,
  });

  return {
    reply: second.choices[0]?.message.content ?? "",
    results,
  };
}

function parseToolArgs(raw: string) {
  try {
    const args = JSON.parse(raw);
    return searchFiltersSchema.partial().parse(args);
  } catch {
    return undefined;
  }
}

/** Compact, grounded payload handed back to the model for formatting. */
function toolResultPayload(results: SearchResult[]) {
  return results.map((r) => ({
    name: r.restaurant.name,
    neighborhood: r.restaurant.neighborhood,
    borough: r.restaurant.borough,
    cuisine: r.restaurant.cuisine_tags,
    price_tier: r.restaurant.price_tier,
    vibe: r.restaurant.vibe_tags,
    must_try: (r.restaurant.dishes ?? [])
      .filter((d) => d.is_must_try)
      .map((d) => d.name),
    booking: r.booking_links.map((b) => ({ provider: b.provider, url: b.url })),
    health_grade: r.restaurant.health_grade,
  }));
}

/** Deterministic fallback when OpenAI is not configured. */
async function fallbackChat(req: ChatRequest): Promise<ChatResponse> {
  const { results } = await runSearch({ query: req.message, limit: 5 });
  if (results.length === 0) {
    return {
      reply:
        "I couldn't find a match in the BiteNYC catalog. Try a different neighborhood or loosen the budget.",
      results: [],
    };
  }
  const lines = results.map((r, i) => {
    const mustTry = (r.restaurant.dishes ?? [])
      .filter((d) => d.is_must_try)
      .map((d) => d.name)
      .slice(0, 2)
      .join(", ");
    const booking = r.booking_links[0]?.label ?? "Walk-in";
    return `${i + 1}. ${r.restaurant.name} (${r.restaurant.neighborhood})\nWhy it fits: ${
      r.restaurant.editorial_summary ?? r.restaurant.description ?? ""
    }\nMust try: ${mustTry || "ask the staff"}\nBooking: ${booking}`;
  });
  return {
    reply: `Here are ${results.length} picks:\n\n${lines.join("\n\n")}`,
    results,
  };
}
