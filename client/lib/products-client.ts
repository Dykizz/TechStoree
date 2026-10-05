import type {
  CategoryDto,
  ProductBaseDto,
  ProductDetailDto,
  ProductQueryFilter,
  PagedResult,
} from "./types/product";
export function formatPrice(price: number) {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
  }).format(price);
}
export function formatShortPrice(price: number) {
  return price >= 1_000_000_000
    ? `${+(price / 1_000_000_000).toFixed(1)} tỷ`
    : price >= 1_000_000
      ? `${+(price / 1_000_000).toFixed(1)} tr`
      : price >= 1000
        ? `${Math.round(price / 1000)} k`
        : `${price} đ`;
}
async function read<T>(url: string): Promise<T> {
  const response = await fetch(url, { cache: "no-store" });
  if (!response.ok) throw new Error("Không thể tải dữ liệu từ máy chủ.");
  return response.json() as Promise<T>;
}
export async function fetchCategories(): Promise<CategoryDto[]> {
  const data = await read<CategoryDto[]>("/api/categories");
  if (!Array.isArray(data)) throw new Error("Danh mục không hợp lệ.");
  return data;
}
export async function fetchProducts(
  filter: ProductQueryFilter = {},
): Promise<PagedResult<ProductBaseDto>> {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(filter))
    if (value != null) params.set(key, String(value));
  const data = await read<PagedResult<ProductBaseDto>>(
    `/api/products?${params}`,
  );
  if (!data?.meta || !Array.isArray(data.items))
    throw new Error("Danh sách sản phẩm không hợp lệ.");
  return data;
}
export async function fetchProductById(
  id: number,
): Promise<ProductDetailDto | null> {
  if (!Number.isSafeInteger(id) || id <= 0) return null;
  const response = await fetch(`/api/products/${id}`, { cache: "no-store" });
  if (response.status === 404) return null;
  if (!response.ok) throw new Error("Không thể tải sản phẩm từ máy chủ.");
  return response.json() as Promise<ProductDetailDto>;
}
