-- Redevelopment OS: MVP Phase 1 schema
--
-- This migration intentionally creates only the six Phase 1 tables.
-- Phase 2 ingestion, normalization, review, publication-batch, and audit tables
-- are deferred to a later migration.

create table public.areas (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  canonical_name text not null,
  district_code text,
  representative_address text,
  representative_latitude numeric,
  representative_longitude numeric,
  project_type text,
  lifecycle_status text not null default 'active',
  current_stage text,
  current_stage_history_id uuid,
  successor_area_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint areas_lifecycle_status_check check (
    lifecycle_status in (
      'active',
      'suspended',
      'cancelled',
      'released',
      'merged',
      'superseded'
    )
  ),
  constraint areas_representative_latitude_check check (
    representative_latitude is null
    or representative_latitude between -90 and 90
  ),
  constraint areas_representative_longitude_check check (
    representative_longitude is null
    or representative_longitude between -180 and 180
  ),
  constraint areas_successor_area_fk foreign key (successor_area_id)
    references public.areas (id)
    on delete restrict,
  constraint areas_successor_not_self_check check (
    successor_area_id is null or successor_area_id <> id
  )
);

comment on table public.areas is
  'Stable redevelopment-area identity and current display summary.';
comment on column public.areas.current_stage is
  'Derived cache only. stage_history is the source of truth; do not edit this column directly.';
comment on column public.areas.current_stage_history_id is
  'Derived cache reference to the stage_history row used for current_stage; do not edit directly.';
comment on column public.areas.representative_latitude is
  'Representative map point only; it is not an official district boundary.';
comment on column public.areas.representative_longitude is
  'Representative map point only; it is not an official district boundary.';
comment on column public.areas.updated_at is
  'The default is applied only on insert. Application writes or a future shared trigger must maintain this value on updates.';

create index areas_district_project_type_idx
  on public.areas (district_code, project_type);
create index areas_lifecycle_status_idx
  on public.areas (lifecycle_status);

create table public.source_registry (
  id uuid primary key default gen_random_uuid(),
  provider_name text not null,
  dataset_name text not null,
  dataset_identifier text,
  service_identifier text,
  access_method text,
  authentication_method text,
  response_format text,
  legal_effect_status text not null default 'unknown',
  automation_status text not null default 'unknown',
  implementation_readiness text not null default 'needs_verification',
  provider_update_frequency text,
  polling_frequency text,
  reconciliation_frequency text,
  terms_checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint source_registry_legal_effect_status_check check (
    legal_effect_status in (
      'legally_effective',
      'reference_only',
      'mixed',
      'unknown'
    )
  ),
  constraint source_registry_automation_status_check check (
    automation_status in (
      'allowed',
      'conditional',
      'prohibited',
      'unknown'
    )
  ),
  constraint source_registry_implementation_readiness_check check (
    implementation_readiness in (
      'metadata_ready',
      'needs_verification',
      'blocked',
      'ready'
    )
  )
);

comment on table public.source_registry is
  'Provider and dataset-level access, legal-effect, automation, and scheduling metadata.';
comment on column public.source_registry.provider_update_frequency is
  'Provider-declared update frequency; separate from application polling.';
comment on column public.source_registry.polling_frequency is
  'Provisional application polling frequency until provider behavior is verified.';
comment on column public.source_registry.reconciliation_frequency is
  'Provisional historical correction and reconciliation frequency.';
comment on column public.source_registry.updated_at is
  'The default is applied only on insert. Application writes or a future shared trigger must maintain this value on updates.';

create unique index source_registry_provider_dataset_identifier_uidx
  on public.source_registry (provider_name, dataset_identifier)
  where dataset_identifier is not null;
create index source_registry_provider_name_idx
  on public.source_registry (provider_name);
create index source_registry_readiness_idx
  on public.source_registry (implementation_readiness);
create index source_registry_automation_status_idx
  on public.source_registry (automation_status);

