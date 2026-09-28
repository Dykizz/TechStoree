"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useCart } from "../../lib/context/CartContext";
import { saveOrder } from "../../lib/order-client";
import { formatPrice } from "../../lib/products-client";
import { Order, OrderItem, PaymentMethod } from "../../lib/types/order";
import styles from "./checkout.module.css";

const PROVINCES = [
  "TP. Hồ Chí Minh",
  "Hà Nội",
  "Đà Nẵng",
  "Hải Phòng",
  "Cần Thơ",
  "Bình Dương",
  "Đồng Nai",
  "Quảng Ninh",
  "Khánh Hòa",
  "Thừa Thiên Huế",
  "Tỉnh / Thành khác",
];

export default function CheckoutPage() {
  const { items, totalPrice, appliedVoucher, discountAmount, finalPrice, clearCart } =
    useCart();

  const [recipientName, setRecipientName] = useState("");
  const [recipientPhone, setRecipientPhone] = useState("");
  const [province, setProvince] = useState("TP. Hồ Chí Minh");
  const [shippingAddress, setShippingAddress] = useState("");
  const [note, setNote] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("COD");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [createdOrder, setCreatedOrder] = useState<Order | null>(null);

  // Dynamic shipping fee calculation
  const shippingFee =
    totalPrice >= 1000000
      ? 0
      : province.includes("Hồ Chí Minh") || province.includes("Hà Nội")
      ? 30000
      : 45000;

  const grandTotal = finalPrice + shippingFee;

  // Auto-fill logged in user info if available
  useEffect(() => {
    async function loadUser() {
      try {
        const res = await fetch("/api/auth/session", { cache: "no-store" });
        if (res.ok) {
          const data = await res.json();
          if (data && data.user) {
            setRecipientName((prev) => prev || data.user.fullName || data.user.username);
          }
        }
      } catch {
        // Optional
      }
    }
    void loadUser();
  }, []);

  const validate = () => {
    const errs: Record<string, string> = {};
    if (!recipientName.trim()) {
      errs.recipientName = "Vui lòng nhập họ và tên người nhận.";
    }
    const cleanPhone = recipientPhone.replace(/[\s.-]/g, "");
    const phoneRegex = /^(0|\+?84)[0-9]{9}$/;
    if (!recipientPhone.trim()) {
      errs.recipientPhone = "Vui lòng nhập số điện thoại.";
    } else if (!phoneRegex.test(cleanPhone)) {
      errs.recipientPhone = "Số điện thoại không hợp lệ (10 số).";
    }
    if (!shippingAddress.trim()) {
      errs.shippingAddress = "Vui lòng nhập địa chỉ cụ thể.";
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handlePlaceOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate() || items.length === 0) return;

    setIsSubmitting(true);

    const randomSuffix = Math.floor(1000 + Math.random() * 9000);
    let orderCode = `TECH-${Date.now().toString().slice(-6)}-${randomSuffix}`;
    const fullAddress = `${shippingAddress.trim()}, ${province}`;

    const orderItems: OrderItem[] = items.map((it) => ({
      orderItemId: `item-${Date.now()}-${it.variantId}`,
      variantId: it.variantId,
      productId: it.productId,
      productName: it.productName,
      variantName: it.variantName,
      unitPrice: it.price,
      quantity: it.quantity,
      imageUrl: it.imageUrl,
    }));

    // Try calling backend checkout API first
    try {
      const backendCartIds = items
        .map((it) => it.backendCartItemId)
        .filter((id): id is number => typeof id === "number" && id > 0);

      const backendPayload = {
        receiverName: recipientName.trim(),
        receiverPhone: recipientPhone.replace(/[\s.-]/g, ""),
        shippingAddress: fullAddress,
        notes: note.trim() || undefined,
        paymentMethod: paymentMethod === "BANKING" ? "BANK_TRANSFER" : paymentMethod,
        voucherCode: appliedVoucher?.code || undefined,
        cartItemIds: backendCartIds.length > 0 ? backendCartIds : undefined,
      };

      const res = await fetch("/api/orders/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(backendPayload),
      });

      if (res.ok) {
        const result = await res.json();
        if (result && result.data && result.data.orderCode) {
          orderCode = result.data.orderCode;
        }
      }
    } catch {
      // Backend offline or guest mode: continue with generated order code
    }

    const newOrder: Order = {
      orderId: `ord-${Date.now()}`,
      orderCode,
      voucherCode: appliedVoucher?.code,
      subtotalAmount: totalPrice,
      discountAmount,
      totalAmount: grandTotal,
      status: "PENDING",
      paymentMethod,
      paymentStatus: paymentMethod === "BANKING" ? "PAID" : "UNPAID",
      shippingAddress: fullAddress,
      recipientName: recipientName.trim(),
      recipientPhone: recipientPhone.trim(),
      note: note.trim() || undefined,
      createdAt: new Date().toISOString(),
      items: orderItems,
    };

    saveOrder(newOrder);
    setCreatedOrder(newOrder);
    clearCart();
    setIsSubmitting(false);
  };

  if (createdOrder) {
    const isBanking = createdOrder.paymentMethod === "BANKING";
    const qrUrl = `https://img.vietqr.io/image/VCB-999988882026-compact2.png?amount=${createdOrder.totalAmount}&addInfo=${encodeURIComponent(
      createdOrder.orderCode
    )}&accountName=TECHSTOREE%20VIETNAM`;

    return (
      <main className={styles.main}>
        <div className={styles.container}>
          <div className={styles.successCard}>
            <svg
              className={styles.successIcon}
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
              <polyline points="22 4 12 14.01 9 11.01" />
            </svg>
            <h1 style={{ fontSize: "1.8rem", marginBottom: "8px" }}>
              Đặt Hàng Thành Công!
            </h1>
            <p style={{ color: "#666", fontSize: "0.95rem" }}>
              Cảm ơn bạn đã tin tưởng TechStoree. Đơn hàng của bạn đang được xử lý.
            </p>

            <div>
              <span className={styles.orderCodeBadge}>
                MÃ ĐƠN HÀNG: {createdOrder.orderCode}
              </span>
            </div>

            {/* If Banking, display VietQR immediately */}
            {isBanking && (
              <div
                style={{
                  background: "#f0fdf4",
                  border: "1px solid #bbf7d0",
                  borderRadius: "16px",
                  padding: "24px",
                  margin: "24px 0",
                  textAlign: "center",
                }}
              >
                <h3 style={{ color: "#166534", marginBottom: "6px", fontSize: "1.15rem" }}>
                  Quét Mã VietQR Để Thanh Toán Đơn Hàng
                </h3>
                <p style={{ color: "#15803d", fontSize: "0.88rem", marginBottom: "16px" }}>
                  Mở ứng dụng ngân hàng bất kỳ để quét mã QR với thông tin chuyển khoản đã điền sẵn:
                </p>

                <div style={{ display: "inline-block", background: "#fff", padding: "12px", borderRadius: "12px", boxShadow: "0 4px 12px rgba(0,0,0,0.08)" }}>
                  <img
                    src={qrUrl}
                    alt={`VietQR ${createdOrder.orderCode}`}
                    style={{ width: "240px", height: "auto", display: "block" }}
                  />
                </div>

                <div style={{ marginTop: "16px", fontSize: "0.9rem", color: "#374151" }}>
                  <p>Ngân hàng: <strong>Vietcombank (VCB)</strong></p>
                  <p>Số tài khoản: <strong>999988882026</strong></p>
                  <p>Chủ tài khoản: <strong>TECHSTOREE VIETNAM</strong></p>
                  <p>Số tiền: <strong style={{ color: "#16a34a", fontSize: "1.1rem" }}>{formatPrice(createdOrder.totalAmount)}</strong></p>
                  <p>Nội dung chuyển khoản: <strong style={{ color: "#dc2626" }}>{createdOrder.orderCode}</strong></p>
                </div>
              </div>
            )}

            <div className={styles.orderDetailsBox}>
              <p>
                <strong>Người nhận:</strong> {createdOrder.recipientName} (
                {createdOrder.recipientPhone})
              </p>
              <p>
                <strong>Địa chỉ giao:</strong> {createdOrder.shippingAddress}
              </p>
              <p>
                <strong>Hình thức thanh toán:</strong>{" "}
                {createdOrder.paymentMethod === "COD"
                  ? "Thanh toán khi nhận hàng (COD)"
                  : "Chuyển khoản VietQR"}
              </p>
              <p>
                <strong>Tổng thanh toán:</strong>{" "}
                <span style={{ color: "#111", fontWeight: 700 }}>
                  {formatPrice(createdOrder.totalAmount)}
                </span>
                {createdOrder.discountAmount > 0 && (
                  <span style={{ color: "#dc2626", marginLeft: "8px" }}>
                    (Đã giảm {formatPrice(createdOrder.discountAmount)} qua voucher{" "}
                    {createdOrder.voucherCode})
                  </span>
                )}
              </p>
            </div>

            <div className={styles.successActions}>
              <Link
                href={`/orders?code=${encodeURIComponent(createdOrder.orderCode)}`}
                className={styles.trackOrderBtn}
              >
                Tra cứu đơn hàng
              </Link>
              <Link href="/products" className={styles.continueShoppingBtn}>
                Tiếp tục mua sắm
              </Link>
            </div>
          </div>
        </div>
      </main>
    );
  }

  if (items.length === 0) {
    return (
      <main className={styles.main}>
        <div className={styles.container}>
          <div style={{ textAlign: "center", padding: "80px 24px" }}>
            <h2>Giỏ hàng của bạn đang trống</h2>
            <p style={{ color: "#666", margin: "16px 0 24px" }}>
              Bạn chưa có sản phẩm nào để tiến hành thanh toán.
            </p>
            <Link
              href="/products"
              style={{
                backgroundColor: "#111",
                color: "#fff",
                padding: "12px 24px",
                borderRadius: "999px",
                textDecoration: "none",
                fontWeight: 600,
                display: "inline-block",
              }}
            >
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
          <h1 className={styles.title}>Thanh Toán Đơn Hàng</h1>
          <p className={styles.subtitle}>
            Vui lòng điền thông tin người nhận và chọn phương thức thanh toán.
          </p>
        </div>

        <form onSubmit={handlePlaceOrder} noValidate>
          <div className={styles.layout}>
            <div className={styles.formSection}>
              <h2 className={styles.sectionTitle}>
                <span className={styles.stepNumber}>1</span>
                Thông tin người nhận & Địa chỉ giao hàng
              </h2>

              <div className={styles.fieldsGrid}>
                <div className={styles.fieldRow}>
                  <div className={styles.field}>
                    <label htmlFor="recipientName" className={styles.label}>
                      Họ và tên <span className={styles.required}>*</span>
                    </label>
                    <input
                      id="recipientName"
                      type="text"
                      className={`${styles.input} ${
                        errors.recipientName ? styles.inputError : ""
                      }`}
                      placeholder="Nguyễn Văn A"
                      value={recipientName}
                      onChange={(e) => {
                        setRecipientName(e.target.value);
                        if (errors.recipientName) {
                          setErrors((prev) => ({ ...prev, recipientName: "" }));
                        }
                      }}
                      required
                    />
                    {errors.recipientName && (
                      <span className={styles.errorText}>
                        {errors.recipientName}
                      </span>
                    )}
                  </div>

                  <div className={styles.field}>
                    <label htmlFor="recipientPhone" className={styles.label}>
                      Số điện thoại <span className={styles.required}>*</span>
                    </label>
                    <input
                      id="recipientPhone"
                      type="tel"
                      className={`${styles.input} ${
                        errors.recipientPhone ? styles.inputError : ""
                      }`}
                      placeholder="0987654321"
                      value={recipientPhone}
                      onChange={(e) => {
                        setRecipientPhone(e.target.value);
                        if (errors.recipientPhone) {
                          setErrors((prev) => ({ ...prev, recipientPhone: "" }));
                        }
                      }}
                      required
                    />
                    {errors.recipientPhone && (
                      <span className={styles.errorText}>
                        {errors.recipientPhone}
                      </span>
                    )}
                  </div>
                </div>

                <div className={styles.fieldRow}>
                  <div className={styles.field}>
                    <label htmlFor="provinceSelect" className={styles.label}>
                      Tỉnh / Thành phố <span className={styles.required}>*</span>
                    </label>
                    <select
                      id="provinceSelect"
                      className={styles.input}
                      value={province}
                      onChange={(e) => setProvince(e.target.value)}
                    >
                      {PROVINCES.map((p) => (
                        <option key={p} value={p}>
                          {p}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className={styles.field}>
                    <label htmlFor="shippingAddress" className={styles.label}>
                      Địa chỉ cụ thể (Số nhà, Tên đường, Phường/Xã){" "}
                      <span className={styles.required}>*</span>
                    </label>
                    <input
                      id="shippingAddress"
                      type="text"
                      className={`${styles.input} ${
                        errors.shippingAddress ? styles.inputError : ""
                      }`}
                      placeholder="Ví dụ: 123 Nguyễn Huệ, Phường Bến Nghé"
                      value={shippingAddress}
                      onChange={(e) => {
                        setShippingAddress(e.target.value);
                        if (errors.shippingAddress) {
                          setErrors((prev) => ({ ...prev, shippingAddress: "" }));
                        }
                      }}
                      required
                    />
                    {errors.shippingAddress && (
                      <span className={styles.errorText}>
                        {errors.shippingAddress}
                      </span>
                    )}
                  </div>
                </div>

                <div className={styles.field}>
                  <label htmlFor="orderNote" className={styles.label}>
                    Ghi chú đơn hàng (Tùy chọn)
                  </label>
                  <textarea
                    id="orderNote"
                    rows={2}
                    className={styles.textarea}
                    placeholder="Ví dụ: Giao hàng vào giờ hành chính, gọi trước khi giao..."
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                  />
                </div>
              </div>

              <h2 className={styles.sectionTitle}>
                <span className={styles.stepNumber}>2</span>
                Phương thức thanh toán
              </h2>

              <div className={styles.paymentOptions}>
                <label
                  className={`${styles.paymentCard} ${
                    paymentMethod === "COD" ? styles.paymentCardActive : ""
                  }`}
                >
                  <input
                    type="radio"
                    name="paymentMethod"
                    value="COD"
                    checked={paymentMethod === "COD"}
                    onChange={() => setPaymentMethod("COD")}
                    className={styles.radioInput}
                  />
                  <div className={styles.paymentContent}>
                    <div className={styles.paymentTitle}>
                      Thanh toán khi nhận hàng (COD)
                    </div>
                    <div className={styles.paymentDesc}>
                      Kiểm tra hàng trước khi nhận, thanh toán tiền mặt trực tiếp cho shipper.
                    </div>
                  </div>
                </label>

                <label
                  className={`${styles.paymentCard} ${
                    paymentMethod === "BANKING" ? styles.paymentCardActive : ""
                  }`}
                >
                  <input
                    type="radio"
                    name="paymentMethod"
                    value="BANKING"
                    checked={paymentMethod === "BANKING"}
                    onChange={() => setPaymentMethod("BANKING")}
                    className={styles.radioInput}
                  />
                  <div className={styles.paymentContent}>
                    <div className={styles.paymentTitle}>
                      Chuyển khoản ngân hàng qua mã QR (VietQR 24/7)
                    </div>
                    <div className={styles.paymentDesc}>
                      Tự động điền số tài khoản, số tiền và nội dung chuyển khoản. Quét bằng mọi App Ngân hàng hoặc Ví MoMo/ZaloPay.
                    </div>
                    {paymentMethod === "BANKING" && (
                      <div className={styles.bankQrBox}>
                        <p>
                          <strong>Ngân hàng thụ hưởng:</strong> Vietcombank (VCB)
                        </p>
                        <p>
                          <strong>Số tài khoản:</strong> 999988882026
                        </p>
                        <p>
                          <strong>Chủ tài khoản:</strong> TECHSTOREE VIETNAM
                        </p>
                        <p style={{ marginTop: "8px", color: "#166534" }}>
                          ✓ Mã QR chính thức sẽ hiển thị ngay sau khi bạn bấm Xác Nhận Đặt Hàng.
                        </p>
                      </div>
                    )}
                  </div>
                </label>
              </div>
            </div>

            <aside className={styles.summarySection}>
              <div className={styles.summaryHeader}>
                <h2 className={styles.summaryTitle}>Đơn hàng ({items.length})</h2>
                <Link href="/cart" className={styles.editCartLink}>
                  Chỉnh sửa giỏ
                </Link>
              </div>

              <div className={styles.itemsList}>
                {items.map((it) => (
                  <div key={it.cartItemId} className={styles.itemRow}>
                    <div className={styles.itemThumb}>
                      {it.imageUrl ? (
                        <Image
                          src={it.imageUrl}
                          alt={it.productName}
                          fill
                          sizes="52px"
                          className={styles.itemImage}
                        />
                      ) : (
                        <div className={styles.orderItemPlaceholder} />
                      )}
                      <span className={styles.itemQtyBadge}>
                        {it.quantity}
                      </span>
                    </div>

                    <div className={styles.itemDetails}>
                      <div className={styles.itemName}>
                        {it.productName}
                      </div>
                      <div className={styles.itemVariant}>
                        {it.variantName}
                      </div>
                    </div>

                    <div className={styles.itemPrice}>
                      {formatPrice(it.price * it.quantity)}
                    </div>
                  </div>
                ))}
              </div>

              <div className={styles.calcRows}>
                <div className={styles.calcRow}>
                  <span>Tạm tính ({items.length} món)</span>
                  <span>{formatPrice(totalPrice)}</span>
                </div>

                {discountAmount > 0 && (
                  <div
                    className={styles.calcRow}
                    style={{ color: "#dc2626" }}
                  >
                    <span>Voucher ({appliedVoucher?.code})</span>
                    <span>-{formatPrice(discountAmount)}</span>
                  </div>
                )}

                <div className={styles.calcRow}>
                  <span>Phí vận chuyển ({province})</span>
                  <span>
                    {shippingFee === 0 ? (
                      <span style={{ color: "#16a34a", fontWeight: 600 }}>Miễn phí</span>
                    ) : (
                      formatPrice(shippingFee)
                    )}
                  </span>
                </div>

                <div className={styles.totalRow}>
                  <span className={styles.totalLabel}>Tổng thanh toán</span>
                  <span className={styles.totalPrice}>
                    {formatPrice(grandTotal)}
                  </span>
                </div>
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className={styles.submitBtn}
                onClick={handlePlaceOrder}
              >
                {isSubmitting ? "Đang xử lý…" : "Xác Nhận Đặt Hàng"}
              </button>

              <p className={styles.policyNotice}>
                Bằng việc bấm xác nhận, bạn đồng ý với Điều khoản mua hàng &
                Chính sách bảo mật của TechStoree.
              </p>
            </aside>
          </div>
        </form>
      </div>
    </main>
  );
}
