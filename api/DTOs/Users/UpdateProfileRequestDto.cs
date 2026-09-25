using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Users;

public class UpdateProfileRequestDto
{
    /// <summary>
    /// Họ và tên cập nhật
    /// </summary>
    /// <example>Nguyễn Văn Anh Cập Nhật</example>
    [Required(ErrorMessage = "Họ và tên không được để trống.")]
    [MaxLength(100, ErrorMessage = "Họ và tên tối đa 100 ký tự.")]
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại liên hệ
    /// </summary>
    /// <example>0988776655</example>
    [MaxLength(15, ErrorMessage = "Số điện thoại tối đa 15 ký tự.")]
    public string? Phone { get; set; }

    /// <summary>
    /// Ngày tháng năm sinh (ISO-8601)
    /// </summary>
    /// <example>2001-08-20T00:00:00Z</example>
    public DateTime? DateOfBirth { get; set; }

    /// <summary>
    /// Sở thích công nghệ (Gaming, Smarthome, Âm thanh, v.v.)
    /// </summary>
    /// <example>Gaming</example>
    [MaxLength(100, ErrorMessage = "Sở thích công nghệ tối đa 100 ký tự.")]
    public string? TechInterest { get; set; }

    /// <summary>
    /// Địa chỉ giao hàng / cư trú
    /// </summary>
    /// <example>456 Nguyễn Huệ, Q.1, TP.HCM</example>
    [MaxLength(255, ErrorMessage = "Địa chỉ tối đa 255 ký tự.")]
    public string? Address { get; set; }
}
