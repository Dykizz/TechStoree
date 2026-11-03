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
import { useQueryClient } from "@tanstack/react-query";
import { cartKeys } from "@/lib/query-keys/cart.keys";
import {
  fetchCartApi,
  previewCartApi,
  mutateCartApi,
  type ServerItem,
} from "@/lib/api/cart-api";
import type { CartContextType, CartItem } from "../types/cart";
import type { Voucher } from "../types/order";

const CartContext = createContext<CartContextType | undefined>(undefined);

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
  const queryClient = useQueryClient();

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
    const cartRes = await fetchCartApi();
    if (current !== version.current) return;

    if (cartRes.status === 401) {
      setItems([]);
      setAppliedVoucher(null);
      voucherRef.current = null;
      setDiscountAmount(0);
      return;
    }

    if (!cartRes.data) {
      throw new Error(cartRes.message || "Không thể tải giỏ hàng.");
    }

    if (cartRes.data.items.length) {
      const previewRes = await previewCartApi(voucherRef.current?.code);
      if (current !== version.current) return;
      if (!previewRes.ok || !previewRes.data) {
        throw new Error(
          previewRes.message || "Không thể cập nhật giá giỏ hàng."
        );
      }

      setItems(
        previewRes.data.items.map((it) =>
          mapItem({ ...it, price: it.unitPrice })
        )
      );
      setDiscountAmount(previewRes.data.voucherDiscountAmount);
      if (voucherRef.current && !previewRes.data.isVoucherApplied) {
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
      const res = await mutateCartApi(url, method, body);
      if (res.status === 401) {
        router.push(`/login?next=${encodeURIComponent(pathname)}`);
        return false;
      }
      if (!res.ok) {
        throw new Error(res.message || "Không thể cập nhật giỏ hàng.");
      }

      await readCart();
      void queryClient.invalidateQueries({ queryKey: cartKeys.all });
      return true;
    } catch (e) {
      setError(
        e instanceof Error ? e.message : "Không thể kết nối đến máy chủ."
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
    openDrawer = false
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
    quantity
  ) => {
    const item = items.find((i) => i.cartItemId === id);
    if (!item?.backendCartItemId) return false;
    return mutate(
      `/api/cart/items/${item.backendCartItemId}`,
      quantity <= 0 ? "DELETE" : "PUT",
      quantity > 0 ? { quantity } : undefined
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
    if (pending.current) {
      return {
        success: false,
        message: "Giỏ hàng đang cập nhật. Vui lòng thử lại.",
      };
    }
    pending.current = true;
    setBusy(true);

    try {
      const preview = await previewCartApi(code.trim());
      if (!preview.ok || !preview.data?.isVoucherApplied) {
        return {
          success: false,
          message:
            preview.data?.voucherMessage ||
            preview.message ||
            "Mã không áp dụng được.",
        };
      }

      const voucher: Voucher = {
        voucherId: 0,
        code: preview.data.voucherCode || code.trim(),
        title: preview.data.voucherTitle || "Mã ưu đãi",
        discountType: "FIXED",
        discountValue: preview.data.voucherDiscountAmount,
        minOrderValue: 0,
        usageLimit: 0,
        limitPerUser: 1,
        startDate: "",
        endDate: "",
        isActive: true,
      };

      voucherRef.current = voucher;
      setAppliedVoucher(voucher);
      setDiscountAmount(preview.data.voucherDiscountAmount);
      await readCart();
      void queryClient.invalidateQueries({ queryKey: cartKeys.all });
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
