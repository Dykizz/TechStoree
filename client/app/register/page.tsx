import type { Metadata } from "next";
import AuthStory from "@/components/auth/auth-story";
import RegisterForm from "./register-form";

export const metadata: Metadata = {
  title: "Tạo tài khoản | TechStoree",
  description: "Tạo tài khoản khách hàng TechStoree.",
};

export default function RegisterPage() {
  return (
    <main className="grid grid-cols-[minmax(0,52%)_minmax(0,48%)] min-h-[100svh] text-[#17191c] max-[1100px]:grid-cols-[minmax(0,48%)_minmax(0,52%)] max-[900px]:grid-cols-1">
      <AuthStory />
      <section
        className="relative flex min-w-0 flex-col items-center justify-start pt-[clamp(82px,13vh,140px)] px-[clamp(30px,5vw,90px)] pb-10 bg-[#fafaf9] max-[900px]:min-h-[100svh] max-[900px]:py-[42px] max-[900px]:px-[25px] max-[900px]:pb-[22px]"
        aria-label="Đăng ký TechStoree"
      >
        <div className="hidden" aria-hidden="true">
          <span className="relative inline-block shrink-0 w-[27px] h-[27px] rounded bg-[#d52432]" />
          <span>TECHSTOREE</span>
        </div>
        <div className="w-full max-w-[420px] max-[900px]:pb-[75px]">
          <RegisterForm />
        </div>
      </section>
    </main>
  );
}
