using WebBanHang.Api.DTOs.Roles;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services.Caching;

public class CachedRoleService(
    RoleService inner,
    ICacheService cache) : IRoleService
{
    public Task<List<ModulePermissionsDto>> GetAllPermissionsGroupedAsync()
        => cache.GetOrCreateAsync(
            CacheKeys.Roles.Permissions(),
            () => inner.GetAllPermissionsGroupedAsync(),
            absoluteExpiration: CacheDurations.Roles.PermissionsAbsolute,
            slidingExpiration: CacheDurations.Roles.PermissionsSliding,
            prefix: CacheKeys.Roles.Prefix);

    public Task<List<RoleDto>> GetRolesAsync()
        => cache.GetOrCreateAsync(
            CacheKeys.Roles.All(),
            () => inner.GetRolesAsync(),
            absoluteExpiration: CacheDurations.Roles.RolesAbsolute,
            slidingExpiration: CacheDurations.Roles.RolesSliding,
            prefix: CacheKeys.Roles.Prefix);

    public Task<RoleDetailDto> GetRoleByIdAsync(string roleId)
        => cache.GetOrCreateAsync(
            CacheKeys.Roles.Detail(roleId),
            () => inner.GetRoleByIdAsync(roleId),
            absoluteExpiration: CacheDurations.Roles.DetailAbsolute,
            slidingExpiration: CacheDurations.Roles.DetailSliding,
            prefix: CacheKeys.Roles.Prefix);

    public async Task<RoleDetailDto> CreateRoleAsync(CreateRoleDto dto)
    {
        var result = await inner.CreateRoleAsync(dto);
        cache.RemoveByPrefix(CacheKeys.Roles.Prefix);
        return result;
    }

    public async Task<RoleDetailDto> UpdateRoleAsync(string roleId, UpdateRoleDto dto)
    {
        var result = await inner.UpdateRoleAsync(roleId, dto);
        cache.RemoveByPrefix(CacheKeys.Roles.Prefix);
        return result;
    }

    public async Task<RoleDetailDto> AssignPermissionsToRoleAsync(string roleId, List<string> permissionIds)
    {
        var result = await inner.AssignPermissionsToRoleAsync(roleId, permissionIds);
        cache.RemoveByPrefix(CacheKeys.Roles.Prefix);
        return result;
    }

    public async Task DeleteRoleAsync(string roleId)
    {
        await inner.DeleteRoleAsync(roleId);
        cache.RemoveByPrefix(CacheKeys.Roles.Prefix);
    }
}

