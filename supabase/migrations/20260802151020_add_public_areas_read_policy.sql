-- Expose only the non-sensitive redevelopment area directory to browser/client
-- roles. The user_values table and all official-source workflow tables remain
-- private because this migration creates no policies for them.
--
-- Write access is intentionally not provided. No INSERT, UPDATE, or DELETE
-- policy is created, and this migration adds no grants.

-- Keep RLS explicitly enabled even if this migration is replayed independently.
alter table public.areas enable row level security;

-- Make policy creation safe if a local database replays this policy definition.
drop policy if exists "Public read access to areas" on public.areas;

create policy "Public read access to areas"
on public.areas
for select
to anon, authenticated
using (true);
