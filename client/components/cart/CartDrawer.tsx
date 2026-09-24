"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { useCart } from "../../lib/context/CartContext";
import { formatPrice } from "../../lib/products-client";
import styles from "./CartDrawer.module.css";

export default function CartDrawer() {
  const router = useRouter();
  const {
    items,
    totalItems,
    totalPrice,
    isCartOpen,
    closeCart,
    updateQuantity,
    removeItem,
  } = useCart();

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

  return (
    <>
      <div
        className={`${styles.backdrop} ${isCartOpen ? styles.backdropOpen : ""}`}
        onClick={closeCart}
        aria-hidden="true"
      />

      <aside
        className={`${styles.drawer} ${isCartOpen ? styles.drawerOpen : ""}`}
        role="dialog"
        aria-modal="true"
        aria-label="Giỏ hàng mua sắm"
      >
        <div className={styles.header}>
          <h2 className={styles.title}>
            Giỏ hàng
            <span className={styles.itemCount}>({totalItems})</span>
          </h2>
          <button
            type="button"
            className={styles.closeButton}
            onClick={closeCart}
            aria-label="Đóng giỏ hàng"
          >
            ✕
          </button>
        </div>

        <div className={styles.body}>
          {items.length === 0 ? (
            <div className={styles.emptyState}>
              <svg
                className={styles.emptyIcon}
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
                className={styles.shopNowBtn}
                onClick={closeCart}
              >
                Khám phá sản phẩm
              </Link>
            </div>
          ) : (
            <ul className={styles.itemList}>
              {items.map((item) => (
                <li key={item.cartItemId} className={styles.item}>
                  <div className={styles.imageWrap}>
                    {item.imageUrl ? (
                      <Image
                        src={item.imageUrl}
                        alt={item.productName}
                        fill
                        className={styles.thumb}
                        sizes="76px"
                      />
                    ) : (
                      <div className={styles.thumb} />
                    )}
                  </div>

                  <div className={styles.itemInfo}>
                    <div className={styles.itemTop}>
                      <h3 className={styles.itemName}>{item.productName}</h3>
                      <button
                        type="button"
                        className={styles.removeBtn}
                        onClick={() => removeItem(item.cartItemId)}
                        aria-label={`Xóa ${item.productName}`}
                      >
                        ✕
                      </button>
                    </div>

                    <div className={styles.itemVariant}>
                      {item.variantName ||
                        Object.values(item.attributes).join(" · ")}
                    </div>

                    <div className={styles.itemBottom}>
                      <span className={styles.price}>
                        {formatPrice(item.price)}
                      </span>

                      <div className={styles.qtyControl}>
                        <button
                          type="button"
                          className={styles.qtyBtn}
                          onClick={() =>
                            updateQuantity(item.cartItemId, item.quantity - 1)
                          }
                          aria-label="Giảm số lượng"
                        >
                          -
                        </button>
                        <span className={styles.qtyValue}>{item.quantity}</span>
                        <button
                          type="button"
                          className={styles.qtyBtn}
                          disabled={item.quantity >= item.stockQuantity}
                          onClick={() =>
                            updateQuantity(item.cartItemId, item.quantity + 1)
                          }
                          aria-label="Tăng số lượng"
                        >
                          +
                        </button>
                      </div>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>

        {items.length > 0 && (
          <div className={styles.footer}>
            <div className={styles.subtotalRow}>
              <span>Tạm tính</span>
              <span className={styles.subtotalPrice}>
                {formatPrice(totalPrice)}
              </span>
            </div>
            <p className={styles.shippingNote}>
              Phí vận chuyển và ưu đãi sẽ được áp dụng khi thanh toán.
            </p>

            <div className={styles.actions}>
              <Link
                href="/cart"
                className={styles.viewCartBtn}
                onClick={closeCart}
              >
                Xem chi tiết giỏ hàng
              </Link>
              <button
                type="button"
                className={styles.checkoutBtn}
                onClick={() => {
                  closeCart();
                  router.push("/cart");
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
