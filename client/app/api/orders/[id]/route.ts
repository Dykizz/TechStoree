import { NextRequest, NextResponse } from "next/server";
import {
  callBackendWithSession,
  setSessionCookies,
  REMEMBER_COOKIE,
} from "../../../../lib/auth-server";
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  if (!/^\d+$/.test(id))
    return NextResponse.json(
      { message: "Mã đơn không hợp lệ." },
      { status: 400 },
    );
  try {
    const { response, renewed } = await callBackendWithSession(
      request,
      `Orders/${id}`,
    );
    const result = NextResponse.json(await response.json(), {
      status: response.status,
      headers: { "Cache-Control": "no-store" },
    });
    if (renewed)
      setSessionCookies(
        result,
        renewed,
        request.cookies.get(REMEMBER_COOKIE)?.value === "1",
      );
    return result;
  } catch {
    return NextResponse.json(
      { message: "Không thể tải đơn hàng." },
      { status: 503 },
    );
  }
}
