import type { ProfileData } from "@/lib/auth-server";
import type { FormValues } from "@/components/profile/ProfileForm";

export type TechInterestOption = {
  key: string;
  displayName: string;
};

export async function fetchProfileApi(): Promise<ProfileData> {
  const response = await fetch("/api/auth/profile", {
    cache: "no-store",
  });
  if (response.status === 401) {
    throw new Error("UNAUTHORIZED");
  }
  const result = (await response.json()) as {
    profile?: ProfileData;
    message?: string;
  };
  if (!response.ok || !result.profile) {
    throw new Error(result.message || "Không thể tải hồ sơ. Vui lòng thử lại.");
  }
  return result.profile;
}

export async function fetchTechInterestsApi(): Promise<TechInterestOption[]> {
  const response = await fetch("/api/tech-interests");
  if (!response.ok) return [];
  const data = await response.json();
  return Array.isArray(data) ? data : [];
}

export async function updateProfileApi(data: FormValues): Promise<ProfileData> {
  const response = await fetch("/api/auth/profile", {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  const result = (await response.json()) as {
    profile?: ProfileData;
    message?: string;
  };
  if (!response.ok || !result.profile) {
    throw new Error(result.message || "Không thể lưu hồ sơ. Vui lòng thử lại.");
  }
  return result.profile;
}

