"use client";

import Image from "next/image";
import { useRouter } from "next/navigation";
import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";
import { formatPrice } from "../../lib/products-client";
import {
  getAutocompleteSuggestions,
  type AutocompleteResult,
} from "../../lib/search/search-engine";
import type { ProductBaseDto } from "../../lib/types/product";
import styles from "./SearchBar.module.css";

const RECENT_SEARCHES_KEY = "techstoree_recent_searches";
const MAX_RECENT_ITEMS = 6;

// Danh mục từ khóa thịnh hành gợi ý sẵn
const TRENDING_SEARCHES = [
  "MacBook Air M3",
  "Sony WH-1000XM5",
  "Logitech MX Master 3S",
  "Laptop Gaming Nitro",
  "Bàn phím cơ FL-Esports",
  "Robot Xiaomi Dreame",
  "Màn hình Dell UltraSharp",
  "Tai nghe AirPods Pro 2",
];

interface SearchBarProps {
  value: string;
  onChange: (query: string) => void;
  onSearch: (query: string) => void;
  allProducts: ProductBaseDto[];
  placeholder?: string;
}

export default function SearchBar({
  value,
  onChange,
  onSearch,
  allProducts,
  placeholder = "Tìm kiếm máy tính, điện thoại, phụ kiện...",
}: SearchBarProps) {
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [recentSearches, setRecentSearches] = useState<string[]>([]);
  const [suggestions, setSuggestions] = useState<AutocompleteResult>({
    keywordSuggestions: [],
    products: [],
    hasTypo: false,
  });
  const [selectedIndex, setSelectedIndex] = useState<number>(-1);

  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);

  // 1. Tải lịch sử tìm kiếm từ localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem(RECENT_SEARCHES_KEY);
      if (saved) {
        setRecentSearches(JSON.parse(saved));
      }
    } catch {
      // Bỏ qua nếu môi trường không hỗ trợ localStorage
    }
  }, []);

  // 2. Lưu từ khóa vào lịch sử
  const saveToRecent = useCallback((query: string) => {
    const clean = query.trim();
    if (!clean) return;

    setRecentSearches((prev) => {
      const updated = [clean, ...prev.filter((item) => item.toLowerCase() !== clean.toLowerCase())].slice(
        0,
        MAX_RECENT_ITEMS,
      );
      try {
        localStorage.setItem(RECENT_SEARCHES_KEY, JSON.stringify(updated));
      } catch {
        // Safe ignore
      }
      return updated;
    });
  }, []);

  // Xóa 1 từ khóa khỏi lịch sử
  const removeRecentItem = (e: React.MouseEvent, itemToRemove: string) => {
    e.stopPropagation();
    setRecentSearches((prev) => {
      const updated = prev.filter((item) => item !== itemToRemove);
      try {
        localStorage.setItem(RECENT_SEARCHES_KEY, JSON.stringify(updated));
      } catch {
        // Safe ignore
      }
      return updated;
    });
  };

  // Xóa toàn bộ lịch sử
  const clearAllRecent = (e: React.MouseEvent) => {
    e.stopPropagation();
    setRecentSearches([]);
    try {
      localStorage.removeItem(RECENT_SEARCHES_KEY);
    } catch {
      // Safe ignore
    }
  };

  // 3. Tính toán gợi ý Autocomplete khi người dùng gõ (Debounce 150ms siêu tốc)
  useEffect(() => {
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }

    if (!value.trim()) {
      setSuggestions({
        keywordSuggestions: [],
        products: [],
        hasTypo: false,
      });
      return;
    }

    debounceTimerRef.current = setTimeout(() => {
      const result = getAutocompleteSuggestions(value, allProducts, 5, 4);
      setSuggestions(result);
    }, 120);

    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
  }, [value, allProducts]);

  // 4. Click ngoài để đóng dropdown
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // 5. Xử lý khi nộp tìm kiếm
  const handlePerformSearch = (query: string) => {
    const clean = query.trim();
    saveToRecent(clean);
    onChange(clean);
    onSearch(clean);
    setIsOpen(false);
  };

  // 6. Điều hướng bàn phím (Phím Mũi tên lên/xuống, Enter, Escape)
  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handlePerformSearch(value);
    } else if (e.key === "Escape") {
      setIsOpen(false);
      inputRef.current?.blur();
    }
  };

  const hasTypoCorrection = suggestions.hasTypo && suggestions.correctedQuery;
  const isTyping = value.trim().length > 0;

  return (
    <div className={styles.searchBarContainer} ref={containerRef}>
      {/* Khung nhập liệu tìm kiếm chính */}
      <div
        className={`${styles.inputWrapper} ${isOpen ? styles.inputWrapperFocused : ""}`}
        onClick={() => {
          setIsOpen(true);
          inputRef.current?.focus();
        }}
      >
        <svg
          className={styles.searchIcon}
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.3-4.3" />
        </svg>

        <input
          ref={inputRef}
          type="text"
          className={styles.searchInput}
          aria-label="Tìm kiếm sản phẩm"
          placeholder={placeholder}
          value={value}
          onChange={(e) => {
            onChange(e.target.value);
            setIsOpen(true);
          }}
          onFocus={() => setIsOpen(true)}
          onKeyDown={handleKeyDown}
        />

        {value && (
          <button
            type="button"
            className={styles.clearBtn}
            onClick={(e) => {
              e.stopPropagation();
              onChange("");
              onSearch("");
              inputRef.current?.focus();
            }}
            title="Xóa tìm kiếm"
            aria-label="Xóa từ khóa"
          >
            ✕
          </button>
        )}
      </div>

      {/* DROPDOWN THÔNG MINH (Chỉ hiện khi Focus) */}
      {isOpen && (
        <div className={styles.dropdownModal}>
          {/* TRẠNG THÁI 1: Khi chưa gõ gì -> Hiển thị Lịch sử & Xu hướng thịnh hành */}
          {!isTyping && (
            <div className={styles.historyAndTrending}>
              {/* Khối Lịch sử tìm kiếm gần đây */}
              {recentSearches.length > 0 && (
                <div className={styles.sectionBlock}>
                  <div className={styles.sectionHeader}>
                    <span className={styles.sectionTitle}>
                      <span className={styles.iconCircle}>🕒</span> Lịch sử tìm kiếm
                    </span>
                    <button
                      type="button"
                      className={styles.clearHistoryBtn}
                      onClick={clearAllRecent}
                    >
                      Xóa tất cả
                    </button>
                  </div>
                  <div className={styles.tagsGrid}>
                    {recentSearches.map((item, idx) => (
                      <span
                        key={idx}
                        className={styles.recentTag}
                        onClick={() => handlePerformSearch(item)}
                      >
                        <span className={styles.tagText}>{item}</span>
                        <button
                          type="button"
                          className={styles.removeTagBtn}
                          onClick={(e) => removeRecentItem(e, item)}
                          title="Xóa mục này"
                        >
                          ✕
                        </button>
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Khối Xu hướng tìm kiếm */}
              <div className={styles.sectionBlock}>
                <div className={styles.sectionHeader}>
                  <span className={styles.sectionTitle}>
                    <span className={styles.iconCircle}>🔥</span> Xu hướng tìm kiếm
                  </span>
                </div>
                <div className={styles.trendingChips}>
                  {TRENDING_SEARCHES.map((trend, idx) => (
                    <button
                      key={idx}
                      type="button"
                      className={styles.trendingChip}
                      onClick={() => handlePerformSearch(trend)}
                    >
                      <span className={styles.trendRank}>{idx + 1}</span>
                      <span className={styles.trendLabel}>{trend}</span>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* TRẠNG THÁI 2: Khi đang gõ -> Hiển thị Autocomplete & Quick Preview */}
          {isTyping && (
            <div className={styles.resultsGrid}>
              {/* Cột trái: Từ khóa gợi ý & Sửa lỗi chính tả */}
              <div className={styles.keywordsCol}>
                {hasTypoCorrection && (
                  <div
                    className={styles.typoAlertBanner}
                    onClick={() => handlePerformSearch(suggestions.correctedQuery!)}
                  >
                    <span className={styles.typoIcon}>💡</span>
                    <div className={styles.typoText}>
                      Có phải bạn muốn tìm:{" "}
                      <strong>{suggestions.correctedQuery}</strong>?
                    </div>
                  </div>
                )}

                <div className={styles.colHeader}>GỢI Ý TỪ KHÓA</div>
                <div className={styles.keywordList}>
                  {suggestions.keywordSuggestions.length > 0 ? (
                    suggestions.keywordSuggestions.map((kw, idx) => (
                      <div
                        key={idx}
                        className={styles.keywordItem}
                        onClick={() => handlePerformSearch(kw)}
                      >
                        <svg
                          className={styles.kwSearchIcon}
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                        >
                          <circle cx="11" cy="11" r="8" />
                          <path d="m21 21-4.3-4.3" />
                        </svg>
                        <span className={styles.kwLabel}>{kw}</span>
                        <span className={styles.kwArrow}>↗</span>
                      </div>
                    ))
                  ) : (
                    <div className={styles.noKeywordsNotice}>
                      Nhấn Enter để tìm <strong>"{value}"</strong>
                    </div>
                  )}
                </div>
              </div>

              {/* Cột phải: Sản phẩm xem nhanh (Quick Products) */}
              <div className={styles.productsCol}>
                <div className={styles.colHeader}>SẢN PHẨM KHỚP NHẤT</div>
                {suggestions.products.length > 0 ? (
                  <div className={styles.quickProductsList}>
                    {suggestions.products.map((p) => {
                      const effectivePrice =
                        p.promotion?.promotionalMinPrice ?? p.minPrice;
                      const hasPromo = p.promotion?.hasPromotion ?? false;

                      return (
                        <div
                          key={p.productId}
                          className={styles.quickProductItem}
                          onClick={() => {
                            setIsOpen(false);
                            router.push(`/products/${p.productId}`);
                          }}
                        >
                          <div className={styles.productThumb}>
                            {p.imageUrl ? (
                              <Image
                                src={p.imageUrl}
                                alt={p.productName}
                                fill
                                sizes="48px"
                                className={styles.thumbImg}
                              />
                            ) : (
                              <div className={styles.noThumb}>Tech</div>
                            )}
                          </div>

                          <div className={styles.productInfo}>
                            <span className={styles.productCategory}>
                              {p.categoryName}
                            </span>
                            <h4 className={styles.productTitle}>
                              {p.productName}
                            </h4>
                            <div className={styles.productPriceRow}>
                              <span className={styles.currentPrice}>
                                {formatPrice(effectivePrice)}
                              </span>
                              {hasPromo && (
                                <span className={styles.originalPrice}>
                                  {formatPrice(p.minPrice)}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className={styles.noQuickProducts}>
                    <span>Không có sản phẩm nào khớp tức thì</span>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Thanh chân trang: Xem tất cả kết quả */}
          {isTyping && (
            <div
              className={styles.dropdownFooter}
              onClick={() => handlePerformSearch(value)}
            >
              <span>
                Xem tất cả kết quả cho <strong>"{value}"</strong>
              </span>
              <span className={styles.enterBadge}>Nhấn Enter ↵</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
