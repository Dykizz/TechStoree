"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { REVIEW_RATINGS, reviewRequest, type PublicReview, type ReviewPage, type ReviewSummary } from "../../lib/reviews";
import ReviewCard from "./ReviewCard";
import { StarRating } from "./StarRating";
import styles from "./reviews.module.css";

export default function ProductReviews({ productId }: { productId: number }) {
  const [summary, setSummary] = useState<ReviewSummary | null>(null);
  const [summaryError, setSummaryError] = useState("");
  const [result, setResult] = useState<ReviewPage<PublicReview> | null>(null);
  const [rating, setRating] = useState("");
  const [withImages, setWithImages] = useState(false);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    reviewRequest<ReviewSummary>(`/api/reviews/product/${productId}/summary`, { signal: controller.signal })
      .then((value) => { if (!controller.signal.aborted) { setSummary(value); setSummaryError(""); } })
      .catch((e) => { if (!controller.signal.aborted) setSummaryError(e.message); });
    return () => controller.abort();
  }, [productId, attempt]);

  useEffect(() => {
    const controller = new AbortController();
    const params = new URLSearchParams({ page: String(page), pageSize: "6" });
    if (rating) params.set("rating", rating);
    if (withImages) params.set("hasImages", "true");
    reviewRequest<ReviewPage<PublicReview>>(`/api/reviews/product/${productId}?${params}`, { signal: controller.signal })
      .then((value) => { if (!controller.signal.aborted) { setResult(value); setError(""); } })
      .catch((e) => { if (!controller.signal.aborted) setError(e.message); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [productId, rating, withImages, page, attempt]);

  function retry() { setLoading(true); setAttempt((value) => value + 1); }
  function filter(value: string) { if (rating === value && page === 1) return; setLoading(true); setRating(value); setPage(1); }

  return (
    <section id="product-reviews" className={styles.productSection} aria-labelledby="product-reviews-title">
      <div className={styles.sectionHeading}>
        <div><p className={styles.eyebrow}>TRẢI NGHIỆM THỰC TẾ</p><h2 id="product-reviews-title">Đánh giá & nhận xét</h2></div>
        <Link href="/reviews" className={styles.textLink}>Đánh giá của tôi ↗</Link>
      </div>
      {summaryError ? <div className={styles.error} role="alert">{summaryError} <button onClick={retry}>Thử lại</button></div> : summary ? (
        <div className={styles.overview}>
          <div className={styles.score}>
            <p><strong>{summary.totalReviews ? summary.averageRating.toLocaleString("vi-VN", { minimumFractionDigits: 1 }) : "—"}</strong><span>/ 5</span></p>
            <StarRating value={summary.averageRating} />
            <span>{summary.totalReviews.toLocaleString("vi-VN")} lượt đánh giá</span>
          </div>
          <div className={styles.distribution} aria-label="Phân bố đánh giá theo từng nửa sao">
            {[...REVIEW_RATINGS].reverse().map((value) => {
              const count = summary.ratingDistribution[value.toFixed(1)] || 0;
              return <button key={value} onClick={() => filter(String(value))} aria-label={`Xem ${count} đánh giá ${value.toLocaleString("vi-VN")} sao`}><span>{value.toLocaleString("vi-VN")} ★</span><span className={styles.bar}><span style={{ width: `${summary.totalReviews ? count / summary.totalReviews * 100 : 0}%` }} /></span><span>{count}</span></button>;
            })}
          </div>
        </div>
      ) : <p className={styles.hint} role="status">Đang tải điểm đánh giá…</p>}
      <div className={styles.filters}>
        <button className={!rating && !withImages ? styles.activeFilter : ""} aria-pressed={!rating && !withImages} onClick={() => { if (rating || withImages || page > 1) { setLoading(true); setRating(""); setWithImages(false); setPage(1); } }}>Tất cả</button>
        {[5, 4, 3, 2, 1].map((value) => <button key={value} className={rating === String(value) ? styles.activeFilter : ""} aria-pressed={rating === String(value)} onClick={() => filter(rating === String(value) ? "" : String(value))}>{value} sao</button>)}
        <button className={withImages ? styles.activeFilter : ""} aria-pressed={withImages} onClick={() => { setLoading(true); setWithImages((value) => !value); setPage(1); }}>Có hình ảnh</button>
      </div>
      {rating && Number(rating) % 1 !== 0 && <p className={styles.hint}>Đang xem đánh giá {Number(rating).toLocaleString("vi-VN")} sao.</p>}
      <div aria-busy={loading}>
        {loading ? <p className={styles.empty} role="status">Đang tải nhận xét…</p> : error ? <div className={styles.error} role="alert">{error} <button onClick={retry}>Thử lại</button></div> : result?.items.length ? result.items.map((review) => <ReviewCard key={review.reviewId} review={review} />) : (
          <div className={styles.empty}><h3>{rating || withImages ? "Chưa có nhận xét phù hợp" : "Chưa có đánh giá cho sản phẩm này"}</h3><p>{rating || withImages ? "Bạn có thể chọn bộ lọc khác để xem thêm." : "Trải nghiệm của bạn sẽ giúp những người mua sau có thêm thông tin."}</p></div>
        )}
      </div>
      {!loading && !error && result && result.meta.totalPages > 1 && (
        <div className={styles.pagination}><button disabled={page <= 1} onClick={() => { setLoading(true); setPage((value) => value - 1); }}>Trang trước</button><span>{page} / {result.meta.totalPages}</span><button disabled={page >= result.meta.totalPages} onClick={() => { setLoading(true); setPage((value) => value + 1); }}>Trang sau</button></div>
      )}
    </section>
  );
}
