import { useQuery } from "@tanstack/react-query";
import { profileKeys } from "@/lib/query-keys/profile.keys";
import { fetchProfileApi } from "@/lib/api/profile-api";
import type { ProfileData } from "@/lib/auth-server";

export function useProfile(enabled = true, initialData?: ProfileData | null) {
  return useQuery({
    queryKey: profileKeys.detail(),
    queryFn: fetchProfileApi,
    enabled,
    staleTime: 5 * 60 * 1000,
    gcTime: 15 * 60 * 1000,
    retry: (failureCount, error) => {
      if (error instanceof Error && error.message === "UNAUTHORIZED") {
        return false;
      }
      return failureCount < 1;
    },
    initialData: initialData ?? undefined,
  });
}

