import { NextRequest, NextResponse } from "next/server";
import { backendRequest, sameOrigin, type SessionUser } from "../../../../lib/auth-server";

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: NextRequest) {
  if (!sameOrigin(request)) {
    return NextResponse.json({ message: "Yêu cầu không hợp lệ." }, { status: 403 });
  }

  let input: Record<string, unknown>;
  try {
    const payload: unknown = await request.json();
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) throw new Error();
    input = payload as Record<string, unknown>;
  } catch {
    return NextResponse.json({ message: "Dữ liệu đăng ký không hợp lệ." }, { status: 400 });
  }

  const username = typeof input.username === "string" ? input.username.trim() : "";
  const fullName = typeof input.fullName === "string" ? input.fullName.trim() : "";
  const email = typeof input.email === "string" ? input.email.trim().toLowerCase() : "";
  const password = typeof input.password === "string" ? input.password : "";

  if (username.length < 3 || username.length > 50 || !fullName || fullName.length > 100 ||
      !emailPattern.test(email) || email.length > 254 || password.length < 6 || password.length > 1024) {
    return NextResponse.json({ message: "Vui lòng kiểm tra thông tin đăng ký." }, { status: 400 });
  }

  try {
    const { response, body } = await backendRequest<SessionUser>("register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, fullName, email, password }),
    });
    if (!response.ok || !body?.success) {
      return NextResponse.json(
        { message: body?.message || "Không thể đăng ký. Vui lòng thử lại." },
        { status: response.ok ? 502 : response.status },
      );
    }

    const result = NextResponse.json({ message: body.message || "Đăng ký thành công." }, { status: 201 });
    result.headers.set("Cache-Control", "no-store");
    return result;
  } catch {
    return NextResponse.json(
      { message: "Không thể kết nối đến API. Hãy kiểm tra backend đang chạy." },
      { status: 503 },
    );
  }
}
