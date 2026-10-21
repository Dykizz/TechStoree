"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import styles from "./UserDropdown.module.css";

interface SessionUser {
  userId: number;
  username: string;
  fullName: string;
  email: string;
  role: string;
}

interface UserDropdownProps {
  user: SessionUser;
  onLogout: () => Promise<void>;
  loggingOut: boolean;
}

export default function UserDropdown({
  user,
  onLogout,
  loggingOut,
}: UserDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const closeTimerRef = useRef<NodeJS.Timeout | null>(null);
  const pathname = usePathname();

  const handleMouseEnter = () => {
    if (closeTimerRef.current) clearTimeout(closeTimerRef.current);
    setIsOpen(true);
  };

  const handleMouseLeave = () => {
    closeTimerRef.current = setTimeout(() => {
      setIsOpen(false);
    }, 220);
  };

  const toggleOpen = () => {
    setIsOpen((prev) => !prev);
  };

  const closeDropdown = () => {
    setIsOpen(false);
  };

  // Close dropdown on route change
  useEffect(() => {
    closeDropdown();
  }, [pathname]);

  // Click outside and escape key handling
  useEffect(() => {
    if (!isOpen) return;

    function handleClickOutside(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setIsOpen(false);
      }
    }

    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [isOpen]);

  const displayName = user.fullName?.trim() || user.username;
  const initial = displayName.charAt(0).toUpperCase() || "U";

  return (
    <div
      className={styles.dropdownContainer}
      ref={containerRef}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      {/* Trigger Button */}
      <button
        type="button"
        className={`${styles.triggerBtn} ${isOpen ? styles.triggerBtnActive : ""}`}
        onClick={toggleOpen}
        aria-haspopup="menu"
        aria-expanded={isOpen}
        aria-label={`Tài khoản của ${displayName}`}
      >
        <span className={styles.avatarCircle} aria-hidden="true">
          {initial}
        </span>
        <span className={styles.nameText}>{displayName}</span>
        <svg
          className={`${styles.chevronIcon} ${isOpen ? styles.chevronOpen : ""}`}
          width="12"
          height="12"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="m6 9 6 6 6-6" />
        </svg>
      </button>

      {/* Dropdown Menu */}
      {isOpen && (
        <div
          className={styles.menuPopover}
          role="menu"
          aria-label="Menu người dùng"
        >
          {/* Header Thông tin user */}
          <div className={styles.menuHeader}>
            <div className={styles.headerAvatar}>{initial}</div>
            <div className={styles.headerDetails}>
              <strong className={styles.headerName} title={displayName}>
                {displayName}
              </strong>
              <span className={styles.headerEmail} title={user.email}>
                {user.email || "techstoree@member.vn"}
              </span>
              <span className={styles.roleTag}>
                {user.role === "ADMIN" ? "Quản trị viên" : "Khách hàng thân thiết"}
              </span>
            </div>
          </div>

          <div className={styles.menuDivider} />

          {/* Danh sách liên kết điều hướng */}
          <div className={styles.menuItemsGroup}>
            <Link
              href="/profile"
              className={`${styles.menuItem} ${
                pathname === "/profile" ? styles.menuItemActive : ""
              }`}
              onClick={closeDropdown}
              role="menuitem"
            >
              <svg
                className={styles.itemIcon}
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
                <circle cx="12" cy="7" r="4" />
              </svg>
              <span>Hồ sơ cá nhân</span>
            </Link>

            {/* Mục "Đơn hàng" chuyển từ menu giữa vào đây theo đúng yêu cầu */}
            <Link
              href="/orders"
              className={`${styles.menuItem} ${
                pathname === "/orders" ? styles.menuItemActive : ""
              }`}
              onClick={closeDropdown}
              role="menuitem"
            >
              <svg
                className={styles.itemIcon}
                width="16"
                height="16"
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
              <span className={styles.itemLabelWithBadge}>
                <span>Đơn hàng của tôi</span>
                <span className={styles.menuBadge}>Theo dõi</span>
              </span>
            </Link>

            <Link
              href="/surveys"
              className={`${styles.menuItem} ${
                pathname === "/surveys" ? styles.menuItemActive : ""
              }`}
              onClick={closeDropdown}
              role="menuitem"
            >
              <svg
                className={styles.itemIcon}
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" />
                <rect x="8" y="2" width="8" height="4" rx="1" ry="1" />
                <path d="m9 14 2 2 4-4" />
              </svg>
              <span>Khảo sát & Quà tặng</span>
            </Link>
          </div>

          <div className={styles.menuDivider} />

          {/* Nút Đăng xuất */}
          <div className={styles.logoutWrapper}>
            <button
              type="button"
              className={styles.logoutButton}
              onClick={() => {
                closeDropdown();
                void onLogout();
              }}
              disabled={loggingOut}
              role="menuitem"
            >
              <svg
                className={styles.logoutIcon}
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                <polyline points="16 17 21 12 16 7" />
                <line x1="21" y1="12" x2="9" y2="12" />
              </svg>
              <span>{loggingOut ? "Đang đăng xuất…" : "Đăng xuất tài khoản"}</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
