"use client";

import { useQuery } from "@tanstack/react-query";
import { fetchCategories } from "@/lib/products-client";
import { categoryKeys } from "@/lib/query-keys/product.keys";

export function useCategories() {
  return useQuery({
    queryKey: categoryKeys.all,
    queryFn: fetchCategories,
    staleTime: 1000 * 60 * 10, // 10 minutes
  });
}

