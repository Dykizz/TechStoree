"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { useCart } from "../../lib/context/CartContext";
import { useProtectedSession } from "../../lib/use-protected-session";
import { mapOrder, type BackendOrder } from "../../lib/orders-api";
import {
  notifyPaymentConfirmed,
  publishNotification,
} from "../../lib/customer-notifications";
import { formatPrice } from "../../lib/products-client";
import { Order, PaymentMethod } from "../../lib/types/order";
import OrderConfirmation from "./OrderConfirmation";
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
  const session = useProtectedSession();
  const {
    items,
    totalPrice,
    appliedVoucher,
    discountAmount,
    finalPrice,
    refreshCart,
    busy,
    error: cartError,
  } = useCart();

  const [recipientName, setRecipientName] = useState("");
  const [recipientPhone, setRecipientPhone] = useState("");
  const [province, setProvince] = useState("TP. Hồ Chí Minh");
  const [shippingAddress, setShippingAddress] = useState("");
  const [note, setNote] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("COD");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [createdOrder, setCreatedOrder] = useState<Order | null>(null);
  const submitting = useRef(false);

  // Dynamic shipping fee calculation
  const shippingFee = 0; // Backend does not currently calculate delivery fees.

  const grandTotal = finalPrice + shippingFee;

  // Auto-fill logged in user info if available
  useEffect(() => {
    async function loadUser() {
      try {
        const res = await fetch("/api/auth/session", { cache: "no-store" });
        if (res.ok) {
          const data = await res.json();
          if (data && data.user) {
            setRecipientName(
              (prev) => prev || data.user.fullName || data.user.username,
            );
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
    if (
      submitting.current ||
      isSubmitting ||
      busy ||
      !!cartError ||
      session.status !== "ready" ||
      !validate() ||
      items.length === 0
    )
      return;

    submitting.current = true;
    setIsSubmitting(true);

    const fullAddress = `${shippingAddress.trim()}, ${province}`;
    try {
      const backendCartIds = items
        .map((it) => it.backendCartItemId)
        .filter((id): id is number => typeof id === "number" && id > 0);
      if (backendCartIds.length !== items.length)
        throw new Error("Giỏ hàng chưa đồng bộ. Vui lòng tải lại.");
      const response = await fetch("/api/orders/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          receiverName: recipientName.trim(),
          receiverPhone: recipientPhone.replace(/[\s.-]/g, ""),
          shippingAddress: fullAddress,
          notes: note.trim() || undefined,
          paymentMethod: paymentMethod === "BANKING" ? "BANK_TRANSFER" : "COD",
          voucherCode: appliedVoucher?.code || undefined,
          cartItemIds: backendCartIds,
        }),
      });
      const result = (await response.json()) as {
        success: boolean;
        message: string;
        data: BackendOrder;
      };
      if (!response.ok || !result.success || !result.data?.orderId)
        throw new Error(result.message || "Không thể đặt hàng.");
      const order = mapOrder(result.data);
      setCreatedOrder(order);
      const paymentNote = order.paymentStatus === "PAID"
        ? ""
        : order.paymentMethod === "BANKING"
          ? " Thanh toán chuyển khoản đang chờ xác nhận."
          : " Bạn sẽ thanh toán khi nhận hàng.";
      if (order.userId === session.user.userId) {
        publishNotification(session.user.userId, {
          id: `order:${order.orderId}`,
          kind: "order",
          title: "Đặt hàng thành công",
          message: `Đơn ${order.orderCode} đã được tạo.${paymentNote}`,
          href: `/orders?code=${encodeURIComponent(order.orderCode)}`,
        });
      }
      notifyPaymentConfirmed(session.user.userId, order);
      await refreshCart();
    } catch (error) {
      setErrors({
        submit:
          error instanceof Error
            ? error.message
            : "Không thể kết nối đến máy chủ.",
      });
    } finally {
      submitting.current = false;
      setIsSubmitting(false);
    }
  };

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

  if (createdOrder) {
    return (
      <main className={styles.main}>
        <div className={styles.container}>
          <OrderConfirmation order={createdOrder} />
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
        {errors.submit && (
          <p
            role="alert"
            className={styles.submitError}
          >
            {errors.submit}
          </p>
        )}
        <div className={styles.heading}>
          <Link href="/cart" className={styles.backLink}>← Quay lại giỏ hàng</Link>
          <p className={styles.eyebrow}>HOÀN TẤT ĐƠN HÀNG</p>
          <h1 className={styles.title}>Một bước nữa là hoàn tất.</h1>
          <p className={styles.subtitle}>
            Kiểm tra thông tin nhận hàng và chọn phương thức thanh toán phù hợp.
          </p>
        </div>

        <form onSubmit={handlePlaceOrder} noValidate aria-busy={isSubmitting}>
          <div className={`${styles.layout} ${isSubmitting ? styles.submittingLayout : ""}`}>
            <fieldset className={styles.formSection} disabled={isSubmitting}>
              <h2 className={styles.sectionTitle}>
                <span className={styles.stepNumber}>1</span>
                Thông tin nhận hàng
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
                      autoComplete="shipping name"
                      aria-invalid={!!errors.recipientName}
                      aria-describedby={errors.recipientName ? "recipient-name-error" : undefined}
                      onChange={(e) => {
                        setRecipientName(e.target.value);
                        if (errors.recipientName) {
                          setErrors((prev) => ({ ...prev, recipientName: "" }));
                        }
                      }}
                      required
                    />
                    {errors.recipientName && (
                      <span id="recipient-name-error" className={styles.errorText}>
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
                      autoComplete="shipping tel"
                      aria-invalid={!!errors.recipientPhone}
                      aria-describedby={errors.recipientPhone ? "recipient-phone-error" : undefined}
                      onChange={(e) => {
                        setRecipientPhone(e.target.value);
                        if (errors.recipientPhone) {
                          setErrors((prev) => ({
                            ...prev,
                            recipientPhone: "",
                          }));
                        }
                      }}
                      required
                    />
                    {errors.recipientPhone && (
                      <span id="recipient-phone-error" className={styles.errorText}>
                        {errors.recipientPhone}
                      </span>
                    )}
                  </div>
                </div>

                <div className={styles.fieldRow}>
                  <div className={styles.field}>
                    <label htmlFor="provinceSelect" className={styles.label}>
                      Tỉnh / Thành phố{" "}
                      <span className={styles.required}>*</span>
                    </label>
                    <select
                      id="provinceSelect"
                      className={styles.input}
                      value={province}
                      autoComplete="shipping address-level1"
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
                      Địa chỉ cụ thể{" "}
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
                      autoComplete="shipping street-address"
                      aria-invalid={!!errors.shippingAddress}
                      aria-describedby={errors.shippingAddress ? "shipping-address-error" : "shipping-address-help"}
                      onChange={(e) => {
                        setShippingAddress(e.target.value);
                        if (errors.shippingAddress) {
                          setErrors((prev) => ({
                            ...prev,
                            shippingAddress: "",
                          }));
                        }
                      }}
                      required
                    />
                    {errors.shippingAddress && (
                      <span id="shipping-address-error" className={styles.errorText}>
                        {errors.shippingAddress}
                      </span>
                    )}
                    <span id="shipping-address-help" className={styles.fieldHint}>Số nhà, tên đường và phường/xã.</span>
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
                      Thanh toán cho đơn vị giao hàng khi bạn nhận được hàng.
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
                    disabled={
                      !process.env.NEXT_PUBLIC_BANK_BIN ||
                      !process.env.NEXT_PUBLIC_BANK_ACCOUNT ||
                      !process.env.NEXT_PUBLIC_BANK_ACCOUNT_NAME
                    }
                    checked={paymentMethod === "BANKING"}
                    onChange={() => setPaymentMethod("BANKING")}
                    className={styles.radioInput}
                  />
                  <div className={styles.paymentContent}>
                    <div className={styles.paymentTitle}>
                      Chuyển khoản ngân hàng qua mã QR (VietQR 24/7)
                    </div>
                    <div className={styles.paymentDesc}>
                      {process.env.NEXT_PUBLIC_BANK_ACCOUNT
                        ? "Mã QR hiển thị thông tin chuyển khoản. Trạng thái thanh toán chỉ cập nhật khi hệ thống xác nhận."
                        : "Chưa cấu hình tài khoản nhận tiền. Vui lòng chọn COD."}
                    </div>
                    {paymentMethod === "BANKING" && (
                      <div className={styles.bankQrBox}>
                        <p>
                          <strong>Ngân hàng thụ hưởng:</strong> Ngân hàng đã cấu
                          hình
                        </p>
                        <p>
                          <strong>Số tài khoản:</strong>{" "}
                          {process.env.NEXT_PUBLIC_BANK_ACCOUNT}
                        </p>
                        <p>
                          <strong>Chủ tài khoản:</strong>{" "}
                          {process.env.NEXT_PUBLIC_BANK_ACCOUNT_NAME}
                        </p>
                        <p style={{ marginTop: "8px", color: "#166534" }}>
                          Mã QR sẽ hiển thị ngay sau khi bạn bấm Xác Nhận Đặt
                          Hàng.
                        </p>
                      </div>
                    )}
                  </div>
                </label>
              </div>
            </fieldset>

            <aside className={styles.summarySection}>
              <div className={styles.summaryHeader}>
                <h2 className={styles.summaryTitle}>
                  Tóm tắt đơn hàng
                </h2>
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
                      <span className={styles.itemQtyBadge}>{it.quantity}</span>
                    </div>

                    <div className={styles.itemDetails}>
                      <div className={styles.itemName}>{it.productName}</div>
                      <div className={styles.itemVariant}>{it.variantName}</div>
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
                  <div className={styles.calcRow} style={{ color: "#dc2626" }}>
                    <span>Voucher ({appliedVoucher?.code})</span>
                    <span>-{formatPrice(discountAmount)}</span>
                  </div>
                )}

                <div className={styles.calcRow}>
                  <span>Phí vận chuyển</span>
                  <span>
                    {shippingFee === 0 ? (
                      <span className={styles.shippingPending}>
                        Chưa tính phí
                      </span>
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

              <p className={styles.feeNotice}>Phí vận chuyển chưa được hệ thống tính trong tổng tiền này.</p>
              <button
                type="submit"
                disabled={isSubmitting || busy || !!cartError}
                className={styles.submitBtn}
              >
                {isSubmitting && <span className={styles.spinner} aria-hidden="true" />}
                {isSubmitting ? "Đang xác nhận đơn…" : "Xác nhận đặt hàng"}
              </button>

              <p className={styles.processingStatus} role="status" aria-live="polite">
                {isSubmitting ? "Đang gửi đơn đến hệ thống. Vui lòng chờ và không đóng trang." : ""}
              </p>

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
