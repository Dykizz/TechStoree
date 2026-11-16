using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Endpoint tương thích cho người dùng hệ thống (ủy quyền kiểm tra chặt theo quyền Customers.* / Employees.*)
/// </summary>
[Authorize]
[Tags("Users")]
public class UsersController(IUserService userService) : BaseApiController
{
    private static bool IsCustomerTarget(UserDto user)
    {
        return user.UserType == UserType.CUSTOMER &&
               user.Roles.Count > 0 &&
               user.Roles.All(r => string.Equals(r, UserRoleTypeExtensions.User, StringComparison.OrdinalIgnoreCase));
    }

    /// <summary>
    /// Lấy danh sách người dùng có phân trang và bộ lọc (tự động kiểm đúng quyền Employees.View hoặc Customers.View)
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<UserDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetUsers([FromQuery] UserQueryFilter filter)
    {
        if (filter.IsStaffOnly == true)
        {
            if (!HasPermission(AppPermissions.Employees.View)) return Forbid();
        }
        else if (filter.IsStaffOnly == false)
        {
            if (!HasPermission(AppPermissions.Customers.View)) return Forbid();
        }
        else if (!HasPermission(AppPermissions.Employees.View) || !HasPermission(AppPermissions.Customers.View))
        {
            return Forbid();
        }

        var result = await userService.GetUsersAsync(filter, CurrentUserId);
        return Success(result, "Lấy danh sách người dùng thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một tài khoản người dùng theo ID
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetUserById(int id)
    {
        var result = await userService.GetUserByIdAsync(id);
        var requiredPermission = IsCustomerTarget(result)
            ? AppPermissions.Customers.View
            : AppPermissions.Employees.View;

        if (!HasPermission(requiredPermission))
        {
            return Forbid();
        }

        return Success(result, "Lấy thông tin người dùng thành công.");
    }

    /// <summary>
    /// Tạo mới tài khoản người dùng hoặc nhân viên với vai trò cụ thể
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserRequestDto dto)
    {
        var isCustomerCreate = dto.Roles == null || dto.Roles.Count == 0 ||
            dto.Roles.All(r => string.Equals(r?.Trim(), UserRoleTypeExtensions.User, StringComparison.OrdinalIgnoreCase));

        var requiredPermission = isCustomerCreate
            ? AppPermissions.Customers.Create
            : AppPermissions.Employees.Create;

        if (!HasPermission(requiredPermission))
        {
            return Forbid();
        }

        var result = await userService.CreateUserAsync(CurrentUserId, dto);
        return CreatedSuccess(result, "Tạo mới tài khoản người dùng thành công.");
    }

    /// <summary>
    /// Cập nhật thông tin tài khoản người dùng (tách chặt quyền Update và AssignRoles)
    /// </summary>
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserRequestDto dto)
    {
        var existing = await userService.GetUserByIdAsync(id);
        var isCustomer = IsCustomerTarget(existing);

        var requiredUpdatePerm = isCustomer
            ? AppPermissions.Customers.Update
            : AppPermissions.Employees.Update;

        if (!HasPermission(requiredUpdatePerm))
        {
            return Forbid();
        }

        // Chặn lén đổi vai trò qua PUT nếu không có quyền Employees.AssignRoles
        if (dto.Roles != null)
        {
            var currentSet = existing.Roles.Select(r => r.Trim().ToUpperInvariant()).ToHashSet();
            var requestedSet = dto.Roles.Where(r => !string.IsNullOrWhiteSpace(r))
                .Select(r => r.Trim().ToUpperInvariant())
                .ToHashSet();

            if (!currentSet.SetEquals(requestedSet))
            {
                if (!HasPermission(AppPermissions.Employees.AssignRoles))
                {
                    return Forbid();
                }
            }
            else
            {
                dto.Roles = null;
            }
        }

        var result = await userService.UpdateUserAsync(CurrentUserId, id, dto);
        return Success(result, "Cập nhật thông tin người dùng thành công.");
    }

    /// <summary>
    /// Khóa hoặc Mở khóa tài khoản người dùng
    /// </summary>
    [HttpPatch("{id:int}/toggle-lock")]
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

        var existing = await userService.GetUserByIdAsync(id);
        var requiredLockPerm = IsCustomerTarget(existing)
            ? AppPermissions.Customers.Lock
            : AppPermissions.Employees.Lock;

        if (!HasPermission(requiredLockPerm))
        {
            return Forbid();
        }

        var result = await userService.ToggleLockAsync(id, dto);
        var message = result.IsLocked ? "Đã khóa tài khoản thành công." : "Đã mở khóa tài khoản thành công.";
        return Success(result, message);
    }

    /// <summary>
    /// Cập nhật vai trò / phân quyền nhân viên
    /// </summary>
    [HttpPatch("{id:int}/role")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateRole(int id, [FromBody] UpdateRoleRequestDto dto)
    {
        if (!HasPermission(AppPermissions.Employees.AssignRoles))
        {
            return Forbid();
        }

        var result = await userService.UpdateRoleAsync(CurrentUserId, id, dto);
        return Success(result, "Cập nhật vai trò người dùng thành công.");
    }

    /// <summary>
    /// Người dùng tự cập nhật thông tin cá nhân (Profile)
    /// </summary>
    [HttpPut("profile")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequestDto dto)
    {
        var result = await userService.UpdateProfileAsync(CurrentUserId, dto);
        return Success(result, "Cập nhật thông tin cá nhân thành công.");
    }

    /// <summary>
    /// Lấy danh mục sở thích công nghệ chuẩn hóa (Phục vụ khảo sát khách hàng &amp; CRM)
    /// </summary>
    [HttpGet("tech-interests")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<TechInterestOptionDto>>), StatusCodes.Status200OK)]
    public IActionResult GetTechInterests()
    {
        var result = userService.GetTechInterests();
        return Success(result, "Lấy danh mục sở thích công nghệ thành công.");
    }

    /// <summary>
    /// [Admin / CRM Manager] Báo cáo phân tích nhân khẩu học khách hàng
    /// </summary>
    [HttpGet("demographics")]
    [ProducesResponseType(typeof(ApiResponse<DemographicsReportDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetDemographicsReport()
    {
        if (!HasPermission(AppPermissions.Customers.View))
        {
            return Forbid();
        }

        var result = await userService.GetDemographicsReportAsync();
        return Success(result, "Lấy báo cáo phân tích nhân khẩu học khách hàng thành công.");
    }
}
