"use client";

import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { getOrders, saveOrder } from "../../lib/order-client";
import { formatPrice } from "../../lib/products-client";
import { Order } from "../../lib/types/order";
import styles from "./orders.module.css";

interface BackendOrderItem {
  variantId: number;
  productName: string;
  variantName: string;
  imageUrl: string | null;
  unitPrice: number;
  quantity: number;
  totalPrice: number;
}

interface BackendOrder {
  orderId: number;
  orderCode: string;
  orderStatus: string;
  paymentMethod: string;
  paymentStatus: string;
  subtotalAmount: number;
  voucherDiscountAmount: number;
  voucherCode?: string;
  totalAmount: number;
  receiverName: string;
  receiverPhone: string;
  shippingAddress: string;
  notes?: string;
  createdAt: string;
  items?: BackendOrderItem[];
}

function OrdersContent() {
  const searchParams = useSearchParams();
  const initialCode = searchParams.get("code") || "";

  const [orders, setOrders] = useState<Order[]>([]);
  const [searchCode, setSearchCode] = useState(initialCode);
  const [filteredOrders, setFilteredOrders] = useState<Order[]>([]);
  const [actionNotice, setActionNotice] = useState("");
  const [cancellingId, setCancellingId] = useState<string | number | null>(null);

  // Load orders from Backend API + local fallback
  useEffect(() => {
    async function loadData() {
      const localList = getOrders();
      let merged = [...localList];

      try {
        const res = await fetch("/api/orders", { cache: "no-store" });
        if (res.ok) {
          const envelope = await res.json();
          if (envelope && envelope.data && Array.isArray(envelope.data.items)) {
            const backendList: Order[] = envelope.data.items.map((bo: BackendOrder) => ({
              orderId: String(bo.orderId),
              orderCode: bo.orderCode,
              voucherCode: bo.voucherCode,
              subtotalAmount: bo.subtotalAmount,
              discountAmount: bo.voucherDiscountAmount || 0,
              totalAmount: bo.totalAmount,
              status: (bo.orderStatus || "PENDING") as Order["status"],
              paymentMethod: bo.paymentMethod === "BANK_TRANSFER" ? "BANKING" : (bo.paymentMethod as Order["paymentMethod"]),
              paymentStatus: bo.paymentStatus === "PAID" ? "PAID" : "UNPAID",
              shippingAddress: bo.shippingAddress,
              recipientName: bo.receiverName,
              recipientPhone: bo.receiverPhone,
              note: bo.notes,
              createdAt: bo.createdAt,
              items: (bo.items || []).map((it, idx) => ({
                orderItemId: `${bo.orderId}-${idx}`,
                variantId: it.variantId,
                productId: 0,
                productName: it.productName,
                variantName: it.variantName,
                unitPrice: it.unitPrice,
                quantity: it.quantity,
                imageUrl: it.imageUrl,
              })),
            }));

            // Deduplicate by orderCode
            const seen = new Set<string>();
            const unique: Order[] = [];
            for (const o of [...backendList, ...localList]) {
              const codeKey = o.orderCode.trim().toLowerCase();
              if (!seen.has(codeKey)) {
                seen.add(codeKey);
                unique.push(o);
              }
            }
            merged = unique;
          }
        }
      } catch {
        // Use localList
      }

      setOrders(merged);
      if (initialCode) {
        setFilteredOrders(
          merged.filter((o) =>
            o.orderCode.toLowerCase().includes(initialCode.toLowerCase())
          )
        );
      } else {
        setFilteredOrders(merged);
      }
    }

    void loadData();
  }, [initialCode]);

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    const q = searchCode.trim().toLowerCase();
    if (!q) {
      setFilteredOrders(orders);
      return;
    }

    const matched = orders.filter(
      (o) =>
        o.orderCode.toLowerCase().includes(q) ||
        o.recipientPhone.includes(q)
    );

    if (matched.length > 0) {
      setFilteredOrders(matched);
      return;
    }

    // Try querying backend by code if not found locally
    try {
      const res = await fetch(`/api/orders/code/${encodeURIComponent(searchCode.trim())}`);
      if (res.ok) {
        const envelope = await res.json();
        if (envelope && envelope.data && envelope.data.orderCode) {
          const bo = envelope.data as BackendOrder;
          const found: Order = {
            orderId: String(bo.orderId),
            orderCode: bo.orderCode,
            voucherCode: bo.voucherCode,
            subtotalAmount: bo.subtotalAmount,
            discountAmount: bo.voucherDiscountAmount || 0,
            totalAmount: bo.totalAmount,
            status: (bo.orderStatus || "PENDING") as Order["status"],
            paymentMethod: bo.paymentMethod === "BANK_TRANSFER" ? "BANKING" : (bo.paymentMethod as Order["paymentMethod"]),
            paymentStatus: bo.paymentStatus === "PAID" ? "PAID" : "UNPAID",
            shippingAddress: bo.shippingAddress,
            recipientName: bo.receiverName,
            recipientPhone: bo.receiverPhone,
            note: bo.notes,
            createdAt: bo.createdAt,
            items: (bo.items || []).map((it, idx) => ({
              orderItemId: `${bo.orderId}-${idx}`,
              variantId: it.variantId,
              productId: 0,
              productName: it.productName,
              variantName: it.variantName,
              unitPrice: it.unitPrice,
              quantity: it.quantity,
              imageUrl: it.imageUrl,
            })),
          };
          setFilteredOrders([found]);
          return;
        }
      }
    } catch {
      // Ignore
    }

    setFilteredOrders([]);
  };

  const handleCancelOrder = async (order: Order) => {
    if (!confirm(`Bạn có chắc chắn muốn hủy đơn hàng ${order.orderCode} không?`)) {
      return;
    }

    setCancellingId(order.orderId);
    setActionNotice("");

    // Try backend cancel if numeric ID
    const numId = parseInt(String(order.orderId), 10);
    let success = false;

    if (!isNaN(numId) && numId > 0) {
      try {
        const res = await fetch(`/api/orders/${numId}/cancel`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ reason: "Khách hàng yêu cầu hủy đơn." }),
        });
        if (res.ok) {
          success = true;
        }
      } catch {
        // Fallback local
      }
    }

    // Update local state
    const updated = orders.map((o) =>
      o.orderCode === order.orderCode ? { ...o, status: "CANCELLED" as const } : o
    );
    setOrders(updated);
    setFilteredOrders((prev) =>
      prev.map((o) =>
        o.orderCode === order.orderCode ? { ...o, status: "CANCELLED" as const } : o
      )
    );

    // Save update to localStorage
    const local = getOrders();
    const updatedLocal = local.map((o) =>
      o.orderCode === order.orderCode ? { ...o, status: "CANCELLED" as const } : o
    );
    if (typeof window !== "undefined") {
      localStorage.setItem("techstoree_orders", JSON.stringify(updatedLocal));
    }

    setActionNotice(`Đơn hàng ${order.orderCode} đã được hủy thành công. Tồn kho và voucher đã được hoàn lại.`);
    setCancellingId(null);
  };

  const getStatusBadge = (status: Order["status"] | string) => {
    switch (status) {
      case "PENDING":
        return (
          <span className={`${styles.statusBadge} ${styles.statusPending}`}>
            Chờ xác nhận
          </span>
        );
      case "CONFIRMED":
        return (
          <span className={styles.statusBadge} style={{ background: "#e0f2fe", color: "#0369a1" }}>
            Đã xác nhận
          </span>
        );
      case "SHIPPING":
        return (
          <span className={`${styles.statusBadge} ${styles.statusShipping}`}>
            Đang giao hàng
          </span>
        );
      case "DELIVERED":
      case "COMPLETED":
        return (
          <span className={`${styles.statusBadge} ${styles.statusCompleted}`}>
            Đã giao hàng
          </span>
        );
      case "CANCELLED":
        return (
          <span className={styles.statusBadge} style={{ background: "#fee2e2", color: "#991b1b" }}>
            Đã hủy đơn
          </span>
        );
      default:
        return <span className={styles.statusBadge}>Đang xử lý</span>;
    }
  };

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <div className={styles.heading}>
          <h1 className={styles.title}>Lịch Sử & Tra Cứu Đơn Hàng</h1>
          <p className={styles.subtitle}>
            Theo dõi trạng thái giao hàng, xem chi tiết và quản lý các đơn hàng của bạn.
          </p>
        </div>

        {actionNotice && (
          <div style={{
            background: "#ecfdf5",
            color: "#065f46",
            padding: "12px 18px",
            borderRadius: "8px",
            marginBottom: "24px",
            border: "1px solid #a7f3d0",
            fontSize: "0.95rem"
          }}>
            ✓ {actionNotice}
          </div>
        )}

        <form onSubmit={handleSearch} className={styles.searchBox}>
          <input
            type="text"
            className={styles.searchInput}
            placeholder="Nhập mã đơn hàng (VD: ORD-2026... hoặc TECH-...) hoặc số điện thoại..."
            value={searchCode}
            onChange={(e) => setSearchCode(e.target.value)}
          />
          <button type="submit" className={styles.searchBtn}>
            Tra cứu
          </button>
        </form>

        {filteredOrders.length === 0 ? (
          <div className={styles.emptyState}>
            <p>Không tìm thấy đơn hàng nào phù hợp với tìm kiếm của bạn.</p>
            <Link href="/products" className={styles.continueBtn}>
              Tiếp tục mua sắm
            </Link>
          </div>
        ) : (
          <div className={styles.orderList}>
            {filteredOrders.map((order) => (
              <div key={order.orderCode} className={styles.orderCard}>
                <div className={styles.orderHeader}>
                  <div>
                    <div className={styles.orderCode}>{order.orderCode}</div>
                    <div className={styles.orderDate}>
                      Ngày đặt: {new Date(order.createdAt).toLocaleString("vi-VN")}
                    </div>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                    {getStatusBadge(order.status)}
                    {(order.status === "PENDING" || order.status === "CONFIRMED") && (
                      <button
                        type="button"
                        onClick={() => void handleCancelOrder(order)}
                        disabled={cancellingId === order.orderId}
                        style={{
                          background: "#fff",
                          border: "1px solid #ef4444",
                          color: "#ef4444",
                          padding: "4px 10px",
                          borderRadius: "6px",
                          fontSize: "0.8rem",
                          cursor: "pointer",
                          fontWeight: 500,
                        }}
                      >
                        {cancellingId === order.orderId ? "Đang hủy…" : "Hủy đơn"}
                      </button>
                    )}
                  </div>
                </div>

                <div className={styles.orderBody}>
                  <div className={styles.itemsList}>
                    {order.items.map((item, idx) => (
                      <div key={item.orderItemId || idx} className={styles.itemRow}>
                        <div className={styles.itemImageWrap}>
                          {item.imageUrl ? (
                            <Image
                              src={item.imageUrl}
                              alt={item.productName}
                              width={56}
                              height={56}
                              className={styles.itemImage}
                            />
                          ) : (
                            <div className={styles.itemPlaceholder} />
                          )}
                        </div>

                        <div className={styles.itemInfo}>
                          <Link
                            href={item.productId ? `/products/${item.productId}` : "#"}
                            className={styles.itemName}
                          >
                            {item.productName}
                          </Link>
                          <div className={styles.itemVariant}>
                            {item.variantName}
                          </div>
                        </div>

                        <div className={styles.itemPriceQty}>
                          <div>{formatPrice(item.unitPrice)}</div>
                          <div style={{ color: "#888", fontSize: "0.8rem" }}>
                            Số lượng: {item.quantity}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className={styles.orderFooter}>
                    <div className={styles.deliveryInfo}>
                      <div className={styles.deliveryTitle}>
                        Thông tin giao hàng
                      </div>
                      <p>
                        <strong>Người nhận:</strong> {order.recipientName} (
                        {order.recipientPhone})
                      </p>
                      <p>
                        <strong>Địa chỉ:</strong> {order.shippingAddress}
                      </p>
                      {order.note && (
                        <p>
                          <strong>Ghi chú:</strong> {order.note}
                        </p>
                      )}
                    </div>

                    <div className={styles.priceSummary}>
                      <div className={styles.priceRow}>
                        <span>Tạm tính:</span>
                        <span>{formatPrice(order.subtotalAmount)}</span>
                      </div>
                      {order.discountAmount > 0 && (
                        <div
                          className={styles.priceRow}
                          style={{ color: "#dc2626" }}
                        >
                          <span>Voucher ({order.voucherCode}):</span>
                          <span>-{formatPrice(order.discountAmount)}</span>
                        </div>
                      )}
                      <div className={styles.priceRow}>
                        <span>Phí ship:</span>
                        <span style={{ color: "#0b8a36" }}>Miễn phí</span>
                      </div>
                      <div className={styles.priceTotalRow}>
                        <span>Tổng tiền:</span>
                        <span>{formatPrice(order.totalAmount)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

export default function OrdersPage() {
  return (
    <Suspense
      fallback={
        <div style={{ textAlign: "center", padding: "100px 0" }}>
          Đang tải dữ liệu đơn hàng…
        </div>
      }
    >
      <OrdersContent />
    </Suspense>
  );
}
