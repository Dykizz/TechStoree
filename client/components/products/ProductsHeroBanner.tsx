"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  PRODUCTS_HERO_BANNERS,
  ProductsHeroBannerItem,
} from "../../lib/products-hero-banners";
import styles from "./ProductsHeroBanner.module.css";

const SLIDE_DURATION_MS = 3_000; // Tự động đổi ảnh mỗi 3 giây theo yêu cầu

interface ProductsHeroBannerProps {
  banners?: ProductsHeroBannerItem[];
}

export default function ProductsHeroBanner({
  banners = PRODUCTS_HERO_BANNERS,
}: ProductsHeroBannerProps) {
  const router = useRouter();
  const [activeIndex, setActiveIndex] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  const total = banners.length;

  const nextSlide = useCallback(() => {
    if (total <= 1) return;
    setActiveIndex((prev) => (prev + 1) % total);
  }, [total]);

  const prevSlide = useCallback(() => {
    if (total <= 1) return;
    setActiveIndex((prev) => (prev - 1 + total) % total);
  }, [total]);

  const goToSlide = (index: number) => {
    setActiveIndex(index);
  };

  // Timer tự động chuyển slide mỗi 3 giây và tự động quay về ảnh đầu tiên khi hết vòng
  useEffect(() => {
    if (total <= 1 || isPaused) return;

    timerRef.current = setInterval(() => {
      nextSlide();
    }, SLIDE_DURATION_MS);

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [total, isPaused, nextSlide, activeIndex]);

  if (!banners || banners.length === 0) return null;

  const current = banners[activeIndex] || banners[0];
  const targetLink = current.linkUrl || "/products";

  // Khi click vào nền background -> chuyển tới trang chi tiết sản phẩm
  const handleBannerClick = () => {
    router.push(targetLink);
  };

  return (
    <section
      className={styles.bannerWrapper}
      aria-label="Bộ sưu tập sản phẩm công nghệ"
      onClick={handleBannerClick}
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
      title="Nhấn vào banner để xem chi tiết sản phẩm này"
    >
      {/* Background Images Slider (Giữ độ sắc nét, không bị blur) */}
      <div className={styles.sliderContainer}>
        {banners.map((slide, idx) => {
          const isActive = idx === activeIndex;
          return (
            <div
              key={slide.id || idx}
              className={`${styles.slideImageWrap} ${
                isActive ? styles.slideActive : styles.slideInactive
              }`}
              aria-hidden={!isActive}
            >
              <Image
                src={slide.imageUrl}
                alt={slide.alt || "Banner sản phẩm công nghệ"}
                fill
                priority={idx === 0}
                className={styles.slideImage}
                sizes="(max-width: 1280px) 100vw, 1280px"
              />
            </div>
          );
        })}
      </div>

      {/* Lớp phủ Gradient Tinh Tế (Giảm mờ tối đa để ảnh sáng rõ, sắc nét) */}
      <div className={styles.gradientOverlay} />

      {/* Vùng Nội Dung: Đồng bộ hàng, chiều cao và tỉ lệ các khối text */}
      <div className={styles.content}>
        {/* Hàng 1: Tag sản phẩm (Có link tới chi tiết sản phẩm) */}
        <div className={styles.tagRow}>
          <Link
            href={targetLink}
            className={styles.tagBadgeLink}
            onClick={(e) => e.stopPropagation()}
            title={`Xem chi tiết: ${current.tag || "Sản phẩm"}`}
          >
            <span className={styles.pulseDot} />
            <span className={styles.tagText}>
              {current.tag || "BỘ SƯU TẬP 2026"}
            </span>
            <svg
              className={styles.tagArrow}
              width="13"
              height="13"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M7 17 17 7" />
              <path d="M7 7h10v10" />
            </svg>
          </Link>
        </div>

        {/* Hàng 2: Tiêu đề Title (Cố định chiều cao và tỉ lệ để không nhảy dòng) */}
        <div className={styles.titleRow}>
          <h1 key={`title-${activeIndex}`} className={styles.heroTitle}>
            {current.title || "Sản Phẩm Công Nghệ Tinh Tuyển"}
          </h1>
        </div>

        {/* Hàng 3: Mô tả Description (Cố định chiều cao và tỉ lệ dòng) */}
        <div className={styles.descriptionRow}>
          <p
            key={`desc-${activeIndex}`}
            className={styles.heroDescription}
          >
            {current.description ||
              "Trải nghiệm các thiết bị công nghệ đẳng cấp được thiết kế tinh tế, hiệu năng mạnh mẽ và đón đầu xu hướng tương lai."}
          </p>
        </div>

        {/* Hint bấm xem sản phẩm */}
        <div className={styles.viewProductHint}>
          <span>Khám phá sản phẩm ngay</span>
          <span className={styles.hintArrow}>→</span>
        </div>

        {/* Thanh điều khiển Controls: Chuyển slide 3 giây */}
        <div
          className={styles.controlsBar}
          onClick={(e) => e.stopPropagation()}
        >
          <button
            type="button"
            className={styles.navArrow}
            onClick={(e) => {
              e.stopPropagation();
              prevSlide();
            }}
            aria-label="Ảnh trước"
            title="Ảnh trước"
          >
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
              <path d="m15 18-6-6 6-6" />
            </svg>
          </button>

          <div className={styles.dotsGroup}>
            {banners.map((_, idx) => {
              const isCurrent = idx === activeIndex;
              return (
                <button
                  key={idx}
                  type="button"
                  className={`${styles.dotItem} ${
                    isCurrent ? styles.dotItemActive : ""
                  }`}
                  onClick={(e) => {
                    e.stopPropagation();
                    goToSlide(idx);
                  }}
                  aria-label={`Chuyển tới ảnh ${idx + 1}`}
                  title={`Ảnh ${idx + 1}`}
                >
                  <span className={styles.dotTrack}>
                    {isCurrent && !isPaused && (
                      <span
                        key={`prog-${activeIndex}-${isPaused}`}
                        className={styles.dotProgress}
                        style={{ animationDuration: `${SLIDE_DURATION_MS}ms` }}
                      />
                    )}
                  </span>
                </button>
              );
            })}
          </div>

          <button
            type="button"
            className={styles.navArrow}
            onClick={(e) => {
              e.stopPropagation();
              nextSlide();
            }}
            aria-label="Ảnh tiếp theo"
            title="Ảnh tiếp theo"
          >
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
              <path d="m9 18 6-6-6-6" />
            </svg>
          </button>

          <span className={styles.counterBadge}>
            0{activeIndex + 1} / 0{total}
          </span>
        </div>
      </div>
    </section>
  );
}
