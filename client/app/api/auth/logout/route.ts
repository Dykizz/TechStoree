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
      if (result.response.status === 401 && refresh) {
        const renewed = await backendRequest<LoginData>("refresh-token", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refreshToken: refresh }),
        });
        const newAccess = renewed.body?.data?.token;
        if (newAccess) {
          await backendRequest<unknown>("logout", {
            method: "POST",
            headers: { Authorization: `Bearer ${newAccess}` },
          });
        }
      }
    }
  } catch {
    // Clear browser cookies even if backend revocation could not be confirmed.
  }

  const result = NextResponse.json(
    { message: "Đã đăng xuất." },
    { status: 200 },
  );
  clearSessionCookies(result);
  return result;
}
