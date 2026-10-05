import { NextRequest, NextResponse } from "next/server";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const base = (process.env.API_BASE_URL || "http://localhost:5000").replace(/\/$/, "");
  const backendUrl = `${base}/api/Products/${id}`;

  try {
    const res = await fetch(backendUrl, {
      cache: "no-store",
      signal: AbortSignal.timeout(5000),
    });

    if (!res.ok) {
      return NextResponse.json(
        { error: "Product not found or backend error" },
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
