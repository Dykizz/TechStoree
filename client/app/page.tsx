"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import ProductCard from "../components/products/ProductCard";
import { fetchCategories, fetchProducts } from "../lib/products-client";
import { CategoryDto, ProductBaseDto } from "../lib/types/product";
import styles from "./storefront.module.css";

export default function HomePage() {
  const [featuredProducts, setFeaturedProducts] = useState<ProductBaseDto[]>([]);
  const [saleProducts, setSaleProducts] = useState<ProductBaseDto[]>([]);
  const [categories, setCategories] = useState<CategoryDto[]>([]);
  const [loading, setLoading] = useState(true);

  // Countdown timer for Flash Sale demo
  const [timeLeft, setTimeLeft] = useState({ hours: 14, minutes: 28, seconds: 45 });

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev.seconds > 0) return { ...prev, seconds: prev.seconds - 1 };
        if (prev.minutes > 0) return { ...prev, minutes: prev.minutes - 1, seconds: 59 };
        if (prev.hours > 0) return { ...prev, hours: prev.hours - 1, minutes: 59, seconds: 59 };
        return { hours: 24, minutes: 0, seconds: 0 };
      });
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    async function loadData() {
      try {
        setLoading(true);
        const [cats, productsRes] = await Promise.all([
          fetchCategories(),
          fetchProducts({ page: 1, pageSize: 8 }),
        ]);
        setCategories(cats);
        setFeaturedProducts(productsRes.items);
        setSaleProducts(productsRes.items.filter((p) => p.hasPromotion || p.promotion?.hasPromotion));
      } finally {
        setLoading(false);
      }
    }
    void loadData();
  }, []);

  const categoryIcons: Record<string, string> = {
    "Laptop & Máy tính": "💻",
    "Điện thoại & Tablet": "📱",
    "Đồng hồ thông minh": "⌚",
    "Phụ kiện cao cấp": "🎧",
  };

  return (
    <main className={styles.main}>
      {/* ================= HERO SECTION ================= */}
      <section className={styles.hero}>
        <div className={styles.container}>
          <div className={styles.heroContent}>
            <div>
              <div className={styles.heroBadge}>
                <span className={styles.heroBadgeDot} />
                BỘ SƯU TẬP CÔNG NGHỆ 2026
              </div>
              <h1 className={styles.heroTitle}>
                Đỉnh Cao Thiết Kế, <br />
                <span className={styles.heroTitleGradient}>Định Hình Tương Lai.</span>
              </h1>
              <p className={styles.heroSubtitle}>
                Khám phá hệ sinh thái thiết bị công nghệ nguyên bản và tinh tuyển. Tối giản trong trải nghiệm, mãnh liệt trong hiệu năng.
              </p>
              <div className={styles.heroActions}>
                <Link href="/products" className={styles.btnPrimary}>
                  Khám phá sản phẩm
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M5 12h14" />
                    <path d="m12 5 7 7-7 7" />
                  </svg>
                </Link>
                <Link href="/products?onSale=true" className={styles.btnSecondary}>
                  Ưu đãi Flash Sale 🔥
                </Link>
              </div>
            </div>

            <div className={styles.heroVisual}>
              <div className={styles.heroCard}>
                <div className={styles.heroImageWrap}>
                  <Image
                    src="/images/editorial-laptop.png"
                    alt="TechStoree StudioBook Pro 16"
                    fill
                    style={{ objectFit: "contain" }}
                    priority
                  />
                </div>
                <div className={styles.heroCardMeta}>
                  <div>
                    <p className={styles.heroCardTag}>Sản phẩm tiêu biểu</p>
                    <h3 className={styles.heroCardTitle}>StudioBook Pro 16</h3>
                    <p style={{ color: "#94a3b8", fontSize: "0.85rem" }}>Liquid Retina XDR, M-Pro Max</p>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <span className={styles.heroCardPrice}>33.141.500₫</span>
                    <div>
                      <span className={styles.heroCardPriceOld}>38.990.000₫</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ================= VALUE PROPOSITIONS ================= */}
      <section className={styles.valueSection}>
        <div className={styles.container}>
          <div className={styles.valueGrid}>
            <div className={styles.valueItem}>
              <div className={styles.valueIcon}>🛡️</div>
              <div>
                <h4>Chính Hãng 100%</h4>
                <p>Bảo hành chính hãng 12-24 tháng</p>
              </div>
            </div>
            <div className={styles.valueItem}>
              <div className={styles.valueIcon}>🚀</div>
              <div>
                <h4>Giao Hỏa Tốc 2H</h4>
                <p>Nội thành miễn phí cho đơn từ 1 triệu</p>
              </div>
            </div>
            <div className={styles.valueItem}>
              <div className={styles.valueIcon}>🔄</div>
              <div>
                <h4>30 Ngày Đổi Mới</h4>
                <p>Lỗi phần cứng là đổi, không chờ đợi</p>
              </div>
            </div>
            <div className={styles.valueItem}>
              <div className={styles.valueIcon}>💳</div>
              <div>
                <h4>Thanh Toán Linh Hoạt</h4>
                <p>VietQR, Thẻ quốc tế, COD an toàn</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ================= FLASH SALE BANNER ================= */}
      <section className={styles.section} style={{ paddingBottom: 0 }}>
        <div className={styles.container}>
          <div className={styles.saleBanner}>
            <div>
              <span className={styles.saleTag}>Ưu Đãi Giới Hạn</span>
              <h2 className={styles.saleTitle}>Flash Sale Công Nghệ Siêu Phẩm</h2>
              <p className={styles.saleDesc}>
                Giảm tới 15% cho dòng laptop StudioBook và điện thoại flagship. Cơ hội sở hữu các thiết bị đỉnh cao với mức giá tốt nhất trong năm.
              </p>
              <div className={styles.countdownWrap}>
                <div className={styles.countdownBox}>
                  <span className={styles.countdownNum}>{String(timeLeft.hours).padStart(2, "0")}</span>
                  <span className={styles.countdownLabel}>Giờ</span>
                </div>
                <div className={styles.countdownBox}>
                  <span className={styles.countdownNum}>{String(timeLeft.minutes).padStart(2, "0")}</span>
                  <span className={styles.countdownLabel}>Phút</span>
                </div>
                <div className={styles.countdownBox}>
                  <span className={styles.countdownNum}>{String(timeLeft.seconds).padStart(2, "0")}</span>
                  <span className={styles.countdownLabel}>Giây</span>
                </div>
              </div>
              <Link href="/products?onSale=true" className={styles.btnPrimary} style={{ background: "#f43f5e", color: "#fff" }}>
                Săn Deal Ngay
              </Link>
            </div>

            <div>
              {saleProducts.length > 0 ? (
                <ProductCard product={saleProducts[0]} />
              ) : (
                <div style={{ color: "#9ca3af", textAlign: "center", padding: "40px" }}>Đang cập nhật các deal hot...</div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* ================= CATEGORIES SECTION ================= */}
      <section className={styles.section}>
        <div className={styles.container}>
          <div className={styles.sectionHeader}>
            <div className={styles.sectionTitleWrap}>
              <p>HỆ SINH THÁI</p>
              <h2 className={styles.sectionTitle}>Danh Mục Sản Phẩm</h2>
            </div>
            <Link href="/products" className={styles.viewAllLink}>
              Xem tất cả danh mục →
            </Link>
          </div>

          <div className={styles.categoryGrid}>
            {categories.map((cat) => (
              <Link
                key={cat.categoryId}
                href={`/products?category=${cat.categoryId}`}
                className={styles.categoryCard}
              >
                <div>
                  <div className={styles.catIcon}>
                    {categoryIcons[cat.categoryName] || "✨"}
                  </div>
                  <h3 className={styles.catName}>{cat.categoryName}</h3>
                  <p className={styles.catDesc}>Thiết bị cao cấp chuẩn studio</p>
                </div>
                <span style={{ fontSize: "0.85rem", color: "#60a5fa", fontWeight: 600 }}>
                  Khám phá ngay →
                </span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* ================= FEATURED PRODUCTS ================= */}
      <section className={styles.section} style={{ backgroundColor: "#0e1017" }}>
        <div className={styles.container}>
          <div className={styles.sectionHeader}>
            <div className={styles.sectionTitleWrap}>
              <p>TUYỂN CHỌN ĐẶC BIỆT</p>
              <h2 className={styles.sectionTitle}>Sản Phẩm Nổi Bật</h2>
            </div>
            <Link href="/products" className={styles.viewAllLink}>
              Xem toàn bộ ({featuredProducts.length}) →
            </Link>
          </div>

          {loading ? (
            <div style={{ textAlign: "center", padding: "80px 0", color: "#9ca3af" }}>
              Đang tải danh sách thiết bị công nghệ…
            </div>
          ) : (
            <div className={styles.productGrid}>
              {featuredProducts.slice(0, 6).map((product) => (
                <ProductCard key={product.productId} product={product} />
              ))}
            </div>
          )}
        </div>
      </section>
    </main>
  );
}
