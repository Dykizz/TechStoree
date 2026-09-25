using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Products;

public class ProductQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc sản phẩm theo mã danh mục
    /// </summary>
    /// <example>1</example>
    public int? CategoryId { get; set; }

    /// <summary>
    /// Lọc sản phẩm có giá biến thể từ mức tối thiểu này trở lên (VNĐ)
    /// </summary>
    /// <example>10000000</example>
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// Lọc sản phẩm có giá biến thể từ mức tối đa này trở xuống (VNĐ)
    /// </summary>
    /// <example>50000000</example>
    public decimal? MaxPrice { get; set; }

    /// <summary>
    /// Lọc theo trạng thái kinh doanh: true (đang bán), false (ngừng bán)
    /// </summary>
    /// <example>true</example>
    public bool? IsActive { get; set; }
}
