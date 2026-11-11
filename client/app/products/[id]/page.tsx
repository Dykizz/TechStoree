"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { use, useState, useMemo } from "react";
import { useCart } from "@/lib/context/CartContext";
import { useProductDetail } from "@/hooks/queries/useProductDetail";
import {
  ProductVariantDto,
} from "@/lib/types/product";
import { useGallery, type GalleryImage } from "@/hooks/useGallery";
import ProductBreadcrumbs from "@/components/products/detail/ProductBreadcrumbs";
import ProductGallery from "@/components/products/detail/ProductGallery";
import ProductActions from "@/components/products/detail/ProductActions";
import ProductLightbox from "@/components/products/detail/ProductLightbox";
import RelatedProducts from "@/components/products/detail/RelatedProducts";

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

  const {
    data: product,
    isLoading: loading,
    error: queryError,
  } = useProductDetail(productId);
  const loadError = queryError ? "Không thể tải sản phẩm từ máy chủ. Vui lòng thử lại." : "";

  // Tìm biến thể mặc định: ưu tiên biến thể còn hàng đầu tiên, hoặc biến thể đầu tiên
  const defaultVariant = useMemo(() => {
    if (!product?.variants?.length) return null;
    return (
      product.variants.find((v) => v.isActive && v.stockQuantity > 0) ||
      product.variants[0]
    );
  }, [product]);

  const [selectedVariant, setSelectedVariant] =
    useState<ProductVariantDto | null>(() => defaultVariant);
  const [, setSelectedAttrs] = useState<Record<string, string>>(() =>
    defaultVariant?.attributes ? { ...defaultVariant.attributes } : {}
  );
  const [quantity, setQuantity] = useState(1);
  const [addedSuccess, setAddedSuccess] = useState(false);

  // Đồng bộ biến thể mặc định khi nạp dữ liệu sản phẩm mới (Render-phase state adjustment)
  const [prevProduct, setPrevProduct] = useState(product);
  if (prevProduct !== product) {
    setPrevProduct(product);
    if (defaultVariant) {
      setSelectedVariant(defaultVariant);
      setSelectedAttrs(defaultVariant.attributes || {});
      setQuantity(1);
    } else {
      setSelectedVariant(null);
      setSelectedAttrs({});
      setQuantity(1);
    }
  }

  // Tập hợp danh sách tất cả hình ảnh từ sản phẩm và toàn bộ các biến thể
  const galleryImages = useMemo<GalleryImage[]>(() => {
    if (!product) return [];
    const list: GalleryImage[] = [];
    const seen = new Set<string>();

    if (product.imageUrl && !seen.has(product.imageUrl)) {
      list.push({ url: product.imageUrl, label: "Hình ảnh chính" });
      seen.add(product.imageUrl);
    }

    if (product.variants) {
      product.variants.forEach((v) => {
        if (v.imageUrl && !seen.has(v.imageUrl)) {
          list.push({
            url: v.imageUrl,
            label: v.variantName,
            variantId: v.variantId,
          });
          seen.add(v.imageUrl);
        }
      });
    }

    return list;
  }, [product]);

  // Gallery hook đóng gói cử chỉ lướt vuốt và Lightbox
  const gallery = useGallery(galleryImages);

  // Đồng bộ ảnh khi người dùng chọn biến thể (Render-phase state adjustment, không cascading render)
  const targetUrl = selectedVariant?.imageUrl;
  const [prevTargetUrl, setPrevTargetUrl] = useState(targetUrl);
  if (prevTargetUrl !== targetUrl) {
    setPrevTargetUrl(targetUrl);
    if (targetUrl) {
      const idx = galleryImages.findIndex((item) => item.url === targetUrl);
      if (idx !== -1) {
        gallery.setCurrentImageIndex(idx);
      }
    }
  }

  if (loading) {
    return (
      <main className="min-h-[calc(100vh-68px)] bg-white px-4 py-8 pb-20 sm:px-6">
        <div className="max-w-[1200px] mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12 animate-pulse">
            <div className="w-full aspect-square bg-neutral-200 rounded-xl" />
            <div className="flex flex-col gap-4">
              <div className="h-4 bg-neutral-200 rounded w-[30%]" />
              <div className="h-8 bg-neutral-200 rounded w-[70%]" />
              <div className="h-7 bg-neutral-200 rounded w-[40%]" />
              <div className="h-4 bg-neutral-200 rounded w-full mt-4" />
              <div className="h-4 bg-neutral-200 rounded w-[90%]" />
            </div>
          </div>
        </div>
      </main>
    );
  }

  if (!product) {
    return (
      <main className="min-h-[calc(100vh-68px)] bg-white px-4 py-8 pb-20 sm:px-6">
        <div className="max-w-[1200px] mx-auto text-center py-24 px-6 [&>h2]:text-[1.8rem] [&>h2]:mb-3 [&>h2]:font-bold [&>p]:text-neutral-500">
          <h2>{loadError || "Không tìm thấy sản phẩm"}</h2>
          <p>
            Sản phẩm này có thể đã ngừng kinh doanh hoặc đường dẫn không đúng.
          </p>
          <Link href="/products" className="inline-block mt-5 bg-[#111111] text-white no-underline px-6 py-3 rounded-md hover:bg-brand transition-colors">
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

  const originalPrice = selectedVariant
    ? selectedVariant.price
    : product.minPrice;
  const promotionalPrice = variantPromo
    ? variantPromo.promotionalPrice
    : !selectedVariant && productPromo
      ? productPromo.promotionalMinPrice
      : null;
  const currentPrice = promotionalPrice ?? originalPrice;

  const activeImage =
    galleryImages[gallery.currentImageIndex]?.url ||
    (selectedVariant && selectedVariant.imageUrl) ||
    product.imageUrl ||
    "";

  const handleAddToCart = async () => {
    if (!selectedVariant || selectedVariant.stockQuantity <= 0 || busy) return;

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
      false
    );

    if (ok) {
      setAddedSuccess(true);
      setTimeout(() => setAddedSuccess(false), 2500);
    }
  };

  const handleBuyNow = async () => {
    if (!selectedVariant || selectedVariant.stockQuantity <= 0 || busy) return;

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
      false
    );

    if (ok) {
      router.push("/checkout");
    }
  };

  const handleSlidePrev = () => {
    if (gallery.currentImageIndex > 0) {
      gallery.goToImageIndex(gallery.currentImageIndex - 1);
    } else if (galleryImages.length > 1) {
      gallery.goToImageIndex(galleryImages.length - 1);
    }
  };

  const handleSlideNext = () => {
    if (gallery.currentImageIndex < galleryImages.length - 1) {
      gallery.goToImageIndex(gallery.currentImageIndex + 1);
    } else if (galleryImages.length > 1) {
      gallery.goToImageIndex(0);
    }
  };

  return (
    <main className="min-h-[calc(100vh-68px)] bg-white px-4 py-8 pb-20 sm:px-6">
      <div className="max-w-[1200px] mx-auto">
        <ProductBreadcrumbs
          categoryId={product.categoryId}
          categoryName={product.categoryName}
          productName={product.productName}
        />

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12 items-start">
          <ProductGallery
            images={galleryImages}
            currentIndex={gallery.currentImageIndex}
            productName={product.productName}
            isDragging={gallery.isDragging}
            dragDeltaX={gallery.dragDeltaX}
            onDragStart={gallery.handleDragStart}
            onDragMove={gallery.handleDragMove}
            onDragEnd={gallery.handleDragEnd}
            onSelectIndex={gallery.goToImageIndex}
            onSlidePrev={handleSlidePrev}
            onSlideNext={handleSlideNext}
          />

          <ProductActions
            product={product}
            selectedVariant={selectedVariant}
            quantity={quantity}
            addedSuccess={addedSuccess}
            busy={busy}
            onVariantChange={(variant) => {
              setSelectedVariant(variant);
              setQuantity(1);
            }}
            onAttributesChange={setSelectedAttrs}
            onQuantityChange={setQuantity}
            onAddToCart={() => void handleAddToCart()}
            onBuyNow={() => void handleBuyNow()}
          />
        </div>

        {/* Danh sách các sản phẩm tương tự */}
        <RelatedProducts
          productId={product.productId}
          categoryId={product.categoryId}
          categoryName={product.categoryName}
        />
      </div>

      <ProductLightbox
        isOpen={gallery.isLightboxOpen}
        images={galleryImages}
        currentIndex={gallery.lightboxIndex}
        productName={product.productName}
        onClose={gallery.closeLightbox}
        onPrev={gallery.handlePrevImage}
        onNext={gallery.handleNextImage}
        onSelectIndex={gallery.setLightboxIndex}
      />
    </main>
  );
}
