namespace WebBanHang.Api.DTOs.Products;

public class ProductBaseDto
{
    /// <summary>
    /// Mã ID duy nhất của sản phẩm
    /// </summary>
    /// <example>1</example>
    public int ProductId { get; set; }

    /// <summary>
    /// Tên dòng sản phẩm
    /// </summary>
    /// <example>Laptop ASUS Zenbook 14 OLED UX3405</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Mã ID danh mục sản phẩm
    /// </summary>
    /// <example>1</example>
    public int CategoryId { get; set; }

    /// <summary>
    /// Tên danh mục sản phẩm
    /// </summary>
    /// <example>Laptop</example>
    public string CategoryName { get; set; } = string.Empty;

    /// <summary>
    /// Hình ảnh đại diện sản phẩm
    /// </summary>
    /// <example>https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/t/e/text_ng_n_4__2_70.png</example>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Giá bán thấp nhất trong các biến thể (VNĐ)
    /// </summary>
    /// <example>24990000</example>
    public decimal MinPrice { get; set; }

    /// <summary>
    /// Giá bán cao nhất trong các biến thể (VNĐ)
    /// </summary>
    /// <example>28990000</example>
    public decimal MaxPrice { get; set; }

    /// <summary>
    /// Tổng số lượng tồn kho của tất cả các biến thể
    /// </summary>
    /// <example>25</example>
    public int TotalStock { get; set; }

    /// <summary>
    /// Trạng thái kinh doanh sản phẩm
    /// </summary>
    /// <example>true</example>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Thông tin tóm tắt khuyến mãi đang áp dụng (null nếu không có khuyến mãi)
    /// </summary>
    public ProductPromotionSummaryDto? Promotion { get; set; }

    /// <summary>
    /// Cờ tiện ích kiểm tra sản phẩm có đang nằm trong đợt giảm giá hay không
    /// </summary>
    /// <example>true</example>
    public bool HasPromotion => Promotion != null;

    /// <summary>
    /// Thời điểm khởi tạo sản phẩm (UTC)
    /// </summary>
    /// <example>2026-01-01T00:00:00Z</example>
    public DateTime CreatedAt { get; set; }
}

/// <summary>
/// Thông tin tóm tắt khuyến mãi áp dụng cho sản phẩm
/// </summary>
public class ProductPromotionSummaryDto
{
    /// <summary>
    /// Cờ xác nhận sản phẩm có biến thể đang khuyến mãi
    /// </summary>
    /// <example>true</example>
    public bool HasPromotion { get; set; } = true;

    /// <summary>
    /// Mã ID khuyến mãi
    /// </summary>
    /// <example>1</example>
    public int? PromotionId { get; set; }

    /// <summary>
    /// Tên chương trình khuyến mãi
    /// </summary>
    /// <example>Flash Sale Cuối Tuần</example>
    public string PromotionName { get; set; } = string.Empty;

    /// <summary>
    /// Loại giảm giá: PERCENTAGE hoặc FIXED_AMOUNT
    /// </summary>
    /// <example>PERCENTAGE</example>
    public string? DiscountType { get; set; }

    /// <summary>
    /// Mức giảm giá
    /// </summary>
    /// <example>10</example>
    public decimal? DiscountValue { get; set; }

    /// <summary>
    /// Giá bán khuyến mãi thấp nhất trong các biến thể (VNĐ)
    /// </summary>
    /// <example>22491000</example>
    public decimal PromotionalMinPrice { get; set; }

    /// <summary>
    /// Giá bán khuyến mãi cao nhất trong các biến thể (VNĐ)
    /// </summary>
    /// <example>26091000</example>
    public decimal PromotionalMaxPrice { get; set; }
}
