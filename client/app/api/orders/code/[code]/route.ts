import { NextRequest, NextResponse } from "next/server";
import {
  callBackendWithSession,
  setSessionCookies,
  REMEMBER_COOKIE,
} from "../../../../../lib/auth-server";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ code: string }> },
) {
  try {
    const { code } = await params;
    const { response, renewed } = await callBackendWithSession(
      request,
      `Orders/code/${code}`,
      {
        method: "GET",
      },
    );

    const data = await response
      .json()
      .catch(() => ({
        success: false,
        message:
          response.status === 401
            ? "Vui lòng đăng nhập để tiếp tục."
            : "Máy chủ chưa xử lý được yêu cầu.",
      }));
    const res = NextResponse.json(data, { status: response.status });
    if (renewed) {
      setSessionCookies(
        res,
        renewed,
        request.cookies.get(REMEMBER_COOKIE)?.value === "1",
      );
    }
    return res;
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Backend unreachable";
    return NextResponse.json({ success: false, message: msg }, { status: 503 });
  }
}
