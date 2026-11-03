import { useMutation, useQueryClient } from "@tanstack/react-query";
import { profileKeys } from "@/lib/query-keys/profile.keys";
import { updateProfileApi } from "@/lib/api/profile-api";
import type { FormValues } from "@/components/profile/ProfileForm";
import type { ProfileData } from "@/lib/auth-server";

export function useUpdateProfile() {
  const queryClient = useQueryClient();

  return useMutation<ProfileData, Error, FormValues>({
    mutationFn: updateProfileApi,
    onSuccess: (updatedProfile) => {
      queryClient.setQueryData(profileKeys.detail(), updatedProfile);
      void queryClient.invalidateQueries({ queryKey: profileKeys.all });
    },
  });
}

