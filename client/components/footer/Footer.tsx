import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-surface text-muted border-t border-border pt-12 pb-6 text-sm">
      <div className="max-w-7xl mx-auto px-8 max-md:px-5">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-12 max-md:gap-8 pb-10">
          <div className="sm:col-span-2 md:col-span-2">
            <Link href="/" className="inline-flex gap-2.5 items-center text-ink text-sm font-extrabold tracking-widest no-underline">
              <span
                className="w-8 h-8 rounded-md bg-brand relative before:content-[''] before:absolute before:top-2 before:left-1.5 before:w-5 before:h-1 before:bg-white after:content-[''] after:absolute after:top-3 after:left-3 after:w-1.5 after:h-3 after:bg-white"
                aria-hidden="true"
              />
              <span>TECHSTOREE</span>
            </Link>
            <p className="leading-relaxed mt-4 text-sm">
              Thiết bị công nghệ. Lựa chọn tinh tế.
              <br />
              Một trải nghiệm giản đơn, dành cho bạn.
            </p>
          </div>
          <div className="sm:col-span-1 md:col-span-1">
            <h2 className="text-sm text-ink mt-1 mb-4 font-semibold">Khám phá</h2>
            <ul className="flex flex-col gap-3.5 list-none p-0 m-0">
              <li>
                <Link href="/products" className="text-muted no-underline transition-colors hover:text-brand">
                  Tất cả sản phẩm
                </Link>
              </li>
              <li>
                <Link href="/products?onSale=true" className="text-muted no-underline transition-colors hover:text-brand">
                  Ưu đãi đang diễn ra
                </Link>
              </li>
              <li>
                <Link href="/cart" className="text-muted no-underline transition-colors hover:text-brand">
                  Giỏ hàng
                </Link>
              </li>
            </ul>
          </div>
          <div className="sm:col-span-1 md:col-span-1">
            <h2 className="text-sm text-ink mt-1 mb-4 font-semibold">Tài khoản của bạn</h2>
            <ul className="flex flex-col gap-3.5 list-none p-0 m-0">
              <li>
                <Link href="/profile" className="text-muted no-underline transition-colors hover:text-brand">
                  Hồ sơ cá nhân
                </Link>
              </li>
              <li>
                <Link href="/orders" className="text-muted no-underline transition-colors hover:text-brand">
                  Lịch sử đơn hàng
                </Link>
              </li>
              <li>
                <Link href="/surveys" className="text-muted no-underline transition-colors hover:text-brand">
                  Khảo sát của tôi
                </Link>
              </li>
            </ul>
          </div>
        </div>
        <div className="flex flex-wrap justify-between gap-3 pt-5 border-t border-neutral-300 text-xs">
          <p>© {new Date().getFullYear()} TechStoree · Dự án học tập</p>
          <p>Thông tin giá và đơn hàng được xác nhận bởi hệ thống.</p>
        </div>
      </div>
    </footer>
  );
}
