import { Voucher } from "./order";

export interface CartItem {
  cartItemId: string; // `${productId}-${variantId}`
  backendCartItemId?: number;
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
  busy: boolean;
  error: string;
  refreshCart: () => Promise<void>;
  dismissError: () => void;
  totalItems: number;
  totalPrice: number;
  appliedVoucher: Voucher | null;
  discountAmount: number;
  finalPrice: number;
  isCartOpen: boolean;
  openCart: () => void;
  closeCart: () => void;
  toggleCart: () => void;
  addItem: (
    item: Omit<CartItem, "cartItemId" | "quantity">,
    quantity?: number,
    openDrawer?: boolean,
  ) => Promise<boolean>;
  updateQuantity: (cartItemId: string, quantity: number) => Promise<boolean>;
  removeItem: (cartItemId: string) => Promise<boolean>;
  clearCart: () => Promise<boolean>;
  applyVoucher: (
    code: string,
  ) => Promise<{ success: boolean; message: string }>;
  removeVoucher: () => void;
}
