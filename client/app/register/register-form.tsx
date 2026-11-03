"use client";

import Link from "next/link";
import { useState, type FormEvent } from "react";
import PasswordVisibilityIcon from "@/components/auth/password-visibility-icon";
import { useRegister } from "@/hooks/mutations/useRegister";
import { cn } from "@/lib/utils";

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
  const [complete, setComplete] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const { mutate: register, isPending: pending } = useRegister();

  function update(field: FieldName, value: string) {
    setValues((current) => ({ ...current, [field]: value }));
    setErrors((current) => ({ ...current, [field]: "" }));
    setServerError("");
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (pending) return;
    const nextErrors = validate(values);
    setErrors(nextErrors);
    setServerError("");
    if (Object.keys(nextErrors).length) return;

    register(
      {
        fullName: values.fullName.trim(),
        username: values.username.trim(),
        email: values.email.trim().toLowerCase(),
        password: values.password,
      },
      {
        onSuccess: () => {
          setValues(initialValues);
          setComplete(true);
        },
        onError: (err) => {
          setServerError(
            err.message || "Không thể kết nối đến máy chủ. Vui lòng thử lại sau."
          );
        },
      }
    );
  }

  if (complete) {
    return (
      <div role="status">
        <p className="text-brand text-[10px] font-bold tracking-[0.13em]">TÀI KHOẢN ĐÃ ĐƯỢC TẠO</p>
        <h2 className="mt-3 text-[clamp(36px,3.1vw,50px)] font-[650] tracking-[-0.055em] leading-[1.14] text-[#17191c] max-[450px]:text-[42px]">
          Chào mừng bạn đến TechStoree.
        </h2>
        <p className="my-6 mb-8 text-[#626771] text-[15px] leading-[1.7]">
          Đăng ký thành công. Hãy đăng nhập bằng email và mật khẩu vừa tạo để tiếp tục.
        </p>
        <Link
          href="/login"
          className="flex w-full min-h-[56px] items-center justify-center gap-3 border border-[#17191c] rounded-[10px] py-3.5 px-[18px] bg-[#17191c] text-white cursor-pointer font-inherit text-sm font-bold no-underline text-center transition-[background,transform] duration-120 hover:bg-[#30343a] hover:-translate-y-px"
        >
          Đi đến đăng nhập
        </Link>
      </div>
    );
  }

  return (
    <>
      <div>
        <p className="text-brand text-[11px] font-extrabold tracking-[0.1em]">TRỞ THÀNH KHÁCH HÀNG</p>
        <h2 className="mt-3 text-[clamp(36px,3.1vw,50px)] font-[650] tracking-[-0.055em] leading-[1.14] text-[#17191c] max-[450px]:text-[42px]">
          Tạo tài khoản.
        </h2>
      </div>
      <p className="mt-5 text-[#626771] text-sm leading-[1.65]">
        Một tài khoản để lưu thông tin cá nhân và tham gia những trải nghiệm dành riêng cho bạn.
      </p>
      {serverError && (
        <div className="mt-11 flex items-start gap-2.5 border border-[#eec4c1] bg-[#fff6f5] text-[#9d2525] rounded-[10px] py-3.5 px-4 text-[13px] leading-[1.55]" role="alert">
          <span className="grid shrink-0 w-[17px] h-[17px] place-items-center border border-current rounded-full text-[11px] font-extrabold" aria-hidden="true">
            !
          </span>
          <span>{serverError}</span>
        </div>
      )}
      <form className="mt-[30px]" onSubmit={handleSubmit} noValidate>
        <div>
          <div className="flex justify-between gap-3 mb-2.5 text-[11px] font-bold tracking-[0.13em] text-[#17191c]">
            <label htmlFor="register-full-name">HỌ VÀ TÊN</label>
          </div>
          <input
            id="register-full-name"
            name="fullName"
            type="text"
            autoComplete="name"
            placeholder="Nguyễn Văn A"
            value={values.fullName}
            onChange={(event) => update("fullName", event.target.value)}
            aria-invalid={Boolean(errors.fullName)}
            aria-describedby={errors.fullName ? "register-full-name-error" : undefined}
            maxLength={100}
            className={cn(
              "w-full h-[54px] border rounded-[10px] px-4 outline-none bg-white text-[#17191c] font-inherit text-sm transition-[border-color,box-shadow] duration-120 placeholder:text-[#979ca4] focus-visible:border-brand focus-visible:ring-3 focus-visible:ring-brand/12",
              errors.fullName ? "border-[#c43131]" : "border-[#d6d9df]"
            )}
            required
          />
          {errors.fullName && (
            <p className="mt-2 text-[#ad2626] text-xs" id="register-full-name-error">
              {errors.fullName}
            </p>
          )}
        </div>

        <div className="mt-[17px]">
          <div className="flex justify-between gap-3 mb-2.5 text-[11px] font-bold tracking-[0.13em] text-[#17191c]">
            <label htmlFor="register-username">TÊN ĐĂNG NHẬP</label>
          </div>
          <input
            id="register-username"
            name="username"
            type="text"
            autoComplete="username"
            placeholder="ten_dang_nhap"
            value={values.username}
            onChange={(event) => update("username", event.target.value)}
            aria-invalid={Boolean(errors.username)}
            aria-describedby={errors.username ? "register-username-error" : undefined}
            minLength={3}
            maxLength={50}
            className={cn(
              "w-full h-[54px] border rounded-[10px] px-4 outline-none bg-white text-[#17191c] font-inherit text-sm transition-[border-color,box-shadow] duration-120 placeholder:text-[#979ca4] focus-visible:border-brand focus-visible:ring-3 focus-visible:ring-brand/12",
              errors.username ? "border-[#c43131]" : "border-[#d6d9df]"
            )}
            required
          />
          {errors.username && (
            <p className="mt-2 text-[#ad2626] text-xs" id="register-username-error">
              {errors.username}
            </p>
          )}
        </div>

        <div className="mt-[17px]">
          <div className="flex justify-between gap-3 mb-2.5 text-[11px] font-bold tracking-[0.13em] text-[#17191c]">
            <label htmlFor="register-email">ĐỊA CHỈ EMAIL</label>
          </div>
          <input
            id="register-email"
            name="email"
            type="email"
            autoComplete="email"
            inputMode="email"
            placeholder="tenban@example.com"
            value={values.email}
            onChange={(event) => update("email", event.target.value)}
            aria-invalid={Boolean(errors.email)}
            aria-describedby={errors.email ? "register-email-error" : undefined}
            maxLength={254}
            className={cn(
              "w-full h-[54px] border rounded-[10px] px-4 outline-none bg-white text-[#17191c] font-inherit text-sm transition-[border-color,box-shadow] duration-120 placeholder:text-[#979ca4] focus-visible:border-brand focus-visible:ring-3 focus-visible:ring-brand/12",
              errors.email ? "border-[#c43131]" : "border-[#d6d9df]"
            )}
            required
          />
          {errors.email && (
            <p className="mt-2 text-[#ad2626] text-xs" id="register-email-error">
              {errors.email}
            </p>
          )}
        </div>

        <div className="mt-[17px]">
          <div className="flex justify-between gap-3 mb-2.5 text-[11px] font-bold tracking-[0.13em] text-[#17191c]">
            <label htmlFor="register-password">MẬT KHẨU</label>
          </div>
          <div className="relative [&>input]:!pr-[72px]">
            <input
              id="register-password"
              name="password"
              type={showPassword ? "text" : "password"}
              autoComplete="new-password"
              placeholder="Ít nhất 6 ký tự"
              value={values.password}
              onChange={(event) => update("password", event.target.value)}
              aria-invalid={Boolean(errors.password)}
              aria-describedby={errors.password ? "register-password-error" : undefined}
              minLength={6}
              className={cn(
                "w-full h-[54px] border rounded-[10px] px-4 outline-none bg-white text-[#17191c] font-inherit text-sm transition-[border-color,box-shadow] duration-120 placeholder:text-[#979ca4] focus-visible:border-brand focus-visible:ring-3 focus-visible:ring-brand/12",
                errors.password ? "border-[#c43131]" : "border-[#d6d9df]"
              )}
              required
            />
            <button
              className="absolute top-[5px] right-[5px] grid w-11 h-11 place-items-center border-0 rounded-lg p-0 bg-transparent text-[#5a606a] cursor-pointer hover:bg-[#f7edef] hover:text-brand focus-visible:outline focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-1"
              type="button"
              onClick={() => setShowPassword((shown) => !shown)}
              aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
              aria-pressed={showPassword}
              aria-controls="register-password"
            >
              <PasswordVisibilityIcon visible={showPassword} />
            </button>
          </div>
          {errors.password && (
            <p className="mt-2 text-[#ad2626] text-xs" id="register-password-error">
              {errors.password}
            </p>
          )}
        </div>

        <div className="mt-[17px]">
          <div className="flex justify-between gap-3 mb-2.5 text-[11px] font-bold tracking-[0.13em] text-[#17191c]">
            <label htmlFor="register-confirm">XÁC NHẬN MẬT KHẨU</label>
          </div>
          <div className="relative [&>input]:!pr-[72px]">
            <input
              id="register-confirm"
              name="confirmPassword"
              type={showConfirmPassword ? "text" : "password"}
              autoComplete="new-password"
              placeholder="Nhập lại mật khẩu"
              value={values.confirmPassword}
              onChange={(event) => update("confirmPassword", event.target.value)}
              aria-invalid={Boolean(errors.confirmPassword)}
              aria-describedby={errors.confirmPassword ? "register-confirm-error" : undefined}
              className={cn(
                "w-full h-[54px] border rounded-[10px] px-4 outline-none bg-white text-[#17191c] font-inherit text-sm transition-[border-color,box-shadow] duration-120 placeholder:text-[#979ca4] focus-visible:border-brand focus-visible:ring-3 focus-visible:ring-brand/12",
                errors.confirmPassword ? "border-[#c43131]" : "border-[#d6d9df]"
              )}
              required
            />
            <button
              className="absolute top-[5px] right-[5px] grid w-11 h-11 place-items-center border-0 rounded-lg p-0 bg-transparent text-[#5a606a] cursor-pointer hover:bg-[#f7edef] hover:text-brand focus-visible:outline focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-1"
              type="button"
              onClick={() => setShowConfirmPassword((shown) => !shown)}
              aria-label={showConfirmPassword ? "Ẩn mật khẩu xác nhận" : "Hiện mật khẩu xác nhận"}
              aria-pressed={showConfirmPassword}
              aria-controls="register-confirm"
            >
              <PasswordVisibilityIcon visible={showConfirmPassword} />
            </button>
          </div>
          {errors.confirmPassword && (
            <p className="mt-2 text-[#ad2626] text-xs" id="register-confirm-error">
              {errors.confirmPassword}
            </p>
          )}
        </div>

        <button
          className="flex w-full min-h-[56px] items-center justify-center gap-3 border border-[#17191c] rounded-[10px] py-3.5 px-[18px] bg-[#17191c] text-white cursor-pointer font-inherit text-sm font-bold no-underline mt-[29px] transition-[background,transform] duration-120 hover:enabled:bg-[#30343a] hover:enabled:-translate-y-px disabled:cursor-wait disabled:opacity-70"
          type="submit"
          disabled={pending}
        >
          {pending ? "Đang tạo tài khoản…" : "Tạo tài khoản"}
        </button>
      </form>

      <div className="flex justify-center gap-[7px] mt-[22px] text-[#7a7e84] text-[13px] max-[450px]:flex-wrap">
        <span>Đã có tài khoản?</span>
        <Link
          href="/login"
          className="border-0 p-0 bg-transparent text-[#9d2430] cursor-pointer font-inherit font-[650] underline underline-offset-[3px] hover:text-[#d52432]"
        >
          Đăng nhập
        </Link>
      </div>
    </>
  );
}
