# WFSC 2026 — World Freshwater Spearfishing Championships App

Live competition management: leaderboard, check-in, weigh-in, teams, awards, protests.

## Stack
- **Frontend**: React + Vite
- **Database**: Supabase (Postgres + Realtime)
- **Hosting**: Netlify

---

## Setup Guide

### Step 1: Supabase

1. Go to [supabase.com](https://supabase.com) → **New project**
2. Name it `wfsc-2026`, set a strong DB password, choose a region close to NZ
3. Wait for it to spin up (~1 min)
4. In the left sidebar → **SQL Editor** → paste the full contents of `supabase-schema.sql` and click **Run**
5. Go to **Settings → API** and copy:
   - **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - **anon / public** key (long JWT string)

### Step 2: Configure Environment

Copy the example env file:
```bash
cp .env.example .env
```

Edit `.env` and fill in your values:
```
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
VITE_ADMIN_PASSWORD=wfsc2026
```

### Step 3: Local Development

```bash
npm install
npm run dev
```

App runs at http://localhost:5173

### Step 4: Deploy to Netlify

**Option A — Drag & Drop (quickest)**
```bash
npm run build
```
Then drag the `dist/` folder to [app.netlify.com/drop](https://app.netlify.com/drop)

**Option B — GitHub + Auto Deploy (recommended)**
1. Push this repo to GitHub
2. Go to [netlify.com](https://netlify.com) → **Add new site → Import from Git**
3. Select your repo
4. Build settings:
   - Build command: `npm run build`
   - Publish directory: `dist`
5. Go to **Site settings → Environment variables** and add:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `VITE_ADMIN_PASSWORD`
6. **Deploy site**

---

## Using the App

### Public Access
- Anyone can view the **Leaderboard** — no login required
- Scores update in real-time via Supabase Realtime

### Admin Access
- Click **🔐 ADMIN** in the top-right corner
- Password: `wfsc2026` (or whatever you set in env)
- All 8 tabs unlock: Dashboard, Leaderboard, Check-In, Weigh-In, Teams, Nations, Awards, Protests

### Workflow on Competition Days

1. **Teams tab** — confirm any pending pairs, fix TBD names before competition starts
2. **Check-In tab** — mark pairs as present at morning briefing (Day 1 = Fri 13 Mar, Day 2 = Sat 14 Mar)
3. **Weigh-In tab** — enter fish count, total weight, largest fish, and smallest catfish per pair per day
4. **Leaderboard** — updates live as scores are entered
5. **Awards tab** — shows podiums by division + open champion + special prizes
6. **Protests tab** — log any protests, track $100 deposit, mark upheld/dismissed

---

## Scoring Formula

Per the WFSC 2026 rules:
- **100 points** per eligible fish (catfish only)
- **10 points** per 100g of total catch weight (floored to nearest 100g)
- Raw score = `(fish_count × 100) + (floor(kg × 10) × 10)`
- Daily percentage = `(pair_raw / day_division_top) × 100`
- Final = sum of Day 1 % + Day 2 %

---

## Troubleshooting

**Scores not updating live?**
- Check Supabase Realtime is enabled: Dashboard → Database → Replication → confirm `weighins` and `pairs` are in the publication

**"Missing Supabase env vars" in console?**
- Make sure `.env` file exists and has the correct values
- For Netlify: check Environment Variables in site settings

**Can't write to database?**
- The schema sets RLS to allow anon writes (password gate is UI-only)
- If you want stricter security, switch to Supabase Auth and update the RLS policies

---

## Project Structure

```
wfsc-2026/
├── src/
│   ├── lib/
│   │   ├── supabase.js      # Supabase client
│   │   ├── constants.js     # Divisions, countries, scoring
│   │   └── hooks.js         # Data fetching + leaderboard calc
│   ├── components/
│   │   └── Flag.jsx         # Inline SVG flags (NZ, USA, AUS, GUM, GHA)
│   ├── App.jsx              # All views: Dashboard, Leaderboard, etc.
│   └── main.jsx             # Entry point
├── supabase-schema.sql      # Run this in Supabase SQL Editor
├── .env.example             # Copy to .env and fill in
├── netlify.toml             # Netlify build + SPA redirect config
├── vite.config.js
└── package.json
```
