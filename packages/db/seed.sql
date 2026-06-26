-- ===========================================================================
-- seed.sql: NYC neighborhoods + sample published restaurants for development.
-- Idempotent: neighborhoods upsert on (name, borough); sample restaurants use
-- fixed UUIDs and are deleted (cascade) before re-insert.
-- ===========================================================================

-- --- neighborhoods (controlled vocabulary, by MVP phase) --------------------
insert into neighborhoods (name, borough, mvp_phase) values
  -- MVP 1
  ('West Village', 'Manhattan', 1),
  ('East Village', 'Manhattan', 1),
  ('Greenwich Village', 'Manhattan', 1),
  ('SoHo', 'Manhattan', 1),
  ('Nolita', 'Manhattan', 1),
  ('Lower East Side', 'Manhattan', 1),
  ('Chinatown', 'Manhattan', 1),
  ('Flatiron', 'Manhattan', 1),
  ('Chelsea', 'Manhattan', 1),
  ('Gramercy', 'Manhattan', 1),
  ('NoMad', 'Manhattan', 1),
  ('Tribeca', 'Manhattan', 1),
  ('Financial District', 'Manhattan', 1),
  ('Hell''s Kitchen', 'Manhattan', 1),
  ('Midtown', 'Manhattan', 1),
  ('Williamsburg', 'Brooklyn', 1),
  ('Greenpoint', 'Brooklyn', 1),
  -- MVP 2
  ('Dumbo', 'Brooklyn', 2),
  ('Brooklyn Heights', 'Brooklyn', 2),
  ('Fort Greene', 'Brooklyn', 2),
  ('Park Slope', 'Brooklyn', 2),
  ('Bushwick', 'Brooklyn', 2),
  ('Bed-Stuy', 'Brooklyn', 2),
  -- MVP 3
  ('Astoria', 'Queens', 3),
  ('Long Island City', 'Queens', 3),
  ('Flushing', 'Queens', 3),
  ('Jackson Heights', 'Queens', 3),
  -- MVP 4
  ('South Bronx', 'Bronx', 4),
  ('Arthur Avenue', 'Bronx', 4),
  ('St. George', 'Staten Island', 4)
on conflict (name, borough) do update set mvp_phase = excluded.mvp_phase;

-- --- sample restaurants -----------------------------------------------------
-- Wipe prior sample rows (cascade removes dishes/media/embeddings).
delete from restaurants where id in (
  '11111111-1111-1111-1111-111111111101',
  '11111111-1111-1111-1111-111111111102',
  '11111111-1111-1111-1111-111111111103',
  '11111111-1111-1111-1111-111111111104',
  '11111111-1111-1111-1111-111111111105',
  '11111111-1111-1111-1111-111111111106',
  '11111111-1111-1111-1111-111111111107',
  '11111111-1111-1111-1111-111111111108',
  '11111111-1111-1111-1111-111111111109',
  '11111111-1111-1111-1111-111111111110'
);

