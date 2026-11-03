"use client";

import { useState, useRef, useCallback, useEffect } from "react";

export interface GalleryImage {
  url: string;
  label?: string;
  variantId?: number;
}

export function useGallery(images: GalleryImage[] = []) {
  const [currentImageIndex, setCurrentImageIndex] = useState<number>(0);
  const [dragDeltaX, setDragDeltaX] = useState<number>(0);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [isLightboxOpen, setIsLightboxOpen] = useState<boolean>(false);
  const [lightboxIndex, setLightboxIndex] = useState<number>(0);

  const dragStartXRef = useRef<number>(0);
  const dragStartTimeRef = useRef<number>(0);
  const isDraggingRef = useRef<boolean>(false);

  const totalImages = images.length;

  const goToImageIndex = useCallback(
    (index: number) => {
      if (totalImages === 0) return;
      const targetIdx = Math.max(0, Math.min(index, totalImages - 1));
      setCurrentImageIndex(targetIdx);
    },
    [totalImages]
  );

  const handlePrevImage = useCallback(
    (e?: React.MouseEvent) => {
      e?.stopPropagation();
      if (totalImages === 0) return;
      setLightboxIndex((prev) => (prev - 1 + totalImages) % totalImages);
    },
    [totalImages]
  );

  const handleNextImage = useCallback(
    (e?: React.MouseEvent) => {
      e?.stopPropagation();
      if (totalImages === 0) return;
      setLightboxIndex((prev) => (prev + 1) % totalImages);
    },
    [totalImages]
  );

  const openLightbox = useCallback((index?: number) => {
    setLightboxIndex(index ?? currentImageIndex);
    setIsLightboxOpen(true);
  }, [currentImageIndex]);

  const closeLightbox = useCallback(() => {
    setCurrentImageIndex(lightboxIndex);
    setIsLightboxOpen(false);
  }, [lightboxIndex]);

  // Lightbox keyboard navigation & body scroll lock
  useEffect(() => {
    if (!isLightboxOpen) return;

    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        closeLightbox();
      } else if (e.key === "ArrowLeft") {
        handlePrevImage();
      } else if (e.key === "ArrowRight") {
        handleNextImage();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => {
      document.body.style.overflow = originalOverflow;
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isLightboxOpen, closeLightbox, handlePrevImage, handleNextImage]);

  // Drag and Swipe Handlers
  const handleDragStart = (clientX: number) => {
    dragStartXRef.current = clientX;
    dragStartTimeRef.current = Date.now();
    isDraggingRef.current = true;
    setIsDragging(true);
    setDragDeltaX(0);
  };

  const handleDragMove = (clientX: number) => {
    if (!isDraggingRef.current) return;
    const delta = clientX - dragStartXRef.current;

    if (
      (currentImageIndex === 0 && delta > 0) ||
      (currentImageIndex === totalImages - 1 && delta < 0)
    ) {
      setDragDeltaX(delta * 0.35);
    } else {
      setDragDeltaX(delta);
    }
  };

  const handleDragEnd = () => {
    if (!isDraggingRef.current) return;
    isDraggingRef.current = false;
    setIsDragging(false);

    const duration = Date.now() - dragStartTimeRef.current;
    const delta = dragDeltaX;
    setDragDeltaX(0);

    if (Math.abs(delta) < 6 && duration < 300) {
      openLightbox(currentImageIndex);
      return;
    }

    if (delta < -38 && currentImageIndex < totalImages - 1) {
      goToImageIndex(currentImageIndex + 1);
    } else if (delta > 38 && currentImageIndex > 0) {
      goToImageIndex(currentImageIndex - 1);
    } else if (delta < -70 && currentImageIndex === totalImages - 1 && totalImages > 1) {
      goToImageIndex(0);
    } else if (delta > 70 && currentImageIndex === 0 && totalImages > 1) {
      goToImageIndex(totalImages - 1);
    }
  };

  return {
    currentImageIndex,
    setCurrentImageIndex,
    dragDeltaX,
    isDragging,
    isLightboxOpen,
    lightboxIndex,
    setLightboxIndex,
    openLightbox,
    closeLightbox,
    goToImageIndex,
    handlePrevImage,
    handleNextImage,
    handleDragStart,
    handleDragMove,
    handleDragEnd,
  };
}

