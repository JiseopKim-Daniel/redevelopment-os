import type { Metadata } from "next";

import { AreaCard } from "@/components/area-card";
import { mockAreas } from "@/data/mock-areas";

export const metadata: Metadata = { title: "구역 탐색" };

export default function AreasPage() {
  return (
    <main className="mx-auto max-w-6xl px-6 py-14">
      <div className="max-w-2xl">
        <p className="text-sm font-semibold text-emerald-700">AREA DIRECTORY</p>
        <h1 className="mt-2 text-4xl font-bold tracking-tight text-slate-950">서울 정비사업 구역</h1>
        <p className="mt-4 leading-7 text-slate-600">
          현재는 MVP 화면 검증을 위한 예시 데이터입니다. Supabase 연결 후 공식 출처 기반 데이터로 교체됩니다.
        </p>
      </div>

      <div className="mt-8 flex flex-wrap gap-3" aria-label="필터 자리 표시자">
        {["전체 자치구", "사업 종류", "사업 단계"].map((label) => (
          <button key={label} type="button" disabled className="cursor-not-allowed rounded-full border border-slate-200 bg-white px-4 py-2 text-sm text-slate-500">
            {label} ▾
          </button>
        ))}
      </div>

      <p className="mt-10 text-sm text-slate-500">총 {mockAreas.length}개 구역</p>
      <div className="mt-4 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {mockAreas.map((area) => <AreaCard key={area.id} area={area} />)}
      </div>
    </main>
  );
}

