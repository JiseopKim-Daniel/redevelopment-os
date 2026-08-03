import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import {
  getLifecycleLabel,
  type OfficialNotice,
  type OfficialNoticeSourceDocument,
  type OfficialNoticeValue,
  type PublicArea,
} from "@/lib/areas";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "구역 정보" };
export const dynamic = "force-dynamic";

type AreaDetailPageProps = { params: Promise<{ slug: string }> };

type OfficialNoticeQueryRow = {
  id: string;
  fact_type: string;
  attribute_key: string;
  published_value: unknown;
  effective_from: string | null;
  last_verified_at: string | null;
  source_documents: OfficialNoticeSourceDocument | null;
};

type OfficialNoticesResult =
  | { notices: OfficialNotice[]; error: null }
  | { notices: []; error: string };

function asNullableString(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

function normalizeNoticeValue(value: unknown): OfficialNoticeValue {
  const record =
    typeof value === "object" && value !== null
      ? (value as Record<string, unknown>)
      : {};

  return {
    notice_number: asNullableString(record.notice_number),
    notice_title: asNullableString(record.notice_title),
    authority: asNullableString(record.authority),
    department: asNullableString(record.department),
    notice_date: asNullableString(record.notice_date),
    notice_type: asNullableString(record.notice_type),
  };
}

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

async function getOfficialNotices(areaId: string): Promise<OfficialNoticesResult> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("published_facts")
    .select(
      `
        id,
        fact_type,
        attribute_key,
        published_value,
        effective_from,
        last_verified_at,
        source_documents!published_facts_source_document_fk (
          source_identifier,
          source_url,
          title,
          issued_at,
          effective_date,
          legal_effect_status
        )
      `,
    )
    .eq("area_id", areaId)
    .eq("verification_status", "verified")
    .eq("fact_type", "official_notice")
    .order("effective_from", { ascending: false })
    .returns<OfficialNoticeQueryRow[]>();

  if (error) {
    console.error("Supabase official notice query failed:", error.message);
    return {
      notices: [],
      error: "공식 출처를 불러오는 중 문제가 발생했습니다.",
    };
  }

  return {
    notices: (data ?? []).map((notice) => ({
      id: notice.id,
      fact_type: notice.fact_type,
      attribute_key: notice.attribute_key,
      published_value: normalizeNoticeValue(notice.published_value),
      effective_from: notice.effective_from,
      last_verified_at: notice.last_verified_at,
      source_document: notice.source_documents,
    })),
    error: null,
  };
}

export default async function AreaDetailPage({ params }: AreaDetailPageProps) {
  const area = await getAreaBySlug((await params).slug);
  if (!area) notFound();
  const officialNotices = await getOfficialNotices(area.id);

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

      <section className="mt-8 rounded-2xl border border-slate-200 bg-white p-7">
        <h2 className="text-xl font-bold">공식 출처</h2>

        {officialNotices.error ? (
          <p className="mt-4 text-sm text-red-700">{officialNotices.error}</p>
        ) : officialNotices.notices.length === 0 ? (
          <p className="mt-4 text-sm text-slate-600">등록된 공식 고시가 아직 없습니다.</p>
        ) : (
          <>
            <p className="mt-3 text-sm text-slate-600">
              아래 자료는 확인된 공식 고시이며, 현재 사업 단계와는 별도로 관리됩니다.
            </p>
            <div className="mt-6 space-y-5">
              {officialNotices.notices.map((notice) => {
                const value = notice.published_value;
                const source = notice.source_document;
                const noticeNumber = value.notice_number ?? source?.source_identifier;
                const noticeTitle = value.notice_title ?? source?.title;
                const noticeDate =
                  notice.effective_from ?? value.notice_date ?? source?.effective_date;

                return (
                  <article
                    key={notice.id}
                    className="rounded-2xl border border-slate-200 bg-slate-50 p-5"
                  >
                    <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                      <p className="text-sm font-semibold text-emerald-700">
                        {noticeNumber ?? "고시번호 확인 전"}
                      </p>
                      <span className="w-fit rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-800">
                        공식 문서 확인
                      </span>
                    </div>
                    <h3 className="mt-3 text-lg font-bold text-slate-950">
                      {noticeTitle ?? "고시 제목 확인 전"}
                    </h3>
                    <dl className="mt-5 grid gap-4 text-sm sm:grid-cols-2">
                      <div>
                        <dt className="text-slate-500">기관·부서</dt>
                        <dd className="mt-1 font-semibold text-slate-900">
                          {[value.authority, value.department].filter(Boolean).join(" · ") ||
                            "기관 정보 확인 전"}
                        </dd>
                      </div>
                      <div>
                        <dt className="text-slate-500">고시 유형</dt>
                        <dd className="mt-1 font-semibold text-slate-900">
                          {value.notice_type ?? "고시 유형 확인 전"}
                        </dd>
                      </div>
                      <div>
                        <dt className="text-slate-500">효력일·고시일</dt>
                        <dd className="mt-1 font-semibold text-slate-900">
                          {noticeDate ?? "날짜 확인 전"}
                        </dd>
                      </div>
                    </dl>
                    {source?.source_url ? (
                      <a
                        href={source.source_url}
                        target="_blank"
                        rel="noreferrer"
                        className="mt-5 inline-flex text-sm font-semibold text-emerald-700 hover:text-emerald-900"
                      >
                        성동구청 원문 보기
                      </a>
                    ) : null}
                  </article>
                );
              })}
            </div>
          </>
        )}
      </section>
    </main>
  );
}
