using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Reviews;

/// <summary>
/// Bộ lọc danh sách đánh giá của sản phẩm dành cho khách xem hàng (Client)
/// </summary>
public class ProductReviewQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc theo mức số sao (ví dụ: 5.0, 4.5, 4.0, ...)
    /// </summary>
    /// <example>5.0</example>
    public decimal? Rating { get; set; }

    /// <summary>
    /// Chỉ lọc những đánh giá có đính kèm hình ảnh
    /// </summary>
    /// <example>true</example>
    public bool? HasImages { get; set; }
}
