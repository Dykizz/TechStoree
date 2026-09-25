namespace WebBanHang.Api.DTOs.Auth;

public class LoginResponseDto
{
    /// <summary>
    /// JSON Web Token (JWT) dùng để xác thực các request kế tiếp (gửi qua Header Authorization: Bearer {token})
    /// </summary>
    /// <example>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...</example>
    public string Token { get; set; } = string.Empty;

    /// <summary>
    /// Chuỗi mã Refresh Token dùng để gia hạn phiên đăng nhập
    /// </summary>
    /// <example>7c9e6679-7425-40de-944b-e07fc1f90ae7</example>
    public string RefreshToken { get; set; } = string.Empty;

    /// <summary>
    /// Thông tin cơ bản của người dùng đang đăng nhập
    /// </summary>
    public BasicUserDto User { get; set; } = new();
}
