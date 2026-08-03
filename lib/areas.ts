export type PublicArea = {
  id: string;
  slug: string;
  canonical_name: string;
  representative_address: string | null;
  project_type: string | null;
  lifecycle_status: string;
  current_stage: string | null;
};

export type OfficialNoticeValue = {
  notice_number: string | null;
  notice_title: string | null;
  authority: string | null;
  department: string | null;
  notice_date: string | null;
  notice_type: string | null;
};

export type OfficialNoticeSourceDocument = {
  source_identifier: string | null;
  source_url: string | null;
  title: string | null;
  issued_at: string | null;
  effective_date: string | null;
  legal_effect_status: string;
};

export type OfficialNotice = {
  id: string;
  fact_type: string;
  attribute_key: string;
  published_value: OfficialNoticeValue;
  effective_from: string | null;
  last_verified_at: string | null;
  source_document: OfficialNoticeSourceDocument | null;
};

const lifecycleLabels: Record<string, string> = {
  active: "추적 중",
  cancelled: "취소",
  merged: "병합",
  released: "해제",
  superseded: "대체됨",
  suspended: "중단·보류",
};

export function getLifecycleLabel(status: string): string {
  return lifecycleLabels[status] ?? status;
}
