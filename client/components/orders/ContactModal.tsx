"use client";

import { useState } from "react";
import { Order, OrderItem } from "../../lib/types/order";
import styles from "./ContactModal.module.css";

interface ContactModalProps {
  isOpen: boolean;
  order: Order | null;
  item: OrderItem | null;
  onClose: () => void;
  onSent: (msg: string) => void;
}

const SUPPORT_TOPICS = [
  "Tư vấn kỹ thuật & hướng dẫn sử dụng",
  "Tra cứu chi tiết hành trình vận chuyển",
  "Yêu cầu đổi mới / bảo hành sản phẩm",
  "Yêu cầu xuất hóa đơn điện tử VAT",
  "Khác (Cần hỗ trợ trực tiếp)",
];

export default function ContactModal({
  isOpen,
  order,
  item,
  onClose,
  onSent,
}: ContactModalProps) {
  const [topic, setTopic] = useState(SUPPORT_TOPICS[0]);
  const [message, setMessage] = useState("");

  if (!isOpen || !order || !item) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSent(
      `Yêu cầu của bạn về "${topic}" cho đơn hàng ${order.orderCode} đã được tiếp nhận. Đội ngũ CSKH sẽ phản hồi qua số điện thoại ${order.recipientPhone} trong ít phút.`
    );
    onClose();
  };

  return (
    <div className={styles.overlay} onClick={onClose} role="dialog" aria-modal="true">
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <h2 className={styles.headerTitle}>Liên Hệ Người Bán & CSKH</h2>
          <button
            type="button"
            className={styles.closeBtn}
            onClick={onClose}
            aria-label="Đóng"
          >
            ✕
          </button>
        </div>

        <div className={styles.body}>
          <div className={styles.storeBanner}>
            <div className={styles.storeLogo}>T</div>
            <div className={styles.storeInfo}>
              <div className={styles.storeName}>TechStoree Official Store</div>
              <div className={styles.storeStatus}>
                <span>●</span> Đang trực tuyến · Phản hồi trong 5 phút
              </div>
            </div>
          </div>

          <div className={styles.contactGrid}>
            <a href="tel:18006936" className={styles.contactChannel}>
              <div className={styles.channelIcon}>📞</div>
              <div className={styles.channelText}>
                <span className={styles.channelTitle}>Hotline miễn phí</span>
                <span className={styles.channelValue}>1800 6936</span>
              </div>
            </a>
            <a
              href="https://zalo.me"
              target="_blank"
              rel="noopener noreferrer"
              className={styles.contactChannel}
            >
              <div className={styles.channelIcon}>💬</div>
              <div className={styles.channelText}>
                <span className={styles.channelTitle}>Zalo Official</span>
                <span className={styles.channelValue}>TechStoree CSKH</span>
              </div>
            </a>
          </div>

          <form onSubmit={handleSubmit} className={styles.formSection}>
            <div style={{ fontSize: "0.82rem", color: "#6b7280" }}>
              Đang hỗ trợ cho: <strong>{item.productName}</strong> (Mã đơn:{" "}
              <strong>{order.orderCode}</strong>)
            </div>

            <label className={styles.sectionLabel} htmlFor="support-topic">
              Chủ đề bạn cần hỗ trợ:
            </label>
            <select
              id="support-topic"
              className={styles.reasonSelect}
              value={topic}
              onChange={(e) => setTopic(e.target.value)}
            >
              {SUPPORT_TOPICS.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>

            <label className={styles.sectionLabel} htmlFor="support-message">
              Nội dung chi tiết:
            </label>
            <textarea
              id="support-message"
              className={styles.textarea}
              placeholder="Vui lòng cung cấp chi tiết câu hỏi hoặc vấn đề bạn gặp phải..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              required
            />

            <div className={styles.footer}>
              <button
                type="button"
                className={styles.cancelBtn}
                onClick={onClose}
              >
                Hủy
              </button>
              <button type="submit" className={styles.sendBtn}>
                Gửi yêu cầu hỗ trợ
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
