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
  updatedAt?: string | null;
  paidAt?: string | null;
  cancelledAt?: string | null;
  cancellationReason?: string | null;
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
    updatedAt: data.updatedAt,
    paidAt: data.paidAt,
    cancelledAt: data.cancelledAt,
    cancellationReason: data.cancellationReason,
    items: (data.items || []).map((it) => ({
      ...it,
      orderItemId: String(it.orderItemId),
      productId: (it as { productId?: number }).productId ?? 0,
    })),
  };
}

export async function cancelOrderApi(
  orderId: string,
  reason: string
): Promise<void> {
  const response = await fetch(`/api/orders/${orderId}/cancel`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ reason: reason.trim() }),
  });
  const result = await response.json();
  if (!response.ok || !result.success) {
    throw new Error(result.message || "Không thể hủy đơn hàng.");
  }
}

export type CheckoutPayload = {
  receiverName: string;
  receiverPhone: string;
  shippingAddress: string;
  notes?: string;
  paymentMethod: "BANK_TRANSFER" | "COD";
  voucherCode?: string;
  cartItemIds: number[];
};

export async function checkoutOrderApi(
  payload: CheckoutPayload
): Promise<BackendOrder> {
  const response = await fetch("/api/orders/checkout", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const result = (await response.json()) as {
    success: boolean;
    message: string;
    data: BackendOrder;
  };
  if (!response.ok || !result.success || !result.data?.orderId) {
    throw new Error(result.message || "Không thể đặt hàng.");
  }
  return result.data;
}
