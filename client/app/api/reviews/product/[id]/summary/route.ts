import { NextRequest, NextResponse } from "next/server";
import { backendApiRequest } from "../../../../../../lib/auth-server";
import { reviewError, reviewId } from "../../../../../../lib/reviews-server";
import { REVIEW_RATINGS, type ReviewPage } from "../../../../../../lib/reviews";

export async function GET(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const id = reviewId((await params).id);
  if (!id) return reviewError("Mã sản phẩm không hợp lệ.");
  try {
    // The only statistics endpoint is admin-only. Exact public rating counts
    // cover all pages without an admin token or fetching the entire review list.
    const counts = await Promise.all(REVIEW_RATINGS.map(async (rating) => {
      const { response, body } = await backendApiRequest<ReviewPage<unknown>>(`Reviews/product/${id}?rating=${rating}&page=1&pageSize=1`, { method: "GET" });
      if (!response.ok || !body?.success || !body.data) throw new Error("Review statistics unavailable");
      return { rating, count: body.data.meta.totalItems };
    }));
    const totalReviews = counts.reduce((sum, item) => sum + item.count, 0);
    const totalRating = counts.reduce((sum, item) => sum + item.rating * item.count, 0);
    return NextResponse.json({ success: true, data: {
      totalReviews,
      averageRating: totalReviews ? Math.round(totalRating / totalReviews * 10) / 10 : 0,
      ratingDistribution: Object.fromEntries(counts.map(({ rating, count }) => [rating.toFixed(1), count])),
    } }, { headers: { "Cache-Control": "no-store" } });
  } catch {
    return reviewError("Chưa tải được điểm tổng quan. Vui lòng thử lại.", 503);
  }
}
