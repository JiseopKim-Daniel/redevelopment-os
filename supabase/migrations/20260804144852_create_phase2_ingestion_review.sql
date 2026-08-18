-- Redevelopment OS: MVP Phase 2 ingestion, normalization, review, publication,
-- and audit schema.
--
-- This migration creates only the six documented Phase 2 tables. It also adds
-- the four foreign keys that Phase 1 explicitly reserved for these tables.
-- RLS is enabled without policies, so browser/client roles receive no access.

create table public.ingestion_runs (
  id uuid primary key default gen_random_uuid(),
  source_registry_id uuid not null,
  retry_of_run_id uuid,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'queued',
  collection_method text not null,
  collector_version text not null,
  requested_scope jsonb not null default '{}'::jsonb,
  attempt_number integer not null default 1,
  records_received integer not null default 0,
  records_failed integer not null default 0,
  error_code text,
  error_summary text,
  retry_after timestamptz,
  retention_until timestamptz,
  created_at timestamptz not null default now(),

  constraint ingestion_runs_source_registry_fk foreign key (source_registry_id)
    references public.source_registry (id)
    on delete restrict,
  constraint ingestion_runs_retry_of_fk foreign key (retry_of_run_id)
    references public.ingestion_runs (id)
    on delete restrict,
  constraint ingestion_runs_retry_not_self_check check (
    retry_of_run_id is null or retry_of_run_id <> id
  ),
  constraint ingestion_runs_status_check check (
    status in (
      'queued',
      'running',
      'succeeded',
      'partially_succeeded',
      'failed',
      'quarantined',
      'cancelled'
    )
  ),
  constraint ingestion_runs_finished_state_check check (
    (
      status in ('queued', 'running')
      and finished_at is null
    )
    or (
      status not in ('queued', 'running')
      and finished_at is not null
    )
  ),
  constraint ingestion_runs_time_order_check check (
    finished_at is null or finished_at >= started_at
  ),
  constraint ingestion_runs_attempt_number_check check (attempt_number >= 1),
  constraint ingestion_runs_record_counts_check check (
    records_received >= 0
    and records_failed >= 0
  ),
  constraint ingestion_runs_retention_check check (
    retention_until is null or retention_until >= created_at
  )
);

comment on table public.ingestion_runs is
  'One immutable-history record per ingestion attempt, including retries, outcomes, and reproducibility metadata.';
comment on column public.ingestion_runs.retention_until is
  'Workflow-populated retention policy target; provider terms and legal requirements govern the actual retention period.';
comment on column public.ingestion_runs.records_received is
  'Operational cache that may be reconciled from raw_observations.';
comment on column public.ingestion_runs.records_failed is
  'Non-negative failure count that may include request-level or processing failures even when no record was successfully received.';

create index ingestion_runs_registry_started_idx
  on public.ingestion_runs (source_registry_id, started_at desc);
create index ingestion_runs_status_started_idx
  on public.ingestion_runs (status, started_at desc);
create index ingestion_runs_retry_of_idx
  on public.ingestion_runs (retry_of_run_id)
  where retry_of_run_id is not null;
create index ingestion_runs_retention_idx
  on public.ingestion_runs (retention_until)
  where retention_until is not null;

create table public.raw_observations (
  id uuid primary key default gen_random_uuid(),
  ingestion_run_id uuid not null,
  source_document_id uuid,
  provider_record_key text,
  fetched_at timestamptz not null default now(),
  collection_method text not null,
  payload jsonb,
  storage_uri text,
  content_hash text,
  http_status integer,
  parser_candidate_version text,
  retention_until timestamptz,
  created_at timestamptz not null default now(),

  constraint raw_observations_ingestion_run_fk foreign key (ingestion_run_id)
    references public.ingestion_runs (id)
    on delete restrict,
  constraint raw_observations_source_document_fk foreign key (source_document_id)
    references public.source_documents (id)
    on delete restrict,
  constraint raw_observations_preserved_content_check check (
    payload is not null
    or nullif(btrim(storage_uri), '') is not null
    or nullif(btrim(content_hash), '') is not null
  ),
  constraint raw_observations_http_status_check check (
    http_status is null or http_status between 100 and 599
  ),
  constraint raw_observations_retention_check check (
    retention_until is null or retention_until >= fetched_at
  )
);

comment on table public.raw_observations is
  'Append-only raw responses or permitted raw-content references acquired by an ingestion run.';
comment on column public.raw_observations.source_document_id is
  'Nullable because raw content may be stored before its source document has been identified or created.';
comment on column public.raw_observations.payload is
  'Raw response payload when provider terms permit database storage.';
comment on column public.raw_observations.retention_until is
  'Workflow-populated retention policy target; provider terms and legal requirements govern the actual retention period.';

create index raw_observations_ingestion_run_idx
  on public.raw_observations (ingestion_run_id);
create index raw_observations_source_document_idx
  on public.raw_observations (source_document_id);
create index raw_observations_provider_key_idx
  on public.raw_observations (provider_record_key)
  where provider_record_key is not null;
