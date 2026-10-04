import Link from "next/link";
import styles from "./Footer.module.css";

export default function Footer() {
  return (
    <footer className={styles.footer}>
      <div className={styles.container}>
        <div className={styles.grid}>
          {/* Brand Info */}
          <div className={styles.colBrand}>
            <div className={styles.brand}>
              <span className={styles.brandMark}>T</span>
              <span>TECHSTOREE</span>
            </div>
            <p className={styles.description}>
              Hệ thống bán lẻ thiết bị công nghệ chính hãng hàng đầu. Trải nghiệm không gian mua sắm tinh tế, dịch vụ bảo hành tiêu chuẩn và hậu mãi tận tâm.
            </p>
            <div className={styles.contactInfo}>
              <p>📍 123 Đường Công Nghệ, Quận 1, TP. Hồ Chí Minh</p>
              <p>📞 Hotline: 1800 6868 (Miễn phí, 8:00 - 21:30)</p>
              <p>✉️ Email: support@techstoree.vn</p>
            </div>
          </div>

          {/* Quick Links */}
          <div className={styles.col}>
            <h4 className={styles.colTitle}>Khám phá</h4>
            <ul className={styles.linkList}>
              <li><Link href="/products?category=1">Laptop & Máy tính</Link></li>
              <li><Link href="/products?category=2">Điện thoại & Tablet</Link></li>
              <li><Link href="/products?category=3">Đồng hồ thông minh</Link></li>
              <li><Link href="/products?category=4">Phụ kiện công nghệ cao cấp</Link></li>
              <li><Link href="/products?onSale=true">Chương trình khuyến mãi hot</Link></li>
            </ul>
          </div>

          {/* Customer Support */}
          <div className={styles.col}>
            <h4 className={styles.colTitle}>Hỗ trợ khách hàng</h4>
            <ul className={styles.linkList}>
              <li><Link href="/orders">Tra cứu tình trạng đơn hàng</Link></li>
              <li><Link href="/profile">Quản lý tài khoản cá nhân</Link></li>
              <li><Link href="/cart">Giỏ hàng của bạn</Link></li>
              <li><a href="#policy">Chính sách bảo hành 1 đổi 1</a></li>
              <li><a href="#delivery">Phương thức giao hàng hỏa tốc</a></li>
            </ul>
          </div>

          {/* Payments & Certification */}
          <div className={styles.col}>
            <h4 className={styles.colTitle}>Thanh toán an toàn</h4>
            <div className={styles.badgeGrid}>
              <span className={styles.paymentBadge}>COD Tiền mặt</span>
              <span className={styles.paymentBadge}>Chuyển khoản VietQR</span>
              <span className={styles.paymentBadge}>Thẻ Visa / MasterCard</span>
              <span className={styles.paymentBadge}>Ví điện tử MoMo/VNPAY</span>
            </div>
            <h4 className={styles.colTitle} style={{ marginTop: "20px" }}>Đảm bảo chất lượng</h4>
            <p className={styles.smallNote}>
              ✓ 100% Sản phẩm chính hãng phân phối chính thức.<br />
              ✓ Đổi trả miễn phí trong 30 ngày nếu phát sinh lỗi phần cứng.
            </p>
          </div>
        </div>

        <div className={styles.bottom}>
          <p>© {new Date().getFullYear()} TechStoree Co., Ltd. Tất cả quyền được bảo lưu.</p>
          <div className={styles.bottomLinks}>
            <a href="#terms">Điều khoản sử dụng</a>
            <span>•</span>
            <a href="#privacy">Chính sách bảo mật</a>
            <span>•</span>
            <a href="#contact">Liên hệ hợp tác</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
