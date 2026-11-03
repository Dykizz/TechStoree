"use client";

import Image from "next/image";
import Link from "next/link";
import { Suspense, useEffect, useRef, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useCart } from "@/lib/context/CartContext";
import { useProtectedSession } from "@/lib/use-protected-session";
import { useProfile } from "@/hooks/queries/useProfile";
import { useCheckoutOrder } from "@/hooks/mutations/useCheckoutOrder";
import { mapOrder } from "@/lib/orders-api";
import {
  notifyPaymentConfirmed,
  publishNotification,
} from "@/lib/customer-notifications";
import { formatPrice } from "@/lib/products-client";
import { Order, PaymentMethod } from "@/lib/types/order";
import OrderConfirmation from "./OrderConfirmation";
import { cn } from "@/lib/utils";

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

const SUPPORTED_BANKS = [
  { bin: "970422", shortName: "MBBank", name: "MBBank (Ngân hàng TMCP Quân Đội)" },
  { bin: "970436", shortName: "Vietcombank", name: "Vietcombank (Ngân hàng Ngoại Thương)" },
  { bin: "970407", shortName: "Techcombank", name: "Techcombank (Ngân hàng Kỹ Thương)" },
  { bin: "970416", shortName: "ACB", name: "ACB (Ngân hàng Á Châu)" },
  { bin: "970432", shortName: "VPBank", name: "VPBank (Ngân hàng Việt Nam Thịnh Vượng)" },
  { bin: "970423", shortName: "TPBank", name: "TPBank (Ngân hàng Tiên Phong)" },
  { bin: "970418", shortName: "BIDV", name: "BIDV (Ngân hàng Đầu tư & Phát triển)" },
  { bin: "970415", shortName: "VietinBank", name: "VietinBank (Ngân hàng Công Thương)" },
  { bin: "970403", shortName: "Sacombank", name: "Sacombank (Ngân hàng Sài Gòn Thương Tín)" },
  { bin: "970448", shortName: "OCB", name: "OCB (Ngân hàng Phương Đông)" },
];

