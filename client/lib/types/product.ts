export interface ProductBaseDto {
  productId: number;
  productName: string;
  categoryId: number;
  categoryName: string;
  imageUrl: string | null;
  minPrice: number;
  maxPrice: number;
  totalStock: number;
  isActive: boolean;
  createdAt: string;
}

export interface ProductVariantDto {
  variantId: number;
  productId: number;
  productName: string;
  variantName: string;
  price: number;
  stockQuantity: number;
  imageUrl: string | null;
  attributes: Record<string, string>;
  isActive: boolean;
  createdAt: string;
}

export interface ProductDetailDto extends ProductBaseDto {
  description: string | null;
  variantAttributes: string[];
  variants: ProductVariantDto[];
}

export interface CategoryDto {
  categoryId: number;
  categoryName: string;
  createdAt: string;
}

export interface PaginationMeta {
  page: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  hasPreviousPage: boolean;
  hasNextPage: boolean;
}

export interface PagedResult<T> {
  items: T[];
  meta: PaginationMeta;
}

export interface ProductQueryFilter {
  page?: number;
  pageSize?: number;
  search?: string;
  categoryId?: number;
  minPrice?: number;
  maxPrice?: number;
  sortBy?: string;
  isAscending?: boolean;
}
