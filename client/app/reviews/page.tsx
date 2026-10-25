import { Suspense } from "react";
import ReviewsClient from "./reviews-client";

export default function ReviewsPage() {
  return <Suspense fallback={<p role="status">Đang tải đánh giá của bạn…</p>}><ReviewsClient /></Suspense>;
}
