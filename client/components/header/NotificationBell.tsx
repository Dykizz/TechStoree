"use client";

import Link from "next/link";
import { useCallback, useEffect, useId, useMemo, useRef, useState, useSyncExternalStore } from "react";
import {
  markNotificationsRead,
  notificationSnapshot,
  notifyOrderCancelled,
  notifyPaymentConfirmed,
  parseNotifications,
  subscribeNotifications,
} from "@/lib/customer-notifications";
import { useOrders } from "@/hooks/queries/useOrders";
import { cn } from "@/lib/utils";

const serverSnapshot = () => "[]";
const dateFormat = new Intl.DateTimeFormat("vi-VN", {
  day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit",
});

export default function NotificationBell({ userId }: { userId: number }) {
  const subscribe = useCallback((onChange: () => void) => subscribeNotifications(userId, onChange), [userId]);
  const getSnapshot = useCallback(() => notificationSnapshot(userId), [userId]);
  const snapshot = useSyncExternalStore(subscribe, getSnapshot, serverSnapshot);
  const notifications = useMemo(() => parseNotifications(snapshot), [snapshot]);
  const unread = notifications.filter((item) => !item.read).length;
  const [open, setOpen] = useState(false);
  const [unreadOnly, setUnreadOnly] = useState(false);
  const wrapper = useRef<HTMLDivElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const panel = useRef<HTMLElement>(null);
  const panelId = useId();
  const headingId = useId();

  const bellFilters = useMemo(() => ({ pageSize: "10" }), []);
  const { data: ordersData } = useOrders(bellFilters, Boolean(userId), {
    refetchInterval: 30000,
  });

  useEffect(() => {
    if (userId && ordersData?.orders) {
      ordersData.orders.forEach((order) => {
        notifyPaymentConfirmed(userId, order);
        notifyOrderCancelled(userId, order);
      });
    }
  }, [userId, ordersData]);

  useEffect(() => {
    if (!open) return;
    panel.current?.focus();
    const onOutside = (event: PointerEvent) => {
      if (!wrapper.current?.contains(event.target as Node)) setOpen(false);
    };
    const onEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setOpen(false);
        trigger.current?.focus();
      }
    };
    document.addEventListener("pointerdown", onOutside);
    document.addEventListener("keydown", onEscape);
    return () => {
      document.removeEventListener("pointerdown", onOutside);
      document.removeEventListener("keydown", onEscape);
    };
  }, [open]);

  const visible = unreadOnly ? notifications.filter((item) => !item.read) : notifications;

  return (
    <div
      className="relative shrink-0"
      ref={wrapper}
      onBlur={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) setOpen(false);
      }}
    >
      <button
        ref={trigger}
        type="button"
        className={cn(
          "relative grid place-items-center w-10 h-10 max-md:w-9 max-md:h-9 bg-neutral-100 text-neutral-800 border border-transparent rounded-full cursor-pointer transition-colors duration-200 hover:bg-red-50 hover:text-brand focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2 motion-reduce:transition-none",
          open && "bg-red-50 text-brand"
        )}
        aria-label={unread ? `Thông báo, ${unread} chưa đọc` : "Thông báo"}
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-controls={open ? panelId : undefined}
        onClick={() => setOpen((value) => !value)}
      >
        <svg
          className="w-5 h-5"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
          <path d="M10 21h4" />
        </svg>
        {unread > 0 && (
          <span
            className="absolute -top-1 -right-1 grid place-items-center min-w-4.5 h-4.5 px-1 border-2 border-white rounded-full text-white bg-brand text-[10px] font-bold"
            aria-hidden="true"
          >
            {unread > 9 ? "9+" : unread}
          </span>
        )}
      </button>
      <span className="sr-only" role="status">
        {unread > 0 ? `Bạn có ${unread} thông báo chưa đọc.` : ""}
      </span>
      {open && (
        <section
          ref={panel}
          id={panelId}
          className="absolute top-full mt-4 right-0 max-md:fixed max-md:top-20 max-md:right-4 w-96 max-w-[calc(100vw-2rem)] max-h-[calc(100dvh-6rem)] overflow-y-auto overscroll-contain border border-neutral-200 rounded-2xl pt-5 bg-white text-ink shadow-2xl focus:outline-none z-50"
          role="dialog"
          aria-labelledby={headingId}
          tabIndex={-1}
        >
          <div className="flex items-center justify-between px-5">
            <div>
              <p className="text-[10px] tracking-widest font-bold text-brand uppercase">TÀI KHOẢN CỦA BẠN</p>
              <h2 id={headingId} className="mt-1 text-2xl font-bold tracking-tight">
                Thông báo
              </h2>
            </div>
            <button
              type="button"
              className="border-0 bg-neutral-100 text-neutral-500 rounded-full w-8 h-8 text-xl cursor-pointer flex items-center justify-center hover:bg-neutral-200 transition-colors"
              aria-label="Đóng thông báo"
              onClick={() => {
                setOpen(false);
                trigger.current?.focus();
              }}
            >
              ×
            </button>
          </div>
          <div className="flex items-center justify-between gap-2 px-5 py-4 pb-3 max-sm:px-3">
            <div className="flex gap-1" aria-label="Lọc thông báo">
              <button
                type="button"
                className={cn(
                  "border-0 px-3 py-1.5 rounded-full text-xs cursor-pointer transition-colors",
                  !unreadOnly ? "text-brand bg-red-50 font-bold" : "bg-transparent text-neutral-500 hover:text-neutral-900"
                )}
                aria-pressed={!unreadOnly}
                onClick={() => setUnreadOnly(false)}
              >
                Tất cả
              </button>
              <button
                type="button"
                className={cn(
                  "border-0 px-3 py-1.5 rounded-full text-xs cursor-pointer transition-colors",
                  unreadOnly ? "text-brand bg-red-50 font-bold" : "bg-transparent text-neutral-500 hover:text-neutral-900"
                )}
                aria-pressed={unreadOnly}
                onClick={() => setUnreadOnly(true)}
              >
                Chưa đọc
              </button>
            </div>
            <button
              type="button"
              className="py-1 border-0 bg-transparent text-xs font-semibold text-brand cursor-pointer disabled:text-neutral-400 disabled:cursor-default"
              disabled={!unread}
              onClick={() => markNotificationsRead(userId)}
            >
              Đánh dấu đã đọc
            </button>
          </div>
          {visible.length ? (
            <ul className="list-none p-0 px-2 pb-2 m-0">
              {visible.map((item) => {
                const isCancelled = item.id.startsWith("cancel:");
                return (
                  <li key={item.id}>
                    <Link
                      href={item.href}
                      className={cn(
                        "flex gap-3 items-start p-3.5 px-3 rounded-xl text-inherit no-underline transition-colors hover:bg-neutral-50 focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2",
                        !item.read && "bg-red-50/50"
                      )}
                      onClick={() => {
                        markNotificationsRead(userId, item.id);
                        setOpen(false);
                        trigger.current?.focus();
                      }}
                    >
                      <span
                        className={cn(
                          "shrink-0 w-8 h-8 rounded-full grid place-items-center",
                          isCancelled
                            ? "bg-red-100 text-red-600"
                            : "bg-green-100 text-green-700"
                        )}
                        aria-hidden="true"
                      >
                        {isCancelled ? (
                          <svg
                            className="w-4 h-4"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          >
                            <circle cx="12" cy="12" r="10" />
                            <line x1="15" y1="9" x2="9" y2="15" />
                            <line x1="9" y1="9" x2="15" y2="15" />
                          </svg>
                        ) : (
                          <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="m6 12 4 4 8-9" />
                          </svg>
                        )}
                      </span>
                      <span className="grid gap-1 min-w-0 flex-1">
                        <strong className="text-xs font-semibold leading-normal text-ink">{item.title}</strong>
                        <span className="text-xs text-neutral-500 leading-relaxed break-words">{item.message}</span>
                        <time className="text-[10px] text-neutral-400" dateTime={item.createdAt}>
                          {dateFormat.format(new Date(item.createdAt))}
                        </time>
                      </span>
                      {!item.read && <span className="shrink-0 w-2 h-2 mt-2 rounded-full bg-brand" aria-label="Chưa đọc" />}
                    </Link>
                  </li>
                );
              })}
            </ul>
          ) : (
            <div className="text-center px-6 pt-6 pb-8">
              <span
                className="grid place-items-center w-10 h-10 mx-auto mb-3 rounded-full bg-neutral-100 text-neutral-400 text-lg"
                aria-hidden="true"
              >
                ✓
              </span>
              <h3 className="text-sm font-semibold text-ink">
                {unreadOnly ? "Bạn đã đọc hết thông báo" : "Chưa có thông báo"}
              </h3>
              <p className="mt-2 text-xs leading-relaxed text-neutral-500">
                Hoàn thành khảo sát, lưu hồ sơ hoặc đặt hàng thành công sẽ được ghi nhận tại đây.
              </p>
            </div>
          )}
          <p className="px-5 py-3 border-t border-neutral-200 text-[10px] leading-relaxed text-neutral-400">
            Lịch sử trên trình duyệt này · Tối đa 50 thông báo
          </p>
        </section>
      )}
    </div>
  );
}
