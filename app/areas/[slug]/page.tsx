import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { getLifecycleLabel, type PublicArea } from "@/lib/areas";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "구역 정보" };
export const dynamic = "force-dynamic";

type AreaDetailPageProps = { params: Promise<{ slug: string }> };

async function getAreaBySlug(slug: string): Promise<PublicArea | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("areas")
    .select(
      "id, slug, canonical_name, representative_address, project_type, lifecycle_status, current_stage",
    )
    .eq("slug", slug)
    .maybeSingle();

  if (error) {
    console.error("Supabase area detail query failed:", error.message);
    throw new Error("구역 정보를 불러오는 중 문제가 발생했습니다.");
  }

  return data;
}

export default async function AreaDetailPage({ params }: AreaDetailPageProps) {
  const area = await getAreaBySlug((await params).slug);
  if (!area) notFound();

  return (
    <main className="mx-auto max-w-5xl px-6 py-12">
      <Link href="/areas" className="text-sm font-semibold text-slate-500 hover:text-emerald-700">
        ← 구역 목록
      </Link>

      <header className="mt-7 rounded-3xl bg-slate-950 p-8 text-white sm:p-10">
        <p className="text-sm font-semibold text-emerald-300">
          {area.project_type ?? "사업 유형 확인 전"}
        </p>
        <div className="mt-3 flex flex-col justify-between gap-6 sm:flex-row sm:items-end">
          <div>
            <h1 className="text-3xl font-bold sm:text-4xl">{area.canonical_name}</h1>
            <p className="mt-3 text-slate-300">
              {area.representative_address ?? "대표 주소 확인 전"}
            </p>
          </div>
          <div className="w-fit rounded-2xl bg-emerald-400 px-5 py-3 text-emerald-950">
            <p className="text-xs font-semibold">구역 상태</p>
            <p className="mt-1 text-lg font-bold">
              {getLifecycleLabel(area.lifecycle_status)}
            </p>
          </div>
        </div>
      </header>

      <section className="mt-8 rounded-2xl border border-slate-200 bg-white p-7">
        <h2 className="text-xl font-bold">구역 기본 정보</h2>
        <dl className="mt-7 grid gap-5 border-t border-slate-100 pt-6 sm:grid-cols-2">
          <div>
            <dt className="text-sm text-slate-500">현재 사업 단계</dt>
            <dd className="mt-1 font-semibold">{area.current_stage ?? "공식 단계 확인 전"}</dd>
          </div>
          <div>
            <dt className="text-sm text-slate-500">사업 유형</dt>
            <dd className="mt-1 font-semibold">{area.project_type ?? "사업 유형 확인 전"}</dd>
          </div>
          <div>
            <dt className="text-sm text-slate-500">구역 상태</dt>
            <dd className="mt-1 font-semibold">
              {getLifecycleLabel(area.lifecycle_status)}
            </dd>
          </div>
          <div>
            <dt className="text-sm text-slate-500">대표 주소</dt>
            <dd className="mt-1 font-semibold">
              {area.representative_address ?? "대표 주소 확인 전"}
            </dd>
          </div>
        </dl>
      </section>
    </main>
  );
}
