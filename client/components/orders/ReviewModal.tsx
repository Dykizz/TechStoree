"use client";

import { useEffect, useState } from "react";
import { OrderItem } from "../../lib/types/order";
import styles from "./ReviewModal.module.css";

interface ReviewModalProps {
  isOpen: boolean;
  orderCode: string;
  item: OrderItem | null;
  imageSrc?: string | null;
  onClose: () => void;
  onSubmit: (rating: number, comment: string) => void;
  initialRating?: number;
  initialComment?: string;
}

const RATING_DESCRIPTIONS: Record<number, string> = {
  1: "⭐ Rất không hài lòng",
  2: "⭐⭐ Không hài lòng",
  3: "⭐⭐⭐ Bình thường",
  4: "⭐⭐⭐⭐ Hài lòng",
  5: "⭐⭐⭐⭐⭐ Cực kỳ hài lòng",
};

const QUICK_TAGS = [
  "Chất lượng vượt trội ⭐",
  "Đóng gói cẩn thận 📦",
  "Giao hàng siêu nhanh ⚡",
  "Đúng mô tả sản phẩm 💯",
  "Nhân viên nhiệt tình ❤️",
  "Rất đáng tiền 💰",
];

export default function ReviewModal({
  isOpen,
  orderCode,
  item,
  imageSrc,
  onClose,
  onSubmit,
  initialRating = 5,
  initialComment = "",
}: ReviewModalProps) {
  const [rating, setRating] = useState(initialRating);
  const [hoverRating, setHoverRating] = useState<number | null>(null);
  const [comment, setComment] = useState(initialComment);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);

  useEffect(() => {
    if (!isOpen) return;
    const t = setTimeout(() => {
      setRating(initialRating);
      setComment(initialComment);
      setSelectedTags([]);
    }, 0);
    return () => clearTimeout(t);
  }, [initialRating, initialComment, isOpen]);

  if (!isOpen || !item) return null;

  const currentScore = hoverRating || rating;

  const handleToggleTag = (tag: string) => {
    let newTags: string[];
    if (selectedTags.includes(tag)) {
      newTags = selectedTags.filter((t) => t !== tag);
    } else {
      newTags = [...selectedTags, tag];
    }
    setSelectedTags(newTags);

    // Also append to comment if not present
    if (!comment.includes(tag)) {
      setComment((prev) => (prev ? `${prev}. ${tag}` : tag));
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(rating, comment.trim());
  };

  return (
    <div className={styles.overlay} onClick={onClose} role="dialog" aria-modal="true">
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <h2 className={styles.headerTitle}>Đánh Giá Sản Phẩm</h2>
          <button
            type="button"
            className={styles.closeBtn}
            onClick={onClose}
            aria-label="Đóng"
          >
            ✕
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className={styles.body}>
            <div className={styles.productCard}>
              <div className={styles.productImageWrap}>
                {imageSrc ? (
                  <img
                    src={imageSrc}
                    alt={item.productName}
                    className={styles.productImage}
                  />
                ) : (
                  <div
                    style={{
                      width: "100%",
                      height: "100%",
                      background: "#f0f0f0",
                    }}
                  />
                )}
              </div>
              <div className={styles.productInfo}>
                <div className={styles.productName}>{item.productName}</div>
                {item.variantName && (
                  <div className={styles.productVariant}>
                    Phân loại: {item.variantName}
                  </div>
                )}
                <div className={styles.orderRef}>Đơn hàng: {orderCode}</div>
              </div>
            </div>

            <div className={styles.ratingSection}>
              <div className={styles.ratingLabel}>Chất lượng sản phẩm:</div>
              <div className={styles.starsRow}>
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    type="button"
                    className={styles.starBtn}
                    onClick={() => setRating(star)}
                    onMouseEnter={() => setHoverRating(star)}
                    onMouseLeave={() => setHoverRating(null)}
                    aria-label={`${star} sao`}
                  >
                    <svg
                      className={styles.starIcon}
                      viewBox="0 0 24 24"
                      fill={star <= currentScore ? "#f59e0b" : "none"}
                      stroke={star <= currentScore ? "#f59e0b" : "#d1d5db"}
                      strokeWidth="1.5"
                    >
                      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                    </svg>
                  </button>
                ))}
              </div>
              <div className={styles.ratingDesc}>
                {RATING_DESCRIPTIONS[currentScore]}
              </div>
            </div>

            <div className={styles.tagsSection}>
              <span className={styles.tagsTitle}>Điểm bạn ấn tượng nhất:</span>
              <div className={styles.tagChips}>
                {QUICK_TAGS.map((tag) => (
                  <button
                    key={tag}
                    type="button"
                    className={`${styles.tagChip} ${
                      selectedTags.includes(tag) ? styles.tagChipActive : ""
                    }`}
                    onClick={() => handleToggleTag(tag)}
                  >
                    {tag}
                  </button>
                ))}
              </div>
            </div>

            <div className={styles.commentSection}>
              <label htmlFor="review-comment" className={styles.commentLabel}>
                Chia sẻ chi tiết trải nghiệm của bạn:
              </label>
              <textarea
                id="review-comment"
                className={styles.textarea}
                placeholder="Hãy cho người khác biết cảm nhận của bạn về sản phẩm, tính năng, chất liệu hoặc thời gian giao hàng..."
                value={comment}
                onChange={(e) => setComment(e.target.value)}
              />
            </div>

            <div className={styles.verifiedBadge}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <polyline points="20 6 9 17 4 12" />
              </svg>
              <span>Xác nhận đã mua hàng tại TechStoree</span>
            </div>
          </div>

          <div className={styles.footer}>
            <button
              type="button"
              className={styles.cancelBtn}
              onClick={onClose}
            >
              Hủy
            </button>
            <button type="submit" className={styles.submitBtn}>
              Gửi đánh giá
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
