-- ===========================================================================
-- 0001_init: core BiteNYC entities (NYC-only)
-- ===========================================================================

create extension if not exists "pgcrypto";
create extension if not exists vector;

-- --- restaurants -----------------------------------------------------------
create table if not exists restaurants (
  id uuid primary key default gen_random_uuid(),

  name text not null,
  slug text unique not null,

  description text,
  editorial_summary text,

  address text not null,
  neighborhood text not null,
  borough text not null check (borough in (
    'Manhattan',
    'Brooklyn',
    'Queens',
    'Bronx',
    'Staten Island'
  )),

  city text not null default 'New York',
  state text not null default 'NY',
  country text not null default 'USA',

  latitude double precision not null,
  longitude double precision not null,

  cuisine_tags text[] default '{}',
  vibe_tags text[] default '{}',
  occasion_tags text[] default '{}',
  dietary_tags text[] default '{}',

  price_tier int check (price_tier between 1 and 4),
  rating numeric(2,1),
  review_count int default 0,

  google_place_id text,
  yelp_business_id text,
  opentable_id text,
  resy_url text,
  tock_url text,
  direct_booking_url text,

  health_grade text,
  health_grade_date date,
  health_inspection_score int,

  is_walk_in_friendly boolean default false,
  is_good_for_date boolean default false,
  is_good_for_groups boolean default false,
  is_good_for_working boolean default false,
  is_open_late boolean default false,
  is_tourist_friendly boolean default false,

  popularity_score numeric default 0,
  editorial_score numeric default 0,

  status text default 'draft' check (status in ('draft', 'published', 'archived')),

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- --- dishes ----------------------------------------------------------------
create table if not exists dishes (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references restaurants(id) on delete cascade,

  name text not null,
  description text,
  why_try text,

  dish_type text,
  tags text[] default '{}',

  is_must_try boolean default false,
  rank int default 0,

  photo_url text,
  created_at timestamptz default now()
);

-- --- media_items -----------------------------------------------------------
create table if not exists media_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references restaurants(id) on delete cascade,
  dish_id uuid references dishes(id) on delete set null,

  media_type text not null check (media_type in ('photo', 'video', 'embed')),
  source text not null check (source in (
    'own_upload',
    'restaurant',
    'creator',
    'tiktok',
    'youtube',
    'instagram',
    'licensed_api'
  )),

  url text not null,
  thumbnail_url text,
  caption text,
  transcript text,

  creator_name text,
  creator_url text,

  rights_status text default 'unknown' check (rights_status in (
    'owned',
    'licensed',
    'embedded',
    'unknown'
  )),

  moderation_status text default 'pending' check (moderation_status in (
    'pending',
    'approved',
    'rejected'
  )),

  created_at timestamptz default now()
);

-- --- restaurant_embeddings (pgvector, OpenAI text-embedding-3-small) --------
create table if not exists restaurant_embeddings (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references restaurants(id) on delete cascade,

  content_type text not null check (content_type in (
    'restaurant_profile',
    'dish',
    'review_summary',
    'video_transcript',
    'editorial_note'
  )),

  content text not null,
  embedding vector(1536),

  created_at timestamptz default now()
);

-- keep updated_at fresh on restaurants
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_restaurants_updated_at on restaurants;
create trigger trg_restaurants_updated_at
  before update on restaurants
  for each row execute function set_updated_at();
