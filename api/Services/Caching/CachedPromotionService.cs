using WebBanHang.Api.DTOs.Promotions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services.Caching;

public class CachedPromotionService(
    PromotionService inner,
    ICacheService cache) : IPromotionService
{
    public Task<IEnumerable<PromotionBaseDto>> GetAllPromotionsAsync(PromotionQueryFilter? filter = null)
        => cache.GetOrCreateAsync(
            CacheKeys.Promotions.List(filter),
            () => inner.GetAllPromotionsAsync(filter),
            absoluteExpiration: CacheDurations.Promotions.Absolute,
            slidingExpiration: CacheDurations.Promotions.Sliding,
            prefix: CacheKeys.Promotions.Prefix);

    public Task<PromotionDetailDto?> GetPromotionByIdAsync(int id)
        => cache.GetOrCreateAsync(
            CacheKeys.Promotions.Detail(id),
            () => inner.GetPromotionByIdAsync(id),
            absoluteExpiration: CacheDurations.Promotions.Absolute,
            slidingExpiration: CacheDurations.Promotions.Sliding,
            prefix: CacheKeys.Promotions.Prefix);

    public async Task<PromotionDetailDto> CreatePromotionAsync(PromotionUpsertRequestDto request)
    {
        var result = await inner.CreatePromotionAsync(request);
        EvictCache();
        return result;
    }

    public async Task<PromotionDetailDto?> UpdatePromotionAsync(int id, PromotionUpsertRequestDto request)
    {
        var result = await inner.UpdatePromotionAsync(id, request);
        EvictCache();
        return result;
    }

    public async Task<bool?> ToggleActiveAsync(int id)
    {
        var result = await inner.ToggleActiveAsync(id);
        EvictCache();
        return result;
    }

    public async Task<bool> DeletePromotionAsync(int id)
    {
        var result = await inner.DeletePromotionAsync(id);
        EvictCache();
        return result;
    }

    private void EvictCache()
    {
        cache.RemoveByPrefix(CacheKeys.Promotions.Prefix);
        cache.RemoveByPrefix(CacheKeys.Products.Prefix);
    }
}

