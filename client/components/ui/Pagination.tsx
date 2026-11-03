"use client";

import { cn } from "@/lib/utils";

export interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  className?: string;
  prevLabel?: string;
  nextLabel?: string;
}

export default function Pagination({
  currentPage,
  totalPages,
  onPageChange,
  className = "",
  prevLabel = "← Trang trước",
  nextLabel = "Trang sau →",
}: PaginationProps) {
  if (totalPages <= 1) return null;

  return (
    <nav
      className={cn("flex items-center justify-center gap-3 mt-8 py-4", className)}
      aria-label="Phân trang"
    >
      <button
        type="button"
        className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg cursor-pointer transition-all duration-200 select-none hover:enabled:bg-gray-100 hover:enabled:border-gray-400 hover:enabled:text-gray-900 disabled:opacity-50 disabled:cursor-not-allowed disabled:bg-gray-50 disabled:border-gray-200 disabled:text-gray-400"
        disabled={currentPage <= 1}
        onClick={() => onPageChange(Math.max(currentPage - 1, 1))}
      >
        {prevLabel}
      </button>
      <span className="text-sm font-medium text-gray-600 px-1">
        Trang {currentPage} / {totalPages}
      </span>
      <button
        type="button"
        className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg cursor-pointer transition-all duration-200 select-none hover:enabled:bg-gray-100 hover:enabled:border-gray-400 hover:enabled:text-gray-900 disabled:opacity-50 disabled:cursor-not-allowed disabled:bg-gray-50 disabled:border-gray-200 disabled:text-gray-400"
        disabled={currentPage >= totalPages}
        onClick={() => onPageChange(Math.min(currentPage + 1, totalPages))}
      >
        {nextLabel}
      </button>
    </nav>
  );
}
