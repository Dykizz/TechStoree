using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Products;

public abstract class ProductBaseRequestDto
{
    private string _productName = string.Empty;

    [Required(ErrorMessage = "Tên sản phẩm không được để trống.")]
    [MaxLength(200, ErrorMessage = "Tên sản phẩm không được vượt quá 200 ký tự.")]
    public string ProductName
    {
        get => _productName;
        set => _productName = value?.Trim() ?? string.Empty;
    }

    [Required(ErrorMessage = "Danh mục sản phẩm không được để trống.")]
    [Range(1, int.MaxValue, ErrorMessage = "Mã danh mục không hợp lệ.")]
    public int CategoryId { get; set; }

    private string? _description;
    public string? Description
    {
        get => _description;
        set => _description = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private string? _imageUrl;
    [MaxLength(500, ErrorMessage = "Đường dẫn ảnh đại diện không được vượt quá 500 ký tự.")]
    public string? ImageUrl
    {
        get => _imageUrl;
        set => _imageUrl = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private List<string>? _variantAttributes;

    /// <summary>
    /// Danh sách tên thuộc tính biến thể (VD: ["Dung lượng", "Màu sắc"]).
    /// Tự động loại bỏ khoảng trắng thừa, phần tử rỗng và trùng lặp không phân biệt hoa thường.
    /// </summary>
    public List<string>? VariantAttributes
    {
        get => _variantAttributes;
        set => _variantAttributes = value?
            .Where(a => !string.IsNullOrWhiteSpace(a))
            .Select(a => a.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    // Trạng thái kinh doanh (mặc định true - Đang bán)
    public bool? IsActive { get; set; } = true;
}
