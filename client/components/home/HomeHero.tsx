"use client";

import Image from "next/image";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { cn } from "@/lib/utils";

const ROTATION_MS = 5_000;
const TRANSITION_MS = 800;
const slides = [
  { name: "iPhone 18 Pro", image: "/images/showcase-iphone-18-pro-lettering.png", theme: "pro" },
  { name: "iPhone Duo", image: "/images/showcase-iphone-duo.png", theme: "duo" },
  { name: "AirPods Pro 3", image: "/images/showcase-airpods-pro-3.png", theme: "airpods" },
  { name: "Galaxy Z Fold8", image: "/images/showcase-galaxy-z-fold8.png", theme: "galaxy" },
] as const;

const themeVars: Record<string, Record<string, string>> = {
  pro: { "--canvas": "#000", "--foreground": "#f5f5f7", "--muted": "#b8b8bf", "--accent": "#ff7d88" },
  duo: { "--canvas": "#f6f5f8", "--foreground": "#1d1d1f", "--muted": "#64646b", "--accent": "#ba2030" },
  airpods: { "--canvas": "#fdfdfb", "--foreground": "#1d1d1f", "--muted": "#64646b", "--accent": "#ba2030" },
  galaxy: { "--canvas": "#514971", "--foreground": "#f5f5f7", "--muted": "#e0daef", "--accent": "#ffadb5" },
};

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
      className="relative isolate overflow-hidden min-h-[620px] lg:min-h-[720px] max-md:min-h-[840px] bg-black"
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
        const isGalaxy = slide.theme === "galaxy";
        return (
          <div
            key={slide.name}
            style={themeVars[slide.theme] as React.CSSProperties}
            className={cn(
              "absolute inset-0 invisible pointer-events-none bg-[var(--canvas)] text-[var(--foreground)]",
              active && "!visible !pointer-events-auto z-10",
              outgoing && "!visible z-0",
              active && frame.previous !== null && "animate-reveal motion-reduce:animate-none"
            )}
            aria-hidden={!active}
            inert={!active}
            role="group"
            aria-roledescription="ảnh trình chiếu"
            aria-label={`${index + 1} / ${slides.length}: ${slide.name}`}
          >
            <div
              className={cn(
                "absolute inset-[4%_-4%_0_28%] 2xl:inset-[4%_2%_0_34%] max-md:inset-[auto_0_85px] max-md:h-[360px]",
                isGalaxy
                  ? "[mask-image:linear-gradient(to_right,transparent,#000_22%),linear-gradient(to_bottom,transparent,#000_12%,#000_88%,transparent)] [mask-composite:intersect] max-md:[mask-image:linear-gradient(to_bottom,transparent,#000_12%,#000_88%,transparent)]"
                  : "[mask-image:linear-gradient(to_right,transparent,#000_18%)] max-md:[mask-image:none]"
              )}
            >
              <Image
                src={slide.image}
                alt=""
                fill
                className="object-contain [object-position:center_70%] max-md:object-center"
                sizes="(max-width: 768px) 100vw, 75vw"
                loading="eager"
                fetchPriority={index === 0 ? "high" : "auto"}
                onLoad={async (event) => {
                  const image = event.currentTarget;
                  try { await image.decode(); } catch { /* onLoad already confirms a usable image. */ }
                  setReady((current) => current.map((value, i) => i === index ? true : value));
                }}
              />
            </div>
            <div className="absolute inset-0 pointer-events-none bg-[linear-gradient(90deg,var(--canvas)_0%,color-mix(in_srgb,var(--canvas)_94%,transparent)_25%,color-mix(in_srgb,var(--canvas)_65%,transparent)_43%,transparent_65%)] max-md:bg-[linear-gradient(to_bottom,var(--canvas)_0%,var(--canvas)_44%,transparent_63%)]" />
            <div className="relative max-w-7xl min-h-[620px] lg:min-h-[720px] max-md:min-h-[840px] mx-auto px-8 pt-20 pb-28 max-lg:pt-14 max-md:px-5 max-md:pt-10 max-md:pb-96 flex items-center max-md:items-start">
              <div className="max-w-lg w-1/2 max-lg:w-3/5 max-md:w-full">
                <p className="text-[var(--accent)] text-xs font-bold tracking-widest leading-relaxed">
                  TECHSTOREE · CÔNG NGHỆ CHO MỖI NGÀY
                </p>
                <h1 className="mt-5 mb-6 max-md:mt-4 max-md:mb-5 text-4xl sm:text-5xl lg:text-6xl font-semibold tracking-tight leading-tight [text-wrap:balance]">
                  Nguyên bản.<br />
                  <span className="text-[var(--muted)]">Tinh tế trong từng lựa chọn.</span>
                </h1>
                <p className="max-w-md text-[var(--muted)] text-sm sm:text-base leading-relaxed">
                  Khám phá thiết bị phù hợp với cách bạn làm việc, sáng tạo và tận hưởng cuộc sống.
                </p>
                <div className="flex flex-wrap gap-5 max-md:gap-4 items-center mt-7">
                  <Link
                    href="/products"
                    className="inline-flex items-center gap-3 px-5 py-3.5 rounded-lg bg-[var(--foreground)] text-[var(--canvas)] text-sm font-semibold no-underline transition-colors duration-200 hover:bg-brand hover:text-white motion-reduce:transition-none focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-4"
                  >
                    Khám phá sản phẩm <span aria-hidden="true">↗</span>
                  </Link>
                  <Link
                    href="/products?onSale=true"
                    className="text-[var(--foreground)] no-underline text-sm font-semibold hover:underline hover:underline-offset-4 focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-4"
                  >
                    Xem ưu đãi hiện có <span aria-hidden="true">→</span>
                  </Link>
                </div>
              </div>
              <p className="absolute right-8 max-md:right-5 bottom-9 max-md:bottom-7 grid gap-1 text-sm font-semibold text-right">
                {slide.name}
                <span className="text-[var(--muted)] text-xs font-normal tracking-wide">
                  Hình ảnh tham khảo
                </span>
              </p>
            </div>
          </div>
        );
      })}
    </section>
  );
}
