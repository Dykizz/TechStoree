import type { Metadata } from "next";
import "@fontsource-variable/inter/wght.css";
import "./globals.css";
import SiteChrome from "../components/SiteChrome";
import { CartProvider } from "../lib/context/CartContext";

export const metadata: Metadata = {
  title: "TechStoree - Thiết bị công nghệ nguyên bản và tinh tế",
  description:
    "Khám phá các thiết bị công nghệ được chọn lọc kỹ lưỡng, trong một trải nghiệm mua sắm giản đơn.",
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
          <SiteChrome>{children}</SiteChrome>
        </CartProvider>
      </body>
    </html>
  );
}
