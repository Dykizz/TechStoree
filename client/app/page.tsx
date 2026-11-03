"use client";
import Link from "next/link";
import HomeHero from "@/components/home/HomeHero";
import ProductCard from "@/components/products/ProductCard";
import { useCategories } from "@/hooks/queries/useCategories";
import { useProducts } from "@/hooks/queries/useProducts";

export default function HomePage() {
  const {
    data: categories = [],
    isLoading: loadingCats,
    error: catError,
    refetch: refetchCats,
  } = useCategories();

  const {
    data: featuredData,
    isLoading: loadingFeatured,
    error: featuredError,
    refetch: refetchFeatured,
  } = useProducts({ pageSize: 8 });

  const {
    data: salesData,
    refetch: refetchSales,
  } = useProducts({ pageSize: 4, onSale: true });

  const products = featuredData?.items || [];
  const sales = salesData?.items || [];
  const loading = loadingCats || loadingFeatured;
  const hasError = !!catError || !!featuredError;
  const error = hasError
    ? "Chưa thể tải sản phẩm. Vui lòng kiểm tra kết nối hoặc thử lại."
    : "";

  const handleRetry = () => {
    void refetchCats();
    void refetchFeatured();
    void refetchSales();
  };

  return (
    <main className="text-ink bg-white">
      <HomeHero />
      <section className="border-b border-border py-6.5" aria-label="Trải nghiệm mua sắm">
        <div className="max-w-7xl mx-auto px-8 max-md:px-5">
          <div className="grid grid-cols-3 max-md:grid-cols-1 gap-7 max-md:gap-5">
            <Link href="#explore" className="group relative block px-3.5 py-3 pr-10 -mx-3.5 -my-3 rounded-xl no-underline transition-colors hover:bg-surface focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-4">
              <span className="text-neutral-400 text-xs tracking-widest font-bold block transition-colors group-hover:text-brand">01 / KHÁM PHÁ</span>
              <p className="mt-1.5 text-sm text-neutral-600">Chọn phiên bản phù hợp</p>
              <i className="absolute right-3.5 top-1/2 -translate-y-1/2 text-lg not-italic text-muted transition-colors group-hover:text-brand" aria-hidden="true">↗</i>
            </Link>
            <Link href="/products" className="group relative block px-3.5 py-3 pr-10 -mx-3.5 -my-3 rounded-xl no-underline transition-colors hover:bg-surface focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-4">
              <span className="text-neutral-400 text-xs tracking-widest font-bold block transition-colors group-hover:text-brand">02 / MINH BẠCH</span>
              <p className="mt-1.5 text-sm text-neutral-600">Giá & tồn kho từ hệ thống</p>
              <i className="absolute right-3.5 top-1/2 -translate-y-1/2 text-lg not-italic text-muted transition-colors group-hover:text-brand" aria-hidden="true">↗</i>
            </Link>
            <Link href="/profile" className="group relative block px-3.5 py-3 pr-10 -mx-3.5 -my-3 rounded-xl no-underline transition-colors hover:bg-surface focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-4">
              <span className="text-neutral-400 text-xs tracking-widest font-bold block transition-colors group-hover:text-brand">03 / CÁ NHÂN</span>
              <p className="mt-1.5 text-sm text-neutral-600">Hồ sơ và đơn hàng của bạn</p>
              <i className="absolute right-3.5 top-1/2 -translate-y-1/2 text-lg not-italic text-muted transition-colors group-hover:text-brand" aria-hidden="true">↗</i>
            </Link>
          </div>
        </div>
      </section>
      <section id="explore" className="py-16 max-md:py-11 scroll-mt-24">
        <div className="max-w-7xl mx-auto px-8 max-md:px-5">
          <div className="flex items-end max-md:items-start justify-between max-md:flex-col gap-5 mb-7">
            <div>
              <p className="text-brand text-xs font-bold tracking-widest leading-relaxed uppercase">KHÁM PHÁ THEO NHU CẦU</p>
              <h2 className="text-2xl sm:text-3xl lg:text-4xl tracking-tight font-semibold mt-2 text-ink">Không gian công nghệ.</h2>
            </div>
            <Link href="/products" className="text-ink text-sm no-underline font-semibold hover:text-brand transition-colors">
              Tất cả sản phẩm →
            </Link>
          </div>
          <div className="grid grid-cols-4 max-lg:grid-cols-2 max-sm:grid-cols-1 gap-3.5 mb-16">
            {categories.map((cat, i) => (
              <Link
                key={cat.categoryId}
                href={`/products?category=${cat.categoryId}`}
                className="group grid grid-cols-[1fr_auto] gap-5 p-6 max-sm:p-4.5 bg-surface rounded-2xl text-ink no-underline border border-transparent transition-colors hover:border-brand"
              >
                <span className="col-span-full text-neutral-400 text-xs font-medium">{String(i + 1).padStart(2, "0")}</span>
                <strong className="text-base font-semibold text-neutral-900 group-hover:text-brand transition-colors">{cat.categoryName}</strong>
                <span className="text-neutral-400 group-hover:text-brand transition-colors" aria-hidden="true">↗</span>
              </Link>
            ))}
          </div>
          {loading ? (
            <p className="py-10 text-muted leading-relaxed text-sm" role="status">
              Đang tải sản phẩm…
            </p>
          ) : error ? (
            <div className="py-10 text-muted leading-relaxed text-sm" role="alert">
              <p className="text-red-600 mb-4">{error}</p>
              <button
                className="inline-flex gap-6 items-center justify-center border border-neutral-900 bg-neutral-900 text-white rounded-lg px-5.5 py-3.5 text-sm font-semibold no-underline cursor-pointer transition-colors hover:bg-brand hover:border-brand"
                onClick={handleRetry}
              >
                Thử lại
              </button>
            </div>
          ) : (
            <>
              <div className="flex items-end max-md:items-start justify-between max-md:flex-col gap-5 mb-7">
                <h2 className="text-2xl sm:text-3xl lg:text-4xl tracking-tight font-semibold text-ink">Những lựa chọn nổi bật.</h2>
              </div>
              <div className="grid grid-cols-4 max-lg:grid-cols-2 max-sm:grid-cols-1 gap-5">
                {products.map((product) => (
                  <ProductCard key={product.productId} product={product} />
                ))}
              </div>
              {!products.length && (
                <p className="py-10 text-muted leading-relaxed text-sm">
                  Cửa hàng chưa có sản phẩm. Hãy quay lại sau.
                </p>
              )}
            </>
          )}
        </div>
      </section>
      {!error && sales.length > 0 && (
        <section className="py-16 max-md:py-11 scroll-mt-24 bg-surface">
          <div className="max-w-7xl mx-auto px-8 max-md:px-5">
            <div className="flex items-end max-md:items-start justify-between max-md:flex-col gap-5 mb-7">
              <div>
                <p className="text-brand text-xs font-bold tracking-widest leading-relaxed uppercase">ƯU ĐÃI ĐANG DIỄN RA</p>
                <h2 className="text-2xl sm:text-3xl lg:text-4xl tracking-tight font-semibold mt-2 text-ink">Thêm giá trị cho lựa chọn.</h2>
              </div>
              <Link href="/products?onSale=true" className="text-ink text-sm no-underline font-semibold hover:text-brand transition-colors">
                Xem ưu đãi →
              </Link>
            </div>
            <div className="grid grid-cols-4 max-lg:grid-cols-2 max-sm:grid-cols-1 gap-5">
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
