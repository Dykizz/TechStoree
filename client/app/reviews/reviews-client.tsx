"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import ReviewCard, { reviewDate } from "../../components/reviews/ReviewCard";
import ReviewComposer from "../../components/reviews/ReviewComposer";
import ReviewThumbnail from "../../components/reviews/ReviewThumbnail";
import { canEditReview, reviewRequest, type MyReview, type PendingReviewItem, type ReviewPage } from "../../lib/reviews";
import { useProtectedSession } from "../../lib/use-protected-session";
import styles from "../../components/reviews/reviews.module.css";

type Lists = { pending: ReviewPage<PendingReviewItem>; reviewed: ReviewPage<MyReview> };

export default function ReviewsClient() {
  const session = useProtectedSession();
  const router = useRouter();
  const query = useSearchParams();
  const tab = query.get("tab") === "reviewed" ? "reviewed" : "pending";
  const rawPage = Number(query.get("page") || 1);
  const page = Number.isSafeInteger(rawPage) && rawPage > 0 ? rawPage : 1;
  const target = Number(query.get("orderItem") || 0);
  const userId = session.user?.userId;
  const [result, setResult] = useState<{ key: string; lists: Lists } | null>(null);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);
  const [notice, setNotice] = useState("");
  const [composer, setComposer] = useState<{ item?: PendingReviewItem; review?: MyReview } | null>(null);
  const key = `${userId}:${tab}:${page}:${target}:${attempt}`;

  useEffect(() => {
    if (!userId) return;
    const controller = new AbortController();
    async function load() {
      try {
        // A deep link from an order locates its actual item across pagination.
        const firstPage = target ? 1 : page;
        const size = target ? 100 : 6;
        const [pending, reviewed] = await Promise.all([
          reviewRequest<ReviewPage<PendingReviewItem>>(`/api/reviews/pending?page=${tab === "pending" ? firstPage : 1}&pageSize=${tab === "pending" ? size : 1}`, { signal: controller.signal }),
          reviewRequest<ReviewPage<MyReview>>(`/api/reviews/my-reviews?page=${tab === "reviewed" ? firstPage : 1}&pageSize=${tab === "reviewed" ? size : 1}`, { signal: controller.signal }),
        ]);
        const lists = { pending, reviewed };
        if (target) {
          const selected = lists[tab];
          let items: (PendingReviewItem | MyReview)[] = selected.items;
          for (let nextPage = 2; nextPage <= selected.meta.totalPages && !items.some((item) => item.orderItemId === target); nextPage++) {
            const next = await reviewRequest<ReviewPage<PendingReviewItem | MyReview>>(`/api/reviews/${tab === "pending" ? "pending" : "my-reviews"}?page=${nextPage}&pageSize=100`, { signal: controller.signal });
            items = next.items;
          }
          const matched = items.find((item) => item.orderItemId === target);
          if (tab === "pending") lists.pending = { items: matched ? [matched as PendingReviewItem] : [], meta: { page: 1, pageSize: 1, totalPages: 1, totalItems: matched ? 1 : 0 } };
          else lists.reviewed = { items: matched ? [matched as MyReview] : [], meta: { page: 1, pageSize: 1, totalPages: 1, totalItems: matched ? 1 : 0 } };
        }
        if (!controller.signal.aborted) { setResult({ key, lists }); setError(""); }
      } catch (e) {
        if (!controller.signal.aborted) setError(e instanceof Error ? e.message : "Không thể tải đánh giá của bạn.");
      }
    }
    void load();
    return () => controller.abort();
  }, [userId, tab, page, target, attempt, key]);

  function navigate(nextTab: string, nextPage = 1) {
    setError("");
    router.replace(`/reviews?tab=${nextTab}&page=${nextPage}`, { scroll: false });
  }

  function saved(review: MyReview) {
    setComposer(null);
    setNotice(`Đã ${composer?.review ? "cập nhật" : "gửi"} đánh giá cho ${review.productName}.`);
    setError("");
    setAttempt((value) => value + 1);
    router.replace(`/reviews?tab=reviewed&orderItem=${review.orderItemId}`, { scroll: false });
  }

  if (session.status !== "ready") return <main className={styles.main}><div className={styles.pageContainer} role="status">{session.status === "error" ? <><p>{session.message}</p><button className={styles.secondaryButton} onClick={session.retry}>Thử lại</button></> : "Đang kiểm tra phiên đăng nhập…"}</div></main>;
  const loading = result?.key !== key;
  const list = result?.lists[tab];

  return (
    <main className={styles.main}><div className={styles.pageContainer}>
      <div className={styles.pageHeading}><div><p className={styles.eyebrow}>GÓC TRẢI NGHIỆM</p><h1>Đánh giá của tôi.</h1><p>Chia sẻ cảm nhận về những sản phẩm bạn đã nhận và xem lại phản hồi từ cửa hàng.</p></div><Link href="/orders" className={styles.textLink}>Xem đơn hàng ↗</Link></div>
      <div className={styles.tabs} aria-label="Danh sách đánh giá">
        <button aria-pressed={tab === "pending"} className={tab === "pending" ? styles.selectedTab : ""} onClick={() => navigate("pending")}>Chờ đánh giá</button>
        <button aria-pressed={tab === "reviewed"} className={tab === "reviewed" ? styles.selectedTab : ""} onClick={() => navigate("reviewed")}>Đã đánh giá</button>
      </div>
      <p className={styles.pageHint}>{tab === "pending" ? "Bạn có thể đánh giá từng sản phẩm sau khi đơn hàng đã được giao thành công." : "Bạn có thể chỉnh sửa đánh giá trong 30 ngày kể từ lần gửi đầu tiên."}</p>
      {notice && <p className={styles.notice} role="status">{notice}</p>}
      {!!target && <div className={styles.targetNotice}><span>Đang xem sản phẩm từ đơn hàng bạn đã chọn.</span><button onClick={() => navigate(tab)}>Xem tất cả</button></div>}
      {error ? <div className={styles.error} role="alert">{error} <button onClick={() => { setError(""); setAttempt((value) => value + 1); }}>Thử lại</button></div> : loading ? <div className={styles.empty} role="status">Đang tải đánh giá…</div> : !list?.items.length ? (
        <div className={styles.empty}><span className={styles.emptyStar} aria-hidden="true">☆</span><h2>{target ? "Sản phẩm không còn trong danh sách này" : tab === "pending" ? "Chưa có sản phẩm chờ đánh giá" : "Chưa có đánh giá nào"}</h2><p>{target ? "Sản phẩm có thể đã được đánh giá hoặc chưa đủ điều kiện. Bạn có thể xem lại cả hai danh sách." : tab === "pending" ? "Các sản phẩm đã giao nhưng chưa được đánh giá sẽ xuất hiện tại đây." : "Sau khi nhận hàng, bạn có thể chia sẻ trải nghiệm từ tab Chờ đánh giá."}</p><Link className={styles.textLink} href="/orders">Xem đơn hàng →</Link></div>
      ) : tab === "pending" ? (
        <div className={styles.pendingList}>{result!.lists.pending.items.map((item) => <article className={styles.pendingCard} key={item.orderItemId}>
          <div className={styles.pendingOrder}><Link href={`/orders?code=${encodeURIComponent(item.orderCode)}`}>{item.orderCode}</Link><time dateTime={item.orderDate}>{reviewDate(item.orderDate)}</time></div>
          <div className={styles.pendingProduct}><ReviewThumbnail src={item.imageUrl} name={item.productName} /><div><Link className={styles.productLink} href={`/products/${item.productId}`}>{item.productName}</Link><p>{item.variantName}</p><span>Số lượng: {item.quantity}</span></div><button className={styles.primaryButton} onClick={() => setComposer({ item })}>Viết đánh giá</button></div>
        </article>)}</div>
      ) : (
        <div className={styles.ownReviewList}>{result!.lists.reviewed.items.map((review) => <ReviewCard key={review.reviewId} review={review} own hidden={review.isHidden} actions={<><Link className={styles.textLink} href={`/orders?code=${encodeURIComponent(review.orderCode)}`}>Đơn {review.orderCode}</Link>{canEditReview(review) ? <button className={styles.secondaryButton} onClick={() => setComposer({ review })}>Chỉnh sửa</button> : <span className={styles.hint}>Đã hết thời hạn chỉnh sửa 30 ngày</span>}</>} />)}</div>
      )}
      {!error && !loading && list && !target && list.meta.totalPages > 1 && <div className={styles.pagination}><button disabled={page <= 1} onClick={() => navigate(tab, page - 1)}>Trang trước</button><span>{page} / {list.meta.totalPages}</span><button disabled={page >= list.meta.totalPages} onClick={() => navigate(tab, page + 1)}>Trang sau</button></div>}
      {composer && <ReviewComposer item={composer.item} review={composer.review} onClose={() => setComposer(null)} onSaved={saved} />}
    </div></main>
  );
}
