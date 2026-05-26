-- ============================================================
-- WFSC 2026 — Consolidated Initial Schema
-- Combines production dump + in-repo schema files + RLS + indexes
-- Run this entire file in your Supabase SQL Editor.
-- ============================================================

-- ============================================================
-- TABLES
-- ============================================================

-- PAIRS — one row per competing pair (current production columns)
create table if not exists pairs (
  id               serial primary key,
  division         text not null check (division in ('Mens','Womens','Masters','Junior','Mixed')),
  country          text not null,
  diver1           text not null,
  diver2           text not null,
  confirmed        boolean not null default false,
  checked_in_d1    boolean not null default false,
  checked_in_d2    boolean not null default false,
  created_at       timestamptz default now(),
  country2         text,
  combined_nations boolean default false,
  team_photo_url   text,
  registered       boolean default false,
  waiver_signed    boolean default false
);

-- WEIGHINS — one row per weigh-in submission (one per pair per day)
create table if not exists weighins (
  id                serial primary key,
  pair_id           integer not null references pairs(id) on delete cascade,
  day               integer not null check (day in (1,2)),
  fish_count        integer not null default 0,
  total_kg          numeric not null default 0,
  largest_fish_kg   numeric not null default 0,
  largest_fish_who  text not null default '',
  smallest_cat_kg   numeric not null default 0,
  smallest_cat_who  text not null default '',
  notes             text default '',
  submitted_at      timestamptz default now(),
  unique(pair_id, day)
);

-- CATCH_PHOTOS — photos linked to weighins and pairs
-- NOTE: dump had a typo; fixed here so pair_id references pairs(id)
create table if not exists catch_photos (
  id           serial primary key,
  weighin_id   integer references weighins(id) on delete cascade,
  pair_id      integer not null references pairs(id) on delete cascade,
  day          integer not null check (day in (1,2)),
  storage_path text not null,
  caption      text default '',
  uploaded_at  timestamptz default now()
);

-- PROTESTS — protest log
create table if not exists protests (
  id            serial primary key,
  team_name     text not null,
  against_team  text not null,
  description   text not null,
  status        text not null default 'pending' check (status in ('pending','upheld','dismissed')),
  deposit_paid  boolean not null default false,
  created_at    timestamptz default now()
);

-- COMPETITION_SETTINGS — simple key/value config (e.g. results_finalized, current_day)
create table if not exists competition_settings (
  key         text primary key,
  value       text not null,
  updated_at  timestamptz default now()
);

insert into competition_settings (key, value) values
  ('results_finalized', 'false'),
  ('current_day', '0')
on conflict (key) do nothing;

-- USER_ANALYTICS — simple page-view tracking
create table if not exists user_analytics (
  id          bigserial primary key,
  user_id     text not null,
  session_id  text not null,
  page_view   text not null,
  timestamp   timestamptz default now(),
  user_agent  text,
  referrer    text
);

create index if not exists idx_user_analytics_user_id    on user_analytics(user_id);
create index if not exists idx_user_analytics_session_id on user_analytics(session_id);
create index if not exists idx_user_analytics_timestamp  on user_analytics(timestamp);

-- MERCH_ORDERS — confirmed merchandise orders (per registered person)
create table if not exists merch_orders (
  id           uuid primary key default gen_random_uuid(),
  booking_id   text,
  booker       text,
  email        text,
  person       text not null,
  item_type    text not null,
  size         text not null,
  is_extra     boolean default false,
  allocated    boolean default false,
  created_at   timestamptz default now()
);

-- MERCH_REQUESTS — requests/wishlist for additional merch
create table if not exists merch_requests (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  item_type   text not null,
  size        text not null,
  notes       text,
  status      text default 'pending',
  created_at  timestamptz default now()
);

-- ============================================================
-- REALTIME — live leaderboard updates
-- ============================================================
alter publication supabase_realtime add table pairs;
alter publication supabase_realtime add table weighins;
alter publication supabase_realtime add table catch_photos;

-- ============================================================
-- ROW LEVEL SECURITY
-- Pattern: public read everything; permissive anon write
-- (admin password gate is enforced in the UI only — not by DB)
-- ============================================================

alter table pairs                enable row level security;
alter table weighins             enable row level security;
alter table catch_photos         enable row level security;
alter table protests             enable row level security;
alter table competition_settings enable row level security;
alter table user_analytics       enable row level security;
alter table merch_orders         enable row level security;
alter table merch_requests       enable row level security;

-- Public read
create policy "Public read pairs"                on pairs                for select using (true);
create policy "Public read weighins"             on weighins             for select using (true);
create policy "Public read catch_photos"         on catch_photos         for select using (true);
create policy "Public read protests"             on protests             for select using (true);
create policy "Public read competition_settings" on competition_settings for select using (true);
create policy "Public read user_analytics"       on user_analytics       for select using (true);
create policy "Public read merch_orders"         on merch_orders         for select using (true);
create policy "Public read merch_requests"       on merch_requests       for select using (true);

-- Anon write (UI-gated)
create policy "Anon write pairs"                on pairs                for all using (true) with check (true);
create policy "Anon write weighins"             on weighins             for all using (true) with check (true);
create policy "Anon write catch_photos"         on catch_photos         for all using (true) with check (true);
create policy "Anon write protests"             on protests             for all using (true) with check (true);
create policy "Anon write competition_settings" on competition_settings for all using (true) with check (true);
create policy "Anon write user_analytics"       on user_analytics       for all using (true) with check (true);
create policy "Anon write merch_orders"         on merch_orders         for all using (true) with check (true);
create policy "Anon write merch_requests"       on merch_requests       for all using (true) with check (true);

-- ============================================================
-- STORAGE NOTE — TWO buckets needed (manual step in Dashboard)
-- After running this SQL, go to Supabase Dashboard → Storage:
--
--   Bucket 1:
--     Name:   catch-photos
--     Public: ON
--     (stores fish photos; path saved in catch_photos.storage_path)
--
--   Bucket 2:
--     Name:   team-photos
--     Public: ON
--     (stores pair team photos; path saved in pairs.team_photo_url)
--
-- For each bucket: Storage → New bucket → enter name → toggle
-- Public ON → Save.
-- ============================================================
