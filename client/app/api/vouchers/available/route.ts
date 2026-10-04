import { NextResponse } from "next/server";
import { apiEndpoint } from "../../../../lib/auth-server";

export async function GET() {
  try {
    const res = await fetch(apiEndpoint("vouchers/available"), {
      cache: "no-store",
      signal: AbortSignal.timeout(5000),
    });
    const data = await res.json();
    return NextResponse.json(data, { status: res.status });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Backend unreachable";
    return NextResponse.json({ success: false, message: msg }, { status: 503 });
  }
}
