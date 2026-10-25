export type ReviewPage<T> = {
  items: T[];
  meta: { page: number; pageSize: number; totalItems: number; totalPages: number };
};

export type PublicReview = {
  reviewId: number;
  authorName: string;
  productId: number;
  productName: string;
  productImageUrl: string | null;
  variantName: string;
  rating: number;
  comment: string | null;
  imageUrls: string[];
  replyContent: string | null;
  repliedAt: string | null;
  createdAt: string;
  updatedAt: string | null;
};

export type MyReview = Omit<PublicReview, "authorName"> & {
  authorName?: string;
  orderItemId: number;
  orderId: number;
  orderCode: string;
  variantId: number;
  isHidden: boolean;
};

export type PendingReviewItem = {
  orderItemId: number;
  orderId: number;
  orderCode: string;
  productId: number;
  productName: string;
  variantId: number;
  variantName: string;
  imageUrl: string | null;
  unitPrice: number;
  quantity: number;
  orderDate: string;
};

export type ReviewSummary = {
  totalReviews: number;
  averageRating: number;
  ratingDistribution: Record<string, number>;
};

export const REVIEW_RATINGS = Array.from({ length: 9 }, (_, index) => 1 + index * 0.5);
export const MAX_REVIEW_IMAGES = 5;
export const MAX_REVIEW_IMAGE_BYTES = 5 * 1024 * 1024;

export function canEditReview(review: Pick<MyReview, "createdAt">, now = Date.now()) {
  const created = Date.parse(review.createdAt);
  return Number.isFinite(created) && now >= created && now - created <= 30 * 86400000;
}

export function safeReviewImage(value: string) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && !url.username && !url.password;
  } catch {
    return false;
  }
}

export async function reviewRequest<T>(url: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(url, { cache: "no-store", ...init });
  const body = await response.json().catch(() => null);
  if (!response.ok || !body?.success || body.data == null) {
    throw new Error(body?.message || "Chưa xử lý được yêu cầu đánh giá. Vui lòng thử lại.");
  }
  return body.data as T;
}
