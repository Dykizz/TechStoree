export interface Voucher {
  voucherId: number;
  code: string;
  title: string;
  discountType: "PERCENT" | "FIXED";
  discountValue: number;
  minOrderValue: number;
  maxDiscountAmount?: number;
  usageLimit: number;
  limitPerUser: number;
  startDate: string;
  endDate: string;
  isActive: boolean;
}

export interface OrderItem {
  orderItemId: string;
  variantId: number;
  productId: number;
  productName: string;
  variantName: string;
  unitPrice: number;
  quantity: number;
  imageUrl: string | null;
}

export type OrderStatus =
  | "PENDING"
  | "CONFIRMED"
  | "SHIPPING"
  | "DELIVERED"
  | "COMPLETED"
  | "CANCELLED";

export type PaymentMethod = "COD" | "BANKING";
export type PaymentStatus = "UNPAID" | "PAID";

export interface Order {
  orderId: string;
  orderCode: string;
  userId?: number;
  voucherCode?: string;
  subtotalAmount: number;
  discountAmount: number;
  totalAmount: number;
  status: OrderStatus;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  shippingAddress: string;
  recipientName: string;
  recipientPhone: string;
  note?: string;
  createdAt: string;
  items: OrderItem[];
}

export interface ProductReview {
  reviewId: string;
  productId: number;
  userName: string;
  rating: number; // 1 - 5
  comment: string;
  createdAt: string;
  isVerifiedPurchase?: boolean;
}
