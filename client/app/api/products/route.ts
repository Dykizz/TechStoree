import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const base = (process.env.API_BASE_URL || "http://localhost:5000").replace(/\/$/, "");
  const searchParams = request.nextUrl.searchParams;
  const backendUrl = `${base}/api/Products?${searchParams.toString()}`;

  try {
    const res = await fetch(backendUrl, {
      cache: "no-store",
      signal: AbortSignal.timeout(5000),
    });

    if (!res.ok) {
      return NextResponse.json(
        { error: "Backend responded with error" },
        { status: res.status }
      );
    }

    const envelope = await res.json();
    return NextResponse.json(envelope.data);
  } catch {
    return NextResponse.json(
      { error: "Backend unreachable" },
      { status: 503 }
    );
  }
}
