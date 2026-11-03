"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import PriceFilterDropdown from "@/components/products/PriceFilterDropdown";
import ProductCard from "@/components/products/ProductCard";
import ProductsHeroBanner from "@/components/products/ProductsHeroBanner";
import SearchBar from "@/components/search/SearchBar";
import Pagination from "@/components/ui/Pagination";
import {
  fetchProducts,
  formatPrice,
} from "@/lib/products-client";
import { executeSearch } from "@/lib/search/search-engine";
import { ProductBaseDto } from "@/lib/types/product";
import { cn } from "@/lib/utils";
import { useCategories } from "@/hooks/queries/useCategories";
import { useProducts } from "@/hooks/queries/useProducts";

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
  const { data: categories = [] } = useCategories();
  const { data: catalogData } = useProducts({ pageSize: 100 });
  const catalogProducts = useMemo(
    () => catalogData?.items || [],
    [catalogData?.items]
  );

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
    <main className="min-h-[calc(100vh-68px)] bg-[#fbfbfb] py-10 px-6 pb-20 max-sm:py-6 max-sm:px-4 max-sm:pb-[60px]">
      <div className="max-w-[1280px] mx-auto">
        <ProductsHeroBanner />

        <section className="bg-white border border-[#ebebeb] rounded-xl p-4 sm:px-5 mb-8 flex flex-col gap-4 shadow-[0_2px_10px_rgba(0,0,0,0.02)]" aria-label="Bộ lọc sản phẩm">
          <div className="flex items-center justify-between gap-4 flex-wrap">
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

            <div className="flex items-center gap-2.5 flex-wrap">
              <PriceFilterDropdown
                key={`${minPrice}-${maxPrice}`}
                minPrice={minPrice}
                maxPrice={maxPrice}
                onChange={handlePriceChange}
              />

              <select
                className="py-2.5 px-4 border border-[#e0e0e0] rounded-md bg-white text-[0.9rem] text-[#333333] cursor-pointer outline-none transition-colors hover:border-[#111111]"
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

          <div className="flex gap-2 overflow-x-auto pb-1 [scrollbar-width:thin]" aria-label="Danh mục">
            <button
              type="button"
              className={cn(
                "flex items-center gap-1.5 py-2 px-4 rounded-full border text-[0.85rem] font-semibold whitespace-nowrap cursor-pointer transition-all",
                onSaleOnly
                  ? "bg-gradient-to-br from-[#e52d27] to-[#b31217] text-white border-[#b31217] shadow-[0_2px_8px_rgba(189,32,45,0.3)]"
                  : "border-[#ffd0d0] bg-[#fff5f5] text-brand hover:bg-[#ffe6e6] hover:border-[#ffb3b3]"
              )}
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
              className={cn(
                "py-2 px-4 rounded-full border text-[0.85rem] cursor-pointer whitespace-nowrap transition-all",
                selectedCategory === null && !onSaleOnly
                  ? "bg-[#111111] border-[#111111] text-white font-semibold hover:bg-[#222222] hover:text-white"
                  : "border-[#e5e5e5] bg-white text-[#555555] font-medium hover:border-[#aaaaaa] hover:text-[#111111]"
              )}
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
                className={cn(
                  "py-2 px-4 rounded-full border text-[0.85rem] cursor-pointer whitespace-nowrap transition-all",
                  selectedCategory === cat.categoryId
                    ? "bg-[#111111] border-[#111111] text-white font-semibold hover:bg-[#222222] hover:text-white"
                    : "border-[#e5e5e5] bg-white text-[#555555] font-medium hover:border-[#aaaaaa] hover:text-[#111111]"
                )}
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
            <div className="flex items-center gap-2.5 pt-2 border-t border-dashed border-[#ebebeb] flex-wrap">
              <span className="text-[0.82rem] text-[#777777] font-medium">Đang lọc giá:</span>
              <span className="inline-flex items-center gap-2 py-1.5 px-3 bg-[#111111] text-white rounded-full text-[0.82rem] font-medium shadow-[0_2px_6px_rgba(0,0,0,0.1)]">
                💰{" "}
                {minPrice !== undefined && maxPrice !== undefined
                  ? `${formatPrice(minPrice)} — ${formatPrice(maxPrice)}`
                  : minPrice !== undefined
                    ? `Từ ${formatPrice(minPrice)} trở lên`
                    : `Đến ${formatPrice(maxPrice!)}`}
                <button
                  type="button"
                  className="bg-transparent border-none text-[#cccccc] cursor-pointer p-0 inline-flex items-center justify-center text-[11px] w-4 h-4 rounded-full transition-all hover:bg-white/25 hover:text-white"
                  onClick={() => handlePriceChange(undefined, undefined)}
                  title="Xóa lọc giá"
                  aria-label="Xóa lọc giá"
                >
                  ✕
                </button>
              </span>
              <button
                type="button"
                className="bg-transparent border-none text-[#888888] text-[0.8rem] underline cursor-pointer p-0.5 px-1 transition-colors hover:text-brand"
                onClick={() => handlePriceChange(undefined, undefined)}
              >
                Xóa bộ lọc giá
              </button>
            </div>
          )}
        </section>

        {/* BANNER THÔNG BÁO SỬA LỖI CHÍNH TẢ (TYPO TOLERANCE NOTICE) */}
        {searchInfo?.hasTypo && (
          <div className="flex items-center justify-between gap-3 bg-[#fefce8] border border-[#fef08a] border-l-4 border-l-[#eab308] p-3 sm:px-[18px] rounded-lg mb-6 text-[0.92rem] text-[#854d0e] shadow-[0_2px_8px_rgba(234,179,8,0.08)]">
            <div>
              💡 Hiển thị kết quả cho:{" "}
              <strong className="text-[#713f12] font-bold">&ldquo;{searchInfo.effectiveQuery}&rdquo;</strong>.
            </div>
            <button
              type="button"
              className="bg-transparent border-none text-[0.84rem] text-[#92400e] underline cursor-pointer py-1 px-2 transition-colors whitespace-nowrap hover:text-[#b45309]"
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
          <div className="text-center py-20 px-6 bg-white border border-[#ebebeb] rounded-xl mb-10" role="alert">
            <p className="text-[#777777] text-[0.95rem] mb-5">{error}</p>
            <button
              className="bg-[#111111] text-white border-none py-2.5 px-5 rounded-md text-[0.9rem] cursor-pointer transition-colors hover:bg-[#333333]"
              onClick={() => setAttempt((a) => a + 1)}
            >
              Thử lại
            </button>
          </div>
        ) : loading ? (
          <div className="text-center py-20 text-[#666666] text-base">Đang tìm kiếm sản phẩm phù hợp…</div>
        ) : products.length === 0 ? (
          /* GIAO DIỆN CỨU CÁNH DEAD-END RESCUE KHI 0 KẾT QUẢ */
          <div className="bg-white border border-[#ebebeb] rounded-2xl p-12 sm:px-8 mb-10 text-center flex flex-col items-center shadow-[0_4px_20px_rgba(0,0,0,0.03)]">
            <div className="text-5xl mb-3">🔍</div>
            <h3 className="text-[1.45rem] font-bold text-slate-900 mb-2">
              Không tìm thấy kết quả phù hợp cho &ldquo;{search}&rdquo;
            </h3>
            <p className="text-[0.95rem] text-slate-500 max-w-[520px] mb-5">
              Rất tiếc, chúng tôi không tìm thấy thiết bị nào khớp với từ khóa tìm kiếm hoặc bộ lọc hiện tại.
            </p>

            <div className="bg-slate-50 border border-slate-200 rounded-lg p-3.5 sm:px-5 mb-6 text-left max-w-[520px] w-full flex flex-col gap-2">
              <div className="text-[0.86rem] text-slate-600">
                ✓ Kiểm tra lại lỗi chính tả hoặc thử các từ khóa ngắn gọn hơn (VD: &ldquo;laptop&rdquo;, &ldquo;tai nghe&rdquo;).
              </div>
              <div className="text-[0.86rem] text-slate-600">
                ✓ Thử tìm bằng từ đồng nghĩa hoặc tên thương hiệu (VD: &ldquo;Sony&rdquo;, &ldquo;Logitech&rdquo;, &ldquo;Asus&rdquo;).
              </div>
              <div className="text-[0.86rem] text-slate-600">
                ✓ Xóa bỏ bớt các bộ lọc khoảng giá hoặc danh mục để mở rộng phạm vi tìm kiếm.
              </div>
            </div>

            <div className="mb-8">
              <button
                type="button"
                className="bg-[#111111] text-white border-none py-2.5 px-5 rounded-md text-[0.9rem] cursor-pointer transition-colors hover:bg-[#333333]"
                onClick={handleResetFilters}
              >
                Xóa tất cả bộ lọc &amp; tìm kiếm
              </button>
            </div>

            {/* Gợi ý danh mục hàng đầu */}
            <div className="flex flex-col items-center gap-3 mb-9 w-full">
              <span className="text-[0.86rem] font-bold text-slate-600 uppercase tracking-[0.05em]">
                Khám phá các danh mục công nghệ hàng đầu:
              </span>
              <div className="flex flex-wrap gap-2 justify-center">
                {categories.map((cat) => (
                  <button
                    key={cat.categoryId}
                    type="button"
                    className="bg-slate-100 border border-slate-300 text-slate-800 py-2 px-4.5 rounded-full text-[0.88rem] font-semibold cursor-pointer transition-colors hover:bg-slate-900 hover:text-white hover:border-slate-900"
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
              <div className="w-full border-t border-slate-100 pt-8">
                <h4 className="text-[1.15rem] font-bold text-slate-900 mb-6 text-left">
                  🔥 Sản phẩm công nghệ nổi bật gợi ý cho bạn
                </h4>
                <div className="grid grid-cols-[repeat(auto-fill,minmax(280px,1fr))] gap-6 mb-10 max-sm:grid-cols-1 max-sm:gap-4">
                  {catalogProducts.slice(0, 3).map((p: ProductBaseDto) => (
                    <ProductCard key={p.productId} product={p} />
                  ))}
                </div>
              </div>
            )}
          </div>
        ) : (
          <>
            <div className="grid grid-cols-[repeat(auto-fill,minmax(280px,1fr))] gap-6 mb-10 max-sm:grid-cols-1 max-sm:gap-4">
              {products.map((product) => (
                <ProductCard key={product.productId} product={product} />
              ))}
            </div>

            <Pagination
              currentPage={page}
              totalPages={totalPages}
              onPageChange={setPage}
            />
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
