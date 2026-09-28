"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { CartContextType, CartItem } from "../types/cart";
import { Voucher } from "../types/order";
import { validateVoucher } from "../order-client";

const CART_STORAGE_KEY = "techstoree_cart";
const VOUCHER_STORAGE_KEY = "techstoree_voucher";

const CartContext = createContext<CartContextType | undefined>(undefined);

interface BackendCartItem {
  cartItemId: number;
  variantId: number;
  productId: number;
  productName: string;
  variantName: string;
  imageUrl: string | null;
  price: number;
  quantity: number;
  stockQuantity: number;
  totalPrice: number;
}

interface BackendCartEnvelope {
  success: boolean;
  data?: {
    cartId: number;
    items: BackendCartItem[];
  };
}

const PRODUCT_IMAGE_FALLBACKS: Record<number, string> = {
  1: "/images/products/asus-zenbook-14.jpg",
  2: "/images/products/acer-nitro-v15.jpg",
  3: "/images/products/sony-wh1000xm5.jpg",
  4: "/images/products/fl-esports-gp75.jpg",
  5: "/images/products/google-nest-hub2.jpg",
};

export function resolveCartItemImage(
  url?: string | null,
  productId?: number
): string | null {
  if (url && !url.includes("cellphones.com.vn")) {
    return url;
  }
  if (productId && PRODUCT_IMAGE_FALLBACKS[productId]) {
    return PRODUCT_IMAGE_FALLBACKS[productId];
  }
  return url || null;
}

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);
  const [appliedVoucher, setAppliedVoucher] = useState<Voucher | null>(null);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isHydrated, setIsHydrated] = useState(false);
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  // Load cart from server or localStorage
  useEffect(() => {
    async function initCart() {
      // 1. Check local session
      let loggedIn = false;
      try {
        const sessionRes = await fetch("/api/auth/session", { cache: "no-store" });
        if (sessionRes.ok) {
          const sess = await sessionRes.json();
          if (sess && sess.user) loggedIn = true;
        }
      } catch {
        // Ignore session error
      }
      setIsLoggedIn(loggedIn);

      // 2. If logged in, fetch from Backend DB
      if (loggedIn) {
        try {
          const backendCartRes = await fetch("/api/cart", { cache: "no-store" });
          if (backendCartRes.ok) {
            const envelope = (await backendCartRes.json()) as BackendCartEnvelope;
            if (envelope && envelope.data && Array.isArray(envelope.data.items)) {
              const mapped: CartItem[] = envelope.data.items.map((it) => ({
                cartItemId: `${it.productId}-${it.variantId}`,
                backendCartItemId: it.cartItemId,
                productId: it.productId,
                productName: it.productName,
                variantId: it.variantId,
                variantName: it.variantName,
                price: it.price,
                quantity: it.quantity,
                stockQuantity: it.stockQuantity,
                imageUrl: resolveCartItemImage(it.imageUrl, it.productId),
                attributes: {},
              }));
              setItems(mapped);
              setIsHydrated(true);
              return;
            }
          }
        } catch {
          // Fallback to local
        }
      }

      // 3. Fallback: Load cart from localStorage
      try {
        const stored = localStorage.getItem(CART_STORAGE_KEY);
        if (stored) {
          const parsed = JSON.parse(stored) as CartItem[];
          if (Array.isArray(parsed)) {
            setItems(
              parsed.map((it) => ({
                ...it,
                imageUrl: resolveCartItemImage(it.imageUrl, it.productId),
              }))
            );
          }
        }
        const storedVoucher = localStorage.getItem(VOUCHER_STORAGE_KEY);
        if (storedVoucher) {
          const parsedV = JSON.parse(storedVoucher) as Voucher;
          if (parsedV && parsedV.code) {
            setAppliedVoucher(parsedV);
          }
        }
      } catch {
        // Ignore localStorage errors
      } finally {
        setIsHydrated(true);
      }
    }

    void initCart();
  }, []);

  // Save cart to localStorage when items update
  useEffect(() => {
    if (!isHydrated) return;
    try {
      localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(items));
    } catch {
      // Ignore quota errors
    }
  }, [items, isHydrated]);

  // Save or remove voucher from localStorage
  useEffect(() => {
    if (!isHydrated) return;
    try {
      if (appliedVoucher) {
        localStorage.setItem(VOUCHER_STORAGE_KEY, JSON.stringify(appliedVoucher));
      } else {
        localStorage.removeItem(VOUCHER_STORAGE_KEY);
      }
    } catch {
      // Ignore
    }
  }, [appliedVoucher, isHydrated]);

  const openCart = () => setIsCartOpen(true);
  const closeCart = () => setIsCartOpen(false);
  const toggleCart = () => setIsCartOpen((prev) => !prev);

  const addItem = (
    itemData: Omit<CartItem, "cartItemId" | "quantity">,
    quantity = 1
  ) => {
    const cartItemId = `${itemData.productId}-${itemData.variantId}`;
    setItems((prevItems) => {
      const existingIndex = prevItems.findIndex((it) => it.cartItemId === cartItemId);

      if (existingIndex > -1) {
        const existing = prevItems[existingIndex];
        const newQty = Math.min(
          existing.quantity + quantity,
          itemData.stockQuantity || 99
        );
        const updated = [...prevItems];
        updated[existingIndex] = { ...existing, quantity: newQty };
        return updated;
      }

      const initialQty = Math.min(
        Math.max(quantity, 1),
        itemData.stockQuantity || 99
      );
      return [...prevItems, { ...itemData, cartItemId, quantity: initialQty }];
    });

    setIsCartOpen(true);

    // Sync to backend DB if logged in
    if (isLoggedIn) {
      void fetch("/api/cart/items", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ variantId: itemData.variantId, quantity }),
      }).then(async (res) => {
        if (res.ok) {
          const envelope = await res.json();
          if (envelope && envelope.data && Array.isArray(envelope.data.items)) {
            const mapped: CartItem[] = envelope.data.items.map((it: BackendCartItem) => ({
              cartItemId: `${it.productId}-${it.variantId}`,
              backendCartItemId: it.cartItemId,
              productId: it.productId,
              productName: it.productName,
              variantId: it.variantId,
              variantName: it.variantName,
              price: it.price,
              quantity: it.quantity,
              stockQuantity: it.stockQuantity,
              imageUrl: it.imageUrl,
              attributes: {},
            }));
            setItems(mapped);
          }
        }
      });
    }
  };

  const updateQuantity = (cartItemId: string, newQty: number) => {
    if (newQty <= 0) {
      removeItem(cartItemId);
      return;
    }

    const item = items.find((i) => i.cartItemId === cartItemId);
    const backendId = item?.backendCartItemId;

    setItems((prev) =>
      prev.map((it) => {
        if (it.cartItemId === cartItemId) {
          const clamped = Math.min(newQty, it.stockQuantity || 99);
          return { ...it, quantity: clamped };
        }
        return it;
      })
    );

    // Sync to backend DB if logged in
    if (isLoggedIn && backendId) {
      void fetch(`/api/cart/items/${backendId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ quantity: newQty }),
      });
    }
  };

  const removeItem = (cartItemId: string) => {
    const item = items.find((i) => i.cartItemId === cartItemId);
    const backendId = item?.backendCartItemId;

    setItems((prev) => prev.filter((it) => it.cartItemId !== cartItemId));

    // Sync to backend DB if logged in
    if (isLoggedIn && backendId) {
      void fetch(`/api/cart/items/${backendId}`, {
        method: "DELETE",
      });
    }
  };

  const clearCart = () => {
    setItems([]);
    setAppliedVoucher(null);

    // Sync to backend DB if logged in
    if (isLoggedIn) {
      void fetch("/api/cart/clear", {
        method: "DELETE",
      });
    }
  };

  const totalItems = items.reduce((sum, it) => sum + it.quantity, 0);
  const totalPrice = items.reduce((sum, it) => sum + it.quantity * it.price, 0);

  // Calculate discount
  let discountAmount = 0;
  if (appliedVoucher && totalPrice >= appliedVoucher.minOrderValue) {
    if (appliedVoucher.discountType === "PERCENT") {
      const calculated = Math.round(
        totalPrice * (appliedVoucher.discountValue / 100)
      );
      discountAmount =
        appliedVoucher.maxDiscountAmount &&
        calculated > appliedVoucher.maxDiscountAmount
          ? appliedVoucher.maxDiscountAmount
          : calculated;
    } else {
      discountAmount = Math.min(appliedVoucher.discountValue, totalPrice);
    }
  }

  const finalPrice = Math.max(0, totalPrice - discountAmount);

  const applyVoucher = (code: string) => {
    const res = validateVoucher(code, totalPrice);
    if (res.valid && res.voucher) {
      setAppliedVoucher(res.voucher);
      return { success: true, message: res.message };
    }
    return { success: false, message: res.message };
  };

  const removeVoucher = () => {
    setAppliedVoucher(null);
  };

  return (
    <CartContext.Provider
      value={{
        items,
        totalItems,
        totalPrice,
        appliedVoucher,
        discountAmount,
        finalPrice,
        isCartOpen,
        openCart,
        closeCart,
        toggleCart,
        addItem,
        updateQuantity,
        removeItem,
        clearCart,
        applyVoucher,
        removeVoucher,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error("useCart must be used within a CartProvider");
  }
  return context;
}
