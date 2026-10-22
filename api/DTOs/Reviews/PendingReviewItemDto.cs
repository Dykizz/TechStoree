namespace WebBanHang.Api.DTOs.Reviews;

/// <summary>
/// DTO món hàng đã nhận nhưng chưa đánh giá (chờ đánh giá)
/// </summary>
public class PendingReviewItemDto
{
    /// <summary>
    /// Mã ID chi tiết đơn hàng
    /// </summary>
    /// <example>501</example>
    public int OrderItemId { get; set; }

    /// <summary>
    /// Mã ID đơn hàng
    /// </summary>
    /// <example>205</example>
    public int OrderId { get; set; }

    /// <summary>
    /// Mã code đơn hàng
    /// </summary>
    /// <example>ORD-20261021-9B2F</example>
    public string OrderCode { get; set; } = string.Empty;

    /// <summary>
    /// Mã ID sản phẩm
    /// </summary>
    /// <example>101</example>
    public int ProductId { get; set; }

    /// <summary>
    /// Tên sản phẩm đã mua
    /// </summary>
    /// <example>iPhone 15 Pro Max</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Mã ID biến thể
    /// </summary>
    /// <example>305</example>
    public int VariantId { get; set; }

    /// <summary>
    /// Tên phân loại biến thể đã mua
    /// </summary>
    /// <example>Màu Titan Tự Nhiên - 256GB</example>
    public string VariantName { get; set; } = string.Empty;

    /// <summary>
    /// Hình ảnh sản phẩm
    /// </summary>
    /// <example>https://res.cloudinary.com/techstore/image/upload/v1/products/iphone15promax.png</example>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Đơn giá mua thực tế
    /// </summary>
    /// <example>29990000</example>
    public decimal UnitPrice { get; set; }

    /// <summary>
    /// Số lượng đã mua
    /// </summary>
    /// <example>1</example>
    public int Quantity { get; set; }

    /// <summary>
    /// Thời gian đơn hàng được tạo
    /// </summary>
    /// <example>2026-10-15T08:30:00Z</example>
    public DateTime OrderDate { get; set; }
}
