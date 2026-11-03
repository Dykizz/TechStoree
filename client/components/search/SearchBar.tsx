"use client";

import {
  useCallback,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";
import {
  getAutocompleteSuggestions,
  type AutocompleteResult,
} from "@/lib/search/search-engine";
import type { ProductBaseDto } from "@/lib/types/product";
import { useClickOutside } from "@/hooks/useClickOutside";
import { useDebounce } from "@/hooks/useDebounce";
import SearchDropdown from "./SearchDropdown";
import { cn } from "@/lib/utils";

const RECENT_SEARCHES_KEY = "techstoree_recent_searches";
const MAX_RECENT_ITEMS = 6;

const emptySuggestions: AutocompleteResult = {
  keywordSuggestions: [],
  products: [],
  hasTypo: false,
};

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
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // 1. Tải lịch sử tìm kiếm từ localStorage (Lazy initializer, không cascading render)
  const [recentSearches, setRecentSearches] = useState<string[]>(() => {
    if (typeof window === "undefined") return [];
    try {
      const saved = localStorage.getItem(RECENT_SEARCHES_KEY);
      return saved ? (JSON.parse(saved) as string[]) : [];
    } catch {
      return [];
    }
  });

  // 2. Debounce truy vấn tìm kiếm
  const debouncedQuery = useDebounce(value.trim(), 150);

  // 3. Tính toán gợi ý tức thì qua useMemo (không dùng setState trong useEffect)
  const suggestions = useMemo<AutocompleteResult>(() => {
    if (!debouncedQuery) return emptySuggestions;
    return getAutocompleteSuggestions(debouncedQuery, allProducts);
  }, [debouncedQuery, allProducts]);

  // 4. Click outside để đóng dropdown
  useClickOutside(containerRef, () => setIsOpen(false), isOpen);

  // 5. Quản lý lịch sử tìm kiếm
  const saveToRecent = useCallback((query: string) => {
    const clean = query.trim();
    if (!clean) return;

    setRecentSearches((prev) => {
      const updated = [
        clean,
        ...prev.filter((item) => item.toLowerCase() !== clean.toLowerCase()),
      ].slice(0, MAX_RECENT_ITEMS);
      try {
        localStorage.setItem(RECENT_SEARCHES_KEY, JSON.stringify(updated));
      } catch {
        // Safe ignore
      }
      return updated;
    });
  }, []);

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

  const clearAllRecent = (e: React.MouseEvent) => {
    e.stopPropagation();
    setRecentSearches([]);
    try {
      localStorage.removeItem(RECENT_SEARCHES_KEY);
    } catch {
      // Safe ignore
    }
  };

  const handlePerformSearch = (query: string) => {
    const clean = query.trim();
    saveToRecent(clean);
    onChange(clean);
    onSearch(clean);
    setIsOpen(false);
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handlePerformSearch(value);
    } else if (e.key === "Escape") {
      setIsOpen(false);
      inputRef.current?.blur();
    }
  };

  const isTyping = value.trim().length > 0;

  return (
    <div className="relative w-full max-w-[580px] z-50" ref={containerRef}>
      <div
        className={cn(
          "flex items-center gap-2.5 bg-white border-[1.5px] rounded-full py-2 px-4 transition-all duration-200 cursor-text",
          isOpen
            ? "border-brand shadow-[0_0_0_4px_rgba(189,32,45,0.12),0_4px_16px_rgba(0,0,0,0.08)]"
            : "border-slate-200 shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
        )}
        onClick={() => {
          setIsOpen(true);
          inputRef.current?.focus();
        }}
      >
        <svg
          className={cn(
            "shrink-0 transition-colors",
            isOpen ? "text-brand" : "text-slate-400"
          )}
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
          className="flex-1 border-none outline-none bg-transparent text-[0.95rem] text-slate-900 font-inherit placeholder:text-slate-400 placeholder:text-[0.9rem]"
          aria-label="Tìm kiếm sản phẩm"
          placeholder={placeholder}
          value={value}
          onChange={(e) => {
            onChange(e.target.value);
            setIsOpen(true);
          }}
          onKeyDown={handleKeyDown}
        />

        {value && (
          <button
            type="button"
            className="bg-slate-200 border-none w-5 h-5 rounded-full text-[11px] font-bold text-slate-500 flex items-center justify-center cursor-pointer p-0 transition-colors shrink-0 hover:bg-slate-300 hover:text-slate-900"
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

      {isOpen && (
        <SearchDropdown
          value={value}
          isTyping={isTyping}
          recentSearches={recentSearches}
          suggestions={suggestions}
          onSelectKeyword={handlePerformSearch}
          onRemoveRecent={removeRecentItem}
          onClearAllRecent={clearAllRecent}
          onClose={() => setIsOpen(false)}
        />
      )}
    </div>
  );
}
