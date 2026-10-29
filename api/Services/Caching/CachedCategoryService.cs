using WebBanHang.Api.DTOs.Categories;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services.Caching;

public class CachedCategoryService(
    CategoryService inner,
    ICacheService cache) : ICategoryService
{
    public Task<List<CategoryDto>> GetCategoriesAsync(string? search = null)
        => cache.GetOrCreateAsync(
            CacheKeys.Categories.All(search),
            () => inner.GetCategoriesAsync(search),
            absoluteExpiration: CacheDurations.Categories.Absolute,
            slidingExpiration: CacheDurations.Categories.Sliding,
            prefix: CacheKeys.Categories.Prefix);

    public Task<CategoryDto> GetCategoryByIdAsync(int id)
        => cache.GetOrCreateAsync(
            CacheKeys.Categories.Detail(id),
            () => inner.GetCategoryByIdAsync(id),
            absoluteExpiration: CacheDurations.Categories.Absolute,
            slidingExpiration: CacheDurations.Categories.Sliding,
            prefix: CacheKeys.Categories.Prefix);

    public async Task<CategoryDto> CreateCategoryAsync(CategoryUpsertRequestDto dto)
    {
        var result = await inner.CreateCategoryAsync(dto);
        EvictCache();
        return result;
    }

    public async Task<CategoryDto> UpdateCategoryAsync(int id, CategoryUpsertRequestDto dto)
    {
        var result = await inner.UpdateCategoryAsync(id, dto);
        EvictCache();
        return result;
    }

    public async Task DeleteCategoryAsync(int id)
    {
        await inner.DeleteCategoryAsync(id);
        EvictCache();
    }

    private void EvictCache()
    {
        cache.RemoveByPrefix(CacheKeys.Categories.Prefix);
        cache.RemoveByPrefix(CacheKeys.Products.Prefix);
    }
}

