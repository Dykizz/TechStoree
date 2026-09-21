namespace WebBanHang.Api.DTOs.Auth;

public class LoginResponseDto
{
    public string Token { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public BasicUserDto User { get; set; } = new();
}
