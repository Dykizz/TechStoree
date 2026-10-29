using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Vouchers;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services.Caching;

public class CachedVoucherService(
    VoucherService inner,
    ICacheService cache) : IVoucherService
{
    public Task<IEnumerable<VoucherBaseDto>> GetAvailableVouchersAsync()
        => cache.GetOrCreateAsync(
            CacheKeys.Vouchers.Available(),
            () => inner.GetAvailableVouchersAsync(),
            absoluteExpiration: CacheDurations.Vouchers.AvailableAbsolute,
            slidingExpiration: CacheDurations.Vouchers.AvailableSliding,
            prefix: CacheKeys.Vouchers.Prefix);

    public Task<VoucherDetailDto?> GetVoucherByIdAsync(int id)
        => cache.GetOrCreateAsync(
            CacheKeys.Vouchers.Detail(id),
            () => inner.GetVoucherByIdAsync(id),
            absoluteExpiration: CacheDurations.Vouchers.DetailAbsolute,
            slidingExpiration: CacheDurations.Vouchers.DetailSliding,
            prefix: CacheKeys.Vouchers.Prefix);

    public Task<PagedResult<VoucherBaseDto>> GetAllVouchersAsync(VoucherQueryFilter? filter = null)
        => cache.GetOrCreateAsync(
            CacheKeys.Vouchers.List(filter),
            () => inner.GetAllVouchersAsync(filter),
            absoluteExpiration: CacheDurations.Vouchers.ListAbsolute,
            slidingExpiration: CacheDurations.Vouchers.ListSliding,
            prefix: CacheKeys.Vouchers.Prefix);

    public async Task<VoucherDetailDto> CreateVoucherAsync(VoucherUpsertRequestDto request)
    {
        var result = await inner.CreateVoucherAsync(request);
        cache.RemoveByPrefix(CacheKeys.Vouchers.Prefix);
        return result;
    }

    public async Task<VoucherDetailDto?> UpdateVoucherAsync(int id, VoucherUpsertRequestDto request)
    {
        var result = await inner.UpdateVoucherAsync(id, request);
        cache.RemoveByPrefix(CacheKeys.Vouchers.Prefix);
        return result;
    }

    public async Task<bool?> ToggleActiveAsync(int id)
    {
        var result = await inner.ToggleActiveAsync(id);
        cache.RemoveByPrefix(CacheKeys.Vouchers.Prefix);
        return result;
    }

    public async Task<bool> DeleteVoucherAsync(int id)
    {
        var result = await inner.DeleteVoucherAsync(id);
        cache.RemoveByPrefix(CacheKeys.Vouchers.Prefix);
        return result;
    }

    public Task<ApplyVoucherResponseDto> ApplyVoucherAsync(ApplyVoucherRequestDto request, int? userId = null)
        => inner.ApplyVoucherAsync(request, userId);

    public Task<IEnumerable<UserVoucherItemDto>> GetMyVouchersAsync(int userId, UserVoucherWalletStatus? status = null)
        => inner.GetMyVouchersAsync(userId, status);

    public Task<UserVoucherItemDto> ClaimVoucherAsync(int voucherId, int userId)
        => inner.ClaimVoucherAsync(voucherId, userId);

    public Task<UserVoucherItemDto?> AwardVoucherAsync(int voucherId, int userId, VoucherAssignedType assignedType = VoucherAssignedType.SURVEY_REWARD)
        => inner.AwardVoucherAsync(voucherId, userId, assignedType);
}

