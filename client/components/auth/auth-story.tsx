"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";

const ROTATION_MS = 5000;

const slides = [
  {
    eyebrow: "APPLE / IPHONE DUO",
    title: "iPhone Duo.",
    subtitle: "Không gian mới trong tay bạn.",
    description: "Mở ra một cách khác để xem, sáng tạo và kết nối mỗi ngày.",
    product: "IPHONE DUO",
    image: "/images/showcase-iphone-duo.png",
    alt: "iPhone Duo mở rộng được cầm bằng hai tay trên nền sáng",
    backdrop: "#f6f5f8",
    theme: "light",
  },
  {
    eyebrow: "APPLE / IPHONE 18 PRO",
    title: "iPhone 18 Pro.",
    subtitle: "Tinh tế trong từng đường nét.",
    description: "Một thiết kế đậm dấu ấn, dành cho những trải nghiệm bạn muốn khám phá sâu hơn.",
    product: "IPHONE 18 PRO",
    image: "/images/showcase-iphone-18-pro-lettering.png",
    alt: "iPhone 18 Pro màu đỏ sẫm nằm ngang trên nền đen",
    backdrop: "#000000",
    theme: "dark",
  },
  {
    eyebrow: "APPLE / AIRPODS PRO 3",
    title: "AirPods Pro 3.",
    subtitle: "Âm thanh theo cách của bạn.",
    description: "Gọn nhẹ, giản đơn và luôn sẵn sàng đồng hành cùng từng khoảnh khắc.",
    product: "AIRPODS PRO 3",
    image: "/images/showcase-airpods-pro-3.png",
    alt: "Một cặp tai nghe AirPods Pro 3 màu trắng trên nền sáng",
    backdrop: "#fdfdfb",
    theme: "light",
  },
  {
    eyebrow: "SAMSUNG / GALAXY Z FOLD8",
    title: "Galaxy Z Fold8.",
    subtitle: "Mở ra góc nhìn mới.",
    description: "Một thiết kế linh hoạt để ý tưởng và cảm hứng có thêm không gian.",
    product: "GALAXY Z FOLD8",
    image: "/images/showcase-galaxy-z-fold8.png",
    alt: "Galaxy Z Fold8 màu tím được cầm trong tay trên nền tím nhạt",
    backdrop: "radial-gradient(circle at 72% 67%, #51486f 0%, #302b45 43%, #1d1b28 82%)",
    theme: "dark",
  },
] as const;

