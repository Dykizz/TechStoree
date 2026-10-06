import type { Order } from "./types/order";

export type CustomerNotification = {
  id: string;
  kind: "survey" | "profile" | "order" | "payment";
  title: string;
  message: string;
  href: string;
  createdAt: string;
  read: boolean;
};

const EVENT = "techstoree:customer-notifications";
const LIMIT = 50;
type NotificationFeed = { items: CustomerNotification[]; seenIds: string[] };
const memory = new Map<number, NotificationFeed>();
const memoryOnly = new Set<number>();

export function notificationStorageKey(userId: number) {
  return `techstoree.notifications.v1.${userId}`;
}

function validUser(userId: number) {
  return Number.isSafeInteger(userId) && userId > 0;
}

function safeHref(href: string) {
  return /^\/(?:profile|surveys(?:\/[1-9]\d*)?|orders(?:\?code=[a-zA-Z0-9%._~-]+)?)$/.test(href);
}

export function parseNotifications(raw: string): CustomerNotification[] {
  try {
    const value: unknown = JSON.parse(raw);
    if (!Array.isArray(value)) return [];
    const seen = new Set<string>();
    return value.filter((item): item is CustomerNotification => {
      if (!item || typeof item !== "object") return false;
      const n = item as CustomerNotification;
      if (typeof n.id !== "string" || n.id.length > 120 || seen.has(n.id) ||
        !["survey", "profile", "order", "payment"].includes(n.kind) ||
        typeof n.title !== "string" || n.title.length > 160 ||
        typeof n.message !== "string" || n.message.length > 500 ||
        typeof n.href !== "string" || !safeHref(n.href) ||
        typeof n.createdAt !== "string" || !Number.isFinite(Date.parse(n.createdAt)) ||
        typeof n.read !== "boolean") return false;
      seen.add(n.id);
      return true;
    }).slice(0, LIMIT);
  } catch {
    return [];
  }
}

function emptyFeed(): NotificationFeed { return { items: [], seenIds: [] }; }

function readFeed(userId: number): NotificationFeed {
  if (typeof window === "undefined" || !validUser(userId)) return emptyFeed();
  if (memoryOnly.has(userId)) return memory.get(userId) || emptyFeed();
  try {
    const raw = window.localStorage.getItem(notificationStorageKey(userId));
    if (raw === null) return memory.get(userId) || emptyFeed();
    const stored = JSON.parse(raw);
    const items = parseNotifications(JSON.stringify(Array.isArray(stored) ? stored : stored?.items));
    const seenIds = Array.isArray(stored?.seenIds)
      ? stored.seenIds.filter((id: unknown): id is string => typeof id === "string" && id.length <= 120)
      : [];
    const feed = { items, seenIds: [...new Set<string>([...items.map((item) => item.id), ...seenIds])].slice(0, 500) };
    memory.set(userId, feed);
    return feed;
  } catch {
    return memory.get(userId) || emptyFeed();
  }
}

function writeFeed(userId: number, feed: NotificationFeed) {
  memory.set(userId, feed);
  try {
    window.localStorage.setItem(notificationStorageKey(userId), JSON.stringify(feed));
    memoryOnly.delete(userId);
  } catch {
    // Storage failure must not turn a successful API operation into a failed one.
    memoryOnly.add(userId);
  }
  window.dispatchEvent(new CustomEvent(EVENT, { detail: userId }));
}

export function notificationSnapshot(userId: number) {
  return JSON.stringify(readFeed(userId).items);
}

export function subscribeNotifications(userId: number, onChange: () => void) {
  const onLocal = (event: Event) => {
    if ((event as CustomEvent<number>).detail === userId) onChange();
  };
  const onStorage = (event: StorageEvent) => {
    if (event.key === notificationStorageKey(userId) || event.key === null) {
      // Do not retain a removed feed from another tab in the in-memory fallback.
      if (event.newValue === null) memory.delete(userId);
      memoryOnly.delete(userId);
      onChange();
    }
  };
  window.addEventListener(EVENT, onLocal);
  window.addEventListener("storage", onStorage);
  return () => {
    window.removeEventListener(EVENT, onLocal);
    window.removeEventListener("storage", onStorage);
  };
}

export function publishNotification(
  userId: number,
  input: Omit<CustomerNotification, "createdAt" | "read">,
) {
  if (typeof window === "undefined" || !validUser(userId)) return;
  const feed = readFeed(userId);
  if (feed.seenIds.includes(input.id)) return;
  const notification = { ...input, createdAt: new Date().toISOString(), read: false };
  if (parseNotifications(JSON.stringify([notification])).length !== 1) return;
  writeFeed(userId, {
    items: [notification, ...feed.items].slice(0, LIMIT),
    // Retain recent event IDs even when older notices leave the visible list.
    seenIds: [input.id, ...feed.seenIds].slice(0, 500),
  });
}

export function markNotificationsRead(userId: number, id?: string) {
  if (typeof window === "undefined" || !validUser(userId)) return;
  const feed = readFeed(userId);
  const items = feed.items;
  if (!items.some((item) => !item.read && (!id || item.id === id))) return;
  writeFeed(userId, { ...feed, items: items.map((item) => !id || item.id === id ? { ...item, read: true } : item) });
}

export function notifyPaymentConfirmed(userId: number, order: Order) {
  if (order.userId !== userId || order.paymentStatus !== "PAID") return;
  publishNotification(userId, {
    id: `payment:${order.orderId}`,
    kind: "payment",
    title: "Thanh toán đã được xác nhận",
    message: `Hệ thống xác nhận đơn ${order.orderCode} đã thanh toán.`,
    href: `/orders?code=${encodeURIComponent(order.orderCode)}`,
  });
}
