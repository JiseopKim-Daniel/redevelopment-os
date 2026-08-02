import Link from "next/link";

export default function NotFound() {
  return (
    <main className="mx-auto max-w-2xl px-6 py-24 text-center">
      <p className="text-sm font-semibold text-emerald-700">404</p>
      <h1 className="mt-3 text-3xl font-bold">구역 정보를 찾을 수 없습니다.</h1>
      <Link href="/areas" className="mt-7 inline-flex rounded-xl bg-slate-900 px-5 py-3 font-semibold text-white">구역 목록으로 돌아가기</Link>
    </main>
  );
}

