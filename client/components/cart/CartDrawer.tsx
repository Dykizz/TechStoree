"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef } from "react";
import { useCart } from "@/lib/context/CartContext";
import { formatPrice } from "@/lib/products-client";
import CartItemRow from "@/components/cart/CartItemRow";
import { cn } from "@/lib/utils";

export default function CartDrawer() {
  const drawer = useRef<HTMLElement>(null);
  const router = useRouter();
  const pathname = usePathname();
  const {
    items,
    totalItems,
    totalPrice,
    isCartOpen,
    closeCart,
    updateQuantity,
    removeItem,
    busy,
  } = useCart();

  // Close drawer if user is on /cart or /checkout
  useEffect(() => {
    if (isCartOpen && (pathname === "/cart" || pathname === "/checkout")) {
      closeCart();
    }
  }, [pathname, isCartOpen, closeCart]);

  // Close drawer on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isCartOpen) {
        closeCart();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isCartOpen, closeCart]);

  // Lock background scroll when drawer is open
  useEffect(() => {
    if (isCartOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isCartOpen]);

  useEffect(() => {
    if (!isCartOpen) return;
    const previous = document.activeElement as HTMLElement | null;
    const panel = drawer.current;
    panel?.querySelector<HTMLButtonElement>("button")?.focus();
    function trap(event: KeyboardEvent) {
      if (event.key !== "Tab" || !panel) return;
      const controls = [
        ...panel.querySelectorAll<HTMLElement>(
          "button:not(:disabled), a[href], input:not(:disabled)",
        ),
      ];
      const first = controls[0];
      const last = controls.at(-1);
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last?.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first?.focus();
      }
    }
    panel?.addEventListener("keydown", trap);
    return () => {
      panel?.removeEventListener("keydown", trap);
      previous?.focus();
    };
  }, [isCartOpen]);

  return (
    <>
      <div
        className={cn(
          "fixed inset-0 bg-black/40 backdrop-blur-[4px] z-[200] transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)]",
          isCartOpen ? "opacity-100 visible" : "opacity-0 invisible pointer-events-none"
        )}
        onClick={closeCart}
        aria-hidden="true"
      />

      <aside
        ref={drawer}
        aria-hidden={!isCartOpen}
        inert={!isCartOpen}
        className={cn(
          "fixed top-0 right-0 bottom-0 w-full max-w-[440px] bg-white z-[210] flex flex-col shadow-[-4px_0_24px_rgba(0,0,0,0.12)] transition-transform duration-[350ms] ease-[cubic-bezier(0.16,1,0.3,1)]",
          isCartOpen ? "translate-x-0" : "translate-x-full"
        )}
        role="dialog"
        aria-modal={isCartOpen ? "true" : undefined}
        aria-label="Giỏ hàng mua sắm"
      >
        <div className="px-6 py-5 flex items-center justify-between border-b border-gray-100">
          <h2 className="text-[1.15rem] font-semibold text-ink m-0">
            Giỏ hàng
            <span className="text-sm font-normal text-muted ml-1.5">({totalItems})</span>
          </h2>
          <button
            type="button"
            className="bg-transparent border-none text-xl cursor-pointer text-muted p-1 sm:px-2 rounded flex items-center justify-center hover:bg-gray-100 hover:text-ink transition-colors"
            onClick={closeCart}
            aria-label="Đóng giỏ hàng"
          >
            ✕
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-6 py-5">
          {items.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center text-gray-500 gap-4">
              <svg
                className="w-14 h-14 text-gray-300"
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
              <p>Giỏ hàng của bạn đang trống.</p>
              <Link
                href="/products"
                className="bg-ink text-white no-underline px-6 py-3 rounded-md text-[0.9rem] font-medium transition-colors hover:bg-gray-800 inline-block"
                onClick={closeCart}
              >
                Khám phá sản phẩm
              </Link>
            </div>
          ) : (
            <ul className="list-none p-0 m-0 flex flex-col gap-5">
              {items.map((item) => (
                <CartItemRow
                  key={item.cartItemId}
                  item={item}
                  onRemove={() => removeItem(item.cartItemId)}
                  onUpdateQty={(newQty) =>
                    updateQuantity(item.cartItemId, newQty)
                  }
                  busy={busy}
                  onClose={closeCart}
                />
              ))}
            </ul>
          )}
        </div>

        {items.length > 0 && (
          <div className="px-6 py-5 border-t border-gray-100 bg-[#fafafa]">
            <div className="flex justify-between items-center mb-2 text-[0.95rem] text-gray-600">
              <span>Tạm tính</span>
              <span className="text-[1.15rem] font-bold text-ink">
                {formatPrice(totalPrice)}
              </span>
            </div>
            <p className="text-xs text-gray-400 mb-4">
              Phí vận chuyển và ưu đãi sẽ được áp dụng khi thanh toán.
            </p>

            <div className="flex flex-col gap-2.5">
              <Link
                href="/cart"
                className="text-center bg-transparent border border-ink text-ink p-3 rounded-md no-underline text-[0.9rem] font-semibold transition-all hover:bg-ink hover:text-white"
                onClick={closeCart}
              >
                Xem tất cả / Đi đến giỏ hàng
              </Link>
              <button
                type="button"
                className="text-center bg-brand border border-brand text-white p-3 rounded-md no-underline text-[0.9rem] font-semibold cursor-pointer transition-colors hover:bg-brandHover"
                onClick={() => {
                  closeCart();
                  router.push("/checkout");
                }}
              >
                Tiến hành thanh toán
              </button>
            </div>
          </div>
        )}
      </aside>
    </>
  );
}
