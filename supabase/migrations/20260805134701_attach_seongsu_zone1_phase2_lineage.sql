-- Retroactively attach complete Phase 2 manual-workflow lineage to the
-- existing Seongsu Strategic Zone 1 association-establishment approval.
--
-- The raw payload below is a structured manual observation snapshot. It is
-- not represented as the complete original portal HTML. Canonical JSON hashing
-- is not yet defined for this project, so content_hash remains null.

do $$
#variable_conflict use_variable
<<lineage>>
declare
  target_area_id uuid;
  source_registry_id uuid;
  source_url text;

  source_document_id constant uuid := '7e4076fa-91cb-42f0-8f93-d553d292ed84';
  published_fact_id constant uuid := '8d523980-1965-4c85-aeb4-9ed7f63cd9fe';
  stage_history_id constant uuid := '4654db47-650f-4d0f-a50e-b66d5cb78713';

  ingestion_run_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee1';
  raw_observation_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee2';
  normalized_observation_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee3';
  review_record_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee4';
  publication_batch_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee5';
  ingestion_audit_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee6';
  raw_audit_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee7';
  normalized_audit_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee8';
  review_audit_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91ee9';
  publication_audit_id constant uuid := 'b470eb43-53e6-49ef-88de-2a1a98a91eea';

  workflow_started_at constant timestamptz := '2026-08-18T21:27:00+09:00';
  raw_fetched_at constant timestamptz := '2026-08-18T21:28:00+09:00';
  workflow_finished_at constant timestamptz := '2026-08-18T21:29:00+09:00';
  normalized_created_at constant timestamptz := '2026-08-18T21:30:00+09:00';
  review_requested_at constant timestamptz := '2026-08-18T21:31:00+09:00';
  human_reviewed_at constant timestamptz := '2026-08-18T21:32:00+09:00';
  batch_created_at constant timestamptz := '2026-08-18T21:32:30+09:00';
  batch_published_at constant timestamptz := '2026-08-18T21:33:00+09:00';

  expected_requested_scope constant jsonb := jsonb_build_object(
    'area_slug', 'seongsu-strategic-zone-1',
    'source_identifier', 'cafeId=200100002009a28',
    'fact_type', 'project_stage',
    'attribute_key', 'association_establishment_approval'
  );
  expected_normalized_value constant jsonb := jsonb_build_object(
    'stage_code', 'association_establishment_approval',
    'stage_label', '조합설립인가',
    'approval_date', '2017-07-18',
    'source_displayed_current_stage', '조합설립인가',
    'source_system', '서울특별시 정비사업 정보몽땅'
  );
  expected_difference_summary constant jsonb := jsonb_build_object(
    'workflow_type', 'retroactive_lineage_attachment',
    'published_value_changed', false,
    'stage_history_changed', false,
    'reason', 'Existing Phase 1 manual publication is being connected to the Phase 2 workflow without changing the public fact.'
  );
  expected_raw_payload jsonb;
