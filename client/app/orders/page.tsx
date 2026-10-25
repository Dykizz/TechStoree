"use client";

import Image from "next/image";
import Link from "next/link";
import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useProtectedSession } from "../../lib/use-protected-session";
import { useCart } from "../../lib/context/CartContext";
import { mapOrder, type BackendOrder } from "../../lib/orders-api";
import {
  notifyOrderCancelled,
  notifyPaymentConfirmed,
  publishNotification,
} from "../../lib/customer-notifications";
import {
  fetchProducts,
  fetchProductById,
  formatPrice,
} from "../../lib/products-client";
import type { Order } from "../../lib/types/order";
import OrderReviewActions, { OrderReviewProvider } from "../../components/reviews/OrderReviewActions";
import styles from "./orders.module.css";

const tabs = [
  { key: "", label: "Tất cả" },
  { key: "PENDING", label: "Chờ xác nhận" },
  { key: "CONFIRMED", label: "Đã xác nhận" },
  { key: "SHIPPING", label: "Đang giao" },
  { key: "DELIVERED", label: "Đã giao" },
  { key: "CANCELLED", label: "Đã hủy" },
];

function formatOrderDateTime(dateStr?: string | null): string {
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

function OrdersContent() {
  const query = useSearchParams();
  const session = useProtectedSession();
  const { addItem, busy } = useCart();
  const [orders, setOrders] = useState<Order[]>([]);
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState(query.get("code") || "");
  const [sortBy, setSortBy] = useState("created_desc");
  const [dateMode, setDateMode] = useState("all");
  const [exactDate, setExactDate] = useState("");
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [actionId, setActionId] = useState("");
  const [attempt, setAttempt] = useState(0);

  const isFilterActive =
    sortBy !== "created_desc" ||
    dateMode !== "all" ||
    Boolean(search.trim()) ||
    Boolean(fromDate) ||
    Boolean(toDate) ||
    Boolean(exactDate);

  const handleResetFilters = () => {
    setSortBy("created_desc");
    setDateMode("all");
    setExactDate("");
    setFromDate("");
    setToDate("");
    setSearch("");
    setPage(1);
  };

  useEffect(() => {
    if (session.status !== "ready") return;
    const userId = session.user.userId;
    let active = true;

    async function load() {
      setLoading(true);
      setError("");
      try {
        const params = new URLSearchParams({
          page: String(page),
          pageSize: "10",
        });
        if (status) params.set("status", status);
        if (search.trim()) params.set("search", search.trim());

        // Tiêu chí sắp xếp: giá hoặc thời gian
        if (sortBy === "price_desc") {
          params.set("sortBy", "totalAmount");
          params.set("isAscending", "false");
        } else if (sortBy === "price_asc") {
          params.set("sortBy", "totalAmount");
          params.set("isAscending", "true");
        } else if (sortBy === "created_asc") {
          params.set("sortBy", "createdAt");
          params.set("isAscending", "true");
        } else {
          // created_desc: thời gian gần nhất (mặc định)
          params.set("sortBy", "createdAt");
          params.set("isAscending", "false");
        }

        // Lọc theo mốc thời gian
        const todayStr = new Date().toISOString().split("T")[0];
        if (dateMode === "exact" && exactDate) {
          params.set("fromDate", exactDate);
          params.set("toDate", exactDate);
        } else if (dateMode === "from" && fromDate) {
          params.set("fromDate", fromDate);
          params.set("toDate", todayStr);
        } else if (dateMode === "range") {
          if (fromDate) params.set("fromDate", fromDate);
          if (toDate) params.set("toDate", toDate);
        } else if (dateMode === "today") {
          params.set("fromDate", todayStr);
          params.set("toDate", todayStr);
        } else if (dateMode === "7days") {
          const d7 = new Date();
          d7.setDate(d7.getDate() - 7);
          params.set("fromDate", d7.toISOString().split("T")[0]);
          params.set("toDate", todayStr);
        } else if (dateMode === "30days") {
          const d30 = new Date();
          d30.setDate(d30.getDate() - 30);
          params.set("fromDate", d30.toISOString().split("T")[0]);
          params.set("toDate", todayStr);
        }

        const response = await fetch(`/api/orders?${params}`, {
          cache: "no-store",
        });
        const result = await response.json();
        if (!response.ok || !result.success)
          throw new Error(result.message || "Không thể tải đơn hàng.");

        const details = await Promise.all(
          result.data.items.map(async (order: BackendOrder) => {
            const res = await fetch(`/api/orders/${order.orderId}`, {
              cache: "no-store",
            });
            const body = await res.json();
            if (!res.ok || !body.success)
              throw new Error(body.message || "Không thể tải chi tiết đơn.");
            return mapOrder(body.data);
          }),
        );

        if (active) {
          setOrders(details);
          setTotalPages(Math.max(1, result.data.meta.totalPages));
          details.forEach((order: Order) => {
            notifyPaymentConfirmed(userId, order);
            notifyOrderCancelled(userId, order);
          });
        }
      } catch (e) {
        if (active)
          setError(
            e instanceof Error ? e.message : "Không thể kết nối đến máy chủ.",
          );
      } finally {
        if (active) setLoading(false);
      }
    }

    void load();
    return () => {
      active = false;
    };
  }, [
    session.status,
    session.user,
    page,
    status,
    search,
    sortBy,
    dateMode,
    exactDate,
    fromDate,
    toDate,
    attempt,
  ]);

  async function cancel(order: Order) {
    if (actionId) return;
    const userReason = window.prompt(
      `Nhập lý do hủy đơn ${order.orderCode} (hoặc nhấn OK để dùng lý do mặc định):`,
      "Khách hàng yêu cầu hủy đơn.",
    );
    if (userReason === null) return;
    const reason = userReason.trim() || "Khách hàng yêu cầu hủy đơn.";

    setActionId(order.orderId);
    setError("");
    setNotice("");
    try {
      const response = await fetch(`/api/orders/${order.orderId}/cancel`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ reason }),
      });
      const result = await response.json();
      if (!response.ok || !result.success)
        throw new Error(result.message || "Không thể hủy đơn.");
      setNotice(result.message);
      if (session.status === "ready") {
        publishNotification(session.user.userId, {
          id: `cancel:${order.orderId}`,
          kind: "order",
          title: "Đã hủy đơn hàng",
          message: `Hệ thống đã xác nhận hủy đơn ${order.orderCode}. Lý do: ${reason}`,
          href: `/orders?code=${encodeURIComponent(order.orderCode)}`,
        });
      }
      setAttempt((a) => a + 1);
    } catch (e) {
      setError(
        e instanceof Error ? e.message : "Không thể hủy đơn. Vui lòng thử lại.",
      );
    } finally {
      setActionId("");
    }
  }


  async function reorder(item: Order["items"][number]) {
    if (actionId || busy) return;
    setActionId(String(item.variantId));
    setError("");
    try {
      const list = await fetchProducts({
        search: item.productName,
        pageSize: 100,
      });
      const matched = list.items.find(
        (p) => p.productName === item.productName,
      );
      if (!matched) throw new Error("Sản phẩm không còn trong danh mục.");
      const product = await fetchProductById(matched.productId);
      const variant = product?.variants.find(
        (v) =>
          v.variantId === item.variantId && v.isActive && v.stockQuantity > 0,
      );
      if (!product || !variant)
        throw new Error("Phiên bản đã mua hiện không còn hàng.");
      await addItem(
        {
          productId: product.productId,
          productName: product.productName,
          variantId: variant.variantId,
          variantName: variant.variantName,
          price: variant.promotion?.hasPromotion
            ? variant.promotion.promotionalPrice
            : variant.price,
          imageUrl: variant.imageUrl || product.imageUrl,
          stockQuantity: variant.stockQuantity,
          attributes: variant.attributes,
        },
        1,
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : "Không thể mua lại sản phẩm.");
    } finally {
      setActionId("");
    }
  }

  if (session.status !== "ready")
    return (
      <main className={styles.main}>
        <div className={styles.container} role="status">
          {session.status === "error" ? (
            <>
              <p>{session.message}</p>
              <button onClick={session.retry}>Thử lại</button>
            </>
          ) : (
            "Đang kiểm tra phiên đăng nhập…"
          )}
        </div>
      </main>
    );

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <div className={styles.heading}>
          <h1 className={styles.title}>Đơn hàng của bạn.</h1>
          <p className={styles.subtitle}>
            Theo dõi đơn hàng và xem lại những lựa chọn của bạn.
          </p>
        </div>
        <div className={styles.tabsWrapper}>
          <div className={styles.tabsList} aria-label="Trạng thái đơn hàng">
            {tabs.map((t) => (
              <button
                className={styles.tabBtn}
                aria-pressed={status === t.key}
                key={t.key}
                onClick={() => {
                  setStatus(t.key);
                  setPage(1);
                }}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>
        <div className={styles.filtersContainer}>
          {/* Hàng 1: Ô tìm kiếm nhanh */}
          <div className={styles.searchRow}>
            <div className={styles.searchIconWrap}>
              <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" fill="none" strokeWidth="2">
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
            </div>
            <input
              className={styles.searchInput}
              aria-label="Tìm đơn hàng"
              placeholder="Tìm theo mã đơn (ORD-...), tên người nhận hoặc số điện thoại…"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
            />
            {search && (
              <button
                type="button"
                className={styles.clearSearchBtn}
                onClick={() => {
                  setSearch("");
                  setPage(1);
                }}
                title="Xóa tìm kiếm"
              >
                ✕
              </button>
            )}
          </div>

          {/* Hàng 2: Bộ chọn cách hiển thị / sắp xếp & mốc thời gian */}
          <div className={styles.controlsRow}>
            <div className={styles.controlGroup}>
              <label htmlFor="order-sort-select" className={styles.controlLabel}>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M3 6h18M6 12h12m-9 6h6" />
                </svg>
                <span>Hiển thị theo:</span>
              </label>
              <select
                id="order-sort-select"
                className={styles.controlSelect}
                value={sortBy}
                onChange={(e) => {
                  setSortBy(e.target.value);
                  setPage(1);
                }}
              >
                <option value="created_desc">Thời gian: Gần nhất (Mới nhất)</option>
                <option value="created_asc">Thời gian: Cũ nhất trước</option>
                <option value="price_desc">Giá: Cao nhất đến thấp nhất</option>
                <option value="price_asc">Giá: Thấp nhất đến cao nhất</option>
              </select>
            </div>

            <div className={styles.controlGroup}>
              <label htmlFor="order-date-mode-select" className={styles.controlLabel}>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                  <line x1="16" y1="2" x2="16" y2="6" />
                  <line x1="8" y1="2" x2="8" y2="6" />
                  <line x1="3" y1="10" x2="21" y2="10" />
                </svg>
                <span>Mốc thời gian:</span>
              </label>
              <select
                id="order-date-mode-select"
                className={styles.controlSelect}
                value={dateMode}
                onChange={(e) => {
                  setDateMode(e.target.value);
                  setPage(1);
                }}
              >
                <option value="all">Tất cả thời gian</option>
                <option value="from">Từ mốc ngày... đến nay</option>
                <option value="exact">Tại 1 ngày cụ thể</option>
                <option value="range">Khoảng ngày tùy chọn</option>
                <option value="today">Hôm nay</option>
                <option value="7days">7 ngày qua</option>
                <option value="30days">30 ngày qua</option>
              </select>
            </div>

            {isFilterActive && (
              <button
                type="button"
                className={styles.resetFilterBtn}
                onClick={handleResetFilters}
                title="Khôi phục về mặc định"
              >
                ↺ Đặt lại bộ lọc
              </button>
            )}
          </div>

          {/* Hàng 3: Ô nhập mốc ngày nếu chọn 'exact', 'from' hoặc 'range' */}
          {dateMode === "exact" && (
            <div className={styles.datePickerRow}>
              <label className={styles.datePickerLabel}>
                <span>Chọn ngày cụ thể:</span>
                <input
                  type="date"
                  className={styles.dateInput}
                  value={exactDate}
                  onChange={(e) => {
                    setExactDate(e.target.value);
                    setPage(1);
                  }}
                />
              </label>
              <span className={styles.datePickerHint}>
                (Chỉ hiển thị các đơn phát sinh trong ngày này)
              </span>
            </div>
          )}

          {dateMode === "from" && (
            <div className={styles.datePickerRow}>
              <label className={styles.datePickerLabel}>
                <span>Từ ngày:</span>
                <input
                  type="date"
                  className={styles.dateInput}
                  value={fromDate}
                  onChange={(e) => {
                    setFromDate(e.target.value);
                    setPage(1);
                  }}
                />
              </label>
              <span className={styles.datePickerArrow}>→</span>
              <span className={styles.datePickerToNow}>
                Cho đến hiện tại ({new Date().toLocaleDateString("vi-VN")})
              </span>
            </div>
          )}

          {dateMode === "range" && (
            <div className={styles.datePickerRow}>
              <label className={styles.datePickerLabel}>
                <span>Từ ngày:</span>
                <input
                  type="date"
                  className={styles.dateInput}
                  value={fromDate}
                  onChange={(e) => {
                    setFromDate(e.target.value);
                    setPage(1);
                  }}
                />
              </label>
              <span className={styles.datePickerArrow}>→</span>
              <label className={styles.datePickerLabel}>
                <span>Đến ngày:</span>
                <input
                  type="date"
                  className={styles.dateInput}
                  value={toDate}
                  onChange={(e) => {
                    setToDate(e.target.value);
                    setPage(1);
                  }}
                />
              </label>
            </div>
          )}
        </div>
        {notice && (
          <p role="status" className={styles.integrationNotice}>
            {notice}
          </p>
        )}
        {error && (
          <div role="alert" className={styles.integrationError}>
            <p>{error}</p>
            <button onClick={() => setAttempt((a) => a + 1)}>Thử lại</button>
          </div>
        )}
        {loading ? (
          <div role="status" className={styles.emptyState}>
            Đang tải đơn hàng…
          </div>
        ) : !error && !orders.length ? (
          <div className={styles.emptyState}>
            <h2>Chưa có đơn hàng phù hợp</h2>
            <p>Đơn hàng sẽ xuất hiện ở đây sau khi bạn đặt hàng hoặc khớp bộ lọc.</p>
            <Link href="/products">Khám phá sản phẩm →</Link>
          </div>
        ) : (
          !error && (
            <OrderReviewProvider itemIds={orders.filter((order) => order.status === "DELIVERED").flatMap((order) => order.items.map((item) => item.orderItemId))}>
            <div className={styles.orderList}>
              {orders.map((order) => (
                <article className={styles.orderCard} key={order.orderId}>
                  <div className={styles.orderHeader}>
                    <div>
                      <strong className={styles.orderCode}>
                        {order.orderCode}
                      </strong>
                      <p className={styles.orderDate}>
                        📅 <strong>Đặt lúc:</strong> {formatOrderDateTime(order.createdAt)}
                      </p>
                    </div>
                    <span
                      className={`${styles.statusBadge} ${
                        order.status === "PENDING"
                          ? styles.badgePending
                          : order.status === "SHIPPING"
                            ? styles.badgeShipping
                            : order.status === "DELIVERED"
                              ? styles.badgeDelivering
                              : order.status === "COMPLETED"
                                ? styles.badgeCompleted
                                : order.status === "CANCELLED"
                                  ? styles.badgeCancelled
                                  : ""
                      }`}
                    >
                      {tabs.find((t) => t.key === order.status)?.label ||
                        order.status}
                    </span>
                  </div>
                  {order.status === "CANCELLED" && (
                    <div className={styles.cancellationNotice}>
                      <div className={styles.cancellationHeader}>
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
                        <span className={styles.cancellationDate}>
                          · Đã hủy lúc: <strong>{formatOrderDateTime(order.cancelledAt || order.updatedAt)}</strong>
                        </span>
                      </div>
                      <p className={styles.cancellationReasonText}>
                        <strong>Lý do hủy đơn:</strong>{" "}
                        {order.cancellationReason || "Không có lý do cụ thể."}
                      </p>
                    </div>
                  )}
                  <div className={styles.orderBody}>
                    <div className={styles.itemsList}>
                      {order.items.map((item) => {
                        const isAwaitingPayment =
                          order.paymentMethod !== "COD" &&
                          order.paymentStatus !== "PAID" &&
                          order.status !== "CANCELLED";
                        const itemHref = isAwaitingPayment
                          ? `/checkout?orderId=${order.orderId}`
                          : `/products/${item.productId}`;
                        const itemTitle = isAwaitingPayment
                          ? "Đơn hàng đang chờ thanh toán - Bấm để vào lại trang thanh toán quét mã QR"
                          : item.productName;

                        return (
                          <div
                            className={styles.itemWrapper}
                            key={item.orderItemId}
                          >
                            <div className={styles.itemRow}>
                              <Link
                                href={itemHref}
                                className={styles.itemImageWrap}
                                title={itemTitle}
                              >
                                {item.imageUrl && (
                                  <Image
                                    src={item.imageUrl}
                                    alt={item.productName}
                                    fill
                                    sizes="80px"
                                    className={styles.itemImage}
                                  />
                                )}
                              </Link>
                              <div className={styles.itemInfo}>
                                <strong className={styles.itemName}>
                                  <Link
                                    href={itemHref}
                                    title={itemTitle}
                                    style={{ color: "inherit", textDecoration: "none" }}
                                  >
                                    {item.productName}
                                  </Link>
                                </strong>
                                <p className={styles.itemVariant}>
                                  {item.variantName}
                                </p>
                                <p className={styles.itemPriceQty}>
                                  {formatPrice(item.unitPrice)} · Số lượng{" "}
                                  {item.quantity}
                                </p>
                              </div>
                              <button
                                className={styles.actionBtnReorder}
                                disabled={!!actionId || busy}
                                onClick={() => void reorder(item)}
                              >
                                Mua lại
                              </button>
                            </div>
                            {order.status === "DELIVERED" && <OrderReviewActions orderItemId={item.orderItemId} />}
                          </div>
                        );
                      })}
                    </div>
                    <div className={styles.orderFooter}>
                      <div className={styles.deliveryInfo}>
                        <p className={styles.deliveryTitle}>
                          Thông tin giao hàng
                        </p>
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
                            className={
                              order.paymentStatus === "PAID"
                                ? styles.paidBadge
                                : styles.unpaidBadge
                            }
                          >
                            {order.paymentStatus === "PAID"
                              ? `✓ Đã thanh toán (lúc ${formatOrderDateTime(order.paidAt || order.updatedAt || order.createdAt)})`
                              : `⏳ Chờ chuyển khoản (tạo lúc ${formatOrderDateTime(order.createdAt)})`}
                          </span>
                        </p>
                        <div style={{ display: "flex", gap: "8px", flexWrap: "wrap", marginTop: "6px" }}>
                          {order.paymentMethod !== "COD" &&
                            order.paymentStatus !== "PAID" &&
                            order.status !== "CANCELLED" && (
                              <Link
                                href={`/checkout?orderId=${order.orderId}`}
                                className={styles.actionBtnPay}
                              >
                                Thanh toán
                              </Link>
                            )}
                          {["PENDING", "CONFIRMED"].includes(order.status) && (
                            <button
                              className={styles.actionBtnContact}
                              disabled={!!actionId}
                              onClick={() => void cancel(order)}
                            >
                              {actionId === order.orderId
                                ? "Đang hủy…"
                                : "Hủy đơn"}
                            </button>
                          )}
                        </div>
                      </div>
                      <div className={styles.priceSummary}>
                        <div className={styles.priceRow}>
                          <span>Tiền hàng</span>
                          <span>{formatPrice(order.subtotalAmount)}</span>
                        </div>
                        {order.discountAmount > 0 && (
                          <div className={styles.priceRow}>
                            <span>Voucher {order.voucherCode}</span>
                            <span>−{formatPrice(order.discountAmount)}</span>
                          </div>
                        )}
                        <div className={styles.priceTotalRow}>
                          <span>Tổng tiền</span>
                          <span>{formatPrice(order.totalAmount)}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </article>
              ))}
            </div>
            </OrderReviewProvider>
          )
        )}
        {!loading && !error && totalPages > 1 && (
          <div className={styles.integrationPagination}>
            <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              Trang trước
            </button>
            <span>
              {page} / {totalPages}
            </span>
            <button
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              Trang sau
            </button>
          </div>
        )}
      </div>
    </main>
  );
}

export default function OrdersPage() {
  return (
    <Suspense fallback={<p role="status">Đang tải đơn hàng…</p>}>
      <OrdersContent />
    </Suspense>
  );
}
