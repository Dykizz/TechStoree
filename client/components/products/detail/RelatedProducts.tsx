"use client";

import Link from "next/link";
import { useMemo } from "react";
import ProductCard from "@/components/products/ProductCard";
import { useProducts } from "@/hooks/queries/useProducts";

interface RelatedProductsProps {
  productId: number;
  categoryId: number;
  categoryName: string;
}

export default function RelatedProducts({
  productId,
  categoryId,
  categoryName,
}: RelatedProductsProps) {
  // Tải các sản phẩm trong cùng danh mục
  const { data: categoryData, isLoading: loadingCategory } = useProducts(
    { categoryId, pageSize: 8 },
    Boolean(categoryId && categoryId > 0)
  );

  // Tải thêm danh sách sản phẩm chung nếu danh mục có ít hơn 4 sản phẩm
  const { data: generalData, isLoading: loadingGeneral } = useProducts(
    { pageSize: 8 },
    true
  );

  // Lọc bỏ sản phẩm hiện tại đang xem
  const sameCategory = useMemo(() => {
    return (categoryData?.items || []).filter(
      (p) => p.productId !== productId && p.isActive
    );
  }, [categoryData?.items, productId]);

  // Tổng hợp tối đa 4 sản phẩm tương tự
  const displayedProducts = useMemo(() => {
    if (sameCategory.length >= 4) {
      return sameCategory.slice(0, 4);
    }

    const currentIds = new Set([
      productId,
      ...sameCategory.map((p) => p.productId),
    ]);

    const fallback = (generalData?.items || []).filter(
      (p) => !currentIds.has(p.productId) && p.isActive
    );

    return [...sameCategory, ...fallback].slice(0, 4);
  }, [sameCategory, generalData?.items, productId]);

  const isLoading = loadingCategory && loadingGeneral && displayedProducts.length === 0;

  if (isLoading) {
    return (
      <section className="mt-16 sm:mt-20 pt-10 border-t border-neutral-200" aria-label="Sản phẩm tương tự">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-8">
          <div>
            <span className="text-xs uppercase tracking-widest text-brand font-bold block mb-1.5">
              GỢI Ý TƯƠNG TỰ
            </span>
            <div className="h-7 w-48 bg-neutral-200 rounded animate-pulse" />
          </div>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className="animate-pulse bg-white border border-neutral-200 rounded-2xl p-5 flex flex-col gap-3 min-h-[320px]"
            >
              <div className="w-full aspect-[4/3] bg-neutral-200 rounded-xl" />
              <div className="h-3 bg-neutral-200 rounded w-1/3 mt-2" />
              <div className="h-5 bg-neutral-200 rounded w-4/5" />
              <div className="h-5 bg-neutral-200 rounded w-1/2 mt-auto" />
            </div>
          ))}
        </div>
      </section>
    );
  }

  if (displayedProducts.length === 0) {
    return null;
  }

  return (
    <section className="mt-16 sm:mt-20 pt-10 border-t border-neutral-200" aria-label="Sản phẩm tương tự">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-8">
        <div>
          <span className="text-xs uppercase tracking-widest text-brand font-bold block mb-1.5">
            GỢI Ý TƯƠNG TỰ
          </span>
          <h2 className="text-2xl sm:text-3xl font-bold text-neutral-900 tracking-tight">
            Sản phẩm tương tự
          </h2>
          <p className="text-sm text-neutral-500 mt-1">
            Khám phá thêm các thiết bị công nghệ cùng danh mục{" "}
            <span className="font-semibold text-neutral-700">
              &ldquo;{categoryName}&rdquo;
            </span>{" "}
            có thể bạn quan tâm
          </p>
        </div>

        <div className="flex items-center gap-2.5 shrink-0 flex-wrap">
          {categoryId > 0 && (
            <Link
              href={`/products?category=${categoryId}`}
              className="inline-flex items-center gap-1.5 text-xs sm:text-sm font-medium text-neutral-700 hover:text-brand transition-colors py-2 px-3.5 rounded-full border border-neutral-300 hover:border-brand/40 bg-white group/cat shadow-xs"
            >
              <span>Xem danh mục &ldquo;{categoryName}&rdquo;</span>
              <span
                className="transition-transform duration-150 group-hover/cat:translate-x-0.5"
                aria-hidden="true"
              >
                &rarr;
              </span>
            </Link>
          )}
          <Link
            href="/products"
            className="inline-flex items-center gap-1.5 text-xs sm:text-sm font-semibold text-white bg-neutral-900 hover:bg-brand transition-colors py-2 px-4 rounded-full border border-neutral-900 hover:border-brand group/all shadow-xs"
          >
            <span>Xem tất cả sản phẩm</span>
            <span
              className="transition-transform duration-150 group-hover/all:translate-x-0.5"
              aria-hidden="true"
            >
              &rarr;
            </span>
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {displayedProducts.map((p) => (
          <ProductCard key={p.productId} product={p} />
        ))}
      </div>
    </section>
  );
}

