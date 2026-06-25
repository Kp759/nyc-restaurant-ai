-- ===========================================================================
-- 0007_social: per-restaurant social profile links (Instagram / X / Facebook)
-- ===========================================================================

alter table restaurants
  add column if not exists instagram_url text,
  add column if not exists x_url text,
  add column if not exists facebook_url text;
