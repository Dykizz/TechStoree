"use client";

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  PRODUCTS_HERO_BANNERS,
  ProductsHeroBannerItem,
} from "@/lib/products-hero-banners";
import { cn } from "@/lib/utils";

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
      className="group/banner relative w-full min-h-[380px] rounded-3xl overflow-hidden mb-9 bg-[#0b0f17] shadow-[0_16px_40px_-12px_rgba(0,0,0,0.28),0_0_0_1px_rgba(255,255,255,0.1)] flex items-center justify-center cursor-pointer select-none transition-[transform,box-shadow] duration-250 hover:shadow-[0_20px_48px_-10px_rgba(0,0,0,0.4),0_0_0_1px_rgba(255,255,255,0.2)] max-md:min-h-[350px] max-md:rounded-[18px] max-md:mb-6"
      aria-label="Bộ sưu tập sản phẩm công nghệ"
      onClick={handleBannerClick}
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
      title="Nhấn vào banner để xem chi tiết sản phẩm này"
    >
      {/* Background Images Slider (Giữ độ sắc nét, không bị blur) */}
      <div className="absolute inset-0 w-full h-full z-[1]">
        {banners.map((slide, idx) => {
          const isActive = idx === activeIndex;
          return (
            <div
              key={slide.id || idx}
              className={cn(
                "absolute inset-0 w-full h-full transition-opacity duration-[800ms] ease-[cubic-bezier(0.4,0,0.2,1)]",
                isActive
                  ? "opacity-100 pointer-events-auto z-[2]"
                  : "opacity-0 pointer-events-none z-[1]"
              )}
              aria-hidden={!isActive}
            >
              <Image
                src={slide.imageUrl}
                alt={slide.alt || "Banner sản phẩm công nghệ"}
                fill
                priority={idx === 0}
                className={cn(
                  "object-cover object-center transition-transform duration-[3000ms] ease-out",
                  isActive ? "scale-100" : "scale-[1.02]"
                )}
                sizes="(max-width: 1280px) 100vw, 1280px"
              />
            </div>
          );
        })}
      </div>

      {/* Lớp phủ Gradient Tinh Tế (Giảm mờ tối đa để ảnh sáng rõ, sắc nét) */}
      <div className="absolute inset-0 z-[3] backdrop-blur-[2.5px] bg-[radial-gradient(ellipse_at_center,rgba(11,15,23,0.48)_0%,rgba(11,15,23,0.8)_100%),linear-gradient(180deg,rgba(11,15,23,0.35)_0%,rgba(11,15,23,0.6)_50%,rgba(11,15,23,0.88)_100%)] pointer-events-none" />

      {/* Vùng Nội Dung: Đồng bộ hàng, chiều cao và tỉ lệ các khối text */}
      <div className="relative z-[4] w-full max-w-[860px] pt-10 px-6 pb-8 text-center flex flex-col items-center text-white max-md:pt-7 max-md:px-4 max-md:pb-6">
        {/* Hàng 1: Tag sản phẩm (Có link tới chi tiết sản phẩm) */}
        <div className="h-[38px] flex items-center justify-center mb-3">
          <Link
            href={targetLink}
            className="group/tag inline-flex items-center gap-2 py-1.5 px-4 rounded-full bg-slate-900/72 border border-white/30 backdrop-blur-md text-[0.8rem] tracking-[0.08em] font-bold text-white uppercase no-underline shadow-[0_4px_16px_rgba(0,0,0,0.3)] transition-all duration-200 cursor-pointer hover:bg-brand/90 hover:border-white/60 hover:-translate-y-px hover:shadow-[0_6px_20px_rgba(189,32,45,0.4)]"
            onClick={(e) => e.stopPropagation()}
            title={`Xem chi tiết: ${current.tag || "Sản phẩm"}`}
          >
            <span className="w-[7px] h-[7px] rounded-full bg-sky-400 shadow-[0_0_10px_#38bdf8] animate-pulse shrink-0" />
            <span className="whitespace-nowrap overflow-hidden text-ellipsis max-w-[480px] max-md:max-w-[260px] max-md:text-[0.72rem] max-[480px]:max-w-[200px]">
              {current.tag || "BỘ SƯU TẬP 2026"}
            </span>
            <svg
              className="opacity-85 transition-transform duration-200 shrink-0 group-hover/tag:translate-x-0.5 group-hover/tag:-translate-y-0.5 group-hover/tag:opacity-100"
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
        <div className="h-[68px] flex items-center justify-center mb-2.5 max-md:h-auto max-md:min-h-[54px]">
          <h1
            key={`title-${activeIndex}`}
            className="text-[2.35rem] font-extrabold text-white tracking-[-0.02em] leading-[1.25] m-0 [text-shadow:0_3px_16px_rgba(0,0,0,0.9),0_1px_4px_rgba(0,0,0,0.9)] line-clamp-2 overflow-hidden animate-fadeInText max-md:text-[1.7rem] max-[480px]:text-[1.4rem]"
          >
            {current.title || "Sản Phẩm Công Nghệ Tinh Tuyển"}
          </h1>
        </div>

        {/* Hàng 3: Mô tả Description (Cố định chiều cao và tỉ lệ dòng) */}
        <div className="h-14 flex items-center justify-center mb-4 max-md:h-auto max-md:min-h-[48px]">
          <p
            key={`desc-${activeIndex}`}
            className="max-w-[680px] mx-auto text-slate-100 text-[0.96rem] leading-[1.55] font-normal [text-shadow:0_2px_10px_rgba(0,0,0,0.9),0_1px_3px_rgba(0,0,0,0.9)] line-clamp-2 overflow-hidden animate-fadeInText max-md:text-[0.88rem] max-md:line-clamp-3"
          >
            {current.description ||
              "Trải nghiệm các thiết bị công nghệ đẳng cấp được thiết kế tinh tế, hiệu năng mạnh mẽ và đón đầu xu hướng tương lai."}
          </p>
        </div>

        {/* Hint bấm xem sản phẩm */}
        <div className="inline-flex items-center gap-1.5 text-[0.8rem] font-semibold text-sky-400 mb-5 bg-slate-900/55 py-1 px-3 rounded-full border border-sky-400/30 shadow-[0_2px_8px_rgba(0,0,0,0.3)] transition-all duration-200 group-hover/banner:bg-sky-400/18 group-hover/banner:border-sky-400 group-hover/banner:text-white">
          <span>Khám phá sản phẩm ngay</span>
          <span className="transition-transform duration-200 group-hover/banner:translate-x-1">
            →
          </span>
        </div>

        {/* Thanh điều khiển Controls: Chuyển slide 3 giây */}
        <div
          className="inline-flex items-center gap-3.5 py-1.5 px-3.5 rounded-full bg-slate-900/80 border border-white/[0.22] backdrop-blur-md shadow-[0_8px_24px_rgba(0,0,0,0.4)] cursor-default"
          onClick={(e) => e.stopPropagation()}
        >
          <button
            type="button"
            className="bg-transparent border-none text-slate-200 w-7 h-7 rounded-full flex items-center justify-center cursor-pointer transition-all duration-200 p-0 hover:bg-white/25 hover:text-white hover:scale-110"
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

          <div className="flex items-center gap-2">
            {banners.map((_, idx) => {
              const isCurrent = idx === activeIndex;
              return (
                <button
                  key={idx}
                  type="button"
                  className="bg-transparent border-none py-1 px-0 cursor-pointer"
                  onClick={(e) => {
                    e.stopPropagation();
                    goToSlide(idx);
                  }}
                  aria-label={`Chuyển tới ảnh ${idx + 1}`}
                  title={`Ảnh ${idx + 1}`}
                >
                  <span
                    className={cn(
                      "block h-1 rounded-[2px] overflow-hidden relative transition-[width,background] duration-300",
                      isCurrent
                        ? "w-[44px] bg-white/40 max-md:w-[32px]"
                        : "w-[26px] bg-white/30 max-md:w-[18px]"
                    )}
                  >
                    {isCurrent && !isPaused && (
                      <span
                        key={`prog-${activeIndex}-${isPaused}`}
                        className="absolute top-0 left-0 h-full w-0 bg-gradient-to-r from-sky-400 to-rose-500 rounded-[2px] animate-progressFill"
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
            className="bg-transparent border-none text-slate-200 w-7 h-7 rounded-full flex items-center justify-center cursor-pointer transition-all duration-200 p-0 hover:bg-white/25 hover:text-white hover:scale-110"
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

          <span className="text-xs font-bold text-slate-300 tracking-[0.05em] pl-1 select-none max-[480px]:hidden">
            0{activeIndex + 1} / 0{total}
          </span>
        </div>
      </div>
    </section>
  );
}
