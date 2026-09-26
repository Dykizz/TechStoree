using WebBanHang.Api.DTOs.Auth;

namespace WebBanHang.Api.Services.Interfaces;

public interface IAuthService
{
    Task<UserInfoDto> RegisterAsync(RegisterRequestDto dto);
    Task<LoginResponseDto> LoginAsync(LoginRequestDto dto);
    Task<LoginResponseDto> RefreshTokenAsync(string? refreshToken);
    Task RevokeTokenAsync(int userId);
    Task<UserInfoDto> GetCurrentUserProfileAsync(int userId);
}
