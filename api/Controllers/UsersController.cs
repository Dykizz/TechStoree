using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

public class UsersController(IUserService userService) : BaseApiController
{ 
    [Authorize(Roles = "ADMIN")]
    [HttpGet]
    public async Task<IActionResult> GetUsers([FromQuery] UserQueryFilter filter)
    {
        var result = await userService.GetUsersAsync(filter);
        return Success(result, "Lấy danh sách người dùng thành công.");
    }

    [Authorize(Roles = "ADMIN")]
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetUserById(int id)
    {
        var result = await userService.GetUserByIdAsync(id);
        return Success(result, "Lấy thông tin người dùng thành công.");
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPatch("{id:int}/toggle-lock")]
    public async Task<IActionResult> ToggleLock(int id, [FromBody(EmptyBodyBehavior = Microsoft.AspNetCore.Mvc.ModelBinding.EmptyBodyBehavior.Allow)] ToggleLockRequestDto? dto = null)
    {
        var result = await userService.ToggleLockAsync(id, dto);
        var message = result.IsLocked ? "Đã khóa tài khoản thành công." : "Đã mở khóa tài khoản thành công.";
        return Success(result, message);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPatch("{id:int}/role")]
    public async Task<IActionResult> UpdateRole(int id, [FromBody] UpdateRoleRequestDto dto)
    {
        var result = await userService.UpdateRoleAsync(id, dto);
        return Success(result, "Cập nhật vai trò người dùng thành công.");
    }

    [Authorize]
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequestDto dto)
    {
        var result = await userService.UpdateProfileAsync(CurrentUserId, dto);
        return Success(result, "Cập nhật thông tin cá nhân thành công.");
    }
}
