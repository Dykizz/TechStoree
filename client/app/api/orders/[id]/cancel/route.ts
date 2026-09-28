import { NextRequest, NextResponse } from "next/server";
import { callBackendWithSession, setSessionCookies, REMEMBER_COOKIE } from "../../../../../lib/auth-server";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json().catch(() => ({ reason: "Khách hàng yêu cầu hủy đơn." }));
    const { response, renewed } = await callBackendWithSession(request, `Orders/${id}/cancel`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    const data = await response.json();
    const res = NextResponse.json(data, { status: response.status });
    if (renewed) {
      setSessionCookies(res, renewed, request.cookies.get(REMEMBER_COOKIE)?.value === "1");
    }
    return res;
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Backend unreachable";
    return NextResponse.json({ success: false, message: msg }, { status: 503 });
  }
}
