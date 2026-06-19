-- ===========================================================================
-- 0005_search_fn: grounded candidate retrieval for AI search
--   match_restaurant_embeddings(query_embedding, match_count, filters)
--   - applies hard filters (borough / neighborhood / price / open / booking)
--   - ANN over restaurant_embeddings via cosine distance
--   - returns one row per restaurant with its BEST matching-content similarity
-- ===========================================================================

create or replace function match_restaurant_embeddings(
  query_embedding vector(1536),
  match_count int default 30,
  filters jsonb default '{}'::jsonb
)
returns table (
  restaurant_id uuid,
  similarity double precision,
  best_content_type text
)
language sql
stable
as $$
  with scoped as (
    select
      e.restaurant_id,
      e.content_type,
      1 - (e.embedding <=> query_embedding) as similarity
    from restaurant_embeddings e
    join restaurants r on r.id = e.restaurant_id
    where r.status = 'published'
      and e.embedding is not null
      and (
        filters->>'borough' is null
        or r.borough = filters->>'borough'
      )
      and (
        filters->>'neighborhood' is null
        or r.neighborhood = filters->>'neighborhood'
      )
      and (
        filters->>'max_price_tier' is null
        or r.price_tier is null
        or r.price_tier <= (filters->>'max_price_tier')::int
      )
      and (
        coalesce((filters->>'open_now')::boolean, false) = false
        or r.is_open_late = true
      )
      and (
        coalesce((filters->>'reservation_available')::boolean, false) = false
        or r.resy_url is not null
        or r.opentable_id is not null
        or r.tock_url is not null
        or r.direct_booking_url is not null
      )
  ),
  ranked as (
    select
      restaurant_id,
      content_type,
      similarity,
      row_number() over (
        partition by restaurant_id order by similarity desc
      ) as rn
    from scoped
  )
  select restaurant_id, similarity, content_type as best_content_type
  from ranked
  where rn = 1
  order by similarity desc
  limit match_count;
$$;
