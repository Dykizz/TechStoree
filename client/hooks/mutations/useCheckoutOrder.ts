import { useMutation, useQueryClient } from "@tanstack/react-query";
import { orderKeys } from "@/lib/query-keys/order.keys";
import {
  checkoutOrderApi,
  type CheckoutPayload,
  type BackendOrder,
} from "@/lib/orders-api";

export function useCheckoutOrder() {
  const queryClient = useQueryClient();

  return useMutation<BackendOrder, Error, CheckoutPayload>({
    mutationFn: (payload) => checkoutOrderApi(payload),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: orderKeys.all });
    },
  });
}

