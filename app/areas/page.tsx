import type { Metadata } from "next";

import { PublicAreaCard } from "@/components/public-area-card";
import type { PublicArea } from "@/lib/areas";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "구역 탐색" };
export const dynamic = "force-dynamic";

type AreasResult =
  | { areas: PublicArea[]; error: null }
  | { areas: []; error: string };

async function getAreas(): Promise<AreasResult> {
  try {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("areas")
      .select(
        "id, slug, canonical_name, representative_address, project_type, lifecycle_status, current_stage",
      )
      .order("canonical_name", { ascending: true });

    if (error) {
      console.error("Supabase areas query failed:", error.message);
      return {
        areas: [],
        error: "구역 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.",
      };
    }

    return { areas: data ?? [], error: null };
  } catch (error) {
    console.error(
      "Supabase areas request could not start:",
      error instanceof Error ? error.message : "Unknown error",
    );
    return {
      areas: [],
      error: "구역 정보를 불러오지 못했습니다. 서비스 설정을 확인해 주세요.",
    };
  }
}

export default async function AreasPage() {
  const result = await getAreas();

  return (
    <main className="mx-auto max-w-6xl px-6 py-14">
      <div className="max-w-2xl">
        <p className="text-sm font-semibold text-emerald-700">AREA DIRECTORY</p>
        <h1 className="mt-2 text-4xl font-bold tracking-tight text-slate-950">서울 정비사업 구역</h1>
        <p className="mt-4 leading-7 text-slate-600">
          공개 구역 기본 정보를 확인할 수 있습니다. 공식 확인 전 단계와 비공개 사용자 값은 표시하지 않습니다.
        </p>
      </div>

      <div className="mt-8 flex flex-wrap gap-3" aria-label="필터 자리 표시자">
        {["전체 자치구", "사업 종류", "사업 단계"].map((label) => (
          <button key={label} type="button" disabled className="cursor-not-allowed rounded-full border border-slate-200 bg-white px-4 py-2 text-sm text-slate-500">
            {label} ▾
          </button>
        ))}
      </div>

      {result.error ? (
        <section className="mt-10 rounded-2xl border border-rose-200 bg-rose-50 p-6 text-rose-800" role="alert">
          <h2 className="font-bold">구역 정보를 표시할 수 없습니다</h2>
          <p className="mt-2 text-sm">{result.error}</p>
        </section>
      ) : result.areas.length === 0 ? (
        <section className="mt-10 rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
          <h2 className="font-bold text-slate-900">등록된 구역이 없습니다</h2>
          <p className="mt-2 text-sm text-slate-500">공개 가능한 구역 데이터가 등록되면 이곳에 표시됩니다.</p>
        </section>
      ) : (
        <>
          <p className="mt-10 text-sm text-slate-500">총 {result.areas.length}개 구역</p>
          <div className="mt-4 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {result.areas.map((area) => <PublicAreaCard key={area.id} area={area} />)}
          </div>
        </>
      )}
    </main>
  );
}
