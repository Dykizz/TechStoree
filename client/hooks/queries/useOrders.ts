"use client";

import { useQuery } from "@tanstack/react-query";
import { orderKeys } from "@/lib/query-keys/order.keys";
import { mapOrder, type BackendOrder } from "@/lib/orders-api";
import type { Order } from "@/lib/types/order";

export interface OrdersQueryResult {
  orders: Order[];
  totalPages: number;
}

export function useOrders(
  filters: Record<string, string>,
  enabled = true,
  options?: { refetchInterval?: number }
) {
  return useQuery({
    queryKey: orderKeys.list(filters),
    queryFn: async (): Promise<OrdersQueryResult> => {
      const params = new URLSearchParams(filters);
      const response = await fetch(`/api/orders?${params.toString()}`, {
        cache: "no-store",
      });
      const result = await response.json();
      if (!response.ok || !result.success) {
        throw new Error(result.message || "Không thể tải đơn hàng.");
      }

      const details: Order[] = await Promise.all(
        result.data.items.map(async (order: BackendOrder) => {
          const res = await fetch(`/api/orders/${order.orderId}`, {
            cache: "no-store",
          });
          const body = await res.json();
          if (!res.ok || !body.success) {
            throw new Error(body.message || "Không thể tải chi tiết đơn.");
          }
          return mapOrder(body.data);
        })
      );

      return {
        orders: details,
        totalPages: Math.max(1, result.data.meta.totalPages),
      };
    },
    enabled,
    staleTime: 1000 * 60 * 2, // 2 minutes
    refetchInterval: options?.refetchInterval,
  });
}

