"use client";

import { useQuery } from "@tanstack/react-query";
import { fetchProducts } from "@/lib/products-client";
import { productKeys } from "@/lib/query-keys/product.keys";
import type { ProductQueryFilter } from "@/lib/types/product";

export function useProducts(filter: ProductQueryFilter = {}, enabled = true) {
  return useQuery({
    queryKey: productKeys.list(filter as Record<string, unknown>),
    queryFn: () => fetchProducts(filter),
    enabled,
    staleTime: 1000 * 60 * 3, // 3 minutes
  });
}

