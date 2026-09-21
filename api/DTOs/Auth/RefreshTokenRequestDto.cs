namespace WebBanHang.Api.DTOs.Auth;

public class RefreshTokenRequestDto
{
    /// <summary>
    /// Refresh token gửi lên từ Body (dành cho Desktop / Mobile)
    /// Nếu để trống, Backend sẽ kiểm tra trong HttpOnly Cookie (dành cho Web)
    /// </summary>
    public string? RefreshToken { get; set; }
}
