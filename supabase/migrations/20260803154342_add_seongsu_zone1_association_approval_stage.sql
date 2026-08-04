-- Register the association-establishment approval stage displayed by Seoul's
-- official redevelopment information portal for Seongsu Strategic Zone 1.
--
-- The portal is an official public-information source for the published
-- project status, but this project page is not itself the legally effective
-- approval notice. The registry and document therefore remain reference_only.
-- Only the supplied 조합설립인가 stage is recorded by this migration.

do $$
declare
  target_area_id uuid;
  latest_stage_id uuid;
  latest_stage_label text;
  registry_id constant uuid := '92eb106e-9b74-4f1e-8e5c-e84857d84735';
  document_id constant uuid := '7e4076fa-91cb-42f0-8f93-d553d292ed84';
  fact_id constant uuid := '8d523980-1965-4c85-aeb4-9ed7f63cd9fe';
  stage_id constant uuid := '4654db47-650f-4d0f-a50e-b66d5cb78713';
  expected_value constant jsonb := jsonb_build_object(
    'stage_code', 'association_establishment_approval',
    'stage_label', '조합설립인가',
    'approval_date', '2017-07-18',
    'source_displayed_current_stage', '조합설립인가',
    'source_system', '서울특별시 정비사업 정보몽땅'
  );
