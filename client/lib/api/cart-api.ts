export type ServerItem = {
  cartItemId: number;
  productId: number;
  productName: string;
  variantId: number;
  variantName: string;
  imageUrl: string | null;
  price: number;
  quantity: number;
  stockQuantity: number;
};

export type CartResponseData = {
  items: ServerItem[];
};

export type PreviewResponseData = {
  items: (ServerItem & { unitPrice: number })[];
  voucherDiscountAmount: number;
  isVoucherApplied: boolean;
  voucherCode?: string;
  voucherTitle?: string;
  voucherMessage?: string;
};

export async function fetchCartApi(): Promise<{
  status: number;
  data?: CartResponseData;
  message?: string;
}> {
  const response = await fetch("/api/cart", { cache: "no-store" });
  const body = await response.json();
  return {
    status: response.status,
    data: body.data,
    message: body.message,
  };
}

export async function previewCartApi(
  voucherCode?: string
): Promise<{
  status: number;
  ok: boolean;
  data?: PreviewResponseData;
  message?: string;
}> {
  const response = await fetch("/api/orders/preview", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ voucherCode }),
  });
  const body = await response.json();
  return {
    status: response.status,
    ok: response.ok && Boolean(body.success),
    data: body.data,
    message: body.message,
  };
}

export async function mutateCartApi(
  url: string,
  method: string,
  body?: unknown
): Promise<{
  status: number;
  ok: boolean;
  message?: string;
}> {
  const response = await fetch(url, {
    method,
    headers: { "Content-Type": "application/json" },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const result = await response.json();
  return {
    status: response.status,
    ok: response.ok && Boolean(result.success),
    message: result.message,
  };
}