create index raw_observations_content_hash_idx
  on public.raw_observations (content_hash)
  where content_hash is not null;
create index raw_observations_fetched_at_idx
  on public.raw_observations (fetched_at desc);
create index raw_observations_retention_idx
  on public.raw_observations (retention_until)
  where retention_until is not null;
create unique index raw_observations_run_provider_key_uidx
  on public.raw_observations (ingestion_run_id, provider_record_key)
  where provider_record_key is not null;
create unique index raw_observations_run_content_hash_uidx
  on public.raw_observations (ingestion_run_id, content_hash)
  where content_hash is not null;

create table public.normalized_observations (
  id uuid primary key default gen_random_uuid(),
  raw_observation_id uuid not null,
  area_id uuid,
  fact_type text not null,
  attribute_key text not null,
  normalized_value jsonb not null,
  unit text,
  effective_date date,
  parser_version text not null,
  confidence_level text not null,
  verification_status text not null default 'unverified',
  deduplication_key text,
  conflict_group_id uuid,
  stale_after timestamptz,
  superseded_by_id uuid,
  created_at timestamptz not null default now(),

  constraint normalized_observations_raw_fk foreign key (raw_observation_id)
    references public.raw_observations (id)
    on delete restrict,
  constraint normalized_observations_area_fk foreign key (area_id)
    references public.areas (id)
    on delete restrict,
  constraint normalized_observations_superseded_by_fk foreign key (superseded_by_id)
    references public.normalized_observations (id)
    on delete restrict,
  constraint normalized_observations_superseded_not_self_check check (
    superseded_by_id is null or superseded_by_id <> id
  ),
  constraint normalized_observations_confidence_level_check check (
    confidence_level in ('high', 'medium', 'low')
  ),
  constraint normalized_observations_verification_status_check check (
    verification_status in (
      'unverified',
      'auto_checked',
      'review_required',
      'verified',
      'rejected',
      'superseded',
      'stale'
    )
  )
);

comment on table public.normalized_observations is
  'Atomic candidate facts parsed and normalized from immutable raw observations; not service-published facts.';
comment on column public.normalized_observations.area_id is
  'Nullable while area matching is unresolved. Ambiguous or low-confidence matches require review.';
comment on column public.normalized_observations.conflict_group_id is
  'Opaque identifier grouping conflicting candidates until a dedicated conflict model is needed.';

create index normalized_observations_raw_idx
  on public.normalized_observations (raw_observation_id);
create index normalized_observations_area_fact_effective_idx
  on public.normalized_observations (area_id, fact_type, effective_date desc);
create index normalized_observations_verification_status_idx
  on public.normalized_observations (verification_status);
create index normalized_observations_deduplication_key_idx
  on public.normalized_observations (deduplication_key)
  where deduplication_key is not null;
create index normalized_observations_conflict_group_idx
  on public.normalized_observations (conflict_group_id)
  where conflict_group_id is not null;
create index normalized_observations_stale_after_idx
  on public.normalized_observations (stale_after)
  where stale_after is not null;

create table public.review_records (
  id uuid primary key default gen_random_uuid(),
  normalized_observation_id uuid not null,
  review_type text not null,
  status text not null default 'requested',
  previous_published_fact_id uuid,
  proposed_value jsonb not null,
  difference_summary jsonb,
  threshold_rule_version text,
  reviewer_label text,
  decision text,
  decision_reason text,
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),

  constraint review_records_normalized_observation_fk
    foreign key (normalized_observation_id)
    references public.normalized_observations (id)
    on delete restrict,
  constraint review_records_previous_published_fact_fk
    foreign key (previous_published_fact_id)
    references public.published_facts (id)
    on delete restrict,
  constraint review_records_status_check check (
    status in (
      'requested',
      'in_review',
      'needs_information',
      'approved',
      'rejected',
      'cancelled'
    )
  ),
  constraint review_records_workflow_state_check check (
    (
      status in ('requested', 'in_review')
      and decision is null
      and reviewed_at is null
    )
    or (
      status in ('approved', 'rejected', 'needs_information', 'cancelled')
      and decision is not null
      and decision = status
      and reviewed_at is not null
      and nullif(btrim(reviewer_label), '') is not null
      and nullif(btrim(decision_reason), '') is not null
    )
  ),
  constraint review_records_approved_verification_check check (
    status <> 'approved' or last_verified_at is not null
  ),
  constraint review_records_human_verification_check check (
    last_verified_at is null
    or (
      reviewed_at is not null
      and nullif(btrim(reviewer_label), '') is not null
      and last_verified_at <= reviewed_at
    )
  ),
  constraint review_records_review_time_check check (
    reviewed_at is null or reviewed_at >= requested_at
  )
);

comment on table public.review_records is
  'Durable single-reviewer MVP workflow for critical changes, conflicts, low confidence, and large-change thresholds.';
comment on column public.review_records.previous_published_fact_id is
  'Nullable when the candidate has no previous published value.';
comment on column public.review_records.last_verified_at is
  'Set only after an actual human comparison with the source; never populated by automated checks.';

