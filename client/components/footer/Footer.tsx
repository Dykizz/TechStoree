import Link from "next/link";
import styles from "./Footer.module.css";
export default function Footer() {
  return (
    <footer className={styles.footer}>
      <div className={styles.container}>
        <div className={styles.grid}>
          <div className={styles.colBrand}>
            <Link href="/" className={styles.brand}>
              <span className={styles.brandMark} aria-hidden="true" />
              <span>TECHSTOREE</span>
            </Link>
            <p className={styles.description}>
              Thiết bị công nghệ. Lựa chọn tinh tế.
              <br />
              Một trải nghiệm giản đơn, dành cho bạn.
            </p>
          </div>
          <div>
            <h2 className={styles.colTitle}>Khám phá</h2>
            <ul className={styles.linkList}>
              <li>
                <Link href="/products">Tất cả sản phẩm</Link>
              </li>
              <li>
                <Link href="/products?onSale=true">Ưu đãi đang diễn ra</Link>
              </li>
              <li>
                <Link href="/cart">Giỏ hàng</Link>
              </li>
            </ul>
          </div>
          <div>
            <h2 className={styles.colTitle}>Tài khoản của bạn</h2>
            <ul className={styles.linkList}>
              <li>
                <Link href="/profile">Hồ sơ cá nhân</Link>
              </li>
              <li>
                <Link href="/orders">Lịch sử đơn hàng</Link>
              </li>
              <li>
                <Link href="/surveys">Khảo sát của tôi</Link>
              </li>
            </ul>
          </div>
        </div>
        <div className={styles.bottom}>
          <p>© {new Date().getFullYear()} TechStoree · Dự án học tập</p>
          <p>Thông tin giá và đơn hàng được xác nhận bởi hệ thống.</p>
        </div>
      </div>
    </footer>
  );
}
