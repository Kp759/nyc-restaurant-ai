import {
  BUDGET_TO_MAX_TIER,
  NEIGHBORHOODS,
  SEARCH_RESTAURANTS_TOOL,
  VIBE_TAGS,
  searchFiltersSchema,
  type SearchFilters,
} from "@bitenyc/shared";
import { aiEnabled, env } from "../env.js";
import { getOpenAI } from "../openai.js";

type PartialFilters = Partial<SearchFilters>;

/**
 * Resolve final filters from the user's query, optionally merged with UI-set
 * overrides. Uses OpenAI function calling when available; otherwise falls back
 * to a deterministic keyword heuristic so /search works without an API key.
 */
export async function extractFilters(
  query: string,
  overrides?: PartialFilters,
): Promise<SearchFilters> {
  const base = aiEnabled ? await extractWithAI(query) : extractHeuristic(query);
  const merged = applyBudget({ ...base, ...stripUndefined(overrides ?? {}) });
  return searchFiltersSchema.parse({ city: "New York", ...merged });
}

function stripUndefined<T extends Record<string, unknown>>(obj: T): Partial<T> {
  return Object.fromEntries(
    Object.entries(obj).filter(([, v]) => v !== undefined && v !== null),
  ) as Partial<T>;
}

/** Translate a budget word into a price-tier ceiling when not already set. */
function applyBudget(filters: PartialFilters): PartialFilters {
  if (filters.max_price_tier == null && filters.budget) {
    const tier = BUDGET_TO_MAX_TIER[filters.budget];
    if (tier) return { ...filters, max_price_tier: tier };
  }
  return filters;
}

async function extractWithAI(query: string): Promise<PartialFilters> {
  const openai = getOpenAI();
  const completion = await openai.chat.completions.create({
    model: env.OPENAI_CHAT_MODEL,
    temperature: 0,
    messages: [
      {
        role: "system",
        content:
          "You convert a New York City restaurant search into structured filters. BiteNYC is NYC-only, so city is always 'New York'. Infer neighborhood, occasion, vibe, cuisine, budget, and price ceiling from the user's words. Call the search_restaurants tool exactly once.",
      },
      { role: "user", content: query },
    ],
    tools: [SEARCH_RESTAURANTS_TOOL],
    tool_choice: {
      type: "function",
      function: { name: SEARCH_RESTAURANTS_TOOL.function.name },
    },
  });

  const call = completion.choices[0]?.message.tool_calls?.[0];
  if (!call) return extractHeuristic(query);
  try {
    const args = JSON.parse(call.function.arguments) as PartialFilters;
    return stripUndefined(args);
  } catch {
    return extractHeuristic(query);
  }
}

const BUDGET_KEYWORDS: Array<[RegExp, SearchFilters["budget"]]> = [
  [/cheap|inexpensive/i, "cheap"],
  [/affordable|under \$?25/i, "affordable"],
  [/moderate|mid-range|under \$?50/i, "moderate"],
  [/upscale|fancy|fine dining|splurge|under \$?1\d0/i, "upscale"],
];

const OCCASION_KEYWORDS: Array<[RegExp, string]> = [
  [/first date/i, "first_date"],
  [/date night|date|romantic/i, "date_night"],
  [/birthday/i, "birthday"],
  [/solo|by myself|alone/i, "solo_dining"],
  [/group|friends|party/i, "groups"],
  [/work|laptop|study|cafe to work/i, "work_cafe"],
  [/visiting|tourist|in town|show (them|someone)/i, "visitor_dinner"],
];

/** Deterministic keyword fallback used when OpenAI is not configured. */
export function extractHeuristic(query: string): PartialFilters {
  const q = query.toLowerCase();
  const filters: PartialFilters = { vibe: [], cuisine: [] };

  const hood = NEIGHBORHOODS.find((n) => q.includes(n.name.toLowerCase()));
  if (hood) {
    filters.neighborhood = hood.name;
    filters.borough = hood.borough;
  }

  for (const [re, occ] of OCCASION_KEYWORDS) {
    if (re.test(q)) {
      filters.occasion = occ;
      break;
    }
  }

  filters.vibe = VIBE_TAGS.filter((tag) => q.includes(tag.replace(/_/g, " ")));

  for (const [re, budget] of BUDGET_KEYWORDS) {
    if (re.test(q)) {
      filters.budget = budget;
      break;
    }
  }

  const dollar = q.match(/under \$?(\d{2,3})/);
  if (dollar?.[1]) {
    const amount = Number(dollar[1]);
    filters.max_price_tier = amount <= 25 ? 1 : amount <= 50 ? 2 : amount <= 100 ? 3 : 4;
  }

  if (/open late|late night|late-night/i.test(q)) filters.open_now = true;
  if (/reservation|book|reserve/i.test(q)) filters.reservation_available = true;

  return filters;
}
