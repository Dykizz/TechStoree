import { NextRequest } from "next/server";
import { reviewError, reviewId, saveReview } from "../../../../lib/reviews-server";

export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const id = reviewId((await params).id);
  return id ? saveReview(request, id) : reviewError("Mã đánh giá không hợp lệ.");
}
