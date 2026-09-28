"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { useCart } from "../../lib/context/CartContext";
import styles from "./Header.module.css";

type SessionUser = {
  userId: number;
  username: string;
  fullName: string;
  email: string;
  role: string;
};

export default function Header() {
  const pathname = usePathname();
  const { totalItems, openCart } = useCart();
  const [user, setUser] = useState<SessionUser | null>(null);

  useEffect(() => {
    async function checkAuth() {
      try {
        const res = await fetch("/api/auth/session", { cache: "no-store" });
        if (res.ok) {
          const data = await res.json();
          if (data && data.user) {
            setUser(data.user);
          }
        }
      } catch {
        // Auth session check optional
      }
    }
    void checkAuth();
  }, [pathname]);

  const handleLogout = async () => {
    try {
      await fetch("/api/auth/logout", { method: "POST" });
      setUser(null);
      window.location.reload();
    } catch {
      // Ignore
    }
  };

  return (
    <header className={styles.header}>
      <div className={styles.inner}>
        <div className={styles.left}>
          <Link href="/" className={styles.brand} aria-label="TechStoree Home">
            <span className={styles.brandMark}>T</span>
            <span>TECHSTOREE</span>
          </Link>

          <nav className={styles.nav} aria-label="Điều hướng chính">
            <Link
              href="/"
              className={`${styles.navLink} ${pathname === "/" ? styles.navLinkActive : ""}`}
            >
              Trang chủ
            </Link>
            <Link
              href="/products"
              className={`${styles.navLink} ${pathname.startsWith("/products") ? styles.navLinkActive : ""}`}
            >
              Sản phẩm
            </Link>
            <Link
              href="/cart"
              className={`${styles.navLink} ${pathname === "/cart" ? styles.navLinkActive : ""}`}
            >
              Giỏ hàng
            </Link>
            <Link
              href="/orders"
              className={`${styles.navLink} ${pathname === "/orders" ? styles.navLinkActive : ""}`}
            >
              Đơn hàng
            </Link>
          </nav>
        </div>

        <div className={styles.right}>
          <button
            type="button"
            className={styles.cartButton}
            onClick={openCart}
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
            <span className={styles.cartText}>Giỏ hàng</span>
            {totalItems > 0 && <span className={styles.cartBadge}>{totalItems}</span>}
          </button>

          {user ? (
            <div className={styles.userInfo}>
              <Link href="/profile" className={styles.userName} title="Xem hồ sơ cá nhân">
                {user.fullName || user.username}
              </Link>
              <button
                type="button"
                className={styles.logoutBtn}
                onClick={() => void handleLogout()}
              >
                Đăng xuất
              </button>
            </div>
          ) : (
            <Link href="/" className={styles.authLink}>
              Đăng nhập
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
