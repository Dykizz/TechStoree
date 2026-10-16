"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import PriceFilterDropdown from "../../components/products/PriceFilterDropdown";
import ProductCard from "../../components/products/ProductCard";
import ProductsHeroBanner from "../../components/products/ProductsHeroBanner";
import SearchBar from "../../components/search/SearchBar";
import {
  fetchCategories,
  fetchProducts,
  formatPrice,
} from "../../lib/products-client";
import { executeSearch } from "../../lib/search/search-engine";
import { CategoryDto, ProductBaseDto } from "../../lib/types/product";
import styles from "./products.module.css";

interface SearchTypoInfo {
  hasTypo: boolean;
  originalQuery: string;
  effectiveQuery: string;
}

function ProductsContent() {
  const query = useSearchParams();
  const initialCategory = Number(query.get("category"));
  const initialSearch = query.get("search") || "";

  const [products, setProducts] = useState<ProductBaseDto[]>([]);
  const [catalogProducts, setCatalogProducts] = useState<ProductBaseDto[]>([]);
  const [categories, setCategories] = useState<CategoryDto[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<number | null>(
    Number.isSafeInteger(initialCategory) && initialCategory > 0
      ? initialCategory
      : null,
  );
  const [onSaleOnly, setOnSaleOnly] = useState(query.get("onSale") === "true");
  const [search, setSearch] = useState(initialSearch);
  const [sortBy, setSortBy] = useState(initialSearch ? "relevance" : "newest");
  const [minPrice, setMinPrice] = useState<number | undefined>(undefined);
  const [maxPrice, setMaxPrice] = useState<number | undefined>(undefined);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [loading, setLoading] = useState(true);
  const [searchInfo, setSearchInfo] = useState<SearchTypoInfo | null>(null);

  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);

  // 1. Tải danh mục và toàn bộ kho sản phẩm để phục vụ Search Engine in-memory
  useEffect(() => {
    async function loadInitialData() {
      try {
        const [cats, catalogRes] = await Promise.all([
          fetchCategories(),
          fetchProducts({ pageSize: 100 }),
        ]);
        setCategories(cats);
        setCatalogProducts(catalogRes.items);
      } catch {
        /* Lỗi sẽ được hiển thị khi tải danh sách chính */
      }
    }
    void loadInitialData();
  }, []);

  // 2. Lọc và xếp hạng sản phẩm (Kết hợp Okapi BM25 + Faceted Search)
  useEffect(() => {
    let active = true;

    async function processProducts() {
      setLoading(true);
      setError("");

      const trimmedSearch = search.trim();

      // TRƯỜNG HỢP A: CÓ TỪ KHÓA TÌM KIẾM -> DÙNG SEARCH ENGINE (BM25 + TYPO + SYNONYMS)
      if (trimmedSearch.length > 0 && catalogProducts.length > 0) {
        try {
          const searchRes = executeSearch(trimmedSearch, catalogProducts);

          if (searchRes.hasTypo) {
            setSearchInfo({
              hasTypo: true,
              originalQuery: searchRes.originalQuery,
              effectiveQuery: searchRes.effectiveQuery,
            });
          } else {
            setSearchInfo(null);
          }

          // Áp dụng Faceted Search kết hợp (Danh mục, Giá, Khuyến mãi)
          let filtered = searchRes.rankedProducts;

          if (selectedCategory !== null) {
            filtered = filtered.filter(
              (p) => p.categoryId === selectedCategory,
            );
          }

          if (onSaleOnly) {
            filtered = filtered.filter((p) => p.promotion?.hasPromotion);
          }

          if (minPrice !== undefined) {
            filtered = filtered.filter((p) => {
              const effectivePrice =
                p.promotion?.promotionalMinPrice ?? p.minPrice;
              return effectivePrice >= minPrice;
            });
          }

          if (maxPrice !== undefined) {
            filtered = filtered.filter((p) => {
              const effectivePrice =
                p.promotion?.promotionalMinPrice ?? p.minPrice;
              return effectivePrice <= maxPrice;
            });
          }

          // Sắp xếp
          if (sortBy === "price-asc") {
            filtered = [...filtered].sort((a, b) => {
              const priceA = a.promotion?.promotionalMinPrice ?? a.minPrice;
              const priceB = b.promotion?.promotionalMinPrice ?? b.minPrice;
              return priceA - priceB;
            });
          } else if (sortBy === "price-desc") {
            filtered = [...filtered].sort((a, b) => {
              const priceA = a.promotion?.promotionalMinPrice ?? a.minPrice;
              const priceB = b.promotion?.promotionalMinPrice ?? b.minPrice;
              return priceB - priceA;
            });
          } else if (sortBy === "newest") {
            filtered = [...filtered].sort(
              (a, b) =>
                new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
            );
          }
          // Nếu sortBy === "relevance" thì giữ nguyên thứ tự điểm BM25

          if (active) {
            const pageSize = 9;
            const computedTotalPages = Math.ceil(filtered.length / pageSize) || 1;
            const pagedItems = filtered.slice(
              (page - 1) * pageSize,
              page * pageSize,
            );

            setProducts(pagedItems);
            setTotalPages(computedTotalPages);
            setTotalItems(filtered.length);
            setLoading(false);
          }
        } catch {
          if (active) {
            setError("Lỗi khi xử lý tìm kiếm.");
            setLoading(false);
          }
        }
        return;
      }

      // TRƯỜNG HỢP B: KHÔNG TÌM KIẾM -> DÙNG PHÂN TRANG VÀ LỌC CƠ BẢN
      setSearchInfo(null);
      const isAsc = sortBy === "price-asc";
      const sortField = sortBy.startsWith("price") ? "price" : "createdAt";

      try {
        const res = await fetchProducts({
          page,
          pageSize: 9,
          search: undefined,
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

    void processProducts();
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
    catalogProducts,
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
        <ProductsHeroBanner />

        <section className={styles.toolbar} aria-label="Bộ lọc sản phẩm">
          <div className={styles.topFilters}>
            {/* THANH TÌM KIẾM THÔNG MINH (AUTOCOMPLETE + HISTORY + TRENDING) */}
            <SearchBar
              value={search}
              onChange={(val) => {
                setSearch(val);
                setPage(1);
                if (val && sortBy !== "price-asc" && sortBy !== "price-desc") {
                  setSortBy("relevance");
                }
              }}
              onSearch={(val) => {
                setSearch(val);
                setPage(1);
                if (val && sortBy !== "price-asc" && sortBy !== "price-desc") {
                  setSortBy("relevance");
                }
              }}
              allProducts={catalogProducts}
            />

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
                {search.trim() && (
                  <option value="relevance">Độ liên quan nhất (BM25)</option>
                )}
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

        {/* BANNER THÔNG BÁO SỬA LỖI CHÍNH TẢ (TYPO TOLERANCE NOTICE) */}
        {searchInfo?.hasTypo && (
          <div className={styles.typoNoticeBanner}>
            <div>
              💡 Hiển thị kết quả cho:{" "}
              <strong>&ldquo;{searchInfo.effectiveQuery}&rdquo;</strong>.
            </div>
            <button
              type="button"
              className={styles.typoOverrideBtn}
              onClick={() => {
                setSearch(searchInfo.originalQuery);
                setSearchInfo(null);
                setPage(1);
              }}
              title="Tìm kiếm chính xác từ khóa gốc của bạn"
            >
              Tìm kiếm thay thế cho &ldquo;{searchInfo.originalQuery}&rdquo;
            </button>
          </div>
        )}

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
          <div className={styles.loading}>Đang tìm kiếm sản phẩm phù hợp…</div>
        ) : products.length === 0 ? (
          /* GIAO DIỆN CỨU CÁNH DEAD-END RESCUE KHI 0 KẾT QUẢ */
          <div className={styles.deadEndContainer}>
            <div className={styles.deadEndIcon}>🔍</div>
            <h3 className={styles.deadEndTitle}>
              Không tìm thấy kết quả phù hợp cho &ldquo;{search}&rdquo;
            </h3>
            <p className={styles.deadEndSubtitle}>
              Rất tiếc, chúng tôi không tìm thấy thiết bị nào khớp với từ khóa tìm kiếm hoặc bộ lọc hiện tại.
            </p>

            <div className={styles.deadEndTips}>
              <div className={styles.tipItem}>
                ✓ Kiểm tra lại lỗi chính tả hoặc thử các từ khóa ngắn gọn hơn (VD: &ldquo;laptop&rdquo;, &ldquo;tai nghe&rdquo;).
              </div>
              <div className={styles.tipItem}>
                ✓ Thử tìm bằng từ đồng nghĩa hoặc tên thương hiệu (VD: &ldquo;Sony&rdquo;, &ldquo;Logitech&rdquo;, &ldquo;Asus&rdquo;).
              </div>
              <div className={styles.tipItem}>
                ✓ Xóa bỏ bớt các bộ lọc khoảng giá hoặc danh mục để mở rộng phạm vi tìm kiếm.
              </div>
            </div>

            <div className={styles.deadEndActions}>
              <button
                type="button"
                className={styles.resetBtn}
                onClick={handleResetFilters}
              >
                Xóa tất cả bộ lọc &amp; tìm kiếm
              </button>
            </div>

            {/* Gợi ý danh mục hàng đầu */}
            <div className={styles.suggestedCategories}>
              <span className={styles.suggestedCatTitle}>
                Khám phá các danh mục công nghệ hàng đầu:
              </span>
              <div className={styles.suggestedCatPills}>
                {categories.map((cat) => (
                  <button
                    key={cat.categoryId}
                    type="button"
                    className={styles.suggestedCatPill}
                    onClick={() => {
                      setSelectedCategory(cat.categoryId);
                      setSearch("");
                      setPage(1);
                    }}
                  >
                    {cat.categoryName}
                  </button>
                ))}
              </div>
            </div>

            {/* Gợi ý các sản phẩm nổi bật bán chạy */}
            {catalogProducts.length > 0 && (
              <div className={styles.featuredRescueSection}>
                <h4 className={styles.featuredRescueHeading}>
                  🔥 Sản phẩm công nghệ nổi bật gợi ý cho bạn
                </h4>
                <div className={styles.grid}>
                  {catalogProducts.slice(0, 3).map((p) => (
                    <ProductCard key={p.productId} product={p} />
                  ))}
                </div>
              </div>
            )}
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
