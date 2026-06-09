-- Adds per-tank feeding schedules (food, amount, frequency).
-- Run this in the Supabase SQL editor on an existing project.
-- (Already included in schema.sql for fresh setups.)

create table if not exists public.feedings (
  id        uuid primary key default gen_random_uuid(),
  tank_id   uuid not null references public.tanks (id) on delete cascade,
  food      text not null,
  amount    text,
  frequency text not null default 'once_daily',
  notes     text,
  created_at timestamptz not null default now()
);
create index if not exists feedings_tank_id_idx on public.feedings (tank_id);

alter table public.feedings enable row level security;

create policy "feedings_via_tank" on public.feedings
  for all using (
    exists (select 1 from public.tanks t
            where t.id = feedings.tank_id and t.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.tanks t
            where t.id = feedings.tank_id and t.user_id = auth.uid())
  );
