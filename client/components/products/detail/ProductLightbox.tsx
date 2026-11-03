"use client";

import Image from "next/image";
import type { GalleryImage } from "@/hooks/useGallery";
import { cn } from "@/lib/utils";

interface ProductLightboxProps {
  isOpen: boolean;
  images: GalleryImage[];
  currentIndex: number;
  productName: string;
  onClose: () => void;
  onPrev: (e?: React.MouseEvent) => void;
  onNext: (e?: React.MouseEvent) => void;
  onSelectIndex: (idx: number) => void;
}

export default function ProductLightbox({
  isOpen,
  images,
  currentIndex,
  productName,
  onClose,
  onPrev,
  onNext,
  onSelectIndex,
}: ProductLightboxProps) {
  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[999999] bg-[#0a0a0f]/95 backdrop-blur-xl flex flex-col justify-between items-center p-6 animate-fadeIn"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
    >
      <div
        className="w-full max-w-[1200px] flex items-center justify-between text-white z-10"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 min-w-0">
          <span className="bg-white/15 text-white text-[0.8rem] font-semibold px-3 py-1 rounded-2xl border border-white/20 shrink-0">
            {currentIndex + 1} / {images.length}
          </span>
          <span className="text-[1.05rem] font-semibold text-[#f3f4f6] max-w-[500px] truncate">{productName}</span>
        </div>
        <button
          type="button"
          className="bg-white/12 border border-white/25 text-white w-11 h-11 rounded-full flex items-center justify-center cursor-pointer hover:bg-red-500/85 hover:border-transparent hover:scale-110 hover:rotate-90 transition-all duration-200 shrink-0"
          onClick={onClose}
          title="Đóng xem ảnh (Phím Esc)"
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
          >
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>
      </div>

      <div
        className="relative w-full max-w-[1100px] flex-1 flex items-center justify-center min-h-0 py-4"
        onClick={(e) => e.stopPropagation()}
      >
        {images.length > 1 && (
          <button
            type="button"
            className="absolute top-1/2 -translate-y-1/2 left-3 bg-white/12 border border-white/20 text-white w-[52px] h-[52px] rounded-full flex items-center justify-center cursor-pointer backdrop-blur-md hover:bg-white/30 hover:-translate-y-1/2 hover:scale-110 hover:shadow-[0_4px_16px_rgba(0,0,0,0.4)] transition-all duration-200 z-10"
            onClick={onPrev}
            title="Ảnh trước (Mũi tên trái)"
          >
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
            >
              <polyline points="15 18 9 12 15 6" />
            </svg>
          </button>
        )}

        <div className="relative w-full h-full max-w-[900px] max-h-[70vh] flex items-center justify-center">
          {images[currentIndex]?.url && (
            <Image
              src={images[currentIndex].url}
              alt={images[currentIndex]?.label || productName}
              fill
              className="!object-contain [filter:drop-shadow(0_14px_35px_rgba(0,0,0,0.65))] animate-zoomIn"
              sizes="90vw"
              priority
            />
          )}
        </div>

        {images.length > 1 && (
          <button
            type="button"
            className="absolute top-1/2 -translate-y-1/2 right-3 bg-white/12 border border-white/20 text-white w-[52px] h-[52px] rounded-full flex items-center justify-center cursor-pointer backdrop-blur-md hover:bg-white/30 hover:-translate-y-1/2 hover:scale-110 hover:shadow-[0_4px_16px_rgba(0,0,0,0.4)] transition-all duration-200 z-10"
            onClick={onNext}
            title="Ảnh tiếp theo (Mũi tên phải)"
          >
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
            >
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
        )}
      </div>

      {images.length > 1 && (
        <div
          className="w-full max-w-[800px] flex justify-center items-center gap-2.5 overflow-x-auto px-4 py-2.5 bg-white/[0.08] border border-white/[0.12] rounded-2xl backdrop-blur-md"
          onClick={(e) => e.stopPropagation()}
        >
          {images.map((img, idx) => (
            <button
              key={"modal-thumb-" + img.url + idx}
              type="button"
              className={cn(
                "relative w-[54px] h-[54px] shrink-0 rounded-lg p-0 cursor-pointer overflow-hidden transition-all duration-150 border-2 hover:border-white/50 hover:scale-105",
                idx === currentIndex
                  ? "!border-[#3b82f6] bg-[#3b82f6]/15 shadow-[0_0_10px_rgba(59,130,246,0.5)]"
                  : "border-transparent bg-white/5"
              )}
              onClick={() => onSelectIndex(idx)}
            >
              <Image
                src={img.url}
                alt={img.label || `Thumb ${idx + 1}`}
                fill
                className="object-contain p-1"
                sizes="54px"
              />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

