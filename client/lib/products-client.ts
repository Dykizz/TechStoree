import {
  CategoryDto,
  PagedResult,
  ProductBaseDto,
  ProductDetailDto,
  ProductQueryFilter,
} from "./types/product";

export const MOCK_CATEGORIES: CategoryDto[] = [
  { categoryId: 1, categoryName: "Laptop & Máy tính", createdAt: "2026-01-01T00:00:00Z" },
  { categoryId: 2, categoryName: "Điện thoại & Tablet", createdAt: "2026-01-01T00:00:00Z" },
  { categoryId: 3, categoryName: "Đồng hồ thông minh", createdAt: "2026-01-01T00:00:00Z" },
  { categoryId: 4, categoryName: "Phụ kiện cao cấp", createdAt: "2026-01-01T00:00:00Z" },
];

export const MOCK_PRODUCTS: ProductDetailDto[] = [
  {
    productId: 1,
    productName: "TechStoree StudioBook Pro 16",
    categoryId: 1,
    categoryName: "Laptop & Máy tính",
    imageUrl: "/images/editorial-laptop.png",
    minPrice: 38990000,
    maxPrice: 52990000,
    totalStock: 35,
    isActive: true,
    hasPromotion: true,
    promotion: {
      hasPromotion: true,
      promotionId: 1,
      promotionName: "Flash Sale Công Nghệ",
      discountType: "PERCENTAGE",
      discountValue: 15,
      promotionalMinPrice: 33141500,
      promotionalMaxPrice: 45041500,
    },
    createdAt: "2026-02-10T10:00:00Z",
    description:
      "Tuyệt tác công nghệ chế tác từ nhôm nguyên khối siêu mỏng. Màn hình Liquid Retina XDR 16 inch chuẩn màu chuyên nghiệp, vi xử lý M-Pro thế hệ mới tối ưu cho đồ họa chuyên sâu và thời lượng pin vượt trội lên tới 22 giờ.",
    variantAttributes: ["Màu sắc", "Dung lượng SSD"],
    variants: [
      {
        variantId: 101,
        productId: 1,
        productName: "TechStoree StudioBook Pro 16",
        variantName: "Xám Không Gian / 512GB",
        price: 38990000,
        hasPromotion: true,
        promotion: {
          hasPromotion: true,
          promotionId: 1,
          promotionName: "Flash Sale Công Nghệ",
          discountType: "PERCENTAGE",
          discountValue: 15,
          promotionalPrice: 33141500,
          discountAmount: 5848500,
        },
        stockQuantity: 15,
        imageUrl: "/images/editorial-laptop.png",
        attributes: { "Màu sắc": "Xám Không Gian", "Dung lượng SSD": "512GB" },
        isActive: true,
        createdAt: "2026-02-10T10:00:00Z",
      },
      {
        variantId: 102,
        productId: 1,
        productName: "TechStoree StudioBook Pro 16",
        variantName: "Xám Không Gian / 1TB",
        price: 45990000,
        stockQuantity: 12,
        imageUrl: "/images/editorial-laptop.png",
        attributes: { "Màu sắc": "Xám Không Gian", "Dung lượng SSD": "1TB" },
        isActive: true,
        createdAt: "2026-02-10T10:00:00Z",
      },
      {
        variantId: 103,
        productId: 1,
        productName: "TechStoree StudioBook Pro 16",
        variantName: "Bạc Ánh Kim / 1TB",
        price: 45990000,
        stockQuantity: 8,
        imageUrl: "/images/editorial-laptop.png",
        attributes: { "Màu sắc": "Bạc Ánh Kim", "Dung lượng SSD": "1TB" },
        isActive: true,
        createdAt: "2026-02-10T10:00:00Z",
      },
      {
        variantId: 104,
        productId: 1,
        productName: "TechStoree StudioBook Pro 16",
        variantName: "Bạc Ánh Kim / 2TB",
        price: 52990000,
        stockQuantity: 0,
        imageUrl: "/images/editorial-laptop.png",
        attributes: { "Màu sắc": "Bạc Ánh Kim", "Dung lượng SSD": "2TB" },
        isActive: true,
        createdAt: "2026-02-10T10:00:00Z",
      },
    ],
  },
  {
    productId: 2,
    productName: "Horizon Phone 16 Titanium",
    categoryId: 2,
    categoryName: "Điện thoại & Tablet",
    imageUrl: "https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?q=80&w=800&auto=format&fit=crop",
    minPrice: 28990000,
    maxPrice: 39990000,
    totalStock: 48,
    isActive: true,
    createdAt: "2026-02-15T10:00:00Z",
    description:
      "Khung viền Titanium cấp hàng không vũ trụ siêu nhẹ và cứng cáp. Màn hình ProMotion 120Hz luôn bật, cụm 3 camera 48MP zoom quang học 5x cùng nút chụp Action Button thế hệ mới.",
    variantAttributes: ["Màu sắc", "Dung lượng"],
    variants: [
      {
        variantId: 201,
        productId: 2,
        productName: "Horizon Phone 16 Titanium",
        variantName: "Titan Tự Nhiên / 256GB",
        price: 28990000,
        stockQuantity: 20,
        imageUrl: "https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?q=80&w=800&auto=format&fit=crop",
        attributes: { "Màu sắc": "Titan Tự Nhiên", "Dung lượng": "256GB" },
        isActive: true,
        createdAt: "2026-02-15T10:00:00Z",
      },
      {
        variantId: 202,
        productId: 2,
        productName: "Horizon Phone 16 Titanium",
        variantName: "Titan Sa Mạc / 512GB",
        price: 34990000,
        stockQuantity: 18,
        imageUrl: "https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?q=80&w=800&auto=format&fit=crop",
        attributes: { "Màu sắc": "Titan Sa Mạc", "Dung lượng": "512GB" },
        isActive: true,
        createdAt: "2026-02-15T10:00:00Z",
      },
      {
        variantId: 203,
        productId: 2,
        productName: "Horizon Phone 16 Titanium",
        variantName: "Titan Đen / 1TB",
        price: 39990000,
        stockQuantity: 10,
        imageUrl: "https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?q=80&w=800&auto=format&fit=crop",
        attributes: { "Màu sắc": "Titan Đen", "Dung lượng": "1TB" },
        isActive: true,
        createdAt: "2026-02-15T10:00:00Z",
      },
    ],
  },
  {
    productId: 3,
    productName: "Aura Chrono Smartwatch Ultra",
    categoryId: 3,
    categoryName: "Đồng hồ thông minh",
    imageUrl: "https://images.unsplash.com/photo-1579586337278-3befd40fd17a?q=80&w=800&auto=format&fit=crop",
    minPrice: 19990000,
    maxPrice: 22490000,
    totalStock: 25,
    isActive: true,
    createdAt: "2026-02-18T10:00:00Z",
    description:
      "Vỏ titan 49mm chống nước chuẩn 100m lặn chuyên nghiệp. Mặt kính sapphire chống xước vượt trội, GPS băng tần kép chính xác từng mét và thời lượng pin 72 giờ ở chế độ tiết kiệm năng lượng.",
    variantAttributes: ["Dây đeo", "Kích cỡ"],
    variants: [
      {
        variantId: 301,
        productId: 3,
        productName: "Aura Chrono Smartwatch Ultra",
        variantName: "Dây Vải Trail / 49mm",
        price: 19990000,
        stockQuantity: 14,
        imageUrl: "https://images.unsplash.com/photo-1579586337278-3befd40fd17a?q=80&w=800&auto=format&fit=crop",
        attributes: { "Dây đeo": "Dây Vải Trail", "Kích cỡ": "49mm" },
        isActive: true,
        createdAt: "2026-02-18T10:00:00Z",
      },
      {
        variantId: 302,
        productId: 3,
        productName: "Aura Chrono Smartwatch Ultra",
        variantName: "Dây Cao Su Ocean / 49mm",
        price: 22490000,
        stockQuantity: 11,
        imageUrl: "https://images.unsplash.com/photo-1579586337278-3befd40fd17a?q=80&w=800&auto=format&fit=crop",
        attributes: { "Dây đeo": "Dây Cao Su Ocean", "Kích cỡ": "49mm" },
        isActive: true,
        createdAt: "2026-02-18T10:00:00Z",
      },
    ],
  },
  {
    productId: 4,
    productName: "AirSound Horizon Max Pro",
    categoryId: 4,
    categoryName: "Phụ kiện cao cấp",
    imageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=800&auto=format&fit=crop",
    minPrice: 12490000,
    maxPrice: 13990000,
    totalStock: 30,
    isActive: true,
    createdAt: "2026-02-20T10:00:00Z",
    description:
      "Tai nghe chụp tai chống ồn chủ động đỉnh cao (ANC). Đệm tai bằng bọt hoạt tính êm ái, âm thanh vòm Spatial Audio với tính năng theo dõi đầu động, tái tạo trung thực từng chi tiết nhạc acoustic.",
    variantAttributes: ["Màu sắc"],
    variants: [
      {
        variantId: 401,
        productId: 4,
        productName: "AirSound Horizon Max Pro",
        variantName: "Xanh Midnight",
        price: 12490000,
        stockQuantity: 18,
        imageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=800&auto=format&fit=crop",
        attributes: { "Màu sắc": "Xanh Midnight" },
        isActive: true,
        createdAt: "2026-02-20T10:00:00Z",
      },
      {
        variantId: 402,
        productId: 4,
        productName: "AirSound Horizon Max Pro",
        variantName: "Trắng Ánh Bạc",
        price: 13990000,
        stockQuantity: 12,
        imageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=800&auto=format&fit=crop",
        attributes: { "Màu sắc": "Trắng Ánh Bạc" },
        isActive: true,
        createdAt: "2026-02-20T10:00:00Z",
      },
    ],
  },
  {
    productId: 5,
    productName: "SlatePad Ultra OLED 13",
    categoryId: 2,
    categoryName: "Điện thoại & Tablet",
    imageUrl: "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?q=80&w=800&auto=format&fit=crop",
    minPrice: 26990000,
    maxPrice: 35990000,
    totalStock: 22,
    isActive: true,
    createdAt: "2026-02-22T10:00:00Z",
    description:
      "Máy tính bảng siêu mỏng chỉ 5.1mm với màn hình Tandem OLED rực rỡ đột phá. Tương thích bút stylus cảm ứng lực và bàn phím từ tính để biến thành cỗ máy làm việc di động hoàn hảo.",
    variantAttributes: ["Màu sắc", "Dung lượng"],
    variants: [
      {
        variantId: 501,
        productId: 5,
        productName: "SlatePad Ultra OLED 13",
        variantName: "Đen Không Gian / 256GB",
        price: 26990000,
        stockQuantity: 12,
        imageUrl: "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?q=80&w=800&auto=format&fit=crop",
        attributes: { "Màu sắc": "Đen Không Gian", "Dung lượng": "256GB" },
        isActive: true,
        createdAt: "2026-02-22T10:00:00Z",
      },
      {
        variantId: 502,
        productId: 5,
        productName: "SlatePad Ultra OLED 13",
        variantName: "Bạc Tinh Khiết / 512GB",
        price: 35990000,
        stockQuantity: 10,
        imageUrl: "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?q=80&w=800&auto=format&fit=crop",
        attributes: { "Màu sắc": "Bạc Tinh Khiết", "Dung lượng": "512GB" },
        isActive: true,
        createdAt: "2026-02-22T10:00:00Z",
      },
    ],
  },
  {
    productId: 6,
    productName: "MagCharge Duo Wireless Pad",
    categoryId: 4,
    categoryName: "Phụ kiện cao cấp",
    imageUrl: "https://images.unsplash.com/photo-1622445262464-84b1456045b6?q=80&w=800&auto=format&fit=crop",
    minPrice: 3290000,
    maxPrice: 3290000,
    totalStock: 60,
    isActive: true,
    createdAt: "2026-02-25T10:00:00Z",
    description:
      "Đế sạc không dây kép gập gọn bọc da nhân tạo cao cấp. Hỗ trợ sạc nhanh đồng thời điện thoại 15W và đồng hồ thông minh với nam châm hít chuẩn xác.",
    variantAttributes: ["Màu sắc"],
    variants: [
      {
        variantId: 601,
        productId: 6,
        productName: "MagCharge Duo Wireless Pad",
        variantName: "Trắng Bắc Cực",
        price: 3290000,
        stockQuantity: 60,
        imageUrl: "https://images.unsplash.com/photo-1622445262464-84b1456045b6?q=80&w=800&auto=format&fit=crop",
        attributes: { "Màu sắc": "Trắng Bắc Cực" },
        isActive: true,
        createdAt: "2026-02-25T10:00:00Z",
      },
    ],
  },
];

