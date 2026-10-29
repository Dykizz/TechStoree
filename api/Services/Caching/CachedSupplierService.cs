using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Suppliers;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services.Caching;

public class CachedSupplierService(
    SupplierService inner,
    ICacheService cache) : ISupplierService
{
    public Task<PagedResult<SupplierDto>> GetSuppliersAsync(SupplierQueryFilter filter)
        => cache.GetOrCreateAsync(
            CacheKeys.Suppliers.List(filter),
            () => inner.GetSuppliersAsync(filter),
            absoluteExpiration: CacheDurations.Suppliers.ListAbsolute,
            slidingExpiration: CacheDurations.Suppliers.ListSliding,
            prefix: CacheKeys.Suppliers.Prefix);

    public Task<SupplierDto> GetSupplierByIdAsync(int id)
        => cache.GetOrCreateAsync(
            CacheKeys.Suppliers.Detail(id),
            () => inner.GetSupplierByIdAsync(id),
            absoluteExpiration: CacheDurations.Suppliers.DetailAbsolute,
            slidingExpiration: CacheDurations.Suppliers.DetailSliding,
            prefix: CacheKeys.Suppliers.Prefix);

    public async Task<SupplierDto> CreateSupplierAsync(SupplierUpsertRequestDto dto)
    {
        var result = await inner.CreateSupplierAsync(dto);
        cache.RemoveByPrefix(CacheKeys.Suppliers.Prefix);
        return result;
    }

    public async Task<SupplierDto> UpdateSupplierAsync(int id, SupplierUpsertRequestDto dto)
    {
        var result = await inner.UpdateSupplierAsync(id, dto);
        cache.RemoveByPrefix(CacheKeys.Suppliers.Prefix);
        return result;
    }

    public async Task DeleteSupplierAsync(int id)
    {
        await inner.DeleteSupplierAsync(id);
        cache.RemoveByPrefix(CacheKeys.Suppliers.Prefix);
    }

    public async Task<SupplierDto> ToggleActiveSupplierAsync(int id)
    {
        var result = await inner.ToggleActiveSupplierAsync(id);
        cache.RemoveByPrefix(CacheKeys.Suppliers.Prefix);
        return result;
    }

    public async Task<SupplierDto> RestoreSupplierAsync(int id)
    {
        var result = await inner.RestoreSupplierAsync(id);
        cache.RemoveByPrefix(CacheKeys.Suppliers.Prefix);
        return result;
    }
}

