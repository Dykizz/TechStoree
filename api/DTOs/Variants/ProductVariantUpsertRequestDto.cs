using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Variants;

public class ProductVariantUpsertRequestDto
{
    /// <summary>
    /// ID của biến thể (khi cập nhật sản phẩm: null nếu là biến thể mới thêm, có giá trị nếu là biến thể cũ cần cập nhật)
    /// </summary>
    public int? VariantId { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "Giá bán không được nhỏ hơn 0.")]
    public decimal Price { get; set; }

    private string? _imageUrl;

    [MaxLength(500, ErrorMessage = "Đường dẫn ảnh không được vượt quá 500 ký tự.")]
    public string? ImageUrl
    {
        get => _imageUrl;
        set => _imageUrl = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    // Giá trị cụ thể của các thuộc tính (VD: {"Dung lượng": "256GB", "Màu sắc": "Titan Sa Mạc"})
    public Dictionary<string, string> Attributes { get; set; } = new();

    // Trạng thái kinh doanh biến thể (mặc định true - Đang bán)
    public bool? IsActive { get; set; } = true;
}
