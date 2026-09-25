using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Auth;

public class LoginRequestDto
{
    /// <summary>
    /// Địa chỉ email tài khoản đã đăng ký trong hệ thống
    /// </summary>
    /// <example>tai@example.com</example>
    [Required(ErrorMessage = "Vui lòng nhập địa chỉ email")]
    [EmailAddress(ErrorMessage = "Địa chỉ email không đúng định dạng")]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Mật khẩu tài khoản (tối thiểu 6 ký tự)
    /// </summary>
    /// <example>Password@123</example>
    [Required(ErrorMessage = "Vui lòng nhập mật khẩu")]
    public string Password { get; set; } = string.Empty;
}
