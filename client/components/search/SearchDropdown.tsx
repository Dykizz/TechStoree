"use client";

import Image from "next/image";
import { useRouter } from "next/navigation";
import { formatPrice } from "@/lib/products-client";
import type { AutocompleteResult } from "@/lib/search/search-engine";

// Danh mục từ khóa thịnh hành gợi ý sẵn
export const TRENDING_SEARCHES = [
  "MacBook Air M3",
  "Sony WH-1000XM5",
  "Logitech MX Master 3S",
  "Laptop Gaming Nitro",
  "Bàn phím cơ FL-Esports",
  "Robot Xiaomi Dreame",
  "Màn hình Dell UltraSharp",
  "Tai nghe AirPods Pro 2",
];

export interface SearchDropdownProps {
  value: string;
  isTyping: boolean;
  recentSearches: string[];
  suggestions: AutocompleteResult;
  onSelectKeyword: (kw: string) => void;
  onRemoveRecent: (e: React.MouseEvent, item: string) => void;
  onClearAllRecent: (e: React.MouseEvent) => void;
  onClose: () => void;
}

export default function SearchDropdown({
  value,
  isTyping,
  recentSearches,
  suggestions,
  onSelectKeyword,
  onRemoveRecent,
  onClearAllRecent,
  onClose,
}: SearchDropdownProps) {
  const router = useRouter();
  const hasTypoCorrection = suggestions.hasTypo && suggestions.correctedQuery;

  return (
    <div className="absolute top-[calc(100%+8px)] left-0 right-0 bg-white border border-slate-200 rounded-[20px] shadow-[0_20px_40px_-12px_rgba(0,0,0,0.2),0_0_0_1px_rgba(0,0,0,0.04)] overflow-hidden animate-slideDown z-[100]">
      {/* TRẠNG THÁI 1: Khi chưa gõ gì -> Hiển thị Lịch sử & Xu hướng thịnh hành */}
      {!isTyping && (
        <div className="p-[18px_20px] flex flex-col gap-4">
          {recentSearches.length > 0 && (
            <div className="flex flex-col gap-2.5">
              <div className="flex items-center justify-between">
                <span className="text-[0.82rem] font-bold text-slate-600 uppercase tracking-[0.05em] flex items-center gap-1.5">
                  <span>🕒</span> Lịch sử tìm kiếm
                </span>
                <button
                  type="button"
                  className="bg-transparent border-none text-[0.78rem] text-slate-400 cursor-pointer py-0.5 px-1.5 rounded transition-colors hover:text-red-500 hover:underline"
                  onClick={onClearAllRecent}
                >
                  Xóa tất cả
                </button>
              </div>
              <div className="flex flex-wrap gap-2">
                {recentSearches.map((item, idx) => (
                  <span
                    key={idx}
                    className="inline-flex items-center gap-1.5 bg-slate-100 border border-slate-200 py-1 px-3 rounded-full text-[0.85rem] text-slate-700 cursor-pointer transition-colors hover:bg-slate-200 hover:text-slate-900 hover:border-slate-300"
                    onClick={() => onSelectKeyword(item)}
                  >
                    <span>{item}</span>
                    <button
                      type="button"
                      className="bg-transparent border-none text-slate-400 text-[11px] cursor-pointer p-0 flex items-center justify-center transition-colors hover:text-red-500"
                      onClick={(e) => onRemoveRecent(e, item)}
                      title="Xóa mục này"
                    >
                      ✕
                    </button>
                  </span>
                ))}
              </div>
            </div>
          )}

          <div className="flex flex-col gap-2.5">
            <div className="flex items-center justify-between">
              <span className="text-[0.82rem] font-bold text-slate-600 uppercase tracking-[0.05em] flex items-center gap-1.5">
                <span>🔥</span> Xu hướng tìm kiếm
              </span>
            </div>
            <div className="flex flex-wrap gap-2">
              {TRENDING_SEARCHES.map((trend, idx) => (
                <button
                  key={idx}
                  type="button"
                  className="group inline-flex items-center gap-2 bg-brand/[0.04] border border-brand/16 py-1.5 px-3.5 rounded-full cursor-pointer transition-colors hover:bg-brand hover:border-brand"
                  onClick={() => onSelectKeyword(trend)}
                >
                  <span className="text-[0.75rem] font-extrabold text-brand w-4 h-4 flex items-center justify-center rounded-full bg-brand/10 group-hover:bg-white/25 group-hover:text-white">
                    {idx + 1}
                  </span>
                  <span className="text-[0.85rem] font-semibold text-slate-800 group-hover:text-white">
                    {trend}
                  </span>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TRẠNG THÁI 2: Khi đang gõ -> Hiển thị Autocomplete & Quick Preview */}
      {isTyping && (
        <div className="grid grid-cols-[1.15fr_1.35fr] max-h-[420px] max-md:grid-cols-1">
          <div className="border-r border-slate-100 bg-[#fafafa] overflow-y-auto max-md:border-r-0 max-md:border-b max-md:max-h-[180px]">
            {hasTypoCorrection && (
              <div
                className="flex items-center gap-2 bg-amber-100 border border-amber-300 py-2 px-3 my-2.5 mx-3 mb-1 rounded-lg text-[0.82rem] text-amber-800 cursor-pointer transition-colors hover:bg-amber-200"
                onClick={() => onSelectKeyword(suggestions.correctedQuery!)}
              >
                <span className="text-base">💡</span>
                <div className="text-amber-800">
                  Có phải bạn muốn tìm:{" "}
                  <strong className="text-amber-900 underline">
                    {suggestions.correctedQuery}
                  </strong>
                  ?
                </div>
              </div>
            )}

            <div className="text-[0.74rem] font-extrabold tracking-[0.06em] text-slate-500 uppercase pt-3 px-4 pb-2 border-b border-slate-100">
              GỢI Ý TỪ KHÓA
            </div>
            <div className="flex flex-col">
              {suggestions.keywordSuggestions.length > 0 ? (
                suggestions.keywordSuggestions.map((kw, idx) => (
                  <div
                    key={idx}
                    className="group flex items-center justify-between py-2.5 px-4 cursor-pointer transition-colors hover:bg-slate-100"
                    onClick={() => onSelectKeyword(kw)}
                  >
                    <svg
                      className="text-slate-400 mr-2 shrink-0"
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
                    <span className="flex-1 text-[0.88rem] font-semibold text-slate-800 whitespace-nowrap overflow-hidden text-ellipsis">
                      {kw}
                    </span>
                    <span className="text-[0.85rem] text-slate-300 ml-2 transition-all group-hover:text-brand group-hover:translate-x-0.5 group-hover:-translate-y-0.5">
                      ↗
                    </span>
                  </div>
                ))
              ) : (
                <div className="p-[18px_16px] text-[0.85rem] text-slate-500 text-center">
                  Nhấn Enter để tìm <strong>&quot;{value}&quot;</strong>
                </div>
              )}
            </div>
          </div>

          <div className="overflow-y-auto bg-white">
            <div className="text-[0.74rem] font-extrabold tracking-[0.06em] text-slate-500 uppercase pt-3 px-4 pb-2 border-b border-slate-100">
              SẢN PHẨM KHỚP NHẤT
            </div>
            {suggestions.products.length > 0 ? (
              <div className="flex flex-col">
                {suggestions.products.map((p) => {
                  const effectivePrice =
                    p.promotion?.promotionalMinPrice ?? p.minPrice;
                  const hasPromo = p.promotion?.hasPromotion ?? false;

                  return (
                    <div
                      key={p.productId}
                      className="flex items-center gap-3 py-2.5 px-4 cursor-pointer border-b border-slate-50 transition-colors hover:bg-slate-50 last:border-b-0"
                      onClick={() => {
                        onClose();
                        router.push(`/products/${p.productId}`);
                      }}
                    >
                      <div className="relative w-11 h-11 rounded-lg bg-slate-100 overflow-hidden shrink-0 border border-slate-200">
                        {p.imageUrl ? (
                          <Image
                            src={p.imageUrl}
                            alt={p.productName}
                            fill
                            sizes="48px"
                            className="object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-[0.65rem] font-bold text-slate-400">
                            Tech
                          </div>
                        )}
                      </div>

                      <div className="flex-1 min-w-0 flex flex-col gap-0.5">
                        <span className="text-[0.7rem] text-slate-400 font-semibold uppercase">
                          {p.categoryName}
                        </span>
                        <h4 className="text-[0.84rem] font-semibold text-slate-900 m-0 whitespace-nowrap overflow-hidden text-ellipsis">
                          {p.productName}
                        </h4>
                        <div className="flex items-center gap-1.5">
                          <span className="text-[0.85rem] font-bold text-brand">
                            {formatPrice(effectivePrice)}
                          </span>
                          {hasPromo && (
                            <span className="text-[0.72rem] text-slate-400 line-through">
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
              <div className="py-[30px] px-4 text-center text-[0.85rem] text-slate-400">
                <span>Không có sản phẩm nào khớp tức thì</span>
              </div>
            )}
          </div>
        </div>
      )}

      {isTyping && (
        <div
          className="py-2.5 px-5 bg-slate-50 border-t border-slate-200 flex items-center justify-between text-[0.84rem] text-slate-600 cursor-pointer transition-colors hover:bg-slate-100 hover:text-brand"
          onClick={() => onSelectKeyword(value)}
        >
          <span>
            Xem tất cả kết quả cho <strong>&quot;{value}&quot;</strong>
          </span>
          <span className="text-[0.72rem] font-bold bg-slate-200 text-slate-600 py-0.75 px-2 rounded">
            Nhấn Enter ↵
          </span>
        </div>
      )}
    </div>
  );
}
