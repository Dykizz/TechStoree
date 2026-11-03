import { useMutation } from "@tanstack/react-query";
import { registerApi, type RegisterCredentials } from "@/lib/api/auth-api";

export function useRegister() {
  return useMutation<{ message?: string }, Error, RegisterCredentials>({
    mutationFn: (credentials) => registerApi(credentials),
  });
}

