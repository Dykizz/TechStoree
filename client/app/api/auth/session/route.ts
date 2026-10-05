import { NextRequest, NextResponse } from "next/server";
import {
  callBackendWithSession,
  clearSessionCookies,
  publicUser,
  setSessionCookies,
  REMEMBER_COOKIE,
  type BackendEnvelope,
  type SessionUser,
} from "../../../../lib/auth-server";
export async function GET(request: NextRequest) {
  try {
    const { response, renewed } = await callBackendWithSession(
      request,
      "Auth/me",
    );
    const body = (await response
      .json()
      .catch(() => ({
        success: false,
        message:
          response.status === 401
            ? "Vui lòng đăng nhập để tiếp tục."
            : "Máy chủ chưa xử lý được yêu cầu.",
      }))) as BackendEnvelope<SessionUser>;
    const result = NextResponse.json(
      response.ok && body?.success && body.data
        ? { user: publicUser(body.data) }
        : { message: body?.message || "Chưa đăng nhập." },
      { status: response.status, headers: { "Cache-Control": "no-store" } },
    );
    if (renewed)
      setSessionCookies(
        result,
        renewed,
        request.cookies.get(REMEMBER_COOKIE)?.value === "1",
      );
    else if (response.status === 401) clearSessionCookies(result);
    return result;
  } catch {
    return NextResponse.json(
      { message: "Không thể kết nối đến API." },
      { status: 503, headers: { "Cache-Control": "no-store" } },
    );
  }
}
