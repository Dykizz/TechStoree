import { NextRequest, NextResponse } from "next/server";
import {
  backendRequest,
  publicUser,
  sameOrigin,
  setSessionCookies,
  type LoginData,
} from "../../../../lib/auth-server";

export async function POST(request: NextRequest) {
  if (!sameOrigin(request)) {
    return NextResponse.json(
      { message: "Yêu cầu không hợp lệ." },
      { status: 403 },
    );
  }

  let input: { email?: unknown; password?: unknown; remember?: unknown };
  try {
    const payload: unknown = await request.json();
    if (!payload || typeof payload !== "object" || Array.isArray(payload))
      throw new Error();
    input = payload;
  } catch {
    return NextResponse.json(
      { message: "Dữ liệu đăng nhập không hợp lệ." },
      { status: 400 },
    );
  }

  const email =
    typeof input.email === "string" ? input.email.trim().toLowerCase() : "";
  const password = typeof input.password === "string" ? input.password : "";
  const remember = input.remember === true;
  if (!email || email.length > 254 || !password || password.length > 1024) {
    return NextResponse.json(
      { message: "Vui lòng kiểm tra email và mật khẩu." },
      { status: 400 },
    );
  }

  try {
    const { response, body } = await backendRequest<LoginData>("login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    if (
      !response.ok ||
      !body?.success ||
      !body.data?.token ||
      !body.data.refreshToken
    ) {
      return NextResponse.json(
        { message: body?.message || "Không thể đăng nhập. Vui lòng thử lại." },
        { status: response.ok ? 502 : response.status },
      );
    }

    const result = NextResponse.json({ user: publicUser(body.data.user) });
    setSessionCookies(result, body.data, remember);
    result.headers.set("Cache-Control", "no-store");
    return result;
  } catch {
    return NextResponse.json(
      { message: "Không thể kết nối đến API. Hãy kiểm tra backend đang chạy." },
      { status: 503 },
    );
  }
}
