import Link from "next/link";

import { AreaCard } from "@/components/area-card";
import { mockAreas } from "@/data/mock-areas";

export default function HomePage() {
  return (
    <main>
      <section className="border-b border-emerald-100 bg-gradient-to-br from-emerald-950 via-emerald-900 to-slate-900 text-white">
        <div className="mx-auto max-w-6xl px-6 py-24">
          <p className="text-sm font-semibold tracking-widest text-emerald-300">SEOUL REDEVELOPMENT INTELLIGENCE</p>
          <h1 className="mt-5 max-w-3xl text-4xl font-bold leading-tight sm:text-6xl">
            흩어진 정비사업 정보를<br />투자 판단의 기준으로.
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-8 text-emerald-50/80">
            서울 재개발·재건축 구역의 사업 단계, 핵심 조건과 투자 점수를 한곳에서 비교합니다.
          </p>
          <Link
            href="/areas"
            className="mt-9 inline-flex rounded-xl bg-white px-5 py-3 font-semibold text-emerald-900 transition hover:bg-emerald-50"
          >
            구역 둘러보기
          </Link>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 py-16">
        <div className="flex items-end justify-between gap-4">
          <div>
            <p className="text-sm font-semibold text-emerald-700">관심 구역 미리보기</p>
            <h2 className="mt-2 text-3xl font-bold text-slate-950">주요 정비사업 구역</h2>
          </div>
          <Link href="/areas" className="hidden text-sm font-semibold text-slate-600 hover:text-emerald-700 sm:block">
            전체 보기 →
          </Link>
        </div>
        <div className="mt-8 grid gap-6 lg:grid-cols-3">
          {mockAreas.map((area) => <AreaCard key={area.id} area={area} />)}
        </div>
      </section>
    </main>
  );
}

