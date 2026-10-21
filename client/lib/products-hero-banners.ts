/**
 * =========================================================================
 * CẤU HÌNH HÌNH ẢNH NỀN CHO VÙNG "SẢN PHẨM CÔNG NGHỆ TINH TUYỂN"
 * =========================================================================
 * 
 * NƠI BẠN CÓ THỂ THÊM / SỬA / XÓA CÁC ẢNH CỐ ĐỊNH CHO NỀN BACKGROUND:
 * 
 * Cách 1: Tải ảnh vào máy (Thư mục client/public/banners/products/)
 *   - Bạn chép file ảnh của mình vào thư mục: client/public/banners/products/ (ví dụ: anh-moi.jpg)
 *   - Sau đó thêm 1 dòng vào mảng PRODUCTS_HERO_BANNERS bên dưới:
 *     {
 *       id: "anh-moi",
 *       imageUrl: "/banners/products/anh-moi.jpg",
 *       alt: "Mô tả ảnh của bạn",
 *       linkUrl: "/products/id-san-pham", // Đường dẫn tới trang chi tiết sản phẩm
 *     }
 * 
 * Cách 2: Dán trực tiếp link ảnh Online (Cloudinary hoặc link HTTPS bất kỳ)
 *     {
 *       id: "cloud-banner",
 *       imageUrl: "https://res.cloudinary.com/.../hinh-anh.jpg",
 *       alt: "Ảnh banner từ Cloudinary",
 *       linkUrl: "/products/id-san-pham", // Đường dẫn tới trang chi tiết sản phẩm
 *     }
 * 
 * Hệ thống sẽ tự động chuyển cảnh mượt mà giữa các ảnh này mỗi 3 giây (3.000 ms) và lặp lại liên tục!
 */

export interface ProductsHeroBannerItem {
  id: string;
  imageUrl: string;
  alt: string;
  tag?: string;
  title?: string;
  description?: string;
  linkUrl?: string; // Link điều hướng tới trang chi tiết sản phẩm
}

export const PRODUCTS_HERO_BANNERS: ProductsHeroBannerItem[] = [
  {
    id: "banner-1",
    imageUrl:
      "https://cdn2.cellphones.com.vn/insecure/rs:fill:0:0/q:100/plain/https://cellphones.com.vn/media/wysiwyg/laptop/macbook/Air/M3-2024/macbook-air-m3-13-inch-2024-2_2.jpg",
    alt: "Laptop Apple MacBook Air M3",
    tag: "Laptop Apple MacBook Air M3",
    title: "Mỏng nhẹ vượt bậc",
    description:
      "Lớp vỏ nhôm tái chế nguyên khối mang lại vẻ ngoài sang trọng, bền bỉ, giúp bạn xử lý mượt mà mọi dự án thiết kế, edit video hay lập trình ở bất cứ đâu.",
    linkUrl: "/products?search=MacBook", // Sau này bạn thay bằng link trang chi tiết (ví dụ: /products/1)
  },
  {
    id: "banner-2",
    imageUrl:
      "https://minhtuanmobile.com/uploads/products/231016113852-910006561.jpg",
    alt: "Chuột không dây công thái học Logitech MX Master 3S",
    tag: "Chuột không dây công thái học Logitech MX Master 3S",
    title: "Vũ khí tối thượng",
    description:
      "Nổi bật với cảm biến quang học 8000 DPI siêu nhạy. Thiết kế công thái học ôm trọn lòng bàn tay giúp giảm thiểu nhức mỏi, mang lại sự thoải mái tuyệt đối cho những ngày dài sáng tạo.",
    linkUrl: "/products?search=Logitech", // Sau này bạn thay bằng link trang chi tiết (ví dụ: /products/2)
  },
  {
    id: "banner-3",
    imageUrl:
      "https://bizweb.dktcdn.net/100/340/129/products/wh-1000xm5-sonycuongphan-1-8.jpg?v=1728039424327",
    alt: "Tai nghe chống ồn Sony WH-1000XM5",
    tag: "Tai nghe chống ồn Sony WH-1000XM5",
    title: "Sự tinh tuyển trong công nghệ âm thanh",
    description:
      "WH-1000XM5 mang đến trải nghiệm chống ồn chủ động nhờ bộ xử lý kép và 8 micro thu âm. Tạo ra một không gian làm việc tĩnh lặng hoàn hảo.",
    linkUrl: "/products?search=Sony", // Sau này bạn thay bằng link trang chi tiết (ví dụ: /products/3)
  },
];
