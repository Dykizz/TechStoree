"use client";

import Image from "next/image";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import styles from "./HomeHero.module.css";

const ROTATION_MS = 5_000;
const TRANSITION_MS = 800;
const slides = [
  { name: "iPhone 18 Pro", image: "/images/showcase-iphone-18-pro-lettering.png", theme: "pro" },
  { name: "iPhone Duo", image: "/images/showcase-iphone-duo.png", theme: "duo" },
  { name: "AirPods Pro 3", image: "/images/showcase-airpods-pro-3.png", theme: "airpods" },
  { name: "Galaxy Z Fold8", image: "/images/showcase-galaxy-z-fold8.png", theme: "galaxy" },
] as const;

export default function HomeHero() {
  const [frame, setFrame] = useState({ active: 0, previous: null as number | null });
  const [ready, setReady] = useState<boolean[]>(slides.map(() => false));
  const [focused, setFocused] = useState(false);
  const [hidden, setHidden] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);

  useEffect(() => {
    const preference = window.matchMedia("(prefers-reduced-motion: reduce)");
    const updateMotion = () => setReducedMotion(preference.matches);
    const updateVisibility = () => setHidden(document.hidden);
    updateMotion();
    updateVisibility();
    preference.addEventListener("change", updateMotion);
    document.addEventListener("visibilitychange", updateVisibility);
    return () => {
      preference.removeEventListener("change", updateMotion);
      document.removeEventListener("visibilitychange", updateVisibility);
    };
  }, []);

  const advance = useCallback((direction: number) => {
    setFrame((current) => {
      // Keep the outgoing scene mounted until the opaque incoming scene covers it.
      if (current.previous !== null) return current;
      for (let step = 1; step < slides.length; step++) {
        const next = (current.active + direction * step + slides.length) % slides.length;
        if (ready[next]) {
          return { active: next, previous: reducedMotion ? null : current.active };
        }
      }
      return current;
    });
  }, [ready, reducedMotion]);

  useEffect(() => {
    if (focused || hidden || reducedMotion) return;
    const timer = window.setInterval(() => advance(1), ROTATION_MS);
    return () => window.clearInterval(timer);
  }, [advance, focused, hidden, reducedMotion]);

  useEffect(() => {
    if (frame.previous === null) return;
    const timer = window.setTimeout(() => {
      setFrame((current) => ({ ...current, previous: null }));
    }, TRANSITION_MS);
    return () => window.clearTimeout(timer);
  }, [frame.active, frame.previous]);

  return (
    <section
      className={styles.hero}
      aria-label="Bộ sưu tập công nghệ TechStoree"
      aria-roledescription="trình chiếu"
      onFocusCapture={() => setFocused(true)}
      onBlurCapture={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) setFocused(false);
      }}
    >
      {slides.map((slide, index) => {
        const active = frame.active === index;
        const outgoing = frame.previous === index;
        return (
          <div
            key={slide.name}
            className={`${styles.scene} ${styles[slide.theme]} ${active ? styles.active : ""} ${outgoing ? styles.outgoing : ""} ${active && frame.previous !== null ? styles.entering : ""}`}
            aria-hidden={!active}
            inert={!active}
            role="group"
            aria-roledescription="ảnh trình chiếu"
            aria-label={`${index + 1} / ${slides.length}: ${slide.name}`}
          >
            <div className={styles.media}>
              <Image
                src={slide.image}
                alt=""
                fill
                sizes="(max-width: 760px) 100vw, 75vw"
                loading="eager"
                fetchPriority={index === 0 ? "high" : "auto"}
                onLoad={async (event) => {
                  const image = event.currentTarget;
                  try { await image.decode(); } catch { /* onLoad already confirms a usable image. */ }
                  setReady((current) => current.map((value, i) => i === index ? true : value));
                }}
              />
            </div>
            <div className={styles.scrim} />
            <div className={styles.inner}>
              <div className={styles.copy}>
                <p className={styles.eyebrow}>TECHSTOREE · CÔNG NGHỆ CHO MỖI NGÀY</p>
                <h1>Nguyên bản.<br /><span>Tinh tế trong từng lựa chọn.</span></h1>
                <p className={styles.subtitle}>
                  Khám phá thiết bị phù hợp với cách bạn làm việc, sáng tạo và tận hưởng cuộc sống.
                </p>
                <div className={styles.actions}>
                  <Link href="/products" className={styles.primary}>Khám phá sản phẩm <span aria-hidden="true">↗</span></Link>
                  <Link href="/products?onSale=true" className={styles.secondary}>Xem ưu đãi hiện có <span aria-hidden="true">→</span></Link>
                </div>
              </div>
              <p className={styles.caption}>{slide.name}<span>Hình ảnh tham khảo</span></p>
            </div>
          </div>
        );
      })}
    </section>
  );
}
