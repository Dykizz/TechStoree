import type { NextRequest, NextResponse } from "next/server";

export const ACCESS_COOKIE = "techstoree_access";
export const REFRESH_COOKIE = "techstoree_refresh";
export const REMEMBER_COOKIE = "techstoree_remember";

const REFRESH_AGE = 60 * 60 * 24 * 7;
const ACCESS_AGE = 60 * 60;

export type BackendEnvelope<T> = {
  success: boolean;
  message: string;
  data: T | null;
};

export type SessionUser = {
  userId: number;
  username: string;
  fullName: string;
  email: string;
  role: string;
};

export type LoginData = {
  token: string;
  refreshToken: string;
  user: SessionUser;
};

export type ProfileData = SessionUser & {
  phone: string | null;
  dateOfBirth: string | null;
  techInterest: string | null;
  address: string | null;
};

export function apiEndpoint(path: string) {
  const base = (process.env.API_BASE_URL || "http://localhost:5000").replace(
    /\/$/,
    "",
  );
  return `${base}/api/${path}`;
}

export function apiUrl(path: string) {
  return apiEndpoint(`Auth/${path}`);
}

export async function backendApiRequest<T>(path: string, init: RequestInit) {
  const response = await fetch(apiEndpoint(path), {
    ...init,
    cache: "no-store",
    signal: AbortSignal.timeout(8000),
  });
  let body: BackendEnvelope<T> | null = null;
  try {
    body = (await response.json()) as BackendEnvelope<T>;
  } catch {
    // The API may be unavailable or return a non-JSON error page.
  }
  return { response, body };
}

export function backendRequest<T>(path: string, init: RequestInit) {
  return backendApiRequest<T>(`Auth/${path}`, init);
}

export function publicUser(user: SessionUser): SessionUser {
  return {
    userId: user.userId,
    username: user.username,
    fullName: user.fullName,
    email: user.email,
    role: user.role,
  };
}

export function sameOrigin(request: NextRequest) {
  const origin = request.headers.get("origin");
  return !origin || origin === request.nextUrl.origin;
}

export function setSessionCookies(
  response: NextResponse,
  data: LoginData,
  remember: boolean,
) {
  const common = {
    httpOnly: true,
    sameSite: "lax" as const,
    secure: process.env.NODE_ENV === "production",
  };
  response.cookies.set(ACCESS_COOKIE, data.token, {
    ...common,
    path: "/",
    ...(remember ? { maxAge: ACCESS_AGE } : {}),
  });
  response.cookies.set(REFRESH_COOKIE, data.refreshToken, {
    ...common,
    path: "/",
    ...(remember ? { maxAge: REFRESH_AGE } : {}),
  });
  response.cookies.set(REMEMBER_COOKIE, remember ? "1" : "0", {
    ...common,
    path: "/",
    ...(remember ? { maxAge: REFRESH_AGE } : {}),
  });
  clearLegacyCookies(response);
}

export function clearSessionCookies(response: NextResponse) {
  for (const [name, path] of [
    [ACCESS_COOKIE, "/"],
    [REFRESH_COOKIE, "/"],
    [REMEMBER_COOKIE, "/"],
  ]) {
    response.cookies.set(name, "", {
      path,
      maxAge: 0,
      expires: new Date(0),
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
    });
  }
  clearLegacyCookies(response);
}

function clearLegacyCookies(response: NextResponse) {
  for (const name of [REFRESH_COOKIE, REMEMBER_COOKIE]) {
    response.headers.append(
      "Set-Cookie",
      `${name}=; Path=/api/auth; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; SameSite=Lax${process.env.NODE_ENV === "production" ? "; Secure" : ""}`,
    );
  }
}

// Concurrent session/cart/profile requests must not rotate the same token twice.
type RenewalEntry = { expires: number; promise: Promise<LoginData | null> };
const serverState = globalThis as typeof globalThis & {
  techstoreeRenewals?: Map<string, RenewalEntry>;
};
const renewals = (serverState.techstoreeRenewals ??= new Map<
  string,
  RenewalEntry
>());

export async function renewSession(refresh: string): Promise<LoginData | null> {
  const now = Date.now();
  for (const [key, entry] of renewals)
    if (entry.expires <= now) renewals.delete(key);
  const existing = renewals.get(refresh);
  if (existing) return existing.promise;
  const promise = backendRequest<LoginData>("refresh-token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken: refresh }),
  }).then(({ response, body }) => {
    if (response.status >= 500) throw new Error("Session service unavailable");
    return response.ok &&
      body?.success &&
      body.data?.token &&
      body.data.refreshToken
      ? body.data
      : null;
  });
  if (renewals.size >= 256) renewals.delete(renewals.keys().next().value!);
  renewals.set(refresh, { expires: now + 5000, promise });
  try {
    return await promise;
  } catch (error) {
    renewals.delete(refresh);
    throw error;
  }
}

export async function callBackendWithSession(
  request: NextRequest,
  path: string,
  init: RequestInit = {},
): Promise<{ response: Response; renewed: LoginData | null }> {
  if (
    init.method &&
    !["GET", "HEAD"].includes(init.method.toUpperCase()) &&
    !sameOrigin(request)
  ) {
    return {
      response: Response.json(
        { success: false, message: "Yêu cầu không hợp lệ." },
        { status: 403 },
      ),
      renewed: null,
    };
  }
  let access = request.cookies.get(ACCESS_COOKIE)?.value;
  const refresh = request.cookies.get(REFRESH_COOKIE)?.value;
  let renewed: LoginData | null = null;

  const makeHeaders = (token?: string) => {
    const headers = new Headers(init.headers || {});
    if (token) {
      headers.set("Authorization", `Bearer ${token}`);
    }
    return headers;
  };

  let response: Response;
  try {
    response = await fetch(apiEndpoint(path), {
      ...init,
      headers: makeHeaders(access),
      cache: "no-store",
      signal: AbortSignal.timeout(8000),
    });

    if (response.status === 401 && refresh) {
      renewed = await renewSession(refresh);
      if (renewed) {
        access = renewed.token;
        response = await fetch(apiEndpoint(path), {
          ...init,
          headers: makeHeaders(access),
          cache: "no-store",
          signal: AbortSignal.timeout(8000),
        });
      }
    }
  } catch (err) {
    throw err;
  }

  if (
    !response.ok &&
    !(await response
      .clone()
      .json()
      .catch(() => null))
  ) {
    response = Response.json(
      {
        success: false,
        message:
          response.status === 401
            ? "Vui lòng đăng nhập để tiếp tục."
            : "Máy chủ chưa xử lý được yêu cầu.",
      },
      { status: response.status },
    );
  }
  return { response, renewed };
}
