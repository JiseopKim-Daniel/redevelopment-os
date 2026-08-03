-- Register the verified identity of Seongdong-gu notice 서고 제2025-155호.
-- This data-only migration records the notice itself. It does not assert a
-- redevelopment project stage, create stage_history, or update current_stage.
--
-- The official notice identity is registered through the Phase 1 manual
-- workflow. No durable Phase 2 review_record exists yet, so last_verified_at
-- remains null until an explicit documented human review event is recorded.
-- No downloaded file is present in the repository, so content_hash and
-- storage_uri are also null.

do $$
declare
  target_area_id uuid;
  registry_id constant uuid := 'a8ee3609-b108-4d7d-972a-a66cc72733dc';
  document_id constant uuid := '7021bb48-4d14-46ad-973c-25b45fb87e5e';
  fact_id constant uuid := 'a2c40f45-6959-42a7-a456-ecb75ea137db';
  expected_value constant jsonb := jsonb_build_object(
    'notice_number', '서고 제2025-155호',
    'notice_title', '성수전략정비구역 제1지구 지구단위계획(정비계획) 결정(변경) 고시문 및 결정도',
    'authority', '성동구청',
    'department', '주거정비과',
    'notice_date', '2025-03-27',
    'notice_type', '정비계획 결정(변경)'
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
         implementation_readiness,
         terms_checked_at
       ) is distinct from (
         '성동구청',
         '성동구 고시공고',
         'official_web_notice',
         'none',
         'HTML/PDF',
         'legally_effective',
         'conditional',
         'metadata_ready',
         null::timestamptz
       )
  ) then
    raise exception 'Deterministic source_registry ID conflicts with existing data';
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
    implementation_readiness,
    terms_checked_at
  )
  select
    registry_id,
    '성동구청',
    '성동구 고시공고',
    'official_web_notice',
    'none',
    'HTML/PDF',
    'legally_effective',
    'conditional',
    'metadata_ready',
    null
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
         '서고 제2025-155호',
         'https://www.sd.go.kr/main/selectBbsNttView.do?bbsNo=184&integrDeptCode=30301590000&key=3715&nttNo=346248',
         'official_redevelopment_plan_notice',
         '성수전략정비구역 제1지구 지구단위계획(정비계획) 결정(변경) 고시문 및 결정도',
         null::timestamptz,
         '2025-03-27'::date,
         'legally_effective',
         null::text,
         null::text
       )
  ) then
    raise exception 'Deterministic source_documents ID conflicts with existing data';
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
    '서고 제2025-155호',
    'https://www.sd.go.kr/main/selectBbsNttView.do?bbsNo=184&integrDeptCode=30301590000&key=3715&nttNo=346248',
    null,
    'official_redevelopment_plan_notice',
    null,
    '성수전략정비구역 제1지구 지구단위계획(정비계획) 결정(변경) 고시문 및 결정도',
    null,
    '2025-03-27'::date,
    null,
    null,
    'legally_effective',
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
         source_document_id,
         fact_type,
         attribute_key,
         published_value,
         effective_from,
         verification_status,
         last_verified_at
       ) is distinct from (
         target_area_id,
         document_id,
         'official_notice',
         'redevelopment_plan_notice',
         expected_value,
         '2025-03-27'::date,
         'verified',
         null::timestamptz
       )
  ) then
    raise exception 'Deterministic published_facts ID conflicts with existing data';
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
    'official_notice',
    'redevelopment_plan_notice',
    expected_value,
    '2025-03-27'::date,
    'verified',
    null
  where not exists (
    select 1 from public.published_facts where id = fact_id
  );
end
$$;
