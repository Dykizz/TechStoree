import { useQuery } from "@tanstack/react-query";
import { techInterestKeys } from "@/lib/query-keys/profile.keys";
import { fetchTechInterestsApi } from "@/lib/api/profile-api";

export function useTechInterests() {
  return useQuery({
    queryKey: techInterestKeys.all,
    queryFn: fetchTechInterestsApi,
    staleTime: 30 * 60 * 1000,
    gcTime: 60 * 60 * 1000,
  });
}

