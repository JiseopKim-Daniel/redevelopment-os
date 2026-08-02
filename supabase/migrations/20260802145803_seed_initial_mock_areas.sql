-- Redevelopment OS: initial repository-local development fixtures
--
-- These values reproduce data/mock-areas.ts for local MVP development. They
-- are reference-only, have no legal effect, and are not verified official
-- redevelopment facts.
--
-- The Phase 1 stage_history table accepts only verified/history statuses.
-- Because this repository contains no cited official source for the mock
-- display stages, this migration intentionally inserts no published_facts or
-- stage_history rows. areas.current_stage and current_stage_history_id remain
-- null; the original display stage is retained only inside user_values.

insert into public.source_registry (
  id,
  provider_name,
  dataset_name,
  dataset_identifier,
  service_identifier,
  access_method,
  authentication_method,
  response_format,
  legal_effect_status,
  automation_status,
  implementation_readiness,
  provider_update_frequency,
  polling_frequency,
  reconciliation_frequency,
  terms_checked_at
)
values (
  '00000000-0000-4000-8000-000000000001',
  'Redevelopment OS',
  'Initial development fixtures',
  'repository:data/mock-areas.ts',
  null,
  'repository_local_fixture',
  'none',
  'TypeScript',
  'reference_only',
  'prohibited',
  'metadata_ready',
  null,
  null,
  null,
  null
)
on conflict (id) do nothing;

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
values (
  '00000000-0000-4000-8000-000000000002',
  '00000000-0000-4000-8000-000000000001',
  'data/mock-areas.ts',
  null,
  'Repository-local development fixture data has no external source URL.',
  'internal_development_fixture',
  'data/mock-areas.ts:mockAreas',
  'Initial mock redevelopment areas',
  null,
  null,
  null,
  null,
  'reference_only',
  null
)
on conflict (id) do nothing;

insert into public.areas (
  id,
  slug,
  canonical_name,
  district_code,
  representative_address,
  representative_latitude,
  representative_longitude,
  project_type,
  lifecycle_status,
  current_stage,
  current_stage_history_id,
  successor_area_id
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    'seongsu-strategic-zone-1',
    '성수전략정비구역 1지구',
    null,
    '서울특별시 성동구 성수동1가 일대',
    null,
    null,
    '재개발',
    'active',
    null,
    null,
    null
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    'sanggye-newtown-zone-5',
    '상계뉴타운 5구역',
    null,
    '서울특별시 노원구 상계동 일대',
    null,
    null,
    '재개발',
    'active',
    null,
    null,
    null
  ),
  (
    '33333333-3333-4333-8333-333333333333',
    'myeonmok-moa-town',
    '면목동 모아타운',
    null,
    '서울특별시 중랑구 면목동 일대',
    null,
    null,
    '모아타운',
    'active',
    null,
    null,
    null
  )
on conflict (id) do nothing;

-- district_code remains null because the mock data contains district names,
-- not authoritative administrative codes. Every remaining mock display value
-- is stored as one non-official fixture bundle per area.
insert into public.user_values (
  id,
  area_id,
  value_type,
  value,
  unit,
  entered_by,
  observed_at,
  source_note
)
values
  (
    '11111111-aaaa-4111-8111-111111111111',
    '11111111-1111-4111-8111-111111111111',
    'initial_mock_display_data',
    jsonb_build_object(
      'legacy_mock_id', 'area-1',
      'district', '성동구',
      'display_stage', '정비구역 지정',
      'is_shintong', false,
      'is_moatown', false,
      'is_land_transaction_permit_zone', true,
      'expected_units', 3014,
      'investment_score', 86,
      'risk_score', 44,
      'summary', '한강변 입지와 대규모 정비계획을 갖춘 장기 관찰 대상 구역입니다.',
      'mock_updated_at', '2026-07-28'
    ),
    null,
    'Redevelopment OS development fixture',
    '2026-07-28T00:00:00Z',
    'Copied from data/mock-areas.ts; reference-only and not an official fact.'
  ),
  (
    '22222222-aaaa-4222-8222-222222222222',
    '22222222-2222-4222-8222-222222222222',
    'initial_mock_display_data',
    jsonb_build_object(
      'legacy_mock_id', 'area-2',
      'district', '노원구',
      'display_stage', '사업시행인가',
      'is_shintong', false,
      'is_moatown', false,
      'is_land_transaction_permit_zone', false,
      'expected_units', 2042,
      'investment_score', 78,
      'risk_score', 38,
      'summary', '사업 진행 속도와 동북권 주거 환경 개선 가능성을 함께 살펴볼 구역입니다.',
      'mock_updated_at', '2026-07-24'
    ),
    null,
    'Redevelopment OS development fixture',
    '2026-07-24T00:00:00Z',
    'Copied from data/mock-areas.ts; reference-only and not an official fact.'
  ),
  (
    '33333333-aaaa-4333-8333-333333333333',
    '33333333-3333-4333-8333-333333333333',
    'initial_mock_display_data',
    jsonb_build_object(
      'legacy_mock_id', 'area-3',
      'district', '중랑구',
      'display_stage', '정비구역 지정',
      'is_shintong', false,
      'is_moatown', true,
      'is_land_transaction_permit_zone', false,
      'expected_units', 1850,
      'investment_score', 72,
      'risk_score', 51,
      'summary', '소규모 정비사업이 모여 진행되는 만큼 구역별 속도 차이를 확인해야 합니다.',
      'mock_updated_at', '2026-07-20'
    ),
    null,
    'Redevelopment OS development fixture',
    '2026-07-20T00:00:00Z',
    'Copied from data/mock-areas.ts; reference-only and not an official fact.'
  )
on conflict (id) do nothing;
