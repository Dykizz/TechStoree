"use client";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from "react";
import { usePathname, useRouter } from "next/navigation";
import type { CartContextType, CartItem } from "../types/cart";
import type { Voucher } from "../types/order";
const CartContext = createContext<CartContextType | undefined>(undefined);
type ServerItem = {
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
export function resolveCartItemImage(url?: string | null) {
  return url || null;
}
function mapItem(it: ServerItem): CartItem {
  return {
    ...it,
    cartItemId: `${it.productId}-${it.variantId}`,
    backendCartItemId: it.cartItemId,
    attributes: {},
  };
}
export function CartProvider({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [items, setItems] = useState<CartItem[]>([]);
  const [appliedVoucher, setAppliedVoucher] = useState<Voucher | null>(null);
  const [discountAmount, setDiscountAmount] = useState(0);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const pending = useRef(false);
  const version = useRef(0);
  const voucherRef = useRef<Voucher | null>(null);
  const readCart = useCallback(async () => {
    const current = ++version.current;
    const response = await fetch("/api/cart", { cache: "no-store" });
    const body = await response.json();
    if (current !== version.current) return;
    if (response.status === 401) {
      setItems([]);
      setAppliedVoucher(null);
      voucherRef.current = null;
      setDiscountAmount(0);
      return;
    }
    if (!response.ok || !body.success || !body.data)
      throw new Error(body.message || "Không thể tải giỏ hàng.");
    if (body.data.items.length) {
      const preview = await fetch("/api/orders/preview", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ voucherCode: voucherRef.current?.code }),
      });
      const result = await preview.json();
      if (current !== version.current) return;
      if (!preview.ok || !result.success)
        throw new Error(result.message || "Không thể cập nhật giá giỏ hàng.");
      setItems(
        result.data.items.map((it: ServerItem & { unitPrice: number }) =>
          mapItem({ ...it, price: it.unitPrice }),
        ),
      );
      setDiscountAmount(result.data.voucherDiscountAmount);
      if (voucherRef.current && !result.data.isVoucherApplied) {
        voucherRef.current = null;
        setAppliedVoucher(null);
      }
    } else {
      setItems([]);
      setDiscountAmount(0);
    }
  }, []);
  const refreshCart = useCallback(async () => {
    try {
      await readCart();
      setError("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Không thể tải giỏ hàng.");
    }
  }, [readCart]);
  useEffect(() => {
    const timer = setTimeout(() => {
      void refreshCart();
    }, 0);
    return () => {
      clearTimeout(timer);
    };
  }, [pathname, refreshCart]);
  async function mutate(url: string, method: string, body?: unknown) {
    if (pending.current) return false;
    pending.current = true;
    setBusy(true);
    setError("");
    try {
      const response = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        ...(body ? { body: JSON.stringify(body) } : {}),
      });
      const result = await response.json();
      if (response.status === 401) {
        router.push(`/login?next=${encodeURIComponent(pathname)}`);
        return false;
      }
      if (!response.ok || !result.success)
        throw new Error(result.message || "Không thể cập nhật giỏ hàng.");
      await readCart();
      return true;
    } catch (e) {
      setError(
        e instanceof Error ? e.message : "Không thể kết nối đến máy chủ.",
      );
      return false;
    } finally {
      pending.current = false;
      setBusy(false);
    }
  }
  const addItem: CartContextType["addItem"] = async (
    item,
    quantity = 1,
    openDrawer = true,
  ) => {
    const ok = await mutate("/api/cart/items", "POST", {
      variantId: item.variantId,
      quantity,
    });
    if (ok && openDrawer) setIsCartOpen(true);
    return ok;
  };
  const updateQuantity: CartContextType["updateQuantity"] = async (
    id,
    quantity,
  ) => {
    const item = items.find((i) => i.cartItemId === id);
    if (!item?.backendCartItemId) return false;
    return mutate(
      `/api/cart/items/${item.backendCartItemId}`,
      quantity <= 0 ? "DELETE" : "PUT",
      quantity > 0 ? { quantity } : undefined,
    );
  };
  const removeItem: CartContextType["removeItem"] = (id) =>
    updateQuantity(id, 0);
  const clearCart = async () => {
    const ok = await mutate("/api/cart", "DELETE");
    if (ok) {
      voucherRef.current = null;
      setAppliedVoucher(null);
      setDiscountAmount(0);
    }
    return ok;
  };
  const applyVoucher = async (code: string) => {
    if (pending.current)
      return {
        success: false,
        message: "Giỏ hàng đang cập nhật. Vui lòng thử lại.",
      };
    pending.current = true;
    setBusy(true);
    try {
      const response = await fetch("/api/orders/preview", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ voucherCode: code.trim() }),
      });
      const body = await response.json();
      if (!response.ok || !body.success || !body.data?.isVoucherApplied)
        return {
          success: false,
          message:
            body.data?.voucherMessage ||
            body.message ||
            "Mã không áp dụng được.",
        };
      const voucher: Voucher = {
        voucherId: 0,
        code: body.data.voucherCode,
        title: body.data.voucherTitle,
        discountType: "FIXED",
        discountValue: body.data.voucherDiscountAmount,
        minOrderValue: 0,
        usageLimit: 0,
        limitPerUser: 1,
        startDate: "",
        endDate: "",
        isActive: true,
      };
      voucherRef.current = voucher;
      setAppliedVoucher(voucher);
      setDiscountAmount(body.data.voucherDiscountAmount);
      await readCart();
      return { success: true, message: "Đã áp dụng mã ưu đãi." };
    } catch {
      return {
        success: false,
        message: "Không thể kiểm tra mã. Vui lòng thử lại.",
      };
    } finally {
      pending.current = false;
      setBusy(false);
    }
  };
  const openCart = useCallback(() => setIsCartOpen(true), []);
  const closeCart = useCallback(() => setIsCartOpen(false), []);
  const toggleCart = useCallback(() => setIsCartOpen((v) => !v), []);
  const totalItems = items.reduce((s, i) => s + i.quantity, 0);
  const totalPrice = items.reduce((s, i) => s + i.quantity * i.price, 0);
  return (
    <CartContext.Provider
      value={{
        items,
        busy,
        error,
        refreshCart,
        dismissError: () => setError(""),
        totalItems,
        totalPrice,
        appliedVoucher,
        discountAmount,
        finalPrice: Math.max(0, totalPrice - discountAmount),
        isCartOpen,
        openCart,
        closeCart,
        toggleCart,
        addItem,
        updateQuantity,
        removeItem,
        clearCart,
        applyVoucher,
        removeVoucher: () => {
          voucherRef.current = null;
          setAppliedVoucher(null);
          setDiscountAmount(0);
        },
      }}
    >
      {children}
    </CartContext.Provider>
  );
}
export function useCart() {
  const context = useContext(CartContext);
  if (!context) throw new Error("CartProvider is required");
  return context;
}
