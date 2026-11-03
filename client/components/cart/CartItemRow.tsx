"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import type { CartItem } from "@/lib/types/cart";
import { formatPrice } from "@/lib/products-client";
import { resolveCartItemImage } from "@/lib/context/CartContext";

export interface CartItemRowProps {
  item: CartItem;
  onRemove: () => void;
  onUpdateQty: (newQty: number) => void;
  busy: boolean;
  onClose?: () => void;
}

export default function CartItemRow({
  item,
  onRemove,
  onUpdateQty,
  busy,
  onClose,
}: CartItemRowProps) {
  const [imgFailed, setImgFailed] = useState(false);
  const resolvedImg = resolveCartItemImage(item.imageUrl);

  return (
    <li className="flex items-center gap-3 py-3 border-b border-gray-100 last:border-b-0 relative">
      <Link
        href={`/products/${item.productId}`}
        className="shrink-0 no-underline"
        onClick={onClose}
        title={item.productName}
      >
        <div className="w-16 h-16 rounded-lg overflow-hidden bg-gray-50 border border-gray-200 flex items-center justify-center">
          {resolvedImg && !imgFailed ? (
            <Image
              width={64}
              height={64}
              unoptimized
              src={resolvedImg}
              alt={item.productName}
              className="w-full h-full object-contain"
              onError={() => setImgFailed(true)}
              loading="lazy"
            />
          ) : (
            <div className="text-gray-400 flex items-center justify-center">
              <svg
                width="22"
                height="22"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect x="2" y="3" width="20" height="14" rx="2" ry="2" />
                <line x1="8" y1="21" x2="16" y2="21" />
                <line x1="12" y1="17" x2="12" y2="21" />
              </svg>
            </div>
          )}
        </div>
      </Link>

      <div className="flex-1 min-w-0 flex flex-col gap-1">
        <Link
          href={`/products/${item.productId}`}
          className="text-sm font-medium text-gray-900 no-underline truncate block hover:text-blue-600 transition-colors"
          onClick={onClose}
          title={item.productName}
        >
          {item.productName}
        </Link>

        {(item.variantName ||
          Object.values(item.attributes || {}).length > 0) && (
          <div className="text-xs text-gray-500 truncate">
            {item.variantName || Object.values(item.attributes).join(" · ")}
          </div>
        )}

        <div className="flex items-center justify-between gap-2 mt-0.5">
          <span className="text-sm font-semibold text-red-500">{formatPrice(item.price)}</span>
          <div className="inline-flex items-center border border-gray-300 rounded-md overflow-hidden bg-white">
            <button
              type="button"
              className="w-6 h-6 flex items-center justify-center border-none bg-transparent text-gray-700 cursor-pointer text-sm leading-none p-0 select-none transition-colors duration-150 hover:enabled:bg-gray-100 hover:enabled:text-gray-900 disabled:opacity-40 disabled:cursor-not-allowed"
              disabled={busy}
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                onUpdateQty(item.quantity - 1);
              }}
              aria-label="Giảm số lượng"
            >
              -
            </button>
            <span className="px-2 text-xs font-medium text-gray-900 min-w-5 text-center">{item.quantity}</span>
            <button
              type="button"
              className="w-6 h-6 flex items-center justify-center border-none bg-transparent text-gray-700 cursor-pointer text-sm leading-none p-0 select-none transition-colors duration-150 hover:enabled:bg-gray-100 hover:enabled:text-gray-900 disabled:opacity-40 disabled:cursor-not-allowed"
              disabled={busy || item.quantity >= item.stockQuantity}
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                onUpdateQty(item.quantity + 1);
              }}
              aria-label="Tăng số lượng"
            >
              +
            </button>
          </div>
        </div>
      </div>

      <button
        type="button"
        className="bg-transparent border-none text-gray-400 cursor-pointer p-1 rounded flex items-center justify-center transition-all duration-150 ml-1 hover:text-red-500 hover:bg-red-100"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          onRemove();
        }}
        aria-label={`Xóa ${item.productName}`}
        title="Xóa khỏi giỏ hàng"
      >
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <polyline points="3 6 5 6 21 6" />
          <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
        </svg>
      </button>
    </li>
  );
}
