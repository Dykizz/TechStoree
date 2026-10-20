import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import { formatPrice } from "../../lib/products-client";
import { ProductBaseDto } from "../../lib/types/product";
import styles from "./ProductCard.module.css";

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
      className={styles.card}
      aria-label={`Xem chi tiết ${product.productName}`}
    >
      <div className={styles.imageContainer}>
        {product.imageUrl && !imageError ? (
          <Image
            src={product.imageUrl}
            alt={product.productName}
            fill
            className={styles.image}
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
            onError={() => setImageError(true)}
          />
        ) : (
          <div className={styles.placeholderWrap}>
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
          <span className={styles.saleBadge}>{discountBadgeText()}</span>
        )}
        {isOutOfStock && (
          <span className={styles.outOfStockBadge}>Tạm hết</span>
        )}
      </div>

      <div className={styles.content}>
        <div>
          <span className={styles.category}>{product.categoryName}</span>
          <h3 className={styles.title}>{product.productName}</h3>
        </div>

        <div className={styles.footer}>
          <div className={styles.priceWrapper}>
            <span className={styles.priceLabel}>
              {promo ? "Giá ưu đãi" : "Giá bán"}
            </span>
            {promo ? (
              <div className={styles.priceRow}>
                <span className={styles.promoPrice}>
                  {displayPromotionalPrice()}
                </span>
                <span className={styles.originalPrice}>
                  {displayOriginalPrice()}
                </span>
              </div>
            ) : (
              <span className={styles.price}>{displayOriginalPrice()}</span>
            )}
          </div>

          <span className={styles.viewDetails}>Chi tiết &rarr;</span>
        </div>
      </div>
    </Link>
  );
}
