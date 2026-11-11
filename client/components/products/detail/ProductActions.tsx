"use client";

import { useRouter } from "next/navigation";
import { formatPrice } from "@/lib/products-client";
import type {
  ProductDetailDto,
  ProductVariantDto,
} from "@/lib/types/product";
import VariantSelector from "@/components/products/VariantSelector";
import ProductReviews from "@/components/reviews/ProductReviews";
import { cn } from "@/lib/utils";

interface ProductActionsProps {
  product: ProductDetailDto;
  selectedVariant: ProductVariantDto | null;
  quantity: number;
  addedSuccess: boolean;
  busy: boolean;
  onVariantChange: (variant: ProductVariantDto | null) => void;
  onAttributesChange: (attrs: Record<string, string>) => void;
  onQuantityChange: (qty: number) => void;
  onAddToCart: () => void;
  onBuyNow: () => void;
  onContinueShopping?: () => void;
}

export default function ProductActions({
  product,
  selectedVariant,
  quantity,
  addedSuccess,
  onVariantChange,
  onAttributesChange,
  onQuantityChange,
  onAddToCart,
  onBuyNow,
  onContinueShopping,
}: ProductActionsProps) {
  const router = useRouter();

  // Xử lý quay về trang trước đó và đúng vị trí sản phẩm vừa xem
  const handleContinueShopping = () => {
    if (onContinueShopping) {
      onContinueShopping();
      return;
    }

    if (typeof window !== "undefined") {
      sessionStorage.setItem(
        "techstoree_scroll_target",
        String(product.productId)
      );

      const lastPage = sessionStorage.getItem("techstoree_last_product_page");
      if (lastPage) {
        try {
          const parsedUrl = new URL(lastPage, window.location.origin);
          // Đảm bảo không điều hướng về một trang chi tiết sản phẩm /products/:id khác
          if (!/^\/products\/\d+/.test(parsedUrl.pathname)) {
            router.push(lastPage);
            return;
          }
        } catch {
          // ignore
        }
      }

      if (window.history.length > 1) {
        router.back();
        return;
      }
    }

    router.push("/products");
  };
  const variantPromo =
    selectedVariant?.promotion && selectedVariant.promotion.hasPromotion
      ? selectedVariant.promotion
      : null;
  const productPromo =
    product.promotion && product.promotion.hasPromotion
      ? product.promotion
      : null;

  const hasPromotion = Boolean(
    variantPromo || (!selectedVariant && productPromo)
  );
  const activePromoName =
    variantPromo?.promotionName || productPromo?.promotionName;

  const originalPrice = selectedVariant
    ? selectedVariant.price
    : product.minPrice;
  const promotionalPrice = variantPromo
    ? variantPromo.promotionalPrice
    : !selectedVariant && productPromo
      ? productPromo.promotionalMinPrice
      : null;

  const currentPrice = promotionalPrice ?? originalPrice;
  const currentStock = selectedVariant
    ? selectedVariant.stockQuantity
    : product.totalStock;
  const isOutOfStock = currentStock <= 0;

  return (
    <div className="flex flex-col">
      <span className="text-[0.8rem] tracking-[0.1em] uppercase text-brand font-semibold mb-2 block">{product.categoryName}</span>
      <h1 className="text-[1.8rem] lg:text-[2.2rem] font-bold text-[#111111] leading-[1.25] mb-4">{product.productName}</h1>

      <div className="flex flex-col gap-3 py-4 border-y border-[#f0f0f0] mb-6">
        <div className="flex items-baseline gap-3.5 flex-wrap">
          <span
            className={cn(
              "text-[1.85rem] font-bold tracking-[-0.02em]",
              hasPromotion ? "text-[#bd202d]" : "text-[#111111]"
            )}
          >
            {!selectedVariant && product.minPrice !== product.maxPrice
              ? `${formatPrice(product.minPrice)} – ${formatPrice(product.maxPrice)}`
              : formatPrice(currentPrice)}
          </span>
          {hasPromotion &&
            promotionalPrice !== null &&
            originalPrice > promotionalPrice && (
              <span className="text-[1.15rem] text-[#999999] line-through font-normal">
                {formatPrice(originalPrice)}
              </span>
            )}
          {variantPromo && (
            <span className="bg-[linear-gradient(135deg,#e52d27_0%,#b31217_100%)] text-white px-2.5 py-1 rounded text-[0.8rem] font-bold tracking-[0.04em] shadow-[0_2px_8px_rgba(189,32,45,0.3)]">
              {variantPromo.discountType === "PERCENTAGE" &&
              variantPromo.discountValue
                ? `-${variantPromo.discountValue}%`
                : variantPromo.discountAmount
                  ? `Tiết kiệm ${formatPrice(variantPromo.discountAmount)}`
                  : "ƯU ĐÃI"}
            </span>
          )}
          {!selectedVariant &&
            productPromo &&
            productPromo.discountValue && (
              <span className="bg-[linear-gradient(135deg,#e52d27_0%,#b31217_100%)] text-white px-2.5 py-1 rounded text-[0.8rem] font-bold tracking-[0.04em] shadow-[0_2px_8px_rgba(189,32,45,0.3)]">
                {productPromo.discountType === "PERCENTAGE"
                  ? `-${productPromo.discountValue}%`
                  : "ƯU ĐÃI"}
              </span>
            )}
        </div>

        {hasPromotion && activePromoName && (
          <div className="flex items-center gap-2 px-3.5 py-2.5 bg-[#fff5f5] border border-[#ffd0d0] rounded-md text-[0.85rem] text-[#a71822]">
            <span className="text-base">⚡</span>
            <span className="[&>strong]:text-[#8c1018]">
              <strong>{activePromoName}</strong> &bull; Đã áp dụng giảm
              giá trực tiếp vào sản phẩm
            </span>
          </div>
        )}

        <div className="text-[0.88rem] font-medium flex items-center gap-1.5">
          <span
            className={cn(
              "w-2 h-2 rounded-full inline-block",
              isOutOfStock ? "bg-[#d93025]" : "bg-[#0b8a36]"
            )}
          />
          <span
            className={cn(isOutOfStock ? "text-[#d93025]" : "text-[#0b8a36]")}
          >
            {isOutOfStock
              ? "Tạm hết hàng"
              : !selectedVariant
                ? `Còn hàng (Tổng ${currentStock} sản phẩm)`
                : `Còn hàng (${currentStock} sản phẩm)`}
          </span>
        </div>
      </div>

      {(product.variantAttributes.length > 0 ||
        product.variants.length > 1) && (
        <div className="mb-7">
          <VariantSelector
            attributes={product.variantAttributes}
            variants={product.variants}
            selectedVariant={selectedVariant}
            onVariantChange={onVariantChange}
            onAttributesChange={onAttributesChange}
          />
        </div>
      )}

      <div className="flex items-center gap-4 mb-8 flex-wrap">
        <span className="text-[0.88rem] font-semibold text-[#222222]">Số lượng:</span>
        <div
          className={cn(
            "flex items-center border rounded-md overflow-hidden",
            !selectedVariant
              ? "bg-[#f7f7f8] border-[#e5e5e5] cursor-not-allowed [&_.qty-display]:text-[#999999]"
              : "bg-white border-[#d5d5d5]"
          )}
        >
          <button
            type="button"
            className="bg-transparent border-0 w-9 h-9 flex items-center justify-center text-[1.1rem] cursor-pointer text-[#333333] hover:enabled:bg-[#f0f0f0] disabled:text-[#cccccc] disabled:cursor-not-allowed transition-colors duration-150"
            disabled={!selectedVariant || quantity <= 1 || isOutOfStock}
            onClick={() => onQuantityChange(Math.max(quantity - 1, 1))}
            aria-label="Giảm số lượng"
          >
            -
          </button>
          <span className="qty-display w-11 text-center text-[0.95rem] font-semibold">
            {!selectedVariant ? "-" : quantity}
          </span>
          <button
            type="button"
            className="bg-transparent border-0 w-9 h-9 flex items-center justify-center text-[1.1rem] cursor-pointer text-[#333333] hover:enabled:bg-[#f0f0f0] disabled:text-[#cccccc] disabled:cursor-not-allowed transition-colors duration-150"
            disabled={
              !selectedVariant ||
              quantity >= currentStock ||
              isOutOfStock
            }
            onClick={() =>
              onQuantityChange(Math.min(quantity + 1, currentStock))
            }
            aria-label="Tăng số lượng"
          >
            +
          </button>
        </div>
        {!selectedVariant && (
          <span className="text-[0.82rem] text-[#e11d48] font-medium flex items-center gap-1">
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            Vui lòng chọn biến thể / màu sắc trước khi chọn số lượng
          </span>
        )}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 mb-9">
        <button
          type="button"
          className={cn(
            "border-2 px-5 py-3.5 rounded-lg text-[0.95rem] font-semibold flex items-center justify-center gap-2 transition-all duration-200 cursor-pointer",
            addedSuccess
              ? "!bg-[#16a34a] !border-[#16a34a] !text-white"
              : "bg-white border-[#111111] text-[#111111] hover:enabled:bg-[#111111] hover:enabled:text-white disabled:border-[#cccccc] disabled:text-[#cccccc] disabled:cursor-not-allowed"
          )}
          disabled={isOutOfStock || !selectedVariant}
          onClick={onAddToCart}
          title={!selectedVariant ? "Vui lòng chọn biến thể / màu sắc" : ""}
        >
          {addedSuccess ? (
            <>
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="20 6 9 17 4 12" />
              </svg>
              <span>Đã thêm vào giỏ hàng!</span>
            </>
          ) : (
            <>
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
                <path d="M3 6h18" />
                <path d="M16 10a4 4 0 0 1-8 0" />
              </svg>
              <span>
                {!selectedVariant
                  ? "Vui lòng chọn biến thể"
                  : isOutOfStock
                    ? "Tạm hết hàng"
                    : "Thêm vào giỏ"}
              </span>
            </>
          )}
        </button>

        <button
          type="button"
          className="px-5 py-3.5 rounded-lg text-[0.95rem] font-semibold cursor-pointer border-2 border-brand bg-brand text-white hover:enabled:bg-brand-hover hover:enabled:border-brand-hover disabled:bg-[#eeeeee] disabled:border-[#eeeeee] disabled:text-[#aaaaaa] disabled:cursor-not-allowed transition-all duration-200"
          disabled={isOutOfStock || !selectedVariant}
          onClick={onBuyNow}
          title={!selectedVariant ? "Vui lòng chọn biến thể / màu sắc" : ""}
        >
          {!selectedVariant ? "Chọn biến thể để mua" : "Mua ngay"}
        </button>
      </div>

      {/* Nút Tiếp tục mua sắm - Quay lại trang trước đó và đúng vị trí sản phẩm */}
      <button
        type="button"
        onClick={handleContinueShopping}
        className="w-full -mt-5 mb-8 py-3.5 px-5 rounded-lg border-2 border-neutral-300 bg-white text-neutral-800 hover:bg-neutral-50 hover:border-neutral-900 hover:text-neutral-950 font-semibold text-[0.95rem] flex items-center justify-center gap-2.5 transition-all duration-200 shadow-sm cursor-pointer group/back active:scale-[0.99]"
        title="Quay lại trang trước và vị trí sản phẩm vừa xem"
      >
        <svg
          className="text-neutral-600 group-hover/back:text-brand transition-colors duration-200"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <circle cx="8" cy="21" r="1" />
          <circle cx="19" cy="21" r="1" />
          <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12" />
        </svg>
        <span>Tiếp tục mua sắm</span>
      </button>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 p-5 bg-[#f9f9f9] rounded-lg mb-8">
        <div className="flex items-center gap-2.5 text-[0.85rem] text-[#444444]">
          <svg
            className="text-brand shrink-0"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8" />
            <path d="M21 3v5h-5" />
            <path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16" />
            <path d="M8 16H3v5" />
          </svg>
          <span>Đổi mới 30 ngày nếu có lỗi kỹ thuật</span>
        </div>
        <div className="flex items-center gap-2.5 text-[0.85rem] text-[#444444]">
          <svg
            className="text-brand shrink-0"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10" />
          </svg>
          <span>Cam kết 100% nguyên bản & chính hãng</span>
        </div>
      </div>

      {product.description && (
        <div className="border-t border-[#eeeeee] pt-6 mb-8">
          <h2 className="text-[1.1rem] font-semibold text-[#111111] mb-3">Tổng quan sản phẩm</h2>
          <p className="text-[0.95rem] leading-[1.7] text-[#555555]">{product.description}</p>
        </div>
      )}

      <div className="border-t border-[#eeeeee] pt-8">
        <ProductReviews key={product.productId} productId={product.productId} />
      </div>
    </div>
  );
}
