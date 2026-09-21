using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Auth;

public class RegisterRequestDto
{
    [Required(ErrorMessage = "Tên đăng nhập không được để trống")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Tên đăng nhập phải từ 3 đến 50 ký tự")]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu không được để trống")]
    [MinLength(6, ErrorMessage = "Mật khẩu phải có độ dài tối thiểu 6 ký tự")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email không được để trống")]
    [EmailAddress(ErrorMessage = "Email không đúng định dạng")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Họ và tên không được để trống")]
    public string FullName { get; set; } = string.Empty;

    public string? Phone { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? TechInterest { get; set; } // Gaming, Văn phòng, Studio, Smarthome
    public string? Address { get; set; }
}
