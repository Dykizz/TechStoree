using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Auth;

public class RegisterRequestDto
{
    /// <summary>
    /// Tên đăng nhập duy nhất (3 đến 50 ký tự)
    /// </summary>
    /// <example>nguyenvana</example>
    [Required(ErrorMessage = "Tên đăng nhập không được để trống")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Tên đăng nhập phải từ 3 đến 50 ký tự")]
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Mật khẩu tài khoản (tối thiểu 6 ký tự)
    /// </summary>
    /// <example>Password@123</example>
    [Required(ErrorMessage = "Mật khẩu không được để trống")]
    [MinLength(6, ErrorMessage = "Mật khẩu phải có độ dài tối thiểu 6 ký tự")]
    public string Password { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email liên hệ duy nhất
    /// </summary>
    /// <example>user@example.com</example>
    [Required(ErrorMessage = "Email không được để trống")]
    [EmailAddress(ErrorMessage = "Email không đúng định dạng")]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Họ và tên đầy đủ của người dùng
    /// </summary>
    /// <example>Người Dùng Thử Nghiệm</example>
    [Required(ErrorMessage = "Họ và tên không được để trống")]
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại liên hệ
    /// </summary>
    /// <example>0987654321</example>
    public string? Phone { get; set; }

    /// <summary>
    /// Ngày tháng năm sinh (định dạng ISO-8601)
    /// </summary>
    /// <example>2000-01-15T00:00:00Z</example>
    public DateTime? DateOfBirth { get; set; }

    /// <summary>
    /// Sở thích công nghệ (Gaming, Văn phòng, Studio, Smarthome)
    /// </summary>
    /// <example>Gaming</example>
    public string? TechInterest { get; set; }

    /// <summary>
    /// Địa chỉ cư trú
    /// </summary>
    /// <example>TP. Hồ Chí Minh</example>
    public string? Address { get; set; }
}