create table public.source_documents (
  id uuid primary key default gen_random_uuid(),
  source_registry_id uuid not null,
  source_identifier text,
  source_url text,
  source_url_absence_reason text,
  document_type text not null,
  request_scope_identity text,
  title text,
  issued_at timestamptz,
  effective_date date,
  content_hash text,
  storage_uri text,
  legal_effect_status text not null default 'unknown',
  supersedes_document_id uuid,
  created_at timestamptz not null default now(),

  constraint source_documents_registry_fk foreign key (source_registry_id)
    references public.source_registry (id)
    on delete restrict,
  constraint source_documents_supersedes_fk foreign key (supersedes_document_id)
    references public.source_documents (id)
    on delete restrict,
  constraint source_documents_supersedes_not_self_check check (
    supersedes_document_id is null or supersedes_document_id <> id
  ),
  constraint source_documents_url_or_reason_check check (
    source_url is not null
    or nullif(btrim(source_url_absence_reason), '') is not null
  ),
  constraint source_documents_legal_effect_status_check check (
    legal_effect_status in (
      'legally_effective',
      'reference_only',
      'mixed',
      'unknown'
    )
  )
);

comment on table public.source_documents is
  'Source metadata for a provider document, dataset, file, or API request-scope identity.';
comment on column public.source_documents.request_scope_identity is
  'Stable identity for an API request scope or dataset slice, not an individual API response payload.';
comment on column public.source_documents.storage_uri is
  'Optional permitted storage location for a provider document or file. Individual API response payloads belong in Phase 2 raw_observations.';

create unique index source_documents_registry_identifier_uidx
  on public.source_documents (source_registry_id, source_identifier)
  where source_identifier is not null;
create index source_documents_type_effective_date_idx
  on public.source_documents (document_type, effective_date);
create index source_documents_content_hash_idx
  on public.source_documents (content_hash)
  where content_hash is not null;

create table public.published_facts (
  id uuid primary key default gen_random_uuid(),
  area_id uuid not null,
  normalized_observation_id uuid,
  source_document_id uuid not null,
  review_record_id uuid,
  publication_batch_id uuid,
  fact_type text not null,
  attribute_key text not null,
  published_value jsonb not null,
  unit text,
  effective_from date,
  effective_to date,
  verification_status text not null,
  last_verified_at timestamptz,
  superseded_by_id uuid,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now(),

  constraint published_facts_area_fk foreign key (area_id)
    references public.areas (id)
    on delete restrict,
  constraint published_facts_source_document_fk foreign key (source_document_id)
    references public.source_documents (id)
    on delete restrict,
  constraint published_facts_supersedes_fk foreign key (superseded_by_id)
    references public.published_facts (id)
    on delete restrict,
  constraint published_facts_supersedes_not_self_check check (
    superseded_by_id is null or superseded_by_id <> id
  ),
  constraint published_facts_verification_status_check check (
    verification_status in (
      'unverified',
      'auto_checked',
      'review_required',
      'verified',
      'rejected',
      'superseded',
      'stale'
    )
  ),
  constraint published_facts_effective_period_check check (
    effective_to is null
    or effective_from is null
    or effective_to >= effective_from
  )
);

comment on table public.published_facts is
  'Versioned official facts exposed by the service. Phase 1 supports manual source-backed publication.';
comment on column public.published_facts.normalized_observation_id is
  'Reserved nullable Phase 2 link. No foreign key is created until normalized_observations exists.';
comment on column public.published_facts.review_record_id is
  'Reserved nullable Phase 2 link. Ordinary auto_checked publication may remain null; critical changes will require an approved review link.';
comment on column public.published_facts.publication_batch_id is
  'Reserved nullable Phase 2 link. No foreign key is created until publication_batches exists.';
comment on column public.published_facts.last_verified_at is
  'Set only when a human actually reviewed the source and normalized value.';
comment on constraint published_facts_verification_status_check on public.published_facts is
  'Ordinary official observations may publish as auto_checked. Critical official changes require verified status and review linkage after Phase 2 is introduced.';

create index published_facts_area_attribute_effective_idx
  on public.published_facts (area_id, attribute_key, effective_from desc);
