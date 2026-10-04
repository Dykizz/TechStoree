import { NextRequest, NextResponse } from "next/server";
import {
  ACCESS_COOKIE,
  REFRESH_COOKIE,
  REMEMBER_COOKIE,
  backendApiRequest,
  backendRequest,
  clearSessionCookies,
  setSessionCookies,
  sameOrigin,
  type LoginData,
  type ProfileData,
} from "../../../../lib/auth-server";

type ProfileUpdate = Pick<ProfileData, "fullName" | "phone" | "dateOfBirth" | "techInterest" | "address">;

function publicProfile(data: ProfileData): ProfileData {
  return {
    userId: data.userId,
    username: data.username,
    fullName: data.fullName,
    email: data.email,
    role: data.role,
    phone: data.phone,
    dateOfBirth: data.dateOfBirth,
    techInterest: data.techInterest,
    address: data.address,
  };
}

function failure(message: string, status: number) {
  return NextResponse.json({ message }, { status, headers: { "Cache-Control": "no-store" } });
}

async function authenticatedProfile(request: NextRequest, update?: ProfileUpdate) {
  const access = request.cookies.get(ACCESS_COOKIE)?.value;
  const refresh = request.cookies.get(REFRESH_COOKIE)?.value;
  if (!access && !refresh) return failure("Chưa đăng nhập.", 401);

  const path = update ? "Users/profile" : "Auth/me";
  const init = (token: string): RequestInit => ({
    method: update ? "PUT" : "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      ...(update ? { "Content-Type": "application/json" } : {}),
    },
    ...(update ? { body: JSON.stringify(update) } : {}),
  });

  try {
    let result = access ? await backendApiRequest<ProfileData>(path, init(access)) : null;
    let renewed: LoginData | null = null;

    if ((!result || result.response.status === 401) && refresh) {
      const renewal = await backendRequest<LoginData>("refresh-token", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken: refresh }),
      });
      if (renewal.response.ok && renewal.body?.success && renewal.body.data?.token && renewal.body.data.refreshToken) {
        renewed = renewal.body.data;
        result = await backendApiRequest<ProfileData>(path, init(renewed.token));
      } else if (renewal.response.status >= 500) {
        return failure("Không thể kiểm tra phiên lúc này. Vui lòng thử lại.", 503);
      } else {
        const expired = failure("Phiên đăng nhập đã hết hạn.", 401);
        clearSessionCookies(expired);
        return expired;
      }
    }

    if (!result || result.response.status === 401) {
      const expired = failure("Phiên đăng nhập đã hết hạn.", 401);
      clearSessionCookies(expired);
      return expired;
    }
    if (!result.response.ok || !result.body?.success || !result.body.data) {
      return failure(result.body?.message || "Không thể tải hồ sơ. Vui lòng thử lại.", result.response.ok ? 502 : result.response.status);
    }

    const response = NextResponse.json(
      { profile: publicProfile(result.body.data), message: result.body.message },
      { headers: { "Cache-Control": "no-store" } },
    );
    if (renewed) {
      setSessionCookies(response, renewed, request.cookies.get(REMEMBER_COOKIE)?.value === "1");
    }
    return response;
  } catch {
    return failure("Không thể kết nối đến API. Hãy kiểm tra backend đang chạy.", 503);
  }
}

export function GET(request: NextRequest) {
  return authenticatedProfile(request);
}

export async function PUT(request: NextRequest) {
  if (!sameOrigin(request)) return failure("Yêu cầu không hợp lệ.", 403);
  if (!request.cookies.get(ACCESS_COOKIE)?.value && !request.cookies.get(REFRESH_COOKIE)?.value) {
    return failure("Chưa đăng nhập.", 401);
  }

  let input: Record<string, unknown>;
  try {
    const payload: unknown = await request.json();
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) throw new Error();
    input = payload as Record<string, unknown>;
  } catch {
    return failure("Dữ liệu hồ sơ không hợp lệ.", 400);
  }

  const fullName = typeof input.fullName === "string" ? input.fullName.trim() : "";
  const optional = (value: unknown) => value == null ? null : typeof value === "string" ? value.trim() || null : undefined;
  const phone = optional(input.phone);
  const techInterest = optional(input.techInterest);
  const address = optional(input.address);
  const dateValue = optional(input.dateOfBirth);
  const validDate = dateValue === null || (typeof dateValue === "string" && /^\d{4}-\d{2}-\d{2}$/.test(dateValue) &&
    !Number.isNaN(Date.parse(`${dateValue}T00:00:00Z`)) && new Date(`${dateValue}T00:00:00Z`).toISOString().slice(0, 10) === dateValue &&
    dateValue <= new Date().toISOString().slice(0, 10));
  if (!fullName || fullName.length > 100 || phone === undefined || (phone?.length ?? 0) > 15 ||
      techInterest === undefined || (techInterest?.length ?? 0) > 100 || address === undefined ||
      (address?.length ?? 0) > 255 || !validDate) {
    return failure("Vui lòng kiểm tra thông tin hồ sơ.", 400);
  }

  return authenticatedProfile(request, {
    fullName,
    phone,
    dateOfBirth: dateValue ? `${dateValue}T00:00:00Z` : null,
    techInterest,
    address,
  });
}
