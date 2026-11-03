"use client";

import Link from "next/link";
import { useCart } from "@/lib/context/CartContext";
import { formatPrice } from "@/lib/products-client";
import CartItemRow from "@/components/cart/CartItemRow";
import { cn } from "@/lib/utils";

interface CartDropdownProps {
  align?: "left" | "right";
  onClose?: () => void;
}

export default function CartDropdown({
  align = "right",
  onClose,
}: CartDropdownProps) {
  const { items, totalItems, totalPrice, removeItem, updateQuantity, busy } =
    useCart();

  const recentItems = items.slice(-5).reverse();
  const hasMore = items.length > 5;

  return (
    <div
      className={cn(
        "absolute top-[calc(100%+12px)] w-[380px] bg-white rounded-2xl shadow-[0_16px_40px_-8px_rgba(0,0,0,0.16),0_4px_12px_rgba(0,0,0,0.05)] border border-black/[0.09] z-[1000] flex flex-col text-[#111111] text-left animate-slideDown after:content-[''] after:absolute after:-top-4 after:left-0 after:right-0 after:h-4 after:bg-transparent after:z-[1]",
        align === "left"
          ? "-left-5 before:content-[''] before:absolute before:-top-1.5 before:left-9 before:w-3 before:h-3 before:bg-[#fafafa] before:rotate-45 before:border-t before:border-l before:border-black/[0.09] before:z-[2]"
          : "right-0 before:content-[''] before:absolute before:-top-1.5 before:right-7 before:w-3 before:h-3 before:bg-[#fafafa] before:rotate-45 before:border-t before:border-l before:border-black/[0.09] before:z-[2]"
      )}
      role="dialog"
      aria-label="Xem trước giỏ hàng"
    >
      <div className="p-3.5 px-4.5 bg-[#fafafa] border-b border-gray-100 rounded-t-2xl flex items-center justify-between relative z-[3]">
        <div className="text-[0.9rem] font-semibold text-[#111111] flex items-center gap-2">
          <span>Giỏ hàng nhỏ</span>
          {totalItems > 0 && (
            <span className="bg-brand text-white text-[0.72rem] font-bold px-1.75 rounded-full min-w-[18px] h-[18px] inline-flex items-center justify-center">
              {totalItems}
            </span>
          )}
        </div>
        {totalItems > 0 && (
          <Link
            href="/cart"
            className="text-[0.82rem] text-muted no-underline font-medium transition-colors hover:text-[#111111]"
            onClick={onClose}
          >
            Xem tất cả →
          </Link>
        )}
      </div>

      <div className="max-h-[290px] overflow-y-auto overscroll-contain">
        {items.length === 0 ? (
          <div className="py-[34px] px-5 text-center flex flex-col items-center justify-center gap-3">
            <svg
              className="w-12 h-12 text-[#b0b0b0]"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <circle cx="8" cy="21" r="1" />
              <circle cx="19" cy="21" r="1" />
              <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12" />
            </svg>
            <p className="text-[0.95rem] font-semibold text-[#222222] m-0">
              Giỏ hàng đang trống
            </p>
            <p className="text-[0.82rem] text-muted m-0 max-w-[240px] leading-snug">
              Chưa có sản phẩm nào được chọn. Hãy khám phá sản phẩm công nghệ tinh tuyển!
            </p>
            <Link
              href="/products"
              className="mt-1 text-[0.82rem] font-semibold text-white bg-[#111111] py-2 px-4 rounded-lg no-underline transition-colors hover:bg-brand"
              onClick={onClose}
            >
              Khám phá sản phẩm
            </Link>
          </div>
        ) : (
          <>
            <ul className="list-none m-0 p-0">
              {recentItems.map((item) => (
                <CartItemRow
                  key={item.cartItemId}
                  item={item}
                  onRemove={() => removeItem(item.cartItemId)}
                  onUpdateQty={(newQty) =>
                    updateQuantity(item.cartItemId, newQty)
                  }
                  busy={busy}
                  onClose={onClose}
                />
              ))}
            </ul>
            {hasMore && (
              <div className="py-2 px-4 bg-slate-50 border-t border-dashed border-slate-200 text-slate-500 text-[0.78rem] font-medium text-center">
                + còn {items.length - 5} sản phẩm khác trong giỏ hàng
              </div>
            )}
          </>
        )}
      </div>

      {items.length > 0 && (
        <div className="p-3.5 px-4.5 bg-[#fafafa] border-t border-gray-100 rounded-b-2xl">
          <div className="flex justify-between items-baseline mb-3">
            <span className="text-[0.84rem] text-muted">Tạm tính:</span>
            <span className="text-[1.05rem] font-bold text-[#111111]">
              {formatPrice(totalPrice)}
            </span>
          </div>

          <div className="flex flex-col gap-2">
            <Link
              href="/cart"
              className="w-full py-2.5 px-3.5 rounded-lg border border-black/14 bg-[#111111] text-white text-[0.88rem] font-semibold text-center no-underline flex items-center justify-center gap-2 transition-all duration-200 shadow-[0_2px_8px_rgba(0,0,0,0.1)] hover:bg-brand hover:border-brand hover:-translate-y-px"
              onClick={onClose}
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
                <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
                <path d="M3 6h18" />
                <path d="M16 10a4 4 0 0 1-8 0" />
              </svg>
              <span>Xem tất cả / Đi đến giỏ hàng</span>
            </Link>
            <Link
              href="/checkout"
              className="w-full py-2.25 px-3.5 rounded-lg border border-slate-200 bg-white text-slate-700 text-[0.84rem] font-semibold text-center no-underline flex items-center justify-center gap-1.5 transition-colors cursor-pointer hover:bg-slate-100 hover:text-slate-900 hover:border-slate-300"
              onClick={onClose}
            >
              <span>Thanh toán ngay</span>
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <line x1="5" y1="12" x2="19" y2="12" />
                <polyline points="12 5 19 12 12 19" />
              </svg>
            </Link>
          </div>

          <p className="text-[0.74rem] text-muted text-center mt-2.5 flex items-center justify-center gap-1">
            <span>🚚</span>
            <span>Giá và ưu đãi được kiểm tra lại khi đặt hàng</span>
          </p>
        </div>
      )}
    </div>
  );
}
