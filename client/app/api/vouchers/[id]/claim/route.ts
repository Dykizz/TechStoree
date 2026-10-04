import { NextRequest, NextResponse } from "next/server";
import { callBackendWithSession, setSessionCookies, REMEMBER_COOKIE } from "../../../../../lib/auth-server";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const { response, renewed } = await callBackendWithSession(request, `vouchers/${id}/claim`, {
      method: "POST",
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
