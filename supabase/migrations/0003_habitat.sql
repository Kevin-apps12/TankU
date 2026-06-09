-- Adds the habitat type to tanks so the app can track freshwater aquariums
-- and ponds alongside saltwater/reef tanks. Existing rows default to
-- 'saltwater' to match the app's original behavior.
alter table public.tanks
  add column if not exists habitat text not null default 'saltwater';
