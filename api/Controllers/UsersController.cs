using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý người dùng và tài khoản hệ thống (Users)
/// </summary>
[Tags("Users")]
public class UsersController(IUserService userService) : BaseApiController
{ 
    /// <summary>
    /// Lấy danh sách người dùng có phân trang và bộ lọc vai trò, trạng thái khóa
    /// </summary>
    /// <param name="filter">Bộ lọc danh sách người dùng</param>
    [HttpGet]
    [HasPermission(AppPermissions.Users.View)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<UserDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetUsers([FromQuery] UserQueryFilter filter)
    {
        var result = await userService.GetUsersAsync(filter);
        return Success(result, "Lấy danh sách người dùng thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một tài khoản người dùng theo ID
    /// </summary>
    /// <param name="id">Mã ID người dùng</param>
    [HttpGet("{id:int}")]
    [HasPermission(AppPermissions.Users.View)]
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
    /// Tạo mới tài khoản người dùng hoặc nhân viên với vai trò cụ thể
    /// </summary>
    /// <param name="dto">Thông tin tài khoản và danh sách vai trò gán</param>
    [HttpPost]
    [HasPermission(AppPermissions.Users.Create)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserRequestDto dto)
    {
        var result = await userService.CreateUserAsync(CurrentUserId, dto);
        return CreatedSuccess(result, "Tạo mới tài khoản người dùng thành công.");
    }

    /// <summary>
    /// Khóa hoặc Mở khóa tài khoản người dùng
    /// </summary>
    /// <param name="id">Mã ID người dùng</param>
    /// <param name="dto">Trạng thái khóa cụ thể (hoặc để trống để toggle đảo ngược)</param>
    [HttpPatch("{id:int}/toggle-lock")]
    [HasPermission(AppPermissions.Users.Lock)]
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
    /// Cập nhật vai trò / phân quyền người dùng
    /// </summary>
    /// <param name="id">Mã ID người dùng</param>
    /// <param name="dto">Mã vai trò mới hoặc danh sách vai trò</param>
    [HttpPatch("{id:int}/role")]
    [HasPermission(AppPermissions.Users.AssignRoles)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateRole(int id, [FromBody] UpdateRoleRequestDto dto)
    {
        var result = await userService.UpdateRoleAsync(CurrentUserId, id, dto);
        return Success(result, "Cập nhật vai trò người dùng thành công.");
    }

    /// <summary>
    /// Người dùng tự cập nhật thông tin cá nhân (Profile)
    /// </summary>
    /// <param name="dto">Thông tin cá nhân cập nhật</param>
    [Authorize]
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
    /// [Admin / CRM Manager] Báo cáo phân tích nhân khẩu học khách hàng (Độ tuổi và Sở thích công nghệ - Barem III.4.1)
    /// </summary>
    [HttpGet("demographics")]
    [HasPermission(AppPermissions.Users.View)]
    [ProducesResponseType(typeof(ApiResponse<DemographicsReportDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetDemographicsReport()
    {
        var result = await userService.GetDemographicsReportAsync();
        return Success(result, "Lấy báo cáo phân tích nhân khẩu học khách hàng thành công.");
    }
}
