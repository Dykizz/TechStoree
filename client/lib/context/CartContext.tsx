"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { CartContextType, CartItem } from "../types/cart";

const CART_STORAGE_KEY = "techstoree_cart";

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isHydrated, setIsHydrated] = useState(false);

  // Load cart from localStorage on client mount
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
  };

  const totalItems = items.reduce((sum, it) => sum + it.quantity, 0);
  const totalPrice = items.reduce((sum, it) => sum + it.quantity * it.price, 0);

  return (
    <CartContext.Provider
      value={{
        items,
        totalItems,
        totalPrice,
        isCartOpen,
        openCart,
        closeCart,
        toggleCart,
        addItem,
        updateQuantity,
        removeItem,
        clearCart,
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
