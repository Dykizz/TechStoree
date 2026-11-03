"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { publishNotification } from "@/lib/customer-notifications";
import { formatPrice } from "@/lib/products-client";
import type { Order } from "@/lib/types/order";
import { cn } from "@/lib/utils";

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

  const effectivePaid = isPaid || paymentConfirmed;

  // Lấy URL quét thanh toán cho mã QR
  const scanPayUrl = useMemo(() => {
    if (typeof window === "undefined") return "";
    const origin = process.env.NEXT_PUBLIC_SITE_URL || window.location.origin;
    return `${origin}/api/orders/${order.orderId}/scan-pay`;
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
    <section ref={receipt} className="max-w-[960px] mx-auto mt-0 sm:mt-2.5 min-w-0 [scroll-margin-top:100px] animate-receiptIn motion-reduce:animate-none" aria-labelledby="order-confirmation-title">
      <div className="max-w-[690px] mb-[25px] sm:mb-[30px]">
        <span className="flex items-center justify-center w-[54px] h-[54px] mb-[22px] border border-[#d6e9dc] rounded-full bg-[#edf7f0] text-[#23834c] animate-iconIn motion-reduce:animate-none" aria-hidden="true">
          <svg className="w-[30px] h-[30px]" viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path className="[stroke-dasharray:30] [stroke-dashoffset:0] animate-drawCheck motion-reduce:animate-none" d="m9 16 5 5 10-10" />
          </svg>
        </span>
        <p className="text-brand text-[10px] font-bold tracking-[.13em] leading-[1.7] uppercase">XÁC NHẬN ĐƠN HÀNG</p>
        <h1 ref={heading} id="order-confirmation-title" tabIndex={-1} className="my-3 mb-3.5 text-[clamp(28px,3.1vw,40px)] font-semibold tracking-[-0.04em] leading-[1.2] [text-wrap:balance] outline-none">
          Cảm ơn bạn đã chọn TechStoree.
        </h1>
        <p className="max-w-[610px] text-muted text-sm leading-[1.8]">
          Đơn hàng đã được tạo thành công. Bạn có thể xem lại thông tin và theo dõi tiến trình bất cứ lúc nào.
        </p>
      </div>

      <div className="min-w-0 overflow-hidden border border-border rounded-2xl sm:rounded-[20px] bg-white shadow-[0_8px_30px_#1d1d1f03]">
        <div className="flex flex-wrap items-center justify-between gap-4 p-5 sm:p-[24px_30px] border-b border-border">
          <div className="grid gap-1.5 min-w-0">
            <span className="text-muted text-[11px]">Mã đơn hàng</span>
            <strong className="text-sm font-semibold tracking-[.03em] leading-[1.6] tabular-nums [overflow-wrap:anywhere]">{order.orderCode}</strong>
          </div>
          <span className="max-w-full px-[11px] py-1.5 border border-border rounded-full text-[#53535a] text-[11px] leading-[1.6]">{orderStatuses[order.status]}</span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-[minmax(0,1.25fr)_minmax(0,1fr)]">
          <div className="min-w-0 p-5 sm:p-[30px] [&>h2]:m-0 [&>h2]:mb-6 [&>h2]:text-ink [&>h2]:text-base [&>h2]:font-semibold [&>h2]:leading-normal">
            <h2>Thông tin nhận hàng</h2>
            <dl className="grid gap-5 sm:gap-[22px] m-0 [&>div]:grid [&>div]:grid-cols-1 [&>div]:sm:grid-cols-[minmax(100px,.7fr)_minmax(0,1fr)] [&>div]:gap-1.5 [&>div]:sm:gap-x-5 [&>div]:sm:gap-y-3 [&>div]:min-w-0 [&_dt]:m-0 [&_dt]:text-muted [&_dt]:text-xs [&_dt]:leading-[1.75] [&_dt]:[overflow-wrap:anywhere] [&_dd]:m-0 [&_dd]:min-w-0 [&_dd]:text-ink [&_dd]:text-[13px] [&_dd]:leading-[1.75] [&_dd]:[overflow-wrap:anywhere]">
              <div><dt>Người nhận</dt><dd>{order.recipientName}</dd></div>
              <div><dt>Số điện thoại</dt><dd>{order.recipientPhone}</dd></div>
              <div><dt>Địa chỉ giao hàng</dt><dd>{order.shippingAddress}</dd></div>
              {order.note && <div><dt>Ghi chú</dt><dd>{order.note}</dd></div>}
              <div><dt>Thanh toán</dt><dd>{isBanking ? "Chuyển khoản (Quét mã QR tự động)" : "Thanh toán khi nhận hàng (COD)"}</dd></div>
            </dl>
          </div>

          <div className="min-w-0 p-5 sm:p-[30px] bg-[#fafafa] border-t md:border-t-0 md:border-l border-border">
            <p className="text-muted text-xs">Tổng tiền đơn hàng</p>
            <p className="my-3 mb-[18px] text-[clamp(26px,3vw,36px)] font-semibold tracking-[-0.04em] leading-[1.3] tabular-nums [overflow-wrap:anywhere]">{formatPrice(order.totalAmount)}</p>
            <span
              className={cn(
                "inline-flex items-start gap-2 max-w-full px-[11px] py-2 border rounded-[9px] text-[11px] leading-[1.6] [&>span]:shrink-0 [&>span]:w-[5px] [&>span]:h-[5px] [&>span]:mt-1.5 [&>span]:rounded-full [&>span]:bg-current",
                effectivePaid
                  ? "border-[#d4e8db] bg-[#eff8f2] text-[#237749]"
                  : "border-[#eadfcf] bg-[#fff9ef] text-[#805a1f]"
              )}
            >
              <span aria-hidden="true" />
              {effectivePaid ? "Đã thanh toán (PAID)" : isBanking ? "Chờ quét mã QR" : "Thanh toán khi nhận hàng"}
            </span>
            <dl className="grid gap-3.5 mt-[26px] pt-[22px] border-t border-border [&>div]:grid [&>div]:grid-cols-2 [&>div]:gap-4 [&>div]:text-xs [&>div]:leading-[1.65] [&_dt]:text-muted [&_dt]:[overflow-wrap:anywhere] [&_dd]:m-0 [&_dd]:text-right [&_dd]:tabular-nums [&_dd]:[overflow-wrap:anywhere]">
              <div><dt>Tạm tính</dt><dd>{formatPrice(order.subtotalAmount)}</dd></div>
              {order.discountAmount > 0 && (
                <div><dt>Giảm giá{order.voucherCode ? ` · ${order.voucherCode}` : ""}</dt><dd>−{formatPrice(order.discountAmount)}</dd></div>
              )}
            </dl>
            <p className="mt-[22px] text-muted text-[11px] leading-[1.8]">
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
        <section className="min-w-0 mt-6 p-5 sm:p-[30px] border border-border rounded-2xl sm:rounded-[20px] bg-white animate-receiptIn [animation-delay:80ms] motion-reduce:animate-none" aria-labelledby="transfer-title">
          <div className="flex items-center gap-4 p-5 sm:p-[20px_24px] bg-[#f0fdf4] border border-[#86efac] rounded-[14px] mb-6">
            <div className="flex items-center justify-center shrink-0 w-11 h-11 rounded-full bg-[#16a34a] text-white text-[22px] font-bold">✓</div>
            <div>
              <h3 className="text-base font-semibold text-[#166534] mb-1">Đã ghi nhận thanh toán thành công!</h3>
              <p className="text-[13px] text-[#15803d] leading-[1.6] m-0">
                Đơn hàng <strong>{order.orderCode}</strong> đã ở trạng thái <strong>ĐÃ THANH TOÁN (PAID)</strong>. Quản trị viên (Admin) và hệ thống xử lý đơn hàng đã ghi nhận thành công.
              </p>
            </div>
          </div>
        </section>
      )}

      {isBanking && !effectivePaid && (
        <section className="min-w-0 mt-6 p-5 sm:p-[30px] border border-border rounded-2xl sm:rounded-[20px] bg-white animate-receiptIn [animation-delay:80ms] motion-reduce:animate-none" aria-labelledby="transfer-title">
          <div className="[&>h2]:my-2 [&>h2]:mb-2 [&>h2]:text-xl [&>h2]:tracking-[-0.025em] [&>h2]:font-semibold [&>p:last-child]:text-muted [&>p:last-child]:text-[13px] [&>p:last-child]:leading-[1.75]">
            <p className="text-brand text-[10px] font-bold tracking-[.13em] leading-[1.7] uppercase">HOÀN TẤT THANH TOÁN TỰ ĐỘNG</p>
            <h2 id="transfer-title">Quét mã QR để nhận diện thanh toán</h2>
            <p>Mở ứng dụng Camera điện thoại hoặc Zalo giơ vào mã QR để hệ thống tự động nhận diện mà không cần chuyển tiền thật.</p>
          </div>
          {qrUrl ? (
            <div className="grid grid-cols-1 sm:grid-cols-[230px_minmax(0,1fr)] gap-[26px] sm:gap-9 items-center mt-[26px]">
              <div className="grid justify-items-center gap-3 p-3.5 border border-border rounded-[14px] bg-white w-full max-w-[250px] sm:max-w-none justify-self-center sm:justify-self-auto [&>img]:block [&>img]:w-full [&>img]:max-w-[210px] [&>img]:h-auto [&>span]:text-muted [&>span]:text-[10px] [&>span]:leading-[1.6] [&>span]:text-center">
                <Image src={qrUrl} alt={`Mã QR nhận diện cho đơn ${order.orderCode}`} width={240} height={240} unoptimized />
                <span>Quét bằng Camera điện thoại hoặc Zalo</span>
              </div>
              <dl className="grid gap-[19px] m-0 [&>div]:grid [&>div]:grid-cols-1 [&>div]:sm:grid-cols-[minmax(100px,.7fr)_minmax(0,1fr)] [&>div]:gap-1.5 [&>div]:sm:gap-x-5 [&>div]:sm:gap-y-3 [&>div]:min-w-0 [&_dt]:m-0 [&_dt]:text-muted [&_dt]:text-xs [&_dt]:leading-[1.75] [&_dt]:[overflow-wrap:anywhere] [&_dd]:m-0 [&_dd]:min-w-0 [&_dd]:text-ink [&_dd]:text-[13px] [&_dd]:leading-[1.75] [&_dd]:[overflow-wrap:anywhere]">
                <div>
                  <dt>Mã đơn hàng</dt>
                  <dd className="text-brand font-semibold">
                    <strong>{order.orderCode}</strong>
                    <button
                      type="button"
                      className="ml-2 px-2 py-[3px] text-[11px] font-medium rounded-md border border-[#d9d9df] bg-[#f8f9fa] text-ink cursor-pointer hover:bg-[#e9ecef] hover:border-[#ced4da] transition-colors duration-150 align-middle"
                      onClick={() => copyToClipboard(order.orderCode, "code")}
                    >
                      {copiedKey === "code" ? "✓ Đã chép" : "Sao chép"}
                    </button>
                  </dd>
                </div>
                <div>
                  <dt>Số tiền thanh toán</dt>
                  <dd className="text-brand font-semibold">
                    {formatPrice(order.totalAmount)}
                    <button
                      type="button"
                      className="ml-2 px-2 py-[3px] text-[11px] font-medium rounded-md border border-[#d9d9df] bg-[#f8f9fa] text-ink cursor-pointer hover:bg-[#e9ecef] hover:border-[#ced4da] transition-colors duration-150 align-middle"
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
            <p className="mt-5 p-4 rounded-[10px] bg-[#fff9ef] text-[#805a1f] text-[13px] leading-[1.75]" role="status">
              Đang tạo mã QR nhận diện...
            </p>
          )}

          <div className="mt-6 p-5 sm:p-[20px_22px] bg-[#f8fafc] border border-[#e2e8f0] rounded-2xl shadow-[0_4px_14px_rgba(0,0,0,0.03)]">
            <div className="inline-flex items-center gap-2.5 px-3.5 py-1.5 bg-[#ecfdf5] border border-[#a7f3d0] rounded-full text-[13px] font-semibold text-[#065f46] mb-2.5">
              <span className="relative w-2.5 h-2.5 bg-[#10b981] rounded-full shrink-0 after:content-[''] after:absolute after:-top-1 after:-left-1 after:-right-1 after:-bottom-1 after:rounded-full after:border-2 after:border-[#10b981] after:animate-radarRipple" aria-hidden="true" />
              <span>Đang chờ quét mã QR... (Hệ thống tự động nhận diện)</span>
            </div>
            <p className="text-[13px] text-[#475569] leading-[1.6] mb-4 [&>strong]:text-[#0f172a]">
              Mở <strong>Camera điện thoại</strong> hoặc <strong>Zalo</strong> hướng vào mã QR ở trên để hoàn tất thanh toán tức thì mà <em>không cần chuyển tiền thật</em>. Màn hình máy tính sẽ tự động chuyển sang ĐÃ THANH TOÁN ngay sau khi quét!
            </p>
            <div className="flex flex-wrap items-center gap-3">
              <button
                type="button"
                className="inline-flex items-center justify-center gap-2 px-[18px] py-2.5 text-[13px] font-semibold bg-[#0f172a] text-[#f8fafc] border border-[#334155] rounded-[10px] cursor-pointer hover:enabled:bg-[#1e293b] hover:enabled:border-[#475569] hover:enabled:-translate-y-px hover:enabled:shadow-[0_4px_12px_rgba(15,23,42,0.2)] shadow-[0_2px_6px_rgba(15,23,42,0.12)] disabled:opacity-60 disabled:cursor-not-allowed transition-all duration-[180ms]"
                onClick={handleSimulateScan}
                disabled={isSimulating}
              >
                {isSimulating ? "Đang xử lý quét..." : "⚡ Thử nghiệm quét mã ngay (Dành cho test trên máy tính)"}
              </button>
              <span className="text-xs text-[#64748b]">Tự động đồng bộ và hiển thị trên màn hình Admin</span>
            </div>
            {simError && (
              <p className="mt-2 text-[#dc2626] text-xs">{simError}</p>
            )}
          </div>
        </section>
      )}

      <div className="flex flex-col sm:flex-row flex-wrap gap-3 mt-7">
        <Link href={`/orders?code=${encodeURIComponent(order.orderCode)}`} className="inline-flex items-center justify-center gap-6 min-h-[48px] px-[21px] py-[13px] border border-transparent rounded-[10px] no-underline text-[13px] font-semibold leading-[1.6] bg-brand text-white hover:bg-brand-hover hover:-translate-y-px transition-all duration-[180ms] w-full sm:w-auto">
          Theo dõi đơn hàng <span aria-hidden="true">↗</span>
        </Link>
        <Link href="/products" className="inline-flex items-center justify-center gap-6 min-h-[48px] px-[21px] py-[13px] border border-[#d9d9df] rounded-[10px] no-underline text-[13px] font-semibold leading-[1.6] bg-white text-ink hover:bg-[#f0f0f3] transition-colors duration-[180ms] w-full sm:w-auto">Tiếp tục mua sắm</Link>
      </div>
      <p className="mt-[18px] text-muted text-[11px] leading-[1.7]">Thông tin và trạng thái đơn hàng được cập nhật từ hệ thống.</p>
    </section>
  );
}