function CheckoutContent() {
  const searchParams = useSearchParams();
  const orderIdParam = searchParams.get("orderId");
  const orderCodeParam = searchParams.get("orderCode") || searchParams.get("code");

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
  const { mutateAsync: checkoutOrderMutation } = useCheckoutOrder();

  const [recipientName, setRecipientName] = useState("");
  const [recipientPhone, setRecipientPhone] = useState("");
  const [province, setProvince] = useState("TP. Hồ Chí Minh");
  const [shippingAddress, setShippingAddress] = useState("");
  const [note, setNote] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("COD");
  const [selectedBankBin, setSelectedBankBin] = useState<string>(
    process.env.NEXT_PUBLIC_BANK_BIN || "970422",
  );
  const [bankAccount, setBankAccount] = useState<string>(
    process.env.NEXT_PUBLIC_BANK_ACCOUNT || "0372933562",
  );
  const [bankAccountName, setBankAccountName] = useState<string>(
    process.env.NEXT_PUBLIC_BANK_ACCOUNT_NAME || "NGUYEN HONG SON",
  );
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [createdOrder, setCreatedOrder] = useState<Order | null>(null);
  const [loadingOrder, setLoadingOrder] = useState<boolean>(
    !!(orderIdParam || orderCodeParam),
  );
  const [orderError, setOrderError] = useState<string>("");
  const submitting = useRef(false);

  // Tải thông tin đơn hàng nếu có orderId hoặc orderCode trên URL (Khách bấm quay lại từ danh sách đơn hàng)
  useEffect(() => {
    if (!orderIdParam && !orderCodeParam) return;
    if (session.status !== "ready") return;

    let active = true;
    async function loadExistingOrder() {
      setLoadingOrder(true);
      setOrderError("");
      try {
        const url = orderIdParam
          ? `/api/orders/${orderIdParam}`
          : `/api/orders/code/${encodeURIComponent(orderCodeParam!)}`;

        const res = await fetch(url, { cache: "no-store" });
        const result = await res.json();
        if (!res.ok || !result.success || !result.data) {
          throw new Error(result.message || "Không tìm thấy thông tin đơn hàng.");
        }
        if (active) {
          const order = mapOrder(result.data);
          setCreatedOrder(order);
        }
      } catch (err: unknown) {
        if (active) {
          setOrderError(
            err instanceof Error ? err.message : "Lỗi khi tải thông tin đơn hàng.",
          );
        }
      } finally {
        if (active) setLoadingOrder(false);
      }
    }

    void loadExistingOrder();

    return () => {
      active = false;
    };
  }, [orderIdParam, orderCodeParam, session.status]);

  const activeBank =
    SUPPORTED_BANKS.find((b) => b.bin === selectedBankBin) || SUPPORTED_BANKS[0];

  // Dynamic shipping fee calculation
  const shippingFee = 0; // Backend does not currently calculate delivery fees.

  const grandTotal = finalPrice + shippingFee;

  // Auto-fill logged in user info (Render-phase state adjustment, không cascading render)
  const [syncedUser, setSyncedUser] = useState(false);
  if (!syncedUser && session.status === "ready" && session.user) {
    setSyncedUser(true);
    const u = session.user;
    if (u.fullName || u.username) {
      setRecipientName((prev) => prev || u.fullName || u.username);
    }
    if (u.phone) {
      setRecipientPhone((prev) => prev || u.phone?.trim() || "");
    }
    if (u.address) {
      setShippingAddress((prev) => prev || u.address?.trim() || "");
    }
  }

  // Sync fresh profile asynchronously via TanStack Query without cascading render
  const isSessionReady = session.status === "ready";
  const { data: userProfile } = useProfile(isSessionReady);

  const [syncedProfile, setSyncedProfile] = useState<typeof userProfile>(undefined);
  if (userProfile && userProfile !== syncedProfile) {
    setSyncedProfile(userProfile);
    if (!recipientName && (userProfile.fullName || userProfile.username)) {
      setRecipientName(userProfile.fullName || userProfile.username);
    }
    if (!recipientPhone && userProfile.phone) {
      setRecipientPhone(userProfile.phone.trim());
    }
    if (!shippingAddress && userProfile.address) {
      setShippingAddress(userProfile.address.trim());
    }
  }

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
      let formattedNotes = note.trim();
      if (paymentMethod === "BANKING") {
        const bankTag = `[VIETQR | ${activeBank.shortName} - STK: ${bankAccount.trim()} - ${bankAccountName.trim().toUpperCase()}]`;
        formattedNotes = formattedNotes ? `${bankTag} ${formattedNotes}` : bankTag;
      }

      const createdBackendOrder = await checkoutOrderMutation({
        receiverName: recipientName.trim(),
        receiverPhone: recipientPhone.replace(/[\s.-]/g, ""),
        shippingAddress: fullAddress,
        notes: formattedNotes ? formattedNotes.slice(0, 500) : undefined,
        paymentMethod: paymentMethod === "BANKING" ? "BANK_TRANSFER" : "COD",
        voucherCode: appliedVoucher?.code || undefined,
        cartItemIds: backendCartIds,
      });
      const order = mapOrder(createdBackendOrder);
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
      <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
        <div className="max-w-[1200px] mx-auto min-w-0" role="status">
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

  if (loadingOrder) {
    return (
      <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
        <div className="max-w-[1200px] mx-auto min-w-0" role="status">
          <p>Đang tải thông tin đơn hàng và mã QR thanh toán…</p>
        </div>
      </main>
    );
  }

  if (orderError) {
    return (
      <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
        <div className="max-w-[1200px] mx-auto min-w-0" role="alert">
          <p style={{ color: "#dc2626", marginBottom: "16px" }}>{orderError}</p>
          <Link href="/orders" className="inline-block mb-[22px] sm:mb-[26px] text-muted text-[13px] no-underline hover:text-brand transition-colors">
            ← Quay lại danh sách đơn hàng
          </Link>
        </div>
      </main>
    );
  }

  if (createdOrder) {
    let customBank = {
      bin: selectedBankBin,
      name: activeBank.name,
      account: bankAccount,
      accountName: bankAccountName,
    };

    if (createdOrder.note) {
      const match = createdOrder.note.match(
        /\[VIETQR \| ([^-]+) - STK: ([^-]+) - ([^\]]+)\]/,
      );
      if (match) {
        const parsedBank = SUPPORTED_BANKS.find(
          (b) => b.shortName.toLowerCase() === match[1].trim().toLowerCase(),
        );
        customBank = {
          bin: parsedBank?.bin || selectedBankBin,
          name: parsedBank?.name || match[1].trim(),
          account: match[2].trim(),
          accountName: match[3].trim(),
        };
      }
    }

    return (
      <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
        <div className="max-w-[1200px] mx-auto min-w-0">
          <OrderConfirmation
            order={createdOrder}
            customBank={customBank}
          />
        </div>
      </main>
    );
  }

  if (items.length === 0) {
    return (
      <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
        <div className="max-w-[1200px] mx-auto min-w-0">
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
    <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
      <div className="max-w-[1200px] mx-auto min-w-0">
        {errors.submit && (
          <p
            role="alert"
            className="mb-6 px-5 py-4 border border-[#f3d6d9] rounded-xl bg-[#fff1f2] text-[#a11929] text-[13px] [overflow-wrap:anywhere]"
          >
            {errors.submit}
          </p>
        )}
        <div className="mb-[26px] sm:mb-8 max-w-[720px]">
          <Link href="/cart" className="inline-block mb-[22px] sm:mb-[26px] text-muted text-[13px] no-underline hover:text-brand transition-colors">← Quay lại giỏ hàng</Link>
          <p className="text-brand text-[10px] font-bold tracking-[.13em] leading-[1.7] uppercase">HOÀN TẤT ĐƠN HÀNG</p>
          <h1 className="my-3 mb-3.5 text-[clamp(28px,3.2vw,42px)] font-semibold tracking-[-0.045em] leading-[1.16] [text-wrap:balance]">Một bước nữa là hoàn tất.</h1>
          <p className="text-muted text-sm leading-[1.75]">
            Kiểm tra thông tin nhận hàng và chọn phương thức thanh toán phù hợp.
          </p>
        </div>

        <form onSubmit={handlePlaceOrder} noValidate aria-busy={isSubmitting}>
          <div
            className={cn(
              "grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_350px] lg:grid-cols-[minmax(0,1fr)_minmax(320px,400px)] gap-[22px] lg:gap-7 items-start transition-opacity transition-transform duration-[220ms] ease-out motion-reduce:transition-none",
              isSubmitting && "opacity-[0.72] translate-y-0.5 motion-reduce:transform-none"
            )}
          >
            <fieldset className="min-w-0 m-0 p-[18px] sm:p-6 lg:p-[30px] border border-border rounded-2xl sm:rounded-[20px] bg-white shadow-[0_8px_30px_#1d1d1f03]" disabled={isSubmitting}>
              <h2 className="flex gap-3 items-center mb-6 text-[15px] sm:text-base font-semibold leading-normal">
                <span className="inline-flex shrink-0 w-7 h-7 items-center justify-center rounded-full bg-[#f3f3f5] text-ink text-xs font-semibold">1</span>
                Thông tin nhận hàng
              </h2>

              <div className="grid gap-5 sm:gap-[22px] mb-[30px] sm:mb-9">
                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-1 lg:grid-cols-2 gap-[18px] items-start">
                  <div className="flex flex-col gap-[9px] min-w-0">
                    <label htmlFor="recipientName" className="text-[#424245] text-xs font-semibold leading-normal">
                      Họ và tên <span className="text-brand">*</span>
                    </label>
                    <input
                      id="recipientName"
                      type="text"
                      className={cn(
                        "w-full min-w-0 min-h-[49px] px-3.5 py-[13px] border rounded-[10px] bg-white text-ink text-sm leading-normal placeholder:text-[#909098] focus:border-brand focus:ring-4 focus:ring-brand/5 focus:outline-none transition-colors duration-[180ms]",
                        errors.recipientName ? "border-brand" : "border-[#dedee2]"
                      )}
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
                      <span id="recipient-name-error" className="text-[#a11929] text-xs leading-[1.6]">
                        {errors.recipientName}
                      </span>
                    )}
                  </div>

                  <div className="flex flex-col gap-[9px] min-w-0">
                    <label htmlFor="recipientPhone" className="text-[#424245] text-xs font-semibold leading-normal">
                      Số điện thoại <span className="text-brand">*</span>
                    </label>
                    <input
                      id="recipientPhone"
                      type="tel"
                      className={cn(
                        "w-full min-w-0 min-h-[49px] px-3.5 py-[13px] border rounded-[10px] bg-white text-ink text-sm leading-normal placeholder:text-[#909098] focus:border-brand focus:ring-4 focus:ring-brand/5 focus:outline-none transition-colors duration-[180ms]",
                        errors.recipientPhone ? "border-brand" : "border-[#dedee2]"
                      )}
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
                      <span id="recipient-phone-error" className="text-[#a11929] text-xs leading-[1.6]">
                        {errors.recipientPhone}
                      </span>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-1 lg:grid-cols-2 gap-[18px] items-start">
                  <div className="flex flex-col gap-[9px] min-w-0">
                    <label htmlFor="provinceSelect" className="text-[#424245] text-xs font-semibold leading-normal">
                      Tỉnh / Thành phố{" "}
                      <span className="text-brand">*</span>
                    </label>
                    <select
                      id="provinceSelect"
                      className="w-full min-w-0 min-h-[49px] px-3.5 py-[13px] border border-[#dedee2] rounded-[10px] bg-white text-ink text-sm leading-normal focus:border-brand focus:ring-4 focus:ring-brand/5 focus:outline-none transition-colors duration-[180ms]"
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

                  <div className="flex flex-col gap-[9px] min-w-0">
                    <label htmlFor="shippingAddress" className="text-[#424245] text-xs font-semibold leading-normal">
                      Địa chỉ cụ thể{" "}
                      <span className="text-brand">*</span>
                    </label>
                    <input
                      id="shippingAddress"
                      type="text"
                      className={cn(
                        "w-full min-w-0 min-h-[49px] px-3.5 py-[13px] border rounded-[10px] bg-white text-ink text-sm leading-normal placeholder:text-[#909098] focus:border-brand focus:ring-4 focus:ring-brand/5 focus:outline-none transition-colors duration-[180ms]",
                        errors.shippingAddress ? "border-brand" : "border-[#dedee2]"
                      )}
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
                      <span id="shipping-address-error" className="text-[#a11929] text-xs leading-[1.6]">
                        {errors.shippingAddress}
                      </span>
                    )}
                    <span id="shipping-address-help" className="text-muted text-[11px] leading-[1.6]">Số nhà, tên đường và phường/xã.</span>
                  </div>
                </div>

                <div className="flex flex-col gap-[9px] min-w-0">
                  <label htmlFor="orderNote" className="text-[#424245] text-xs font-semibold leading-normal">
                    Ghi chú đơn hàng (Tùy chọn)
                  </label>
                  <textarea
                    id="orderNote"
                    rows={2}
                    className="w-full min-w-0 min-h-[98px] resize-y px-3.5 py-[13px] border border-[#dedee2] rounded-[10px] bg-white text-ink text-sm leading-normal placeholder:text-[#909098] focus:border-brand focus:ring-4 focus:ring-brand/5 focus:outline-none transition-colors duration-[180ms]"
                    placeholder="Ví dụ: Giao hàng vào giờ hành chính, gọi trước khi giao..."
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                  />
                </div>
              </div>

              <h2 className="flex gap-3 items-center mb-6 text-[15px] sm:text-base font-semibold leading-normal">
                <span className="inline-flex shrink-0 w-7 h-7 items-center justify-center rounded-full bg-[#f3f3f5] text-ink text-xs font-semibold">2</span>
                Phương thức thanh toán
              </h2>

              <div className="grid gap-3.5">
                <label
                  className={cn(
                    "flex items-start gap-[11px] sm:gap-3.5 p-[15px_13px] sm:p-[18px] border rounded-[13px] cursor-pointer transition-all duration-[180ms] has-[:disabled]:cursor-not-allowed",
                    paymentMethod === "COD"
                      ? "border-brand bg-[#fff8f8] shadow-[0_0_0_1px_#bd202d08]"
                      : "border-border bg-white hover:border-[#c4c4c9] has-[:disabled]:bg-[#fafafa]"
                  )}
                >
                  <input
                    type="radio"
                    name="paymentMethod"
                    value="COD"
                    checked={paymentMethod === "COD"}
                    onChange={() => setPaymentMethod("COD")}
                    className="shrink-0 w-4 h-4 mt-1 accent-brand"
                  />
                  <div className="min-w-0 flex-1">
                    <div className="text-[13px] font-semibold leading-[1.6]">
                      Thanh toán khi nhận hàng (COD)
                    </div>
                    <div className="mt-1.5 text-muted text-xs leading-[1.75]">
                      Thanh toán cho đơn vị giao hàng khi bạn nhận được hàng.
                    </div>
                  </div>
                </label>

                <label
                  className={cn(
                    "flex items-start gap-[11px] sm:gap-3.5 p-[15px_13px] sm:p-[18px] border rounded-[13px] cursor-pointer transition-all duration-[180ms] has-[:disabled]:cursor-not-allowed",
                    paymentMethod === "BANKING"
                      ? "border-brand bg-[#fff8f8] shadow-[0_0_0_1px_#bd202d08]"
                      : "border-border bg-white hover:border-[#c4c4c9] has-[:disabled]:bg-[#fafafa]"
                  )}
                >
                  <input
                    type="radio"
                    name="paymentMethod"
                    value="BANKING"
                    checked={paymentMethod === "BANKING"}
                    onChange={() => setPaymentMethod("BANKING")}
                    className="shrink-0 w-4 h-4 mt-1 accent-brand"
                  />
                  <div className="min-w-0 flex-1">
                    <div className="text-[13px] font-semibold leading-[1.6]">
                      Chuyển khoản ngân hàng qua mã QR (VietQR 24/7)
                    </div>
                    <div className="mt-1.5 text-muted text-xs leading-[1.75]">
                      Quét mã VietQR bằng ứng dụng ngân hàng bất kỳ để chuyển khoản nhanh 24/7.
                    </div>
                    {paymentMethod === "BANKING" && (
                      <div className="grid gap-[9px] mt-[15px] p-3.5 border border-border rounded-[9px] bg-white text-[#53535a] text-xs [overflow-wrap:anywhere]">
                        <div className="mb-3">
                          <label className="block text-xs font-semibold text-ink mb-1">
                            Ngân hàng thụ hưởng:
                          </label>
                          <select
                            className="w-full px-3 py-2 text-[13px] border border-border rounded-lg bg-white text-ink outline-none focus:border-brand transition-colors duration-150 box-border"
                            value={selectedBankBin}
                            onChange={(e) => setSelectedBankBin(e.target.value)}
                          >
                            {SUPPORTED_BANKS.map((b) => (
                              <option key={b.bin} value={b.bin}>
                                {b.name}
                              </option>
                            ))}
                          </select>
                        </div>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <div className="mb-3 sm:mb-0">
                            <label className="block text-xs font-semibold text-ink mb-1">
                              Số tài khoản nhận tiền:
                            </label>
                            <input
                              type="text"
                              className="w-full px-3 py-2 text-[13px] border border-border rounded-lg bg-white text-ink outline-none focus:border-brand transition-colors duration-150 box-border"
                              value={bankAccount}
                              onChange={(e) => setBankAccount(e.target.value)}
                              placeholder="Nhập số tài khoản"
                            />
                          </div>
                          <div>
                            <label className="block text-xs font-semibold text-ink mb-1">
                              Tên chủ tài khoản:
                            </label>
                            <input
                              type="text"
                              className="w-full px-3 py-2 text-[13px] border border-border rounded-lg bg-white text-ink outline-none focus:border-brand transition-colors duration-150 box-border"
                              value={bankAccountName}
                              onChange={(e) => setBankAccountName(e.target.value)}
                              placeholder="Nhập tên chủ tài khoản"
                            />
                          </div>
                        </div>
                        <p style={{ marginTop: "10px", color: "#166534", fontSize: "12px", lineHeight: "1.5" }}>
                          ✓ Hệ thống sẽ tạo mã VietQR chuẩn theo ngân hàng &amp; số tài khoản bạn chọn. Khi bấm &quot;Xác nhận đặt hàng&quot;, mã QR sẽ hiển thị kèm nút báo tín hiệu đã thanh toán.
                        </p>
                      </div>
                    )}
                  </div>
                </label>
              </div>
            </fieldset>

            <aside className="min-w-0 m-0 static md:sticky md:top-24 p-[18px_22px] sm:p-[23px] lg:p-[26px] border border-border rounded-2xl sm:rounded-[20px] bg-white shadow-[0_8px_30px_#1d1d1f03]">
              <div className="flex flex-wrap gap-x-4 gap-y-2.5 items-center justify-between mb-6">
                <h2 className="text-base font-semibold leading-normal">
                  Tóm tắt đơn hàng
                </h2>
                <Link href="/cart" className="text-brand text-[11px] no-underline hover:underline hover:underline-offset-[3px]">
                  Chỉnh sửa giỏ
                </Link>
              </div>

              <div className="grid gap-5 max-h-[350px] overflow-y-auto pt-0.5 pr-1.5 pb-6 mb-6 border-b border-border">
                {items.map((it) => (
                  <div key={it.cartItemId} className="grid grid-cols-[56px_minmax(0,1fr)] gap-x-3.5 gap-y-1.5 items-start">
                    <div className="row-span-2 w-14 h-14 rounded-[10px] overflow-hidden relative bg-[#f7f7f9] border border-[#eeeeef]">
                      {it.imageUrl ? (
                        <Image
                          src={it.imageUrl}
                          alt={it.productName}
                          fill
                          sizes="52px"
                          className="object-contain p-[3px] pointer-events-none"
                        />
                      ) : (
                        <div className="w-full h-full bg-[#eee]" />
                      )}
                      <span className="absolute top-0.5 right-0.5 flex items-center justify-center min-w-[17px] min-h-[17px] px-1 rounded-[9px] bg-ink text-white text-[9px] font-semibold pointer-events-none">{it.quantity}</span>
                    </div>

                    <div className="min-w-0 [overflow-wrap:anywhere]">
                      <div className="text-xs font-semibold leading-[1.65]">{it.productName}</div>
                      <div className="mt-1 text-muted text-[11px] leading-[1.6]">{it.variantName}</div>
                    </div>

                    <div className="col-start-2 text-[13px] font-semibold leading-[1.6] tabular-nums [overflow-wrap:anywhere]">
                      {formatPrice(it.price * it.quantity)}
                    </div>
                  </div>
                ))}
              </div>

              <div className="grid gap-3.5 mb-[18px]">
                <div className="grid grid-cols-2 gap-x-4 gap-y-2.5 items-start text-[#63636b] text-xs leading-[1.7] [&>span]:min-w-0 [&>span]:[overflow-wrap:anywhere] [&>span:last-child]:text-right [&>span:last-child]:tabular-nums [&>span:last-child]:text-ink">
                  <span>Tạm tính ({items.length} món)</span>
                  <span>{formatPrice(totalPrice)}</span>
                </div>

                {discountAmount > 0 && (
                  <div className="grid grid-cols-2 gap-x-4 gap-y-2.5 items-start text-[#dc2626] text-xs leading-[1.7] [&>span]:min-w-0 [&>span]:[overflow-wrap:anywhere] [&>span:last-child]:text-right [&>span:last-child]:tabular-nums">
                    <span>Voucher ({appliedVoucher?.code})</span>
                    <span>-{formatPrice(discountAmount)}</span>
                  </div>
                )}

                <div className="grid grid-cols-2 gap-x-4 gap-y-2.5 items-start text-[#63636b] text-xs leading-[1.7] [&>span]:min-w-0 [&>span]:[overflow-wrap:anywhere] [&>span:last-child]:text-right [&>span:last-child]:tabular-nums [&>span:last-child]:text-ink">
                  <span>Phí vận chuyển</span>
                  <span>
                    {shippingFee === 0 ? (
                      <span className="text-muted">
                        Chưa tính phí
                      </span>
                    ) : (
                      formatPrice(shippingFee)
                    )}
                  </span>
                </div>

                <div className="grid gap-1.5 pt-5 mt-1.5 border-t border-border">
                  <span className="text-muted text-xs">Tổng thanh toán</span>
                  <span className="text-ink text-[clamp(26px,2.4vw,32px)] font-semibold tracking-[-0.035em] leading-[1.3] tabular-nums [overflow-wrap:anywhere]">
                    {formatPrice(grandTotal)}
                  </span>
                </div>
              </div>

              <p className="mb-5 text-muted text-[11px] leading-[1.7]">Phí vận chuyển chưa được hệ thống tính trong tổng tiền này.</p>
              <button
                type="submit"
                disabled={isSubmitting || busy || !!cartError}
                className="flex items-center justify-center gap-2.5 w-full min-h-[50px] px-[18px] py-3.5 border-0 rounded-[10px] bg-brand text-white text-[13px] font-semibold cursor-pointer hover:enabled:bg-brand-hover hover:enabled:-translate-y-px disabled:cursor-not-allowed disabled:opacity-65 transition-all duration-[180ms]"
              >
                {isSubmitting && <span className="shrink-0 w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" aria-hidden="true" />}
                {isSubmitting ? "Đang xác nhận đơn…" : "Xác nhận đặt hàng"}
              </button>

              <p
                className={cn(
                  "text-[#63636b] text-[11px] leading-[1.65]",
                  isSubmitting && "mt-3.5"
                )}
                role="status"
                aria-live="polite"
              >
                {isSubmitting ? "Đang gửi đơn đến hệ thống. Vui lòng chờ và không đóng trang." : ""}
              </p>

              <p className="mt-4 text-muted text-[10px] leading-[1.75]">
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

export default function CheckoutPage() {
  return (
    <Suspense
      fallback={
        <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
          <div className="max-w-[1200px] mx-auto min-w-0" role="status">
            <p>Đang tải trang thanh toán…</p>
          </div>
        </main>
      }
    >
      <CheckoutContent />
    </Suspense>
  );
}

