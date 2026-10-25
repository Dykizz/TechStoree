"use client";

import Image from "next/image";
import { useState } from "react";
import styles from "./reviews.module.css";

export default function ReviewThumbnail({ src, name, size = 64 }: { src?: string | null; name: string; size?: number }) {
  const [failed, setFailed] = useState<string | null>(null);
  const available = !!src && src !== failed;
  return (
    <span className={styles.thumbnail} style={{ width: size, height: size }}>
      {available ? <Image src={src} alt={name} width={size} height={size} onError={() => setFailed(src)} /> : (
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" role="img" aria-label={`Chưa có ảnh của ${name}`}>
          <rect x="3" y="3" width="18" height="18" rx="3" />
          <circle cx="8.5" cy="8.5" r="1.5" />
          <path d="m3 17 5-5 4 4 3-3 6 6" />
        </svg>
      )}
    </span>
  );
}
