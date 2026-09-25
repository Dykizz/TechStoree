"use client";

import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { getOrders } from "../../lib/order-client";
import { formatPrice } from "../../lib/products-client";
import { Order } from "../../lib/types/order";
import styles from "./orders.module.css";

function OrdersContent() {
  const searchParams = useSearchParams();
  const initialCode = searchParams.get("code") || "";

  const [orders, setOrders] = useState<Order[]>([]);
  const [searchCode, setSearchCode] = useState(initialCode);
  const [filteredOrders, setFilteredOrders] = useState<Order[]>([]);

  useEffect(() => {
    const timer = setTimeout(() => {
      const list = getOrders();
      setOrders(list);
      if (initialCode) {
        const found = list.filter((o) =>
          o.orderCode.toLowerCase().includes(initialCode.toLowerCase())
        );
        setFilteredOrders(found);
      } else {
        setFilteredOrders(list);
      }
    }, 0);
    return () => clearTimeout(timer);
  }, [initialCode]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const q = searchCode.trim().toLowerCase();
    if (!q) {
      setFilteredOrders(orders);
    } else {
      setFilteredOrders(
        orders.filter(
          (o) =>
            o.orderCode.toLowerCase().includes(q) ||
            o.recipientPhone.includes(q)
        )
      );
    }
  };

  const getStatusBadge = (status: Order["status"]) => {
    switch (status) {
      case "PENDING":
        return (
          <span className={`${styles.statusBadge} ${styles.statusPending}`}>
            Chờ xác nhận
          </span>
        );
      case "SHIPPING":
        return (
          <span className={`${styles.statusBadge} ${styles.statusShipping}`}>
            Đang giao hàng
          </span>
        );
      case "COMPLETED":
        return (
          <span className={`${styles.statusBadge} ${styles.statusCompleted}`}>
            Đã hoàn thành
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
            Theo dõi trạng thái giao hàng và chi tiết các đơn hàng bạn đã đặt.
          </p>
        </div>

        <form onSubmit={handleSearch} className={styles.searchBox}>
          <input
            type="text"
            className={styles.searchInput}
            placeholder="Nhập mã đơn hàng (VD: TECH-123456-7890) hoặc số điện thoại..."
            value={searchCode}
            onChange={(e) => setSearchCode(e.target.value)}
          />
          <button type="submit" className={styles.searchBtn}>
            Tra cứu
          </button>
        </form>

        {filteredOrders.length === 0 ? (
          <div className={styles.emptyState}>
            <svg
              className={styles.emptyIcon}
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
            >
              <rect width="18" height="18" x="3" y="3" rx="2" />
              <path d="M3 9h18" />
              <path d="M9 21V9" />
            </svg>
            <h2>Chưa có đơn hàng nào</h2>
            <p>
              {searchCode
                ? `Không tìm thấy đơn hàng phù hợp với từ khóa "${searchCode}".`
                : "Bạn chưa đặt đơn hàng nào trên hệ thống."}
            </p>
            <Link href="/products" className={styles.shopBtn}>
              Khám phá sản phẩm ngay
            </Link>
          </div>
        ) : (
          <div className={styles.ordersList}>
            {filteredOrders.map((order) => (
              <div key={order.orderId} className={styles.orderCard}>
                <div className={styles.orderHeader}>
                  <div className={styles.orderMeta}>
                    <span className={styles.orderCode}>{order.orderCode}</span>
                    <span className={styles.orderDate}>
                      {new Date(order.createdAt).toLocaleDateString("vi-VN", {
                        hour: "2-digit",
                        minute: "2-digit",
                        day: "2-digit",
                        month: "2-digit",
                        year: "numeric",
                      })}
                    </span>
                  </div>

                  <div className={styles.orderBadges}>
                    {getStatusBadge(order.status)}
                    <span
                      className={`${styles.paymentBadge} ${
                        order.paymentStatus === "PAID"
                          ? styles.paymentPaid
                          : styles.paymentUnpaid
                      }`}
                    >
                      {order.paymentStatus === "PAID"
                        ? "Đã thanh toán"
                        : "Chưa thanh toán (COD)"}
                    </span>
                  </div>
                </div>

                <div className={styles.orderBody}>
                  <div className={styles.itemsTable}>
                    {order.items.map((item) => (
                      <div key={item.orderItemId} className={styles.itemRow}>
                        <div className={styles.itemThumb}>
                          {item.imageUrl ? (
                            <Image
                              src={item.imageUrl}
                              alt={item.productName}
                              fill
                              className={styles.itemImage}
                              sizes="56px"
                            />
                          ) : (
                            <div className={styles.itemImage} />
                          )}
                        </div>

                        <div className={styles.itemInfo}>
                          <Link
                            href={`/products/${item.productId}`}
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
