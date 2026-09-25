import { Order, ProductReview, Voucher } from "./types/order";

export const SAMPLE_VOUCHERS: Voucher[] = [
  {
    voucherId: 1,
    code: "CELL50",
    title: "Giảm 50.000₫ cho đơn từ 500.000₫",
    discountType: "FIXED",
    discountValue: 50000,
    minOrderValue: 500000,
    usageLimit: 100,
    limitPerUser: 1,
    startDate: "2026-01-01T00:00:00Z",
    endDate: "2026-12-31T23:59:59Z",
    isActive: true,
  },
  {
    voucherId: 2,
    code: "TECH100",
    title: "Giảm 100.000₫ cho đơn từ 2.000.000₫",
    discountType: "FIXED",
    discountValue: 100000,
    minOrderValue: 2000000,
    usageLimit: 50,
    limitPerUser: 1,
    startDate: "2026-01-01T00:00:00Z",
    endDate: "2026-12-31T23:59:59Z",
    isActive: true,
  },
  {
    voucherId: 3,
    code: "VIP10",
    title: "Giảm 10% tối đa 1.500.000₫ cho đơn từ 5.000.000₫",
    discountType: "PERCENT",
    discountValue: 10,
    minOrderValue: 5000000,
    maxDiscountAmount: 1500000,
    usageLimit: 30,
    limitPerUser: 1,
    startDate: "2026-01-01T00:00:00Z",
    endDate: "2026-12-31T23:59:59Z",
    isActive: true,
  },
];

export function validateVoucher(
  code: string,
  subtotal: number
): { valid: boolean; voucher?: Voucher; discount: number; message: string } {
  const normalized = code.trim().toUpperCase();
  const voucher = SAMPLE_VOUCHERS.find((v) => v.code === normalized);

  if (!voucher || !voucher.isActive) {
    return {
      valid: false,
      discount: 0,
      message: "Mã giảm giá không tồn tại hoặc đã hết hạn.",
    };
  }

  const now = new Date();
  if (now < new Date(voucher.startDate) || now > new Date(voucher.endDate)) {
    return {
      valid: false,
      discount: 0,
      message: "Mã giảm giá hiện không trong thời gian diễn ra chương trình.",
    };
  }

  if (subtotal < voucher.minOrderValue) {
    return {
      valid: false,
      discount: 0,
      message: `Đơn hàng cần tối thiểu ${new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency: "VND",
      }).format(voucher.minOrderValue)} để áp dụng mã này.`,
    };
  }

  let discount = 0;
  if (voucher.discountType === "PERCENT") {
    discount = Math.round(subtotal * (voucher.discountValue / 100));
    if (voucher.maxDiscountAmount && discount > voucher.maxDiscountAmount) {
      discount = voucher.maxDiscountAmount;
    }
  } else {
    discount = Math.min(voucher.discountValue, subtotal);
  }

  return {
    valid: true,
    voucher,
    discount,
    message: `Áp dụng mã ${voucher.code} thành công!`,
  };
}

const ORDERS_STORAGE_KEY = "techstoree_orders";
const REVIEWS_STORAGE_KEY = "techstoree_reviews";

export function getOrders(): Order[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(ORDERS_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) return parsed;
    }
  } catch {
    // Ignore error
  }
  return [];
}

export function saveOrder(order: Order): void {
  if (typeof window === "undefined") return;
  try {
    const existing = getOrders();
    const updated = [order, ...existing];
    localStorage.setItem(ORDERS_STORAGE_KEY, JSON.stringify(updated));
  } catch {
    // Ignore quota error
  }
}

export function getOrderByCode(code: string): Order | undefined {
  const orders = getOrders();
  return orders.find(
    (o) => o.orderCode.trim().toLowerCase() === code.trim().toLowerCase()
  );
}

// Sample Reviews Seed
export const DEFAULT_REVIEWS: ProductReview[] = [
  {
    reviewId: "rev-1",
    productId: 1,
    userName: "customer_anh",
    rating: 5,
    comment:
      "Sản phẩm hoàn thiện cực kỳ tinh xảo, màn hình OLED sắc nét, đóng gói cẩn thận và giao hàng rất nhanh.",
    createdAt: "2026-02-12T14:30:00Z",
    isVerifiedPurchase: true,
  },
  {
    reviewId: "rev-2",
    productId: 1,
    userName: "Minh Quân",
    rating: 5,
    comment:
      "Hiệu năng chip xử lý đồ họa mượt mà, bàn phím gõ êm, pin dùng thực tế được gần 18 tiếng liên tục. Đáng tiền!",
    createdAt: "2026-02-20T09:15:00Z",
    isVerifiedPurchase: true,
  },
  {
    reviewId: "rev-3",
    productId: 2,
    userName: "Hoàng Nam",
    rating: 5,
    comment:
      "Khung viền titan nhẹ và cầm rất đầm tay. Camera chụp đêm cực kỳ sắc nét.",
    createdAt: "2026-02-22T16:45:00Z",
    isVerifiedPurchase: true,
  },
];

export function getProductReviews(productId: number): ProductReview[] {
  if (typeof window === "undefined") {
    return DEFAULT_REVIEWS.filter((r) => r.productId === productId);
  }
  try {
    const raw = localStorage.getItem(REVIEWS_STORAGE_KEY);
    const customReviews: ProductReview[] = raw ? JSON.parse(raw) : [];
    const all = [...customReviews, ...DEFAULT_REVIEWS];
    return all.filter((r) => r.productId === productId);
  } catch {
    return DEFAULT_REVIEWS.filter((r) => r.productId === productId);
  }
}

export function addProductReview(
  reviewData: Omit<ProductReview, "reviewId" | "createdAt">
): ProductReview {
  const newReview: ProductReview = {
    ...reviewData,
    reviewId: `rev-${Date.now()}`,
    createdAt: new Date().toISOString(),
    isVerifiedPurchase: true,
  };

  if (typeof window !== "undefined") {
    try {
      const raw = localStorage.getItem(REVIEWS_STORAGE_KEY);
      const existing: ProductReview[] = raw ? JSON.parse(raw) : [];
      const updated = [newReview, ...existing];
      localStorage.setItem(REVIEWS_STORAGE_KEY, JSON.stringify(updated));
    } catch {
      // Ignore
    }
  }

  return newReview;
}
