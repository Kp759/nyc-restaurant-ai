import { BOROUGHS } from "./boroughs.js";

/**
 * JSON-schema definition of the `search_restaurants` tool used for OpenAI
 * function calling. Used in two places:
 *  - /search: extract structured filters from the user's query
 *  - /chat: let the model call our grounded search and format the results
 *
 * Kept as a plain object (not Zod) so it can be passed straight to the OpenAI
 * `tools` parameter without conversion.
 */
export const SEARCH_RESTAURANTS_TOOL = {
  type: "function" as const,
  function: {
    name: "search_restaurants",
    description:
      "Search BiteNYC's curated New York City restaurant database. ALWAYS call this to ground any recommendation. Never invent restaurants or details; only describe places returned by this tool.",
    parameters: {
      type: "object",
      additionalProperties: false,
      properties: {
        city: {
          type: "string",
          enum: ["New York"],
          description: "Always 'New York'. BiteNYC is NYC-only.",
        },
        borough: {
          type: ["string", "null"],
          enum: [...BOROUGHS, null],
          description: "NYC borough, if the user implied or named one.",
        },
        neighborhood: {
          type: ["string", "null"],
          description:
            "NYC neighborhood, e.g. 'West Village', 'SoHo', 'Williamsburg'.",
        },
        occasion: {
          type: ["string", "null"],
          description:
            "Occasion, e.g. 'date_night', 'first_date', 'birthday', 'groups', 'work_cafe', 'visitor_dinner', 'solo_dining'.",
        },
        vibe: {
          type: "array",
          items: { type: "string" },
          description:
            "Vibe descriptors, e.g. ['cozy','aesthetic','romantic','rooftop','great_cocktails','quiet'].",
        },
        cuisine: {
          type: "array",
          items: { type: "string" },
          description: "Cuisines or dishes, e.g. ['italian','pasta','omakase','ramen'].",
        },
        budget: {
          type: "string",
          enum: ["cheap", "budget", "affordable", "moderate", "upscale", "splurge", "any"],
          description: "Rough budget level inferred from the query.",
        },
        max_price_tier: {
          type: ["integer", "null"],
          minimum: 1,
          maximum: 4,
          description:
            "Hard price ceiling 1-4 ($, $$, $$$, $$$$) if the user gave a dollar amount (e.g. 'under $150' -> 4, 'under $25' -> 1).",
        },
        party_size: {
          type: "integer",
          minimum: 1,
          description: "Number of diners. Default 2.",
        },
        open_now: {
          type: "boolean",
          description: "True if the user wants somewhere open right now / late.",
        },
        reservation_available: {
          type: "boolean",
          description: "True if the user wants a place that takes reservations.",
        },
      },
      required: ["city"],
    },
  },
} as const;
