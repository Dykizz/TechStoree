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

interface MyVoucherItem {
  userVoucherId: number;
  voucherId: number;
  code: string;
  title: string;
  description?: string | null;
  discountType: "PERCENTAGE" | "FIXED_AMOUNT";
  discountValue: number;
  minOrderValue: number;
  maxDiscountAmount?: number | null;
  startDate: string;
  endDate: string;
  assignedType?: string;
  isUsed: boolean;
  isUsable: boolean;
}

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
    applyVoucher,
    removeVoucher,
  } = useCart();
  const { mutateAsync: checkoutOrderMutation } = useCheckoutOrder();

  const [myVouchers, setMyVouchers] = useState<MyVoucherItem[]>([]);
  const [loadingVouchers, setLoadingVouchers] = useState(false);
  const [voucherInput, setVoucherInput] = useState("");
  const [voucherError, setVoucherError] = useState("");
  const [applyingVoucher, setApplyingVoucher] = useState(false);

  const [recipientName, setRecipientName] = useState("");
  const [recipientPhone, setRecipientPhone] = useState("");
  const [province, setProvince] = useState("TP. Hồ Chí Minh");
  const [shippingAddress, setShippingAddress] = useState("");
  const [note, setNote] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("COD");
  const [selectedBankBin, setSelectedBankBin] = useState<string>(
    process.env.NEXT_PUBLIC_BANK_BIN || "970422",
  );
  const [bankAccount] = useState<string>(
    process.env.NEXT_PUBLIC_BANK_ACCOUNT || "0372933562",
  );
  const [bankAccountName] = useState<string>(
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

  // Tải thông tin đơn hàng nếu có orderId hoặc orderCode trên URL
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

  const shippingFee = 0;
  const grandTotal = finalPrice + shippingFee;

  // Load My Vouchers from customer wallet
  useEffect(() => {
    if (session.status !== "ready") return;
    let active = true;

    async function loadMyVouchers() {
      setLoadingVouchers(true);
      try {
        const res = await fetch("/api/vouchers/my-wallet?status=USABLE", {
          cache: "no-store",
        });
        if (!active) return;
        const result = await res.json();
        if (res.ok && result.success && Array.isArray(result.data)) {
          setMyVouchers(result.data);
        }
      } catch {
        // Silently continue
      } finally {
        if (active) setLoadingVouchers(false);
      }
    }

    void loadMyVouchers();

    return () => {
      active = false;
    };
  }, [session.status]);

  const handleApplyVoucherCode = async (code: string) => {
    if (!code.trim() || applyingVoucher) return;
    setApplyingVoucher(true);
    setVoucherError("");
    try {
      const res = await applyVoucher(code.trim());
      if (!res.success) {
        setVoucherError(res.message);
      } else {
        setVoucherInput("");
      }
    } catch {
      setVoucherError("Không thể áp dụng mã giảm giá.");
    } finally {
      setApplyingVoucher(false);
    }
  };

  const handleRemoveVoucher = () => {
    removeVoucher();
    setVoucherError("");
  };

  // Auto-fill logged in user info
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
  const [syncedProfile, setSyncedProfile] = useState<typeof userProfile | null>(null);
  if (userProfile && userProfile !== syncedProfile) {
    setSyncedProfile(userProfile);
    if (userProfile.fullName || userProfile.username) {
      setRecipientName((prev) => prev || userProfile.fullName || userProfile.username);
    }
    if (userProfile.phone) {
      setRecipientPhone((prev) => prev || userProfile.phone?.trim() || "");
    }
    if (userProfile.address) {
      setShippingAddress((prev) => prev || userProfile.address?.trim() || "");
    }
  }

  const validate = () => {
    const errs: Record<string, string> = {};
    if (!recipientName.trim()) {
      errs.recipientName = "Vui lòng nhập họ tên người nhận";
    }
    if (!recipientPhone.trim()) {
      errs.recipientPhone = "Vui lòng nhập số điện thoại";
    } else if (!/^(0[3|5|7|8|9])+([0-9]{8})$/.test(recipientPhone.trim())) {
      errs.recipientPhone = "Số điện thoại không đúng định dạng VN (10 số)";
    }
    if (!shippingAddress.trim()) {
      errs.shippingAddress = "Vui lòng nhập địa chỉ giao hàng";
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    if (items.length === 0) return;
    if (submitting.current) return;

    submitting.current = true;
    setIsSubmitting(true);

    try {
      const fullAddress = `${shippingAddress.trim()}, ${province}`;
      const backendCartIds = items
        .map((item) => Number(item.backendCartItemId))
        .filter((id) => !Number.isNaN(id) && id > 0);

      let formattedNotes = note.trim();
      if (paymentMethod === "BANKING") {
        const bankTag = `[VIETQR | ${activeBank.shortName} - STK: ${bankAccount.trim()} - ${bankAccountName.trim().toUpperCase()}]`;
        formattedNotes = formattedNotes ? `${bankTag} ${formattedNotes}` : bankTag;
      }

      const backendOrder = await checkoutOrderMutation({
        receiverName: recipientName.trim(),
        receiverPhone: recipientPhone.replace(/[\s.-]/g, ""),
        shippingAddress: fullAddress,
        notes: formattedNotes ? formattedNotes.slice(0, 500) : undefined,
        paymentMethod: paymentMethod === "BANKING" ? "BANK_TRANSFER" : "COD",
        voucherCode: appliedVoucher?.code || undefined,
        cartItemIds: backendCartIds,
      });

      const order = mapOrder(backendOrder);
      setCreatedOrder(order);

      if (session.status === "ready") {
        publishNotification(session.user.userId, {
          id: `order-placed:${order.orderId}`,
          kind: "order",
          title: "Đặt hàng thành công",
          message: `Đơn hàng ${order.orderCode} đã được tạo với tổng giá trị ${formatPrice(order.totalAmount)}.`,
          href: "/orders",
        });
      }

      await refreshCart();
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Đã có lỗi xảy ra");
    } finally {
      submitting.current = false;
      setIsSubmitting(false);
    }
  };

  if (loadingOrder) {
    return (
      <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
        <div className="max-w-[1200px] mx-auto min-w-0" role="status">
          <p>Đang tải thông tin đơn hàng…</p>
        </div>
      </main>
    );
  }

  if (orderError) {
    return (
      <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
        <div className="max-w-[1200px] mx-auto min-w-0" role="alert">
          <p className="text-[#a11929]">{orderError}</p>
          <Link href="/orders" className="text-brand text-xs hover:underline">
            ← Quay lại danh sách đơn hàng
          </Link>
        </div>
      </main>
    );
  }

  if (createdOrder) {
    return (
      <OrderConfirmation
        order={createdOrder}
        customBank={{
          bin: activeBank.bin,
          name: activeBank.name,
          account: bankAccount,
          accountName: bankAccountName,
        }}
      />
    );
  }

  if (items.length === 0) {
    return (
      <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
        <div className="max-w-[1200px] mx-auto min-w-0">
          <div className="mb-8 max-w-[720px]">
            <Link href="/cart" className="inline-block mb-6 text-muted text-xs hover:text-brand transition-colors">
              ← Quay lại giỏ hàng
            </Link>
            <h1 className="my-3 mb-3.5 text-[clamp(28px,3.2vw,42px)] font-semibold tracking-[-0.045em] leading-[1.16]">
              Giỏ hàng trống
            </h1>
            <p className="text-muted text-sm leading-[1.75]">
              Bạn chưa có sản phẩm nào trong giỏ để thực hiện thanh toán.
            </p>
            <Link
              href="/products"
              className="inline-block mt-5 px-5 py-3 rounded-lg bg-ink text-white text-xs font-semibold hover:bg-brand transition-colors"
            >
              Tiếp tục mua sắm
            </Link>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-[calc(100vh-68px)] px-4 py-[26px] pb-[52px] sm:px-6 sm:py-11 sm:pb-20 bg-[#f5f5f7] text-ink leading-[1.55]">
      <div className="max-w-[1200px] mx-auto min-w-0">
        <div className="mb-8 max-w-[720px]">
          <Link href="/cart" className="inline-block mb-6 text-muted text-xs hover:text-brand transition-colors">
            ← Quay lại giỏ hàng
          </Link>
          <span className="text-brand text-[10px] font-bold tracking-[.13em] leading-[1.7] uppercase block">QUY TRÌNH MUA SẮM</span>
          <h1 className="my-3 mb-3.5 text-[clamp(28px,3.2vw,42px)] font-semibold tracking-[-0.045em] leading-[1.16]">
            Thanh toán an toàn
          </h1>
          <p className="text-muted text-sm leading-[1.75]">
            Vui lòng điền địa chỉ nhận hàng và chọn phương thức thanh toán phù
            hợp.
          </p>
        </div>

        <form onSubmit={handleSubmit}>
          <div
            className={cn(
              "grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_minmax(320px,400px)] gap-7 items-start transition-all duration-[220ms]",
              isSubmitting && "opacity-70 translate-y-0.5"
            )}
          >
            {/* Form Section */}
            <div className="min-w-0 m-0 p-[30px] border border-border rounded-[20px] bg-white shadow-[0_8px_30px_#1d1d1f03]">
              <div className="flex gap-3 items-center mb-6 text-base font-semibold leading-normal">
                <span className="inline-flex flex-none w-7 h-7 items-center justify-center rounded-full bg-[#f3f3f5] text-ink text-xs font-semibold">1</span>
                <span>Thông tin giao hàng</span>
              </div>

              <div className="grid gap-[22px] mb-9">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-[18px] items-start">
                  <div className="flex flex-col gap-2.5 min-w-0">
                    <label className="text-[#424245] text-xs font-semibold leading-normal" htmlFor="recipientName">
                      Họ và tên <span className="text-brand">*</span>
                    </label>
                    <input
                      id="recipientName"
                      type="text"
                      disabled={isSubmitting}
                      placeholder="Nguyễn Văn A"
                      value={recipientName}
                      onChange={(e) => {
                        setRecipientName(e.target.value);
                        if (errors.recipientName) {
                          setErrors((prev) => ({ ...prev, recipientName: "" }));
                        }
                      }}
                      className={cn(
                        "w-full min-w-0 p-[13px_14px] min-h-[49px] border rounded-[10px] bg-white text-ink text-sm leading-normal transition-colors placeholder:text-[#909098] focus:border-brand focus:ring-1 focus:ring-brand outline-none",
                        errors.recipientName ? "border-brand" : "border-[#dedee2]"
                      )}
                    />
                    {errors.recipientName && (
                      <span className="text-[#a11929] text-xs leading-relaxed" role="alert">
                        {errors.recipientName}
                      </span>
                    )}
                  </div>

                  <div className="flex flex-col gap-2.5 min-w-0">
                    <label className="text-[#424245] text-xs font-semibold leading-normal" htmlFor="recipientPhone">
                      Số điện thoại <span className="text-brand">*</span>
                    </label>
                    <input
                      id="recipientPhone"
                      type="tel"
                      disabled={isSubmitting}
                      placeholder="0901234567"
                      value={recipientPhone}
                      onChange={(e) => {
                        setRecipientPhone(e.target.value);
                        if (errors.recipientPhone) {
                          setErrors((prev) => ({ ...prev, recipientPhone: "" }));
                        }
                      }}
                      className={cn(
                        "w-full min-w-0 p-[13px_14px] min-h-[49px] border rounded-[10px] bg-white text-ink text-sm leading-normal transition-colors placeholder:text-[#909098] focus:border-brand focus:ring-1 focus:ring-brand outline-none",
                        errors.recipientPhone ? "border-brand" : "border-[#dedee2]"
                      )}
                    />
                    {errors.recipientPhone && (
                      <span className="text-[#a11929] text-xs leading-relaxed" role="alert">
                        {errors.recipientPhone}
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex flex-col gap-2.5 min-w-0">
                  <label className="text-[#424245] text-xs font-semibold leading-normal" htmlFor="province">
                    Tỉnh / Thành phố <span className="text-brand">*</span>
                  </label>
                  <select
                    id="province"
                    disabled={isSubmitting}
                    value={province}
                    onChange={(e) => setProvince(e.target.value)}
                    className="w-full min-w-0 p-[13px_14px] min-h-[49px] border border-[#dedee2] rounded-[10px] bg-white text-ink text-sm leading-normal transition-colors outline-none focus:border-brand focus:ring-1 focus:ring-brand"
                  >
                    {PROVINCES.map((p) => (
                      <option key={p} value={p}>
                        {p}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex flex-col gap-2.5 min-w-0">
                  <label className="text-[#424245] text-xs font-semibold leading-normal" htmlFor="shippingAddress">
                    Địa chỉ chi tiết (Số nhà, ngõ/tổ, đường, phường/xã){" "}
                    <span className="text-brand">*</span>
                  </label>
                  <input
                    id="shippingAddress"
                    type="text"
                    disabled={isSubmitting}
                    placeholder="Số 123 đường ABC, Phường X, Quận Y"
                    value={shippingAddress}
                    onChange={(e) => {
                      setShippingAddress(e.target.value);
                      if (errors.shippingAddress) {
                        setErrors((prev) => ({ ...prev, shippingAddress: "" }));
                      }
                    }}
                    className={cn(
                      "w-full min-w-0 p-[13px_14px] min-h-[49px] border rounded-[10px] bg-white text-ink text-sm leading-normal transition-colors placeholder:text-[#909098] focus:border-brand focus:ring-1 focus:ring-brand outline-none",
                      errors.shippingAddress ? "border-brand" : "border-[#dedee2]"
                    )}
                  />
                  {errors.shippingAddress && (
                    <span className="text-[#a11929] text-xs leading-relaxed" role="alert">
                      {errors.shippingAddress}
                    </span>
                  )}
                </div>

                <div className="flex flex-col gap-2.5 min-w-0">
                  <label className="text-[#424245] text-xs font-semibold leading-normal" htmlFor="note">Ghi chú đơn hàng (Tùy chọn)</label>
                  <textarea
                    id="note"
                    disabled={isSubmitting}
                    placeholder="Lời dặn riêng: Giao giờ hành chính, gọi trước khi giao..."
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                    className="w-full min-w-0 p-[13px_14px] min-h-[98px] resize-y border border-[#dedee2] rounded-[10px] bg-white text-ink text-sm leading-normal transition-colors placeholder:text-[#909098] focus:border-brand focus:ring-1 focus:ring-brand outline-none"
                  />
                </div>
              </div>

              <div className="flex gap-3 items-center mb-6 text-base font-semibold leading-normal">
                <span className="inline-flex flex-none w-7 h-7 items-center justify-center rounded-full bg-[#f3f3f5] text-ink text-xs font-semibold">2</span>
                <span>Phương thức thanh toán</span>
              </div>

              <div className="grid gap-3.5">
                <label
                  className={cn(
                    "flex items-start gap-3.5 p-[18px] border rounded-[13px] cursor-pointer transition-colors",
                    paymentMethod === "COD"
                      ? "border-brand bg-[#fff8f8]"
                      : "border-border hover:border-[#c4c4c9]"
                  )}
                >
                  <input
                    type="radio"
                    name="paymentMethod"
                    value="COD"
                    disabled={isSubmitting}
                    checked={paymentMethod === "COD"}
                    onChange={() => setPaymentMethod("COD")}
                    className="flex-none w-4 h-4 mt-1 accent-brand"
                  />
                  <div className="min-w-0 flex-1">
                    <div className="text-[13px] font-semibold leading-[1.6]">
                      Thanh toán khi nhận hàng (COD)
                    </div>
                    <div className="mt-1.5 text-muted text-xs leading-[1.75]">
                      Bạn kiểm tra hàng và thanh toán tiền mặt trực tiếp cho nhân
                      viên giao hàng khi nhận được gói bọc bảo mật.
                    </div>
                  </div>
                </label>

                <label
                  className={cn(
                    "flex items-start gap-3.5 p-[18px] border rounded-[13px] cursor-pointer transition-colors",
                    paymentMethod === "BANKING"
                      ? "border-brand bg-[#fff8f8]"
                      : "border-border hover:border-[#c4c4c9]"
                  )}
                >
                  <input
                    type="radio"
                    name="paymentMethod"
                    value="BANKING"
                    disabled={isSubmitting}
                    checked={paymentMethod === "BANKING"}
                    onChange={() => setPaymentMethod("BANKING")}
                    className="flex-none w-4 h-4 mt-1 accent-brand"
                  />
                  <div className="min-w-0 flex-1">
                    <div className="text-[13px] font-semibold leading-[1.6]">
                      Chuyển khoản liên ngân hàng (VietQR - Tự động duyệt)
                    </div>
                    <div className="mt-1.5 text-muted text-xs leading-[1.75]">
                      Hệ thống tạo mã QR động đúng số tiền và nội dung đơn. Bạn
                      chỉ cần quét qua app ngân hàng bất kỳ để hoàn tất nhanh
                      chóng.
                    </div>

                    {paymentMethod === "BANKING" && (
                      <div className="grid gap-2.5 mt-4 p-3.5 border border-border rounded-[9px] bg-white text-[#53535a] text-xs [overflow-wrap:anywhere]">
                        <div className="flex flex-col gap-1.5">
                          <label className="text-[#424245] text-xs font-semibold leading-normal" htmlFor="bankSelect">
                            Chọn ngân hàng thụ hưởng nhận tiền:
                          </label>
                          <select
                            id="bankSelect"
                            value={selectedBankBin}
                            onChange={(e) => setSelectedBankBin(e.target.value)}
                            className="w-full min-w-0 p-[13px_14px] min-h-[49px] border border-[#dedee2] rounded-[10px] bg-white text-ink text-sm leading-normal transition-colors outline-none focus:border-brand focus:ring-1 focus:ring-brand"
                          >
                            {SUPPORTED_BANKS.map((b) => (
                              <option key={b.bin} value={b.bin}>
                                {b.name}
                              </option>
                            ))}
                          </select>
                        </div>
                        <p className="m-0 leading-[1.7]">
                          <strong>Số tài khoản:</strong> {bankAccount}
                        </p>
                        <p className="m-0 leading-[1.7]">
                          <strong>Chủ tài khoản:</strong> {bankAccountName}
                        </p>
                        <p className="m-0 leading-[1.7]">
                          <strong>Ngân hàng:</strong> {activeBank.name}
                        </p>
                        <span className="text-muted text-[11px] leading-[1.6]">
                          * Mã QR chính thức kèm mã giao dịch sẽ hiển thị ngay
                          sau khi bạn bấm &ldquo;Xác nhận đặt hàng&rdquo;.
                        </span>
                      </div>
                    )}
                  </div>
                </label>
              </div>
            </div>

            {/* Summary Section */}
            <aside className="min-w-0 m-0 p-[26px] border border-border rounded-[20px] bg-white shadow-[0_8px_30px_#1d1d1f03] sticky top-24">
              <div className="flex flex-wrap gap-2.5 items-center justify-between mb-6">
                <h2 className="text-base font-semibold leading-normal m-0">Tóm tắt đơn hàng</h2>
                <Link href="/cart" className="text-brand text-[11px] no-underline hover:underline hover:underline-offset-2">
                  Sửa giỏ hàng
                </Link>
              </div>

              <div className="grid gap-5 max-h-[350px] overflow-y-auto pt-0.5 pb-6 mb-6 border-b border-border">
                {items.map((it) => (
                  <div className="grid grid-cols-[56px_minmax(0,1fr)] gap-x-3.5 gap-y-1 items-start" key={it.cartItemId}>
                    <div className="row-span-2 w-14 h-14 rounded-[10px] overflow-hidden relative bg-[#f7f7f9] border border-[#eeeeef]">
                      {it.imageUrl ? (
                        <Image
                          src={it.imageUrl}
                          alt={it.productName}
                          fill
                          sizes="56px"
                          className="object-contain p-[3px] pointer-events-none"
                        />
                      ) : (
                        <div className="w-full h-full bg-[#eeeeee]" />
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

              {/* MỤC LỰA CHỌN MÃ GIẢM GIÁ: MÃ GIẢM GIÁ CỦA TÔI */}
              <div className="mb-5 p-4 border border-dashed border-neutral-300 rounded-xl bg-neutral-50/70">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="m-0 flex items-center gap-1.5 text-[13px] font-bold text-ink">
                    <span aria-hidden="true">🏷️</span> Mã giảm giá của tôi
                  </h3>
                  {appliedVoucher && (
                    <button
                      type="button"
                      onClick={handleRemoveVoucher}
                      className="bg-transparent border-0 text-[#dc2626] text-xs font-semibold cursor-pointer hover:underline"
                    >
                      Gỡ bỏ
                    </button>
                  )}
                </div>

                {appliedVoucher && (
                  <div className="p-2.5 mb-3 bg-red-50 border border-red-200 rounded-lg flex items-center justify-between text-xs">
                    <div className="flex items-center gap-2">
                      <span className="bg-brand text-white px-1.5 py-0.5 rounded text-[10px] font-bold">Đang dùng</span>
                      <span className="font-mono font-bold text-brand">{appliedVoucher.code}</span>
                      <span className="font-semibold text-brand">
                        (-{formatPrice(discountAmount)})
                      </span>
                    </div>
                  </div>
                )}

                {voucherError && (
                  <p className="text-[#dc2626] text-xs mb-3 font-medium" role="alert">
                    {voucherError}
                  </p>
                )}

                {loadingVouchers ? (
                  <p className="text-muted text-xs my-2">Đang tải mã giảm giá của bạn…</p>
                ) : myVouchers.length > 0 ? (
                  <div className="flex flex-col gap-2.5 max-h-[220px] overflow-y-auto mb-3 pr-1">
                    {myVouchers.map((voucher) => {
                      const isApplied = appliedVoucher?.code === voucher.code;
                      const isEligible = totalPrice >= (voucher.minOrderValue || 0);
                      const isSurveyReward = voucher.assignedType === "SURVEY_REWARD";

                      return (
                        <div
                          key={voucher.userVoucherId || voucher.code}
                          className={cn(
                            "flex items-center justify-between p-2.5 bg-white border rounded-lg text-xs transition-colors",
                            isApplied
                              ? "border-brand bg-red-50/30"
                              : !isEligible
                                ? "opacity-60 bg-neutral-50 border-neutral-200"
                                : "border-neutral-200 hover:border-neutral-300"
                          )}
                        >
                          <div className="min-w-0 flex-1 pr-2">
                            <div className="flex items-center gap-1.5 mb-1">
                              <span className="font-mono font-bold text-ink px-1.5 py-0.5 bg-neutral-100 rounded text-[11px]">{voucher.code}</span>
                              {isSurveyReward && (
                                <span className="bg-amber-100 text-amber-800 text-[10px] font-semibold px-1.5 py-0.5 rounded">
                                  🎁 Thưởng khảo sát
                                </span>
                              )}
                            </div>
                            <div className="font-medium text-neutral-800 truncate">{voucher.title}</div>
                            {voucher.minOrderValue > 0 && (
                              <div className="text-[11px] text-muted mt-0.5">
                                Đơn tối thiểu: {formatPrice(voucher.minOrderValue)}
                                {!isEligible && (
                                  <span className="text-red-500 font-medium"> (chưa đủ ĐK)</span>
                                )}
                              </div>
                            )}
                          </div>

                          <div className="shrink-0">
                            {isApplied ? (
                              <button
                                type="button"
                                onClick={handleRemoveVoucher}
                                className="px-2.5 py-1 rounded bg-neutral-200 text-neutral-700 font-medium cursor-pointer"
                                disabled={applyingVoucher}
                              >
                                Đang áp dụng ✓
                              </button>
                            ) : (
                              <button
                                type="button"
                                onClick={() => void handleApplyVoucherCode(voucher.code)}
                                className={cn(
                                  "px-2.5 py-1 rounded font-semibold transition-colors cursor-pointer",
                                  isEligible
                                    ? "bg-brand text-white hover:bg-brand-hover"
                                    : "bg-neutral-100 text-neutral-400 cursor-not-allowed"
                                )}
                                disabled={!isEligible || applyingVoucher}
                              >
                                {isEligible ? "Áp dụng" : "Chưa đủ ĐK"}
                              </button>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="text-center py-3 bg-white border border-neutral-200 rounded-lg text-xs mb-3">
                    <p className="text-muted m-0">Bạn chưa có mã giảm giá nào trong ví.</p>
                    <Link href="/surveys" className="text-brand font-semibold hover:underline block mt-1">
                      Hoàn thành khảo sát để nhận mã ưu đãi ↗
                    </Link>
                  </div>
                )}

                {/* Ô nhập mã giảm giá thủ công */}
                <div className="flex gap-2">
                  <input
                    type="text"
                    placeholder="Nhập mã ưu đãi khác..."
                    value={voucherInput}
                    onChange={(e) => {
                      setVoucherInput(e.target.value.toUpperCase());
                      if (voucherError) setVoucherError("");
                    }}
                    className="flex-1 min-w-0 px-3 py-1.5 border border-neutral-300 rounded-lg text-xs uppercase outline-none focus:border-brand"
                  />
                  <button
                    type="button"
                    onClick={() => void handleApplyVoucherCode(voucherInput)}
                    disabled={!voucherInput.trim() || applyingVoucher}
                    className="px-3 py-1.5 rounded-lg bg-neutral-900 text-white text-xs font-semibold hover:bg-black disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
                  >
                    Áp dụng
                  </button>
                </div>
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
