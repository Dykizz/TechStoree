import { NextRequest, NextResponse } from "next/server";
import { sameOrigin } from "./auth-server";
import { customerProxy } from "./customer-proxy";
import { MAX_REVIEW_IMAGES, REVIEW_RATINGS, safeReviewImage, type PublicReview } from "./reviews";

// Public backend DTOs also contain email, phone and order identifiers. Only this
// allowlist may leave the public Next.js endpoint, with the author masked here.
export function publicReview(raw: Record<string, unknown>): PublicReview {
  const name = Array.from(String(raw.fullName || raw.username || "").trim().normalize("NFC"));
  return {
    reviewId: Number(raw.reviewId),
    authorName: name.length > 1 ? `${name[0]}***${name[name.length - 1]}` : "Khách hàng",
    productId: Number(raw.productId),
    productName: String(raw.productName || ""),
    productImageUrl: typeof raw.productImageUrl === "string" ? raw.productImageUrl : null,
    variantName: String(raw.variantName || ""),
    rating: Number(raw.rating),
    comment: typeof raw.comment === "string" ? raw.comment : null,
    imageUrls: Array.isArray(raw.imageUrls) ? raw.imageUrls.filter((url): url is string => typeof url === "string" && safeReviewImage(url)) : [],
    replyContent: typeof raw.replyContent === "string" ? raw.replyContent : null,
    repliedAt: typeof raw.repliedAt === "string" ? raw.repliedAt : null,
    createdAt: String(raw.createdAt || ""),
    updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : null,
  };
}

export function reviewId(value: string) {
  const id = Number(value);
  return /^[1-9]\d*$/.test(value) && Number.isSafeInteger(id) && id <= 2147483647 ? id : null;
}

export function reviewQuery(request: NextRequest, product = false) {
  const input = request.nextUrl.searchParams;
  const page = Number(input.get("page") || 1);
  const pageSize = Number(input.get("pageSize") || 6);
  if (!Number.isInteger(page) || page < 1 || page > 100000 || !Number.isInteger(pageSize) || pageSize < 1 || pageSize > 100) return null;
  const query = new URLSearchParams({ page: String(page), pageSize: String(pageSize), sortBy: "createdAt", isAscending: "false" });
  if (product && input.has("rating")) {
    const rating = Number(input.get("rating"));
    if (!REVIEW_RATINGS.includes(rating)) return null;
    query.set("rating", String(rating));
  }
  if (product && input.has("hasImages")) {
    if (!["true", "false"].includes(input.get("hasImages")!)) return null;
    query.set("hasImages", input.get("hasImages")!);
  }
  return query;
}

export function reviewError(message: string, status = 400) {
  return NextResponse.json({ success: false, message }, { status, headers: { "Cache-Control": "no-store" } });
}

export async function saveReview(request: NextRequest, id?: number) {
  if (!sameOrigin(request)) return reviewError("Yêu cầu không hợp lệ.", 403);
  const input = await request.json().catch(() => null);
  if (!input || typeof input !== "object" || !REVIEW_RATINGS.includes(input.rating)) return reviewError("Vui lòng chọn từ 1 đến 5 sao, theo bước 0,5.");
  if (input.comment != null && (typeof input.comment !== "string" || input.comment.length > 1000)) return reviewError("Nhận xét tối đa 1.000 ký tự.");
  if (!Array.isArray(input.imageUrls) || input.imageUrls.length > MAX_REVIEW_IMAGES || input.imageUrls.some((url: unknown) => typeof url !== "string" || !safeReviewImage(url))) return reviewError(`Vui lòng chọn tối đa ${MAX_REVIEW_IMAGES} ảnh hợp lệ.`);
  if (!id && !reviewId(String(input.orderItemId))) return reviewError("Món hàng cần đánh giá không hợp lệ.");
  return customerProxy(request, id ? `Reviews/${id}` : "Reviews", {
    method: id ? "PUT" : "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rating: input.rating, comment: input.comment?.trim() || null, imageUrls: input.imageUrls, ...(!id ? { orderItemId: input.orderItemId } : {}) }),
  });
}
