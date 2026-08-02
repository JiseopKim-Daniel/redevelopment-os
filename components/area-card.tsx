import Link from "next/link";

import type { Area } from "@/types/area";

export function AreaCard({ area }: { area: Area }) {
  return (
    <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold text-emerald-700">{area.district} · {area.projectType}</p>
          <h2 className="mt-2 text-xl font-bold text-slate-950">{area.name}</h2>
        </div>
        <div className="rounded-xl bg-emerald-50 px-3 py-2 text-center">
          <p className="text-xs text-emerald-700">투자 점수</p>
          <p className="text-xl font-bold text-emerald-800">{area.investmentScore}</p>
        </div>
      </div>

      <p className="mt-4 text-sm leading-6 text-slate-600">{area.summary}</p>

      <dl className="mt-5 grid grid-cols-2 gap-3 text-sm">
        <div className="rounded-lg bg-slate-50 p-3">
          <dt className="text-slate-500">현재 단계</dt>
          <dd className="mt-1 font-semibold text-slate-900">{area.currentStage}</dd>
        </div>
        <div className="rounded-lg bg-slate-50 p-3">
          <dt className="text-slate-500">예상 세대수</dt>
          <dd className="mt-1 font-semibold text-slate-900">{area.expectedUnits.toLocaleString()}세대</dd>
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