create index review_records_status_requested_idx
  on public.review_records (status, requested_at);
create index review_records_normalized_observation_idx
  on public.review_records (normalized_observation_id);
create index review_records_reviewed_at_idx
  on public.review_records (reviewed_at desc)
  where reviewed_at is not null;
create index review_records_previous_fact_idx
  on public.review_records (previous_published_fact_id)
  where previous_published_fact_id is not null;

create table public.publication_batches (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'draft',
  created_by text not null,
  published_at timestamptz,
  rolled_back_at timestamptz,
  rollback_of_batch_id uuid,
  reason text,
  created_at timestamptz not null default now(),

  constraint publication_batches_rollback_of_fk foreign key (rollback_of_batch_id)
    references public.publication_batches (id)
    on delete restrict,
  constraint publication_batches_rollback_not_self_check check (
    rollback_of_batch_id is null or rollback_of_batch_id <> id
  ),
  constraint publication_batches_status_check check (
    status in (
      'draft',
      'publishing',
      'published',
      'failed',
      'rolled_back'
    )
  ),
  constraint publication_batches_lifecycle_timestamps_check check (
    (
      status in ('draft', 'publishing', 'failed')
      and published_at is null
      and rolled_back_at is null
    )
    or (
      status = 'published'
      and published_at is not null
      and rolled_back_at is null
    )
    or (
      status = 'rolled_back'
      and published_at is not null
      and rolled_back_at is not null
      and rolled_back_at >= published_at
      and nullif(btrim(reason), '') is not null
    )
  ),
  constraint publication_batches_compensating_rollback_check check (
    rollback_of_batch_id is null
    or nullif(btrim(reason), '') is not null
  )
);

comment on table public.publication_batches is
  'Atomic publication and non-destructive rollback unit for versioned official facts.';
comment on column public.publication_batches.rollback_of_batch_id is
  'When non-null, this row is a compensating rollback publication that reverses the referenced original batch. Status describes this row itself.';
comment on column public.publication_batches.rolled_back_at is
  'Set only when this publication row itself has status rolled_back; it must not precede published_at.';
comment on column public.publication_batches.created_by is
  'Single-user MVP actor label; actor fields will later standardize on user foreign keys.';

create index publication_batches_status_published_idx
  on public.publication_batches (status, published_at desc);
create index publication_batches_rollback_of_idx
  on public.publication_batches (rollback_of_batch_id)
  where rollback_of_batch_id is not null;

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  actor_type text not null,
  actor_label text,
  entity_type text not null,
  entity_id uuid not null,
  ingestion_run_id uuid,
  publication_batch_id uuid,
  before_hash text,
  after_hash text,
  change_summary jsonb,
  reason text,
  occurred_at timestamptz not null default now(),

  constraint audit_logs_ingestion_run_fk foreign key (ingestion_run_id)
    references public.ingestion_runs (id)
    on delete restrict,
  constraint audit_logs_publication_batch_fk foreign key (publication_batch_id)
    references public.publication_batches (id)
    on delete restrict
);

comment on table public.audit_logs is
  'Append-only audit history is intended; trusted workflow permissions or a future trigger must enforce update and delete prevention.';
comment on column public.audit_logs.entity_id is
  'Polymorphic entity reference interpreted together with entity_type; integrity is enforced by trusted workflow code or future triggers.';

create index audit_logs_entity_occurred_idx
  on public.audit_logs (entity_type, entity_id, occurred_at desc);
create index audit_logs_event_occurred_idx
  on public.audit_logs (event_type, occurred_at desc);
create index audit_logs_ingestion_run_idx
  on public.audit_logs (ingestion_run_id)
  where ingestion_run_id is not null;
create index audit_logs_publication_batch_idx
  on public.audit_logs (publication_batch_id)
  where publication_batch_id is not null;

-- Complete the Phase 1 links that were deliberately left nullable until these
-- Phase 2 tables existed. Existing manual Phase 1 rows remain valid as null.
alter table public.published_facts
  add constraint published_facts_normalized_observation_fk
  foreign key (normalized_observation_id)
  references public.normalized_observations (id)
  on delete restrict;

alter table public.published_facts
  add constraint published_facts_review_record_fk
  foreign key (review_record_id)
  references public.review_records (id)
  on delete restrict;

alter table public.published_facts
  add constraint published_facts_publication_batch_fk
  foreign key (publication_batch_id)
  references public.publication_batches (id)
  on delete restrict;

alter table public.stage_history
  add constraint stage_history_review_record_fk
  foreign key (review_record_id)
  references public.review_records (id)
  on delete restrict;

-- Phase 2 workflow tables are private by default. No SELECT or write policies
-- are created here; trusted server-side workflow code will require a separate
-- least-privilege authorization design.
alter table public.ingestion_runs enable row level security;
alter table public.raw_observations enable row level security;
alter table public.normalized_observations enable row level security;
alter table public.review_records enable row level security;
alter table public.publication_batches enable row level security;
alter table public.audit_logs enable row level security;
