import { useQuery } from "@tanstack/react-query";
import { authKeys } from "@/lib/query-keys/auth.keys";
import type { SessionUser } from "@/lib/auth-server";

export async function fetchSessionApi(): Promise<SessionUser | null> {
  try {
    const res = await fetch("/api/auth/session", { cache: "no-store" });
    if (!res.ok) return null;
    const data = await res.json();
    return data?.user ?? null;
  } catch {
    return null;
  }
}

export function useSession() {
  return useQuery({
    queryKey: authKeys.session(),
    queryFn: fetchSessionApi,
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    refetchOnWindowFocus: true,
  });
}

