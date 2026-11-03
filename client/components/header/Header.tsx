"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { useCart } from "@/lib/context/CartContext";
import { logoutCustomer } from "@/lib/logout-client";
import { useSession } from "@/hooks/queries/useSession";
import { authKeys } from "@/lib/query-keys/auth.keys";
import CartDropdown from "../cart/CartDropdown";
import NotificationBell from "./NotificationBell";
import UserDropdown from "./UserDropdown";
import { cn } from "@/lib/utils";

export default function Header() {
  const pathname = usePathname();
  const queryClient = useQueryClient();
  const { data: user = null } = useSession();
  const { totalItems, openCart, isCartOpen } = useCart();
  const [menuOpen, setMenuOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);
  const [logoutError, setLogoutError] = useState("");
  const [isRightHovered, setIsRightHovered] = useState(false);

  const rightTimerRef = useRef<NodeJS.Timeout | null>(null);

  const handleRightMouseEnter = () => {
    if (rightTimerRef.current) clearTimeout(rightTimerRef.current);
    setIsRightHovered(true);
  };

  const handleRightMouseLeave = () => {
    rightTimerRef.current = setTimeout(() => {
      setIsRightHovered(false);
    }, 220);
  };

  const closeDropdowns = () => {
    setIsRightHovered(false);
  };

  // Close dropdown on route change or when cart drawer opens
  useEffect(() => {
    const t = setTimeout(() => {
      closeDropdowns();
      setMenuOpen(false);
    }, 0);
    return () => clearTimeout(t);
  }, [pathname, isCartOpen]);

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        closeDropdowns();
        setMenuOpen(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const handleLogout = async () => {
    if (loggingOut) return;
    setLoggingOut(true);
    setLogoutError("");
    try {
      await logoutCustomer();
      queryClient.setQueryData(authKeys.session(), null);
      const privateRoutes = ["/profile", "/orders", "/cart", "/checkout", "/surveys"];
      const isPrivateRoute = privateRoutes.some(
        (route) => pathname === route || pathname.startsWith(`${route}/`),
      );
      // A full navigation discards cached private pages and client cart state.
      // eslint-disable-next-line @next/next/no-location-assign-relative-destination -- Logout must discard the in-memory private-page/session cache.
      if (isPrivateRoute) window.location.href = "/";
      else window.location.reload();
    } catch (error) {
      setLogoutError(
        error instanceof Error
          ? error.message
          : "Không thể đăng xuất. Vui lòng thử lại.",
      );
      setLoggingOut(false);
    }
  };

  return (
    <header className="sticky top-0 z-[100] bg-white/92 backdrop-blur-md border-b border-black/[0.08] transition-all duration-200">
      <div className="max-w-[1280px] mx-auto px-6 h-[68px] flex items-center justify-between max-md:px-4 max-md:h-[60px]">
        <div className="flex items-center gap-[30px] max-[1050px]:gap-[18px] max-md:gap-5">
          <Link
            href="/"
            className="flex items-center gap-2.5 no-underline text-ink font-bold tracking-[0.15em] text-[0.82rem] max-[450px]:text-[10px] max-[450px]:gap-[7px] max-[360px]:[&>span:last-child]:hidden"
            aria-label="TechStoree Home"
          >
            <span
              className="w-7 h-7 bg-brand text-white rounded-[5px] relative flex items-center justify-center shrink-0 before:content-[''] before:absolute before:w-[17px] before:h-[5px] before:top-[6px] before:left-[5px] before:bg-white after:content-[''] after:absolute after:w-[5px] after:h-[11px] after:top-[11px] after:left-[11px] after:bg-white"
              aria-hidden="true"
            />
            <span>TECHSTOREE</span>
          </Link>

          {/* Menu giữa: Chỉ giữ Trang chủ và Sản phẩm. Giỏ hàng và Đơn hàng đã gộp sang góc phải */}
          <nav
            id="site-navigation"
            className={cn(
              "items-center gap-6 max-[1050px]:gap-4",
              menuOpen
                ? "flex absolute top-full left-0 right-0 flex-col items-stretch p-5 bg-white border-b border-border shadow-[0_12px_24px_rgba(0,0,0,0.04)] min-[851px]:static min-[851px]:flex-row min-[851px]:p-0 min-[851px]:bg-transparent min-[851px]:border-none min-[851px]:shadow-none"
                : "hidden min-[851px]:flex"
            )}
            aria-label="Điều hướng chính"
          >
            <Link
              href="/"
              className={cn(
                "text-[#555555] no-underline text-[0.92rem] font-medium tracking-[0.02em] transition-colors duration-150 relative py-1 hover:text-ink max-[850px]:py-3",
                pathname === "/" && "text-ink font-semibold after:content-[''] after:absolute after:bottom-0 after:left-0 after:right-0 after:h-[2px] after:bg-ink"
              )}
              onClick={() => setMenuOpen(false)}
            >
              Trang chủ
            </Link>
            <Link
              href="/products"
              className={cn(
                "text-[#555555] no-underline text-[0.92rem] font-medium tracking-[0.02em] transition-colors duration-150 relative py-1 hover:text-ink max-[850px]:py-3",
                pathname.startsWith("/products") && "text-ink font-semibold after:content-[''] after:absolute after:bottom-0 after:left-0 after:right-0 after:h-[2px] after:bg-ink"
              )}
              onClick={() => setMenuOpen(false)}
            >
              Sản phẩm
            </Link>

            {/* Mobile menu extras */}
            {menuOpen && (
              <div className="flex flex-col border-t border-dashed border-black/10 mt-2 pt-2">
                <Link
                  href="/orders"
                  className={cn(
                    "text-[#555555] no-underline text-[0.92rem] font-medium tracking-[0.02em] transition-colors duration-150 relative py-3 hover:text-ink",
                    pathname === "/orders" && "text-ink font-semibold"
                  )}
                  onClick={() => setMenuOpen(false)}
                >
                  Đơn hàng của tôi
                </Link>
                <Link
                  href="/cart"
                  className={cn(
                    "text-[#555555] no-underline text-[0.92rem] font-medium tracking-[0.02em] transition-colors duration-150 relative py-3 hover:text-ink",
                    pathname === "/cart" && "text-ink font-semibold"
                  )}
                  onClick={() => setMenuOpen(false)}
                >
                  Giỏ hàng ({totalItems})
                </Link>
                {user && (
                  <Link
                    href="/profile"
                    className={cn(
                      "text-[#555555] no-underline text-[0.92rem] font-medium tracking-[0.02em] transition-colors duration-150 relative py-3 hover:text-ink",
                      pathname === "/profile" && "text-ink font-semibold"
                    )}
                    onClick={() => setMenuOpen(false)}
                  >
                    Hồ sơ ({user.fullName || user.username})
                  </Link>
                )}
              </div>
            )}
          </nav>
        </div>

        <div className="flex items-center gap-5 max-[1050px]:gap-3 max-[450px]:gap-1.5">
          <button
            type="button"
            className="hidden max-[850px]:flex items-center justify-center bg-transparent border border-border rounded-[7px] w-9 h-9 text-xl cursor-pointer text-ink"
            aria-label={menuOpen ? "Đóng menu" : "Mở menu"}
            aria-controls="site-navigation"
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen(!menuOpen)}
          >
            {menuOpen ? "×" : "☰"}
          </button>

          {/* Nút Giỏ hàng góc phải duy nhất: Hover mở Popover, Click mở Drawer */}
          <div
            className="relative inline-flex items-center"
            onMouseEnter={handleRightMouseEnter}
            onMouseLeave={handleRightMouseLeave}
          >
            <button
              type="button"
              className="bg-transparent border border-black/10 rounded-full px-4 py-2 flex items-center gap-2 cursor-pointer text-[0.88rem] font-medium text-ink transition-all duration-200 hover:bg-[#f7f7f7] hover:border-black/20"
              onClick={() => {
                closeDropdowns();
                openCart();
              }}
              aria-label={`Giỏ hàng có ${totalItems} sản phẩm`}
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" />
                <path d="M3 6h18" />
                <path d="M16 10a4 4 0 0 1-8 0" />
              </svg>
              <span className="max-[850px]:hidden">Giỏ hàng</span>
              {totalItems > 0 && (
                <span className="bg-brand text-white text-xs font-bold min-w-[20px] h-5 rounded-full inline-flex items-center justify-center px-1.5">
                  {totalItems}
                </span>
              )}
            </button>

            {isRightHovered && !isCartOpen && (
              <CartDropdown align="right" onClose={closeDropdowns} />
            )}
          </div>

          {user && <NotificationBell key={user.userId} userId={user.userId} />}

          {/* User Profile Dropdown: Gom nhóm Đơn hàng, Profile, Surveys, Logout */}
          {user ? (
            <UserDropdown
              user={user}
              onLogout={handleLogout}
              loggingOut={loggingOut}
            />
          ) : (
            <Link
              href="/login"
              className="text-ink no-underline text-[0.88rem] font-medium px-4 py-2 rounded-md transition-colors hover:bg-gray-100 max-[450px]:p-2 max-[450px]:text-xs"
            >
              Đăng nhập
            </Link>
          )}
        </div>
      </div>
      {logoutError && (
        <p className="m-0 px-5 py-2.5 bg-rose-50 text-rose-800 text-center text-[0.85rem]" role="alert">
          {logoutError}
        </p>
      )}
    </header>
  );
}
