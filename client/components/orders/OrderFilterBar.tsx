"use client";

import { cn } from "@/lib/utils";

export const ORDER_TABS = [
  { key: "", label: "Tất cả" },
  { key: "PENDING", label: "Chờ xác nhận" },
  { key: "CONFIRMED", label: "Đã xác nhận" },
  { key: "SHIPPING", label: "Đang giao" },
  { key: "DELIVERED", label: "Đã giao" },
  { key: "CANCELLED", label: "Đã hủy" },
];

interface OrderFilterBarProps {
  status: string;
  search: string;
  sortBy: string;
  dateMode: string;
  exactDate: string;
  fromDate: string;
  toDate: string;
  onStatusChange: (status: string) => void;
  onSearchChange: (search: string) => void;
  onSortByChange: (sortBy: string) => void;
  onDateModeChange: (mode: string) => void;
  onExactDateChange: (date: string) => void;
  onFromDateChange: (date: string) => void;
  onToDateChange: (date: string) => void;
  onResetFilters: () => void;
}

const getTabActiveClass = (key: string) => {
  switch (key) {
    case "":
      return "bg-[#111827] text-white border-[#111827] font-semibold shadow-[0_4px_12px_rgba(17,24,39,0.15)]";
    case "PENDING":
      return "bg-[#fffbeb] text-[#b45309] border-[#fcd34d] font-semibold shadow-[0_4px_12px_rgba(245,158,11,0.15)]";
    case "CONFIRMED":
      return "bg-[#eff6ff] text-[#1d4ed8] border-[#93c5fd] font-semibold shadow-[0_4px_12px_rgba(37,99,235,0.15)]";
    case "SHIPPING":
      return "bg-[#f5f3ff] text-[#6d28d9] border-[#c4b5fd] font-semibold shadow-[0_4px_12px_rgba(124,58,237,0.15)]";
    case "DELIVERED":
      return "bg-[#ecfdf5] text-[#047857] border-[#6ee7b7] font-semibold shadow-[0_4px_12px_rgba(5,150,105,0.15)]";
    case "CANCELLED":
      return "bg-[#fff1f2] text-[#be123c] border-[#fda4af] font-semibold shadow-[0_4px_12px_rgba(225,29,72,0.15)]";
    default:
      return "bg-neutral-900 text-white font-semibold";
  }
};