export default function AuthStory() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [previousIndex, setPreviousIndex] = useState<number | null>(null);
  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);
  const [hidden, setHidden] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);

  useEffect(() => {
    const media = window.matchMedia("(prefers-reduced-motion: reduce)");
    const updateMotion = () => setReducedMotion(media.matches);
    const updateVisibility = () => setHidden(document.hidden);
    updateMotion();
    updateVisibility();
    media.addEventListener("change", updateMotion);
    document.addEventListener("visibilitychange", updateVisibility);
    return () => {
      media.removeEventListener("change", updateMotion);
      document.removeEventListener("visibilitychange", updateVisibility);
    };
  }, []);

  useEffect(() => {
    if (hovered || focused || hidden || reducedMotion) return;
    const timer = window.setTimeout(() => {
      setPreviousIndex(activeIndex);
      setActiveIndex((activeIndex + 1) % slides.length);
    }, ROTATION_MS);
    return () => window.clearTimeout(timer);
  }, [activeIndex, hovered, focused, hidden, reducedMotion]);

  useEffect(() => {
    if (previousIndex === null) return;
    const timer = window.setTimeout(() => setPreviousIndex(null), 900);
    return () => window.clearTimeout(timer);
  }, [activeIndex, previousIndex]);

  const showSlide = (index: number) => {
    if (index === activeIndex) return;
    setPreviousIndex(reducedMotion ? null : activeIndex);
    setActiveIndex(index);
  };

  const activeSlide = slides[activeIndex];

  return (
    <section
      className="relative overflow-hidden min-w-0 min-h-[100svh] bg-[#161719] text-[#f6f6f4] max-[900px]:min-h-[430px]"
      aria-label="Sản phẩm nổi bật TechStoree"
      onPointerEnter={() => setHovered(true)}
      onPointerLeave={() => setHovered(false)}
      onFocusCapture={() => setFocused(true)}
      onBlurCapture={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) setFocused(false);
      }}
    >
      {slides.map((slide, index) => {
        const isActive = index === activeIndex;
        const isPrevious = index === previousIndex;
        const isLight = slide.theme === "light";

        return (
          <div
            key={slide.image}
            className={cn(
              "absolute inset-0 overflow-hidden",
              isLight
                ? "[--story-eyebrow:#3a4c78] [--story-subtitle:#656b75] [--story-description:#555b65] [--story-counter:#272b32] [--story-counter-muted:#8b909a] [--story-selector:#a5aab4] [--story-selector-active:#272b32] [--story-footer:#696e77] text-[#1d2025]"
                : "[--story-eyebrow:#aab4ce] [--story-subtitle:#aeb0b6] [--story-description:#bcbdbd] [--story-counter:#f2f2ef] [--story-counter-muted:#858990] [--story-selector:#7b8190] [--story-selector-active:#f5f6f7] [--story-footer:#929496] text-[#f6f6f4]",
              isActive
                ? "z-[2] visible"
                : isPrevious
                ? "z-[1] visible"
                : "invisible",
              isActive && previousIndex !== null && "animate-storyReveal"
            )}
            style={{ background: slide.backdrop }}
            aria-hidden={!isActive}
          >
            <div
              className={cn(
                "absolute z-0 top-[43%] right-0 bottom-[112px] left-0 pointer-events-none max-[900px]:top-[42%] max-[900px]:bottom-[55px]",
                !isLight && "[mask-image:linear-gradient(to_bottom,transparent,#000_10%,#000_88%,transparent)]"
              )}
            >
              {slide.product === "GALAXY Z FOLD8" && (
                <div
                  className="absolute -inset-[30px] bg-center bg-cover blur-[44px] opacity-85"
                  style={{ backgroundImage: `url("${slide.image}")` }}
                  aria-hidden="true"
                />
              )}
              <div
                className={cn(
                  "absolute top-0 bottom-0 left-1/2 aspect-[16/9] max-w-full -translate-x-1/2",
                  slide.product === "GALAXY Z FOLD8" && "[mask-image:linear-gradient(to_right,transparent,#000_10%,#000_90%,transparent)]"
                )}
              >
                <Image
                  src={slide.image}
                  alt={isActive ? slide.alt : ""}
                  fill
                  sizes="(max-width: 900px) 100vw, 52vw"
                  loading="eager"
                  className="object-contain object-center"
                />
              </div>
            </div>
            <div className="relative z-[2] flex flex-col h-full min-h-[100svh] pt-[clamp(30px,4vw,64px)] px-[clamp(30px,5vw,80px)] pb-[27px] max-[1100px]:px-[35px] max-[900px]:h-auto max-[900px]:min-h-[430px] max-[900px]:py-6 max-[900px]:px-[25px] max-[900px]:pb-[18px]">
              <div className="inline-flex items-center gap-2.5 w-fit text-xs font-extrabold tracking-[0.08em]" aria-label="TechStoree">
                <span
                  className="relative inline-block shrink-0 w-[27px] h-[27px] rounded bg-[#d52432] before:content-[''] before:absolute before:block before:bg-white before:top-[7px] before:left-[5px] before:w-[17px] before:h-[4px] before:[clip-path:polygon(9%_0,100%_0,91%_100%,0_100%)] after:content-[''] after:absolute after:block after:bg-white after:top-[10px] after:left-[11px] after:w-[5px] after:h-[11px] after:[clip-path:polygon(0_0,100%_0,100%_76%,50%_100%,0_76%)]"
                  aria-hidden="true"
                />
                <span>TECHSTOREE</span>
              </div>
              <div className="max-w-[680px] mt-[clamp(34px,5vh,56px)] max-[900px]:mt-[26px]" aria-live="off">
                <p className="text-[var(--story-eyebrow)] text-[10px] font-extrabold tracking-[0.2em] uppercase">
                  {slide.eyebrow}
                </p>
                <h1 className="mt-5 text-[clamp(43px,3.8vw,60px)] font-[660] tracking-[-0.055em] leading-[1.1] max-[1100px]:text-[clamp(42px,4.1vw,58px)] max-[900px]:max-w-[610px] max-[900px]:mt-[11px] max-[900px]:text-[clamp(27px,6vw,38px)] max-[900px]:leading-[1.12]">
                  {slide.title}
                  <span className="block text-[var(--story-subtitle)] font-[520]">
                    {slide.subtitle}
                  </span>
                </h1>
                <p className="max-w-[410px] mt-[25px] text-[var(--story-description)] text-sm leading-[1.75] max-[900px]:hidden">
                  {slide.description}
                </p>
              </div>
              <div className="flex justify-between gap-[18px] mt-auto text-[var(--story-footer)] text-[9px] font-bold tracking-[0.13em] max-[900px]:hidden">
                <span>© 2026 TECHSTOREE</span>
                <span>HÌNH ẢNH THAM KHẢO</span>
              </div>
            </div>
          </div>
        );
      })}

      {/* Navigation Controls */}
      <div
        className={cn(
          "absolute z-[3] right-[clamp(30px,5vw,80px)] bottom-[56px] left-[clamp(30px,5vw,80px)] flex items-center justify-between min-h-[44px] max-[1100px]:right-[35px] max-[1100px]:left-[35px] max-[900px]:right-[25px] max-[900px]:left-[25px] max-[900px]:bottom-[18px]",
          activeSlide.theme === "light"
            ? "[--story-counter:#272b32] [--story-counter-muted:#8b909a] [--story-selector:#a5aab4] [--story-selector-active:#272b32] text-[#1d2025]"
            : "[--story-counter:#f2f2ef] [--story-counter-muted:#858990] [--story-selector:#7b8190] [--story-selector-active:#f5f6f7] text-[#f6f6f4]"
        )}
        aria-label="Điều khiển trình chiếu sản phẩm"
      >
        <span className="text-[var(--story-counter)] text-[11px] font-[750] tracking-[0.13em]">
          {String(activeIndex + 1).padStart(2, "0")}{" "}
          <span className="mx-1 text-[var(--story-counter-muted)]">/</span>{" "}
          {String(slides.length).padStart(2, "0")}
        </span>

        <div className="flex items-center gap-1">
          {slides.map((slide, index) => {
            const isSel = index === activeIndex;
            return (
              <button
                key={slide.image}
                type="button"
                className={cn(
                  "relative w-8 h-8 border-0 p-0 bg-transparent cursor-pointer before:content-[''] before:absolute before:right-[3px] before:left-[3px] before:top-[15px] before:transition-[background,height] before:duration-250 hover:before:h-[3px] hover:before:bg-[var(--story-selector-active)]",
                  isSel
                    ? "before:h-[3px] before:bg-[var(--story-selector-active)]"
                    : "before:h-[2px] before:bg-[var(--story-selector)]"
                )}
                onClick={() => showSlide(index)}
                aria-label={`Hiển thị ${slide.product}`}
                aria-current={isSel ? "true" : undefined}
              />
            );
          })}
        </div>

        <div className="flex gap-[7px] [&>button]:w-[34px] [&>button]:h-[34px] [&>button]:border [&>button]:border-current [&>button]:rounded-full [&>button]:bg-transparent [&>button]:text-inherit [&>button]:cursor-pointer [&>button]:text-[17px] [&>button]:opacity-65 [&>button]:transition-[background,opacity] [&>button]:duration-200 hover:[&>button]:bg-gray-500/12 hover:[&>button]:opacity-100 focus-visible:[&>button]:outline focus-visible:[&>button]:outline-2 focus-visible:[&>button]:outline-current focus-visible:[&>button]:outline-offset-2">
          <button
            type="button"
            onClick={() =>
              showSlide((activeIndex - 1 + slides.length) % slides.length)
            }
            aria-label="Sản phẩm trước"
          >
            ←
          </button>
          <button
            type="button"
            onClick={() => showSlide((activeIndex + 1) % slides.length)}
            aria-label="Sản phẩm tiếp theo"
          >
            →
          </button>
        </div>
      </div>
    </section>
  );
}
