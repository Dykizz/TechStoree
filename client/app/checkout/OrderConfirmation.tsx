"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef } from "react";
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

export default function OrderConfirmation({ order }: { order: Order }) {
  const heading = useRef<HTMLHeadingElement>(null);
  const receipt = useRef<HTMLElement>(null);
  const isBanking = order.paymentMethod === "BANKING";
  const isPaid = order.paymentStatus === "PAID";
  const bankBin = process.env.NEXT_PUBLIC_BANK_BIN;
  const bankAccount = process.env.NEXT_PUBLIC_BANK_ACCOUNT;
  const bankAccountName = process.env.NEXT_PUBLIC_BANK_ACCOUNT_NAME;
  const bankConfigured = !!(bankBin && bankAccount && bankAccountName);
  const qrUrl = bankConfigured
    ? `https://img.vietqr.io/image/${bankBin}-${bankAccount}-compact2.png?amount=${order.totalAmount}&addInfo=${encodeURIComponent(order.orderCode)}&accountName=${encodeURIComponent(bankAccountName)}`
    : null;

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
            <span className={`${styles.paymentStatus} ${isPaid ? styles.paidStatus : ""}`}>
              <span aria-hidden="true" />
              {isPaid ? "Đã thanh toán" : isBanking ? "Chờ xác nhận chuyển khoản" : "Thanh toán khi nhận hàng"}
            </span>
            <dl className={styles.amountBreakdown}>
              <div><dt>Tạm tính</dt><dd>{formatPrice(order.subtotalAmount)}</dd></div>
              {order.discountAmount > 0 && (
                <div><dt>Giảm giá{order.voucherCode ? ` · ${order.voucherCode}` : ""}</dt><dd>−{formatPrice(order.discountAmount)}</dd></div>
              )}
            </dl>
            <p className={styles.paymentExplanation}>
              {isPaid
                ? "Hệ thống đã xác nhận thanh toán cho đơn hàng này."
                : isBanking
                  ? "Đơn đã được tạo, nhưng chưa được xác nhận thanh toán. Hiển thị hoặc quét QR không tự đổi trạng thái này."
                  : "Đơn hàng chưa thanh toán. Bạn sẽ thanh toán khi nhận hàng."}
            </p>
          </div>
        </div>
      </div>

      {isBanking && !isPaid && (
        <section className={styles.transferSection} aria-labelledby="transfer-title">
          <div className={styles.transferHeading}>
            <p className={styles.eyebrow}>HOÀN TẤT THANH TOÁN</p>
            <h2 id="transfer-title">Thông tin chuyển khoản</h2>
            <p>Chuyển đúng số tiền và giữ nguyên mã đơn hàng trong nội dung chuyển khoản.</p>
          </div>
          {qrUrl ? (
            <div className={styles.transferGrid}>
              <div className={styles.qrFrame}>
                <Image src={qrUrl} alt={`VietQR cho đơn ${order.orderCode}`} width={240} height={300} unoptimized />
                <span>Quét bằng ứng dụng ngân hàng</span>
              </div>
              <dl className={`${styles.detailList} ${styles.transferDetails}`}>
                <div><dt>Ngân hàng / mã BIN</dt><dd>{bankBin}</dd></div>
                <div><dt>Số tài khoản</dt><dd>{bankAccount}</dd></div>
                <div><dt>Chủ tài khoản</dt><dd>{bankAccountName}</dd></div>
                <div><dt>Số tiền</dt><dd className={styles.transferValue}>{formatPrice(order.totalAmount)}</dd></div>
                <div><dt>Nội dung</dt><dd className={styles.transferValue}>{order.orderCode}</dd></div>
              </dl>
            </div>
          ) : (
            <p className={styles.transferUnavailable} role="status">
              Chưa có đủ thông tin tài khoản nhận tiền để hiển thị QR. Đơn đã được lưu; vui lòng theo dõi đơn hàng và chờ thông tin thanh toán được cấu hình.
            </p>
          )}
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
