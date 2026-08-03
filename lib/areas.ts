export type PublicArea = {
  id: string;
  slug: string;
  canonical_name: string;
  representative_address: string | null;
  project_type: string | null;
  lifecycle_status: string;
  current_stage: string | null;
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
