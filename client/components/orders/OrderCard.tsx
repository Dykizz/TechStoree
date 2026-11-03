"use client";

import Image from "next/image";
import Link from "next/link";
import { formatPrice } from "@/lib/products-client";
import type { Order, OrderItem } from "@/lib/types/order";
import OrderReviewActions from "@/components/reviews/OrderReviewActions";
import { ORDER_TABS } from "./OrderFilterBar";
import { cn } from "@/lib/utils";

export function formatOrderDateTime(dateStr?: string | null): string {
  if (!dateStr) return "";
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return "";
  const hours = String(d.getHours()).padStart(2, "0");
  const minutes = String(d.getMinutes()).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();
  return `${hours}:${minutes} · ${day}/${month}/${year}`;
}

const getStatusBadgeClass = (status: Order["status"]) => {
  switch (status) {
    case "PENDING":
      return "bg-[#fffbeb] text-[#b45309] border-[#fcd34d]";
    case "SHIPPING":
      return "bg-[#eff6ff] text-[#1d4ed8] border-[#93c5fd]";
    case "DELIVERED":
      return "bg-[#f5f3ff] text-[#6d28d9] border-[#c4b5fd]";
    case "COMPLETED":
      return "bg-[#ecfdf5] text-[#047857] border-[#6ee7b7]";
    case "CANCELLED":
      return "bg-[#fff1f2] text-[#be123c] border-[#fda4af]";
    default:
      return "bg-neutral-100 text-neutral-700 border-neutral-300";
  }
};

interface OrderCardProps {
  order: Order;
  busy: boolean;
  actionId: string;
  onReorder: (item: OrderItem) => void;
  onCancel: (order: Order) => void;
}

