-- Browser/client roles may read only verified official facts and the legally
-- effective source metadata that supports them. All other rows remain hidden
-- by RLS, and no public write access is provided.
--
-- This migration intentionally creates no policy for source_registry,
-- user_values, stage_history, or any other table.

-- Keep RLS explicitly enabled if this migration is replayed independently.
alter table public.published_facts enable row level security;
alter table public.source_documents enable row level security;

drop policy if exists "Public read access to verified published facts"
on public.published_facts;

create policy "Public read access to verified published facts"
on public.published_facts
for select
to anon, authenticated
using (verification_status = 'verified');

drop policy if exists "Public read access to legally effective source documents"
on public.source_documents;

create policy "Public read access to legally effective source documents"
on public.source_documents
for select
to anon, authenticated
using (legal_effect_status = 'legally_effective');
