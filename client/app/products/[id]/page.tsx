"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { use, useEffect, useState } from "react";
import VariantSelector from "../../../components/products/VariantSelector";
import { useCart } from "../../../lib/context/CartContext";
import { addProductReview, getProductReviews } from "../../../lib/order-client";
import { fetchProductById, formatPrice } from "../../../lib/products-client";
import { ProductReview } from "../../../lib/types/order";
import { ProductDetailDto, ProductVariantDto } from "../../../lib/types/product";
import styles from "./product-detail.module.css";

export default function ProductDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = use(params);
  const productId = parseInt(resolvedParams.id, 10);
  const router = useRouter();
  const { addItem } = useCart();

  const [product, setProduct] = useState<ProductDetailDto | null>(null);
  const [selectedVariant, setSelectedVariant] = useState<ProductVariantDto | null>(null);
  const [quantity, setQuantity] = useState(1);
  const [loading, setLoading] = useState(true);

  // Reviews state
  const [reviews, setReviews] = useState<ProductReview[]>([]);
  const [reviewName, setReviewName] = useState("");
  const [reviewRating, setReviewRating] = useState(5);
  const [reviewComment, setReviewComment] = useState("");
  const [reviewSuccess, setReviewSuccess] = useState("");

  useEffect(() => {
    async function loadProduct() {
      setLoading(true);
      const data = await fetchProductById(productId);
      setProduct(data);
      if (data && data.variants && data.variants.length > 0) {
        const initial = data.variants.find((v) => v.stockQuantity > 0) || data.variants[0];
        setSelectedVariant(initial);
      }
      setLoading(false);
    }
    void loadProduct();

    // Load reviews
    const timer = setTimeout(() => {
      setReviews(getProductReviews(productId));
    }, 0);

    // Prefill username if logged in
    fetch("/api/auth/session")
      .then((r) => r.json())
      .then((d) => {
        if (d && d.user) {
          setReviewName(d.user.fullName || d.user.username);
        }
      })
      .catch(() => {});

    return () => clearTimeout(timer);
  }, [productId]);

  const handleReviewSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!reviewName.trim() || !reviewComment.trim()) return;

    const newRev = addProductReview({
      productId,
      userName: reviewName.trim(),
      rating: reviewRating,
      comment: reviewComment.trim(),
    });

    setReviews((prev) => [newRev, ...prev]);
    setReviewComment("");
    setReviewSuccess("Cảm ơn bạn! Đánh giá của bạn đã được ghi nhận.");
    setTimeout(() => setReviewSuccess(""), 4000);
  };

  if (loading) {
    return (
      <main className={styles.main}>
        <div className={styles.container}>
          <div style={{ textAlign: "center", padding: "100px 0", color: "#666" }}>
            Đang tải thông tin sản phẩm…
          </div>
        </div>
      </main>
    );
  }

  if (!product) {
    return (
      <main className={styles.main}>
        <div className={`${styles.container} ${styles.notFound}`}>
          <h2>Không tìm thấy sản phẩm</h2>
          <p>Sản phẩm này có thể đã ngừng kinh doanh hoặc đường dẫn không đúng.</p>
          <Link href="/products" className={styles.backBtn}>
            &larr; Xem tất cả sản phẩm
          </Link>
        </div>
      </main>
    );
  }

  const variantPromo = selectedVariant?.promotion && selectedVariant.promotion.hasPromotion
    ? selectedVariant.promotion
    : null;
  const productPromo = product.promotion && product.promotion.hasPromotion
    ? product.promotion
    : null;

  const hasPromotion = Boolean(variantPromo || (!selectedVariant && productPromo));
  const activePromoName = variantPromo?.promotionName || productPromo?.promotionName;

  const originalPrice = selectedVariant ? selectedVariant.price : product.minPrice;
  const promotionalPrice = variantPromo
    ? variantPromo.promotionalPrice
    : productPromo
    ? productPromo.promotionalMinPrice
    : null;

  const currentPrice = promotionalPrice ?? originalPrice;
  const currentStock = selectedVariant ? selectedVariant.stockQuantity : product.totalStock;
  const isOutOfStock = currentStock <= 0;
  const activeImage = (selectedVariant && selectedVariant.imageUrl) || product.imageUrl;

  const handleAddToCart = () => {
    if (!selectedVariant || isOutOfStock) return;

    addItem(
      {
        productId: product.productId,
        productName: product.productName,
        variantId: selectedVariant.variantId,
        variantName: selectedVariant.variantName,
        attributes: selectedVariant.attributes,
        price: currentPrice,
        imageUrl: activeImage,
        stockQuantity: selectedVariant.stockQuantity,
      },
      quantity
    );
  };

  const handleBuyNow = () => {
    if (!selectedVariant || isOutOfStock) return;
    handleAddToCart();
    router.push("/cart");
  };

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <nav className={styles.breadcrumbs} aria-label="Breadcrumb">
          <Link href="/">Trang chủ</Link>
          <span>/</span>
          <Link href="/products">Sản phẩm</Link>
          <span>/</span>
          <Link href={`/products?categoryId=${product.categoryId}`}>
            {product.categoryName}
          </Link>
          <span>/</span>
          <span style={{ color: "#111", fontWeight: 500 }}>
            {product.productName}
          </span>
        </nav>

        <div className={styles.productLayout}>
          <div className={styles.gallery}>
            <div className={styles.mainImageWrap}>
              {activeImage ? (
                <Image
                  src={activeImage}
                  alt={product.productName}
                  fill
                  priority
                  className={styles.mainImage}
                  sizes="(max-width: 900px) 100vw, 50vw"
                />
              ) : (
                <div className={styles.mainImage} />
              )}
            </div>
          </div>

          <div className={styles.details}>
            <span className={styles.categoryTag}>{product.categoryName}</span>
            <h1 className={styles.title}>{product.productName}</h1>

            <div className={styles.priceBlock}>
              <div className={styles.priceGroup}>
                <span className={`${styles.price} ${hasPromotion ? styles.pricePromo : ""}`}>
                  {formatPrice(currentPrice)}
                </span>
                {hasPromotion && promotionalPrice !== null && originalPrice > promotionalPrice && (
                  <span className={styles.originalPrice}>{formatPrice(originalPrice)}</span>
                )}
                {variantPromo && (
                  <span className={styles.promoBadge}>
                    {variantPromo.discountType === "PERCENTAGE" && variantPromo.discountValue
                      ? `-${variantPromo.discountValue}%`
                      : variantPromo.discountAmount
                      ? `Tiết kiệm ${formatPrice(variantPromo.discountAmount)}`
                      : "ƯU ĐÃI"}
                  </span>
                )}
                {!selectedVariant && productPromo && productPromo.discountValue && (
                  <span className={styles.promoBadge}>
                    {productPromo.discountType === "PERCENTAGE"
                      ? `-${productPromo.discountValue}%`
                      : "ƯU ĐÃI"}
                  </span>
                )}
              </div>

              {hasPromotion && activePromoName && (
                <div className={styles.promoBanner}>
                  <span className={styles.promoIcon}>⚡</span>
                  <span className={styles.promoText}>
                    <strong>{activePromoName}</strong> &bull; Đã áp dụng giảm giá trực tiếp vào sản phẩm
                  </span>
                </div>
              )}

              <div className={styles.stockStatus}>
                <span
                  className={`${styles.dot} ${
                    isOutOfStock ? styles.dotOutOfStock : styles.dotInStock
                  }`}
                />
                <span
                  className={isOutOfStock ? styles.outOfStock : styles.inStock}
                >
                  {isOutOfStock
                    ? "Tạm hết hàng"
                    : `Còn hàng (${currentStock} sản phẩm)`}
                </span>
              </div>
            </div>

            {product.variantAttributes.length > 0 && (
              <div className={styles.variantsSection}>
                <VariantSelector
                  attributes={product.variantAttributes}
                  variants={product.variants}
                  selectedVariant={selectedVariant}
                  onVariantChange={(variant) => {
                    setSelectedVariant(variant);
                    setQuantity(1);
                  }}
                />
              </div>
            )}

            <div className={styles.quantitySection}>
              <span className={styles.qtyLabel}>Số lượng:</span>
              <div className={styles.qtyControl}>
                <button
                  type="button"
                  className={styles.qtyBtn}
                  disabled={quantity <= 1 || isOutOfStock}
                  onClick={() => setQuantity((q) => Math.max(q - 1, 1))}
                  aria-label="Giảm số lượng"
                >
                  -
                </button>
                <span className={styles.qtyDisplay}>{quantity}</span>
                <button
                  type="button"
                  className={styles.qtyBtn}
                  disabled={quantity >= currentStock || isOutOfStock}
                  onClick={() =>
                    setQuantity((q) => Math.min(q + 1, currentStock))
                  }
                  aria-label="Tăng số lượng"
                >
                  +
                </button>
              </div>
            </div>

            <div className={styles.actions}>
              <button
                type="button"
                className={styles.addToCartBtn}
                disabled={isOutOfStock || !selectedVariant}
                onClick={handleAddToCart}
              >
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
                <span>{isOutOfStock ? "Tạm hết hàng" : "Thêm vào giỏ"}</span>
              </button>

              <button
                type="button"
                className={styles.buyNowBtn}
                disabled={isOutOfStock || !selectedVariant}
                onClick={handleBuyNow}
              >
                Mua ngay
              </button>
            </div>

            <div className={styles.guarantees}>
              <div className={styles.guaranteeItem}>
                <svg
                  className={styles.guaranteeIcon}
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                >
                  <rect width="20" height="12" x="2" y="6" rx="2" />
                  <circle cx="12" cy="12" r="2" />
                  <path d="M6 12h.01M18 12h.01" />
                </svg>
                <span>Bảo hành chính hãng 12 - 24 tháng</span>
              </div>
              <div className={styles.guaranteeItem}>
                <svg
                  className={styles.guaranteeIcon}
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                >
                  <path d="m7.5 4.27 9 5.15" />
                  <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z" />
                </svg>
                <span>Miễn phí giao hàng toàn quốc</span>
              </div>
              <div className={styles.guaranteeItem}>
                <svg
                  className={styles.guaranteeIcon}
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
              <div className={styles.guaranteeItem}>
                <svg
                  className={styles.guaranteeIcon}
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
              <div className={styles.descriptionSection}>
                <h2 className={styles.descTitle}>Tổng quan sản phẩm</h2>
                <p className={styles.descContent}>{product.description}</p>
              </div>
            )}

            <section className={styles.reviewsSection} aria-label="Đánh giá từ khách hàng">
              <div className={styles.reviewsHeader}>
                <h2 className={styles.reviewsTitle}>Đánh giá & Nhận xét</h2>
                <div className={styles.reviewsScore}>
                  <span className={styles.starRating}>★ ★ ★ ★ ★</span>
                  <span>({reviews.length} lượt đánh giá)</span>
                </div>
              </div>

              <div className={styles.reviewFormCard}>
                <h3 className={styles.reviewFormTitle}>Gửi đánh giá của bạn</h3>
                <form onSubmit={handleReviewSubmit}>
                  <div className={styles.starPicker} role="radiogroup" aria-label="Chọn số sao">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        type="button"
                        className={`${styles.starBtn} ${
                          star <= reviewRating ? styles.starActive : ""
                        }`}
                        onClick={() => setReviewRating(star)}
                        aria-label={`${star} sao`}
                      >
                        ★
                      </button>
                    ))}
                  </div>

                  <div className={styles.reviewInputRow}>
                    <input
                      type="text"
                      className={styles.reviewInput}
                      placeholder="Họ và tên của bạn *"
                      value={reviewName}
                      onChange={(e) => setReviewName(e.target.value)}
                      required
                    />
                    <textarea
                      rows={3}
                      className={styles.reviewTextarea}
                      placeholder="Chia sẻ cảm nhận chi tiết của bạn về chất lượng sản phẩm... *"
                      value={reviewComment}
                      onChange={(e) => setReviewComment(e.target.value)}
                      required
                    />
                  </div>

                  <button type="submit" className={styles.submitReviewBtn}>
                    Gửi đánh giá
                  </button>

                  {reviewSuccess && (
                    <span style={{ color: "#16a34a", fontSize: "0.85rem", marginLeft: "12px" }}>
                      {reviewSuccess}
                    </span>
                  )}
                </form>
              </div>

              <div className={styles.reviewsList}>
                {reviews.map((rev) => (
                  <div key={rev.reviewId} className={styles.reviewCard}>
                    <div className={styles.reviewTop}>
                      <div className={styles.reviewAuthor}>
                        <span>{rev.userName}</span>
                        {rev.isVerifiedPurchase && (
                          <span className={styles.verifiedBadge}>✓ Đã mua hàng</span>
                        )}
                      </div>
                      <span className={styles.reviewDate}>
                        {new Date(rev.createdAt).toLocaleDateString("vi-VN")}
                      </span>
                    </div>

                    <div className={styles.reviewStars}>
                      {"★".repeat(rev.rating)}
                      <span style={{ color: "#d1d5db" }}>
                        {"★".repeat(5 - rev.rating)}
                      </span>
                    </div>

                    <p className={styles.reviewComment}>{rev.comment}</p>
                  </div>
                ))}
              </div>
            </section>
          </div>
        </div>
      </div>
    </main>
  );
}