export default function OrderCard({
  order,
  busy,
  actionId,
  onReorder,
  onCancel,
}: OrderCardProps) {
  return (
    <article className="bg-white border border-[#ebebeb] rounded-[14px] overflow-hidden shadow-[0_2px_10px_rgba(0,0,0,0.02)] hover:shadow-[0_4px_16px_rgba(0,0,0,0.04)] transition-shadow duration-200">
      <div className="bg-[#fafafa] px-5 sm:px-6 py-4 border-b border-[#eeeeee] flex justify-between items-center flex-wrap gap-3">
        <div>
          <strong className="text-[1.05rem] font-bold text-[#111111] tracking-[0.04em]">{order.orderCode}</strong>
          <p className="text-[0.84rem] text-[#777777] mt-0.5">
            📅 <strong>Đặt lúc:</strong> {formatOrderDateTime(order.createdAt)}
          </p>
        </div>
        <span
          className={cn(
            "text-[0.78rem] font-semibold px-3 py-1 rounded-md tracking-[0.03em] inline-flex items-center gap-1.5 border",
            getStatusBadgeClass(order.status)
          )}
        >
          {ORDER_TABS.find((t) => t.key === order.status)?.label || order.status}
        </span>
      </div>

      {order.status === "CANCELLED" && (
        <div className="mt-4 mx-5 sm:mx-6 p-3 sm:px-4 bg-[#fff1f2] border border-[#fecdd3] rounded-lg flex flex-col gap-1.5">
          <div className="flex items-center gap-2 text-[0.88rem] font-semibold text-[#be123c] [&>svg]:shrink-0 [&>svg]:text-[#e11d48]">
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="15" y1="9" x2="9" y2="15" />
              <line x1="9" y1="9" x2="15" y2="15" />
            </svg>
            <span>Đơn hàng đã bị hủy</span>
            <span className="text-[0.8rem] font-normal text-[#881337] opacity-80">
              · Đã hủy lúc:{" "}
              <strong>
                {formatOrderDateTime(order.cancelledAt || order.updatedAt)}
              </strong>
            </span>
          </div>
          <p className="m-0 text-[0.86rem] text-[#9f1239] leading-[1.45] [&>strong]:font-semibold">
            <strong>Lý do hủy đơn:</strong>{" "}
            {order.cancellationReason || "Không có lý do cụ thể."}
          </p>
        </div>
      )}

      <div className="p-5 sm:p-6">
        <div className="flex flex-col gap-5">
          {order.items.map((item) => {
            const isAwaitingPayment =
              order.paymentMethod !== "COD" &&
              order.paymentStatus !== "PAID" &&
              order.status !== "CANCELLED";
            const itemHref = isAwaitingPayment
              ? `/checkout?orderId=${order.orderId}`
              : item.productId && item.productId > 0
                ? `/products/${item.productId}`
                : `/products?search=${encodeURIComponent(item.productName)}`;
            const itemTitle = isAwaitingPayment
              ? "Đơn hàng đang chờ thanh toán - Bấm để vào lại trang thanh toán quét mã QR"
              : item.productName;

            return (
              <div className="border-b border-[#f0f0f0] pb-[18px] last:border-b-0 last:pb-0" key={item.orderItemId}>
                <div className="flex items-center gap-4">
                  <Link
                    href={itemHref}
                    className="w-16 h-16 rounded-lg bg-[#f7f7f7] border border-[#eeeeee] overflow-hidden relative shrink-0 flex items-center justify-center"
                    title={itemTitle}
                  >
                    {item.imageUrl && (
                      <Image
                        src={item.imageUrl}
                        alt={item.productName}
                        fill
                        sizes="80px"
                        className="w-full h-full object-contain"
                      />
                    )}
                  </Link>
                  <div className="flex-1 min-w-0">
                    <strong className="text-[0.95rem] font-semibold text-[#111111] no-underline leading-[1.4] line-clamp-2 hover:text-brand transition-colors duration-150">
                      <Link
                        href={itemHref}
                        title={itemTitle}
                        style={{ color: "inherit", textDecoration: "none" }}
                      >
                        {item.productName}
                      </Link>
                    </strong>
                    <p className="text-[0.8rem] text-[#6b7280] mt-0.5">{item.variantName}</p>
                    <p className="text-[0.92rem] font-semibold text-[#111111]">
                      {formatPrice(item.unitPrice)} · Số lượng {item.quantity}
                    </p>
                  </div>
                  <button
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-[#111111] border border-[#111111] text-white text-[0.84rem] font-semibold cursor-pointer hover:bg-brand hover:border-brand transition-colors duration-200 shrink-0"
                    disabled={!!actionId || busy}
                    onClick={() => void onReorder(item)}
                  >
                    Mua lại
                  </button>
                </div>
                {order.status === "DELIVERED" && (
                  <div className="mt-2 text-right">
                    <OrderReviewActions orderItemId={String(item.orderItemId)} />
                  </div>
                )}
              </div>
            );
          })}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-[1fr_290px] gap-6 items-start mt-6 pt-5 border-t border-[#eeeeee]">
          <div className="text-[0.88rem] text-[#555555] leading-[1.6]">
            <p className="font-bold text-[#111111] mb-1.5 uppercase text-[0.8rem] tracking-[0.05em]">Thông tin giao hàng</p>
            <p>
              {order.recipientName} · {order.recipientPhone}
            </p>
            <p>{order.shippingAddress}</p>
            <p>
              {order.paymentMethod === "COD"
                ? "Thanh toán khi nhận hàng (COD)"
                : "Chuyển khoản (VietQR)"}{" "}
              ·{" "}
              <span
                className={cn(
                  "font-semibold",
                  order.paymentStatus === "PAID"
                    ? "text-[#16a34a]"
                    : "text-[#d97706]"
                )}
              >
                {order.paymentStatus === "PAID"
                  ? `✓ Đã thanh toán (lúc ${formatOrderDateTime(order.paidAt || order.updatedAt || order.createdAt)})`
                  : `⏳ Chờ chuyển khoản (tạo lúc ${formatOrderDateTime(order.createdAt)})`}
              </span>
            </p>
            <div
              style={{
                display: "flex",
                gap: "8px",
                flexWrap: "wrap",
                marginTop: "6px",
              }}
            >
              {order.paymentMethod !== "COD" &&
                order.paymentStatus !== "PAID" &&
                order.status !== "CANCELLED" && (
                  <Link
                    href={`/checkout?orderId=${order.orderId}`}
                    className="inline-block mt-1 px-3 py-1.5 rounded-md bg-[#bd202d] text-white text-[0.82rem] font-semibold hover:bg-brand-hover no-underline"
                  >
                    Thanh toán chuyển khoản ↗
                  </Link>
                )}
            </div>
          </div>

          <div className="flex flex-col gap-1 text-[0.9rem] text-[#666666] md:text-right">
            <div>
              Tạm tính:{" "}
              <strong className="text-[#111111]">{formatPrice(order.subtotalAmount)}</strong>
            </div>
            {order.discountAmount > 0 && (
              <div className="text-brand">
                Giảm giá: -{formatPrice(order.discountAmount)}
              </div>
            )}
            <div className="text-[1.05rem] font-bold text-[#111111] mt-1 pt-2 border-t border-[#eeeeee]">
              Tổng thanh toán:{" "}
              <span className="text-brand">{formatPrice(order.totalAmount)}</span>
            </div>
            <div className="mt-3 flex justify-start md:justify-end gap-2.5">
              {order.status === "PENDING" && (
                <button
                  className="px-3.5 py-1.5 rounded-lg border border-[#fecdd3] bg-white text-[#e11d48] text-[0.84rem] font-medium hover:bg-[#fff1f2] cursor-pointer transition-colors duration-150"
                  disabled={busy}
                  onClick={() => onCancel(order)}
                >
                  Hủy đơn
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </article>
  );
}
