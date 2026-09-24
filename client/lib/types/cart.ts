export interface CartItem {
  cartItemId: string; // `${productId}-${variantId}`
  productId: number;
  productName: string;
  variantId: number;
  variantName: string;
  attributes: Record<string, string>;
  price: number;
  imageUrl: string | null;
  quantity: number;
  stockQuantity: number;
}

export interface CartContextType {
  items: CartItem[];
  totalItems: number;
  totalPrice: number;
  isCartOpen: boolean;
  openCart: () => void;
  closeCart: () => void;
  toggleCart: () => void;
  addItem: (item: Omit<CartItem, "cartItemId" | "quantity">, quantity?: number) => void;
  updateQuantity: (cartItemId: string, quantity: number) => void;
  removeItem: (cartItemId: string) => void;
  clearCart: () => void;
}
