"use client";

import Image from "next/image";
import type { GalleryImage } from "@/hooks/useGallery";
import { cn } from "@/lib/utils";

interface ProductGalleryProps {
  images: GalleryImage[];
  currentIndex: number;
  productName: string;
  isDragging: boolean;
  dragDeltaX: number;
  onDragStart: (clientX: number) => void;
  onDragMove: (clientX: number) => void;
  onDragEnd: () => void;
  onSelectIndex: (idx: number) => void;
  onSlidePrev: () => void;
  onSlideNext: () => void;
}

export default function ProductGallery({
  images,
  currentIndex,
  productName,
  isDragging,
  dragDeltaX,
  onDragStart,
  onDragMove,
  onDragEnd,
  onSelectIndex,
  onSlidePrev,
  onSlideNext,
}: ProductGalleryProps) {
  return (
    <div className="static lg:sticky lg:top-[100px]">
      <div
        className={cn(
          "relative w-full aspect-square bg-[#f7f7f7] rounded-xl overflow-hidden border border-[#eeeeee] cursor-grab select-none [touch-action:pan-y] hover:border-[#d1d5db] hover:shadow-[0_6px_20px_rgba(0,0,0,0.06)] transition-all duration-200 group",
          isDragging && "!cursor-grabbing"
        )}
        onMouseDown={(e) => onDragStart(e.clientX)}
        onMouseMove={(e) => onDragMove(e.clientX)}
        onMouseUp={onDragEnd}
        onMouseLeave={onDragEnd}
        onTouchStart={(e) => onDragStart(e.touches[0].clientX)}
        onTouchMove={(e) => onDragMove(e.touches[0].clientX)}
        onTouchEnd={onDragEnd}
        onTouchCancel={onDragEnd}
        title="Kéo sang trái/phải để lướt ảnh • Nhấp để phóng to"
      >
        <div
          className="flex w-full h-full will-change-transform"
          style={{
            transform: `translateX(calc(-${currentIndex * 100}% + ${dragDeltaX}px))`,
            transition: isDragging
              ? "none"
              : "transform 0.35s cubic-bezier(0.2, 0.8, 0.25, 1)",
          }}
        >
          {images.length > 0 ? (
            images.map((img, idx) => (
              <div key={img.url + idx} className="relative w-full h-full shrink-0 flex items-center justify-center p-6">
                <Image
                  src={img.url}
                  alt={img.label || productName}
                  fill
                  priority={idx === 0}
                  className="object-contain pointer-events-none select-none transition-transform duration-200"
                  sizes="(max-width: 900px) 100vw, 50vw"
                  draggable={false}
                />
              </div>
            ))
          ) : (
            <div className="relative w-full h-full shrink-0 flex items-center justify-center p-6">
              <div className="object-contain pointer-events-none select-none transition-transform duration-200" />
            </div>
          )}
        </div>

        {images.length > 1 && (
          <div className="absolute top-3.5 left-3.5 inline-flex items-center bg-[#111111]/70 backdrop-blur-md text-white text-[0.74rem] font-semibold px-3 py-1 rounded-[14px] z-[4] pointer-events-none shadow-[0_2px_8px_rgba(0,0,0,0.15)]">
            <span>
              {currentIndex + 1} / {images.length}
            </span>
          </div>
        )}

        {images.length > 1 && (
          <>
            <button
              type="button"
              className="absolute top-1/2 -translate-y-1/2 left-3 w-[42px] h-[42px] rounded-full bg-white/95 border border-black/10 shadow-[0_4px_14px_rgba(0,0,0,0.12)] flex items-center justify-center text-[#111111] cursor-pointer z-[5] opacity-0 group-hover:opacity-100 hover:bg-white hover:-translate-y-1/2 hover:scale-110 hover:shadow-[0_6px_18px_rgba(0,0,0,0.18)] transition-all duration-200"
              onClick={onSlidePrev}
              title="Ảnh trước"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
              >
                <polyline points="15 18 9 12 15 6" />
              </svg>
            </button>
            <button
              type="button"
              className="absolute top-1/2 -translate-y-1/2 right-3 w-[42px] h-[42px] rounded-full bg-white/95 border border-black/10 shadow-[0_4px_14px_rgba(0,0,0,0.12)] flex items-center justify-center text-[#111111] cursor-pointer z-[5] opacity-0 group-hover:opacity-100 hover:bg-white hover:-translate-y-1/2 hover:scale-110 hover:shadow-[0_6px_18px_rgba(0,0,0,0.18)] transition-all duration-200"
              onClick={onSlideNext}
              title="Ảnh tiếp theo"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
              >
                <polyline points="9 18 15 12 9 6" />
              </svg>
            </button>
          </>
        )}

        {images.length > 1 && (
          <div
            className="absolute bottom-3 left-1/2 -translate-x-1/2 flex items-center gap-1.5 bg-[#0f172a]/55 backdrop-blur-md px-3 py-1.5 rounded-[20px] z-[4] shadow-[0_2px_10px_rgba(0,0,0,0.15)]"
            onClick={(e) => e.stopPropagation()}
          >
            {images.map((_, i) => (
              <button
                key={i}
                type="button"
                className={cn(
                  "h-[7px] cursor-pointer border-0 p-0 transition-all duration-200 ease-out hover:bg-white/80",
                  i === currentIndex
                    ? "w-[22px] rounded bg-white shadow-[0_0_8px_rgba(255,255,255,0.9)]"
                    : "w-[7px] rounded-full bg-white/40"
                )}
                onClick={() => onSelectIndex(i)}
                title={`Xem ảnh ${i + 1}`}
              />
            ))}
          </div>
        )}
      </div>

      {images.length > 1 && (
        <div className="flex gap-2.5 mt-3.5 overflow-x-auto p-[4px_2px_8px] [scrollbar-width:thin]">
          {images.map((img, idx) => (
            <button
              key={img.url + idx}
              type="button"
              className={cn(
                "relative w-[68px] h-[68px] shrink-0 bg-[#f7f7f7] rounded-lg p-0 cursor-pointer overflow-hidden transition-all duration-200 border-2 hover:border-[#9ca3af] hover:-translate-y-0.5",
                idx === currentIndex
                  ? "!border-[#2563eb] shadow-[0_0_0_2px_rgba(37,99,235,0.25),0_4px_10px_rgba(0,0,0,0.08)]"
                  : "border-[#e5e7eb]"
              )}
              onClick={() => onSelectIndex(idx)}
              title={img.label || `Ảnh ${idx + 1}`}
            >
              <Image
                src={img.url}
                alt={img.label || `Thumbnail ${idx + 1}`}
                fill
                className="object-contain p-1.5"
                sizes="68px"
              />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

