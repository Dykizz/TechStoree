"use client";

import Link from "next/link";
import { useCart } from "../lib/context/CartContext";
import { usePathname } from "next/navigation";
import Header from "./header/Header";
import Footer from "./footer/Footer";
import CartDrawer from "./cart/CartDrawer";

export default function SiteChrome({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const { error, dismissError, refreshCart } = useCart();
  const authPage = pathname === "/login" || pathname === "/register";
  return (
    <>
      {!authPage && <Header />}
      {!authPage && error && (
        <div className="site-error" role="alert">
          <span>{error}</span>
          <button onClick={() => void refreshCart()}>Thử lại</button>
          <Link href="/cart">Xem giỏ hàng</Link>
          <button onClick={dismissError} aria-label="Đóng thông báo">
            ×
          </button>
        </div>
      )}
      {children}
      {!authPage && (
        <>
          <Footer />
          <CartDrawer />
        </>
      )}
    </>
  );
}
