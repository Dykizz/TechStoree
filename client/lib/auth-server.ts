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
  const base = (process.env.API_BASE_URL || "http://localhost:5000").replace(/\/$/, "");
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

export function setSessionCookies(response: NextResponse, data: LoginData, remember: boolean) {
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
    path: "/api/auth",
    ...(remember ? { maxAge: REFRESH_AGE } : {}),
  });
  response.cookies.set(REMEMBER_COOKIE, remember ? "1" : "0", {
    ...common,
    path: "/api/auth",
    ...(remember ? { maxAge: REFRESH_AGE } : {}),
  });
}

export function clearSessionCookies(response: NextResponse) {
  for (const [name, path] of [
    [ACCESS_COOKIE, "/"],
    [REFRESH_COOKIE, "/api/auth"],
    [REMEMBER_COOKIE, "/api/auth"],
  ]) {
    response.cookies.set(name, "", { path, maxAge: 0 });
  }
}

export async function callBackendWithSession(
  request: NextRequest,
  path: string,
  init: RequestInit = {}
): Promise<{ response: Response; renewed: LoginData | null }> {
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
    });

    if (response.status === 401 && refresh) {
      const renewal = await backendRequest<LoginData>("refresh-token", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken: refresh }),
      });

      if (renewal.response.ok && renewal.body?.success && renewal.body.data?.token) {
        renewed = renewal.body.data;
        access = renewed.token;
        response = await fetch(apiEndpoint(path), {
          ...init,
          headers: makeHeaders(access),
          cache: "no-store",
        });
      }
    }
  } catch (err) {
    throw err;
  }

  return { response, renewed };
}

