"use client";

import { useId } from "react";
import { REVIEW_RATINGS } from "../../lib/reviews";
import styles from "./reviews.module.css";

export function StarRating({ value }: { value: number }) {
  return (
    <span className={styles.stars} role="img" aria-label={`${value.toLocaleString("vi-VN")} trên 5 sao`}>
      {[1, 2, 3, 4, 5].map((star) => (
        <span className={styles.star} key={star} aria-hidden="true">
          <span>★</span>
          <span className={styles.starFill} style={{ width: `${Math.max(0, Math.min(1, value - star + 1)) * 100}%` }}>★</span>
        </span>
      ))}
    </span>
  );
}

export function RatingPicker({ value, onChange, disabled }: { value: number; onChange: (rating: number) => void; disabled: boolean }) {
  const id = useId();
  return (
    <fieldset className={styles.ratingField} disabled={disabled}>
      <legend>Trải nghiệm của bạn với sản phẩm</legend>
      <div className={styles.ratingPicker}>
        <StarRating value={value} />
        {REVIEW_RATINGS.map((rating, index) => (
          <label key={rating} className={styles.halfChoice} style={{ left: `${index === 0 ? 0 : (index + 1) * 10}%`, width: index === 0 ? "20%" : "10%" }}>
            <input type="radio" name={`rating-${id}`} value={rating} checked={rating === value} onChange={() => onChange(rating)} />
            <span className={styles.srOnly}>{rating.toLocaleString("vi-VN")} sao</span>
          </label>
        ))}
      </div>
      <span className={styles.ratingValue}>{value.toLocaleString("vi-VN")} / 5</span>
      <p className={styles.hint}>Chọn từng nửa ngôi sao; dùng phím mũi tên khi chọn bằng bàn phím.</p>
    </fieldset>
  );
}
