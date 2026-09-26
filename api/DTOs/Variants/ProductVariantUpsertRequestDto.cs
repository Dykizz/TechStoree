using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Variants;

public class ProductVariantUpsertRequestDto
{
    /// <summary>
    /// ID của biến thể (khi cập nhật sản phẩm: null nếu là biến thể mới thêm, có giá trị nếu là biến thể cũ cần cập nhật)
    /// </summary>
    /// <example>1</example>
    public int? VariantId { get; set; }

    /// <summary>
    /// Giá bán niêm yết của biến thể sản phẩm (VNĐ)
    /// </summary>
    /// <example>31990000</example>
    [Range(0, double.MaxValue, ErrorMessage = "Giá bán không được nhỏ hơn 0.")]
    public decimal Price { get; set; }

    private string? _imageUrl;

    /// <summary>
    /// Đường dẫn hình ảnh riêng biệt của biến thể (nếu có)
    /// </summary>
    /// <example>https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/2/s25-ultra-blue.png</example>
    [MaxLength(500, ErrorMessage = "Đường dẫn ảnh không được vượt quá 500 ký tự.")]
    public string? ImageUrl
    {
        get => _imageUrl;
        set => _imageUrl = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    /// <summary>
    /// Bộ thuộc tính định danh biến thể (Key: Tên thuộc tính, Value: Giá trị tương ứng)
    /// </summary>
    public Dictionary<string, string> Attributes { get; set; } = new();

    /// <summary>
    /// Trạng thái kinh doanh biến thể (mặc định true - Đang bán)
    /// </summary>
    /// <example>true</example>
    public bool? IsActive { get; set; } = true;
}
