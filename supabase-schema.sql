-- ============================================================
-- WFSC 2026 — Supabase Schema
-- Run this entire file in your Supabase SQL Editor
-- ============================================================

-- PAIRS table: one row per competing pair
create table if not exists pairs (
  id              serial primary key,
  division        text not null check (division in ('Mens','Womens','Masters','Junior','Mixed')),
  country         text not null,
  diver1          text not null,
  diver2          text not null,
  confirmed       boolean not null default false,
  checked_in_d1   boolean not null default false,
  checked_in_d2   boolean not null default false,
  created_at      timestamptz default now()
);

-- WEIGHINS table: one row per weigh-in submission (one per pair per day)
create table if not exists weighins (
  id              serial primary key,
  pair_id         integer not null references pairs(id) on delete cascade,
  day             integer not null check (day in (1,2)),
  fish_count      integer not null default 0,
  total_kg        numeric(6,3) not null default 0,
  largest_fish_kg numeric(6,3) not null default 0,
  largest_fish_who text not null default '',
  smallest_cat_kg numeric(6,3) not null default 0,
  smallest_cat_who text not null default '',
  notes           text default '',
  submitted_at    timestamptz default now(),
  unique(pair_id, day)
);

-- PROTESTS table: simple log
create table if not exists protests (
  id              serial primary key,
  team_name       text not null,
  against_team    text not null,
  description     text not null,
  status          text not null default 'pending' check (status in ('pending','upheld','dismissed')),
  deposit_paid    boolean not null default false,
  created_at      timestamptz default now()
);

-- ============================================================
-- Enable Realtime on weighins (for live leaderboard updates)
-- ============================================================
alter publication supabase_realtime add table weighins;
alter publication supabase_realtime add table pairs;

-- ============================================================
-- Row Level Security — public read, no public write
-- ============================================================
alter table pairs    enable row level security;
alter table weighins enable row level security;
alter table protests enable row level security;

-- Public can read everything (leaderboard is public)
create policy "Public read pairs"    on pairs    for select using (true);
create policy "Public read weighins" on weighins for select using (true);
create policy "Public read protests" on protests for select using (true);

-- Only authenticated (service role via admin app) can write
-- Note: we use anon key on frontend with RLS bypassed for writes via
-- a Postgres function that checks a shared secret password.
-- For simplicity in this setup, we allow anon writes — 
-- the admin password gate is enforced in the UI only.
-- For production hardening, replace with Supabase Auth.
create policy "Anon write pairs"    on pairs    for all using (true) with check (true);
create policy "Anon write weighins" on weighins for all using (true) with check (true);
create policy "Anon write protests" on protests for all using (true) with check (true);

-- ============================================================
-- SEED DATA — 36 pairs from CSV entries
-- ============================================================
insert into pairs (division, country, diver1, diver2, confirmed) values
-- MENS
('Mens','New Zealand','Darren Shields','Hamish Shields',true),
('Mens','New Zealand','Nathan Anderson','Mike Rolls',true),
('Mens','New Zealand','Justin Reid','Rex Smith',true),
('Mens','New Zealand','Lachlan Luff','TBD',false),
('Mens','Australia','Nathan Natale','Clinton Duffy',true),
('Mens','Australia','TBD','TBD',false),
('Mens','USA','Jason Spier','TBD',false),
('Mens','USA','TBD','TBD',false),
('Mens','Guam','TBD','TBD',false),
('Mens','Guam','TBD','TBD',false),

-- WOMENS
('Womens','New Zealand','Marama Reti','Sarah Jayne Webb',true),
('Womens','New Zealand','Lisa Anderson','TBD',false),
('Womens','New Zealand','Steph Thomson','TBD',false),
('Womens','New Zealand','TBD','TBD',false),
('Womens','Australia','TBD','TBD',false),
('Womens','Australia','TBD','TBD',false),
('Womens','USA','TBD','TBD',false),
('Womens','USA','TBD','TBD',false),

-- MASTERS
('Masters','New Zealand','Mike Thomson','Alan Jamieson',true),
('Masters','New Zealand','Dave Peacock','TBD',false),
('Masters','New Zealand','Grant McMillan','TBD',false),
('Masters','New Zealand','TBD','TBD',false),
('Masters','Australia','TBD','TBD',false),
('Masters','Australia','TBD','TBD',false),

-- JUNIOR
('Junior','New Zealand','Ruby Jamieson','Indie Thomson',true),
('Junior','New Zealand','TBD','TBD',false),
('Junior','New Zealand','TBD','TBD',false),
('Junior','New Zealand','TBD','TBD',false),
('Junior','Australia','TBD','TBD',false),
('Junior','Australia','TBD','TBD',false),

-- MIXED
('Mixed','New Zealand','Sam Reti','Emily Reti',true),
('Mixed','New Zealand','TBD','TBD',false),
('Mixed','New Zealand','TBD','TBD',false),
('Mixed','New Zealand','TBD','TBD',false),
('Mixed','Australia','TBD','TBD',false),
('Mixed','USA','TBD','TBD',false);

-- ============================================================
-- STORAGE — catch photos bucket
-- Run this AFTER creating the bucket in Supabase Dashboard:
-- Storage → New bucket → name: "catch-photos" → Public: ON
-- ============================================================

-- Photos metadata table (links photos to weighins)
create table if not exists catch_photos (
  id          serial primary key,
  weighin_id  integer references weighins(id) on delete cascade,
  pair_id     integer not null references pairs(id) on delete cascade,
  day         integer not null check (day in (1,2)),
  storage_path text not null,
  caption     text default '',
  uploaded_at timestamptz default now()
);

alter table catch_photos enable row level security;
create policy "Public read photos"  on catch_photos for select using (true);
create policy "Anon write photos"   on catch_photos for all    using (true) with check (true);

alter publication supabase_realtime add table catch_photos;
