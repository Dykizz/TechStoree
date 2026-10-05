"use client";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import ProductCard from "../components/products/ProductCard";
import { fetchCategories, fetchProducts } from "../lib/products-client";
import type { CategoryDto, ProductBaseDto } from "../lib/types/product";
import styles from "./storefront.module.css";

export default function HomePage() {
  const [products, setProducts] = useState<ProductBaseDto[]>([]);
  const [sales, setSales] = useState<ProductBaseDto[]>([]);
  const [categories, setCategories] = useState<CategoryDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);
  useEffect(() => {
    let active = true;
    async function load() {
      setLoading(true);
      setError("");
      try {
        const [cats, featured, offers] = await Promise.all([
          fetchCategories(),
          fetchProducts({ pageSize: 8 }),
          fetchProducts({ pageSize: 4, onSale: true }),
        ]);
        if (active) {
          setCategories(cats);
          setProducts(featured.items);
          setSales(offers.items);
        }
      } catch {
        if (active)
          setError(
            "Chưa thể tải sản phẩm. Vui lòng kiểm tra kết nối hoặc thử lại.",
          );
      } finally {
        if (active) setLoading(false);
      }
    }
    void load();
    return () => {
      active = false;
    };
  }, [attempt]);
  const featured = products.find((p) => p.imageUrl && p.totalStock > 0);
  return (
    <main className={styles.main}>
      <section className={styles.hero}>
        <div className={styles.container}>
          <div className={styles.heroContent}>
            <div className={styles.heroCopy}>
              <p className={styles.eyebrow}>
                TECHSTOREE · CÔNG NGHỆ CHO MỖI NGÀY
              </p>
              <h1>
                Nguyên bản.
                <br />
                <span>Tinh tế trong từng lựa chọn.</span>
              </h1>
              <p className={styles.subtitle}>
                Khám phá thiết bị phù hợp với cách bạn làm việc, sáng tạo và tận
                hưởng cuộc sống.
              </p>
              <div className={styles.heroActions}>
                <Link href="/products" className={styles.primaryButton}>
                  Khám phá sản phẩm ↗
                </Link>
                <Link href="/products?onSale=true" className={styles.textLink}>
                  Xem ưu đãi hiện có →
                </Link>
              </div>
            </div>
            <Link
              href={featured ? `/products/${featured.productId}` : "/products"}
              className={styles.heroVisual}
            >
              <div className={styles.heroImage}>
                <Image
                  src={featured?.imageUrl || "/images/editorial-laptop.png"}
                  alt={featured?.productName || "Thiết kế thiết bị công nghệ"}
                  fill
                  sizes="(max-width: 760px) 90vw, 45vw"
                  priority
                />
              </div>
              <div className={styles.heroCaption}>
                <span>
                  {featured ? featured.categoryName : "DESIGN / TECHNOLOGY"}
                </span>
                <strong>
                  {featured?.productName || "Ít hơn. Nhưng tốt hơn."}
                </strong>
                <span aria-hidden="true">↗</span>
              </div>
            </Link>
          </div>
        </div>
      </section>
      <section className={styles.benefits} aria-label="Trải nghiệm mua sắm">
        <div className={styles.container}>
          <div className={styles.benefitGrid}>
            <div>
              <span>01 / KHÁM PHÁ</span>
              <p>Chọn phiên bản phù hợp</p>
            </div>
            <div>
              <span>02 / MINH BẠCH</span>
              <p>Giá & tồn kho từ hệ thống</p>
            </div>
            <div>
              <span>03 / CÁ NHÂN</span>
              <p>Hồ sơ và đơn hàng của bạn</p>
            </div>
          </div>
        </div>
      </section>
      <section className={styles.section}>
        <div className={styles.container}>
          <div className={styles.sectionHeading}>
            <div>
              <p className={styles.eyebrow}>KHÁM PHÁ THEO NHU CẦU</p>
              <h2>Không gian công nghệ.</h2>
            </div>
            <Link href="/products" className={styles.textLink}>
              Tất cả sản phẩm →
            </Link>
          </div>
          <div className={styles.categories}>
            {categories.map((cat, i) => (
              <Link
                key={cat.categoryId}
                href={`/products?category=${cat.categoryId}`}
              >
                <span>{String(i + 1).padStart(2, "0")}</span>
                <strong>{cat.categoryName}</strong>
                <span aria-hidden="true">↗</span>
              </Link>
            ))}
          </div>
          {loading ? (
            <p className={styles.state} role="status">
              Đang tải sản phẩm…
            </p>
          ) : error ? (
            <div className={styles.state} role="alert">
              <p>{error}</p>
              <button
                className={styles.primaryButton}
                onClick={() => setAttempt((a) => a + 1)}
              >
                Thử lại
              </button>
            </div>
          ) : (
            <>
              <div className={styles.sectionHeading}>
                <h2>Những lựa chọn nổi bật.</h2>
              </div>
              <div className={styles.productGrid}>
                {products.map((product) => (
                  <ProductCard key={product.productId} product={product} />
                ))}
              </div>
              {!products.length && (
                <p className={styles.state}>
                  Cửa hàng chưa có sản phẩm. Hãy quay lại sau.
                </p>
              )}
            </>
          )}
        </div>
      </section>
      {!error && sales.length > 0 && (
        <section className={`${styles.section} ${styles.saleSection}`}>
          <div className={styles.container}>
            <div className={styles.sectionHeading}>
              <div>
                <p className={styles.eyebrow}>ƯU ĐÃI ĐANG DIỄN RA</p>
                <h2>Thêm giá trị cho lựa chọn.</h2>
              </div>
              <Link href="/products?onSale=true" className={styles.textLink}>
                Xem ưu đãi →
              </Link>
            </div>
            <div className={styles.productGrid}>
              {sales.map((product) => (
                <ProductCard key={product.productId} product={product} />
              ))}
            </div>
          </div>
        </section>
      )}
    </main>
  );
}