begin
  select id
    into target_area_id
    from public.areas
   where slug = 'seongsu-strategic-zone-1';

  if target_area_id is null then
    raise exception 'Required area with slug seongsu-strategic-zone-1 does not exist';
  end if;

  select document.source_registry_id, document.source_url
    into source_registry_id, source_url
    from public.source_documents as document
   where document.id = source_document_id;

  if source_registry_id is null then
    raise exception 'Required source document % does not exist', source_document_id;
  end if;

  if not exists (
    select 1
      from public.source_documents as document
     where document.id = source_document_id
       and document.source_identifier = 'cafeId=200100002009a28'
       and document.source_url = 'https://cleanup.seoul.go.kr/assc/scrin-bbs/execute.do?cafeId=200100002009a28'
       and document.document_type = 'official_project_status_page'
       and document.title = '성수전략정비구역 제1 주택정비형 재개발정비사업조합'
       and document.legal_effect_status = 'reference_only'
  ) then
    raise exception 'Source document % does not match the expected portal status page', source_document_id;
  end if;

  if not exists (
    select 1
      from public.published_facts as fact
     where fact.id = published_fact_id
       and fact.area_id = target_area_id
       and fact.source_document_id = source_document_id
       and fact.fact_type = 'project_stage'
       and fact.attribute_key = 'association_establishment_approval'
       and fact.published_value = expected_normalized_value
       and fact.effective_from = '2017-07-18'::date
       and fact.verification_status = 'verified'
  ) then
    raise exception 'Published fact % is absent or inconsistent', published_fact_id;
  end if;

  if not exists (
    select 1
      from public.stage_history as stage
     where stage.id = stage_history_id
       and stage.area_id = target_area_id
       and stage.stage_code = 'association_establishment_approval'
       and stage.effective_date = '2017-07-18'::date
       and stage.published_fact_id = published_fact_id
       and stage.source_document_id = source_document_id
       and stage.verification_status = 'verified'
  ) then
    raise exception 'Stage history % is absent or inconsistent', stage_history_id;
  end if;

  if exists (
    select 1
      from public.published_facts as fact
     where fact.id = published_fact_id
       and (
         (fact.normalized_observation_id is not null and fact.normalized_observation_id <> normalized_observation_id)
         or (fact.review_record_id is not null and fact.review_record_id <> review_record_id)
         or (fact.publication_batch_id is not null and fact.publication_batch_id <> publication_batch_id)
       )
  ) then
    raise exception 'Published fact % already has conflicting Phase 2 lineage', published_fact_id;
  end if;

  if exists (
    select 1
      from public.stage_history as stage
     where stage.id = stage_history_id
       and stage.review_record_id is not null
       and stage.review_record_id <> review_record_id
  ) then
    raise exception 'Stage history % already has a conflicting review record', stage_history_id;
  end if;

  expected_raw_payload := jsonb_build_object(
    'source_system', '서울특별시 정비사업 정보몽땅',
    'project_title', '성수전략정비구역 제1 주택정비형 재개발정비사업조합',
    'area_slug', 'seongsu-strategic-zone-1',
    'displayed_stage', '조합설립인가',
    'approval_date', '2017-07-18',
    'source_identifier', 'cafeId=200100002009a28',
    'source_url', source_url,
    'observation_method', 'manual_human_read'
  );

  if exists (
    select 1
      from public.ingestion_runs as existing
     where existing.id = ingestion_run_id
       and (
         existing.source_registry_id,
         retry_of_run_id,
         started_at,
         finished_at,
         status,
         collection_method,
         collector_version,
         requested_scope,
         attempt_number,
         records_received,
         records_failed,
         error_code,
         error_summary,
         retry_after,
         retention_until,
         created_at
       ) is distinct from (
         source_registry_id,
         null::uuid,
         workflow_started_at,
         workflow_finished_at,
         'succeeded',
         'manual_portal_snapshot',
         'phase2-manual-validation-v1',
         expected_requested_scope,
         1,
         1,
         0,
         null::text,
         null::text,
         null::timestamptz,
         null::timestamptz,
         workflow_started_at
       )
  ) then
    raise exception 'Deterministic ingestion_runs ID conflicts with existing data';
  end if;

  insert into public.ingestion_runs (
    id,
    source_registry_id,
    retry_of_run_id,
    started_at,
    finished_at,
    status,
    collection_method,
    collector_version,
    requested_scope,
    attempt_number,
    records_received,
    records_failed,
    error_code,
    error_summary,
    retry_after,
    retention_until,
    created_at
  )
  select
    ingestion_run_id,
    source_registry_id,
    null,
    workflow_started_at,
    workflow_finished_at,
    'succeeded',
    'manual_portal_snapshot',
    'phase2-manual-validation-v1',
    expected_requested_scope,
    1,
    1,
    0,
    null,
    null,
    null,
    null,
    workflow_started_at
  where not exists (
    select 1 from public.ingestion_runs as existing where existing.id = ingestion_run_id
  );

  if exists (
    select 1
      from public.raw_observations as existing
     where existing.id = raw_observation_id
       and (
         existing.ingestion_run_id,
         existing.source_document_id,
         provider_record_key,
         fetched_at,
         collection_method,
         payload,
         storage_uri,
         content_hash,
         http_status,
         parser_candidate_version,
         retention_until,
         created_at
       ) is distinct from (
         ingestion_run_id,
         source_document_id,
         'cafeId=200100002009a28:association_establishment_approval',
         raw_fetched_at,
         'manual_portal_snapshot',
         expected_raw_payload,
         null::text,
         null::text,
         null::integer,
         'phase2-manual-parser-v1',
         null::timestamptz,
         raw_fetched_at
       )
  ) then
    raise exception 'Deterministic raw_observations ID conflicts with existing data';
  end if;

  if exists (
    select 1
      from public.raw_observations as existing
     where existing.ingestion_run_id = ingestion_run_id
       and existing.provider_record_key = 'cafeId=200100002009a28:association_establishment_approval'
       and existing.id <> raw_observation_id
  ) then
    raise exception 'Raw observation logical identity exists under a different ID';
  end if;

  insert into public.raw_observations (
    id,
    ingestion_run_id,
    source_document_id,
    provider_record_key,
    fetched_at,
    collection_method,
    payload,
    storage_uri,
    content_hash,
    http_status,
    parser_candidate_version,
    retention_until,
    created_at
  )
  select
    raw_observation_id,
    ingestion_run_id,
    source_document_id,
    'cafeId=200100002009a28:association_establishment_approval',
    raw_fetched_at,
    'manual_portal_snapshot',
    expected_raw_payload,
    null,
    null,
    null,
    'phase2-manual-parser-v1',
    null,
    raw_fetched_at
  where not exists (
    select 1 from public.raw_observations as existing where existing.id = raw_observation_id
  );

  if exists (
    select 1
      from public.normalized_observations as existing
     where existing.id = normalized_observation_id
       and (
         existing.raw_observation_id,
         area_id,
         fact_type,
         attribute_key,
         normalized_value,
         unit,
         effective_date,
         parser_version,
         confidence_level,
         verification_status,
         deduplication_key,
         conflict_group_id,
         stale_after,
         superseded_by_id,
         created_at
       ) is distinct from (
         raw_observation_id,
         target_area_id,
         'project_stage',
         'association_establishment_approval',
         expected_normalized_value,
         null::text,
         '2017-07-18'::date,
         'phase2-manual-parser-v1',
         'high',
         'verified',
         'seongsu-strategic-zone-1:project_stage:association_establishment_approval:2017-07-18',
         null::uuid,
         null::timestamptz,
         null::uuid,
         normalized_created_at
       )
  ) then
    raise exception 'Deterministic normalized_observations ID conflicts with existing data';
  end if;

  if exists (
    select 1
      from public.normalized_observations as existing
     where existing.deduplication_key = 'seongsu-strategic-zone-1:project_stage:association_establishment_approval:2017-07-18'
       and existing.id <> normalized_observation_id
  ) then
    raise exception 'Normalized observation logical identity exists under a different ID';
  end if;

  insert into public.normalized_observations (
    id,
    raw_observation_id,
    area_id,
    fact_type,
    attribute_key,
    normalized_value,
    unit,
    effective_date,
    parser_version,
    confidence_level,
    verification_status,
    deduplication_key,
    conflict_group_id,
    stale_after,
    superseded_by_id,
    created_at
  )
  select
    normalized_observation_id,
    raw_observation_id,
    target_area_id,
    'project_stage',
    'association_establishment_approval',
    expected_normalized_value,
    null,
    '2017-07-18'::date,
    'phase2-manual-parser-v1',
    'high',
    'verified',
    'seongsu-strategic-zone-1:project_stage:association_establishment_approval:2017-07-18',
    null,
    null,
    null,
    normalized_created_at
  where not exists (
    select 1 from public.normalized_observations as existing where existing.id = normalized_observation_id
  );

  if exists (
    select 1
      from public.review_records as existing
     where existing.id = review_record_id
       and (
         existing.normalized_observation_id,
         review_type,
         status,
         previous_published_fact_id,
         proposed_value,
         difference_summary,
         threshold_rule_version,
         reviewer_label,
         decision,
         decision_reason,
         requested_at,
         reviewed_at,
         last_verified_at,
         created_at
       ) is distinct from (
         normalized_observation_id,
         'critical_stage_manual_verification',
         'approved',
         published_fact_id,
         expected_normalized_value,
         expected_difference_summary,
         'phase2-critical-stage-v1',
         'phase2-manual-reviewer',
         'approved',
         'Official portal stage and approval date manually matched the existing published fact.',
         review_requested_at,
         human_reviewed_at,
         human_reviewed_at,
         review_requested_at
       )
  ) then
    raise exception 'Deterministic review_records ID conflicts with existing data';
  end if;

  if exists (
    select 1
      from public.review_records as existing
     where existing.normalized_observation_id = normalized_observation_id
       and existing.review_type = 'critical_stage_manual_verification'
       and existing.id <> review_record_id
  ) then
    raise exception 'Review logical identity exists under a different ID';
  end if;

  insert into public.review_records (
    id,
    normalized_observation_id,
    review_type,
    status,
    previous_published_fact_id,
    proposed_value,
    difference_summary,
    threshold_rule_version,
    reviewer_label,
    decision,
    decision_reason,
    requested_at,
    reviewed_at,
    last_verified_at,
    created_at
  )
  select
    review_record_id,
    normalized_observation_id,
    'critical_stage_manual_verification',
    'approved',
    published_fact_id,
    expected_normalized_value,
    expected_difference_summary,
    'phase2-critical-stage-v1',
    'phase2-manual-reviewer',
    'approved',
    'Official portal stage and approval date manually matched the existing published fact.',
    review_requested_at,
    human_reviewed_at,
    human_reviewed_at,
    review_requested_at
  where not exists (
    select 1 from public.review_records as existing where existing.id = review_record_id
  );

  if exists (
    select 1
      from public.publication_batches as existing
     where existing.id = publication_batch_id
       and (
         status,
         created_by,
         published_at,
         rolled_back_at,
         rollback_of_batch_id,
         reason,
         created_at
       ) is distinct from (
         'published',
         'phase2-manual-validation',
         batch_published_at,
         null::timestamptz,
         null::uuid,
         'Retroactively attach Phase 2 workflow lineage to the existing verified Seongsu association-approval fact without changing its value.',
         batch_created_at
       )
  ) then
    raise exception 'Deterministic publication_batches ID conflicts with existing data';
  end if;

  insert into public.publication_batches (
    id,
    status,
    created_by,
    published_at,
    rolled_back_at,
    rollback_of_batch_id,
    reason,
    created_at
  )
  select
    publication_batch_id,
    'published',
    'phase2-manual-validation',
    batch_published_at,
    null,
    null,
    'Retroactively attach Phase 2 workflow lineage to the existing verified Seongsu association-approval fact without changing its value.',
    batch_created_at
  where not exists (
    select 1 from public.publication_batches as existing where existing.id = publication_batch_id
  );

  update public.published_facts as fact
     set normalized_observation_id = lineage.normalized_observation_id,
         review_record_id = lineage.review_record_id,
         publication_batch_id = lineage.publication_batch_id
   where fact.id = lineage.published_fact_id;

  if not found then
    raise exception 'Published fact % disappeared before lineage attachment', published_fact_id;
  end if;

  update public.stage_history as stage
     set review_record_id = lineage.review_record_id
   where stage.id = lineage.stage_history_id;

  if not found then
    raise exception 'Stage history % disappeared before review attachment', stage_history_id;
  end if;

  if exists (
    select 1
      from public.audit_logs as existing
     where existing.id = ingestion_audit_id
       and (
         event_type, actor_type, actor_label, entity_type, entity_id,
         existing.ingestion_run_id, existing.publication_batch_id, before_hash, after_hash,
         change_summary, reason, occurred_at
       ) is distinct from (
         'ingestion_run_succeeded', 'system', 'phase2-manual-validation',
         'ingestion_run', ingestion_run_id, ingestion_run_id, null::uuid,
         null::text, null::text,
         jsonb_build_object('status', 'succeeded', 'records_received', 1, 'records_failed', 0),
         'Manual portal snapshot workflow completed successfully.',
         '2026-08-18T21:29:10+09:00'::timestamptz
       )
  ) then
    raise exception 'Deterministic ingestion audit ID conflicts with existing data';
  end if;

  insert into public.audit_logs (
    id, event_type, actor_type, actor_label, entity_type, entity_id,
    ingestion_run_id, publication_batch_id, before_hash, after_hash,
    change_summary, reason, occurred_at
  )
  select
    ingestion_audit_id, 'ingestion_run_succeeded', 'system', 'phase2-manual-validation',
    'ingestion_run', ingestion_run_id, ingestion_run_id, null, null, null,
    jsonb_build_object('status', 'succeeded', 'records_received', 1, 'records_failed', 0),
    'Manual portal snapshot workflow completed successfully.',
    '2026-08-18T21:29:10+09:00'::timestamptz
  where not exists (select 1 from public.audit_logs as existing where existing.id = ingestion_audit_id);

  if exists (
    select 1
      from public.audit_logs as existing
     where existing.id = raw_audit_id
       and (
         event_type, actor_type, actor_label, entity_type, entity_id,
         existing.ingestion_run_id, existing.publication_batch_id, before_hash, after_hash,
         change_summary, reason, occurred_at
       ) is distinct from (
         'raw_observation_recorded', 'system', 'phase2-manual-validation',
         'raw_observation', raw_observation_id, ingestion_run_id, null::uuid,
         null::text, null::text,
         jsonb_build_object('observation_method', 'manual_human_read', 'complete_original_html', false),
         'Structured manual portal observation snapshot recorded.',
         '2026-08-18T21:29:20+09:00'::timestamptz
       )
  ) then
    raise exception 'Deterministic raw observation audit ID conflicts with existing data';
  end if;

  insert into public.audit_logs (
    id, event_type, actor_type, actor_label, entity_type, entity_id,
    ingestion_run_id, publication_batch_id, before_hash, after_hash,
    change_summary, reason, occurred_at
  )
  select
    raw_audit_id, 'raw_observation_recorded', 'system', 'phase2-manual-validation',
    'raw_observation', raw_observation_id, ingestion_run_id, null, null, null,
    jsonb_build_object('observation_method', 'manual_human_read', 'complete_original_html', false),
    'Structured manual portal observation snapshot recorded.',
    '2026-08-18T21:29:20+09:00'::timestamptz
  where not exists (select 1 from public.audit_logs as existing where existing.id = raw_audit_id);

  if exists (
    select 1
      from public.audit_logs as existing
     where existing.id = normalized_audit_id
       and (
         event_type, actor_type, actor_label, entity_type, entity_id,
         existing.ingestion_run_id, existing.publication_batch_id, before_hash, after_hash,
         change_summary, reason, occurred_at
       ) is distinct from (
         'normalized_observation_created', 'system', 'phase2-manual-validation',
         'normalized_observation', normalized_observation_id, ingestion_run_id, null::uuid,
         null::text, null::text,
         jsonb_build_object('fact_type', 'project_stage', 'attribute_key', 'association_establishment_approval', 'verification_status', 'verified'),
         'Manual portal snapshot normalized into the existing stage value.',
         '2026-08-18T21:30:10+09:00'::timestamptz
       )
  ) then
    raise exception 'Deterministic normalized observation audit ID conflicts with existing data';
  end if;

  insert into public.audit_logs (
    id, event_type, actor_type, actor_label, entity_type, entity_id,
    ingestion_run_id, publication_batch_id, before_hash, after_hash,
    change_summary, reason, occurred_at
  )
  select
    normalized_audit_id, 'normalized_observation_created', 'system', 'phase2-manual-validation',
    'normalized_observation', normalized_observation_id, ingestion_run_id, null, null, null,
    jsonb_build_object('fact_type', 'project_stage', 'attribute_key', 'association_establishment_approval', 'verification_status', 'verified'),
    'Manual portal snapshot normalized into the existing stage value.',
    '2026-08-18T21:30:10+09:00'::timestamptz
  where not exists (select 1 from public.audit_logs as existing where existing.id = normalized_audit_id);

  if exists (
    select 1
      from public.audit_logs as existing
     where existing.id = review_audit_id
       and (
         event_type, actor_type, actor_label, entity_type, entity_id,
         existing.ingestion_run_id, existing.publication_batch_id, before_hash, after_hash,
         change_summary, reason, occurred_at
       ) is distinct from (
         'review_approved', 'human', 'phase2-manual-reviewer',
         'review_record', review_record_id, ingestion_run_id, null::uuid,
         null::text, null::text,
         jsonb_build_object('decision', 'approved', 'published_value_changed', false, 'stage_history_changed', false),
         'Official portal stage and approval date manually matched the existing published fact.',
         '2026-08-18T21:32:10+09:00'::timestamptz
       )
  ) then
    raise exception 'Deterministic review audit ID conflicts with existing data';
  end if;

  insert into public.audit_logs (
    id, event_type, actor_type, actor_label, entity_type, entity_id,
    ingestion_run_id, publication_batch_id, before_hash, after_hash,
    change_summary, reason, occurred_at
  )
  select
    review_audit_id, 'review_approved', 'human', 'phase2-manual-reviewer',
    'review_record', review_record_id, ingestion_run_id, null, null, null,
    jsonb_build_object('decision', 'approved', 'published_value_changed', false, 'stage_history_changed', false),
    'Official portal stage and approval date manually matched the existing published fact.',
    '2026-08-18T21:32:10+09:00'::timestamptz
  where not exists (select 1 from public.audit_logs as existing where existing.id = review_audit_id);

  if exists (
    select 1
      from public.audit_logs as existing
     where existing.id = publication_audit_id
       and (
         event_type, actor_type, actor_label, entity_type, entity_id,
         existing.ingestion_run_id, existing.publication_batch_id, before_hash, after_hash,
         change_summary, reason, occurred_at
       ) is distinct from (
         'publication_lineage_attached', 'workflow', 'phase2-manual-validation',
         'published_fact', published_fact_id, ingestion_run_id, publication_batch_id,
         null::text, null::text,
         jsonb_build_object(
           'normalized_observation_id', normalized_observation_id,
           'review_record_id', review_record_id,
           'publication_batch_id', publication_batch_id,
           'published_value_changed', false,
           'stage_history_changed', false
         ),
         'Phase 2 workflow lineage attached without changing the published fact or stage history value.',
         '2026-08-18T21:33:10+09:00'::timestamptz
       )
  ) then
    raise exception 'Deterministic publication audit ID conflicts with existing data';
  end if;

  insert into public.audit_logs (
    id, event_type, actor_type, actor_label, entity_type, entity_id,
    ingestion_run_id, publication_batch_id, before_hash, after_hash,
    change_summary, reason, occurred_at
  )
  select
    publication_audit_id, 'publication_lineage_attached', 'workflow', 'phase2-manual-validation',
    'published_fact', published_fact_id, ingestion_run_id, publication_batch_id, null, null,
    jsonb_build_object(
      'normalized_observation_id', normalized_observation_id,
      'review_record_id', review_record_id,
      'publication_batch_id', publication_batch_id,
      'published_value_changed', false,
      'stage_history_changed', false
    ),
    'Phase 2 workflow lineage attached without changing the published fact or stage history value.',
    '2026-08-18T21:33:10+09:00'::timestamptz
  where not exists (select 1 from public.audit_logs as existing where existing.id = publication_audit_id);
end
$$;
