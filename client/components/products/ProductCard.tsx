import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import { formatPrice } from "@/lib/products-client";
import { ProductBaseDto } from "@/lib/types/product";

interface ProductCardProps {
  product: ProductBaseDto;
}

export default function ProductCard({ product }: ProductCardProps) {
  const [imageError, setImageError] = useState(false);
  const isOutOfStock = product.totalStock <= 0;
  const promo =
    product.promotion && product.promotion.hasPromotion
      ? product.promotion
      : null;

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
    <Link
      href={`/products/${product.productId}`}
      className="group flex flex-col bg-white border border-neutral-200 rounded-2xl overflow-hidden no-underline text-inherit transition-all duration-200 ease-out relative hover:-translate-y-1 hover:shadow-lg hover:border-neutral-300 focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-4"
      aria-label={`Xem chi tiết ${product.productName}`}
    >
      <div className="relative w-full aspect-[4/3] bg-[#f7f7f7] overflow-hidden">
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
          <span className="absolute top-3 right-3 bg-[linear-gradient(135deg,#e52d27_0%,#b31217_100%)] text-white px-2.5 py-1 rounded text-xs font-bold tracking-wide shadow-[0_2px_8px_rgba(189,32,45,0.35)] z-10">
            {discountBadgeText()}
          </span>
        )}
        {isOutOfStock && (
          <span className="absolute top-3 right-3 bg-black/75 text-white px-2.5 py-1 rounded text-xs font-semibold tracking-wide z-10">
            Tạm hết
          </span>
        )}
      </div>

      <div className="p-5 flex flex-col flex-1 justify-between">
        <div>
          <span className="text-xs uppercase tracking-wider text-neutral-500 mb-1.5 font-medium block">
            {product.categoryName}
          </span>
          <h3 className="text-base sm:text-lg font-semibold text-neutral-900 m-0 mb-3 leading-snug line-clamp-2">
            {product.productName}
          </h3>
        </div>

        <div className="flex items-end justify-between gap-3 flex-wrap mt-auto pt-3 border-t border-neutral-100">
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
      </div>
    </Link>
  );
}
