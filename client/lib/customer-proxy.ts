import { NextRequest, NextResponse } from "next/server";
import {
  callBackendWithSession,
  clearSessionCookies,
  REMEMBER_COOKIE,
  setSessionCookies,
} from "./auth-server";

export async function customerProxy(
  request: NextRequest,
  path: string,
  init?: RequestInit,
) {
  try {
    const { response, renewed } = await callBackendWithSession(
      request,
      path,
      init,
    );
    const body = await response.json().catch(() => ({
      success: false,
      message:
        response.status === 401
          ? "Vui lòng đăng nhập để tiếp tục."
          : "Máy chủ chưa xử lý được yêu cầu.",
    }));
    const result = NextResponse.json(body, {
      status: response.status,
      headers: { "Cache-Control": "no-store" },
    });
    if (response.status === 401) clearSessionCookies(result);
    else if (renewed)
      setSessionCookies(
        result,
        renewed,
        request.cookies.get(REMEMBER_COOKIE)?.value === "1",
      );
    return result;
  } catch {
    return NextResponse.json(
      {
        success: false,
        message: "Không thể kết nối đến máy chủ. Vui lòng thử lại.",
      },
      { status: 503 },
    );
  }
}
