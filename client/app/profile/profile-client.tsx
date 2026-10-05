"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState, type FormEvent } from "react";
import { useProtectedSession } from "../../lib/use-protected-session";
import type { ProfileData } from "../../lib/auth-server";
import styles from "./profile.module.css";

type FormValues = {
  fullName: string;
  phone: string;
  dateOfBirth: string;
  techInterest: string;
  address: string;
};

const previewProfile: ProfileData = {
  userId: 0,
  username: "khach_hang_mau",
  fullName: "Nguyễn Minh Anh",
  email: "minhanh@example.com",
  role: "USER",
  phone: "090 123 4567",
  dateOfBirth: "1998-05-18T00:00:00Z",
  techInterest: "Điện thoại, âm thanh",
  address: "Quận 1, TP. Hồ Chí Minh",
};

function toForm(profile: ProfileData): FormValues {
  return {
    fullName: profile.fullName || "",
    phone: profile.phone || "",
    dateOfBirth: profile.dateOfBirth?.slice(0, 10) || "",
    techInterest: profile.techInterest || "",
    address: profile.address || "",
  };
}

export default function ProfileClient({ preview = false }: { preview?: boolean }) {
  const router = useRouter();
  const session = useProtectedSession(!preview);
  const [profile, setProfile] = useState<ProfileData | null>(preview ? previewProfile : null);
  const [form, setForm] = useState<FormValues | null>(preview ? toForm(previewProfile) : null);
  const [loadingError, setLoadingError] = useState("");
  const [reload, setReload] = useState(0);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState("");
  const [notice, setNotice] = useState("");
  const [loggingOut, setLoggingOut] = useState(false);

  useEffect(() => {
    if (preview || session.status !== "ready") return;
    const controller = new AbortController();
    async function load() {
      setLoadingError("");
      try {
        const response = await fetch("/api/auth/profile", { cache: "no-store", signal: controller.signal });
        if (response.status === 401) {
          router.replace("/");
          return;
        }
        const result = (await response.json()) as { profile?: ProfileData; message?: string };
        if (controller.signal.aborted) return;
        if (!response.ok || !result.profile) {
          setLoadingError(result.message || "Không thể tải hồ sơ. Vui lòng thử lại.");
          return;
        }
        setProfile(result.profile);
        setForm(toForm(result.profile));
      } catch {
        if (!controller.signal.aborted) setLoadingError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
      }
    }
    void load();
    return () => controller.abort();
  }, [preview, session.status, reload, router]);

  function change(field: keyof FormValues, value: string) {
    setForm((current) => current ? { ...current, [field]: value } : current);
    setSaveError("");
    setNotice("");
  }

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!form || saving) return;
    const fullName = form.fullName.trim();
    if (!fullName || fullName.length > 100 || form.phone.trim().length > 15 ||
        form.techInterest.trim().length > 100 || form.address.trim().length > 255 ||
        (form.dateOfBirth && form.dateOfBirth > new Date().toISOString().slice(0, 10))) {
      setSaveError("Vui lòng kiểm tra lại các thông tin trong biểu mẫu.");
      return;
    }
    setSaving(true);
    setSaveError("");
    setNotice("");
    if (preview) {
      setProfile((current) => current ? {
        ...current,
        fullName,
        phone: form.phone.trim() || null,
        dateOfBirth: form.dateOfBirth ? `${form.dateOfBirth}T00:00:00Z` : null,
        techInterest: form.techInterest.trim() || null,
        address: form.address.trim() || null,
      } : current);
      setNotice("Đã cập nhật bản xem trước. Dữ liệu này không được lưu vào tài khoản.");
      setSaving(false);
      return;
    }
    try {
      const response = await fetch("/api/auth/profile", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          fullName,
          phone: form.phone.trim() || null,
          dateOfBirth: form.dateOfBirth || null,
          techInterest: form.techInterest.trim() || null,
          address: form.address.trim() || null,
        }),
      });
      if (response.status === 401) {
        router.replace("/");
        return;
      }
      const result = (await response.json()) as { profile?: ProfileData; message?: string };
      if (!response.ok || !result.profile) {
        setSaveError(result.message || "Không thể lưu hồ sơ. Vui lòng thử lại.");
        return;
      }
      setProfile(result.profile);
      setForm(toForm(result.profile));
      setNotice("Đã lưu thông tin cá nhân.");
    } catch {
      setSaveError("Không thể kết nối đến máy chủ. Vui lòng thử lại.");
    } finally {
      setSaving(false);
    }
  }

  async function logout() {
    if (loggingOut) return;
    setLoggingOut(true);
    try {
      await fetch("/api/auth/logout", { method: "POST" });
    } catch {
      // Ignore
    } finally {
      try {
        localStorage.removeItem("techstoree_cart");
        localStorage.removeItem("techstoree_voucher");
      } catch {
        // Ignore
      }
      window.location.href = "/";
    }
  }

  const initials = profile?.fullName.trim().split(/\s+/).slice(-2).map((part) => part[0]?.toUpperCase()).join("") || "T";
  const error = preview ? "" : session.status === "error" ? session.message : loadingError;

  return (
    <main className={styles.page}>
      <header className={styles.header}>
        <Link className={styles.brand} href="/" aria-label="TechStoree">
          <span className={styles.brandMark}>T</span><span>TECHSTOREE</span>
        </Link>
        <span className={styles.headerCaption}>TÀI KHOẢN KHÁCH HÀNG</span>
        {preview ? <Link className={styles.headerAction} href="/profile">Xem trang thật</Link> : (
          <button className={styles.headerAction} type="button" onClick={() => void logout()} disabled={loggingOut || !profile}>
            {loggingOut ? "Đang đăng xuất…" : "Đăng xuất"}
          </button>
        )}
      </header>

      <div className={styles.container}>
        <div className={styles.pageIntro}>
          <p className={styles.eyebrow}>KHÔNG GIAN CỦA BẠN</p>
          <h1>Hồ sơ cá nhân<span>.</span></h1>
          <p>Quản lý thông tin của bạn trong một nơi đơn giản và an toàn.</p>
        </div>

        {preview && <div className={styles.previewBanner} role="status">BẢN XEM TRƯỚC · Thông tin bên dưới là dữ liệu mẫu. Bạn có thể thử chỉnh sửa giao diện; không có thay đổi nào được gửi tới backend.</div>}

        {!preview && (session.status === "checking" || (session.status === "ready" && !profile && !error)) ? (
          <div className={styles.stateCard} role="status">Đang xác minh và tải hồ sơ của bạn…</div>
        ) : error ? (
          <div className={styles.stateCard} role="alert">
            <h2>Chưa thể mở hồ sơ</h2>
            <p>{error}</p>
            <button className={styles.primaryButton} type="button" onClick={() => {
              if (session.status === "error") session.retry();
              else setReload((value) => value + 1);
            }}>Thử lại</button>
          </div>
        ) : profile && form ? (
          <div className={styles.grid}>
            <aside className={styles.summary} aria-label="Thông tin tài khoản">
              <div className={styles.avatar} aria-hidden="true">{initials}</div>
              <p className={styles.summaryLabel}>TÀI KHOẢN CỦA TÔI</p>
              <h2>{profile.fullName || profile.username}</h2>
              <p className={styles.summaryEmail}>{profile.email}</p>
              <div className={styles.summaryRule} />
              <p className={styles.summaryNote}>{preview ? "Đây là thông tin minh họa, không phải tài khoản thật." : "Thông tin được lưu trên tài khoản TechStoree của bạn."}</p>
            </aside>

            <section className={styles.formCard} aria-labelledby="profile-heading">
              <div className={styles.formHeading}>
                <div><p className={styles.eyebrow}>THÔNG TIN CÁ NHÂN</p><h2 id="profile-heading">Chi tiết hồ sơ</h2></div>
                <span className={styles.privateTag}>{preview ? "Dữ liệu mẫu" : "Riêng tư"}</span>
              </div>
              <form onSubmit={(event) => void save(event)}>
                <div className={styles.fields}>
                  <div className={styles.field}>
                    <label htmlFor="profile-name">HỌ VÀ TÊN <span>*</span></label>
                    <input id="profile-name" autoComplete="name" value={form.fullName} onChange={(event) => change("fullName", event.target.value)} maxLength={100} required />
                  </div>
                  <div className={styles.field}>
                    <label htmlFor="profile-phone">SỐ ĐIỆN THOẠI</label>
                    <input id="profile-phone" type="tel" autoComplete="tel" value={form.phone} onChange={(event) => change("phone", event.target.value)} maxLength={15} placeholder="Chưa cập nhật" />
                  </div>
                  <div className={styles.field}>
                    <label htmlFor="profile-birth">NGÀY SINH</label>
                    <input id="profile-birth" type="date" value={form.dateOfBirth} max={new Date().toISOString().slice(0, 10)} onChange={(event) => change("dateOfBirth", event.target.value)} />
                  </div>
                  <div className={styles.field}>
                    <label htmlFor="profile-interest">SỞ THÍCH CÔNG NGHỆ</label>
                    <input id="profile-interest" value={form.techInterest} onChange={(event) => change("techInterest", event.target.value)} maxLength={100} placeholder="Ví dụ: điện thoại, âm thanh…" />
                  </div>
                  <div className={`${styles.field} ${styles.fullWidth}`}>
                    <label htmlFor="profile-address">ĐỊA CHỈ</label>
                    <input id="profile-address" autoComplete="street-address" value={form.address} onChange={(event) => change("address", event.target.value)} maxLength={255} placeholder="Chưa cập nhật" />
                  </div>
                </div>
                <div className={styles.accountDetails}>
                  <p className={styles.eyebrow}>THÔNG TIN ĐĂNG NHẬP</p>
                  <div><span>Tên đăng nhập</span><strong>{profile.username}</strong></div>
                  <div><span>Địa chỉ email</span><strong>{profile.email}</strong></div>
                  <p>Tên đăng nhập và email hiện chưa thể thay đổi từ trang hồ sơ.</p>
                </div>
                {saveError && <p className={styles.error} role="alert">{saveError}</p>}
                {notice && <p className={styles.success} role="status">{notice}</p>}
                <div className={styles.actions}>
                  <button className={styles.secondaryButton} type="button" onClick={() => { setForm(toForm(profile)); setSaveError(""); setNotice(""); }} disabled={saving}>Hoàn tác</button>
                  <button className={styles.primaryButton} type="submit" disabled={saving}>{saving ? "Đang lưu…" : "Lưu thay đổi"}</button>
                </div>
              </form>
            </section>
          </div>
        ) : null}
      </div>
    </main>
  );
}
