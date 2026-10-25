import { NextRequest, NextResponse } from "next/server";
import { backendApiRequest } from "../../../../../lib/auth-server";
import { publicReview, reviewError, reviewId, reviewQuery } from "../../../../../lib/reviews-server";
import type { ReviewPage } from "../../../../../lib/reviews";

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const id = reviewId((await params).id);
  const query = reviewQuery(request, true);
  if (!id || !query) return reviewError("Sản phẩm hoặc bộ lọc không hợp lệ.");
  try {
    const { response, body } = await backendApiRequest<ReviewPage<Record<string, unknown>>>(`Reviews/product/${id}?${query}`, { method: "GET" });
    if (!response.ok || !body?.success || !body.data) return reviewError("Chưa tải được đánh giá sản phẩm.", response.ok ? 502 : response.status);
    return NextResponse.json({ success: true, data: { items: body.data.items.map(publicReview), meta: body.data.meta } }, { headers: { "Cache-Control": "no-store" } });
  } catch {
    return reviewError("Không thể kết nối đến dịch vụ đánh giá. Vui lòng thử lại.", 503);
  }
}
