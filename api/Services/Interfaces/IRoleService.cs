using WebBanHang.Api.DTOs.Roles;

namespace WebBanHang.Api.Services.Interfaces;

public interface IRoleService
{
    Task<List<ModulePermissionsDto>> GetAllPermissionsGroupedAsync();
    Task<List<RoleDto>> GetRolesAsync();
    Task<RoleDetailDto> GetRoleByIdAsync(string roleId);
    Task<RoleDetailDto> CreateRoleAsync(CreateRoleDto dto);
    Task<RoleDetailDto> UpdateRoleAsync(string roleId, UpdateRoleDto dto);
    Task<RoleDetailDto> AssignPermissionsToRoleAsync(string roleId, List<string> permissionIds);
    Task DeleteRoleAsync(string roleId);
}
