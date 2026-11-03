"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { useClickOutside } from "@/hooks/useClickOutside";
import { cn } from "@/lib/utils";

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

  // Close dropdown on route change without cascading render
  const [prevPathname, setPrevPathname] = useState(pathname);
  if (prevPathname !== pathname) {
    setPrevPathname(pathname);
    setIsOpen(false);
  }

  // Click outside handling
  useClickOutside(containerRef, () => setIsOpen(false), isOpen);

  // Escape key handling
  useEffect(() => {
    if (!isOpen) return;

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setIsOpen(false);
      }
    }

    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isOpen]);

  const displayName = user.fullName?.trim() || user.username;
  const initial = displayName.charAt(0).toUpperCase() || "U";

  return (
    <div
      className="relative inline-flex items-center"
      ref={containerRef}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      {/* Trigger Button */}
      <button
        type="button"
        className={cn(
          "bg-transparent border border-black/10 rounded-full py-1 pr-3 pl-1.5 flex items-center gap-2 cursor-pointer transition-all duration-200 text-neutral-900 font-sans hover:bg-neutral-50 hover:border-black/20 hover:shadow-sm",
          isOpen && "bg-neutral-50 border-black/20 shadow-sm"
        )}
        onClick={toggleOpen}
        aria-haspopup="menu"
        aria-expanded={isOpen}
        aria-label={`Tài khoản của ${displayName}`}
      >
        <span className="w-7.5 h-7.5 rounded-full bg-gradient-to-br from-slate-800 to-slate-950 text-white flex items-center justify-center text-xs font-bold shrink-0 shadow-sm" aria-hidden="true">
          {initial}
        </span>
        <span className="text-sm font-semibold max-w-[120px] truncate text-slate-800">{displayName}</span>
        <svg
          className={cn(
            "text-slate-500 transition-transform duration-200 ease-out shrink-0",
            isOpen && "rotate-180 text-slate-900"
          )}
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
          className="absolute top-[calc(100%+8px)] right-0 w-64 bg-white rounded-2xl shadow-[0_14px_40px_-10px_rgba(0,0,0,0.14),0_0_0_1px_rgba(0,0,0,0.06)] z-[1000] overflow-hidden animate-slideDown"
          role="menu"
          aria-label="Menu người dùng"
        >
          {/* Header Thông tin user */}
          <div className="p-4 flex items-center gap-3 bg-gradient-to-b from-slate-50 to-white">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-brand to-rose-900 text-white flex items-center justify-center text-lg font-bold shrink-0 shadow-md shadow-brand/25">{initial}</div>
            <div className="flex flex-col overflow-hidden min-w-0">
              <strong className="text-sm font-bold text-slate-900 truncate" title={displayName}>
                {displayName}
              </strong>
              <span className="text-xs text-slate-500 truncate mt-0.5" title={user.email}>
                {user.email || "techstoree@member.vn"}
              </span>
              <span className="inline-block self-start mt-1 px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 text-[10px] font-semibold uppercase tracking-wider">
                {user.role === "ADMIN" ? "Quản trị viên" : "Khách hàng thân thiết"}
              </span>
            </div>
          </div>

          <div className="h-px bg-slate-100 m-0" />

          {/* Danh sách liên kết điều hướng */}
          <div className="p-1.5 flex flex-col gap-0.5">
            <Link
              href="/profile"
              className={cn(
                "group flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-slate-700 no-underline text-sm font-medium transition-all duration-150 hover:bg-slate-50 hover:text-slate-900 hover:translate-x-0.5",
                pathname === "/profile" && "bg-slate-100 text-brand font-semibold"
              )}
              onClick={closeDropdown}
              role="menuitem"
            >
              <svg
                className={cn(
                  "text-slate-500 shrink-0 transition-colors group-hover:text-brand",
                  pathname === "/profile" && "text-brand"
                )}
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

            <Link
              href="/orders"
              className={cn(
                "group flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-slate-700 no-underline text-sm font-medium transition-all duration-150 hover:bg-slate-50 hover:text-slate-900 hover:translate-x-0.5",
                pathname === "/orders" && "bg-slate-100 text-brand font-semibold"
              )}
              onClick={closeDropdown}
              role="menuitem"
            >
              <svg
                className={cn(
                  "text-slate-500 shrink-0 transition-colors group-hover:text-brand",
                  pathname === "/orders" && "text-brand"
                )}
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
              <span className="flex items-center justify-between w-full">
                <span>Đơn hàng của tôi</span>
                <span className="text-[10px] font-bold bg-red-100 text-red-600 px-1.5 py-0.5 rounded-full tracking-wide">Theo dõi</span>
              </span>
            </Link>

            <Link
              href="/surveys"
              className={cn(
                "group flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-slate-700 no-underline text-sm font-medium transition-all duration-150 hover:bg-slate-50 hover:text-slate-900 hover:translate-x-0.5",
                pathname === "/surveys" && "bg-slate-100 text-brand font-semibold"
              )}
              onClick={closeDropdown}
              role="menuitem"
            >
              <svg
                className={cn(
                  "text-slate-500 shrink-0 transition-colors group-hover:text-brand",
                  pathname === "/surveys" && "text-brand"
                )}
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

          <div className="h-px bg-slate-100 m-0" />

          {/* Nút Đăng xuất */}
          <div className="p-1.5 bg-neutral-50">
            <button
              type="button"
              className="group w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl bg-transparent border-0 text-slate-500 text-sm font-medium cursor-pointer text-left transition-colors duration-150 hover:bg-red-50 hover:text-red-500 disabled:opacity-60 disabled:cursor-wait"
              onClick={() => {
                closeDropdown();
                void onLogout();
              }}
              disabled={loggingOut}
              role="menuitem"
            >
              <svg
                className="shrink-0 transition-transform duration-200 group-hover:translate-x-0.5"
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
