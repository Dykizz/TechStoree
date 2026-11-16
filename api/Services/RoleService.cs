using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Roles;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class RoleService(AppDbContext context, PermissionCatalogState catalogState) : IRoleService
{
    /// <summary>
    /// Vai trò Quản trị viên: Cho phép tùy chỉnh phân quyền để phù hợp với phân nhiệm doanh nghiệp.
    /// </summary>
    private static bool IsProtectedAdmin(Role role) => false;

    /// <summary>
    /// Ánh xạ thực thể Permission sang DTO kèm thông tin ngữ cảnh lấy từ danh mục chuẩn:
    /// quyền đang được bao nhiêu endpoint sử dụng và có phải quyền Reserved hay không.
    /// </summary>
    private PermissionDto ToPermissionDto(Permission permission)
    {
        var snapshot = catalogState.Snapshot;
        var endpoints = snapshot?.EndpointsOf(permission.PermissionId) ?? Array.Empty<string>();

        return new PermissionDto
        {
            PermissionId = permission.PermissionId,
            PermissionName = permission.PermissionName,
            Module = permission.Module,
            Description = permission.Description,
            IsReserved = snapshot?.IsReserved(permission.PermissionId) ?? false,
            EndpointCount = endpoints.Count,
            Endpoints = endpoints.ToList()
        };
    }

    /// <summary>
    /// Chuẩn hoá và kiểm tra danh sách mã quyền trước khi gán cho vai trò.
    /// Ném <see cref="BadRequestException"/> nếu có mã không tồn tại hoặc đã ngừng sử dụng,
    /// thay vì âm thầm bỏ qua khiến Quản trị viên tưởng đã gán quyền thành công.
    /// </summary>
    private async Task<List<string>> ResolvePermissionsAsync(IEnumerable<string>? requested)
    {
        var clean = (requested ?? [])
            .Where(p => !string.IsNullOrWhiteSpace(p))
            .Select(p => p.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (clean.Count == 0)
        {
            return [];
        }

        // Đọc toàn bộ rồi so khớp trong bộ nhớ để tránh sai lệch collation của PostgreSQL.
        var known = await context.Permissions
            .AsNoTracking()
            .Select(p => p.PermissionId)
            .ToListAsync();

        var knownSet = new HashSet<string>(known, StringComparer.OrdinalIgnoreCase);

        var unknown = clean.Where(p => !knownSet.Contains(p)).ToList();
        if (unknown.Count > 0)
        {
            throw new BadRequestException($"Các quyền không tồn tại trong hệ thống: {string.Join(", ", unknown)}.");
        }

        // Quyền đã bị xoá khỏi danh mục chuẩn trong mã nguồn (ngừng sử dụng) thì không cho gán mới.
        var legacy = clean.Where(p => !AppPermissions.ById.ContainsKey(p)).ToList();
        if (legacy.Count > 0)
        {
            throw new BadRequestException(
                $"Các quyền đã ngừng sử dụng, không thể gán cho vai trò: {string.Join(", ", legacy)}.");
        }

        // Tự động bổ sung quyền View phụ thuộc nếu vai trò có bất kỳ quyền thao tác nào trong module đó
        var resolvedSet = new HashSet<string>(clean, StringComparer.OrdinalIgnoreCase);
        foreach (var pid in clean)
        {
            var dotIndex = pid.IndexOf('.');
            if (dotIndex > 0)
            {
                var modulePrefix = pid[..dotIndex];
                var viewPermissionId = $"{modulePrefix}.View";
                if (knownSet.Contains(viewPermissionId) && !resolvedSet.Contains(viewPermissionId))
                {
                    resolvedSet.Add(viewPermissionId);
                }
            }
        }

        // Trả về mã chuẩn lấy từ CSDL để bảo đảm đúng chính tả khoá chính.
        return known.Where(p => resolvedSet.Contains(p, StringComparer.OrdinalIgnoreCase)).ToList();
    }

    public async Task<List<ModulePermissionsDto>> GetAllPermissionsGroupedAsync()
    {
        var activeIds = AppPermissions.ById.Keys.ToList();
        var permissions = await context.Permissions
            .AsNoTracking()
            .Where(p => activeIds.Contains(p.PermissionId))
            .OrderBy(p => p.Module)
            .ThenBy(p => p.PermissionName)
            .ToListAsync();

        return permissions
            .GroupBy(p => p.Module)
            .Select(g => new ModulePermissionsDto
            {
                Module = g.Key,
                Permissions = g.Select(ToPermissionDto).ToList()
            })
            .ToList();
    }

    public async Task<List<RoleDto>> GetAssignableRolesAsync()
    {
        var roles = await context.Roles
            .AsNoTracking()
            .Where(r => r.RoleId.ToUpper() != UserRoleTypeExtensions.User)
            .OrderByDescending(r => r.IsSystem)
            .ThenBy(r => r.RoleName)
            .ToListAsync();

        return roles.Select(r => new RoleDto
        {
            RoleId = r.RoleId,
            RoleName = r.RoleName,
            Description = r.Description,
            IsSystem = r.IsSystem
        }).ToList();
    }

    public async Task<List<UserDto>> GetUsersByRoleAsync(string roleId)
    {
        var normalizedRoleId = roleId.Trim().ToUpperInvariant();

        var roleExists = await context.Roles
            .AsNoTracking()
            .AnyAsync(r => r.RoleId.ToUpper() == normalizedRoleId);
        if (!roleExists)
        {
            throw new NotFoundException($"Không tìm thấy vai trò với mã '{roleId}'.");
        }

        var users = await context.Users
            .AsNoTracking()
            .Include(u => u.Customer)
            .Include(u => u.Employee)
            .Include(u => u.Admin)
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .Where(u => u.UserRoles.Any(ur => ur.RoleId.ToUpper() == normalizedRoleId))
            .OrderBy(u => u.FullName)
            .ToListAsync();

        return users.Select(u => u.ToUserDto()).ToList();
    }

    public async Task<List<RoleDto>> GetRolesAsync()
    {
        var activeIds = AppPermissions.ById.Keys.ToList();
        var allPermIds = await context.Permissions
            .AsNoTracking()
            .Where(p => activeIds.Contains(p.PermissionId))
            .Select(p => p.PermissionId)
            .ToListAsync();

        // Đếm số lượng tài khoản chính xác theo từng vai trò trực tiếp từ bảng user_roles
        var userCountByRole = await context.UserRoles
            .AsNoTracking()
            .GroupBy(ur => ur.RoleId)
            .Select(g => new { RoleId = g.Key, Count = g.Select(x => x.UserId).Distinct().Count() })
            .ToDictionaryAsync(x => x.RoleId, x => x.Count, StringComparer.OrdinalIgnoreCase);

        var roles = await context.Roles
            .AsNoTracking()
            .Include(r => r.RolePermissions)
            .OrderByDescending(r => r.IsSystem)
            .ThenBy(r => r.RoleName)
            .ToListAsync();

        return roles.Select(r => new RoleDto
        {
            RoleId = r.RoleId,
            RoleName = r.RoleName,
            Description = r.Description,
            IsSystem = r.IsSystem,
            UserCount = userCountByRole.TryGetValue(r.RoleId, out var count) ? count : 0,
            Permissions = IsProtectedAdmin(r)
                ? allPermIds
                : r.RolePermissions
                    .Select(rp => rp.PermissionId)
                    .Where(pid => AppPermissions.ById.ContainsKey(pid))
                    .ToList()
        }).ToList();
    }

    public async Task<RoleDetailDto> GetRoleByIdAsync(string roleId)
    {
        var normalizedRoleId = roleId.Trim().ToUpperInvariant();

        var role = await context.Roles
            .AsNoTracking()
            .Include(r => r.RolePermissions)
                .ThenInclude(rp => rp.Permission)
            .FirstOrDefaultAsync(r => r.RoleId.ToUpper() == normalizedRoleId);

        if (role == null)
        {
            throw new NotFoundException($"Không tìm thấy vai trò với mã '{roleId}'.");
        }

        var userCount = await context.UserRoles
            .AsNoTracking()
            .Where(ur => ur.RoleId.ToUpper() == normalizedRoleId)
            .Select(ur => ur.UserId)
            .Distinct()
            .CountAsync();

        if (IsProtectedAdmin(role))
        {
            var activeIds = AppPermissions.ById.Keys.ToList();
            var allPerms = await context.Permissions
                .AsNoTracking()
                .Where(p => activeIds.Contains(p.PermissionId))
                .OrderBy(p => p.Module)
                .ThenBy(p => p.PermissionName)
                .ToListAsync();

            return new RoleDetailDto
            {
                RoleId = role.RoleId,
                RoleName = role.RoleName,
                Description = role.Description ?? "Quản trị viên tối cao: toàn quyền trên toàn hệ thống",
                IsSystem = true,
                UserCount = userCount,
                Permissions = allPerms.Select(p => p.PermissionId).ToList(),
                PermissionDetails = allPerms.Select(ToPermissionDto).ToList()
            };
        }

        return new RoleDetailDto
        {
            RoleId = role.RoleId,
            RoleName = role.RoleName,
            Description = role.Description,
            IsSystem = role.IsSystem,
            UserCount = userCount,
            Permissions = role.RolePermissions
                .Select(rp => rp.PermissionId)
                .Where(pid => AppPermissions.ById.ContainsKey(pid))
                .ToList(),
            PermissionDetails = role.RolePermissions
                .Where(rp => rp.Permission != null && AppPermissions.ById.ContainsKey(rp.PermissionId))
                .Select(rp => ToPermissionDto(rp.Permission!))
                .ToList()
        };
    }

    public async Task<RoleDetailDto> CreateRoleAsync(CreateRoleDto dto)
    {
        var roleName = dto.RoleName.Trim();

        // Chuẩn hoá về chữ hoa để khớp với UserService khi gán vai trò; PostgreSQL so sánh
        // chuỗi phân biệt hoa thường nên GUID chữ thường sẽ không gán được cho tài khoản nào.
        var roleId = string.IsNullOrWhiteSpace(dto.RoleId)
            ? Guid.NewGuid().ToString().ToUpperInvariant()
            : dto.RoleId.Trim().ToUpperInvariant();

        if (await context.Roles.AnyAsync(r => r.RoleId.ToUpper() == roleId))
        {
            throw new ConflictException($"Mã vai trò '{roleId}' đã tồn tại.");
        }

        if (await context.Roles.AnyAsync(r => r.RoleName.ToLower() == roleName.ToLower()))
        {
            throw new ConflictException($"Tên vai trò '{roleName}' đã tồn tại.");
        }

        var newRole = new Role
        {
            RoleId = roleId,
            RoleName = roleName,
            Description = dto.Description?.Trim(),
            IsSystem = false
        };

        foreach (var pid in await ResolvePermissionsAsync(dto.Permissions))
        {
            newRole.RolePermissions.Add(new RolePermission
            {
                RoleId = roleId,
                PermissionId = pid,
                AssignedAt = DateTime.UtcNow
            });
        }

        context.Roles.Add(newRole);
        await context.SaveChangesAsync();

        return await GetRoleByIdAsync(roleId);
    }

    private static List<string> EnsureAdminSafetyPermissions(Role role, IEnumerable<string>? requestedPermissions)
    {
        var list = (requestedPermissions ?? [])
            .Where(p => !string.IsNullOrWhiteSpace(p))
            .ToList();

        if (role.RoleId.Equals(UserRoleTypeExtensions.Admin, StringComparison.OrdinalIgnoreCase))
        {
            var set = new HashSet<string>(list, StringComparer.OrdinalIgnoreCase)
            {
                AppPermissions.Roles.View,
                AppPermissions.Roles.Update
            };
            return set.ToList();
        }

        return list;
    }

    private async Task ReplaceRolePermissionsAsync(Role role, IEnumerable<string>? requestedPermissions)
    {
        var safeguarded = EnsureAdminSafetyPermissions(role, requestedPermissions);
        var resolved = await ResolvePermissionsAsync(safeguarded);

        context.RolePermissions.RemoveRange(role.RolePermissions);
        role.RolePermissions.Clear();

        foreach (var pid in resolved)
        {
            role.RolePermissions.Add(new RolePermission
            {
                RoleId = role.RoleId,
                PermissionId = pid,
                AssignedAt = DateTime.UtcNow
            });
        }
    }

    public async Task<RoleDetailDto> UpdateRoleAsync(string roleId, UpdateRoleDto dto)
    {
        var normalizedRoleId = roleId.Trim().ToUpperInvariant();

        var role = await context.Roles
            .Include(r => r.RolePermissions)
            .FirstOrDefaultAsync(r => r.RoleId.ToUpper() == normalizedRoleId);

        if (role == null)
        {
            throw new NotFoundException($"Không tìm thấy vai trò với mã '{roleId}'.");
        }

        var roleName = dto.RoleName.Trim();
        if (await context.Roles.AnyAsync(r => r.RoleId != role.RoleId && r.RoleName.ToLower() == roleName.ToLower()))
        {
            throw new ConflictException($"Tên vai trò '{roleName}' đã được sử dụng.");
        }

        role.RoleName = roleName;
        role.Description = dto.Description?.Trim();

        if (!IsProtectedAdmin(role))
        {
            await ReplaceRolePermissionsAsync(role, dto.Permissions);
        }

        await context.SaveChangesAsync();
        return await GetRoleByIdAsync(role.RoleId);
    }

    public async Task<RoleDetailDto> AssignPermissionsToRoleAsync(string roleId, List<string> permissionIds)
    {
        var normalizedRoleId = roleId.Trim().ToUpperInvariant();

        var role = await context.Roles
            .Include(r => r.RolePermissions)
            .FirstOrDefaultAsync(r => r.RoleId.ToUpper() == normalizedRoleId);

        if (role == null)
        {
            throw new NotFoundException($"Không tìm thấy vai trò với mã '{roleId}'.");
        }

        if (IsProtectedAdmin(role))
        {
            throw new BadRequestException("Không thể chỉnh sửa danh sách quyền hạn của Quản trị viên tối cao (ADMIN).");
        }

        await ReplaceRolePermissionsAsync(role, permissionIds);

        await context.SaveChangesAsync();
        return await GetRoleByIdAsync(role.RoleId);
    }

    public async Task DeleteRoleAsync(string roleId)
    {
        var normalizedRoleId = roleId.Trim().ToUpperInvariant();

        var role = await context.Roles
            .Include(r => r.UserRoles)
            .FirstOrDefaultAsync(r => r.RoleId.ToUpper() == normalizedRoleId);

        if (role == null)
        {
            throw new NotFoundException($"Không tìm thấy vai trò với mã '{roleId}'.");
        }

        if (role.IsSystem)
        {
            throw new BadRequestException("Không thể xóa vai trò mặc định của hệ thống.");
        }

        if (role.UserRoles.Count > 0)
        {
            throw new BadRequestException($"Không thể xóa vai trò '{role.RoleName}' vì đang có {role.UserRoles.Count} người dùng sở hữu vai trò này.");
        }

        context.Roles.Remove(role);
        await context.SaveChangesAsync();
    }
}