insert into restaurants (
  id, name, slug, description, editorial_summary, address, neighborhood, borough,
  latitude, longitude, cuisine_tags, vibe_tags, occasion_tags, dietary_tags,
  price_tier, rating, review_count, resy_url, opentable_id, tock_url, direct_booking_url,
  health_grade, health_grade_date, health_inspection_score,
  is_walk_in_friendly, is_good_for_date, is_good_for_groups, is_good_for_working,
  is_open_late, is_tourist_friendly, popularity_score, editorial_score, status
) values
  (
    '11111111-1111-1111-1111-111111111101',
    'Lilia''s Corner', 'lilias-corner',
    'Intimate West Village trattoria with handmade pasta and a candlelit back room.',
    'A perennial first-date favorite: dim lighting, a tight wine list, and pasta that overdelivers for the price.',
    '54 Bedford St', 'West Village', 'Manhattan',
    40.7305, -74.0040,
    array['italian','pasta','wine_bar'],
    array['cozy','romantic','intimate','dim_lighting','good_wine_list'],
    array['date_night','first_date','anniversary'],
    array['vegetarian'],
    3, 4.7, 1280,
    'https://resy.com/cities/ny/lilias-corner', null, null, 'https://liliascorner.example.com/reserve',
    'A', '2026-03-12', 9,
    false, true, false, false, false, true, 92, 88, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111102',
    'Maison Mott', 'maison-mott',
    'SoHo all-day cafe with marble tables, natural light, and excellent espresso.',
    'The platonic SoHo aesthetic cafe: photogenic interiors, laptop-friendly mornings, and a strong matcha program.',
    '180 Mott St', 'SoHo', 'Manhattan',
    40.7212, -73.9957,
    array['cafe','coffee','brunch','french'],
    array['aesthetic','stylish','cozy','quiet','instagrammable','good_for_working'],
    array['work_cafe','solo_dining','first_date','brunch'],
    array['vegetarian','vegan'],
    2, 4.5, 860,
    null, null, null, 'https://maisonmott.example.com',
    'A', '2026-01-22', 11,
    true, false, false, true, false, true, 81, 84, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111103',
    'Rotolo East', 'rotolo-east',
    'East Village casual Italian spot known for spicy rigatoni and natural wine.',
    'Loud, fun, and affordable - the kind of weeknight dinner that turns into a late one.',
    '110 St Marks Pl', 'East Village', 'Manhattan',
    40.7274, -73.9845,
    array['italian','pasta','natural_wine'],
    array['lively','casual','trendy','great_cocktails'],
    array['date_night','groups','birthday'],
    array['vegetarian'],
    2, 4.4, 640,
    'https://resy.com/cities/ny/rotolo-east', null, null, null,
    'A', '2026-02-08', 12,
    true, true, true, false, true, false, 76, 70, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111104',
    'Kura Omakase', 'kura-omakase',
    'Twelve-seat Williamsburg omakase counter with a focused nigiri progression.',
    'A serious sushi counter that still comes in under $150 - book ahead, it sells out.',
    '215 Wythe Ave', 'Williamsburg', 'Brooklyn',
    40.7218, -73.9576,
    array['japanese','sushi','omakase'],
    array['intimate','upscale','quiet','michelin_style'],
    array['date_night','anniversary','business_meal'],
    array[]::text[],
    4, 4.8, 410,
    'https://resy.com/cities/ny/kura-omakase', null, 'https://www.exploretock.com/kura-omakase', null,
    'A', '2026-04-01', 7,
    false, true, false, false, false, false, 88, 90, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111105',
    'Ferns Greenpoint', 'ferns-greenpoint',
    'Plant-filled Greenpoint cafe with slow mornings and a quiet work-friendly back.',
    'The cozy Greenpoint corner you go to with a book - great drip coffee, better pastries.',
    '108 Franklin St', 'Greenpoint', 'Brooklyn',
    40.7301, -73.9580,
    array['cafe','coffee','bakery'],
    array['cozy','aesthetic','quiet','good_for_working'],
    array['work_cafe','solo_dining','brunch'],
    array['vegetarian','vegan','gluten_free'],
    1, 4.6, 520,
    null, null, null, 'https://ferns.example.com',
    'A', '2026-03-30', 10,
    true, false, false, true, false, false, 70, 79, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111106',
    'Dimes Late', 'dimes-late',
    'Lower East Side late-night kitchen serving noodles and natural wine till 2am.',
    'Where downtown ends up after midnight - bright flavors, low lighting, no pretense.',
    '49 Canal St', 'Lower East Side', 'Manhattan',
    40.7146, -73.9920,
    array['asian','noodles','cocktails'],
    array['late_night','trendy','lively','great_cocktails'],
    array['groups','date_night','solo_dining'],
    array['vegetarian'],
    2, 4.3, 980,
    null, null, null, null,
    'B', '2026-02-19', 18,
    true, true, true, false, true, true, 74, 66, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111107',
    'Quill Tribeca', 'quill-tribeca',
    'Upscale Tribeca tasting-menu restaurant with a hushed dining room.',
    'Tribeca special-occasion benchmark: precise cooking, deep cellar, impeccable service.',
    '173 Franklin St', 'Tribeca', 'Manhattan',
    40.7184, -74.0090,
    array['american','tasting_menu','fine_dining'],
    array['upscale','quiet','romantic','michelin_style','good_wine_list'],
    array['anniversary','business_meal','date_night'],
    array['vegetarian'],
    4, 4.7, 350,
    null, '1234567', 'https://www.exploretock.com/quill-tribeca', null,
    'A', '2026-01-15', 6,
    false, true, false, false, false, true, 85, 92, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111108',
    'Highline Rooftop', 'highline-rooftop',
    'Chelsea rooftop bar and grill with skyline views and a big cocktail list.',
    'Birthday-dinner energy with a view - come for sunset, stay for the cocktails.',
    '447 W 16th St', 'Chelsea', 'Manhattan',
    40.7426, -74.0060,
    array['american','grill','cocktails'],
    array['rooftop','lively','trendy','great_cocktails','instagrammable'],
    array['birthday','groups','date_night'],
    array['vegetarian','gluten_free'],
    3, 4.2, 1500,
    'https://resy.com/cities/ny/highline-rooftop', '7654321', null, null,
    'A', '2026-03-05', 12,
    false, true, true, false, true, true, 90, 72, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111109',
    'Sotto Flatiron', 'sotto-flatiron',
    'Flatiron pasta bar with a buzzy counter and an excellent cacio e pepe.',
    'Solid downtown-adjacent pasta date spot - walk-in seats at the bar if you time it right.',
    '12 E 22nd St', 'Flatiron', 'Manhattan',
    40.7398, -73.9885,
    array['italian','pasta','wine_bar'],
    array['trendy','lively','great_cocktails'],
    array['date_night','groups'],
    array['vegetarian'],
    3, 4.5, 720,
    'https://resy.com/cities/ny/sotto-flatiron', null, null, null,
    'A', '2026-02-27', 9,
    true, true, true, false, false, false, 79, 75, 'published'
  ),
  (
    '11111111-1111-1111-1111-111111111110',
    'Nolita Nook', 'nolita-nook',
    'Tiny Nolita dessert-and-coffee nook famous for its pistachio soft serve.',
    'The after-dinner move in Nolita - aesthetic, cheap, and reliably packed.',
    '23 Prince St', 'Nolita', 'Manhattan',
    40.7233, -73.9949,
    array['cafe','dessert','coffee'],
    array['aesthetic','cozy','dessert_spot','instagrammable','tiktok_popular'],
    array['solo_dining','first_date'],
    array['vegetarian'],
    1, 4.6, 1100,
    null, null, null, null,
    'A', '2026-04-10', 8,
    true, false, false, false, true, true, 83, 68, 'published'
  );

