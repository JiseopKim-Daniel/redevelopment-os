import { NextResponse } from "next/server";

import { runSeongsuZone1ManualIngestion } from "@/lib/ingestion/seongsu-zone1";

export async function POST() {
  if (process.env.NODE_ENV === "production") {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  try {
    const result = await runSeongsuZone1ManualIngestion();
    return NextResponse.json(result, { status: 201 });
  } catch {
    return NextResponse.json(
      { error: "The development ingestion workflow failed." },
      { status: 500 },
    );
  }
}
