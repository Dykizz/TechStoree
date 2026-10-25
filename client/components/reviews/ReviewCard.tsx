"use client";

import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";
import type { MyReview, PublicReview } from "../../lib/reviews";
import { safeReviewImage } from "../../lib/reviews";
import { StarRating } from "./StarRating";
import styles from "./reviews.module.css";

export function reviewDate(value: string) {
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date.toLocaleDateString("vi-VN") : "";
}

export default function ReviewCard({ review, own = false, hidden = false, actions }: { review: PublicReview | MyReview; own?: boolean; hidden?: boolean; actions?: ReactNode }) {
  return (
    <article className={styles.reviewCard}>
      {own && <Link href={`/products/${review.productId}`} className={styles.productLink}>{review.productName}</Link>}
      <div className={styles.reviewHeading}>
        <div className={styles.author}>
          <span className={styles.avatar} aria-hidden="true">{own ? "B" : review.authorName?.charAt(0) || "K"}</span>
          <div><strong>{own ? "Đánh giá của bạn" : review.authorName}</strong><span className={styles.verified}>✓ Đã mua tại TechStoree</span></div>
        </div>
        <time dateTime={review.createdAt}>{reviewDate(review.createdAt)}</time>
      </div>
      <div className={styles.reviewMeta}><StarRating value={review.rating} /><span>{review.rating.toLocaleString("vi-VN")} / 5</span></div>
      {review.variantName && <p className={styles.variant}>Phiên bản: {review.variantName}</p>}
      {review.comment && <p className={styles.comment}>{review.comment}</p>}
      {!!review.imageUrls.length && (
        <div className={styles.photoGrid}>
          {review.imageUrls.filter(safeReviewImage).map((url, index) => (
            <a key={`${url}-${index}`} href={url} target="_blank" rel="noopener noreferrer" aria-label={`Mở ảnh đánh giá ${index + 1} ở tab mới`}>
              <Image src={url} alt={`Ảnh trải nghiệm sản phẩm ${index + 1}`} width={96} height={96} unoptimized />
            </a>
          ))}
        </div>
      )}
      {review.replyContent && (
        <div className={styles.shopReply}>
          <div><strong>Phản hồi từ TechStoree</strong>{review.repliedAt && <time dateTime={review.repliedAt}>{reviewDate(review.repliedAt)}</time>}</div>
          <p>{review.replyContent}</p>
        </div>
      )}
      {hidden && <p className={styles.hint}>Đánh giá đang được ẩn trên trang sản phẩm.</p>}
      {actions && <div className={styles.cardActions}>{actions}</div>}
    </article>
  );
}
