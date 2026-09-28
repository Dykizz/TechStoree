"use client";

import Link from "next/link";
import { useEffect, useState, type FormEvent } from "react";
import AuthStory from "./components/auth-story";
import PasswordVisibilityIcon from "./components/password-visibility-icon";
import styles from "./page.module.css";

type SessionUser = {
  userId: number;
  username: string;
  fullName: string;
  email: string;
  role: string;
};

type AuthResult = { user?: SessionUser; message?: string };
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function Home() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [remember, setRemember] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [pending, setPending] = useState(false);
  const [checkingSession, setCheckingSession] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [user, setUser] = useState<SessionUser | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    async function checkSession() {
      try {
        const response = await fetch("/api/auth/session", {
          cache: "no-store",
          signal: controller.signal,
        });
        if (response.ok) {
          const result = (await response.json()) as AuthResult;
          setUser(result.user ?? null);
        }
      } catch {
        // Keep the form available even if the backend is offline.
      } finally {
        if (!controller.signal.aborted) setCheckingSession(false);
      }
    }
    void checkSession();
    return () => controller.abort();
  }, []);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (pending) return;
    const normalizedEmail = email.trim().toLowerCase();
    const nextEmailError = emailPattern.test(normalizedEmail)
      ? ""
      : "Vui lòng nhập email hợp lệ.";
    const nextPasswordError = password ? "" : "Vui lòng nhập mật khẩu.";
    setEmailError(nextEmailError);
    setPasswordError(nextPasswordError);
    setError("");
    setNotice("");
    if (nextEmailError || nextPasswordError) return;

    setPending(true);
    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: normalizedEmail, password, remember }),
      });
      const result = (await response.json()) as AuthResult;
      if (!response.ok || !result.user) {
        setError(result.message ?? "Không thể đăng nhập. Vui lòng thử lại.");
        return;
      }
      setPassword("");
      setUser(result.user);
    } catch {
      setError("Không thể kết nối đến máy chủ. Vui lòng thử lại sau.");
    } finally {
      setPending(false);
    }
  }

  async function handleLogout() {
    if (pending) return;
    setPending(true);
    setError("");
    try {
      const response = await fetch("/api/auth/logout", { method: "POST" });
      const result = (await response.json()) as AuthResult;
      if (!response.ok) {
        setNotice(result.message ?? "Đã rời phiên trên trình duyệt này.");
      }
    } catch {
      setNotice("Đã rời phiên trên trình duyệt này; chưa xác nhận được với máy chủ.");
    } finally {
      setUser(null);
      setPending(false);
    }
  }

  return (
    <main className={styles.page}>
      <AuthStory />

      <section className={styles.authPanel} aria-label="Đăng nhập TechStoree">
        <div className={styles.mobileBrand} aria-hidden="true">
          <span className={styles.brandMark} /><span>TECHSTOREE</span>
        </div>
        <div className={styles.authContent}>
          {checkingSession ? (
            <div className={styles.sessionLoading} role="status">Đang kiểm tra phiên đăng nhập…</div>
          ) : user ? (
            <div className={styles.signedIn}>
              <p className={styles.signedInKicker}>ĐĂNG NHẬP THÀNH CÔNG</p>
              <h2>Xin chào, {user.fullName || user.username}.</h2>
              <p>Bạn đã đăng nhập với <strong>{user.email}</strong>. Hồ sơ cá nhân và danh mục sản phẩm của bạn đã sẵn sàng.</p>
              <div style={{ display: "flex", flexDirection: "column", gap: "10px", marginTop: "20px" }}>
                <Link
                  href="/profile"
                  className={styles.primaryButton}
                  style={{ textDecoration: "none", textAlign: "center" }}
                >
                  Xem hồ sơ của tôi
                </Link>
                <Link
                  href="/products"
                  className={styles.primaryButton}
                  style={{
                    textDecoration: "none",
                    textAlign: "center",
                    background: "#bd202d",
                    borderColor: "#bd202d",
                  }}
                >
                  Khám phá sản phẩm ngay
                </Link>
                <button className={styles.textButton} type="button" onClick={() => void handleLogout()} disabled={pending}>
                  {pending ? "Đang đăng xuất…" : "Đăng xuất tài khoản"}
                </button>
              </div>
            </div>
          ) : (
            <>
              <div className={styles.heading}>
                <p>ĐĂNG NHẬP HỆ THỐNG</p>
                <h2>Chào mừng trở lại.</h2>
              </div>
              {error && <div className={styles.formAlert} role="alert"><span className={styles.alertIcon} aria-hidden="true">!</span><span>{error}</span></div>}
              {notice && <div className={styles.notice} role="status">{notice}</div>}
              <form className={styles.form} onSubmit={handleSubmit} noValidate>
                <div className={styles.field}>
                  <div className={styles.labelRow}><label htmlFor="email">ĐỊA CHỈ EMAIL</label></div>
                  <input id="email" name="email" type="email" autoComplete="email" inputMode="email" placeholder="tenban@example.com" value={email}
                    onChange={(event) => { setEmail(event.target.value); setEmailError(""); }}
                    aria-invalid={Boolean(emailError)} aria-describedby={emailError ? "email-error" : undefined} required />
                  {emailError && <p className={styles.fieldError} id="email-error">{emailError}</p>}
                </div>
                <div className={styles.field}>
                  <div className={styles.labelRow}><label htmlFor="password">MẬT KHẨU</label></div>
                  <div className={styles.passwordWrap}>
                    <input id="password" name="password" type={showPassword ? "text" : "password"} autoComplete="current-password" placeholder="Nhập mật khẩu" value={password}
                      onChange={(event) => { setPassword(event.target.value); setPasswordError(""); }}
                      aria-invalid={Boolean(passwordError)} aria-describedby={passwordError ? "password-error" : undefined} required />
                    <button className={styles.showPassword} type="button" onClick={() => setShowPassword((shown) => !shown)} aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"} aria-pressed={showPassword} aria-controls="password">
                      <PasswordVisibilityIcon visible={showPassword} />
                    </button>
                  </div>
                  {passwordError && <p className={styles.fieldError} id="password-error">{passwordError}</p>}
                </div>
                <div className={styles.formOptions}>
                  <label className={styles.remember}><input type="checkbox" checked={remember} onChange={(event) => setRemember(event.target.checked)} /><span>Duy trì đăng nhập</span></label>
                  <button type="button" className={styles.textButton} onClick={() => { setError(""); setNotice("Tính năng đặt lại mật khẩu chưa được backend hỗ trợ."); }}>Quên mật khẩu?</button>
                </div>
                <button className={styles.primaryButton} type="submit" disabled={pending}>
                  <span>{pending ? "Đang đăng nhập…" : "Đăng nhập"}</span>
                </button>
              </form>
              <div className={styles.signUp}>
                <span>Chưa có tài khoản?</span>
                <Link href="/register" className={styles.textButton}>Tạo tài khoản mới</Link>
              </div>
            </>
          )}
        </div>
      </section>
    </main>
  );
}
