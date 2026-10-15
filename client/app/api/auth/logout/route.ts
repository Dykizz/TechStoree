import { NextRequest, NextResponse } from "next/server";
import {
  ACCESS_COOKIE,
  REFRESH_COOKIE,
  backendRequest,
  clearSessionCookies,
  sameOrigin,
  type LoginData,
} from "../../../../lib/auth-server";

export async function POST(request: NextRequest) {
  if (!sameOrigin(request)) {
    return NextResponse.json({ message: "Yêu cầu không hợp lệ." }, { status: 403 });
  }

  let access = request.cookies.get(ACCESS_COOKIE)?.value;
  const refresh = request.cookies.get(REFRESH_COOKIE)?.value;
  let revoked = !access && !refresh;

  try {
    if (!access && refresh) {
      const renewed = await backendRequest<LoginData>("refresh-token", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken: refresh }),
      });
      access = renewed.body?.data?.token;
    }
    if (access) {
      const result = await backendRequest<unknown>("logout", {
        method: "POST",
        headers: { Authorization: `Bearer ${access}` },
      });
      revoked = result.response.ok;
      if (result.response.status === 401 && refresh) {
        const renewed = await backendRequest<LoginData>("refresh-token", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refreshToken: refresh }),
        });
        const newAccess = renewed.body?.data?.token;
        if (newAccess) {
          const retry = await backendRequest<unknown>("logout", {
            method: "POST",
            headers: { Authorization: `Bearer ${newAccess}` },
          });
          revoked = retry.response.ok;
        }
      }
    }
  } catch {
    // Clear browser cookies even if backend revocation could not be confirmed.
  }

  const result = NextResponse.json(
    {
      signedOut: true,
      backendRevoked: revoked,
      message: revoked
        ? "Đã đăng xuất."
        : "Đã rời phiên trên trình duyệt; chưa xác nhận được với API.",
    },
    { status: 200 },
  );
  clearSessionCookies(result);
  return result;
}
