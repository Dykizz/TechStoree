"use client";

import Link from "next/link";
import { useState, type FormEvent } from "react";
import PasswordVisibilityIcon from "../components/password-visibility-icon";
import styles from "../page.module.css";

type FieldName = "fullName" | "username" | "email" | "password" | "confirmPassword";
type FormValues = Record<FieldName, string>;
type FieldErrors = Partial<Record<FieldName, string>>;

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const initialValues: FormValues = {
  fullName: "", username: "", email: "", password: "", confirmPassword: "",
};

function validate(values: FormValues): FieldErrors {
  const errors: FieldErrors = {};
  if (!values.fullName.trim() || values.fullName.trim().length > 100) {
    errors.fullName = "Vui lòng nhập họ tên (tối đa 100 ký tự).";
  }
  if (values.username.trim().length < 3 || values.username.trim().length > 50) {
    errors.username = "Tên đăng nhập cần từ 3 đến 50 ký tự.";
  }
  if (!emailPattern.test(values.email.trim()) || values.email.trim().length > 254) {
    errors.email = "Vui lòng nhập email hợp lệ.";
  }
  if (values.password.length < 6 || values.password.length > 1024) {
    errors.password = "Mật khẩu cần ít nhất 6 ký tự.";
  }
  if (values.confirmPassword !== values.password) {
    errors.confirmPassword = "Hai mật khẩu chưa trùng nhau.";
  }
  return errors;
}

