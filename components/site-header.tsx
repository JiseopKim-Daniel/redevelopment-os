import Link from "next/link";

export function SiteHeader() {
  return (
    <header className="border-b border-slate-200 bg-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Link href="/" className="text-lg font-bold tracking-tight text-slate-950">
          Redevelopment OS
        </Link>
        <nav aria-label="주요 메뉴" className="flex gap-6 text-sm font-medium text-slate-600">
          <Link className="transition hover:text-emerald-700" href="/areas">
            구역 탐색
          </Link>
          <span className="cursor-not-allowed text-slate-300" title="MVP 이후 제공 예정">
            관심 구역
          </span>
        </nav>
      </div>
    </header>
  );
}