create index published_facts_current_idx
  on public.published_facts (area_id, attribute_key)
  where effective_to is null;
create index published_facts_source_document_idx
  on public.published_facts (source_document_id);
create index published_facts_verification_status_idx
  on public.published_facts (verification_status);

create table public.stage_history (
  id uuid primary key default gen_random_uuid(),
  area_id uuid not null,
  stage_code text not null,
  effective_date date,
  published_fact_id uuid not null,
  source_document_id uuid not null,
  verification_status text not null,
  review_record_id uuid,
  supersedes_stage_history_id uuid,
  recorded_at timestamptz not null default now(),

  constraint stage_history_area_fk foreign key (area_id)
    references public.areas (id)
    on delete restrict,
  constraint stage_history_published_fact_fk foreign key (published_fact_id)
    references public.published_facts (id)
    on delete restrict,
  constraint stage_history_source_document_fk foreign key (source_document_id)
    references public.source_documents (id)
    on delete restrict,
  constraint stage_history_supersedes_fk foreign key (supersedes_stage_history_id)
    references public.stage_history (id)
    on delete restrict,
  constraint stage_history_supersedes_not_self_check check (
    supersedes_stage_history_id is null or supersedes_stage_history_id <> id
  ),
  constraint stage_history_verification_status_check check (
    verification_status in (
      'verified',
      'superseded',
      'stale'
    )
  )
);

comment on table public.stage_history is
  'Single source of truth for project-stage ordering and current-stage calculation.';
comment on column public.stage_history.review_record_id is
  'Reserved nullable Phase 2 link. No foreign key is created until review_records exists.';
comment on column public.stage_history.published_fact_id is
  'The approved stage-type published fact. Publishing it and inserting this stage row must be atomic.';

create unique index stage_history_obvious_duplicate_uidx
  on public.stage_history (
    area_id,
    stage_code,
    coalesce(effective_date, '-infinity'::date),
    source_document_id
  );
create index stage_history_area_effective_recorded_idx
  on public.stage_history (area_id, effective_date desc, recorded_at desc);
create index stage_history_source_document_idx
  on public.stage_history (source_document_id);

-- Required as the referenced key for the composite current-stage cache FK.
-- Although id is already globally unique, including area_id lets the FK enforce
-- that an area's cache can point only to its own stage_history row.
alter table public.stage_history
  add constraint stage_history_id_area_id_unique unique (id, area_id);

-- Add the derived-cache foreign key only after stage_history exists.
alter table public.areas
  add constraint areas_current_stage_history_fk
  foreign key (current_stage_history_id, id)
  references public.stage_history (id, area_id)
  on delete set null (current_stage_history_id);

create table public.user_values (
  id uuid primary key default gen_random_uuid(),
  area_id uuid not null,
  value_type text not null,
  value jsonb not null,
  unit text,
  entered_by text,
  observed_at timestamptz,
  source_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint user_values_area_fk foreign key (area_id)
    references public.areas (id)
    on delete restrict
);

comment on table public.user_values is
  'User-entered values such as notes, manually observed private asking prices, and assumptions; always separate from official facts.';
comment on column public.user_values.entered_by is
  'Single-user MVP actor label. A later migration may replace or supplement it with a user foreign key.';
comment on column public.user_values.updated_at is
  'The default is applied only on insert. Application writes or a future shared trigger must maintain this value on updates.';

create index user_values_area_type_observed_idx
  on public.user_values (area_id, value_type, observed_at desc);
create index user_values_active_idx
  on public.user_values (area_id, created_at desc)
  where deleted_at is null;

-- RLS is enabled now, but this migration intentionally defines no policies.
-- With no permissive policies, browser/client roles cannot read or write these
-- tables through the Supabase data API. Least-privilege read/write policies must
-- be designed and added before application integration.
alter table public.areas enable row level security;
alter table public.source_registry enable row level security;
alter table public.source_documents enable row level security;
alter table public.published_facts enable row level security;
alter table public.stage_history enable row level security;
alter table public.user_values enable row level security;
