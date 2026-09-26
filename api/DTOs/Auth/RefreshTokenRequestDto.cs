namespace WebBanHang.Api.DTOs.Auth;

public class RefreshTokenRequestDto
{
    /// <summary>
    /// Refresh token gửi lên từ Body (dành cho Desktop / Mobile)
    /// Nếu để trống, Backend sẽ kiểm tra trong HttpOnly Cookie (dành cho Web)
    /// </summary>
    /// <example>7c9e6679-7425-40de-944b-e07fc1f90ae7</example>
    public string? RefreshToken { get; set; }
}
