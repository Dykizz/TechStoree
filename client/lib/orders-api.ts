import type { Order } from "./types/order";
export type BackendOrder = {
  orderId: number;
  orderCode: string;
  userId: number;
  receiverName: string;
  receiverPhone: string;
  shippingAddress: string;
  notes?: string;
  orderStatus: Order["status"];
  paymentMethod: string;
  paymentStatus: string;
  subtotalAmount: number;
  voucherDiscountAmount: number;
  totalAmount: number;
  voucherCode?: string;
  createdAt: string;
  items?: {
    orderItemId: number;
    variantId: number;
    productName: string;
    variantName: string;
    unitPrice: number;
    quantity: number;
    imageUrl: string | null;
  }[];
};
export function mapOrder(data: BackendOrder): Order {
  return {
    orderId: String(data.orderId),
    orderCode: data.orderCode,
    userId: data.userId,
    recipientName: data.receiverName,
    recipientPhone: data.receiverPhone,
    shippingAddress: data.shippingAddress,
    note: data.notes,
    status: data.orderStatus,
    paymentMethod: data.paymentMethod === "BANK_TRANSFER" ? "BANKING" : "COD",
    paymentStatus: data.paymentStatus === "PAID" ? "PAID" : "UNPAID",
    subtotalAmount: data.subtotalAmount,
    discountAmount: data.voucherDiscountAmount,
    totalAmount: data.totalAmount,
    voucherCode: data.voucherCode,
    createdAt: data.createdAt,
    items: (data.items || []).map((it) => ({
      ...it,
      orderItemId: String(it.orderItemId),
      productId: 0,
    })),
  };
}
