# Reef Tracker

A cross-platform (Android / iOS / Web) Flutter app to track saltwater
aquarium parameters and tank health, with AI-powered recommendations.

- **Auth + data:** Supabase (Postgres, Auth, Row Level Security, Edge Functions)
- **State:** Riverpod
- **Routing:** go_router
- **Charts:** fl_chart
- **AI:** Venice AI, called server-side from a Supabase Edge Function so the
  API key is never shipped in the app.

## Features

- Email/password sign in & sign up (Supabase Auth).
- Create tanks: volume (L/gal), type, start date, notes.
- Per-tank **equipment** (lights, filters, skimmers, pumps, refugiums, …),
  **livestock** (fish, corals, inverts), and **dosing** schedule.
- Log water **parameters**: temperature, alkalinity, calcium, magnesium, pH,
  nitrate, phosphate, salinity — plus your own **custom parameters**.
- Out-of-range readings are flagged against reef target ranges.
- **Trend graphs** per parameter with the ideal range shaded.
- **AI recommendations** generated from the tank profile + recent readings.

---

## 1. Create a Supabase project

1. Go to <https://supabase.com> and create a **new** project (separate from any
   existing one). Choose a database password and region.
2. In **Project Settings → API**, copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`
   (The anon key is safe to ship; it is gated by Row Level Security.)

## 2. Create the database schema

Open **SQL Editor → New query**, paste the contents of
[`supabase/schema.sql`](supabase/schema.sql), and run it. This creates all
tables and the RLS policies that keep each user's data private.

## 3. Configure auth

In **Authentication → Providers → Email**, enable email sign-up. For quick
local testing you may turn **"Confirm email"** off so new accounts work
immediately; turn it back on before any real launch.

## 4. Run the app

Pass the Supabase config as `--dart-define` values. Easiest is the helper
script (PowerShell):

```powershell
# Edit env.ps1 first with your URL + anon key, then:
./run.ps1 chrome      # web
./run.ps1             # default device
```

Or run directly:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If you skip these, the app shows a "Supabase is not configured" screen.

## 5. Deploy the AI Edge Function (Venice)

Get a Venice AI key from <https://venice.ai> (API access). Then, with the
[Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Secrets (server-side only — never in the app):
supabase secrets set VENICE_API_KEY=your_venice_key
supabase secrets set VENICE_MODEL=llama-3.3-70b   # optional

supabase functions deploy ai-recommend
```

The app calls this function via `supabase.functions.invoke('ai-recommend')`;
Supabase forwards the signed-in user's JWT, so the function only ever reads
that user's tank (RLS enforced).

---

## Build for release

```bash
# Android
flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# iOS (on macOS)
flutter build ipa --dart-define=...
# Web
flutter build web --dart-define=...
```

## Project layout

```
lib/
  core/            config, theme, supabase providers
  routing/         go_router + auth guard
  features/
    auth/          sign in / sign up
    tanks/         tanks, equipment, livestock, dosing
    parameters/    parameter types, readings, logging, charts
    ai/            recommendations (calls the Edge Function)
supabase/
  schema.sql                       database + RLS
  functions/ai-recommend/index.ts  Venice AI proxy
```

## Notes & next steps

- Adding new built-in parameters: extend `ParameterCatalog` in
  `lib/features/parameters/domain/parameter_type.dart`.
- Users can already add custom parameters from the **Log reading** screen.
- Ideas to build next: photo journal, water-change log, push reminders for
  testing/dosing, CSV export, multi-tank dashboard.
