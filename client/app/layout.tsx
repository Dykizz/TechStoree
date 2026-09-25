import type { Metadata } from "next";
import "@fontsource-variable/inter/wght.css";
import "./globals.css";
import Header from "../components/header/Header";
import CartDrawer from "../components/cart/CartDrawer";
import { CartProvider } from "../lib/context/CartContext";

export const metadata: Metadata = {
  title: "TechStoree - Thiết bị công nghệ nguyên bản và tinh tế",
  description: "Khám phá các thiết bị công nghệ được chọn lọc kỹ lưỡng, trong một trải nghiệm mua sắm giản đơn.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="vi">
      <body>
        <CartProvider>
          <Header />
          {children}
          <CartDrawer />
        </CartProvider>
      </body>
    </html>
  );
}
