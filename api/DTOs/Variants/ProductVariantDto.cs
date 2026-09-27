namespace WebBanHang.Api.DTOs.Variants;

public class ProductVariantDto
{
    /// <summary>
    /// Mã ID duy nhất của biến thể
    /// </summary>
    /// <example>1</example>
    public int VariantId { get; set; }

    /// <summary>
    /// Mã ID của dòng sản phẩm gốc
    /// </summary>
    /// <example>1</example>
    public int ProductId { get; set; }

    /// <summary>
    /// Tên dòng sản phẩm
    /// </summary>
    /// <example>Laptop ASUS Zenbook 14 OLED UX3405</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Tên phân loại biến thể
    /// </summary>
    /// <example>16GB RAM / 512GB SSD - Xanh</example>
    public string VariantName { get; set; } = string.Empty;

    /// <summary>
    /// Giá bán niêm yết (VNĐ)
    /// </summary>
    /// <example>24990000</example>
    public decimal Price { get; set; }

    /// <summary>
    /// Số lượng tồn kho khả dụng hiện tại
    /// </summary>
    /// <example>15</example>
    public int StockQuantity { get; set; }

    /// <summary>
    /// Hình ảnh riêng của biến thể
    /// </summary>
    /// <example>https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/t/e/text_ng_n_4__2_70.png</example>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Danh sách cặp thuộc tính phân loại (Key - Value)
    /// </summary>
    public Dictionary<string, string> Attributes { get; set; } = new();

    /// <summary>
    /// Thông tin khuyến mãi đang áp dụng cho biến thể này (null nếu không có khuyến mãi)
    /// </summary>
    public VariantPromotionDto? Promotion { get; set; }

    /// <summary>
    /// Cờ tiện ích kiểm tra biến thể có đang được hưởng khuyến mãi hay không
    /// </summary>
    /// <example>true</example>
    public bool HasPromotion => Promotion != null;

    /// <summary>
    /// Trạng thái kinh doanh biến thể
    /// </summary>
    /// <example>true</example>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Thời điểm khởi tạo biến thể (UTC)
    /// </summary>
    /// <example>2026-01-01T00:00:00Z</example>
    public DateTime CreatedAt { get; set; }
}

/// <summary>
/// Chi tiết khuyến mãi áp dụng cho từng biến thể
/// </summary>
public class VariantPromotionDto
{
    /// <summary>
    /// Cờ xác nhận biến thể đang được áp dụng khuyến mãi
    /// </summary>
    /// <example>true</example>
    public bool HasPromotion { get; set; } = true;

    /// <summary>
    /// Mã ID của chương trình khuyến mãi
    /// </summary>
    /// <example>1</example>
    public int PromotionId { get; set; }

    /// <summary>
    /// Tên chương trình khuyến mãi
    /// </summary>
    /// <example>Flash Sale Cuối Tuần</example>
    public string PromotionName { get; set; } = string.Empty;

    /// <summary>
    /// Loại giảm giá: PERCENTAGE hoặc FIXED_AMOUNT
    /// </summary>
    /// <example>PERCENTAGE</example>
    public string DiscountType { get; set; } = "PERCENTAGE";

    /// <summary>
    /// Giá trị giảm (VD: 10 nếu là 10%, 500000 nếu là 500k)
    /// </summary>
    /// <example>10</example>
    public decimal DiscountValue { get; set; }

    /// <summary>
    /// Giá bán thực tế sau khi áp dụng khuyến mãi (VNĐ)
    /// </summary>
    /// <example>22491000</example>
    public decimal PromotionalPrice { get; set; }

    /// <summary>
    /// Số tiền được giảm giá (VNĐ)
    /// </summary>
    /// <example>2499000</example>
    public decimal DiscountAmount { get; set; }
}
