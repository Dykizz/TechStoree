using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Products;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services.Caching;

public class CachedProductService(
    ProductService inner,
    ICacheService cache) : IProductService
{
    public Task<PagedResult<ProductBaseDto>> GetProductsAsync(ProductQueryFilter filter, bool isAdmin = false)
        => cache.GetOrCreateAsync(
            CacheKeys.Products.List(filter, isAdmin),
            () => inner.GetProductsAsync(filter, isAdmin),
            absoluteExpiration: CacheDurations.Products.ListAbsolute,
            slidingExpiration: CacheDurations.Products.ListSliding,
            prefix: CacheKeys.Products.Prefix);

    public Task<ProductDetailDto> GetProductByIdAsync(int id, bool isAdmin = false)
        => cache.GetOrCreateAsync(
            CacheKeys.Products.Detail(id, isAdmin),
            () => inner.GetProductByIdAsync(id, isAdmin),
            absoluteExpiration: CacheDurations.Products.DetailAbsolute,
            slidingExpiration: CacheDurations.Products.DetailSliding,
            prefix: CacheKeys.Products.Prefix);

    public async Task<ProductDetailDto> CreateProductAsync(ProductCreateRequestDto dto)
    {
        var result = await inner.CreateProductAsync(dto);
        cache.RemoveByPrefix(CacheKeys.Products.Prefix);
        return result;
    }

    public async Task<ProductDetailDto> UpdateProductAsync(int id, ProductUpdateRequestDto dto)
    {
        var result = await inner.UpdateProductAsync(id, dto);
        cache.RemoveByPrefix(CacheKeys.Products.Prefix);
        return result;
    }

    public async Task<bool> ToggleProductStatusAsync(int id)
    {
        var result = await inner.ToggleProductStatusAsync(id);
        cache.RemoveByPrefix(CacheKeys.Products.Prefix);
        return result;
    }

    public async Task DeleteProductAsync(int id)
    {
        await inner.DeleteProductAsync(id);
        cache.RemoveByPrefix(CacheKeys.Products.Prefix);
    }
}

