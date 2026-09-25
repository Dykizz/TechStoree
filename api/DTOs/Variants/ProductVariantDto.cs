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
