using WebBanHang.Api.DTOs.Products;
using WebBanHang.Api.DTOs.Promotions;
using WebBanHang.Api.DTOs.Suppliers;
using WebBanHang.Api.DTOs.Vouchers;

namespace WebBanHang.Api.Services.Caching;

public static class CacheKeys
{
    public static string Normalize(string? text) 
        => string.IsNullOrWhiteSpace(text) ? "all" : Uri.EscapeDataString(text.Trim().ToLower());

    public static class Products
    {
        public const string Prefix = "products";

        public static string Detail(int id, bool isAdmin) 
            => $"{Prefix}:detail:{id}:{(isAdmin ? "admin" : "public")}";

        public static string List(ProductQueryFilter filter, bool isAdmin)
        {
            var role = isAdmin ? "admin" : "public";
            var sortBy = string.IsNullOrWhiteSpace(filter.SortBy) ? "default" : filter.SortBy.Trim().ToLower();
            return $"{Prefix}:list:{role}:p{filter.Page}:s{filter.PageSize}:c{filter.CategoryId}:min{filter.MinPrice}:max{filter.MaxPrice}:sort_{sortBy}:{filter.IsAscending}:sale{filter.OnSale}:act{filter.IsActive}:q_{Normalize(filter.Search)}";
        }
    }

    public static class Categories
    {
        public const string Prefix = "categories";

        public static string Detail(int id) => $"{Prefix}:detail:{id}";

        public static string All(string? search) => $"{Prefix}:list:{Normalize(search)}";
    }

    public static class Promotions
    {
        public const string Prefix = "promotions";

        public static string Detail(int id) => $"{Prefix}:detail:{id}";

        public static string List(PromotionQueryFilter? filter)
        {
            if (filter is null) return $"{Prefix}:list:all";
            return $"{Prefix}:list:act_{filter.IsActive}:st_{filter.Status}:from_{filter.FromDate:yyyyMMdd}:to_{filter.ToDate:yyyyMMdd}:q_{Normalize(filter.Search)}";
        }
    }

    public static class Vouchers
    {
        public const string Prefix = "vouchers";

        public static string Available() => $"{Prefix}:available";

        public static string Detail(int id) => $"{Prefix}:detail:{id}";

        public static string List(VoucherQueryFilter? filter)
        {
            if (filter is null) return $"{Prefix}:list:all";
            return $"{Prefix}:list:p{filter.Page}:s{filter.PageSize}:st_{filter.Status}:act_{filter.IsActive}:pub_{filter.IsPublic}:q_{Normalize(filter.Search)}";
        }
    }

    public static class Roles
    {
        public const string Prefix = "roles";

        public static string Permissions() => $"{Prefix}:permissions";

        public static string All() => $"{Prefix}:all";

        public static string Detail(string roleId) => $"{Prefix}:detail:{roleId.Trim().ToLower()}";
    }

    public static class Suppliers
    {
        public const string Prefix = "suppliers";

        public static string Detail(int id) => $"{Prefix}:detail:{id}";

        public static string List(SupplierQueryFilter filter)
        {
            var status = string.IsNullOrWhiteSpace(filter.Status) ? "active" : filter.Status.Trim().ToLower();
            var sortBy = string.IsNullOrWhiteSpace(filter.SortBy) ? "default" : filter.SortBy.Trim().ToLower();
            return $"{Prefix}:list:p{filter.Page}:s{filter.PageSize}:st_{status}:sort_{sortBy}:{filter.IsAscending}:q_{Normalize(filter.Search)}";
        }
    }
}