export default function OrderFilterBar({
  status,
  search,
  sortBy,
  dateMode,
  exactDate,
  fromDate,
  toDate,
  onStatusChange,
  onSearchChange,
  onSortByChange,
  onDateModeChange,
  onExactDateChange,
  onFromDateChange,
  onToDateChange,
  onResetFilters,
}: OrderFilterBarProps) {
  const isFilterActive =
    sortBy !== "created_desc" ||
    dateMode !== "all" ||
    Boolean(search.trim()) ||
    Boolean(fromDate) ||
    Boolean(toDate) ||
    Boolean(exactDate);

  return (
    <>
      <div className="bg-white border border-[#ebebeb] rounded-[14px] p-1.5 mb-6 shadow-[0_2px_10px_rgba(0,0,0,0.02)] overflow-x-auto [scrollbar-width:thin]" role="tablist">
        <div className="flex gap-1.5 min-w-max">
          {ORDER_TABS.map((tab) => (
            <button
              key={tab.key}
              role="tab"
              aria-selected={status === tab.key}
              className={cn(
                "flex items-center gap-2 px-4 py-2.5 rounded-[10px] border text-[0.88rem] cursor-pointer whitespace-nowrap transition-all duration-200 ease-out",
                status === tab.key
                  ? getTabActiveClass(tab.key)
                  : "border-transparent text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900 font-medium"
              )}
              onClick={() => onStatusChange(tab.key)}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white border border-[#ebebeb] rounded-[14px] p-4 sm:px-5 mb-6 flex flex-col gap-3.5 shadow-[0_1px_4px_rgba(0,0,0,0.03)]">
        <div className="relative flex items-center w-full">
          <div className="absolute left-3.5 text-[#9ca3af] pointer-events-none flex items-center">
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <circle cx="11" cy="11" r="8" />
              <path d="m21 21-4.3-4.3" />
            </svg>
          </div>
          <input
            className="w-full pl-[42px] pr-10 py-[11px] border border-[#d1d5db] rounded-[10px] text-[0.92rem] text-[#111827] outline-none bg-[#f9fafb] focus:bg-white focus:border-[#111827] focus:ring-4 focus:ring-neutral-900/10 transition-all duration-200"
            aria-label="Tìm đơn hàng"
            placeholder="Tìm theo mã đơn (ORD-...), tên người nhận hoặc số điện thoại…"
            value={search}
            onChange={(e) => onSearchChange(e.target.value)}
          />
          {search && (
            <button
              type="button"
              className="absolute right-3 bg-transparent border-0 text-[#9ca3af] text-sm cursor-pointer p-1 flex items-center justify-center rounded-full hover:bg-[#e5e7eb] hover:text-[#1f2937] transition-colors duration-150"
              onClick={() => onSearchChange("")}
              title="Xóa tìm kiếm"
            >
              ✕
            </button>
          )}
        </div>

        <div className="flex flex-col sm:flex-row flex-wrap gap-3 items-stretch sm:items-center">
          <div className="flex items-center justify-between sm:justify-start gap-2 bg-[#f3f4f6] px-3 py-1.5 rounded-[10px] border border-[#e5e7eb]">
            <label htmlFor="order-sort-select" className="flex items-center gap-1.5 text-[0.82rem] font-semibold text-[#4b5563] whitespace-nowrap">
              <svg
                width="15"
                height="15"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <path d="M3 6h18M6 12h12m-9 6h6" />
              </svg>
              <span>Hiển thị theo:</span>
            </label>
            <select
              id="order-sort-select"
              className="bg-white border border-[#d1d5db] rounded-lg px-3 py-1.5 text-[0.84rem] font-medium text-[#111827] outline-none cursor-pointer focus:border-[#111827] transition-colors duration-150"
              value={sortBy}
              onChange={(e) => onSortByChange(e.target.value)}
            >
              <option value="created_desc">Thời gian: Gần nhất (Mới nhất)</option>
              <option value="created_asc">Thời gian: Cũ nhất trước</option>
              <option value="price_desc">Giá: Cao nhất đến thấp nhất</option>
              <option value="price_asc">Giá: Thấp nhất đến cao nhất</option>
            </select>
          </div>

          <div className="flex items-center justify-between sm:justify-start gap-2 bg-[#f3f4f6] px-3 py-1.5 rounded-[10px] border border-[#e5e7eb]">
            <label htmlFor="order-date-mode-select" className="flex items-center gap-1.5 text-[0.82rem] font-semibold text-[#4b5563] whitespace-nowrap">
              <svg
                width="15"
                height="15"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                <line x1="16" y1="2" x2="16" y2="6" />
                <line x1="8" y1="2" x2="8" y2="6" />
                <line x1="3" y1="10" x2="21" y2="10" />
              </svg>
              <span>Mốc thời gian:</span>
            </label>
            <select
              id="order-date-mode-select"
              className="bg-white border border-[#d1d5db] rounded-lg px-3 py-1.5 text-[0.84rem] font-medium text-[#111827] outline-none cursor-pointer focus:border-[#111827] transition-colors duration-150"
              value={dateMode}
              onChange={(e) => onDateModeChange(e.target.value)}
            >
              <option value="all">Tất cả thời gian</option>
              <option value="from">Từ mốc ngày... đến nay</option>
              <option value="exact">Tại 1 ngày cụ thể</option>
              <option value="range">Khoảng ngày tùy chọn</option>
              <option value="today">Hôm nay</option>
              <option value="7days">7 ngày qua</option>
              <option value="30days">30 ngày qua</option>
            </select>
          </div>

          {isFilterActive && (
            <button
              type="button"
              className="inline-flex items-center justify-center gap-1.5 px-3.5 py-2 bg-[#fee2e2] border border-[#fca5a5] text-[#b91c1c] rounded-lg text-[0.82rem] font-semibold cursor-pointer hover:bg-[#fecaca] hover:text-[#991b1b] transition-colors duration-150 w-full sm:w-auto sm:ml-auto"
              onClick={onResetFilters}
              title="Khôi phục về mặc định"
            >
              ↺ Đặt lại bộ lọc
            </button>
          )}
        </div>

        {dateMode === "exact" && (
          <div className="flex flex-wrap items-center gap-3 p-2.5 px-3.5 bg-[#f8fafc] border border-dashed border-[#cbd5e1] rounded-[10px]">
            <label className="flex items-center gap-2 text-[0.84rem] font-semibold text-[#334155]">
              <span>Chọn ngày cụ thể:</span>
              <input
                type="date"
                className="px-3 py-1.5 border border-[#cbd5e1] rounded-lg text-[0.84rem] text-[#0f172a] bg-white outline-none cursor-pointer focus:border-[#0f172a]"
                value={exactDate}
                onChange={(e) => onExactDateChange(e.target.value)}
              />
            </label>
            <span className="text-[0.8rem] text-[#64748b] italic">
              (Chỉ hiển thị các đơn phát sinh trong ngày này)
            </span>
          </div>
        )}

        {dateMode === "from" && (
          <div className="flex flex-wrap items-center gap-3 p-2.5 px-3.5 bg-[#f8fafc] border border-dashed border-[#cbd5e1] rounded-[10px]">
            <label className="flex items-center gap-2 text-[0.84rem] font-semibold text-[#334155]">
              <span>Từ ngày:</span>
              <input
                type="date"
                className="px-3 py-1.5 border border-[#cbd5e1] rounded-lg text-[0.84rem] text-[#0f172a] bg-white outline-none cursor-pointer focus:border-[#0f172a]"
                value={fromDate}
                onChange={(e) => onFromDateChange(e.target.value)}
              />
            </label>
            <span className="text-sm text-[#94a3b8] font-semibold">→</span>
            <span className="text-[0.82rem] font-medium text-[#059669] bg-[#ecfdf5] px-2.5 py-1 rounded-md border border-[#a7f3d0]">
              Cho đến hiện tại ({new Date().toLocaleDateString("vi-VN")})
            </span>
          </div>
        )}

        {dateMode === "range" && (
          <div className="flex flex-wrap items-center gap-3 p-2.5 px-3.5 bg-[#f8fafc] border border-dashed border-[#cbd5e1] rounded-[10px]">
            <label className="flex items-center gap-2 text-[0.84rem] font-semibold text-[#334155]">
              <span>Từ ngày:</span>
              <input
                type="date"
                className="px-3 py-1.5 border border-[#cbd5e1] rounded-lg text-[0.84rem] text-[#0f172a] bg-white outline-none cursor-pointer focus:border-[#0f172a]"
                value={fromDate}
                onChange={(e) => onFromDateChange(e.target.value)}
              />
            </label>
            <span className="text-sm text-[#94a3b8] font-semibold">→</span>
            <label className="flex items-center gap-2 text-[0.84rem] font-semibold text-[#334155]">
              <span>Đến ngày:</span>
              <input
                type="date"
                className="px-3 py-1.5 border border-[#cbd5e1] rounded-lg text-[0.84rem] text-[#0f172a] bg-white outline-none cursor-pointer focus:border-[#0f172a]"
                value={toDate}
                onChange={(e) => onToDateChange(e.target.value)}
              />
            </label>
          </div>
        )}
      </div>
    </>
  );
}