export function formatPrice(price: number): string {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
  }).format(price);
}

export function formatShortPrice(price: number): string {
  if (price >= 1_000_000_000) {
    const b = price / 1_000_000_000;
    return `${Number.isInteger(b) ? b : b.toFixed(1)} tỷ`;
  }
  if (price >= 1_000_000) {
    const m = price / 1_000_000;
    return `${Number.isInteger(m) ? m : m.toFixed(1)} tr`;
  }
  if (price >= 1_000) {
    const k = price / 1_000;
    return `${Number.isInteger(k) ? k : k.toFixed(0)} k`;
  }
  return `${price} đ`;
}

export async function fetchCategories(): Promise<CategoryDto[]> {
  try {
    const res = await fetch("/api/categories", { cache: "no-store" });
    if (res.ok) {
      const data = (await res.json()) as CategoryDto[];
      if (Array.isArray(data) && data.length > 0) return data;
    }
  } catch {
    // Backend offline, fallback to mock
  }
  return MOCK_CATEGORIES;
}

export async function fetchProducts(
  filter: ProductQueryFilter = {}
): Promise<PagedResult<ProductBaseDto>> {
  const params = new URLSearchParams();
  if (filter.page) params.set("page", filter.page.toString());
  if (filter.pageSize) params.set("pageSize", filter.pageSize.toString());
  if (filter.search) params.set("search", filter.search);
  if (filter.categoryId) params.set("categoryId", filter.categoryId.toString());
  if (filter.minPrice !== undefined && filter.minPrice !== null)
    params.set("minPrice", filter.minPrice.toString());
  if (filter.maxPrice !== undefined && filter.maxPrice !== null)
    params.set("maxPrice", filter.maxPrice.toString());
  if (filter.sortBy) params.set("sortBy", filter.sortBy);
  if (filter.isAscending !== undefined)
    params.set("isAscending", filter.isAscending.toString());
  if (filter.onSale !== undefined)
    params.set("onSale", filter.onSale.toString());

  try {
    const res = await fetch(`/api/products?${params.toString()}`, {
      cache: "no-store",
    });
    if (res.ok) {
      const result = (await res.json()) as PagedResult<ProductBaseDto>;
      if (result && Array.isArray(result.items)) return result;
    }
  } catch {
    // Backend offline, fallback to mock
  }

  // Fallback client-side filtering on mock data
  let filtered = [...MOCK_PRODUCTS];

  if (filter.onSale) {
    filtered = filtered.filter((p) => p.hasPromotion || p.promotion?.hasPromotion);
  }

  if (filter.search) {
    const q = filter.search.toLowerCase();
    filtered = filtered.filter(
      (p) =>
        p.productName.toLowerCase().includes(q) ||
        p.categoryName.toLowerCase().includes(q) ||
        (p.description && p.description.toLowerCase().includes(q))
    );
  }

  if (filter.categoryId) {
    filtered = filtered.filter((p) => p.categoryId === filter.categoryId);
  }

  if (filter.minPrice !== undefined && filter.minPrice !== null) {
    filtered = filtered.filter((p) => p.maxPrice >= (filter.minPrice ?? 0));
  }

  if (filter.maxPrice !== undefined && filter.maxPrice !== null) {
    filtered = filtered.filter((p) => p.minPrice <= (filter.maxPrice ?? Infinity));
  }

  if (filter.sortBy === "price") {
    filtered.sort((a, b) =>
      filter.isAscending ? a.minPrice - b.minPrice : b.minPrice - a.minPrice
    );
  } else {
    // Default newest
    filtered.sort((a, b) => (a.createdAt > b.createdAt ? -1 : 1));
  }

  const page = filter.page && filter.page > 0 ? filter.page : 1;
  const pageSize = filter.pageSize && filter.pageSize > 0 ? filter.pageSize : 9;
  const totalItems = filtered.length;
  const totalPages = Math.ceil(totalItems / pageSize) || 1;
  const startIndex = (page - 1) * pageSize;
  const paginatedItems = filtered.slice(startIndex, startIndex + pageSize);

  return {
    items: paginatedItems.map((p) => ({
      productId: p.productId,
      productName: p.productName,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      imageUrl: p.imageUrl,
      minPrice: p.minPrice,
      maxPrice: p.maxPrice,
      totalStock: p.totalStock,
      isActive: p.isActive,
      promotion: p.promotion,
      hasPromotion: p.hasPromotion,
      createdAt: p.createdAt,
    })),
    meta: {
      page,
      pageSize,
      totalItems,
      totalPages,
      hasPreviousPage: page > 1,
      hasNextPage: page < totalPages,
    },
  };
}

export async function fetchProductById(id: number): Promise<ProductDetailDto | null> {
  try {
    const res = await fetch(`/api/products/${id}`, { cache: "no-store" });
    if (res.ok) {
      const data = (await res.json()) as ProductDetailDto;
      if (data && data.productId) return data;
    }
  } catch {
    // Backend offline, fallback to mock
  }

  const found = MOCK_PRODUCTS.find((p) => p.productId === id);
  return found || null;
}
