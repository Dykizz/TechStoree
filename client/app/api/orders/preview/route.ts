import { NextRequest, NextResponse } from "next/server";
import { callBackendWithSession, setSessionCookies, REMEMBER_COOKIE } from "../../../../lib/auth-server";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { response, renewed } = await callBackendWithSession(request, "Orders/preview", {
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
