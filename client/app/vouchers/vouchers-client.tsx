"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useProtectedSession } from "../../lib/use-protected-session";
import { formatPrice } from "../../lib/products-client";
import styles from "./vouchers.module.css";

export interface UserVoucherItem {
  userVoucherId: number;
  voucherId: number;
  code: string;
  title: string;
  description?: string | null;
  discountType: "PERCENTAGE" | "FIXED_AMOUNT";
  discountValue: number;
  minOrderValue: number;
  maxDiscountAmount?: number | null;
  startDate: string;
  endDate: string;
  assignedType?: "CLAIMED" | "SURVEY_REWARD" | "ADMIN_GIFT" | string;
  assignedAt?: string;
  isUsed: boolean;
  usedAt?: string | null;
  orderId?: number | null;
  isUsable: boolean;
}

function formatDate(iso: string) {
  if (!iso) return "";
  try {
    const d = new Date(iso);
    return d.toLocaleDateString("vi-VN", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
  } catch {
    return iso;
  }
}

export default function VouchersClient() {
  const session = useProtectedSession();
  const [vouchers, setVouchers] = useState<UserVoucherItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState<"ALL" | "USABLE" | "SURVEY" | "USED">("ALL");
  const [copiedCode, setCopiedCode] = useState<string | null>(null);

  useEffect(() => {
    if (session.status !== "ready") return;

    let active = true;
    async function loadVouchers() {
      setLoading(true);
      setError("");
      try {
        const res = await fetch("/api/vouchers/my-wallet", {
          cache: "no-store",
        });
        const result = await res.json();
        if (!active) return;
        if (!res.ok || !result.success) {
          throw new Error(result.message || "Không thể tải danh sách voucher.");
        }
        setVouchers(Array.isArray(result.data) ? result.data : []);
      } catch (err: unknown) {
        if (active) {
          setError(
            err instanceof Error
              ? err.message
              : "Có lỗi xảy ra khi kết nối máy chủ.",
          );
        }
      } finally {
        if (active) setLoading(false);
      }
    }

    void loadVouchers();

    return () => {
      active = false;
    };
  }, [session.status]);

  const handleCopy = (code: string) => {
    void navigator.clipboard.writeText(code);
    setCopiedCode(code);
    setTimeout(() => {
      setCopiedCode((prev) => (prev === code ? null : prev));
    }, 2000);
  };

  const filteredVouchers = vouchers.filter((v) => {
    if (filter === "USABLE") return v.isUsable;
    if (filter === "SURVEY") return v.assignedType === "SURVEY_REWARD";
    if (filter === "USED") return v.isUsed || !v.isUsable;
    return true;
  });

  const usableCount = vouchers.filter((v) => v.isUsable).length;
  const surveyCount = vouchers.filter((v) => v.assignedType === "SURVEY_REWARD").length;

  if (session.status !== "ready") {
    return (
      <main className={styles.main}>
        <div className={styles.container}>
          <div className={styles.loadingBox}>
            {session.status === "error" ? (
              <>
                <p>{session.message}</p>
                <button onClick={session.retry} className={styles.filterBtn}>
                  Thử lại
                </button>
              </>
            ) : (
              "Đang kiểm tra phiên đăng nhập…"
            )}
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <Link href="/profile" className={styles.backLink}>
          ← Quay lại Hồ sơ cá nhân
        </Link>

        <p className={styles.eyebrow}>KHO VOUCHER CỦA BẠN</p>
        <h1 className={styles.title}>Mã giảm giá của tôi</h1>
        <p className={styles.description}>
          Danh sách mã ưu đãi độc quyền và phần thưởng nhận được từ các bài khảo sát ý kiến khách hàng. Chọn mã hoặc sao chép để áp dụng ngay khi thanh toán đơn hàng.
        </p>

        {/* BỘ LỌC */}
        <div className={styles.filters} role="tablist" aria-label="Lọc trạng thái mã giảm giá">
          <button
            type="button"
            className={`${styles.filterBtn} ${filter === "ALL" ? styles.filterBtnActive : ""}`}
            onClick={() => setFilter("ALL")}
            aria-pressed={filter === "ALL"}
          >
            Tất cả <span className={styles.badgeCount}>{vouchers.length}</span>
          </button>
          <button
            type="button"
            className={`${styles.filterBtn} ${filter === "USABLE" ? styles.filterBtnActive : ""}`}
            onClick={() => setFilter("USABLE")}
            aria-pressed={filter === "USABLE"}
          >
            Có thể dùng ngay <span className={styles.badgeCount}>{usableCount}</span>
          </button>
          <button
            type="button"
            className={`${styles.filterBtn} ${filter === "SURVEY" ? styles.filterBtnActive : ""}`}
            onClick={() => setFilter("SURVEY")}
            aria-pressed={filter === "SURVEY"}
          >
            🎁 Thưởng khảo sát <span className={styles.badgeCount}>{surveyCount}</span>
          </button>
          <button
            type="button"
            className={`${styles.filterBtn} ${filter === "USED" ? styles.filterBtnActive : ""}`}
            onClick={() => setFilter("USED")}
            aria-pressed={filter === "USED"}
          >
            Đã dùng / Hết hạn
          </button>
        </div>

        {error && (
          <div className={styles.emptyCard} role="alert">
            <div className={styles.emptyIcon}>⚠️</div>
            <h2 className={styles.emptyTitle}>Không thể tải mã giảm giá</h2>
            <p className={styles.emptyText}>{error}</p>
          </div>
        )}

        {loading ? (
          <div className={styles.loadingBox}>
            <p>Đang tải danh sách voucher của bạn…</p>
          </div>
        ) : filteredVouchers.length > 0 ? (
          <div className={styles.grid}>
            {filteredVouchers.map((v) => {
              const isSurveyReward = v.assignedType === "SURVEY_REWARD";
              const isCopied = copiedCode === v.code;

              return (
                <div
                  key={v.userVoucherId || v.code}
                  className={`${styles.voucherCard} ${!v.isUsable ? styles.voucherCardDisabled : ""}`}
                >
                  <div>
                    <div className={styles.cardTop}>
                      <span className={styles.codeBadge}>{v.code}</span>
                      {isSurveyReward && (
                        <span className={styles.surveyBadge}>
                          🎁 Thưởng khảo sát
                        </span>
                      )}
                      <span
                        className={`${styles.statusPill} ${
                          v.isUsed
                            ? styles.statusUsed
                            : v.isUsable
                              ? styles.statusUsable
                              : styles.statusExpired
                        }`}
                      >
                        {v.isUsed ? "Đã dùng" : v.isUsable ? "Có thể dùng" : "Hết hiệu lực"}
                      </span>
                    </div>

                    <div className={styles.discountValue}>
                      {v.discountType === "PERCENTAGE"
                        ? `Giảm ${v.discountValue}%`
                        : `Giảm ${formatPrice(v.discountValue)}`}
                    </div>

                    <h2 className={styles.cardTitle}>{v.title}</h2>
                    {v.description && (
                      <p className={styles.cardDescription}>{v.description}</p>
                    )}

                    <div className={styles.cardConditions}>
                      <div className={styles.conditionRow}>
                        <span>• Đơn tối thiểu:</span>
                        <strong>{v.minOrderValue > 0 ? formatPrice(v.minOrderValue) : "Không giới hạn"}</strong>
                      </div>
                      {v.maxDiscountAmount && v.maxDiscountAmount > 0 ? (
                        <div className={styles.conditionRow}>
                          <span>• Giảm tối đa:</span>
                          <strong>{formatPrice(v.maxDiscountAmount)}</strong>
                        </div>
                      ) : null}
                      <div className={styles.conditionRow}>
                        <span>• Hạn sử dụng:</span>
                        <strong>{formatDate(v.endDate)}</strong>
                      </div>
                    </div>
                  </div>

                  <div className={styles.cardActions}>
                    <button
                      type="button"
                      onClick={() => handleCopy(v.code)}
                      className={`${styles.copyBtn} ${isCopied ? styles.copyBtnCopied : ""}`}
                      title="Sao chép mã vào bộ nhớ tạm"
                    >
                      {isCopied ? "Đã chép ✓" : "Sao chép mã"}
                    </button>

                    {v.isUsable && (
                      <Link href="/products" className={styles.useBtn}>
                        Dùng ngay →
                      </Link>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className={styles.emptyCard}>
            <div className={styles.emptyIcon}>🏷️</div>
            <h2 className={styles.emptyTitle}>
              {filter === "ALL"
                ? "Bạn chưa có mã giảm giá nào"
                : "Không tìm thấy mã giảm giá phù hợp"}
            </h2>
            <p className={styles.emptyText}>
              Hãy tham gia các bài khảo sát sản phẩm tại TechStoree để nhận ngay các voucher giảm giá độc quyền vào ví của bạn.
            </p>
            <Link href="/surveys" className={styles.useBtn}>
              Làm khảo sát nhận voucher ↗
            </Link>
          </div>
        )}

        {/* BANNER THAM GIA KHẢO SÁT */}
        <div className={styles.surveyPromoBanner}>
          <div className={styles.surveyPromoContent}>
            <h3>🎁 Nhận thêm voucher giảm giá bằng cách làm khảo sát</h3>
            <p>
              Đóng góp ý kiến về các sản phẩm công nghệ bạn quan tâm để nhận ngay các mã ưu đãi độc quyền từ TechStoree.
            </p>
          </div>
          <Link href="/surveys" className={styles.surveyPromoBtn}>
            Tham gia khảo sát ngay ↗
          </Link>
        </div>
      </div>
    </main>
  );
}

