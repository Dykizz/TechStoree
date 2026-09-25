"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { CartContextType, CartItem } from "../types/cart";
import { Voucher } from "../types/order";
import { validateVoucher } from "../order-client";

const CART_STORAGE_KEY = "techstoree_cart";
const VOUCHER_STORAGE_KEY = "techstoree_voucher";

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);
  const [appliedVoucher, setAppliedVoucher] = useState<Voucher | null>(null);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isHydrated, setIsHydrated] = useState(false);

  // Load cart and voucher from localStorage on client mount
  useEffect(() => {
    const timer = setTimeout(() => {
      try {
        const stored = localStorage.getItem(CART_STORAGE_KEY);
        if (stored) {
          const parsed = JSON.parse(stored) as CartItem[];
          if (Array.isArray(parsed)) {
            setItems(parsed);
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
    }, 0);
    return () => clearTimeout(timer);
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
        localStorage.setItem(
          VOUCHER_STORAGE_KEY,
          JSON.stringify(appliedVoucher)
        );
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
      const existingIndex = prevItems.findIndex(
        (it) => it.cartItemId === cartItemId
      );

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
  };

  const updateQuantity = (cartItemId: string, newQty: number) => {
    if (newQty <= 0) {
      removeItem(cartItemId);
      return;
    }

    setItems((prev) =>
      prev.map((item) => {
        if (item.cartItemId === cartItemId) {
          const clamped = Math.min(newQty, item.stockQuantity || 99);
          return { ...item, quantity: clamped };
        }
        return item;
      })
    );
  };

  const removeItem = (cartItemId: string) => {
    setItems((prev) => prev.filter((item) => item.cartItemId !== cartItemId));
  };

  const clearCart = () => {
    setItems([]);
    setAppliedVoucher(null);
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
