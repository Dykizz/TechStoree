using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Auth;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Xác thực và Phiên đăng nhập (Authentication)
/// </summary>
[Tags("Authentication")]
public class AuthController(IAuthService authService) : BaseApiController
{
    /// <summary>
    /// Đăng ký tài khoản người dùng mới (Role mặc định là USER)
    /// </summary>
    /// <param name="dto">Thông tin đăng ký (Username, Password, Email, Họ tên, SĐT, Ngày sinh, Sở thích)</param>
    [HttpPost("register")]
    [ProducesResponseType(typeof(ApiResponse<UserInfoDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto dto)
    {
        var result = await authService.RegisterAsync(dto);
        return CreatedSuccess(result, "Đăng ký tài khoản thành công!");
    }

    /// <summary>
    /// Đăng nhập hệ thống (Email + Password)
    /// </summary>
    /// <param name="dto">Thông tin đăng nhập</param>
    [HttpPost("login")]
    [ProducesResponseType(typeof(ApiResponse<LoginResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto dto)
    {
        var result = await authService.LoginAsync(dto);
        SetRefreshTokenCookie(result.RefreshToken);
        return Success(result, "Đăng nhập thành công!");
    }

    /// <summary>
    /// Làm mới Access Token bằng Refresh Token (qua Cookie hoặc Body)
    /// </summary>
    /// <param name="dto">Refresh token (nếu không dùng HttpOnly Cookie)</param>
    [HttpPost("refresh-token")]
    [ProducesResponseType(typeof(ApiResponse<LoginResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RefreshToken([FromBody(EmptyBodyBehavior = Microsoft.AspNetCore.Mvc.ModelBinding.EmptyBodyBehavior.Allow)] RefreshTokenRequestDto? dto = null)
    {
        var refreshToken = Request.Cookies["refreshToken"] ?? dto?.RefreshToken;
        var result = await authService.RefreshTokenAsync(refreshToken);
        SetRefreshTokenCookie(result.RefreshToken);
        return Success(result, "Làm mới phiên đăng nhập thành công!");
    }

    /// <summary>
    /// Đăng xuất và thu hồi Refresh Token
    /// </summary>
    [Authorize]
    [HttpPost("logout")]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Logout()
    {
        await authService.RevokeTokenAsync(CurrentUserId);
        Response.Cookies.Delete("refreshToken");
        return Success("Đăng xuất thành công!");
    }

    /// <summary>
    /// Lấy thông tin tài khoản hiện tại từ Access Token (JWT)
    /// </summary>
    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType(typeof(ApiResponse<UserInfoDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
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
