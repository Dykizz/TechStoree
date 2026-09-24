using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Products;

namespace WebBanHang.Api.Services.Interfaces;

public interface IProductService
{
    Task<PagedResult<ProductBaseDto>> GetProductsAsync(ProductQueryFilter filter, bool isAdmin = false);
    Task<ProductDetailDto> GetProductByIdAsync(int id, bool isAdmin = false);
    Task<ProductDetailDto> CreateProductAsync(ProductCreateRequestDto dto);
    Task<ProductDetailDto> UpdateProductAsync(int id, ProductUpdateRequestDto dto);
    Task<bool> ToggleProductStatusAsync(int id);
    Task DeleteProductAsync(int id);
}
