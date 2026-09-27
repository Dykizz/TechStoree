using WebBanHang.Api.DTOs.Variants;

namespace WebBanHang.Api.DTOs.Products;

public class ProductDetailDto : ProductBaseDto
{
    /// <summary>
    /// Mô tả chi tiết dòng sản phẩm
    /// </summary>
    /// <example>Laptop mỏng nhẹ cao cấp màn hình OLED 120Hz, chip Intel Core Ultra thế hệ mới.</example>
    public string? Description { get; set; }

    /// <summary>
    /// Danh sách các tiêu chí thuộc tính biến thể (VD: ["Cấu hình (RAM/SSD)", "Màu sắc"])
    /// </summary>
    public List<string> VariantAttributes { get; set; } = new();

    /// <summary>
    /// Danh sách chi tiết các biến thể của sản phẩm
    /// </summary>
    public List<ProductVariantDto> Variants { get; set; } = new();
}
