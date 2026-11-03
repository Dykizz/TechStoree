import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./providers/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      aspectRatio: {
        "4/3": "4 / 3",
      },
      spacing: {
        "4.5": "1.125rem", // 18px
        "7.5": "1.875rem", // 30px
        "8.5": "2.125rem", // 34px
      },
      colors: {
        brand: {
          DEFAULT: "var(--brand, #bd202d)",
          hover: "var(--brand-hover, #9e1925)",
        },
        ink: "var(--ink, #1d1d1f)",
        muted: "var(--muted, #6e6e73)",
        surface: "var(--surface, #f5f5f7)",
        border: "var(--border, #e5e5e7)",
      },
      fontFamily: {
        sans: [
          '"Inter Variable"',
          "-apple-system",
          "BlinkMacSystemFont",
          '"Segoe UI"',
          "sans-serif",
        ],
      },
      keyframes: {
        fadeIn: {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        slideUp: {
          "0%": { opacity: "0", transform: "translateY(16px) scale(0.98)" },
          "100%": { opacity: "1", transform: "translateY(0) scale(1)" },
        },
        slideDown: {
          "0%": { opacity: "0", transform: "translateY(-10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        drawerSlideIn: {
          "0%": { transform: "translateX(100%)" },
          "100%": { transform: "translateX(0)" },
        },
        pulseGlow: {
          "0%, 100%": { opacity: "1", transform: "scale(1)" },
          "50%": { opacity: "0.7", transform: "scale(1.05)" },
        },
        popoverFadeIn: {
          "0%": { opacity: "0", transform: "translateY(-8px) scale(0.98)" },
          "100%": { opacity: "1", transform: "translateY(0) scale(1)" },
        },
        fadeInText: {
          "0%": { opacity: "0", transform: "translateY(6px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        progressFill: {
          "0%": { width: "0%" },
          "100%": { width: "100%" },
        },
        storyReveal: {
          "0%": { clipPath: "inset(0 100% 0 0)" },
          "100%": { clipPath: "inset(0)" },
        },
        reveal: {
          "0%": { clipPath: "inset(0 0 0 100%)" },
          "100%": { clipPath: "inset(0)" },
        },
        radarRipple: {
          "0%": { transform: "scale(0.6)", opacity: "1" },
          "100%": { transform: "scale(2.2)", opacity: "0" },
        },
        receiptIn: {
          from: { opacity: "0", transform: "translateY(12px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        iconIn: {
          from: { opacity: "0", transform: "scale(.88)" },
          to: { opacity: "1", transform: "scale(1)" },
        },
        drawCheck: {
          from: { strokeDashoffset: "30" },
          to: { strokeDashoffset: "0" },
        },
        zoomIn: {
          from: { opacity: "0", transform: "scale(0.92)" },
          to: { opacity: "1", transform: "scale(1)" },
        },
      },
      animation: {
        fadeIn: "fadeIn 0.2s ease-out",
        slideUp: "slideUp 0.25s cubic-bezier(0.16, 1, 0.3, 1)",
        slideDown: "slideDown 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
        popoverFadeIn: "popoverFadeIn 0.18s cubic-bezier(0.16, 1, 0.3, 1)",
        fadeInText: "fadeInText 0.45s ease-out",
        progressFill: "progressFill linear forwards",
        storyReveal: "storyReveal 820ms cubic-bezier(0.65, 0, 0.2, 1) both",
        drawerSlideIn: "drawerSlideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1)",
        pulseGlow: "pulseGlow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        reveal: "reveal 800ms cubic-bezier(.22, .68, .16, 1) both",
        radarRipple: "radarRipple 1.6s cubic-bezier(0, 0.2, 0.8, 1) infinite",
        receiptIn: "receiptIn 480ms cubic-bezier(.22, .68, .16, 1) both",
        iconIn: "iconIn 420ms ease both",
        drawCheck: "drawCheck 600ms 100ms ease both",
        zoomIn: "zoomIn 0.25s cubic-bezier(0.16, 1, 0.3, 1)",
      },
    },
  },
  plugins: [],
};

export default config;
