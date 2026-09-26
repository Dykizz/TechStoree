using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.Promotions;

/// <summary>
/// DTO tóm tắt chương trình khuyến mãi dùng cho danh sách (không chứa mảng variants để tối ưu hiệu năng)
/// </summary>
public class PromotionBaseDto
{
    /// <summary>
    /// Mã ID khuyến mãi
    /// </summary>
    /// <example>1</example>
    public int PromotionId { get; set; }

    /// <summary>
    /// Tên chương trình khuyến mãi
    /// </summary>
    /// <example>Flash Sale Cuối Tuần</example>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả chi tiết thể lệ
    /// </summary>
    /// <example>Giảm 10% cho các dòng laptop và tai nghe cao cấp</example>
    public string? Description { get; set; }

    /// <summary>
    /// Loại giảm giá: PERCENTAGE hoặc FIXED_AMOUNT
    /// </summary>
    /// <example>PERCENTAGE</example>
    public string DiscountType { get; set; } = "PERCENTAGE";

    /// <summary>
    /// Giá trị giảm (10 nếu là 10%, hoặc 500000 nếu là 500k)
    /// </summary>
    /// <example>10</example>
    public decimal DiscountValue { get; set; }

    /// <summary>
    /// Thời gian bắt đầu (UTC)
    /// </summary>
    public DateTime StartDate { get; set; }

    /// <summary>
    /// Thời gian kết thúc (UTC)
    /// </summary>
    public DateTime EndDate { get; set; }

    /// <summary>
    /// Trạng thái kích hoạt của khuyến mãi
    /// </summary>
    /// <example>true</example>
    public bool IsActive { get; set; }

    /// <summary>
    /// Thời gian tạo (UTC)
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Trạng thái thời gian: UPCOMING (sắp diễn ra), ACTIVE (đang diễn ra), EXPIRED (đã kết thúc)
    /// </summary>
    /// <example>ACTIVE</example>
    public PromotionStatus Status { get; set; } = PromotionStatus.ACTIVE;

    /// <summary>
    /// Tổng số biến thể tham gia chương trình
    /// </summary>
    /// <example>5</example>
    public int VariantCount { get; set; }
}

/// <summary>
/// DTO chi tiết chương trình khuyến mãi kèm danh sách đầy đủ các biến thể sản phẩm tham gia
/// </summary>
public class PromotionDetailDto : PromotionBaseDto
{
    /// <summary>
    /// Danh sách chi tiết các biến thể tham gia kèm giá bán ưu đãi
    /// </summary>
    public List<PromotionVariantItemDto> Variants { get; set; } = new();
}

/// <summary>
/// Alias cho PromotionDetailDto để tương thích ngược
/// </summary>
public class PromotionDto : PromotionDetailDto
{
}

public class PromotionVariantItemDto
{
    /// <summary>
    /// Mã ID biến thể
    /// </summary>
    /// <example>1</example>
    public int VariantId { get; set; }

    /// <summary>
    /// Mã ID sản phẩm gốc
    /// </summary>
    /// <example>1</example>
    public int ProductId { get; set; }

    /// <summary>
    /// Tên dòng sản phẩm
    /// </summary>
    /// <example>Laptop ASUS Zenbook 14 OLED</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Tên biến thể (màu sắc/dung lượng)
    /// </summary>
    /// <example>16GB RAM / 512GB SSD - Xanh</example>
    public string VariantName { get; set; } = string.Empty;

    /// <summary>
    /// Giá bán gốc niêm yết (VNĐ)
    /// </summary>
    /// <example>24990000</example>
    public decimal OriginalPrice { get; set; }

    /// <summary>
    /// Giá bán sau khi áp dụng khuyến mãi (VNĐ)
    /// </summary>
    /// <example>22491000</example>
    public decimal PromotionalPrice { get; set; }

    /// <summary>
    /// Số tiền được giảm (VNĐ)
    /// </summary>
    /// <example>2499000</example>
    public decimal DiscountAmount { get; set; }

    /// <summary>
    /// Số lượng tồn kho khả dụng
    /// </summary>
    /// <example>15</example>
    public int StockQuantity { get; set; }

    /// <summary>
    /// Ảnh biến thể
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Thuộc tính chi tiết của biến thể
    /// </summary>
    public Dictionary<string, string> Attributes { get; set; } = new();
}
