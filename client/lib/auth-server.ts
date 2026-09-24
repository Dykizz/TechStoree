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

export function apiUrl(path: string) {
  const base = (process.env.API_BASE_URL || "http://localhost:5000").replace(/\/$/, "");
  return `${base}/api/Auth/${path}`;
}

export async function backendRequest<T>(path: string, init: RequestInit) {
  const response = await fetch(apiUrl(path), {
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
