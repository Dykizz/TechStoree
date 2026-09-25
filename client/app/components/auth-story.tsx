"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import styles from "../page.module.css";

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
      className={styles.story}
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
        return (
          <div
            key={slide.image}
            className={`${styles.storyScene} ${slide.theme === "light" ? styles.storyLight : ""} ${isActive ? styles.storySceneActive : ""} ${isPrevious ? styles.storyScenePrevious : ""} ${isActive && previousIndex !== null ? styles.storySceneEntering : ""}`}
            style={{ background: slide.backdrop }}
            aria-hidden={!isActive}
          >
            <div className={styles.storyMedia}>
              {slide.product === "GALAXY Z FOLD8" && (
                <div
                  className={styles.storyMediaAmbience}
                  style={{ backgroundImage: `url("${slide.image}")` }}
                  aria-hidden="true"
                />
              )}
              <div className={`${styles.productFrame} ${slide.product === "GALAXY Z FOLD8" ? styles.productFrameSoftEdge : ""}`}>
                <Image
                  src={slide.image}
                  alt={isActive ? slide.alt : ""}
                  fill
                  sizes="(max-width: 900px) 100vw, 52vw"
                  loading="eager"
                  className={styles.productImage}
                />
              </div>
            </div>
            <div className={styles.storyInner}>
              <div className={styles.brand} aria-label="TechStoree">
                <span className={styles.brandMark} aria-hidden="true" />
                <span>TECHSTOREE</span>
              </div>
              <div className={styles.storyContent} aria-live="off">
                <p className={styles.storyEyebrow}>{slide.eyebrow}</p>
                <h1>{slide.title}<span>{slide.subtitle}</span></h1>
                <p className={styles.storyDescription}>{slide.description}</p>
              </div>
              <div className={styles.storyFooter}>
                <span>© 2026 TECHSTOREE</span><span>HÌNH ẢNH THAM KHẢO</span>
              </div>
            </div>
          </div>
        );
      })}
      <div className={`${styles.storyNavigation} ${activeSlide.theme === "light" ? styles.storyLight : ""}`} aria-label="Điều khiển trình chiếu sản phẩm">
            <span className={styles.slideCount}>{String(activeIndex + 1).padStart(2, "0")} <span>/</span> {String(slides.length).padStart(2, "0")}</span>
            <div className={styles.slideSelectors}>
              {slides.map((slide, index) => (
                <button
                  key={slide.image}
                  type="button"
                  className={`${styles.slideSelector} ${index === activeIndex ? styles.slideSelectorActive : ""}`}
                  onClick={() => showSlide(index)}
                  aria-label={`Hiển thị ${slide.product}`}
                  aria-current={index === activeIndex ? "true" : undefined}
                />
              ))}
            </div>
            <div className={styles.slideArrows}>
              <button type="button" onClick={() => showSlide((activeIndex - 1 + slides.length) % slides.length)} aria-label="Sản phẩm trước">←</button>
              <button type="button" onClick={() => showSlide((activeIndex + 1) % slides.length)} aria-label="Sản phẩm tiếp theo">→</button>
            </div>
      </div>
    </section>
  );
}
