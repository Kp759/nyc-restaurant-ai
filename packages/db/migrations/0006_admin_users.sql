-- ===========================================================================
-- 0006_admin_users: role-based access for the admin CMS
--   Maps a Supabase auth user (by email) to an admin role. The admin app checks
--   membership here in middleware. Seed rows via the service role.
-- ===========================================================================

create table if not exists admin_users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  role text not null default 'editor' check (role in ('admin', 'editor')),
  created_at timestamptz default now()
);

alter table admin_users enable row level security;
-- No anon/authenticated policies: only the service role (admin app server) reads
-- this table, so RLS being on with no policy denies client access by default.
