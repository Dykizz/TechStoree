"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import { formatPrice, formatShortPrice } from "@/lib/products-client";
import { useClickOutside } from "@/hooks/useClickOutside";
import PricePresets, { PRESETS, type PricePreset } from "./PricePresets";
import { cn } from "@/lib/utils";

export interface PriceFilterDropdownProps {
  minPrice?: number;
  maxPrice?: number;
  onChange: (minPrice?: number, maxPrice?: number) => void;
  systemMinPrice?: number;
  systemMaxPrice?: number;
}

function formatNumberInput(value: string): string {
  const digits = value.replace(/\D/g, "");
  if (!digits) return "";
  const num = parseInt(digits, 10);
  return num.toLocaleString("vi-VN");
}

function parseNumberInput(value: string): number | undefined {
  const digits = value.replace(/\D/g, "");
  if (!digits) return undefined;
  const num = parseInt(digits, 10);
  return isNaN(num) ? undefined : num;
}

export default function PriceFilterDropdown({
  minPrice,
  maxPrice,
  onChange,
  systemMinPrice,
  systemMaxPrice,
}: PriceFilterDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [inputMin, setInputMin] = useState(
    minPrice !== undefined ? minPrice.toLocaleString("vi-VN") : ""
  );
  const [inputMax, setInputMax] = useState(
    maxPrice !== undefined ? maxPrice.toLocaleString("vi-VN") : ""
  );
  const [errorMsg, setErrorMsg] = useState("");

  const containerRef = useRef<HTMLDivElement>(null);

  // Sync state cleanly when props change externally without cascading render
  const [prevPrices, setPrevPrices] = useState({ minPrice, maxPrice });
  if (prevPrices.minPrice !== minPrice || prevPrices.maxPrice !== maxPrice) {
    setPrevPrices({ minPrice, maxPrice });
    setInputMin(minPrice !== undefined ? minPrice.toLocaleString("vi-VN") : "");
    setInputMax(maxPrice !== undefined ? maxPrice.toLocaleString("vi-VN") : "");
    setErrorMsg("");
  }

  // Click outside and escape key handling
  useClickOutside(containerRef, () => setIsOpen(false), isOpen);

  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") setIsOpen(false);
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen]);

  const hasFilter = minPrice !== undefined || maxPrice !== undefined;

  const activePreset = PRESETS.find((preset) => {
    if (preset.id === "all") return !hasFilter;
    if (preset.min !== undefined && preset.max !== undefined) {
      return minPrice === preset.min && maxPrice === preset.max;
    }
    if (preset.min !== undefined) {
      return minPrice === preset.min && maxPrice === undefined;
    }
    if (preset.max !== undefined) {
      return maxPrice === preset.max && minPrice === undefined;
    }
    return false;
  });

  const getTriggerLabel = (): string => {
    if (!hasFilter) return "Khoảng giá";
    if (activePreset && activePreset.id !== "all") {
      return activePreset.label;
    }
    if (minPrice !== undefined && maxPrice !== undefined) {
      return `${formatShortPrice(minPrice)} - ${formatShortPrice(maxPrice)}`;
    }
    if (minPrice !== undefined) {
      return `Từ ${formatShortPrice(minPrice)}`;
    }
    if (maxPrice !== undefined) {
      return `Đến ${formatShortPrice(maxPrice)}`;
    }
    return "Khoảng giá";
  };

  const handleSelectPreset = (preset: PricePreset) => {
    setErrorMsg("");
    if (preset.id === "all") {
      setInputMin("");
      setInputMax("");
      onChange(undefined, undefined);
    } else {
      setInputMin(preset.min !== undefined ? preset.min.toLocaleString("vi-VN") : "");
      setInputMax(preset.max !== undefined ? preset.max.toLocaleString("vi-VN") : "");
      onChange(preset.min, preset.max);
    }
    setIsOpen(false);
  };

  const handleApplyCustom = (e: FormEvent) => {
    e.preventDefault();
    const parsedMin = parseNumberInput(inputMin);
    const parsedMax = parseNumberInput(inputMax);

    if (parsedMin !== undefined && parsedMax !== undefined && parsedMin > parsedMax) {
      setErrorMsg("Giá tối thiểu không được lớn hơn giá tối đa.");
      return;
    }

    if (parsedMin === undefined && parsedMax === undefined) {
      setErrorMsg("Vui lòng nhập ít nhất một mức giá.");
      return;
    }

    setErrorMsg("");
    onChange(parsedMin, parsedMax);
    setIsOpen(false);
  };

  const handleClear = (e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    setInputMin("");
    setInputMax("");
    setErrorMsg("");
    onChange(undefined, undefined);
  };

  return (
    <div className="relative inline-block" ref={containerRef}>
      <button
        type="button"
        className={cn(
          "inline-flex items-center gap-2 px-3.5 py-2.5 border rounded-md text-[0.9rem] cursor-pointer outline-none transition-all duration-200 whitespace-nowrap select-none",
          hasFilter
            ? "border-ink bg-[#f7f7f7] text-ink font-semibold shadow-[0_1px_4px_rgba(0,0,0,0.05)]"
            : "border-[#e0e0e0] bg-white text-[#333333] hover:border-ink hover:text-ink"
        )}
        onClick={() => {
          if (!isOpen) {
            setInputMin(minPrice?.toLocaleString("vi-VN") ?? "");
            setInputMax(maxPrice?.toLocaleString("vi-VN") ?? "");
            setErrorMsg("");
          }
          setIsOpen((prev) => !prev);
        }}
        aria-haspopup="dialog"
        aria-expanded={isOpen}
        title="Lọc sản phẩm theo khoảng giá"
      >
        <svg
          className={cn(
            "shrink-0 transition-colors",
            hasFilter ? "text-ink" : "text-[#666666]"
          )}
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
        </svg>

        <span className="inline-block max-w-[170px] overflow-hidden text-ellipsis whitespace-nowrap">
          {getTriggerLabel()}
        </span>

        {hasFilter && (
          <span className="inline-flex items-center justify-center w-1.5 h-1.5 rounded-full bg-[#e52d27]" />
        )}

        {hasFilter && (
          <span
            role="button"
            tabIndex={0}
            className="inline-flex items-center justify-center w-[18px] h-[18px] rounded-full border-none bg-[#e8e8e8] text-[#555555] text-[11px] cursor-pointer ml-0.5 transition-colors hover:bg-ink hover:text-white"
            onClick={handleClear}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                handleClear();
              }
            }}
            title="Xóa lọc giá"
            aria-label="Xóa lọc giá"
          >
            ✕
          </span>
        )}

        <svg
          className={cn(
            "text-[#888888] transition-transform duration-200 shrink-0",
            isOpen && "rotate-180"
          )}
          width="14"
          height="14"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="m6 9 6 6 6-6" />
        </svg>
      </button>

      {isOpen && (
        <div
          className="absolute top-[calc(100%+8px)] right-0 w-[360px] max-w-[calc(100vw-32px)] bg-white border border-[#e5e5e5] rounded-xl shadow-[0_14px_40px_rgba(0,0,0,0.12)] p-[18px] z-[100] animate-popoverFadeIn max-[480px]:w-[320px] max-[480px]:right-auto max-[480px]:left-0"
          role="dialog"
          aria-label="Bộ lọc khoảng giá"
        >
          <div className="flex items-center justify-between mb-3">
            <span className="text-[0.95rem] font-bold text-ink flex items-center gap-1.5">
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" />
              </svg>
              Lọc theo khoảng giá
            </span>
            {hasFilter && (
              <button
                type="button"
                className="bg-transparent border-none text-[0.8rem] text-[#777777] underline cursor-pointer p-0 transition-colors hover:text-brand"
                onClick={handleClear}
              >
                Thiết lập lại
              </button>
            )}
          </div>

          {(systemMinPrice !== undefined || systemMaxPrice !== undefined) && (
            <div className="flex items-center gap-1.5 bg-[#f7f7f7] border border-[#ebebeb] rounded-md py-[7px] px-2.5 text-[0.78rem] text-[#555555] mb-3.5 [&_strong]:text-ink">
              <span>💡 Dải giá hệ thống:</span>
              <strong>
                {systemMinPrice !== undefined
                  ? formatPrice(systemMinPrice)
                  : "0 ₫"}
                {" - "}
                {systemMaxPrice !== undefined
                  ? formatPrice(systemMaxPrice)
                  : "cao nhất"}
              </strong>
            </div>
          )}

          <div className="text-[0.75rem] font-semibold uppercase tracking-[0.06em] text-[#888888] mb-2">
            Phân khúc phổ biến
          </div>
          <PricePresets
            activePresetId={activePreset?.id}
            onSelectPreset={handleSelectPreset}
          />

          <div className="h-[1px] bg-[#eeeeee] my-3.5" />

          <form onSubmit={handleApplyCustom} className="flex flex-col gap-2">
            <div className="text-[0.75rem] font-semibold uppercase tracking-[0.06em] text-[#888888] mb-2">
              Tự nhập khoảng giá
            </div>
            <div className="flex items-end gap-2">
              <div className="flex-1 flex flex-col gap-1">
                <label htmlFor="price-min-input" className="text-[0.72rem] text-[#666666] font-medium">
                  Từ giá
                </label>
                <div className="relative flex items-center">
                  <input
                    id="price-min-input"
                    type="text"
                    inputMode="numeric"
                    className="w-full py-2 pr-6 pl-2.5 border border-[#d5d5d5] rounded-md text-[0.85rem] text-ink outline-none bg-white transition-[border-color,box-shadow] duration-200 focus:border-ink focus:ring-1 focus:ring-ink placeholder:text-[#b5b5b5]"
                    placeholder="0"
                    value={inputMin}
                    onChange={(e) => {
                      setInputMin(formatNumberInput(e.target.value));
                      setErrorMsg("");
                    }}
                  />
                  <span className="absolute right-2 text-xs text-[#888888] pointer-events-none font-medium">
                    ₫
                  </span>
                </div>
              </div>

              <span className="text-[0.9rem] text-[#999999] font-semibold mb-2">
                —
              </span>

              <div className="flex-1 flex flex-col gap-1">
                <label htmlFor="price-max-input" className="text-[0.72rem] text-[#666666] font-medium">
                  Đến giá
                </label>
                <div className="relative flex items-center">
                  <input
                    id="price-max-input"
                    type="text"
                    inputMode="numeric"
                    className="w-full py-2 pr-6 pl-2.5 border border-[#d5d5d5] rounded-md text-[0.85rem] text-ink outline-none bg-white transition-[border-color,box-shadow] duration-200 focus:border-ink focus:ring-1 focus:ring-ink placeholder:text-[#b5b5b5]"
                    placeholder="30.000.000"
                    value={inputMax}
                    onChange={(e) => {
                      setInputMax(formatNumberInput(e.target.value));
                      setErrorMsg("");
                    }}
                  />
                  <span className="absolute right-2 text-xs text-[#888888] pointer-events-none font-medium">
                    ₫
                  </span>
                </div>
              </div>
            </div>

            {errorMsg && (
              <div className="text-xs text-[#d32f2f] bg-[#fde8e8] py-1.5 px-2.5 rounded-md flex items-center gap-1.5" role="alert">
                <svg
                  width="14"
                  height="14"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                >
                  <circle cx="12" cy="12" r="10" />
                  <line x1="12" y1="8" x2="12" y2="12" />
                  <line x1="12" y1="16" x2="12.01" y2="16" />
                </svg>
                {errorMsg}
              </div>
            )}

            <div className="flex items-center gap-2 mt-1.5">
              <button
                type="submit"
                className="flex-1 py-[9px] px-4 bg-ink text-white border-none rounded-md text-[0.85rem] font-semibold cursor-pointer transition-colors hover:bg-[#2b2b2b] text-center"
              >
                Áp dụng
              </button>
              <button
                type="button"
                className="py-[9px] px-3.5 border border-[#d5d5d5] bg-white text-[#444444] rounded-md text-[0.85rem] cursor-pointer transition-all hover:border-ink hover:text-ink"
                onClick={() => setIsOpen(false)}
              >
                Đóng
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