export default function RegisterForm() {
  const [values, setValues] = useState<FormValues>(initialValues);
  const [errors, setErrors] = useState<FieldErrors>({});
  const [serverError, setServerError] = useState("");
  const [pending, setPending] = useState(false);
  const [complete, setComplete] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  function update(field: FieldName, value: string) {
    setValues((current) => ({ ...current, [field]: value }));
    setErrors((current) => ({ ...current, [field]: "" }));
    setServerError("");
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (pending) return;
    const nextErrors = validate(values);
    setErrors(nextErrors);
    setServerError("");
    if (Object.keys(nextErrors).length) return;

    setPending(true);
    try {
      const response = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          fullName: values.fullName.trim(),
          username: values.username.trim(),
          email: values.email.trim().toLowerCase(),
          password: values.password,
        }),
      });
      const result = (await response.json()) as { message?: string };
      if (!response.ok) {
        setServerError(result.message || "Không thể đăng ký. Vui lòng thử lại.");
        return;
      }
      setValues(initialValues);
      setComplete(true);
    } catch {
      setServerError("Không thể kết nối đến máy chủ. Vui lòng thử lại sau.");
    } finally {
      setPending(false);
    }
  }

  if (complete) {
    return (
      <div className={styles.signedIn} role="status">
        <p className={styles.signedInKicker}>TÀI KHOẢN ĐÃ ĐƯỢC TẠO</p>
        <h2>Chào mừng bạn đến TechStoree.</h2>
        <p>Đăng ký thành công. Hãy đăng nhập bằng email và mật khẩu vừa tạo để tiếp tục.</p>
        <Link href="/login" className={styles.primaryButton}>Đi đến đăng nhập</Link>
      </div>
    );
  }

  return (
    <>
      <div className={styles.heading}>
        <p>TRỞ THÀNH KHÁCH HÀNG</p>
        <h2>Tạo tài khoản.</h2>
      </div>
      <p className={styles.registerIntro}>Một tài khoản để lưu thông tin cá nhân và tham gia những trải nghiệm dành riêng cho bạn.</p>
      {serverError && <div className={styles.formAlert} role="alert"><span className={styles.alertIcon} aria-hidden="true">!</span><span>{serverError}</span></div>}
      <form className={`${styles.form} ${styles.registerForm}`} onSubmit={handleSubmit} noValidate>
        <div className={styles.field}>
          <div className={styles.labelRow}><label htmlFor="register-full-name">HỌ VÀ TÊN</label></div>
          <input id="register-full-name" name="fullName" type="text" autoComplete="name" placeholder="Nguyễn Văn A" value={values.fullName}
            onChange={(event) => update("fullName", event.target.value)} aria-invalid={Boolean(errors.fullName)} aria-describedby={errors.fullName ? "register-full-name-error" : undefined} maxLength={100} required />
          {errors.fullName && <p className={styles.fieldError} id="register-full-name-error">{errors.fullName}</p>}
        </div>
        <div className={styles.field}>
          <div className={styles.labelRow}><label htmlFor="register-username">TÊN ĐĂNG NHẬP</label></div>
          <input id="register-username" name="username" type="text" autoComplete="username" placeholder="ten_dang_nhap" value={values.username}
            onChange={(event) => update("username", event.target.value)} aria-invalid={Boolean(errors.username)} aria-describedby={errors.username ? "register-username-error" : undefined} minLength={3} maxLength={50} required />
          {errors.username && <p className={styles.fieldError} id="register-username-error">{errors.username}</p>}
        </div>
        <div className={styles.field}>
          <div className={styles.labelRow}><label htmlFor="register-email">ĐỊA CHỈ EMAIL</label></div>
          <input id="register-email" name="email" type="email" autoComplete="email" inputMode="email" placeholder="tenban@example.com" value={values.email}
            onChange={(event) => update("email", event.target.value)} aria-invalid={Boolean(errors.email)} aria-describedby={errors.email ? "register-email-error" : undefined} maxLength={254} required />
          {errors.email && <p className={styles.fieldError} id="register-email-error">{errors.email}</p>}
        </div>
        <div className={styles.field}>
          <div className={styles.labelRow}><label htmlFor="register-password">MẬT KHẨU</label></div>
          <div className={styles.passwordWrap}>
            <input id="register-password" name="password" type={showPassword ? "text" : "password"} autoComplete="new-password" placeholder="Ít nhất 6 ký tự" value={values.password}
              onChange={(event) => update("password", event.target.value)} aria-invalid={Boolean(errors.password)} aria-describedby={errors.password ? "register-password-error" : undefined} minLength={6} required />
            <button className={styles.showPassword} type="button" onClick={() => setShowPassword((shown) => !shown)} aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"} aria-pressed={showPassword} aria-controls="register-password">
              <PasswordVisibilityIcon visible={showPassword} />
            </button>
          </div>
          {errors.password && <p className={styles.fieldError} id="register-password-error">{errors.password}</p>}
        </div>
        <div className={styles.field}>
          <div className={styles.labelRow}><label htmlFor="register-confirm">XÁC NHẬN MẬT KHẨU</label></div>
          <div className={styles.passwordWrap}>
            <input id="register-confirm" name="confirmPassword" type={showConfirmPassword ? "text" : "password"} autoComplete="new-password" placeholder="Nhập lại mật khẩu" value={values.confirmPassword}
              onChange={(event) => update("confirmPassword", event.target.value)} aria-invalid={Boolean(errors.confirmPassword)} aria-describedby={errors.confirmPassword ? "register-confirm-error" : undefined} required />
            <button className={styles.showPassword} type="button" onClick={() => setShowConfirmPassword((shown) => !shown)} aria-label={showConfirmPassword ? "Ẩn mật khẩu xác nhận" : "Hiện mật khẩu xác nhận"} aria-pressed={showConfirmPassword} aria-controls="register-confirm">
              <PasswordVisibilityIcon visible={showConfirmPassword} />
            </button>
          </div>
          {errors.confirmPassword && <p className={styles.fieldError} id="register-confirm-error">{errors.confirmPassword}</p>}
        </div>
        <button className={styles.primaryButton} type="submit" disabled={pending}>
          {pending ? "Đang tạo tài khoản…" : "Tạo tài khoản"}
        </button>
      </form>
      <div className={styles.signUp}>
        <span>Đã có tài khoản?</span><Link href="/login" className={styles.textButton}>Đăng nhập</Link>
      </div>
    </>
  );
}
