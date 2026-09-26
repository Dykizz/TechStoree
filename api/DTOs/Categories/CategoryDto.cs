namespace WebBanHang.Api.DTOs.Categories;

public class CategoryDto
{
    /// <summary>
    /// Mã ID duy nhất của danh mục
    /// </summary>
    /// <example>1</example>
    public int CategoryId { get; set; }

    /// <summary>
    /// Tên danh mục sản phẩm
    /// </summary>
    /// <example>Laptop</example>
    public string CategoryName { get; set; } = string.Empty;

    /// <summary>
    /// Thời điểm khởi tạo danh mục (UTC)
    /// </summary>
    /// <example>2026-01-01T00:00:00Z</example>
    public DateTime CreatedAt { get; set; }
}
