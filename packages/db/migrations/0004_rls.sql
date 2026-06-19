-- ===========================================================================
-- 0004_rls: row level security
--   - public (anon) can READ only published content
--   - writes happen through the service role (API + admin), which bypasses RLS
--   - saved lists are owner-scoped for authenticated users
-- ===========================================================================

alter table restaurants enable row level security;
alter table dishes enable row level security;
alter table media_items enable row level security;
alter table restaurant_embeddings enable row level security;
alter table neighborhoods enable row level security;
alter table content_reports enable row level security;
alter table takedown_requests enable row level security;
alter table saved_lists enable row level security;
alter table saved_list_items enable row level security;

-- --- public reads (published only) -----------------------------------------
drop policy if exists "public read published restaurants" on restaurants;
create policy "public read published restaurants" on restaurants
  for select to anon, authenticated
  using (status = 'published');

drop policy if exists "public read dishes of published" on dishes;
create policy "public read dishes of published" on dishes
  for select to anon, authenticated
  using (exists (
    select 1 from restaurants r
    where r.id = dishes.restaurant_id and r.status = 'published'
  ));

drop policy if exists "public read approved media of published" on media_items;
create policy "public read approved media of published" on media_items
  for select to anon, authenticated
  using (
    moderation_status = 'approved'
    and exists (
      select 1 from restaurants r
      where r.id = media_items.restaurant_id and r.status = 'published'
    )
  );

drop policy if exists "public read neighborhoods" on neighborhoods;
create policy "public read neighborhoods" on neighborhoods
  for select to anon, authenticated
  using (is_active = true);

-- --- anyone can file a report / takedown (insert only) ----------------------
drop policy if exists "anyone can report" on content_reports;
create policy "anyone can report" on content_reports
  for insert to anon, authenticated
  with check (true);

drop policy if exists "anyone can request takedown" on takedown_requests;
create policy "anyone can request takedown" on takedown_requests
  for insert to anon, authenticated
  with check (true);

-- --- saved lists: owner scoped ---------------------------------------------
drop policy if exists "owner manages saved lists" on saved_lists;
create policy "owner manages saved lists" on saved_lists
  for all to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists "public read public saved lists" on saved_lists;
create policy "public read public saved lists" on saved_lists
  for select to anon, authenticated
  using (is_public = true);

drop policy if exists "owner manages saved list items" on saved_list_items;
create policy "owner manages saved list items" on saved_list_items
  for all to authenticated
  using (exists (
    select 1 from saved_lists l
    where l.id = saved_list_items.list_id and l.owner_id = auth.uid()
  ))
  with check (exists (
    select 1 from saved_lists l
    where l.id = saved_list_items.list_id and l.owner_id = auth.uid()
  ));

-- restaurant_embeddings has no public policy: server-side (service role) only.
