"use client";

import Image from "next/image";
import Link from "next/link";
import { useState, useEffect, type MouseEvent } from "react";
import { formatPrice, fetchProductById } from "@/lib/products-client";
import { ProductBaseDto } from "@/lib/types/product";
import { useCart } from "@/lib/context/CartContext";
import { cn } from "@/lib/utils";

interface ProductCardProps {
  product: ProductBaseDto;
}

export default function ProductCard({ product }: ProductCardProps) {
  const [imageError, setImageError] = useState(false);
  const [isAdding, setIsAdding] = useState(false);
  const [addedSuccess, setAddedSuccess] = useState(false);
  const { addItem } = useCart();
  const isOutOfStock = product.totalStock <= 0;
  const promo =
    product.promotion && product.promotion.hasPromotion
      ? product.promotion
      : null;

  // Lưu URL trang hiện tại và ID sản phẩm để khi bấm "Tiếp tục mua sắm" có thể quay về đúng vị trí
  const handleCardClick = () => {
    if (typeof window !== "undefined") {
      // Chỉ cập nhật trang danh sách mua sắm nếu trang hiện tại KHÔNG PHẢI là trang chi tiết sản phẩm /products/:id
      const isDetailPage = /^\/products\/\d+/.test(window.location.pathname);
      if (!isDetailPage) {
        sessionStorage.setItem(
          "techstoree_last_product_page",
          window.location.href
        );
      }
      sessionStorage.setItem(
        "techstoree_last_product_id",
        String(product.productId)
      );
    }
  };

  // Tự động cuộn đến sản phẩm này nếu khách hàng vừa quay lại từ trang chi tiết sản phẩm
  useEffect(() => {
    if (typeof window === "undefined") return;
    const scrollTarget = sessionStorage.getItem("techstoree_scroll_target");
    if (scrollTarget && Number(scrollTarget) === product.productId) {
      sessionStorage.removeItem("techstoree_scroll_target");

      const timer = setTimeout(() => {
        const el = document.getElementById(`product-card-${product.productId}`);
        if (el) {
          el.scrollIntoView({ behavior: "smooth", block: "center" });
          el.classList.add(
            "ring-4",
            "ring-brand/50",
            "shadow-xl",
            "transition-all",
            "duration-500"
          );
          setTimeout(() => {
            el.classList.remove("ring-4", "ring-brand/50", "shadow-xl");
          }, 2200);
        }
      }, 200);

      return () => clearTimeout(timer);
    }
  }, [product.productId]);

  // Thêm nhanh vào giỏ hàng trực tiếp từ Card sản phẩm
  const handleQuickAddToCart = async (e: MouseEvent<HTMLButtonElement>) => {
    e.preventDefault();
    e.stopPropagation();

    if (isOutOfStock || isAdding) return;

    setIsAdding(true);
    try {
      // Tải chi tiết sản phẩm để lấy danh sách biến thể
      const detail = await fetchProductById(product.productId);
      if (!detail || !detail.variants || detail.variants.length === 0) {
        throw new Error("Không tìm thấy biến thể của sản phẩm.");
      }

      // Chọn biến thể đầu tiên còn hàng hoặc biến thể đầu tiên
      const defaultVariant =
        detail.variants.find((v) => v.isActive && v.stockQuantity > 0) ||
        detail.variants[0];

      const variantPromo =
        defaultVariant.promotion && defaultVariant.promotion.hasPromotion
          ? defaultVariant.promotion
          : null;
      const unitPrice =
        variantPromo && variantPromo.promotionalPrice != null
          ? variantPromo.promotionalPrice
          : defaultVariant.price;

      // Thực hiện thêm thẳng vào giỏ hàng (không bật popup CartDrawer)
      const ok = await addItem(
        {
          productId: product.productId,
          productName: product.productName,
          variantId: defaultVariant.variantId,
          variantName: defaultVariant.variantName,
          attributes: defaultVariant.attributes || {},
          price: unitPrice,
          imageUrl: defaultVariant.imageUrl || product.imageUrl,
          stockQuantity: defaultVariant.stockQuantity,
        },
        1,
        false // Thêm thẳng vào giỏ hàng luôn
      );

      if (ok) {
        setAddedSuccess(true);
        setTimeout(() => setAddedSuccess(false), 2200);
      }
    } catch (err) {
      console.error("Lỗi khi thêm nhanh vào giỏ hàng:", err);
    } finally {
      setIsAdding(false);
    }
  };

  // Hiển thị giá thấp nhất theo yêu cầu
  const displayOriginalPrice = () => {
    return formatPrice(product.minPrice);
  };

  const displayPromotionalPrice = () => {
    if (!promo) return null;
    return formatPrice(promo.promotionalMinPrice);
  };

  const discountBadgeText = () => {
    if (!promo) return null;
    if (promo.discountType === "PERCENTAGE" && promo.discountValue) {
      return `-${promo.discountValue}%`;
    }
    if (promo.discountValue) {
      return `-${formatPrice(promo.discountValue)}`;
    }
    return "GIẢM GIÁ";
  };

  return (
    <div
      id={`product-card-${product.productId}`}
      className="group flex flex-col bg-white border border-neutral-200 rounded-2xl overflow-hidden text-inherit transition-all duration-300 ease-out relative hover:-translate-y-1 hover:shadow-lg hover:border-neutral-300"
    >
      {/* Backdrop link: Bấm vào bất kỳ đâu trên card để xem chi tiết */}
      <Link
        href={`/products/${product.productId}`}
        onClick={handleCardClick}
        className="absolute inset-0 z-0"
        aria-label={`Xem chi tiết ${product.productName}`}
      />

      {/* Vùng hình ảnh sản phẩm */}
      <div className="relative w-full aspect-[4/3] bg-[#f7f7f7] overflow-hidden pointer-events-none">
        {product.imageUrl && !imageError ? (
          <Image
            src={product.imageUrl}
            alt={product.productName}
            fill
            className="object-contain p-5 transition-transform duration-300 ease-out text-transparent group-hover:scale-105"
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
            onError={() => setImageError(true)}
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center bg-[#f7f7f7]">
            <svg
              width="44"
              height="44"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#cccccc"
              strokeWidth="1.2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <rect x="2" y="3" width="20" height="14" rx="2" ry="2" />
              <line x1="8" y1="21" x2="16" y2="21" />
              <line x1="12" y1="17" x2="12" y2="21" />
            </svg>
          </div>
        )}

        {promo && (
          <span className="absolute top-3 right-3 bg-[linear-gradient(135deg,#e52d27_0%,#b31217_100%)] text-white px-2.5 py-1 rounded text-xs font-bold tracking-wide shadow-[0_2px_8px_rgba(189,32,45,0.35)] z-10 pointer-events-none">
            {discountBadgeText()}
          </span>
        )}
        {isOutOfStock && (
          <span className="absolute top-3 right-3 bg-black/75 text-white px-2.5 py-1 rounded text-xs font-semibold tracking-wide z-10 pointer-events-none">
            Tạm hết
          </span>
        )}
      </div>

      {/* Vùng thông tin sản phẩm */}
      <div className="p-5 flex flex-col flex-1 justify-between relative z-10 pointer-events-none">
        <div>
          <span className="text-xs uppercase tracking-wider text-neutral-500 mb-1.5 font-medium block">
            {product.categoryName}
          </span>
          <h3 className="text-base sm:text-lg font-semibold text-neutral-900 m-0 mb-3 leading-snug line-clamp-2">
            {product.productName}
          </h3>
        </div>

        <div className="mt-auto pt-3 border-t border-neutral-100 flex flex-col">
          <div className="flex items-end justify-between gap-3 flex-wrap">
            <div className="flex flex-col gap-0.5 min-w-0">
              <span className="text-xs text-neutral-400 uppercase">
                {promo ? "Giá ưu đãi" : "Giá bán"}
              </span>
              {promo ? (
                <div className="flex items-baseline gap-2 flex-wrap">
                  <span className="text-lg font-bold text-brand tracking-tight">
                    {displayPromotionalPrice()}
                  </span>
                  <span className="text-xs text-neutral-400 line-through font-normal">
                    {displayOriginalPrice()}
                  </span>
                </div>
              ) : (
                <span className="text-base font-bold text-neutral-900 tracking-tight">
                  {displayOriginalPrice()}
                </span>
              )}
            </div>

            <span className="text-xs font-semibold text-brand flex items-center gap-1 transition-transform duration-150 group-hover:translate-x-1">
              Chi tiết &rarr;
            </span>
          </div>

          {/* Nút Thêm vào giỏ hàng xuất hiện khi đưa chuột vào (hover) */}
          <div className="overflow-hidden transition-all duration-300 ease-out max-h-0 opacity-0 group-hover:max-h-14 group-hover:opacity-100 group-hover:mt-3 max-sm:max-h-14 max-sm:opacity-100 max-sm:mt-3">
            <button
              type="button"
              disabled={isOutOfStock || isAdding}
              onClick={handleQuickAddToCart}
              className={cn(
                "pointer-events-auto w-full py-2.5 px-4 rounded-xl text-xs sm:text-sm font-semibold flex items-center justify-center gap-2 transition-all duration-200 shadow-sm cursor-pointer",
                addedSuccess
                  ? "!bg-emerald-600 !text-white !border-emerald-600"
                  : isOutOfStock
                    ? "bg-neutral-100 text-neutral-400 border border-neutral-200 cursor-not-allowed"
                    : "bg-neutral-900 text-white hover:bg-brand hover:shadow-md active:scale-[0.98]"
              )}
              aria-label={`Thêm ${product.productName} vào giỏ hàng`}
            >
              {addedSuccess ? (
                <>
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <polyline points="20 6 9 17 4 12" />
                  </svg>
                  <span>Đã thêm vào giỏ!</span>
                </>
              ) : isAdding ? (
                <>
                  <svg
                    className="animate-spin"
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                  >
                    <circle
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      strokeOpacity="0.25"
                      fill="none"
                    />
                    <path
                      d="M12 2a10 10 0 0 1 10 10"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      fill="none"
                    />
                  </svg>
                  <span>Đang thêm...</span>
                </>
              ) : (
                <>
                  <svg
                    width="16"
                    height="16"
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
                    {isOutOfStock ? "Tạm hết hàng" : "Thêm vào giỏ hàng"}
                  </span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
