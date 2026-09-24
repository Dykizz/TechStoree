using WebBanHang.Api.DTOs.Variants;

namespace WebBanHang.Api.DTOs.Products;

public class ProductDetailDto : ProductBaseDto
{
    public string? Description { get; set; }
    public List<string> VariantAttributes { get; set; } = new();
    public List<ProductVariantDto> Variants { get; set; } = new();
}