-- --- dishes -----------------------------------------------------------------
insert into dishes (restaurant_id, name, description, why_try, dish_type, tags, is_must_try, rank) values
  ('11111111-1111-1111-1111-111111111101', 'Spicy Rigatoni', 'Vodka sauce with calabrian chili', 'The dish people come back for', 'pasta', array['signature','spicy'], true, 1),
  ('11111111-1111-1111-1111-111111111101', 'Tiramisu', 'Espresso-soaked ladyfingers', 'Best shared at the end of a date', 'dessert', array['classic'], true, 2),
  ('11111111-1111-1111-1111-111111111101', 'Cacio e Pepe', 'Pecorino and black pepper', 'Simple and perfectly executed', 'pasta', array['vegetarian'], false, 3),

  ('11111111-1111-1111-1111-111111111102', 'Iced Matcha', 'Ceremonial-grade matcha latte', 'The most photographed drink in the room', 'drink', array['signature'], true, 1),
  ('11111111-1111-1111-1111-111111111102', 'Egg & Gruyere Tartine', 'Open-faced on sourdough', 'Great solo work-from-cafe lunch', 'brunch', array['vegetarian'], true, 2),
  ('11111111-1111-1111-1111-111111111102', 'Almond Croissant', 'Twice-baked, house-made', 'Pairs with the espresso', 'pastry', array['vegetarian'], false, 3),

  ('11111111-1111-1111-1111-111111111103', 'Spicy Rigatoni', 'Spicy tomato cream', 'Cheap thrills done right', 'pasta', array['signature','spicy'], true, 1),
  ('11111111-1111-1111-1111-111111111103', 'Burrata', 'With charred bread', 'Easy group starter', 'appetizer', array['vegetarian'], true, 2),
  ('11111111-1111-1111-1111-111111111103', 'Negroni', 'Classic, stirred', 'Order before the table fills up', 'cocktail', array['signature'], false, 3),

  ('11111111-1111-1111-1111-111111111104', 'Otoro Nigiri', 'Fatty bluefin tuna', 'The peak of the progression', 'sushi', array['signature'], true, 1),
  ('11111111-1111-1111-1111-111111111104', 'Uni Hand Roll', 'Hokkaido uni, warm rice', 'Worth the splurge', 'sushi', array['signature'], true, 2),
  ('11111111-1111-1111-1111-111111111104', 'Tamago', 'House sweet egg', 'A quiet showstopper to close', 'sushi', array[]::text[], false, 3),

  ('11111111-1111-1111-1111-111111111105', 'Drip Coffee', 'Rotating single origin', 'The reason regulars return', 'drink', array['signature'], true, 1),
  ('11111111-1111-1111-1111-111111111105', 'Cardamom Bun', 'Laminated, lightly spiced', 'Sells out by noon', 'pastry', array['vegetarian'], true, 2),
  ('11111111-1111-1111-1111-111111111105', 'Avocado Toast', 'On seeded sourdough', 'Reliable work-cafe fuel', 'brunch', array['vegan'], false, 3),

  ('11111111-1111-1111-1111-111111111106', 'Dan Dan Noodles', 'Sichuan pepper, pork', 'The late-night anchor', 'noodles', array['signature','spicy'], true, 1),
  ('11111111-1111-1111-1111-111111111106', 'Scallion Pancake', 'Crispy, flaky', 'Great for the table', 'appetizer', array['vegetarian'], true, 2),
  ('11111111-1111-1111-1111-111111111106', 'House Martini', 'Cold and dry', 'Pairs with everything spicy', 'cocktail', array['signature'], false, 3),

  ('11111111-1111-1111-1111-111111111107', 'Tasting Menu', 'Seasonal, multi-course', 'The whole point of coming', 'tasting', array['signature'], true, 1),
  ('11111111-1111-1111-1111-111111111107', 'Aged Duck', 'Dry-aged, served two ways', 'A standout main course', 'main', array['signature'], true, 2),
  ('11111111-1111-1111-1111-111111111107', 'Chocolate Souffle', 'To order at start of meal', 'Worth planning around', 'dessert', array['vegetarian'], false, 3),

  ('11111111-1111-1111-1111-111111111108', 'Skyline Spritz', 'House aperitivo', 'Sunset in a glass', 'cocktail', array['signature'], true, 1),
  ('11111111-1111-1111-1111-111111111108', 'Wagyu Sliders', 'Three to an order', 'Best group share', 'main', array['signature'], true, 2),
  ('11111111-1111-1111-1111-111111111108', 'Grilled Branzino', 'Whole, lemon, herbs', 'Lighter option with a view', 'main', array['gluten_free'], false, 3),

  ('11111111-1111-1111-1111-111111111109', 'Cacio e Pepe', 'Tableside finish', 'The signature plate', 'pasta', array['signature','vegetarian'], true, 1),
  ('11111111-1111-1111-1111-111111111109', 'Bone Marrow', 'With grilled bread', 'Rich starter to share', 'appetizer', array['signature'], true, 2),
  ('11111111-1111-1111-1111-111111111109', 'Spritz', 'Aperol or Hugo', 'Easy aperitif at the bar', 'cocktail', array[]::text[], false, 3),

  ('11111111-1111-1111-1111-111111111110', 'Pistachio Soft Serve', 'Sicilian pistachio', 'The TikTok-famous cone', 'dessert', array['signature','vegetarian'], true, 1),
  ('11111111-1111-1111-1111-111111111110', 'Affogato', 'Espresso over soft serve', 'The grown-up order', 'dessert', array['vegetarian'], true, 2),
  ('11111111-1111-1111-1111-111111111110', 'Cortado', 'Small and strong', 'Good walking coffee', 'drink', array[]::text[], false, 3);

