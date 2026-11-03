import { useMutation, useQueryClient } from "@tanstack/react-query";
import { orderKeys } from "@/lib/query-keys/order.keys";
import { cancelOrderApi } from "@/lib/orders-api";

export function useCancelOrder() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, { orderId: string; reason: string }>({
    mutationFn: ({ orderId, reason }) => cancelOrderApi(orderId, reason),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: orderKeys.all });
    },
  });
}

