-- ===========================================================================
-- 0003_indexes: array GIN, filter btrees, and the pgvector ivfflat index
-- ===========================================================================

-- array tag membership filters
create index if not exists idx_restaurants_cuisine_tags on restaurants using gin (cuisine_tags);
create index if not exists idx_restaurants_vibe_tags on restaurants using gin (vibe_tags);
create index if not exists idx_restaurants_occasion_tags on restaurants using gin (occasion_tags);
create index if not exists idx_restaurants_dietary_tags on restaurants using gin (dietary_tags);

-- common scalar filters
create index if not exists idx_restaurants_neighborhood on restaurants (neighborhood);
create index if not exists idx_restaurants_borough on restaurants (borough);
create index if not exists idx_restaurants_price_tier on restaurants (price_tier);
create index if not exists idx_restaurants_status on restaurants (status);
create index if not exists idx_restaurants_slug on restaurants (slug);

-- dishes + media lookups by restaurant
create index if not exists idx_dishes_restaurant on dishes (restaurant_id);
create index if not exists idx_media_restaurant on media_items (restaurant_id);
create index if not exists idx_media_moderation on media_items (moderation_status);

-- embeddings: filter by restaurant + content type, and ANN search
create index if not exists idx_embeddings_restaurant on restaurant_embeddings (restaurant_id);
create index if not exists idx_embeddings_content_type on restaurant_embeddings (content_type);

-- approximate nearest-neighbour over cosine distance.
-- NOTE: ivfflat needs data to build good lists; safe to (re)build after seeding.
create index if not exists idx_embeddings_vector
  on restaurant_embeddings using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);

-- moderation queues
create index if not exists idx_reports_status on content_reports (status);
create index if not exists idx_takedowns_status on takedown_requests (status);
