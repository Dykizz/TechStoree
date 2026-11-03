import { useMutation, useQueryClient } from "@tanstack/react-query";
import { authKeys } from "@/lib/query-keys/auth.keys";
import { profileKeys } from "@/lib/query-keys/profile.keys";
import { orderKeys } from "@/lib/query-keys/order.keys";
import { loginApi, type LoginCredentials } from "@/lib/api/auth-api";
import type { SessionUser } from "@/lib/auth-server";

export function useLogin() {
  const queryClient = useQueryClient();

  return useMutation<{ user: SessionUser; message?: string }, Error, LoginCredentials>({
    mutationFn: (credentials) => loginApi(credentials),
    onSuccess: (data) => {
      queryClient.setQueryData(authKeys.session(), data.user);
      void queryClient.invalidateQueries({ queryKey: authKeys.all });
      void queryClient.invalidateQueries({ queryKey: profileKeys.all });
      void queryClient.invalidateQueries({ queryKey: orderKeys.all });
    },
  });
}

