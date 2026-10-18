"use client";

import Link from "next/link";
import { useCallback, useEffect, useId, useMemo, useRef, useState, useSyncExternalStore } from "react";
import {
  markNotificationsRead,
  notificationSnapshot,
  parseNotifications,
  subscribeNotifications,
} from "../../lib/customer-notifications";
import styles from "./NotificationBell.module.css";

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
    <div className={styles.wrapper} ref={wrapper} onBlur={(event) => {
      if (!event.currentTarget.contains(event.relatedTarget)) setOpen(false);
    }}>
      <button
        ref={trigger}
        type="button"
        className={`${styles.bell} ${open ? styles.selected : ""}`}
        aria-label={unread ? `Thông báo, ${unread} chưa đọc` : "Thông báo"}
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-controls={open ? panelId : undefined}
        onClick={() => setOpen((value) => !value)}
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
          <path d="M10 21h4" />
        </svg>
        {unread > 0 && <span className={styles.badge} aria-hidden="true">{unread > 9 ? "9+" : unread}</span>}
      </button>
      <span className={styles.srOnly} role="status">{unread > 0 ? `Bạn có ${unread} thông báo chưa đọc.` : ""}</span>
      {open && (
        <section ref={panel} id={panelId} className={styles.panel} role="dialog" aria-labelledby={headingId} tabIndex={-1}>
          <div className={styles.heading}>
            <div><p>TÀI KHOẢN CỦA BẠN</p><h2 id={headingId}>Thông báo</h2></div>
            <button type="button" className={styles.close} aria-label="Đóng thông báo" onClick={() => { setOpen(false); trigger.current?.focus(); }}>×</button>
          </div>
          <div className={styles.toolbar}>
            <div className={styles.filters} aria-label="Lọc thông báo">
              <button type="button" aria-pressed={!unreadOnly} onClick={() => setUnreadOnly(false)}>Tất cả</button>
              <button type="button" aria-pressed={unreadOnly} onClick={() => setUnreadOnly(true)}>Chưa đọc</button>
            </div>
            <button type="button" className={styles.markRead} disabled={!unread} onClick={() => markNotificationsRead(userId)}>Đánh dấu đã đọc</button>
          </div>
          {visible.length ? (
            <ul className={styles.list}>
              {visible.map((item) => (
                <li key={item.id}>
                  <Link href={item.href} className={`${styles.item} ${item.read ? "" : styles.unread}`} onClick={() => { markNotificationsRead(userId, item.id); setOpen(false); trigger.current?.focus(); }}>
                    <span className={styles.successIcon} aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m6 12 4 4 8-9" /></svg></span>
                    <span className={styles.content}><strong>{item.title}</strong><span>{item.message}</span><time dateTime={item.createdAt}>{dateFormat.format(new Date(item.createdAt))}</time></span>
                    {!item.read && <span className={styles.dot} aria-label="Chưa đọc" />}
                  </Link>
                </li>
              ))}
            </ul>
          ) : (
            <div className={styles.empty}><span aria-hidden="true">✓</span><h3>{unreadOnly ? "Bạn đã đọc hết thông báo" : "Chưa có thông báo"}</h3><p>Hoàn thành khảo sát, lưu hồ sơ hoặc đặt hàng thành công sẽ được ghi nhận tại đây.</p></div>
          )}
          <p className={styles.note}>Lịch sử trên trình duyệt này · Tối đa 50 thông báo</p>
        </section>
      )}
    </div>
  );
}
