import { NextRequest, NextResponse } from "next/server";
import { callBackendWithSession, setSessionCookies, REMEMBER_COOKIE } from "../../../../lib/auth-server";

export async function GET(request: NextRequest) {
  try {
    const { response, renewed } = await callBackendWithSession(request, "vouchers/my-wallet", {
      method: "GET",
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
