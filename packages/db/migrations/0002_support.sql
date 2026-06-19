-- ===========================================================================
-- 0002_support: reference + moderation + saved-lists tables
-- ===========================================================================

-- --- neighborhoods (controlled vocabulary for the admin pickers) ------------
create table if not exists neighborhoods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  borough text not null check (borough in (
    'Manhattan',
    'Brooklyn',
    'Queens',
    'Bronx',
    'Staten Island'
  )),
  -- which MVP phase introduces this neighborhood (1-4)
  mvp_phase int not null default 1 check (mvp_phase between 1 and 4),
  is_active boolean not null default true,
  created_at timestamptz default now(),
  unique (name, borough)
);

-- --- content moderation: reports (App Store Guideline 1.2) ------------------
create table if not exists content_reports (
  id uuid primary key default gen_random_uuid(),

  target_type text not null check (target_type in (
    'restaurant', 'media_item', 'dish', 'review'
  )),
  target_id uuid not null,

  reason text not null check (reason in (
    'spam', 'nsfw', 'inaccurate', 'abusive', 'copyright', 'other'
  )),
  details text,
  reporter_id text,

  status text not null default 'open' check (status in (
    'open', 'reviewing', 'resolved', 'dismissed'
  )),
  resolution_note text,
  resolved_by text,
  resolved_at timestamptz,

  created_at timestamptz default now()
);

-- --- restaurant owner takedown requests ------------------------------------
create table if not exists takedown_requests (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references restaurants(id) on delete cascade,

  requester_name text not null,
  requester_email text not null,
  relationship text not null check (relationship in (
    'owner', 'manager', 'legal', 'other'
  )),
  details text,

  status text not null default 'open' check (status in (
    'open', 'reviewing', 'resolved', 'dismissed'
  )),
  resolution_note text,
  resolved_by text,
  resolved_at timestamptz,

  created_at timestamptz default now()
);

-- --- saved lists (for the future iOS client) -------------------------------
create table if not exists saved_lists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  name text not null,
  emoji text,
  is_public boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists saved_list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid references saved_lists(id) on delete cascade,
  restaurant_id uuid references restaurants(id) on delete cascade,
  note text,
  created_at timestamptz default now(),
  unique (list_id, restaurant_id)
);

drop trigger if exists trg_saved_lists_updated_at on saved_lists;
create trigger trg_saved_lists_updated_at
  before update on saved_lists
  for each row execute function set_updated_at();
