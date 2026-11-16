using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Roles;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý hồ sơ Nhân sự nội bộ và Phân vai trò nhân viên (Employees)
/// </summary>
[Route("api/employees")]
[Authorize]
[Tags("Employees")]
public class EmployeesController(IUserService userService, IRoleService roleService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách nhân viên nội bộ có phân trang và bộ lọc
    /// </summary>
    [HttpGet]
    [HasPermission(AppPermissions.Employees.View)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<UserDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetEmployees([FromQuery] EmployeeQueryFilter filter)
    {
        var result = await userService.GetEmployeesAsync(filter);
        return Success(result, "Lấy danh sách nhân viên thành công.");
    }

    /// <summary>
    /// Lấy danh sách vai trò nhân sự dùng để gán cho nhân viên (không yêu cầu quyền Roles.View)
    /// </summary>
    [HttpGet("assignable-roles")]
    [ProducesResponseType(typeof(ApiResponse<List<RoleDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetAssignableRoles()
    {
        if (!HasPermission(AppPermissions.Employees.View) &&
            !HasPermission(AppPermissions.Employees.Create) &&
            !HasPermission(AppPermissions.Employees.AssignRoles))
        {
            return Forbid();
        }

        var result = await roleService.GetAssignableRolesAsync();
        return Success(result, "Lấy danh sách vai trò nhân sự thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một nhân viên theo ID
    /// </summary>
    [HttpGet("{id:int}")]
    [HasPermission(AppPermissions.Employees.View)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetEmployeeById(int id)
    {
        var result = await userService.GetEmployeeByIdAsync(id);
        return Success(result, "Lấy thông tin nhân viên thành công.");
    }

    /// <summary>
    /// Tạo mới tài khoản nhân viên với vai trò cụ thể
    /// </summary>
    [HttpPost]
    [HasPermission(AppPermissions.Employees.Create)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateEmployee([FromBody] CreateEmployeeRequestDto dto)
    {
        var result = await userService.CreateEmployeeAsync(CurrentUserId, dto);
        return CreatedSuccess(result, "Tạo mới tài khoản nhân viên thành công.");
    }

    /// <summary>
    /// Cập nhật thông tin hồ sơ nhân viên (không tự ý đổi vai trò hoặc trạng thái khóa)
    /// </summary>
    [HttpPut("{id:int}")]
    [HasPermission(AppPermissions.Employees.Update)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateEmployee(int id, [FromBody] UpdateEmployeeRequestDto dto)
    {
        var result = await userService.UpdateEmployeeAsync(id, dto);
        return Success(result, "Cập nhật thông tin nhân viên thành công.");
    }

    /// <summary>
    /// Gán hoặc cập nhật vai trò cho nhân viên
    /// </summary>
    [HttpPatch("{id:int}/role")]
    [HasPermission(AppPermissions.Employees.AssignRoles)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateEmployeeRoles(int id, [FromBody] UpdateRoleRequestDto dto)
    {
        var result = await userService.UpdateEmployeeRolesAsync(CurrentUserId, id, dto);
        return Success(result, "Cập nhật vai trò nhân viên thành công.");
    }

    /// <summary>
    /// Khóa hoặc mở khóa tài khoản nhân viên
    /// </summary>
    [HttpPatch("{id:int}/toggle-lock")]
    [HasPermission(AppPermissions.Employees.Lock)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleLock(int id, [FromBody(EmptyBodyBehavior = Microsoft.AspNetCore.Mvc.ModelBinding.EmptyBodyBehavior.Allow)] ToggleLockRequestDto? dto = null)
    {
        if (id == CurrentUserId)
        {
            throw new BadRequestException("Bạn không thể tự khóa tài khoản của chính mình.");
        }

        var result = await userService.ToggleEmployeeLockAsync(id, dto);
        var message = result.IsLocked ? "Đã khóa tài khoản nhân viên thành công." : "Đã mở khóa tài khoản nhân viên thành công.";
        return Success(result, message);
    }
}
