using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.DTOs.Auth;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

public class AuthController(IAuthService authService) : BaseApiController
{
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto dto)
    {
        var result = await authService.RegisterAsync(dto);
        return CreatedSuccess(result, "Đăng ký tài khoản thành công!");
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto dto)
    {
        var result = await authService.LoginAsync(dto);
        SetRefreshTokenCookie(result.RefreshToken);
        return Success(result, "Đăng nhập thành công!");
    }

    [HttpPost("refresh-token")]
    public async Task<IActionResult> RefreshToken([FromBody(EmptyBodyBehavior = Microsoft.AspNetCore.Mvc.ModelBinding.EmptyBodyBehavior.Allow)] RefreshTokenRequestDto? dto = null)
    {
        var refreshToken = Request.Cookies["refreshToken"] ?? dto?.RefreshToken;
        var result = await authService.RefreshTokenAsync(refreshToken);
        SetRefreshTokenCookie(result.RefreshToken);
        return Success(result, "Làm mới phiên đăng nhập thành công!");
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        await authService.RevokeTokenAsync(CurrentUserId);
        Response.Cookies.Delete("refreshToken");
        return Success("Đăng xuất thành công!");
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetProfile()
    {
        var result = await authService.GetCurrentUserProfileAsync(CurrentUserId);
        return Success(result, "Lấy thông tin tài khoản thành công!");
    }

    private void SetRefreshTokenCookie(string refreshToken)
    {
        var cookieOptions = new CookieOptions
        {
            HttpOnly = true,
            Expires = DateTime.UtcNow.AddDays(7),
            Secure = false,
            SameSite = SameSiteMode.Lax,
            Path = "/"
        };

        Response.Cookies.Append("refreshToken", refreshToken, cookieOptions);
    }
}
