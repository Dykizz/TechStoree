"use client";

import Link from "next/link";
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { canEditReview, reviewRequest, type MyReview, type ReviewPage } from "../../lib/reviews";
import styles from "./reviews.module.css";

const ReviewContext = createContext<{ reviews: Map<number, MyReview>; loading: boolean; error: boolean }>({ reviews: new Map(), loading: true, error: false });

export function OrderReviewProvider({ itemIds, children }: { itemIds: string[]; children: ReactNode }) {
  const key = itemIds.join(",");
  const [state, setState] = useState({ key: "", reviews: new Map<number, MyReview>(), error: false });
  useEffect(() => {
    if (!key) return;
    const controller = new AbortController();
    async function load() {
      try {
        const first = await reviewRequest<ReviewPage<MyReview>>("/api/reviews/my-reviews?page=1&pageSize=100", { signal: controller.signal });
        const reviews = new Map(first.items.map((review) => [review.orderItemId, review]));
        const wanted = key.split(",").map(Number);
        // OrderItemDto currently omits IsReviewed. Match the actual private
        // review history rather than treating a missing flag as false.
        for (let page = 2; page <= first.meta.totalPages && !wanted.every((id) => reviews.has(id)); page++) {
          const next = await reviewRequest<ReviewPage<MyReview>>(`/api/reviews/my-reviews?page=${page}&pageSize=100`, { signal: controller.signal });
          next.items.forEach((review) => reviews.set(review.orderItemId, review));
        }
        if (!controller.signal.aborted) setState({ key, reviews, error: false });
      } catch {
        if (!controller.signal.aborted) setState({ key, reviews: new Map(), error: true });
      }
    }
    void load();
    return () => controller.abort();
  }, [key]);
  return <ReviewContext.Provider value={{ reviews: state.reviews, error: state.error, loading: !!key && state.key !== key }}>{children}</ReviewContext.Provider>;
}

export default function OrderReviewActions({ orderItemId }: { orderItemId: string }) {
  const { reviews, loading, error } = useContext(ReviewContext);
  const review = reviews.get(Number(orderItemId));
  if (loading) return <span className={styles.orderReviewHint} role="status">Đang tải đánh giá…</span>;
  if (error) return <Link className={styles.orderReviewLink} href="/reviews">Quản lý đánh giá ↗</Link>;
  return <Link className={styles.orderReviewLink} href={`/reviews?tab=${review ? "reviewed" : "pending"}&orderItem=${orderItemId}`}>{review ? canEditReview(review) ? "Sửa / xem đánh giá" : "Xem đánh giá" : "Đánh giá sản phẩm"}</Link>;
}
