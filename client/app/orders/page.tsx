"use client";
import Image from "next/image";
import Link from "next/link";
import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useProtectedSession } from "../../lib/use-protected-session";
import { useCart } from "../../lib/context/CartContext";
import { mapOrder, type BackendOrder } from "../../lib/orders-api";
import {
  fetchProducts,
  fetchProductById,
  formatPrice,
} from "../../lib/products-client";
import type { Order } from "../../lib/types/order";
import styles from "./orders.module.css";
const tabs = [
  { key: "", label: "Tất cả" },
  { key: "PENDING", label: "Chờ xác nhận" },
  { key: "CONFIRMED", label: "Đã xác nhận" },
  { key: "SHIPPING", label: "Đang giao" },
  { key: "DELIVERED", label: "Đã giao" },
  { key: "CANCELLED", label: "Đã hủy" },
];
function OrdersContent() {
  const query = useSearchParams();
  const session = useProtectedSession();
  const { addItem, busy } = useCart();
  const [orders, setOrders] = useState<Order[]>([]);
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState(query.get("code") || "");
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [actionId, setActionId] = useState("");
  const [attempt, setAttempt] = useState(0);
  useEffect(() => {
    if (session.status !== "ready") return;
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
  }, [session.status, page, status, search, attempt]);
  async function cancel(order: Order) {
    if (actionId || !confirm(`Hủy đơn ${order.orderCode}?`)) return;
    setActionId(order.orderId);
    setError("");
    setNotice("");
    try {
      const response = await fetch(`/api/orders/${order.orderId}/cancel`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ reason: "Khách hàng yêu cầu hủy đơn." }),
      });
      const result = await response.json();
      if (!response.ok || !result.success)
        throw new Error(result.message || "Không thể hủy đơn.");
      setNotice(result.message);
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
        <div className={styles.searchBox}>
          <input
            className={styles.searchInput}
            aria-label="Tìm đơn hàng"
            placeholder="Tìm theo mã đơn, tên hoặc số điện thoại người nhận…"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
          />
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
            <p>Đơn hàng sẽ xuất hiện ở đây sau khi bạn đặt hàng.</p>
            <Link href="/products">Khám phá sản phẩm →</Link>
          </div>
        ) : (
          !error && (
            <div className={styles.orderList}>
              {orders.map((order) => (
                <article className={styles.orderCard} key={order.orderId}>
                  <div className={styles.orderHeader}>
                    <div>
                      <strong className={styles.orderCode}>
                        {order.orderCode}
                      </strong>
                      <p className={styles.orderDate}>
                        {new Date(order.createdAt).toLocaleString("vi-VN")}
                      </p>
                    </div>
                    <span className={styles.statusBadge}>
                      {tabs.find((t) => t.key === order.status)?.label ||
                        order.status}
                    </span>
                  </div>
                  <div className={styles.orderBody}>
                    <div className={styles.itemsList}>
                      {order.items.map((item) => (
                        <div
                          className={styles.itemWrapper}
                          key={item.orderItemId}
                        >
                          <div className={styles.itemRow}>
                            <div className={styles.itemImageWrap}>
                              {item.imageUrl && (
                                <Image
                                  src={item.imageUrl}
                                  alt={item.productName}
                                  fill
                                  sizes="80px"
                                  className={styles.itemImage}
                                />
                              )}
                            </div>
                            <div className={styles.itemInfo}>
                              <strong className={styles.itemName}>
                                {item.productName}
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
                        </div>
                      ))}
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
                            ? "Thanh toán khi nhận hàng"
                            : "Chuyển khoản"}{" "}
                          ·{" "}
                          {order.paymentStatus === "PAID"
                            ? "Đã thanh toán"
                            : "Chưa thanh toán"}
                        </p>
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
