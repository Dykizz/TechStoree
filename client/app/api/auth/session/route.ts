import { NextRequest, NextResponse } from "next/server";
import {
  ACCESS_COOKIE,
  REFRESH_COOKIE,
  REMEMBER_COOKIE,
  backendRequest,
  clearSessionCookies,
  publicUser,
  setSessionCookies,
  type LoginData,
  type SessionUser,
} from "../../../../lib/auth-server";

export async function GET(request: NextRequest) {
  const access = request.cookies.get(ACCESS_COOKIE)?.value;
  const refresh = request.cookies.get(REFRESH_COOKIE)?.value;
  if (!access && !refresh) {
    return NextResponse.json({ message: "Chưa đăng nhập." }, { status: 401 });
  }

  try {
    if (access) {
      const { response, body } = await backendRequest<SessionUser>("me", {
        headers: { Authorization: `Bearer ${access}` },
      });
      if (response.ok && body?.success && body.data) {
        return NextResponse.json(
          { user: publicUser(body.data) },
          { headers: { "Cache-Control": "no-store" } },
        );
      }
      if (response.status !== 401) {
        return NextResponse.json({ message: body?.message || "Không thể kiểm tra phiên." }, { status: response.status });
      }
    }

    if (refresh) {
      const renewed = await backendRequest<LoginData>("refresh-token", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken: refresh }),
      });
      if (renewed.response.ok && renewed.body?.success && renewed.body.data?.token) {
        const result = NextResponse.json(
          { user: publicUser(renewed.body.data.user) },
          { headers: { "Cache-Control": "no-store" } },
        );
        setSessionCookies(result, renewed.body.data, request.cookies.get(REMEMBER_COOKIE)?.value === "1");
        return result;
      }
    }
  } catch {
    return NextResponse.json({ message: "Không thể kết nối đến API." }, { status: 503 });
  }

  const result = NextResponse.json({ message: "Phiên đăng nhập đã hết hạn." }, { status: 401 });
  clearSessionCookies(result);
  return result;
}
