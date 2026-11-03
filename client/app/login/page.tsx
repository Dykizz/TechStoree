"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { useQueryClient } from "@tanstack/react-query";
import AuthStory from "@/components/auth/auth-story";
import PasswordVisibilityIcon from "@/components/auth/password-visibility-icon";
import { useSession } from "@/hooks/queries/useSession";
import { useLogin } from "@/hooks/mutations/useLogin";
import { authKeys } from "@/lib/query-keys/auth.keys";
import { logoutCustomer } from "@/lib/logout-client";
import { cn } from "@/lib/utils";

type SessionUser = {
  userId: number;
  username: string;
  fullName: string;
  email: string;
  role: string;
};

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function LoginPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { data: sessionUser, isLoading: checkingSession } = useSession();
  const { mutate: login, isPending: isLoggingIn } = useLogin();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [remember, setRemember] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [localUser, setLocalUser] = useState<SessionUser | null>(null);

  const user = localUser ?? sessionUser ?? null;
  const pending = isLoggingIn || isLoggingOut;

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

    login(
      { email: normalizedEmail, password, remember },
      {
        onSuccess: (result) => {
          setPassword("");
          setLocalUser(result.user);
          const next = new URLSearchParams(window.location.search).get("next");
          router.replace(
            next?.startsWith("/") && !next.startsWith("//") && !next.includes("\\")
              ? next
              : "/"
          );
          router.refresh();
        },
        onError: (err) => {
          setError(
            err.message ||
              "Không thể kết nối đến máy chủ. Vui lòng thử lại sau."
          );
        },
      }
    );
  }

  async function handleLogout() {
    if (pending) return;
    setIsLoggingOut(true);
    setError("");
    try {
      await logoutCustomer();
      queryClient.setQueryData(authKeys.session(), null);
    } catch {
      setNotice(
        "Đã rời phiên trên trình duyệt này; chưa xác nhận được với máy chủ."
      );
    } finally {
      setLocalUser(null);
      setIsLoggingOut(false);
    }
  }

  return (
    <main className="grid grid-cols-[minmax(0,52%)_minmax(0,48%)] min-h-[100svh] text-[#17191c] max-[1100px]:grid-cols-[minmax(0,48%)_minmax(0,52%)] max-[900px]:grid-cols-1">
      <AuthStory />

      <section
        className="relative flex min-w-0 flex-col items-center justify-start pt-[clamp(82px,13vh,140px)] px-[clamp(30px,5vw,90px)] pb-10 bg-[#fafaf9] max-[900px]:min-h-[100svh] max-[900px]:py-[42px] max-[900px]:px-[25px] max-[900px]:pb-[22px]"
        aria-label="Đăng nhập TechStoree"
      >
        <div className="hidden" aria-hidden="true">
          <span className="relative inline-block shrink-0 w-[27px] h-[27px] rounded bg-[#d52432]" />
          <span>TECHSTOREE</span>
        </div>
        <div className="w-full max-w-[420px] max-[900px]:pb-[75px]">
          {checkingSession ? (
            <div className="text-[#6c7077] text-sm" role="status">
              Đang kiểm tra phiên đăng nhập…
            </div>
          ) : user ? (
            <div>
              <p className="text-brand text-[10px] font-bold tracking-[0.13em]">
                ĐÃ ĐĂNG NHẬP
              </p>
              <h2 className="mt-3 text-[clamp(36px,3.1vw,50px)] font-[650] tracking-[-0.055em] leading-[1.14] text-[#17191c] max-[450px]:text-[42px]">
                Xin chào, {user.fullName || user.username}.
              </h2>
              <p className="my-6 mb-8 text-[#626771] text-[15px] leading-[1.7]">
                Bạn đã đăng nhập với tài khoản{" "}
                <strong className="text-[#17191c] font-[650]">{user.email}</strong>
                . Hồ sơ cá nhân và giỏ hàng của bạn đã sẵn sàng.
              </p>
              <div className="flex flex-col gap-2.5 mt-5">
                <Link
                  href="/"
                  className="flex w-full min-h-[56px] items-center justify-center gap-3 border border-[#17191c] rounded-[10px] py-3.5 px-[18px] bg-[#17191c] text-white cursor-pointer font-inherit text-sm font-bold no-underline text-center transition-[background,transform] duration-120 hover:bg-[#30343a] hover:-translate-y-px"
                >
                  Khám phá mua sắm ngay
                </Link>
                <Link
                  href="/profile"
                  className="flex w-full min-h-[56px] items-center justify-center gap-3 border border-[#333] rounded-[10px] py-3.5 px-[18px] bg-[#333] text-white cursor-pointer font-inherit text-sm font-bold no-underline text-center transition-[background,transform] duration-120 hover:bg-[#444] hover:-translate-y-px"
                >
                  Xem hồ sơ của tôi
                </Link>
                <button
                  className="border-0 p-0 bg-transparent text-[#9d2430] cursor-pointer font-inherit font-[650] underline underline-offset-[3px] hover:text-[#d52432] mt-2"
                  type="button"
                  onClick={() => void handleLogout()}
                  disabled={pending}
                >
                  {pending ? "Đang đăng xuất…" : "Đăng xuất tài khoản"}
                </button>
              </div>
            </div>
          ) : (
            <>
              <div>
                <p className="text-brand text-[11px] font-extrabold tracking-[0.1em]">
                  ĐĂNG NHẬP HỆ THỐNG
                </p>
                <h2 className="mt-3 text-[clamp(36px,3.1vw,50px)] font-[650] tracking-[-0.055em] leading-[1.14] text-[#17191c] max-[450px]:text-[42px]">
                  Chào mừng trở lại.
                </h2>
              </div>
              {error && (
                <div
                  className="mt-11 flex items-start gap-2.5 border border-[#eec4c1] bg-[#fff6f5] text-[#9d2525] rounded-[10px] py-3.5 px-4 text-[13px] leading-[1.55]"
                  role="alert"
                >
                  <span
                    className="grid shrink-0 w-[17px] h-[17px] place-items-center border border-current rounded-full text-[11px] font-extrabold"
                    aria-hidden="true"
                  >
                    !
                  </span>
                  <span>{error}</span>
                </div>
              )}
              {notice && (
                <div
                  className="mt-11 border border-[#cbd5fa] bg-[#f2f5ff] text-[#1d377f] rounded-[10px] py-3.5 px-4 text-[13px] leading-[1.55]"
                  role="status"
                >
                  {notice}
                </div>
              )}
              <form className="mt-11" onSubmit={handleSubmit} noValidate>
                <div>
                  <div className="flex justify-between gap-3 mb-2.5 text-[11px] font-bold tracking-[0.13em] text-[#17191c]">
                    <label htmlFor="email">ĐỊA CHỈ EMAIL</label>
                  </div>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    autoComplete="email"
                    inputMode="email"
                    placeholder="tenban@example.com"
                    value={email}
                    onChange={(event) => {
                      setEmail(event.target.value);
                      setEmailError("");
                    }}
                    aria-invalid={Boolean(emailError)}
                    aria-describedby={emailError ? "email-error" : undefined}
                    className={cn(
                      "w-full h-[54px] border rounded-[10px] px-4 outline-none bg-white text-[#17191c] font-inherit text-sm transition-[border-color,box-shadow] duration-120 placeholder:text-[#979ca4] focus-visible:border-brand focus-visible:ring-3 focus-visible:ring-brand/12",
                      emailError ? "border-[#c43131]" : "border-[#d6d9df]"
                    )}
                    required
                  />
                  {emailError && (
                    <p className="mt-2 text-[#ad2626] text-xs" id="email-error">
                      {emailError}
                    </p>
                  )}
                </div>

                <div className="mt-6">
                  <div className="flex justify-between gap-3 mb-2.5 text-[11px] font-bold tracking-[0.13em] text-[#17191c]">
                    <label htmlFor="password">MẬT KHẨU</label>
                  </div>
                  <div className="relative [&>input]:!pr-[72px]">
                    <input
                      id="password"
                      name="password"
                      type={showPassword ? "text" : "password"}
                      autoComplete="current-password"
                      placeholder="Nhập mật khẩu"
                      value={password}
                      onChange={(event) => {
                        setPassword(event.target.value);
                        setPasswordError("");
                      }}
                      aria-invalid={Boolean(passwordError)}
                      aria-describedby={
                        passwordError ? "password-error" : undefined
                      }
                      className={cn(
                        "w-full h-[54px] border rounded-[10px] px-4 outline-none bg-white text-[#17191c] font-inherit text-sm transition-[border-color,box-shadow] duration-120 placeholder:text-[#979ca4] focus-visible:border-brand focus-visible:ring-3 focus-visible:ring-brand/12",
                        passwordError ? "border-[#c43131]" : "border-[#d6d9df]"
                      )}
                      required
                    />
                    <button
                      className="absolute top-[5px] right-[5px] grid w-11 h-11 place-items-center border-0 rounded-lg p-0 bg-transparent text-[#5a606a] cursor-pointer hover:bg-[#f7edef] hover:text-brand focus-visible:outline focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-1"
                      type="button"
                      onClick={() => setShowPassword((shown) => !shown)}
                      aria-label={
                        showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"
                      }
                      aria-pressed={showPassword}
                      aria-controls="password"
                    >
                      <PasswordVisibilityIcon visible={showPassword} />
                    </button>
                  </div>
                  {passwordError && (
                    <p
                      className="mt-2 text-[#ad2626] text-xs"
                      id="password-error"
                    >
                      {passwordError}
                    </p>
                  )}
                </div>

                <div className="flex items-center justify-between gap-4 my-[19px] mb-8 text-[13px] max-[450px]:flex-wrap">
                  <label className="inline-flex items-center gap-[9px] text-[#565b63] cursor-pointer [&>input]:w-[15px] [&>input]:h-[15px] [&>input]:m-0 [&>input]:accent-brand">
                    <input
                      type="checkbox"
                      checked={remember}
                      onChange={(event) => setRemember(event.target.checked)}
                    />
                    <span>Duy trì đăng nhập</span>
                  </label>
                  <button
                    type="button"
                    className="border-0 p-0 bg-transparent text-[#9d2430] cursor-pointer font-inherit font-[650] underline underline-offset-[3px] hover:text-[#d52432]"
                    onClick={() => {
                      setError("");
                      setNotice(
                        "Vui lòng liên hệ quản trị viên để hỗ trợ khôi phục mật khẩu.",
                      );
                    }}
                  >
                    Quên mật khẩu?
                  </button>
                </div>

                <button
                  className="flex w-full min-h-[56px] items-center justify-center gap-3 border border-[#17191c] rounded-[10px] py-3.5 px-[18px] bg-[#17191c] text-white cursor-pointer font-inherit text-sm font-bold no-underline transition-[background,transform] duration-120 hover:enabled:bg-[#30343a] hover:enabled:-translate-y-px disabled:cursor-wait disabled:opacity-70"
                  type="submit"
                  disabled={pending}
                >
                  <span>{pending ? "Đang đăng nhập…" : "Đăng nhập"}</span>
                </button>
              </form>

              <div className="flex justify-center gap-[7px] mt-[22px] text-[#7a7e84] text-[13px] max-[450px]:flex-wrap">
                <span>Chưa có tài khoản?</span>
                <Link
                  href="/register"
                  className="border-0 p-0 bg-transparent text-[#9d2430] cursor-pointer font-inherit font-[650] underline underline-offset-[3px] hover:text-[#d52432]"
                >
                  Tạo tài khoản mới
                </Link>
              </div>
            </>
          )}
        </div>
      </section>
    </main>
  );
}