-- --- sample phones (for Call button in the app) ---------------------------
update restaurants set phone = '(212) 555-0101' where id = '11111111-1111-1111-1111-111111111101';
update restaurants set phone = '(212) 555-0102' where id = '11111111-1111-1111-1111-111111111102';
update restaurants set phone = '(212) 555-0103' where id = '11111111-1111-1111-1111-111111111103';
update restaurants set phone = '(718) 555-0104' where id = '11111111-1111-1111-1111-111111111104';
update restaurants set phone = '(718) 555-0105' where id = '11111111-1111-1111-1111-111111111105';
update restaurants set phone = '(212) 555-0106' where id = '11111111-1111-1111-1111-111111111106';
update restaurants set phone = '(212) 555-0107' where id = '11111111-1111-1111-1111-111111111107';
update restaurants set phone = '(212) 555-0108' where id = '11111111-1111-1111-1111-111111111108';
update restaurants set phone = '(212) 555-0109' where id = '11111111-1111-1111-1111-111111111109';
update restaurants set phone = '(212) 555-0110' where id = '11111111-1111-1111-1111-111111111110';

-- --- media items (photos + embeds) -----------------------------------------
insert into media_items (restaurant_id, media_type, source, url, thumbnail_url, caption, creator_name, creator_url, rights_status, moderation_status) values
  ('11111111-1111-1111-1111-111111111101', 'photo', 'restaurant', 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200&q=80', 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&q=80', 'The candlelit back room', null, null, 'owned', 'approved'),
  ('11111111-1111-1111-1111-111111111101', 'embed', 'tiktok', 'https://www.tiktok.com/@food/video/1000000000000000001', 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=600&q=80', 'Spicy rigatoni close-up', 'nycpastaguy', 'https://www.tiktok.com/@nycpastaguy', 'embedded', 'approved'),
  ('11111111-1111-1111-1111-111111111102', 'photo', 'restaurant', 'https://images.unsplash.com/photo-1495474472287-4d089bc0b663?w=1200&q=80', 'https://images.unsplash.com/photo-1495474472287-4d089bc0b663?w=600&q=80', 'Marble tables, morning light', null, null, 'owned', 'approved'),
  ('11111111-1111-1111-1111-111111111102', 'embed', 'youtube', 'https://www.youtube.com/shorts/aaaaaaaaaa1', 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&q=80', 'Matcha pour', 'sohocafes', 'https://youtube.com/@sohocafes', 'embedded', 'approved'),
  ('11111111-1111-1111-1111-111111111103', 'photo', 'creator', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200&q=80', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80', 'Weeknight buzz', 'evdiner', 'https://instagram.com/evdiner', 'licensed', 'approved'),
  ('11111111-1111-1111-1111-111111111104', 'photo', 'restaurant', 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=1200&q=80', 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=600&q=80', 'The twelve-seat counter', null, null, 'owned', 'approved'),
  ('11111111-1111-1111-1111-111111111104', 'embed', 'tiktok', 'https://www.tiktok.com/@sushi/video/1000000000000000004', 'https://images.unsplash.com/photo-1611146879225-0d8700889f68?w=600&q=80', 'Otoro nigiri', 'bksushi', 'https://www.tiktok.com/@bksushi', 'embedded', 'approved'),
  ('11111111-1111-1111-1111-111111111105', 'photo', 'restaurant', 'https://images.unsplash.com/photo-1501339847302-ac925a4b04fe?w=1200&q=80', 'https://images.unsplash.com/photo-1501339847302-ac925a4b04fe?w=600&q=80', 'Plant-filled back room', null, null, 'owned', 'approved'),
  ('11111111-1111-1111-1111-111111111106', 'photo', 'creator', 'https://images.unsplash.com/photo-1569718212165-3a8278dfe799?w=1200&q=80', 'https://images.unsplash.com/photo-1569718212165-3a8278dfe799?w=600&q=80', 'Late-night dan dan', 'lesnights', 'https://instagram.com/lesnights', 'licensed', 'approved'),
  ('11111111-1111-1111-1111-111111111107', 'photo', 'restaurant', 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200&q=80', 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&q=80', 'The hushed dining room', null, null, 'owned', 'approved'),
  ('11111111-1111-1111-1111-111111111108', 'photo', 'restaurant', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200&q=80', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600&q=80', 'Skyline at sunset', null, null, 'owned', 'approved'),
  ('11111111-1111-1111-1111-111111111108', 'embed', 'tiktok', 'https://www.tiktok.com/@rooftops/video/1000000000000000008', 'https://images.unsplash.com/photo-1566417713940-7f1e4c4e8661?w=600&q=80', 'Sunset spritz', 'nycrooftops', 'https://www.tiktok.com/@nycrooftops', 'embedded', 'approved'),
  ('11111111-1111-1111-1111-111111111109', 'photo', 'restaurant', 'https://images.unsplash.com/photo-1476124369491-e679abbca7be?w=1200&q=80', 'https://images.unsplash.com/photo-1476124369491-e679abbca7be?w=600&q=80', 'The pasta bar', null, null, 'owned', 'approved'),
  ('11111111-1111-1111-1111-111111111110', 'embed', 'tiktok', 'https://www.tiktok.com/@dessert/video/1000000000000000010', 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=600&q=80', 'Pistachio soft serve', 'nycsweets', 'https://www.tiktok.com/@nycsweets', 'embedded', 'approved'),
  ('11111111-1111-1111-1111-111111111110', 'photo', 'restaurant', 'https://images.unsplash.com/photo-1488477181941-7818a87d0933?w=1200&q=80', 'https://images.unsplash.com/photo-1488477181941-7818a87d0933?w=600&q=80', 'The famous cone', null, null, 'owned', 'approved');
