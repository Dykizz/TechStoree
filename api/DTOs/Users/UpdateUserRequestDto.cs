using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.DTOs.Users;

public class UpdateUserRequestDto
{
    /// <summary>
    /// Họ và tên người dùng / nhân viên
    /// </summary>
    /// <example>Nguyễn Văn A</example>
    [Required(ErrorMessage = "Họ và tên không được để trống.")]
    [MaxLength(100, ErrorMessage = "Họ và tên tối đa 100 ký tự.")]
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email (Duy nhất)
    /// </summary>
    /// <example>user@techstoree.vn</example>
    [EmailAddress(ErrorMessage = "Định dạng email không hợp lệ.")]
    [MaxLength(100, ErrorMessage = "Email tối đa 100 ký tự.")]
    public string? Email { get; set; }

    /// <summary>
    /// Số điện thoại liên hệ
    /// </summary>
    /// <example>0987654321</example>
    [MaxLength(15, ErrorMessage = "Số điện thoại tối đa 15 ký tự.")]
    public string? Phone { get; set; }

    /// <summary>
    /// Mật khẩu mới (nếu muốn đổi mật khẩu; để trống nếu giữ nguyên mật khẩu cũ)
    /// </summary>
    /// <example>MatKhau123@</example>
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự.")]
    public string? Password { get; set; }

    /// <summary>
    /// Ngày sinh (ISO-8601)
    /// </summary>
    /// <example>1998-05-20T00:00:00Z</example>
    public DateTime? DateOfBirth { get; set; }

    /// <summary>
    /// Sở thích công nghệ
    /// </summary>
    /// <example>Laptop</example>
    [MaxLength(100, ErrorMessage = "Sở thích công nghệ tối đa 100 ký tự.")]
    public string? TechInterest { get; set; }

    /// <summary>
    /// Địa chỉ cư trú
    /// </summary>
    /// <example>Quận 1, TP. Hồ Chí Minh</example>
    [MaxLength(255, ErrorMessage = "Địa chỉ tối đa 255 ký tự.")]
    public string? Address { get; set; }

    /// <summary>
    /// Mã nhân viên (nếu là nhân viên)
    /// </summary>
    /// <example>NV001</example>
    [MaxLength(20, ErrorMessage = "Mã nhân viên tối đa 20 ký tự.")]
    public string? EmployeeCode { get; set; }

    /// <summary>
    /// Hình thức làm việc: FULL_TIME hoặc PART_TIME
    /// </summary>
    /// <example>FULL_TIME</example>
    public EmploymentType? EmploymentType { get; set; }

    /// <summary>
    /// Lương cơ bản hàng tháng (Áp dụng cho nhân viên Full-time)
    /// </summary>
    /// <example>8000000</example>
    [Range(0, 1000000000, ErrorMessage = "Lương cơ bản không hợp lệ.")]
    public decimal? BaseSalary { get; set; }

    /// <summary>
    /// Tiền công theo giờ (Áp dụng cho nhân viên Part-time)
    /// </summary>
    /// <example>30000</example>
    [Range(0, 10000000, ErrorMessage = "Tiền công theo giờ không hợp lệ.")]
    public decimal? HourlyRate { get; set; }

    /// <summary>
    /// Danh sách vai trò mới (tùy chọn; nếu truyền sẽ cập nhật vai trò tài khoản)
    /// </summary>
    /// <example>["SALES_STAFF"]</example>
    public List<string>? Roles { get; set; }
}
