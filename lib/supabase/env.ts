export function getSupabaseEnv() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url || !publishableKey) {
    throw new Error("Supabase 환경 변수가 없습니다. .env.example을 참고해 .env.local을 설정하세요.");
  }

  return { url, publishableKey };
}

