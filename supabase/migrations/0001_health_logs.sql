-- Adds tank health journal entries (1-10 rating + notes over time).
-- Run this in the Supabase SQL editor on an existing project.
-- (Already included in schema.sql for fresh setups.)

create table if not exists public.health_logs (
  id          uuid primary key default gen_random_uuid(),
  tank_id     uuid not null references public.tanks (id) on delete cascade,
  rating      integer not null check (rating between 1 and 10),
  notes       text,
  observed_at timestamptz not null default now(),
  created_at  timestamptz not null default now()
);
create index if not exists health_logs_tank_idx
  on public.health_logs (tank_id, observed_at desc);

alter table public.health_logs enable row level security;

create policy "health_logs_via_tank" on public.health_logs
  for all using (
    exists (select 1 from public.tanks t
            where t.id = health_logs.tank_id and t.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.tanks t
            where t.id = health_logs.tank_id and t.user_id = auth.uid())
  );
