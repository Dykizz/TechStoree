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
  const [isSimulating, setIsSimulating] = useState(false);
  const [simError, setSimError] = useState("");
  const [scanPayUrl, setScanPayUrl] = useState<string>("");

  const effectivePaid = isPaid || paymentConfirmed;

  // Lấy URL quét thanh toán cho mã QR (Ưu tiên IP mạng nội bộ để điện thoại quét được cùng Wi-Fi)
  useEffect(() => {
    if (typeof window !== "undefined") {
      const isLocal =
        window.location.hostname === "localhost" ||
        window.location.hostname === "127.0.0.1";
      const host = isLocal ? "192.168.100.226:3000" : window.location.host;
      setScanPayUrl(`http://${host}/api/orders/${order.orderId}/scan-pay`);
    }
  }, [order.orderId]);

  // Tạo ảnh mã QR chứa URL quét thanh toán
  const qrUrl = scanPayUrl
    ? `https://api.qrserver.com/v1/create-qr-code/?size=260x260&margin=8&data=${encodeURIComponent(scanPayUrl)}`
    : null;

  // Tự động lắng nghe tín hiệu quét mã (Auto-polling mỗi 2 giây)
  useEffect(() => {
    if (!isBanking || effectivePaid) return;

    let isMounted = true;
    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/orders/${order.orderId}/check-payment`, {
          cache: "no-store",
        });
        if (!res.ok) return;
        const data = await res.json();
        if (isMounted && data?.isPaid) {
          setPaymentConfirmed(true);
          if (order.userId) {
            publishNotification(order.userId, {
              id: `payment:${order.orderId}`,
              kind: "order",
              title: "Thanh toán thành công",
              message: `Đơn hàng ${order.orderCode} đã quét mã và hoàn tất thanh toán thành công!`,
              href: `/orders?code=${encodeURIComponent(order.orderCode)}`,
            });
          }
        }
      } catch {
        // Polling background error silently ignored
      }
    }, 2000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [isBanking, effectivePaid, order.orderId, order.orderCode, order.userId]);

  const copyToClipboard = (text: string, key: string) => {
    if (typeof navigator !== "undefined" && navigator.clipboard) {
      void navigator.clipboard.writeText(text);
      setCopiedKey(key);
      setTimeout(() => setCopiedKey((prev) => (prev === key ? null : prev)), 2000);
    }
  };

  const handleSimulateScan = async () => {
    if (effectivePaid || isSimulating) return;
    setIsSimulating(true);
    setSimError("");
    try {
      const res = await fetch(`/api/orders/${order.orderId}/scan-pay`, {
        method: "POST",
      });
      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.message || "Không thể mô phỏng quét mã.");
      }
      setPaymentConfirmed(true);
      if (order.userId) {
        publishNotification(order.userId, {
          id: `payment:${order.orderId}`,
          kind: "order",
          title: "Thanh toán thành công",
          message: `Đơn hàng ${order.orderCode} đã được quét mã và ghi nhận thanh toán thành công!`,
          href: `/orders?code=${encodeURIComponent(order.orderCode)}`,
        });
      }
    } catch (err: unknown) {
      setSimError(
        err instanceof Error ? err.message : "Lỗi khi mô phỏng quét mã.",
      );
    } finally {
      setIsSimulating(false);
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
              <div><dt>Thanh toán</dt><dd>{isBanking ? "Chuyển khoản (Quét mã QR tự động)" : "Thanh toán khi nhận hàng (COD)"}</dd></div>
            </dl>
          </div>

          <div className={styles.receiptAmount}>
            <p className={styles.amountLabel}>Tổng tiền đơn hàng</p>
            <p className={styles.amountValue}>{formatPrice(order.totalAmount)}</p>
            <span className={`${styles.paymentStatus} ${effectivePaid ? styles.paidStatus : ""}`}>
              <span aria-hidden="true" />
              {effectivePaid ? "Đã thanh toán (PAID)" : isBanking ? "Chờ quét mã QR" : "Thanh toán khi nhận hàng"}
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
                  ? "Đơn đã được tạo. Vui lòng quét mã QR bên dưới bằng Camera hoặc Zalo để hệ thống tự động nhận diện thanh toán (không cần chuyển tiền thật)."
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
            <p className={styles.eyebrow}>HOÀN TẤT THANH TOÁN TỰ ĐỘNG</p>
            <h2 id="transfer-title">Quét mã QR để nhận diện thanh toán</h2>
            <p>Mở ứng dụng Camera điện thoại hoặc Zalo giơ vào mã QR để hệ thống tự động nhận diện mà không cần chuyển tiền thật.</p>
          </div>
          {qrUrl ? (
            <div className={styles.transferGrid}>
              <div className={styles.qrFrame}>
                <Image src={qrUrl} alt={`Mã QR nhận diện cho đơn ${order.orderCode}`} width={240} height={240} unoptimized />
                <span>Quét bằng Camera điện thoại hoặc Zalo</span>
              </div>
              <dl className={`${styles.detailList} ${styles.transferDetails}`}>
                <div>
                  <dt>Mã đơn hàng</dt>
                  <dd className={styles.transferValue}>
                    <strong>{order.orderCode}</strong>
                    <button
                      type="button"
                      className={styles.copyBtn}
                      onClick={() => copyToClipboard(order.orderCode, "code")}
                    >
                      {copiedKey === "code" ? "✓ Đã chép" : "Sao chép"}
                    </button>
                  </dd>
                </div>
                <div>
                  <dt>Số tiền thanh toán</dt>
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
                  <dt>Hình thức</dt>
                  <dd>Nhận diện tự động qua quét mã QR (Cách 1)</dd>
                </div>
                <div>
                  <dt>Trạng thái</dt>
                  <dd style={{ color: "#d97706", fontWeight: 600 }}>Đang chờ quét...</dd>
                </div>
              </dl>
            </div>
          ) : (
            <p className={styles.transferUnavailable} role="status">
              Đang tạo mã QR nhận diện...
            </p>
          )}

          <div className={styles.autoScanBox}>
            <div className={styles.scannerBadge}>
              <span className={styles.radarPulse} aria-hidden="true" />
              <span>Đang chờ quét mã QR... (Hệ thống tự động nhận diện)</span>
            </div>
            <p className={styles.autoScanHint}>
              Mở <strong>Camera điện thoại</strong> hoặc <strong>Zalo</strong> hướng vào mã QR ở trên để hoàn tất thanh toán tức thì mà <em>không cần chuyển tiền thật</em>. Màn hình máy tính sẽ tự động chuyển sang ĐÃ THANH TOÁN ngay sau khi quét!
            </p>
            <div className={styles.simScanWrapper}>
              <button
                type="button"
                className={styles.simScanBtn}
                onClick={handleSimulateScan}
                disabled={isSimulating}
              >
                {isSimulating ? "Đang xử lý quét..." : "⚡ Thử nghiệm quét mã ngay (Dành cho test trên máy tính)"}
              </button>
              <span className={styles.scanLiveNotice}>Tự động đồng bộ và hiển thị trên màn hình Admin</span>
            </div>
            {simError && (
              <p className={styles.confirmErrorText}>{simError}</p>
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
