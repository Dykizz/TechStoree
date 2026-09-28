import Image from "next/image";
import Link from "next/link";
import { formatPrice } from "../../lib/products-client";
import { ProductBaseDto } from "../../lib/types/product";
import styles from "./ProductCard.module.css";

interface ProductCardProps {
  product: ProductBaseDto;
}

export default function ProductCard({ product }: ProductCardProps) {
  const isOutOfStock = product.totalStock <= 0;
  const promo = product.promotion && product.promotion.hasPromotion ? product.promotion : null;

  const displayOriginalPrice = () => {
    if (product.minPrice === product.maxPrice) {
      return formatPrice(product.minPrice);
    }
    return `${formatPrice(product.minPrice)} – ${formatPrice(product.maxPrice)}`;
  };

  const displayPromotionalPrice = () => {
    if (!promo) return null;
    if (promo.promotionalMinPrice === promo.promotionalMaxPrice) {
      return formatPrice(promo.promotionalMinPrice);
    }
    return `${formatPrice(promo.promotionalMinPrice)} – ${formatPrice(promo.promotionalMaxPrice)}`;
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
        {product.imageUrl ? (
          <Image
            src={product.imageUrl}
            alt={product.productName}
            fill
            className={styles.image}
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
          />
        ) : (
          <div className={styles.image} />
        )}

        <span className={styles.badge}>{product.categoryName}</span>
        {promo && <span className={styles.saleBadge}>{discountBadgeText()}</span>}
        {isOutOfStock && <span className={styles.outOfStockBadge}>Tạm hết</span>}
      </div>

      <div className={styles.content}>
        <div>
          <span className={styles.category}>{product.categoryName}</span>
          <h3 className={styles.title}>{product.productName}</h3>
        </div>

        <div className={styles.footer}>
          <div className={styles.priceWrapper}>
            <span className={styles.priceLabel}>{promo ? "Giá ưu đãi" : "Giá từ"}</span>
            {promo ? (
              <div className={styles.priceRow}>
                <span className={styles.promoPrice}>{displayPromotionalPrice()}</span>
                <span className={styles.originalPrice}>{displayOriginalPrice()}</span>
              </div>
            ) : (
              <span className={styles.price}>{displayOriginalPrice()}</span>
            )}
          </div>

          <span className={styles.viewDetails}>
            Chi tiết &rarr;
          </span>
        </div>
      </div>
    </Link>
  );
}
