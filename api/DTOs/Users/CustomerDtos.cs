using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Users;

/// <summary>
/// Bộ lọc truy vấn danh sách khách hàng (phạm vi CRM, chỉ lấy tài khoản khách hàng).
/// </summary>
public class CustomerQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc theo trạng thái tài khoản: true (bị khóa), false (đang hoạt động)
    /// </summary>
    /// <example>false</example>
    public bool? IsLocked { get; set; }

    /// <summary>
    /// Lọc theo sở thích công nghệ (Enum key hoặc nhãn tiếng Việt; dùng NOT_SET để lọc chưa cập nhật)
    /// </summary>
    /// <example>GAMING</example>
    public string? TechInterest { get; set; }
}

/// <summary>
/// Dữ liệu tạo mới tài khoản khách hàng từ phân hệ CRM / Quản lý khách hàng.
/// </summary>
public class CreateCustomerRequestDto
{
    /// <summary>
    /// Tên tài khoản đăng nhập (Duy nhất)
    /// </summary>
    /// <example>khachhang02</example>
    [Required(ErrorMessage = "Tên đăng nhập không được để trống.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Tên đăng nhập phải từ 3 đến 50 ký tự.")]
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email (Duy nhất)
    /// </summary>
    /// <example>khachhang02@gmail.com</example>
    [Required(ErrorMessage = "Email không được để trống.")]
    [EmailAddress(ErrorMessage = "Định dạng email không hợp lệ.")]
    [MaxLength(100)]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Mật khẩu khởi tạo
    /// </summary>
    /// <example>MatKhau123@</example>
    [Required(ErrorMessage = "Mật khẩu không được để trống.")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự.")]
    public string Password { get; set; } = string.Empty;

    /// <summary>
    /// Họ và tên khách hàng
    /// </summary>
    /// <example>Nguyễn Văn Khách</example>
    [Required(ErrorMessage = "Họ và tên không được để trống.")]
    [MaxLength(100)]
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại liên hệ
    /// </summary>
    /// <example>0987654321</example>
    [MaxLength(15)]
    public string? Phone { get; set; }

    /// <summary>
    /// Ngày sinh
    /// </summary>
    /// <example>1998-05-20T00:00:00Z</example>
    public DateTime? DateOfBirth { get; set; }

    /// <summary>
    /// Sở thích công nghệ
    /// </summary>
    /// <example>GAMING</example>
    [MaxLength(100, ErrorMessage = "Sở thích công nghệ tối đa 100 ký tự.")]
    public string? TechInterest { get; set; }

    /// <summary>
    /// Địa chỉ cư trú / giao hàng
    /// </summary>
    /// <example>Quận 1, TP. Hồ Chí Minh</example>
    [MaxLength(255, ErrorMessage = "Địa chỉ tối đa 255 ký tự.")]
    public string? Address { get; set; }
}

/// <summary>
/// Dữ liệu cập nhật hồ sơ khách hàng từ phân hệ CRM / Quản lý khách hàng.
/// </summary>
public class UpdateCustomerRequestDto
{
    /// <summary>
    /// Họ và tên khách hàng
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
    /// Mật khẩu mới (nếu muốn đổi mật khẩu; để trống nếu giữ nguyên)
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
    /// <example>GAMING</example>
    [MaxLength(100, ErrorMessage = "Sở thích công nghệ tối đa 100 ký tự.")]
    public string? TechInterest { get; set; }

    /// <summary>
    /// Địa chỉ cư trú / giao hàng
    /// </summary>
    /// <example>Quận 1, TP. Hồ Chí Minh</example>
    [MaxLength(255, ErrorMessage = "Địa chỉ tối đa 255 ký tự.")]
    public string? Address { get; set; }
}
