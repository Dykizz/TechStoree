"use client";

import { useQuery } from "@tanstack/react-query";
import { fetchProductById } from "@/lib/products-client";
import { productKeys } from "@/lib/query-keys/product.keys";

export function useProductDetail(productId: number) {
  return useQuery({
    queryKey: productKeys.detail(productId),
    queryFn: () => fetchProductById(productId),
    enabled: Number.isSafeInteger(productId) && productId > 0,
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
}

