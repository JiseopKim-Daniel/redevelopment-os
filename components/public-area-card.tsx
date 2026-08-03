import Link from "next/link";

import { getLifecycleLabel, type PublicArea } from "@/lib/areas";

export function PublicAreaCard({ area }: { area: PublicArea }) {
  return (
    <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
      <div>
        <p className="text-sm font-semibold text-emerald-700">
          {area.project_type ?? "사업 유형 확인 전"}
        </p>
        <h2 className="mt-2 text-xl font-bold text-slate-950">{area.canonical_name}</h2>
      </div>

      <p className="mt-4 text-sm leading-6 text-slate-600">
        {area.representative_address ?? "대표 주소 확인 전"}
      </p>

      <dl className="mt-5 grid grid-cols-2 gap-3 text-sm">
        <div className="rounded-lg bg-slate-50 p-3">
          <dt className="text-slate-500">현재 단계</dt>
          <dd className="mt-1 font-semibold text-slate-900">
            {area.current_stage ?? "공식 단계 확인 전"}
          </dd>
        </div>
        <div className="rounded-lg bg-slate-50 p-3">
          <dt className="text-slate-500">구역 상태</dt>
          <dd className="mt-1 font-semibold text-slate-900">
            {getLifecycleLabel(area.lifecycle_status)}
          </dd>
        </div>
      </dl>

      <Link
        href={`/areas/${area.slug}`}
        className="mt-6 inline-flex text-sm font-semibold text-emerald-700 hover:text-emerald-900"
      >
        상세 정보 보기 →
      </Link>
    </article>
  );
}