begin
  select id
    into target_area_id
    from public.areas
   where slug = 'seongsu-strategic-zone-1';

  if target_area_id is null then
    raise exception 'Required area with slug seongsu-strategic-zone-1 does not exist';
  end if;

  if exists (
    select 1
      from public.source_registry
     where id = registry_id
       and (
         provider_name,
         dataset_name,
         access_method,
         authentication_method,
         response_format,
         legal_effect_status,
         automation_status,
         implementation_readiness
       ) is distinct from (
         '서울특별시',
         '정비사업 정보몽땅',
         'official_web_portal',
         'none',
         'HTML',
         'reference_only',
         'conditional',
         'metadata_ready'
       )
  ) then
    raise exception 'Deterministic source_registry ID conflicts with existing data';
  end if;

  if exists (
    select 1
      from public.source_registry
     where provider_name = '서울특별시'
       and dataset_name = '정비사업 정보몽땅'
       and id <> registry_id
  ) then
    raise exception 'Source registry identity already exists under a different ID';
  end if;

  insert into public.source_registry (
    id,
    provider_name,
    dataset_name,
    access_method,
    authentication_method,
    response_format,
    legal_effect_status,
    automation_status,
    implementation_readiness
  )
  select
    registry_id,
    '서울특별시',
    '정비사업 정보몽땅',
    'official_web_portal',
    'none',
    'HTML',
    'reference_only',
    'conditional',
    'metadata_ready'
  where not exists (
    select 1 from public.source_registry where id = registry_id
  );

  if exists (
    select 1
      from public.source_documents
     where id = document_id
       and (
         source_registry_id,
         source_identifier,
         source_url,
         document_type,
         title,
         issued_at,
         effective_date,
         legal_effect_status,
         content_hash,
         storage_uri
       ) is distinct from (
         registry_id,
         'cafeId=200100002009a28',
         'https://cleanup.seoul.go.kr/assc/scrin-bbs/execute.do?cafeId=200100002009a28',
         'official_project_status_page',
         '성수전략정비구역 제1 주택정비형 재개발정비사업조합',
         null::timestamptz,
         null::date,
         'reference_only',
         null::text,
         null::text
       )
  ) then
    raise exception 'Deterministic source_documents ID conflicts with existing data';
  end if;

  if exists (
    select 1
      from public.source_documents
     where source_registry_id = registry_id
       and source_identifier = 'cafeId=200100002009a28'
       and id <> document_id
  ) then
    raise exception 'Source document identity already exists under a different ID';
  end if;

  insert into public.source_documents (
    id,
    source_registry_id,
    source_identifier,
    source_url,
    source_url_absence_reason,
    document_type,
    request_scope_identity,
    title,
    issued_at,
    effective_date,
    content_hash,
    storage_uri,
    legal_effect_status,
    supersedes_document_id
  )
  select
    document_id,
    registry_id,
    'cafeId=200100002009a28',
    'https://cleanup.seoul.go.kr/assc/scrin-bbs/execute.do?cafeId=200100002009a28',
    null,
    'official_project_status_page',
    null,
    '성수전략정비구역 제1 주택정비형 재개발정비사업조합',
    null,
    null,
    null,
    null,
    'reference_only',
    null
  where not exists (
    select 1 from public.source_documents where id = document_id
  );

  if exists (
    select 1
      from public.published_facts
     where id = fact_id
       and (
         area_id,
         normalized_observation_id,
         source_document_id,
         review_record_id,
         publication_batch_id,
         fact_type,
         attribute_key,
         published_value,
         effective_from,
         verification_status,
         last_verified_at
       ) is distinct from (
         target_area_id,
         null::uuid,
         document_id,
         null::uuid,
         null::uuid,
         'project_stage',
         'association_establishment_approval',
         expected_value,
         '2017-07-18'::date,
         'verified',
         null::timestamptz
       )
  ) then
    raise exception 'Deterministic published_facts ID conflicts with existing data';
  end if;

  if exists (
    select 1
      from public.published_facts
     where area_id = target_area_id
       and fact_type = 'project_stage'
       and attribute_key = 'association_establishment_approval'
       and effective_from = '2017-07-18'::date
       and id <> fact_id
  ) then
    raise exception 'Stage fact identity already exists under a different ID';
  end if;

  insert into public.published_facts (
    id,
    area_id,
    normalized_observation_id,
    source_document_id,
    review_record_id,
    publication_batch_id,
    fact_type,
    attribute_key,
    published_value,
    effective_from,
    verification_status,
    last_verified_at
  )
  select
    fact_id,
    target_area_id,
    null,
    document_id,
    null,
    null,
    'project_stage',
    'association_establishment_approval',
    expected_value,
    '2017-07-18'::date,
    'verified',
    null
  where not exists (
    select 1 from public.published_facts where id = fact_id
  );

  if exists (
    select 1
      from public.stage_history
     where id = stage_id
       and (
         area_id,
         stage_code,
         effective_date,
         published_fact_id,
         source_document_id,
         verification_status,
         review_record_id,
         supersedes_stage_history_id
       ) is distinct from (
         target_area_id,
         'association_establishment_approval',
         '2017-07-18'::date,
         fact_id,
         document_id,
         'verified',
         null::uuid,
         null::uuid
       )
  ) then
    raise exception 'Deterministic stage_history ID conflicts with existing data';
  end if;

  insert into public.stage_history (
    id,
    area_id,
    stage_code,
    effective_date,
    published_fact_id,
    source_document_id,
    verification_status,
    review_record_id,
    supersedes_stage_history_id
  )
  select
    stage_id,
    target_area_id,
    'association_establishment_approval',
    '2017-07-18'::date,
    fact_id,
    document_id,
    'verified',
    null,
    null
  where not exists (
    select 1 from public.stage_history where id = stage_id
  );

  -- Phase 1 cache reconstruction uses the latest verified history row by date.
  -- Later stage-order and correction rules may supersede this simple ordering.
  select
    stage.id,
    fact.published_value ->> 'stage_label'
    into latest_stage_id, latest_stage_label
    from public.stage_history as stage
    join public.published_facts as fact
      on fact.id = stage.published_fact_id
   where stage.area_id = target_area_id
     and stage.verification_status = 'verified'
   order by
     stage.effective_date desc nulls last,
     stage.recorded_at desc
   limit 1;

  if latest_stage_id is null then
    raise exception 'No verified stage_history row exists for target area';
  end if;

  update public.areas
     set current_stage = latest_stage_label,
         current_stage_history_id = latest_stage_id
   where id = target_area_id;
end
$$;
