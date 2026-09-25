import type { Metadata } from "next";
import AuthStory from "../components/auth-story";
import RegisterForm from "./register-form";
import styles from "../page.module.css";

export const metadata: Metadata = {
  title: "Tạo tài khoản | TechStoree",
  description: "Tạo tài khoản khách hàng TechStoree.",
};

export default function RegisterPage() {
  return (
    <main className={styles.page}>
      <AuthStory />
      <section className={styles.authPanel} aria-label="Đăng ký TechStoree">
        <div className={styles.mobileBrand} aria-hidden="true">
          <span className={styles.brandMark} /><span>TECHSTOREE</span>
        </div>
        <div className={styles.authContent}>
          <RegisterForm />
        </div>
      </section>
    </main>
  );
}
