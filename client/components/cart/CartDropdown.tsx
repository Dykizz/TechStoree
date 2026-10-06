"use client";

import Link from "next/link";
import Image from "next/image";
import { useState } from "react";
import { useCart, resolveCartItemImage } from "../../lib/context/CartContext";
import { CartItem } from "../../lib/types/cart";
import { formatPrice } from "../../lib/products-client";
import styles from "./CartDropdown.module.css";

interface CartDropdownProps {
  align?: "left" | "right";
  onClose?: () => void;
}

function CartDropdownItem({
  item,
  onRemove,
  onClose,
}: {
  item: CartItem;
  onRemove: () => void;
  onClose?: () => void;
}) {
  const [imgFailed, setImgFailed] = useState(false);
  const resolvedImg = resolveCartItemImage(item.imageUrl);

  return (
    <li className={styles.item}>
      <Link
        href={`/products/${item.productId}`}
        className={styles.imageLink}
        onClick={onClose}
        title={item.productName}
      >
        <div className={styles.imageWrap}>
          {resolvedImg && !imgFailed ? (
            <Image
              width={64}
              height={64}
              unoptimized
              src={resolvedImg}
              alt={item.productName}
              className={styles.thumb}
              onError={() => setImgFailed(true)}
              loading="lazy"
            />
          ) : (
            <div className={styles.thumbPlaceholder}>
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

      <div className={styles.itemDetails}>
        <Link
          href={`/products/${item.productId}`}
          className={styles.itemName}
          onClick={onClose}
          title={item.productName}
        >
          {item.productName}
        </Link>

        {(item.variantName ||
          Object.values(item.attributes || {}).length > 0) && (
          <div className={styles.itemVariant}>
            {item.variantName || Object.values(item.attributes).join(" · ")}
          </div>
        )}

        <div className={styles.itemMeta}>
          <span className={styles.itemPrice}>{formatPrice(item.price)}</span>
          <span className={styles.itemQuantity}>×{item.quantity}</span>
        </div>
      </div>

      <button
        type="button"
        className={styles.removeBtn}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          onRemove();
        }}
        aria-label={`Xóa ${item.productName}`}
        title="Xóa khỏi giỏ hàng"
      >
        <svg
          width="13"
          height="13"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <line x1="18" y1="6" x2="6" y2="18" />
          <line x1="6" y1="6" x2="18" y2="18" />
        </svg>
      </button>
    </li>
  );
}

export default function CartDropdown({
  align = "right",
  onClose,
}: CartDropdownProps) {
  const { items, totalItems, totalPrice, removeItem } = useCart();

  return (
    <div
      className={`${styles.dropdown} ${
        align === "left" ? styles.alignLeft : styles.alignRight
      }`}
      role="dialog"
      aria-label="Xem trước giỏ hàng"
    >
      <div className={styles.header}>
        <div className={styles.headerTitle}>
          <span>Giỏ hàng</span>
          {totalItems > 0 && (
            <span className={styles.countBadge}>{totalItems}</span>
          )}
        </div>
        {totalItems > 0 && (
          <Link href="/cart" className={styles.viewAllLink} onClick={onClose}>
            Xem tất cả →
          </Link>
        )}
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
            <p className={styles.emptyTitle}>Giỏ hàng đang trống</p>
            <p className={styles.emptyDesc}>
              Chưa có sản phẩm nào được chọn. Hãy khám phá sản phẩm công nghệ
              tinh tuyển!
            </p>
            <Link
              href="/products"
              className={styles.shopNowBtn}
              onClick={onClose}
            >
              Khám phá sản phẩm
            </Link>
          </div>
        ) : (
          <ul className={styles.itemList}>
            {items.map((item) => (
              <CartDropdownItem
                key={item.cartItemId}
                item={item}
                onRemove={() => removeItem(item.cartItemId)}
                onClose={onClose}
              />
            ))}
          </ul>
        )}
      </div>

      {items.length > 0 && (
        <div className={styles.footer}>
          <div className={styles.subtotalRow}>
            <span className={styles.subtotalLabel}>Tạm tính:</span>
            <span className={styles.subtotalPrice}>
              {formatPrice(totalPrice)}
            </span>
          </div>

          <div className={styles.actions}>
            <Link href="/cart" className={styles.viewCartBtn} onClick={onClose}>
              Xem giỏ hàng
            </Link>
            <Link
              href="/checkout"
              className={styles.checkoutBtn}
              onClick={onClose}
            >
              <span>Thanh toán</span>
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

          <p className={styles.shippingNote}>
            <span>🚚</span>
            <span>Giá và ưu đãi được kiểm tra lại khi đặt hàng</span>
          </p>
        </div>
      )}
    </div>
  );
}
