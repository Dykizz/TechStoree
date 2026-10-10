using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Roles;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Vai trò (Roles) và Quyền hạn (Permissions) trong hệ thống
/// </summary>
[Tags("Role & Permission Management")]
public class RolesController(IRoleService roleService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách tất cả các quyền hạn trong hệ thống (được gom nhóm theo từng Module)
    /// </summary>
    [HttpGet("permissions")]
    [HasPermission(AppPermissions.Roles.View)]
    [ProducesResponseType(typeof(ApiResponse<List<ModulePermissionsDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllPermissions()
    {
        var result = await roleService.GetAllPermissionsGroupedAsync();
        return Success(result, "Lấy danh mục quyền hạn thành công!");
    }

    /// <summary>
    /// Lấy danh sách tất cả vai trò (Role) kèm số lượng người dùng và quyền hạn
    /// </summary>
    [HttpGet]
    [HasPermission(AppPermissions.Roles.View)]
    [ProducesResponseType(typeof(ApiResponse<List<RoleDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRoles()
    {
        var result = await roleService.GetRolesAsync();
        return Success(result, "Lấy danh sách vai trò thành công!");
    }

    /// <summary>
    /// Lấy chi tiết thông tin và quyền hạn của một vai trò
    /// </summary>
    /// <param name="id">Mã định danh vai trò (vd: ADMIN, WAREHOUSE_STAFF, ROLE_KETOAN...)</param>
    [HttpGet("{id}")]
    [HasPermission(AppPermissions.Roles.View)]
    [ProducesResponseType(typeof(ApiResponse<RoleDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetRoleById(string id)
    {
        var result = await roleService.GetRoleByIdAsync(id);
        return Success(result, "Lấy chi tiết vai trò thành công!");
    }

    /// <summary>
    /// Tạo vai trò mới với danh sách quyền hạn tùy chỉnh
    /// </summary>
    /// <param name="dto">Thông tin vai trò (Tên, Mã vai trò tùy chọn, Mô tả, Danh sách mã quyền)</param>
    [HttpPost]
    [HasPermission(AppPermissions.Roles.Create)]
    [ProducesResponseType(typeof(ApiResponse<RoleDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreateRole([FromBody] CreateRoleDto dto)
    {
        var result = await roleService.CreateRoleAsync(dto);
        return CreatedSuccess(result, "Tạo vai trò mới thành công!");
    }

    /// <summary>
    /// Cập nhật thông tin và quyền hạn của một vai trò
    /// </summary>
    /// <param name="id">Mã vai trò cần sửa</param>
    /// <param name="dto">Dữ liệu cập nhật</param>
    [HttpPut("{id}")]
    [HasPermission(AppPermissions.Roles.Update)]
    [ProducesResponseType(typeof(ApiResponse<RoleDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> UpdateRole(string id, [FromBody] UpdateRoleDto dto)
    {
        var result = await roleService.UpdateRoleAsync(id, dto);
        return Success(result, "Cập nhật vai trò thành công!");
    }

    /// <summary>
    /// Gán hoặc cập nhật danh sách quyền hạn (Permissions) cho một vai trò cụ thể
    /// </summary>
    /// <param name="id">Mã vai trò (vd: WAREHOUSE_STAFF, ROLE_KETOAN...)</param>
    /// <param name="dto">Danh sách các mã quyền hạn cần gán</param>
    [HttpPut("{id}/permissions")]
    [HttpPost("{id}/permissions")]
    [HasPermission(AppPermissions.Roles.Update)]
    [ProducesResponseType(typeof(ApiResponse<RoleDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AssignPermissions(string id, [FromBody] AssignPermissionsDto dto)
    {
        var result = await roleService.AssignPermissionsToRoleAsync(id, dto.Permissions);
        return Success(result, "Gán quyền cho vai trò thành công!");
    }

    /// <summary>
    /// Xóa vai trò tùy chỉnh (Không cho phép xóa vai trò hệ thống hoặc vai trò đang có người dùng)
    /// </summary>
    /// <param name="id">Mã vai trò cần xóa</param>
    [HttpDelete("{id}")]
    [HasPermission(AppPermissions.Roles.Delete)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteRole(string id)
    {
        await roleService.DeleteRoleAsync(id);
        return Success("Xóa vai trò thành công!");
    }
}
