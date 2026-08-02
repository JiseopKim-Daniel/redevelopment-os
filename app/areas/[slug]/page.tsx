import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { getAreaBySlug, mockAreas } from "@/data/mock-areas";

type AreaDetailPageProps = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return mockAreas.map(({ slug }) => ({ slug }));
}

export async function generateMetadata({ params }: AreaDetailPageProps): Promise<Metadata> {
  const area = getAreaBySlug((await params).slug);
  return { title: area?.name ?? "구역 정보" };
}

export default async function AreaDetailPage({ params }: AreaDetailPageProps) {
  const area = getAreaBySlug((await params).slug);
  if (!area) notFound();

  const flags = [
    ["신통기획", area.isShintong],
    ["모아타운", area.isMoatown],
    ["토지거래허가구역", area.isTohuga],
  ] as const;

  return (
    <main className="mx-auto max-w-5xl px-6 py-12">
      <Link href="/areas" className="text-sm font-semibold text-slate-500 hover:text-emerald-700">← 구역 목록</Link>

      <header className="mt-7 rounded-3xl bg-slate-950 p-8 text-white sm:p-10">
        <p className="text-sm font-semibold text-emerald-300">{area.district} · {area.projectType}</p>
        <div className="mt-3 flex flex-col justify-between gap-6 sm:flex-row sm:items-end">
          <div>
            <h1 className="text-3xl font-bold sm:text-4xl">{area.name}</h1>
            <p className="mt-3 text-slate-300">{area.address}</p>
          </div>
          <div className="w-fit rounded-2xl bg-emerald-400 px-5 py-3 text-emerald-950">
            <p className="text-xs font-semibold">투자 점수 v1</p>
            <p className="text-3xl font-bold">{area.investmentScore}</p>
          </div>
        </div>
      </header>

      <div className="mt-8 grid gap-8 lg:grid-cols-[1.5fr_1fr]">
        <section className="rounded-2xl border border-slate-200 bg-white p-7">
          <h2 className="text-xl font-bold">구역 개요</h2>
          <p className="mt-4 leading-7 text-slate-600">{area.summary}</p>
          <dl className="mt-7 grid gap-5 border-t border-slate-100 pt-6 sm:grid-cols-2">
            <div><dt className="text-sm text-slate-500">현재 사업 단계</dt><dd className="mt-1 font-semibold">{area.currentStage}</dd></div>
            <div><dt className="text-sm text-slate-500">예상 세대수</dt><dd className="mt-1 font-semibold">{area.expectedUnits.toLocaleString()}세대</dd></div>
            <div><dt className="text-sm text-slate-500">리스크 점수</dt><dd className="mt-1 font-semibold">{area.riskScore} / 100</dd></div>
            <div><dt className="text-sm text-slate-500">정보 갱신일</dt><dd className="mt-1 font-semibold">{area.updatedAt}</dd></div>
          </dl>
        </section>

        <aside className="space-y-6">
          <section className="rounded-2xl border border-slate-200 bg-white p-6">
            <h2 className="font-bold">핵심 조건</h2>
            <ul className="mt-4 space-y-3">
              {flags.map(([label, enabled]) => (
                <li key={label} className="flex items-center justify-between text-sm">
                  <span className="text-slate-600">{label}</span>
                  <span className={enabled ? "font-semibold text-emerald-700" : "text-slate-400"}>{enabled ? "해당" : "해당 없음"}</span>
                </li>
              ))}
            </ul>
          </section>
          <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-6">
            <h2 className="font-bold">투자 메모</h2>
            <p className="mt-3 text-sm leading-6 text-slate-500">Supabase 연결 후 개인 메모와 점수 세부 항목이 표시될 영역입니다.</p>
          </section>
        </aside>
      </div>
    </main>
  );
}

