import { NextRequest } from "next/server";
import { customerProxy } from "../../../../lib/customer-proxy";
import { reviewError, reviewQuery } from "../../../../lib/reviews-server";

export function GET(request: NextRequest) {
  const query = reviewQuery(request);
  return query ? customerProxy(request, `Reviews/pending?${query}`) : reviewError("Phân trang không hợp lệ.");
}
