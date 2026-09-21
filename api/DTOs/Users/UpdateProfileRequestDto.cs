using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Users;

public class UpdateProfileRequestDto
{
    [Required(ErrorMessage = "Họ và tên không được để trống.")]
    [MaxLength(100, ErrorMessage = "Họ và tên tối đa 100 ký tự.")]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(15, ErrorMessage = "Số điện thoại tối đa 15 ký tự.")]
    public string? Phone { get; set; }

    public DateTime? DateOfBirth { get; set; }

    [MaxLength(100, ErrorMessage = "Sở thích công nghệ tối đa 100 ký tự.")]
    public string? TechInterest { get; set; }

    [MaxLength(255, ErrorMessage = "Địa chỉ tối đa 255 ký tự.")]
    public string? Address { get; set; }
}
