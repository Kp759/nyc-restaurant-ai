-- Rewrite stored Google photo proxy URLs to relative paths so mobile clients
-- can attach the current API host (fixes images on physical devices).
update media_items
set url = regexp_replace(url, '^https?://[^/]+(/photo\?.*)$', '\1')
where url ~ '/photo\?name=places/';

update media_items
set thumbnail_url = regexp_replace(thumbnail_url, '^https?://[^/]+(/photo\?.*)$', '\1')
where thumbnail_url ~ '/photo\?name=places/';
