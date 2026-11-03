import type { SessionUser } from "@/lib/auth-server";

export type LoginCredentials = {
  email: string;
  password: string;
  remember?: boolean;
};

export type RegisterCredentials = {
  fullName: string;
  username: string;
  email: string;
  password: string;
};

export async function loginApi(
  credentials: LoginCredentials
): Promise<{ user: SessionUser; message?: string }> {
  const response = await fetch("/api/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(credentials),
  });
  const result = await response.json();
  if (!response.ok || !result.user) {
    throw new Error(result.message || "Không thể đăng nhập. Vui lòng thử lại.");
  }
  return result;
}

export async function registerApi(
  credentials: RegisterCredentials
): Promise<{ message?: string }> {
  const response = await fetch("/api/auth/register", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(credentials),
  });
  const result = await response.json();
  if (!response.ok) {
    throw new Error(result.message || "Không thể đăng ký. Vui lòng thử lại.");
  }
  return result;
}

export async function logoutApi(): Promise<{
  signedOut: boolean;
  message?: string;
}> {
  const response = await fetch("/api/auth/logout", { method: "POST" });
  const result = await response.json();
  if (!response.ok || result.signedOut !== true) {
    throw new Error(result.message || "Không thể đăng xuất. Vui lòng thử lại.");
  }
  return result;
}

