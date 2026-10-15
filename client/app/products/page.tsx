"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import PriceFilterDropdown from "../../components/products/PriceFilterDropdown";
import ProductCard from "../../components/products/ProductCard";
import {
  fetchCategories,
  fetchProducts,
  formatPrice,
} from "../../lib/products-client";
import { CategoryDto, ProductBaseDto } from "../../lib/types/product";
import styles from "./products.module.css";

function ProductsContent() {
  const query = useSearchParams();
  const initialCategory = Number(query.get("category"));
  const [products, setProducts] = useState<ProductBaseDto[]>([]);
  const [categories, setCategories] = useState<CategoryDto[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<number | null>(
    Number.isSafeInteger(initialCategory) && initialCategory > 0
      ? initialCategory
      : null,
  );
  const [onSaleOnly, setOnSaleOnly] = useState(query.get("onSale") === "true");
  const [search, setSearch] = useState("");
  const [sortBy, setSortBy] = useState("newest");
  const [minPrice, setMinPrice] = useState<number | undefined>(undefined);
  const [maxPrice, setMaxPrice] = useState<number | undefined>(undefined);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [loading, setLoading] = useState(true);

  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);

  // Load categories on mount
  useEffect(() => {
    async function loadCats() {
      try {
        const cats = await fetchCategories();
        setCategories(cats);
      } catch {
        /* Product request shows the retry state. */
      }
    }
    void loadCats();
  }, []);

  // Load products whenever filters change
  useEffect(() => {
    let active = true;
    async function loadData() {
      setLoading(true);
      const isAsc = sortBy === "price-asc";
      const sortField = sortBy.startsWith("price") ? "price" : "createdAt";

      setError("");
      try {
        const res = await fetchProducts({
          page,
          pageSize: 9,
          search: search.trim() || undefined,
          categoryId: selectedCategory || undefined,
          minPrice,
          maxPrice,
          sortBy: sortField,
          isAscending: isAsc,
          onSale: onSaleOnly || undefined,
        });

        if (active) {
          setProducts(res.items);
          setTotalPages(res.meta.totalPages);
          setTotalItems(res.meta.totalItems);
          setLoading(false);
        }
      } catch {
        if (active) {
          setError("Không thể tải sản phẩm từ máy chủ.");
          setLoading(false);
        }
      }
    }

    void loadData();
    return () => {
      active = false;
    };
  }, [
    selectedCategory,
    search,
    sortBy,
    page,
    onSaleOnly,
    minPrice,
    maxPrice,
    attempt,
  ]);

  const handlePriceChange = (min?: number, max?: number) => {
    setMinPrice(min);
    setMaxPrice(max);
    setPage(1);
  };

  const handleResetFilters = () => {
    setSelectedCategory(null);
    setOnSaleOnly(false);
    setSearch("");
    setMinPrice(undefined);
    setMaxPrice(undefined);
    setSortBy("newest");
    setPage(1);
  };

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <div className={styles.hero}>
          <p className={styles.heroSubtitle}>BỘ SƯU TẬP 2026</p>
          <h1 className={styles.heroTitle}>Sản Phẩm Công Nghệ Tinh Tuyển</h1>
          <p className={styles.heroDescription}>
            Trải nghiệm các thiết bị công nghệ đẳng cấp được thiết kế tinh tế,
            hiệu năng mạnh mẽ và đón đầu xu hướng tương lai.
          </p>
        </div>

        <section className={styles.toolbar} aria-label="Bộ lọc sản phẩm">
          <div className={styles.topFilters}>
            <div className={styles.searchWrap}>
              <svg
                className={styles.searchIcon}
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="11" cy="11" r="8" />
                <path d="m21 21-4.3-4.3" />
              </svg>
              <input
                type="text"
                className={styles.searchInput}
                aria-label="Tìm kiếm sản phẩm"
                placeholder="Tìm kiếm máy tính, điện thoại, phụ kiện..."
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
              />
            </div>

            <div className={styles.filterControls}>
              <PriceFilterDropdown
                key={`${minPrice}-${maxPrice}`}
                minPrice={minPrice}
                maxPrice={maxPrice}
                onChange={handlePriceChange}
              />

              <select
                className={styles.sortSelect}
                value={sortBy}
                onChange={(e) => {
                  setSortBy(e.target.value);
                  setPage(1);
                }}
                aria-label="Sắp xếp sản phẩm"
              >
                <option value="newest">Mới nhất</option>
                <option value="price-asc">Giá: Thấp đến cao</option>
                <option value="price-desc">Giá: Cao đến thấp</option>
              </select>
            </div>
          </div>

          <div className={styles.categoryPills} aria-label="Danh mục">
            <button
              type="button"
              className={`${styles.salePill} ${onSaleOnly ? styles.salePillActive : ""}`}
              onClick={() => {
                setOnSaleOnly((prev) => !prev);
                setPage(1);
              }}
              title="Chỉ hiển thị các sản phẩm đang có chương trình giảm giá"
            >
              🔥 Đang khuyến mãi
            </button>
            <button
              type="button"
              className={`${styles.categoryPill} ${
                selectedCategory === null && !onSaleOnly
                  ? styles.categoryPillActive
                  : ""
              }`}
              onClick={() => {
                setSelectedCategory(null);
                setOnSaleOnly(false);
                setPage(1);
              }}
            >
              Tất cả danh mục ({totalItems})
            </button>
            {categories.map((cat) => (
              <button
                key={cat.categoryId}
                type="button"
                className={`${styles.categoryPill} ${
                  selectedCategory === cat.categoryId
                    ? styles.categoryPillActive
                    : ""
                }`}
                onClick={() => {
                  setSelectedCategory(cat.categoryId);
                  setPage(1);
                }}
              >
                {cat.categoryName}
              </button>
            ))}
          </div>

          {(minPrice !== undefined || maxPrice !== undefined) && (
            <div className={styles.activeFilterRow}>
              <span className={styles.activeFilterLabel}>Đang lọc giá:</span>
              <span className={styles.activePriceBadge}>
                💰{" "}
                {minPrice !== undefined && maxPrice !== undefined
                  ? `${formatPrice(minPrice)} — ${formatPrice(maxPrice)}`
                  : minPrice !== undefined
                    ? `Từ ${formatPrice(minPrice)} trở lên`
                    : `Đến ${formatPrice(maxPrice!)}`}
                <button
                  type="button"
                  className={styles.removeFilterBtn}
                  onClick={() => handlePriceChange(undefined, undefined)}
                  title="Xóa lọc giá"
                  aria-label="Xóa lọc giá"
                >
                  ✕
                </button>
              </span>
              <button
                type="button"
                className={styles.clearAllBtn}
                onClick={() => handlePriceChange(undefined, undefined)}
              >
                Xóa bộ lọc giá
              </button>
            </div>
          )}
        </section>

        {error ? (
          <div className={styles.empty} role="alert">
            <p>{error}</p>
            <button
              className={styles.resetBtn}
              onClick={() => setAttempt((a) => a + 1)}
            >
              Thử lại
            </button>
          </div>
        ) : loading ? (
          <div className={styles.loading}>Đang tải danh sách sản phẩm…</div>
        ) : products.length === 0 ? (
          <div className={styles.empty}>
            <h3>Không tìm thấy sản phẩm phù hợp</h3>
            <p>
              Hãy thử thay đổi từ khóa tìm kiếm hoặc bỏ chọn danh mục hiện tại.
            </p>
            <button
              type="button"
              className={styles.resetBtn}
              onClick={handleResetFilters}
            >
              Xóa bộ lọc
            </button>
          </div>
        ) : (
          <>
            <div className={styles.grid}>
              {products.map((product) => (
                <ProductCard key={product.productId} product={product} />
              ))}
            </div>

            {totalPages > 1 && (
              <div className={styles.pagination}>
                <button
                  type="button"
                  className={styles.pageBtn}
                  disabled={page <= 1}
                  onClick={() => setPage((p) => Math.max(p - 1, 1))}
                >
                  &larr; Trang trước
                </button>
                <span className={styles.pageInfo}>
                  Trang {page} / {totalPages}
                </span>
                <button
                  type="button"
                  className={styles.pageBtn}
                  disabled={page >= totalPages}
                  onClick={() => setPage((p) => Math.min(p + 1, totalPages))}
                >
                  Trang sau &rarr;
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </main>
  );
}
function CatalogBoundary() {
  const query = useSearchParams();
  return <ProductsContent key={query.toString()} />;
}
export default function ProductsPage() {
  return (
    <Suspense fallback={<p role="status">Đang tải sản phẩm…</p>}>
      <CatalogBoundary />
    </Suspense>
  );
}
