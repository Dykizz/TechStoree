"use client";

import { useEffect, useRef, useState } from "react";
import { formatPrice, formatShortPrice } from "../../lib/products-client";
import styles from "./PriceFilterDropdown.module.css";

export interface PriceFilterDropdownProps {
  minPrice?: number;
  maxPrice?: number;
  onChange: (minPrice?: number, maxPrice?: number) => void;
  systemMinPrice?: number;
  systemMaxPrice?: number;
}

interface PricePreset {
  id: string;
  label: string;
  desc: string;
  min?: number;
  max?: number;
}

const PRESETS: PricePreset[] = [
  { id: "all", label: "Tất cả mức giá", desc: "Toàn bộ dải giá" },
  { id: "under-2m", label: "Dưới 2 triệu", desc: "< 2.000.000 ₫", max: 2000000 },
  { id: "2m-5m", label: "2 - 5 triệu", desc: "2.000.000 - 5.000.000 ₫", min: 2000000, max: 5000000 },
  { id: "2m-10m", label: "2 - 10 triệu", desc: "2.000.000 - 10.000.000 ₫", min: 2000000, max: 10000000 },
  { id: "5m-10m", label: "5 - 10 triệu", desc: "5.000.000 - 10.000.000 ₫", min: 5000000, max: 10000000 },
  { id: "10m-20m", label: "10 - 20 triệu", desc: "10.000.000 - 20.000.000 ₫", min: 10000000, max: 20000000 },
  { id: "above-20m", label: "Trên 20 triệu", desc: "> 20.000.000 ₫", min: 20000000 },
];

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

  // Sync state if props change externally (e.g. Reset All Filters)
  useEffect(() => {
    setInputMin(minPrice !== undefined ? minPrice.toLocaleString("vi-VN") : "");
    setInputMax(maxPrice !== undefined ? maxPrice.toLocaleString("vi-VN") : "");
    setErrorMsg("");
  }, [minPrice, maxPrice]);

  // Click outside and escape key handling
  useEffect(() => {
    if (!isOpen) return;

    function handleClickOutside(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setIsOpen(false);
      }
    }

    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [isOpen]);

  const hasFilter = minPrice !== undefined || maxPrice !== undefined;

  // Determine active preset (if any)
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

  // Calculate trigger button label
  const getTriggerLabel = () => {
    if (activePreset && activePreset.id !== "all") {
      return activePreset.label;
    }
    if (minPrice !== undefined && maxPrice !== undefined) {
      return `${formatShortPrice(minPrice)} - ${formatShortPrice(maxPrice)}`;
    }
    if (minPrice !== undefined) {
      return `≥ ${formatShortPrice(minPrice)}`;
    }
    if (maxPrice !== undefined) {
      return `≤ ${formatShortPrice(maxPrice)}`;
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
      setInputMin(preset.min ? preset.min.toLocaleString("vi-VN") : "");
      setInputMax(preset.max ? preset.max.toLocaleString("vi-VN") : "");
      onChange(preset.min, preset.max);
    }
    setIsOpen(false);
  };

  const handleApplyCustom = (e: React.FormEvent) => {
    e.preventDefault();
    const parsedMin = parseNumberInput(inputMin);
    const parsedMax = parseNumberInput(inputMax);

    if (
      parsedMin !== undefined &&
      parsedMax !== undefined &&
      parsedMin > parsedMax
    ) {
      setErrorMsg("Giá tối thiểu không được lớn hơn giá tối đa.");
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
    <div className={styles.container} ref={containerRef}>
      {/* Trigger Button */}
      <button
        type="button"
        className={`${styles.triggerBtn} ${hasFilter ? styles.triggerBtnActive : ""}`}
        onClick={() => setIsOpen((prev) => !prev)}
        aria-haspopup="dialog"
        aria-expanded={isOpen}
        title="Lọc sản phẩm theo khoảng giá"
      >
        <svg
          className={styles.triggerIcon}
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

        <span className={styles.triggerLabel}>{getTriggerLabel()}</span>

        {hasFilter && <span className={styles.triggerBadge} />}

        {hasFilter && (
          <span
            role="button"
            tabIndex={0}
            className={styles.clearTriggerBtn}
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
          className={`${styles.chevron} ${isOpen ? styles.chevronOpen : ""}`}
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

      {/* Popover Content */}
      {isOpen && (
        <div className={styles.popover} role="dialog" aria-label="Bộ lọc khoảng giá">
          <div className={styles.popoverHeader}>
            <span className={styles.popoverTitle}>
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
                className={styles.resetLink}
                onClick={handleClear}
              >
                Thiết lập lại
              </button>
            )}
          </div>

          {(systemMinPrice !== undefined || systemMaxPrice !== undefined) && (
            <div className={styles.systemPriceHint}>
              <span>💡 Dải giá hệ thống:</span>
              <strong>
                {systemMinPrice !== undefined ? formatPrice(systemMinPrice) : "0 ₫"}
                {" - "}
                {systemMaxPrice !== undefined ? formatPrice(systemMaxPrice) : "cao nhất"}
              </strong>
            </div>
          )}

          {/* Quick Preset Buttons */}
          <div className={styles.sectionLabel}>Phân khúc phổ biến</div>
          <div className={styles.presetsGrid}>
            {PRESETS.map((preset) => {
              const isSelected = activePreset?.id === preset.id;
              return (
                <button
                  key={preset.id}
                  type="button"
                  className={`${styles.presetBtn} ${isSelected ? styles.presetBtnActive : ""}`}
                  onClick={() => handleSelectPreset(preset)}
                >
                  <span className={styles.presetLabel}>{preset.label}</span>
                  <span className={styles.presetDesc}>{preset.desc}</span>
                </button>
              );
            })}
          </div>

          <div className={styles.divider} />

          {/* Custom Range Inputs */}
          <form onSubmit={handleApplyCustom} className={styles.customSection}>
            <div className={styles.sectionLabel}>Tự nhập khoảng giá</div>
            <div className={styles.inputsRow}>
              <div className={styles.inputGroup}>
                <label htmlFor="price-min-input" className={styles.inputLabel}>
                  Từ giá
                </label>
                <div className={styles.inputWrap}>
                  <input
                    id="price-min-input"
                    type="text"
                    inputMode="numeric"
                    className={styles.customInput}
                    placeholder="0"
                    value={inputMin}
                    onChange={(e) => {
                      setInputMin(formatNumberInput(e.target.value));
                      setErrorMsg("");
                    }}
                  />
                  <span className={styles.currencySuffix}>₫</span>
                </div>
              </div>

              <span className={styles.rangeDash}>—</span>

              <div className={styles.inputGroup}>
                <label htmlFor="price-max-input" className={styles.inputLabel}>
                  Đến giá
                </label>
                <div className={styles.inputWrap}>
                  <input
                    id="price-max-input"
                    type="text"
                    inputMode="numeric"
                    className={styles.customInput}
                    placeholder="30.000.000"
                    value={inputMax}
                    onChange={(e) => {
                      setInputMax(formatNumberInput(e.target.value));
                      setErrorMsg("");
                    }}
                  />
                  <span className={styles.currencySuffix}>₫</span>
                </div>
              </div>
            </div>

            {errorMsg && (
              <div className={styles.errorMessage} role="alert">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="12" cy="12" r="10" />
                  <line x1="12" y1="8" x2="12" y2="12" />
                  <line x1="12" y1="16" x2="12.01" y2="16" />
                </svg>
                {errorMsg}
              </div>
            )}

            <div className={styles.actionsRow}>
              <button type="submit" className={styles.applyBtn}>
                Áp dụng
              </button>
              <button
                type="button"
                className={styles.closeBtn}
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
