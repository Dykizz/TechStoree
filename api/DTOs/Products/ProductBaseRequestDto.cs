using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Products;

public abstract class ProductBaseRequestDto
{
    private string _productName = string.Empty;

    /// <summary>
    /// Tên sản phẩm
    /// </summary>
    /// <example>Điện thoại Samsung Galaxy S25 Ultra AI</example>
    [Required(ErrorMessage = "Tên sản phẩm không được để trống.")]
    [MaxLength(200, ErrorMessage = "Tên sản phẩm không được vượt quá 200 ký tự.")]
    public string ProductName
    {
        get => _productName;
        set => _productName = value?.Trim() ?? string.Empty;
    }

    /// <summary>
    /// Mã ID của danh mục sản phẩm
    /// </summary>
    /// <example>1</example>
    [Required(ErrorMessage = "Danh mục sản phẩm không được để trống.")]
    [Range(1, int.MaxValue, ErrorMessage = "Mã danh mục không hợp lệ.")]
    public int CategoryId { get; set; }

    private string? _description;

    /// <summary>
    /// Mô tả chi tiết sản phẩm
    /// </summary>
    /// <example>Siêu phẩm AI Phone 2026 với chip Snapdragon 8 Elite, camera 200MP zoom 100x.</example>
    public string? Description
    {
        get => _description;
        set => _description = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private string? _imageUrl;

    /// <summary>
    /// Đường dẫn hình ảnh đại diện của sản phẩm
    /// </summary>
    /// <example>https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/2/s25-ultra.png</example>
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

    /// <summary>
    /// Trạng thái kinh doanh sản phẩm (true: đang bán, false: ngừng kinh doanh)
    /// </summary>
    /// <example>true</example>
    public bool? IsActive { get; set; } = true;
}
