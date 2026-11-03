"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useCart } from "@/lib/context/CartContext";
import { formatPrice } from "@/lib/products-client";
import { cn } from "@/lib/utils";

export default function CartPage() {
  const router = useRouter();
  const {
    items,
    totalItems,
    totalPrice,
    appliedVoucher,
    discountAmount,
    finalPrice,
    busy,
    error: cartError,
    updateQuantity,
    removeItem,
    clearCart,
    applyVoucher,
    removeVoucher,
  } = useCart();

  const [voucherCode, setVoucherCode] = useState("");
  const [voucherMsg, setVoucherMsg] = useState<{
    text: string;
    isError: boolean;
  } | null>(null);

  const handleApplyVoucher = async (codeToApply?: string) => {
    const code = (codeToApply || voucherCode).trim();
    if (!code) {
      setVoucherMsg({ text: "Vui lòng nhập mã voucher.", isError: true });
      return;
    }
    const res = await applyVoucher(code);
    setVoucherMsg({ text: res.message, isError: !res.success });
    if (res.success) {
      setVoucherCode("");
    }
  };

  const handleProceedToCheckout = () => {
    router.push("/checkout");
  };

  if (items.length === 0) {
    return (
      <main className="min-h-[calc(100vh-68px)] bg-[#fbfbfb] py-10 px-6 pb-20">
        <div className="max-w-[1200px] mx-auto">
          <div className="bg-white border border-[#ebebeb] rounded-xl py-20 px-6 text-center flex flex-col items-center gap-4">
            <svg
              className="w-16 h-16 text-[#cccccc]"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
            >
              <circle cx="8" cy="21" r="1" />
              <circle cx="19" cy="21" r="1" />
              <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12" />
            </svg>
            <h1 className="text-[1.4rem] font-semibold text-[#111111]">
              Giỏ hàng của bạn đang trống
            </h1>
            <p className="text-[#777777] max-w-[440px] text-[0.95rem]">
              Chưa có sản phẩm nào trong giỏ hàng. Hãy khám phá danh mục sản phẩm công nghệ tinh tuyển của chúng tôi để chọn món đồ yêu thích.
            </p>
            <Link
              href="/products"
              className="bg-[#111111] text-white no-underline py-3.5 px-7 rounded-md text-[0.95rem] font-medium transition-colors hover:bg-[#333333] mt-2"
            >
              Khám phá sản phẩm ngay
            </Link>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-[calc(100vh-68px)] bg-[#fbfbfb] py-10 px-6 pb-20">
      <div className="max-w-[1200px] mx-auto">
        <div className="mb-8">
          <h1 className="font-inherit text-[2.2rem] font-bold text-[#111111] mb-2">
            Giỏ Hàng Mua Sắm
          </h1>
          <p className="text-muted text-[0.95rem]">
            Bạn đang có <strong>{totalItems}</strong> sản phẩm trong giỏ hàng.
          </p>
        </div>

        <div className="grid grid-cols-[1fr_380px] gap-9 items-start max-[960px]:grid-cols-1">
          <section
            className="bg-white border border-[#ebebeb] rounded-xl p-6"
            aria-label="Danh sách sản phẩm"
          >
            <div className="grid grid-cols-[2fr_1fr_1fr_1fr_auto] gap-4 pb-4 border-b border-[#eeeeee] text-[0.8rem] font-semibold text-[#888888] uppercase tracking-[0.05em] max-[960px]:hidden">
              <span>Sản phẩm</span>
              <span>Đơn giá</span>
              <span>Số lượng</span>
              <span>Thành tiền</span>
              <span aria-hidden="true" />
            </div>

            {items.map((item) => (
              <div
                key={item.cartItemId}
                className="grid grid-cols-[2fr_1fr_1fr_1fr_auto] gap-4 items-center py-5 border-b border-[#f2f2f2] last:border-b-0 max-[960px]:grid-cols-1 max-[960px]:gap-3"
              >
                <div className="flex items-center gap-4">
                  <div className="w-[72px] h-[72px] bg-[#f7f7f7] rounded-lg overflow-hidden relative shrink-0 border border-[#eeeeee]">
                    {item.imageUrl ? (
                      <Image
                        src={item.imageUrl}
                        alt={item.productName}
                        fill
                        className="object-cover"
                        sizes="72px"
                      />
                    ) : (
                      <div className="w-full h-full bg-[#f7f7f7]" />
                    )}
                  </div>
                  <div className="flex flex-col gap-1">
                    <Link
                      href={`/products/${item.productId}`}
                      className="text-[0.95rem] font-semibold text-[#111111] no-underline leading-tight hover:text-brand"
                    >
                      {item.productName}
                    </Link>
                    <span className="text-[0.82rem] text-muted">
                      {item.variantName ||
                        Object.values(item.attributes).join(" · ")}
                    </span>
                  </div>
                </div>

                <div className="text-[0.92rem] text-[#444444] font-medium max-[960px]:before:content-['Đơn_giá:_'] max-[960px]:before:text-[#888888]">
                  {formatPrice(item.price)}
                </div>

                <div>
                  <div className="inline-flex items-center border border-[#d5d5d5] rounded-md bg-white">
                    <button
                      type="button"
                      className="bg-transparent border-none w-7 h-7 flex items-center justify-center cursor-pointer text-sm text-[#333333] transition-colors hover:enabled:bg-gray-100 disabled:text-[#cccccc] disabled:cursor-not-allowed"
                      disabled={busy}
                      onClick={() =>
                        updateQuantity(item.cartItemId, item.quantity - 1)
                      }
                      aria-label="Giảm số lượng"
                    >
                      -
                    </button>
                    <input
                      type="number"
                      className="w-[38px] h-7 text-center text-[0.88rem] font-semibold border-none bg-transparent text-[#111111] outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                      value={item.quantity}
                      min={1}
                      max={item.stockQuantity}
                      disabled={busy}
                      onChange={(e) => {
                        const val = parseInt(e.target.value, 10);
                        if (!isNaN(val) && val >= 1) {
                          updateQuantity(
                            item.cartItemId,
                            Math.min(val, item.stockQuantity),
                          );
                        }
                      }}
                      aria-label="Số lượng"
                    />
                    <button
                      type="button"
                      className="bg-transparent border-none w-7 h-7 flex items-center justify-center cursor-pointer text-sm text-[#333333] transition-colors hover:enabled:bg-gray-100 disabled:text-[#cccccc] disabled:cursor-not-allowed"
                      disabled={busy || item.quantity >= item.stockQuantity}
                      onClick={() =>
                        updateQuantity(item.cartItemId, item.quantity + 1)
                      }
                      aria-label="Tăng số lượng"
                    >
                      +
                    </button>
                  </div>
                </div>

                <div className="text-base font-bold text-[#111111] max-[960px]:before:content-['Thành_tiền:_'] max-[960px]:before:text-[#888888] max-[960px]:before:text-[0.85rem] max-[960px]:before:font-normal">
                  {formatPrice(item.price * item.quantity)}
                </div>

                <div>
                  <button
                    type="button"
                    className="bg-transparent border-none text-[#999999] cursor-pointer p-1.5 rounded transition-colors hover:text-[#ff3b30]"
                    disabled={busy || !!cartError}
                    onClick={() => removeItem(item.cartItemId)}
                    aria-label={`Xóa ${item.productName}`}
                  >
                    <svg
                      width="18"
                      height="18"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                    >
                      <path d="M3 6h18" />
                      <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" />
                      <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" />
                    </svg>
                  </button>
                </div>
              </div>
            ))}

            <div className="flex justify-between items-center mt-6 pt-5 border-t border-[#eeeeee]">
              <Link
                href="/products"
                className="text-[#555555] no-underline text-[0.9rem] font-medium flex items-center gap-1.5 hover:text-[#111111]"
              >
                &larr; Tiếp tục mua sắm
              </Link>
              <button
                type="button"
                className="bg-transparent border-none text-[#888888] text-[0.88rem] cursor-pointer hover:text-[#ff3b30] hover:underline"
                disabled={busy}
                onClick={clearCart}
              >
                Xóa toàn bộ giỏ hàng
              </button>
            </div>
          </section>

          <aside
            className="bg-white border border-[#ebebeb] rounded-xl p-6 sticky top-[100px]"
            aria-label="Tóm tắt đơn hàng"
          >
            <h2 className="text-[1.2rem] font-semibold text-[#111111] mb-5">
              Tóm Tắt Đơn Hàng
            </h2>

            <div className="mb-5 pb-5 border-b border-[#eeeeee]">
              <label htmlFor="voucherInput" className="text-[0.85rem] font-semibold text-[#333333] mb-2 block">
                MÃ GIẢM GIÁ / VOUCHER
              </label>

              {appliedVoucher ? (
                <div className="bg-emerald-50 border border-emerald-200 text-emerald-800 p-2.5 sm:px-3 rounded-md flex items-center justify-between text-[0.85rem]">
                  <div>
                    <strong>{appliedVoucher.code}</strong>: -
                    {formatPrice(discountAmount)}
                  </div>
                  <button
                    type="button"
                    className="bg-transparent border-none text-red-600 text-[0.8rem] font-semibold cursor-pointer py-0.5 px-1"
                    onClick={removeVoucher}
                  >
                    Hủy mã ✕
                  </button>
                </div>
              ) : (
                <>
                  <div className="flex gap-2 mb-2">
                    <input
                      id="voucherInput"
                      type="text"
                      className="flex-1 py-2.5 px-3 border border-[#d5d5d5] rounded-md text-[0.88rem] uppercase outline-none focus:border-brand"
                      placeholder="Nhập mã voucher (VD: TECH100)"
                      value={voucherCode}
                      onChange={(e) => {
                        setVoucherCode(e.target.value);
                        setVoucherMsg(null);
                      }}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          e.preventDefault();
                          handleApplyVoucher();
                        }
                      }}
                    />
                    <button
                      type="button"
                      className="bg-[#111111] text-white border-none px-4 rounded-md text-[0.85rem] font-semibold cursor-pointer whitespace-nowrap hover:bg-[#333333]"
                      onClick={() => handleApplyVoucher()}
                    >
                      Áp dụng
                    </button>
                  </div>

                  {voucherMsg && (
                    <p
                      className={cn(
                        "text-[0.8rem] mt-1.5",
                        voucherMsg.isError ? "text-red-600" : "text-emerald-600"
                      )}
                    >
                      {voucherMsg.text}
                    </p>
                  )}
                </>
              )}
            </div>

            <div className="flex flex-col gap-3.5 pb-5 border-b border-[#eeeeee] mb-5">
              <div className="flex justify-between items-center text-[0.92rem] text-[#555555]">
                <span>Tổng tiền hàng ({totalItems} sản phẩm)</span>
                <span>{formatPrice(totalPrice)}</span>
              </div>
              {discountAmount > 0 && (
                <div className="flex justify-between items-center text-[0.92rem] text-red-600 font-semibold">
                  <span>Giảm giá ({appliedVoucher?.code})</span>
                  <span>-{formatPrice(discountAmount)}</span>
                </div>
              )}
              <div className="flex justify-between items-center text-[0.92rem] text-[#555555]">
                <span>Vận chuyển tiêu chuẩn</span>
                <span className="text-[#0b8a36] font-semibold">Chưa tính phí</span>
              </div>
            </div>

            <div className="flex justify-between items-baseline mb-6">
              <span className="text-[1.05rem] font-semibold text-[#111111]">
                Tổng thanh toán
              </span>
              <span className="text-[1.6rem] font-bold text-[#111111] tracking-[-0.02em]">
                {formatPrice(finalPrice)}
              </span>
            </div>

            <button
              type="button"
              className="w-full bg-brand text-white border-none p-4 rounded-lg text-base font-semibold cursor-pointer transition-colors hover:bg-brandHover flex items-center justify-center gap-2"
              disabled={busy}
              onClick={handleProceedToCheckout}
            >
              Tiến hành đặt hàng
            </button>
          </aside>
        </div>
      </div>
    </main>
  );
}
