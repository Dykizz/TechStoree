"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { publishNotification } from "../../lib/customer-notifications";
import { formatPrice } from "../../lib/products-client";
import type { Order } from "../../lib/types/order";
import styles from "./checkout.module.css";

const orderStatuses: Record<Order["status"], string> = {
  PENDING: "Chờ xác nhận",
  CONFIRMED: "Đã xác nhận",
  SHIPPING: "Đang giao hàng",
  DELIVERED: "Đã giao hàng",
  COMPLETED: "Đã hoàn thành",
  CANCELLED: "Đã hủy",
};

export default function OrderConfirmation({
  order,
  customBank,
}: {
  order: Order;
  customBank?: {
    bin: string;
    name: string;
    account: string;
    accountName: string;
  };
}) {
  const heading = useRef<HTMLHeadingElement>(null);
  const receipt = useRef<HTMLElement>(null);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const isBanking = order.paymentMethod === "BANKING";
  const isPaid = order.paymentStatus === "PAID";
  const [paymentConfirmed, setPaymentConfirmed] = useState(isPaid);
  const [isConfirming, setIsConfirming] = useState(false);
  const [confirmError, setConfirmError] = useState("");

  const effectivePaid = isPaid || paymentConfirmed;

  const bankBin = customBank?.bin || process.env.NEXT_PUBLIC_BANK_BIN || "970422";
  const bankName = customBank?.name || process.env.NEXT_PUBLIC_BANK_NAME || "MBBank";
  const bankAccount = customBank?.account || process.env.NEXT_PUBLIC_BANK_ACCOUNT || "0372933562";
  const bankAccountName = customBank?.accountName || process.env.NEXT_PUBLIC_BANK_ACCOUNT_NAME || "NGUYEN HONG SON";
  const bankConfigured = !!(bankBin && bankAccount && bankAccountName);
  const qrUrl = bankConfigured
    ? `https://img.vietqr.io/image/${bankBin}-${bankAccount}-compact2.png?amount=${order.totalAmount}&addInfo=${encodeURIComponent(order.orderCode)}&accountName=${encodeURIComponent(bankAccountName)}`
    : null;

  const copyToClipboard = (text: string, key: string) => {
    if (typeof navigator !== "undefined" && navigator.clipboard) {
      void navigator.clipboard.writeText(text);
      setCopiedKey(key);
      setTimeout(() => setCopiedKey((prev) => (prev === key ? null : prev)), 2000);
    }
  };

  const handleConfirmPayment = async () => {
    if (effectivePaid || isConfirming) return;
    setIsConfirming(true);
    setConfirmError("");
    try {
      const res = await fetch(`/api/orders/${order.orderId}/confirm-payment`, {
        method: "POST",
      });
      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.message || "Không thể cập nhật trạng thái thanh toán.");
      }
      setPaymentConfirmed(true);
      if (order.userId) {
        publishNotification(order.userId, {
          id: `payment:${order.orderId}`,
          kind: "order",
          title: "Thanh toán thành công",
          message: `Đơn hàng ${order.orderCode} đã được ghi nhận thanh toán chuyển khoản thành công.`,
          href: `/orders?code=${encodeURIComponent(order.orderCode)}`,
        });
      }
    } catch (err: unknown) {
      setConfirmError(
        err instanceof Error ? err.message : "Lỗi khi xác nhận thanh toán.",
      );
    } finally {
      setIsConfirming(false);
    }
  };

  useEffect(() => {
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    receipt.current?.scrollIntoView({ behavior: reducedMotion ? "auto" : "smooth", block: "start" });
    heading.current?.focus({ preventScroll: true });
  }, []);

  return (
    <section ref={receipt} className={styles.receipt} aria-labelledby="order-confirmation-title">
      <div className={styles.receiptIntro}>
        <span className={styles.successIcon} aria-hidden="true">
          <svg viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="m9 16 5 5 10-10" />
          </svg>
        </span>
        <p className={styles.eyebrow}>XÁC NHẬN ĐƠN HÀNG</p>
        <h1 ref={heading} id="order-confirmation-title" tabIndex={-1} className={styles.receiptTitle}>
          Cảm ơn bạn đã chọn TechStoree.
        </h1>
        <p className={styles.receiptSubtitle}>
          Đơn hàng đã được tạo thành công. Bạn có thể xem lại thông tin và theo dõi tiến trình bất cứ lúc nào.
        </p>
      </div>

      <div className={styles.receiptCard}>
        <div className={styles.receiptHeader}>
          <div className={styles.receiptCode}>
            <span>Mã đơn hàng</span>
            <strong>{order.orderCode}</strong>
          </div>
          <span className={styles.orderStatus}>{orderStatuses[order.status]}</span>
        </div>

        <div className={styles.receiptColumns}>
          <div className={styles.receiptDelivery}>
            <h2>Thông tin nhận hàng</h2>
            <dl className={styles.detailList}>
              <div><dt>Người nhận</dt><dd>{order.recipientName}</dd></div>
              <div><dt>Số điện thoại</dt><dd>{order.recipientPhone}</dd></div>
              <div><dt>Địa chỉ giao hàng</dt><dd>{order.shippingAddress}</dd></div>
              {order.note && <div><dt>Ghi chú</dt><dd>{order.note}</dd></div>}
              <div><dt>Thanh toán</dt><dd>{isBanking ? "Chuyển khoản ngân hàng" : "Thanh toán khi nhận hàng (COD)"}</dd></div>
            </dl>
          </div>

          <div className={styles.receiptAmount}>
            <p className={styles.amountLabel}>Tổng tiền đơn hàng</p>
            <p className={styles.amountValue}>{formatPrice(order.totalAmount)}</p>
            <span className={`${styles.paymentStatus} ${effectivePaid ? styles.paidStatus : ""}`}>
              <span aria-hidden="true" />
              {effectivePaid ? "Đã thanh toán (PAID)" : isBanking ? "Chờ chuyển khoản" : "Thanh toán khi nhận hàng"}
            </span>
            <dl className={styles.amountBreakdown}>
              <div><dt>Tạm tính</dt><dd>{formatPrice(order.subtotalAmount)}</dd></div>
              {order.discountAmount > 0 && (
                <div><dt>Giảm giá{order.voucherCode ? ` · ${order.voucherCode}` : ""}</dt><dd>−{formatPrice(order.discountAmount)}</dd></div>
              )}
            </dl>
            <p className={styles.paymentExplanation}>
              {effectivePaid
                ? "Hệ thống đã xác nhận thanh toán cho đơn hàng này. Quản trị viên (Admin) và cửa hàng đã nhận được trạng thái ĐÃ THANH TOÁN."
                : isBanking
                  ? "Đơn đã được tạo. Vui lòng quét mã VietQR bên dưới để chuyển khoản, sau đó nhấn nút 'Tôi đã thanh toán' để báo tín hiệu cho hệ thống."
                  : "Đơn hàng chưa thanh toán. Bạn sẽ thanh toán khi nhận hàng."}
            </p>
          </div>
        </div>
      </div>

      {isBanking && effectivePaid && (
        <section className={styles.transferSection} aria-labelledby="transfer-title">
          <div className={styles.paidSuccessCard}>
            <div className={styles.paidSuccessIcon}>✓</div>
            <div>
              <h3 className={styles.paidSuccessTitle}>Đã ghi nhận thanh toán thành công!</h3>
              <p className={styles.paidSuccessDesc}>
                Đơn hàng <strong>{order.orderCode}</strong> đã ở trạng thái <strong>ĐÃ THANH TOÁN (PAID)</strong>. Quản trị viên (Admin) và hệ thống xử lý đơn hàng đã ghi nhận thành công.
              </p>
            </div>
          </div>
        </section>
      )}

      {isBanking && !effectivePaid && (
        <section className={styles.transferSection} aria-labelledby="transfer-title">
          <div className={styles.transferHeading}>
            <p className={styles.eyebrow}>HOÀN TẤT THANH TOÁN</p>
            <h2 id="transfer-title">Thông tin chuyển khoản</h2>
            <p>Quét mã VietQR bằng ứng dụng ngân hàng hoặc sao chép thông tin để chuyển khoản nhanh 24/7.</p>
          </div>
          {qrUrl ? (
            <div className={styles.transferGrid}>
              <div className={styles.qrFrame}>
                <Image src={qrUrl} alt={`VietQR cho đơn ${order.orderCode}`} width={240} height={300} unoptimized />
                <span>Quét bằng ứng dụng ngân hàng</span>
              </div>
              <dl className={`${styles.detailList} ${styles.transferDetails}`}>
                <div>
                  <dt>Ngân hàng</dt>
                  <dd>{bankName} (BIN: {bankBin})</dd>
                </div>
                <div>
                  <dt>Số tài khoản</dt>
                  <dd>
                    <strong>{bankAccount}</strong>
                    <button
                      type="button"
                      className={styles.copyBtn}
                      onClick={() => copyToClipboard(bankAccount, "account")}
                    >
                      {copiedKey === "account" ? "✓ Đã chép" : "Sao chép"}
                    </button>
                  </dd>
                </div>
                <div>
                  <dt>Chủ tài khoản</dt>
                  <dd>{bankAccountName}</dd>
                </div>
                <div>
                  <dt>Số tiền</dt>
                  <dd className={styles.transferValue}>
                    {formatPrice(order.totalAmount)}
                    <button
                      type="button"
                      className={styles.copyBtn}
                      onClick={() => copyToClipboard(String(order.totalAmount), "amount")}
                    >
                      {copiedKey === "amount" ? "✓ Đã chép" : "Sao chép"}
                    </button>
                  </dd>
                </div>
                <div>
                  <dt>Nội dung</dt>
                  <dd className={styles.transferValue}>
                    {order.orderCode}
                    <button
                      type="button"
                      className={styles.copyBtn}
                      onClick={() => copyToClipboard(order.orderCode, "code")}
                    >
                      {copiedKey === "code" ? "✓ Đã chép" : "Sao chép"}
                    </button>
                  </dd>
                </div>
              </dl>
            </div>
          ) : (
            <p className={styles.transferUnavailable} role="status">
              Chưa có đủ thông tin tài khoản nhận tiền để hiển thị QR.
            </p>
          )}

          <div className={styles.confirmPaymentBox}>
            <p className={styles.confirmPaymentHeading}>
              ⚡ Đã quét mã và chuyển tiền thành công?
            </p>
            <p className={styles.confirmPaymentSub}>
              Bấm nút bên dưới để báo tín hiệu đã thanh toán cho hệ thống. Đơn hàng sẽ lập tức chuyển sang trạng thái <strong>Đã thanh toán</strong> và Quản trị viên (Admin) sẽ thấy ngay!
            </p>
            <button
              type="button"
              className={styles.confirmPaymentBtn}
              onClick={handleConfirmPayment}
              disabled={isConfirming}
            >
              {isConfirming ? "Đang xử lý xác nhận..." : "✓ Tôi đã thanh toán (Báo tín hiệu chuyển khoản)"}
            </button>
            {confirmError && (
              <p className={styles.confirmErrorText}>{confirmError}</p>
            )}
          </div>
        </section>
      )}

      <div className={styles.successActions}>
        <Link href={`/orders?code=${encodeURIComponent(order.orderCode)}`} className={styles.trackOrderBtn}>
          Theo dõi đơn hàng <span aria-hidden="true">↗</span>
        </Link>
        <Link href="/products" className={styles.continueShoppingBtn}>Tiếp tục mua sắm</Link>
      </div>
      <p className={styles.receiptFootnote}>Thông tin và trạng thái đơn hàng được cập nhật từ hệ thống.</p>
    </section>
  );
}
