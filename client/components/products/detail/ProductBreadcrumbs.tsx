"use client";

import Link from "next/link";

interface ProductBreadcrumbsProps {
  categoryId: number;
  categoryName: string;
  productName: string;
}

export default function ProductBreadcrumbs({
  categoryId,
  categoryName,
  productName,
}: ProductBreadcrumbsProps) {
  return (
    <nav className="flex items-center gap-2 text-[0.85rem] text-[#888888] mb-8 [&>a]:text-[#666666] [&>a]:no-underline [&>a]:hover:text-[#111111] [&>a]:transition-colors [&>a]:duration-150 [&>span]:text-[#cccccc]" aria-label="Breadcrumb">
      <Link href="/">Trang chủ</Link>
      <span>/</span>
      <Link href="/products">Sản phẩm</Link>
      <span>/</span>
      <Link href={`/products?category=${categoryId}`}>
        {categoryName}
      </Link>
      <span>/</span>
      <span className="!text-[#111111] font-medium">
        {productName}
      </span>
    </nav>
  );
}

