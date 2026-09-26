using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Tài khoản Người dùng và Phân quyền RBAC (Users)
/// </summary>
[Tags("Users")]
public class UsersController(IUserService userService) : BaseApiController
{ 
    /// <summary>
    /// Lấy danh sách người dùng có phân trang và bộ lọc vai trò, trạng thái khóa (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="filter">Bộ lọc danh sách người dùng</param>
    [Authorize(Roles = "ADMIN")]
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<UserDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetUsers([FromQuery] UserQueryFilter filter)
    {
        var result = await userService.GetUsersAsync(filter);
        return Success(result, "Lấy danh sách người dùng thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một tài khoản người dùng theo ID (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID người dùng</param>
    [Authorize(Roles = "ADMIN")]
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetUserById(int id)
    {
        var result = await userService.GetUserByIdAsync(id);
        return Success(result, "Lấy thông tin người dùng thành công.");
    }

    /// <summary>
    /// Khóa hoặc Mở khóa tài khoản người dùng (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID người dùng</param>
    /// <param name="dto">Trạng thái khóa cụ thể (hoặc để trống để toggle đảo ngược)</param>
    [Authorize(Roles = "ADMIN")]
    [HttpPatch("{id:int}/toggle-lock")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleLock(int id, [FromBody(EmptyBodyBehavior = Microsoft.AspNetCore.Mvc.ModelBinding.EmptyBodyBehavior.Allow)] ToggleLockRequestDto? dto = null)
    {
        var result = await userService.ToggleLockAsync(id, dto);
        var message = result.IsLocked ? "Đã khóa tài khoản thành công." : "Đã mở khóa tài khoản thành công.";
        return Success(result, message);
    }

    /// <summary>
    /// Cập nhật vai trò / phân quyền người dùng: ADMIN, USER (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID người dùng</param>
    /// <param name="dto">Mã vai trò mới</param>
    [Authorize(Roles = "ADMIN")]
    [HttpPatch("{id:int}/role")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateRole(int id, [FromBody] UpdateRoleRequestDto dto)
    {
        var result = await userService.UpdateRoleAsync(id, dto);
        return Success(result, "Cập nhật vai trò người dùng thành công.");
    }

    /// <summary>
    /// Cập nhật thông tin hồ sơ của tài khoản hiện tại (Yêu cầu đăng nhập)
    /// </summary>
    /// <param name="dto">Thông tin cập nhật: Họ tên, SĐT, Ngày sinh, Sở thích, Địa chỉ</param>
    [Authorize]
    [HttpPut("profile")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequestDto dto)
    {
        var result = await userService.UpdateProfileAsync(CurrentUserId, dto);
        return Success(result, "Cập nhật thông tin cá nhân thành công.");
    }
}
