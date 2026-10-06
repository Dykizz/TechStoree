"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useCart } from "../../lib/context/CartContext";

import { formatPrice } from "../../lib/products-client";
import styles from "./cart.module.css";

export default function CartPage() {
  const router = useRouter();
  const {
    items,
    totalItems,
    totalPrice,
    appliedVoucher,
    discountAmount,
    finalPrice,
    busy,
    error: cartError,
    updateQuantity,
    removeItem,
    clearCart,
    applyVoucher,
    removeVoucher,
  } = useCart();

  const [voucherCode, setVoucherCode] = useState("");
  const [voucherMsg, setVoucherMsg] = useState<{
    text: string;
    isError: boolean;
  } | null>(null);

  const handleApplyVoucher = async (codeToApply?: string) => {
    const code = (codeToApply || voucherCode).trim();
    if (!code) {
      setVoucherMsg({ text: "Vui lòng nhập mã voucher.", isError: true });
      return;
    }
    const res = await applyVoucher(code);
    setVoucherMsg({ text: res.message, isError: !res.success });
    if (res.success) {
      setVoucherCode("");
    }
  };

  const handleProceedToCheckout = () => {
    router.push("/checkout");
  };

  if (items.length === 0) {
    return (
      <main className={styles.main}>
        <div className={styles.container}>
          <div className={styles.emptyState}>
            <svg
              className={styles.emptyIcon}
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
            >
              <circle cx="8" cy="21" r="1" />
              <circle cx="19" cy="21" r="1" />
              <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12" />
            </svg>
            <h1 className={styles.emptyTitle}>Giỏ hàng của bạn đang trống</h1>
            <p className={styles.emptyText}>
              Chưa có sản phẩm nào trong giỏ hàng. Hãy khám phá danh mục sản
              phẩm công nghệ tinh tuyển của chúng tôi để chọn món đồ yêu thích.
            </p>
            <Link href="/products" className={styles.shopBtn}>
              Khám phá sản phẩm ngay
            </Link>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <div className={styles.heading}>
          <h1 className={styles.title}>Giỏ Hàng Mua Sắm</h1>
          <p className={styles.subtitle}>
            Bạn đang có <strong>{totalItems}</strong> sản phẩm trong giỏ hàng.
          </p>
        </div>

        <div className={styles.layout}>
          <section
            className={styles.cartListSection}
            aria-label="Danh sách sản phẩm"
          >
            <div className={styles.tableHeader}>
              <span>Sản phẩm</span>
              <span>Đơn giá</span>
              <span>Số lượng</span>
              <span>Thành tiền</span>
              <span aria-hidden="true" />
            </div>

            {items.map((item) => (
              <div key={item.cartItemId} className={styles.cartItem}>
                <div className={styles.productCol}>
                  <div className={styles.imageWrap}>
                    {item.imageUrl ? (
                      <Image
                        src={item.imageUrl}
                        alt={item.productName}
                        fill
                        className={styles.thumb}
                        sizes="72px"
                      />
                    ) : (
                      <div className={styles.thumb} />
                    )}
                  </div>
                  <div className={styles.productInfo}>
                    <Link
                      href={`/products/${item.productId}`}
                      className={styles.productName}
                    >
                      {item.productName}
                    </Link>
                    <span className={styles.variantLabel}>
                      {item.variantName ||
                        Object.values(item.attributes).join(" · ")}
                    </span>
                  </div>
                </div>

                <div className={styles.unitPrice}>
                  {formatPrice(item.price)}
                </div>

                <div className={styles.qtyCol}>
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
                    <span className={styles.qtyDisplay}>{item.quantity}</span>
                    <button
                      type="button"
                      className={styles.qtyBtn}
                      disabled={busy || item.quantity >= item.stockQuantity}
                      onClick={() =>
                        updateQuantity(item.cartItemId, item.quantity + 1)
                      }
                      aria-label="Tăng số lượng"
                    >
                      +
                    </button>
                  </div>
                </div>

                <div className={styles.itemTotal}>
                  {formatPrice(item.price * item.quantity)}
                </div>

                <div>
                  <button
                    type="button"
                    className={styles.removeBtn}
                    disabled={busy || !!cartError}
                    onClick={() => removeItem(item.cartItemId)}
                    aria-label={`Xóa ${item.productName}`}
                  >
                    <svg
                      width="18"
                      height="18"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                    >
                      <path d="M3 6h18" />
                      <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" />
                      <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" />
                    </svg>
                  </button>
                </div>
              </div>
            ))}

            <div className={styles.cartActions}>
              <Link href="/products" className={styles.continueLink}>
                &larr; Tiếp tục mua sắm
              </Link>
              <button
                type="button"
                className={styles.clearCartBtn}
                disabled={busy}
                onClick={clearCart}
              >
                Xóa toàn bộ giỏ hàng
              </button>
            </div>
          </section>

          <aside
            className={styles.summarySection}
            aria-label="Tóm tắt đơn hàng"
          >
            <h2 className={styles.summaryTitle}>Tóm Tắt Đơn Hàng</h2>

            <div className={styles.voucherBox}>
              <label htmlFor="voucherInput" className={styles.voucherLabel}>
                MÃ GIẢM GIÁ / VOUCHER
              </label>

              {appliedVoucher ? (
                <div className={styles.appliedVoucherBadge}>
                  <div>
                    <strong>{appliedVoucher.code}</strong>: -
                    {formatPrice(discountAmount)}
                  </div>
                  <button
                    type="button"
                    className={styles.removeVoucherBtn}
                    onClick={removeVoucher}
                  >
                    Hủy mã ✕
                  </button>
                </div>
              ) : (
                <>
                  <div className={styles.voucherInputGroup}>
                    <input
                      id="voucherInput"
                      type="text"
                      className={styles.voucherInput}
                      placeholder="Nhập mã voucher (VD: TECH100)"
                      value={voucherCode}
                      onChange={(e) => {
                        setVoucherCode(e.target.value);
                        setVoucherMsg(null);
                      }}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          e.preventDefault();
                          handleApplyVoucher();
                        }
                      }}
                    />
                    <button
                      type="button"
                      className={styles.voucherApplyBtn}
                      onClick={() => handleApplyVoucher()}
                    >
                      Áp dụng
                    </button>
                  </div>

                  {voucherMsg && (
                    <p
                      className={`${styles.voucherMessage} ${
                        voucherMsg.isError
                          ? styles.voucherMessageError
                          : styles.voucherMessageSuccess
                      }`}
                    >
                      {voucherMsg.text}
                    </p>
                  )}
                </>
              )}
            </div>

            <div className={styles.summaryRows}>
              <div className={styles.summaryRow}>
                <span>Tổng tiền hàng ({totalItems} sản phẩm)</span>
                <span>{formatPrice(totalPrice)}</span>
              </div>
              {discountAmount > 0 && (
                <div className={`${styles.summaryRow} ${styles.discountRow}`}>
                  <span>Giảm giá ({appliedVoucher?.code})</span>
                  <span>-{formatPrice(discountAmount)}</span>
                </div>
              )}
              <div className={styles.summaryRow}>
                <span>Vận chuyển tiêu chuẩn</span>
                <span className={styles.freeShipping}>Chưa tính phí</span>
              </div>
            </div>

            <div className={styles.totalRow}>
              <span className={styles.totalLabel}>Tổng thanh toán</span>
              <span className={styles.totalPrice}>
                {formatPrice(finalPrice)}
              </span>
            </div>

            <button
              type="button"
              className={styles.checkoutBtn}
              disabled={busy}
              onClick={handleProceedToCheckout}
            >
              Tiến hành đặt hàng
            </button>
          </aside>
        </div>
      </div>
    </main>
  );
}
