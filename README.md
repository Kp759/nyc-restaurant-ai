# BiteNYC

An AI-powered restaurant, cafe, and date-night discovery app for **New York City only**.

> Find the right NYC restaurant by vibe, dish, neighborhood, occasion, and reservation availability.

This repository contains the **foundation**: the database, the backend API with grounded AI search, and the admin CMS used to curate the first 300-500 NYC listings. The SwiftUI iOS client is a future workstream that consumes this API.

## Launch coverage (curated, staged)

| Phase | Coverage | Target listings |
| ----- | -------- | --------------- |
| MVP 1 | Manhattan below 59th + Williamsburg + Greenpoint | 300-500 |
| MVP 2 | Brooklyn: Dumbo, Fort Greene, Park Slope, Bushwick, Bed-Stuy | +300 |
| MVP 3 | Queens: Astoria, LIC, Flushing, Jackson Heights | +300 |
| MVP 4 | Bronx + Staten Island + full NYC | +500 |

## Monorepo layout

```
bitenyc/
├── packages/
│   ├── shared/   # Shared TS types + Zod schemas (boroughs, tags, DTOs, contracts)
│   └── db/       # Supabase SQL migrations + seed data
├── apps/
│   ├── api/      # Fastify + TypeScript backend (search, chat, moderation)
│   └── admin/    # Next.js admin CMS (curation + moderation queue)
└── scripts/      # Data jobs: Google Places / Yelp / DOHMH health / embeddings
```

## Tech stack

- **DB:** Supabase Postgres + `pgvector`
- **API:** Node.js + TypeScript + Fastify, OpenAI (embeddings + function calling)
- **Admin:** Next.js (App Router) + Supabase Auth (role-based)
- **Data jobs:** TypeScript scripts (Google Places, Yelp, NYC DOHMH, embeddings)

## Getting started

```bash
# 1. Install deps (pnpm via corepack)
corepack pnpm@9.12.0 install

# 2. Configure environment
cp .env.example .env                         # API + data jobs (Supabase + OpenAI)
cp apps/admin/.env.local.example apps/admin/.env.local   # admin (Next loads its own env)

# 3. Apply the database schema to your Supabase project, then seed
pnpm --filter @bitenyc/db migrate
pnpm --filter @bitenyc/db seed

# 4. Create your first admin user (auth user + admin_users allowlist)
pnpm --filter @bitenyc/scripts create:admin -- you@example.com 'a-strong-password' admin

# 5. Run the services
pnpm dev:api      # http://localhost:4000
pnpm dev:admin    # http://localhost:3000

# 6. (Optional) Import + enrich + embed real NYC data
pnpm --filter @bitenyc/scripts import:places   # Google Places -> drafts
pnpm --filter @bitenyc/scripts match:yelp      # Yelp enrichment
pnpm --filter @bitenyc/scripts match:health    # NYC DOHMH health grades
pnpm --filter @bitenyc/scripts embeddings      # OpenAI embeddings
```

> Note: `pnpm` is provided via corepack. If `pnpm` isn't on your PATH, run
> `corepack enable` once, or prefix commands with `corepack pnpm@9.12.0`.

## AI search

Recommendations are **grounded** in the database. The model extracts structured
filters from a natural-language query, BiteNYC retrieves candidates via hard
filters + pgvector similarity, re-ranks them with a weighted formula, and only
then asks the model to format the results. The model never invents restaurants.

```
final_score =
  0.25*semantic + 0.20*vibe + 0.15*neighborhood + 0.10*dish
+ 0.10*editorial + 0.08*review + 0.05*reservation + 0.04*media
+ 0.03*health
```

## Reservations

Deep links only for the MVP, surfaced in provider order:
Resy → OpenTable → Tock → SevenRooms → Direct website → Phone.
Live availability comes later, after partner/API approval.

## Content moderation

Per Apple App Store Guideline 1.2, the schema and admin ship with report
content, owner takedown requests, and a moderation queue from day one.
