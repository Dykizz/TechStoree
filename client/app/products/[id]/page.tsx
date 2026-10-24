"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { use, useEffect, useState, useMemo, useRef, useCallback } from "react";
import VariantSelector from "../../../components/products/VariantSelector";
import { useCart } from "../../../lib/context/CartContext";
import { fetchProductById, formatPrice } from "../../../lib/products-client";
import {
  ProductDetailDto,
  ProductVariantDto,
} from "../../../lib/types/product";
import styles from "./product-detail.module.css";

export default function ProductDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = use(params);
  const productId = /^[1-9]\d*$/.test(resolvedParams.id)
    ? Number(resolvedParams.id)
    : 0;
  const router = useRouter();
  const { addItem, busy } = useCart();

  const [product, setProduct] = useState<ProductDetailDto | null>(null);
  const [selectedVariant, setSelectedVariant] =
    useState<ProductVariantDto | null>(null);
  const [selectedAttrs, setSelectedAttrs] = useState<Record<string, string>>({});
  const [quantity, setQuantity] = useState(1);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [addedSuccess, setAddedSuccess] = useState(false);

  // Gallery, Swipe Slider & Lightbox States
  const [currentImageIndex, setCurrentImageIndex] = useState<number>(0);
  const [dragDeltaX, setDragDeltaX] = useState<number>(0);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [isLightboxOpen, setIsLightboxOpen] = useState<boolean>(false);
  const [lightboxIndex, setLightboxIndex] = useState<number>(0);

  // Drag Gesture Refs
  const dragStartXRef = useRef<number>(0);
  const dragStartTimeRef = useRef<number>(0);
  const isDraggingRef = useRef<boolean>(false);

  useEffect(() => {
    async function loadProduct() {
      setLoading(true);
      try {
        const data = await fetchProductById(productId);
        setProduct(data);
        if (
          data &&
          data.variants &&
          data.variants.length === 1 &&
          (!data.variantAttributes || data.variantAttributes.length === 0)
        ) {
          // Chỉ tự động chọn nếu sản phẩm chỉ có duy nhất 1 biến thể và không có thuộc tính lựa chọn
          setSelectedVariant(data.variants[0]);
        } else {
          // Bắt buộc khách hàng chủ động chọn biến thể / màu sắc
          setSelectedVariant(null);
          setSelectedAttrs({});
        }
      } catch {
        setLoadError("Không thể tải sản phẩm từ máy chủ. Vui lòng thử lại.");
      } finally {
        setLoading(false);
      }
    }
    void loadProduct();
  }, [productId]);

  // Tập hợp danh sách tất cả hình ảnh từ sản phẩm và toàn bộ các biến thể (luôn gọi hook ở cấp cao nhất)
  const galleryImages = useMemo(() => {
    if (!product) return [];
    const list: {
      url: string;
      variantId?: number;
      variantName?: string;
      label?: string;
    }[] = [];
    const seenUrls = new Set<string>();

    const addImg = (
      url?: string | null,
      variantId?: number,
      variantName?: string,
      label?: string,
    ) => {
      if (url && url.trim() && !seenUrls.has(url.trim())) {
        seenUrls.add(url.trim());
        list.push({
          url: url.trim(),
          variantId,
          variantName,
          label: label || "Ảnh sản phẩm",
        });
      }
    };

    // 1. Ảnh chính sản phẩm
    addImg(product.imageUrl, undefined, undefined, "Ảnh đại diện");

    // 2. Ảnh từ toàn bộ biến thể
    if (product.variants && Array.isArray(product.variants)) {
      for (const v of product.variants) {
        addImg(v.imageUrl, v.variantId, v.variantName, v.variantName);
      }
    }

    return list;
  }, [product]);

  // Tìm hình ảnh hiển thị theo biến thể đang chọn hoặc màu sắc đang click
  const colorPreviewVariant =
    product && selectedAttrs["Màu sắc"]
      ? product.variants.find(
          (v) =>
            v.attributes &&
            v.attributes["Màu sắc"] === selectedAttrs["Màu sắc"] &&
            v.imageUrl,
        )
      : null;

  // Đồng bộ ảnh khi người dùng chọn biến thể hoặc màu sắc
  useEffect(() => {
    if (galleryImages.length === 0) return;
    const targetUrl =
      selectedVariant?.imageUrl || colorPreviewVariant?.imageUrl;
    if (targetUrl) {
      const idx = galleryImages.findIndex((item) => item.url === targetUrl);
      if (idx !== -1) {
        setCurrentImageIndex(idx);
      }
    }
  }, [selectedVariant, colorPreviewVariant, galleryImages]);

  // Lightbox navigation handlers
  const handlePrevImage = useCallback(
    (e?: React.MouseEvent) => {
      e?.stopPropagation();
      setLightboxIndex(
        (prev) => (prev - 1 + galleryImages.length) % galleryImages.length,
      );
    },
    [galleryImages.length],
  );

  const handleNextImage = useCallback(
    (e?: React.MouseEvent) => {
      e?.stopPropagation();
      setLightboxIndex((prev) => (prev + 1) % galleryImages.length);
    },
    [galleryImages.length],
  );

  // Phím tắt bàn phím (Esc, ArrowLeft, ArrowRight) và khóa cuộn trang khi mở Lightbox
  useEffect(() => {
    if (!isLightboxOpen) return;
    document.body.style.overflow = "hidden";

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setCurrentImageIndex(lightboxIndex);
        setIsLightboxOpen(false);
      } else if (e.key === "ArrowLeft") {
        handlePrevImage();
      } else if (e.key === "ArrowRight") {
        handleNextImage();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => {
      document.body.style.overflow = "";
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isLightboxOpen, lightboxIndex, handlePrevImage, handleNextImage]);

  // Chuyển ảnh mượt mà độc lập, không tự ý can thiệp vào biến thể khách đang chọn
  const goToImageIndex = useCallback(
    (index: number) => {
      if (galleryImages.length === 0) return;
      const targetIdx = Math.max(0, Math.min(index, galleryImages.length - 1));
      setCurrentImageIndex(targetIdx);
    },
    [galleryImages.length],
  );

  // Xử lý cử chỉ KÉO / LƯỚT ảnh (Drag & Swipe Gesture)
  const handleDragStart = (clientX: number) => {
    dragStartXRef.current = clientX;
    dragStartTimeRef.current = Date.now();
    isDraggingRef.current = true;
    setIsDragging(true);
    setDragDeltaX(0);
  };

  const handleDragMove = (clientX: number) => {
    if (!isDraggingRef.current) return;
    const delta = clientX - dragStartXRef.current;

    // Giảm độ trượt nhẹ (resistance) nếu kéo quá mép đầu hoặc mép cuối
    if (
      (currentImageIndex === 0 && delta > 0) ||
      (currentImageIndex === galleryImages.length - 1 && delta < 0)
    ) {
      setDragDeltaX(delta * 0.35);
    } else {
      setDragDeltaX(delta);
    }
  };

  const handleDragEnd = () => {
    if (!isDraggingRef.current) return;
    isDraggingRef.current = false;
    setIsDragging(false);

    const duration = Date.now() - dragStartTimeRef.current;
    const delta = dragDeltaX;
    setDragDeltaX(0);

    // Nếu chỉ nhấp chuột nhanh (< 6px dịch chuyển và < 300ms) -> Click: Phóng to Lightbox!
    if (Math.abs(delta) < 6 && duration < 300) {
      setLightboxIndex(currentImageIndex);
      setIsLightboxOpen(true);
      return;
    }

    // Kéo sang trái đủ xa (delta < -38px) -> Lướt sang ảnh tiếp theo
    if (delta < -38 && currentImageIndex < galleryImages.length - 1) {
      goToImageIndex(currentImageIndex + 1);
    }
    // Kéo sang phải đủ xa (delta > 38px) -> Lướt về ảnh trước đó
    else if (delta > 38 && currentImageIndex > 0) {
      goToImageIndex(currentImageIndex - 1);
    }
    // Kéo mạnh sang trái khi ở ảnh cuối cùng -> quay về ảnh đầu tiên
    else if (delta < -70 && currentImageIndex === galleryImages.length - 1 && galleryImages.length > 1) {
      goToImageIndex(0);
    }
    // Kéo mạnh sang phải khi ở ảnh đầu tiên -> chuyển đến ảnh cuối cùng
    else if (delta > 70 && currentImageIndex === 0 && galleryImages.length > 1) {
      goToImageIndex(galleryImages.length - 1);
    }
  };

  // Nút mũi tên lùi / tiến ảnh trên khung hình
  const handleSlidePrev = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (currentImageIndex > 0) {
      goToImageIndex(currentImageIndex - 1);
    } else if (galleryImages.length > 1) {
      goToImageIndex(galleryImages.length - 1);
    }
  };

  const handleSlideNext = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (currentImageIndex < galleryImages.length - 1) {
      goToImageIndex(currentImageIndex + 1);
    } else if (galleryImages.length > 1) {
      goToImageIndex(0);
    }
  };

  if (loading) {
    return (
      <main className={styles.main}>
        <div className={styles.container}>
          <div
            style={{ textAlign: "center", padding: "100px 0", color: "#666" }}
          >
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
          <h2>{loadError || "Không tìm thấy sản phẩm"}</h2>
          <p>
            Sản phẩm này có thể đã ngừng kinh doanh hoặc đường dẫn không đúng.
          </p>
          <Link href="/products" className={styles.backBtn}>
            &larr; Xem tất cả sản phẩm
          </Link>
        </div>
      </main>
    );
  }

  const variantPromo =
    selectedVariant?.promotion && selectedVariant.promotion.hasPromotion
      ? selectedVariant.promotion
      : null;
  const productPromo =
    product.promotion && product.promotion.hasPromotion
      ? product.promotion
      : null;

  const hasPromotion = Boolean(
    variantPromo || (!selectedVariant && productPromo),
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

  const activeImage =
    galleryImages[currentImageIndex]?.url ||
    (selectedVariant && selectedVariant.imageUrl) ||
    colorPreviewVariant?.imageUrl ||
    product.imageUrl ||
    "";

  const handleAddToCart = async () => {
    if (!selectedVariant || isOutOfStock || busy) return;

    const ok = await addItem(
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
      quantity,
      false, // Không tự động bật thanh task / drawer kế bên
    );

    if (ok) {
      setAddedSuccess(true);
      setTimeout(() => setAddedSuccess(false), 2500);
    }
  };

  const handleBuyNow = async () => {
    if (!selectedVariant || isOutOfStock || busy) return;

    const added = await addItem(
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
      quantity,
      false,
    );
    if (added) router.push("/checkout");
  };

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <nav className={styles.breadcrumbs} aria-label="Breadcrumb">
          <Link href="/">Trang chủ</Link>
          <span>/</span>
          <Link href="/products">Sản phẩm</Link>
          <span>/</span>
          <Link href={`/products?category=${product.categoryId}`}>
            {product.categoryName}
          </Link>
          <span>/</span>
          <span style={{ color: "#111", fontWeight: 500 }}>
            {product.productName}
          </span>
        </nav>

        <div className={styles.productLayout}>
          <div className={styles.gallery}>
            <div
              className={`${styles.mainImageWrap} ${isDragging ? styles.isDragging : ""}`}
              onMouseDown={(e) => handleDragStart(e.clientX)}
              onMouseMove={(e) => handleDragMove(e.clientX)}
              onMouseUp={handleDragEnd}
              onMouseLeave={handleDragEnd}
              onTouchStart={(e) => handleDragStart(e.touches[0].clientX)}
              onTouchMove={(e) => handleDragMove(e.touches[0].clientX)}
              onTouchEnd={handleDragEnd}
              onTouchCancel={handleDragEnd}
              title="Kéo sang trái/phải để lướt ảnh • Nhấp để phóng to"
            >
              {/* Dải trượt các hình ảnh liên tục (Carousel Slider Track) */}
              <div
                className={styles.galleryTrack}
                style={{
                  transform: `translateX(calc(-${currentImageIndex * 100}% + ${dragDeltaX}px))`,
                  transition: isDragging
                    ? "none"
                    : "transform 0.35s cubic-bezier(0.2, 0.8, 0.25, 1)",
                }}
              >
                {galleryImages.length > 0 ? (
                  galleryImages.map((img, idx) => (
                    <div key={img.url + idx} className={styles.gallerySlide}>
                      <Image
                        src={img.url}
                        alt={img.label || product.productName}
                        fill
                        priority={idx === 0}
                        className={styles.mainImage}
                        sizes="(max-width: 900px) 100vw, 50vw"
                        draggable={false}
                      />
                    </div>
                  ))
                ) : (
                  <div className={styles.gallerySlide}>
                    <div className={styles.mainImage} />
                  </div>
                )}
              </div>

              {/* Badge chỉ số ảnh */}
              {galleryImages.length > 1 && (
                <div className={styles.galleryTopBadge}>
                  <span>
                    {currentImageIndex + 1} / {galleryImages.length}
                  </span>
                </div>
              )}

              {/* Nút chuyển ảnh sang trái / phải khi hover */}
              {galleryImages.length > 1 && (
                <>
                  <button
                    type="button"
                    className={`${styles.gallerySlideBtn} ${styles.gallerySlideBtnPrev}`}
                    onClick={handleSlidePrev}
                    title="Ảnh trước"
                  >
                    <svg
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.5"
                    >
                      <polyline points="15 18 9 12 15 6" />
                    </svg>
                  </button>
                  <button
                    type="button"
                    className={`${styles.gallerySlideBtn} ${styles.gallerySlideBtnNext}`}
                    onClick={handleSlideNext}
                    title="Ảnh tiếp theo"
                  >
                    <svg
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.5"
                    >
                      <polyline points="9 18 15 12 9 6" />
                    </svg>
                  </button>
                </>
              )}

              {/* Chấm tròn định vị trang (Pagination Dots) */}
              {galleryImages.length > 1 && (
                <div
                  className={styles.galleryDotsBar}
                  onClick={(e) => e.stopPropagation()}
                >
                  {galleryImages.map((_, i) => (
                    <button
                      key={i}
                      type="button"
                      className={`${styles.galleryDotItem} ${
                        i === currentImageIndex ? styles.galleryDotItemActive : ""
                      }`}
                      onClick={() => goToImageIndex(i)}
                      title={`Xem ảnh ${i + 1}`}
                    />
                  ))}
                </div>
              )}
            </div>

            {/* Dải ảnh Thumbnail bên dưới ảnh chính */}
            {galleryImages.length > 1 && (
              <div className={styles.thumbnailsStrip}>
                {galleryImages.map((img, idx) => (
                  <button
                    key={img.url + idx}
                    type="button"
                    className={`${styles.thumbBtn} ${
                      idx === currentImageIndex ? styles.thumbBtnActive : ""
                    }`}
                    onClick={() => goToImageIndex(idx)}
                    title={img.label || `Ảnh ${idx + 1}`}
                  >
                    <Image
                      src={img.url}
                      alt={img.label || `Thumbnail ${idx + 1}`}
                      fill
                      className={styles.thumbImg}
                      sizes="68px"
                    />
                  </button>
                ))}
              </div>
            )}
          </div>

          <div className={styles.details}>
            <span className={styles.categoryTag}>{product.categoryName}</span>
            <h1 className={styles.title}>{product.productName}</h1>

            <div className={styles.priceBlock}>
              <div className={styles.priceGroup}>
                <span
                  className={`${styles.price} ${hasPromotion ? styles.pricePromo : ""}`}
                >
                  {!selectedVariant && product.minPrice !== product.maxPrice
                    ? `${formatPrice(product.minPrice)} – ${formatPrice(product.maxPrice)}`
                    : formatPrice(currentPrice)}
                </span>
                {hasPromotion &&
                  promotionalPrice !== null &&
                  originalPrice > promotionalPrice && (
                    <span className={styles.originalPrice}>
                      {formatPrice(originalPrice)}
                    </span>
                  )}
                {variantPromo && (
                  <span className={styles.promoBadge}>
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
                    <strong>{activePromoName}</strong> &bull; Đã áp dụng giảm
                    giá trực tiếp vào sản phẩm
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
                    : !selectedVariant
                      ? `Còn hàng (Tổng ${currentStock} sản phẩm)`
                      : `Còn hàng (${currentStock} sản phẩm)`}
                </span>
              </div>
            </div>

            {(product.variantAttributes.length > 0 ||
              product.variants.length > 1) && (
              <div className={styles.variantsSection}>
                <VariantSelector
                  attributes={product.variantAttributes}
                  variants={product.variants}
                  selectedVariant={selectedVariant}
                  onVariantChange={(variant) => {
                    setSelectedVariant(variant);
                    setQuantity(1);
                  }}
                  onAttributesChange={(attrs) => {
                    setSelectedAttrs(attrs);
                  }}
                />
              </div>
            )}

            <div className={styles.quantitySection}>
              <span className={styles.qtyLabel}>Số lượng:</span>
              <div
                className={`${styles.qtyControl} ${
                  !selectedVariant ? styles.qtyControlDisabled : ""
                }`}
              >
                <button
                  type="button"
                  className={styles.qtyBtn}
                  disabled={!selectedVariant || quantity <= 1 || isOutOfStock}
                  onClick={() => setQuantity((q) => Math.max(q - 1, 1))}
                  aria-label="Giảm số lượng"
                >
                  -
                </button>
                <span className={styles.qtyDisplay}>
                  {!selectedVariant ? "-" : quantity}
                </span>
                <button
                  type="button"
                  className={styles.qtyBtn}
                  disabled={
                    !selectedVariant ||
                    quantity >= currentStock ||
                    isOutOfStock
                  }
                  onClick={() =>
                    setQuantity((q) => Math.min(q + 1, currentStock))
                  }
                  aria-label="Tăng số lượng"
                >
                  +
                </button>
              </div>
              {!selectedVariant && (
                <span className={styles.qtyHint}>
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

            <div className={styles.actions}>
              <button
                type="button"
                className={`${styles.addToCartBtn} ${addedSuccess ? styles.addToCartSuccess : ""}`}
                disabled={isOutOfStock || !selectedVariant}
                onClick={handleAddToCart}
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
                className={styles.buyNowBtn}
                disabled={isOutOfStock || !selectedVariant}
                onClick={handleBuyNow}
                title={!selectedVariant ? "Vui lòng chọn biến thể / màu sắc" : ""}
              >
                {!selectedVariant ? "Chọn biến thể để mua" : "Mua ngay"}
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
                <span>Chi phí được xác nhận khi đặt hàng</span>
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

            <section
              className={styles.reviewsSection}
              aria-label="Đánh giá sản phẩm"
            >
              <h2 className={styles.reviewsTitle}>Đánh giá & nhận xét</h2>
              <p className={styles.descContent}>
                Tính năng đánh giá đang được hoàn thiện. Chưa có đánh giá được
                xác nhận bởi hệ thống.
              </p>
            </section>
          </div>
        </div>
      </div>

      {/* Target Modal / Lightbox phóng to chi tiết */}
      {isLightboxOpen && (
        <div
          className={styles.lightboxModal}
          onClick={() => {
            setCurrentImageIndex(lightboxIndex);
            setIsLightboxOpen(false);
          }}
          role="dialog"
          aria-modal="true"
        >
          <div
            className={styles.lightboxHeader}
            onClick={(e) => e.stopPropagation()}
          >
            <div className={styles.lightboxTitleWrap}>
              <span className={styles.lightboxCounter}>
                {lightboxIndex + 1} / {galleryImages.length}
              </span>
              <span className={styles.lightboxTitle}>
                {product.productName}
              </span>
            </div>
            <button
              type="button"
              className={styles.lightboxCloseBtn}
              onClick={() => {
                setCurrentImageIndex(lightboxIndex);
                setIsLightboxOpen(false);
              }}
              title="Đóng xem ảnh (Phím Esc)"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
              >
                <line x1="18" y1="6" x2="6" y2="18" />
                <line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>

          <div
            className={styles.lightboxBody}
            onClick={(e) => e.stopPropagation()}
          >
            {galleryImages.length > 1 && (
              <button
                type="button"
                className={`${styles.lightboxNavBtn} ${styles.lightboxNavBtnPrev}`}
                onClick={handlePrevImage}
                title="Ảnh trước (Mũi tên trái)"
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                >
                  <polyline points="15 18 9 12 15 6" />
                </svg>
              </button>
            )}

            <div className={styles.lightboxImageWrap}>
              {galleryImages[lightboxIndex]?.url && (
                <Image
                  src={galleryImages[lightboxIndex].url}
                  alt={
                    galleryImages[lightboxIndex]?.label || product.productName
                  }
                  fill
                  className={styles.lightboxImage}
                  sizes="90vw"
                  priority
                />
              )}
            </div>

            {galleryImages.length > 1 && (
              <button
                type="button"
                className={`${styles.lightboxNavBtn} ${styles.lightboxNavBtnNext}`}
                onClick={handleNextImage}
                title="Ảnh tiếp theo (Mũi tên phải)"
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                >
                  <polyline points="9 18 15 12 9 6" />
                </svg>
              </button>
            )}
          </div>

          {galleryImages.length > 1 && (
            <div
              className={styles.lightboxFooter}
              onClick={(e) => e.stopPropagation()}
            >
              {galleryImages.map((img, idx) => (
                <button
                  key={"modal-thumb-" + img.url + idx}
                  type="button"
                  className={`${styles.lightboxThumbBtn} ${
                    idx === lightboxIndex ? styles.lightboxThumbBtnActive : ""
                  }`}
                  onClick={() => setLightboxIndex(idx)}
                >
                  <Image
                    src={img.url}
                    alt={img.label || `Thumb ${idx + 1}`}
                    fill
                    className={styles.lightboxThumbImg}
                    sizes="54px"
                  />
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </main>
  );
}
