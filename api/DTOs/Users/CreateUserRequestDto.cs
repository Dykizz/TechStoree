using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Users;

public class CreateUserRequestDto
{
    /// <summary>
    /// Tên tài khoản đăng nhập (Duy nhất)
    /// </summary>
    /// <example>nhanvien_kho_01</example>
    [Required(ErrorMessage = "Tên đăng nhập không được để trống.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Tên đăng nhập phải từ 3 đến 50 ký tự.")]
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email (Duy nhất)
    /// </summary>
    /// <example>kho01@techstoree.vn</example>
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
    /// Họ và tên người dùng / nhân viên
    /// </summary>
    /// <example>Trần Văn Kho</example>
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
    /// <example>Laptop</example>
    public string? TechInterest { get; set; }

    /// <summary>
    /// Địa chỉ cư trú
    /// </summary>
    /// <example>Quận 1, TP. Hồ Chí Minh</example>
    public string? Address { get; set; }

    /// <summary>
    /// Danh sách các vai trò gán cho tài khoản (Ví dụ: ["WAREHOUSE_STAFF", "SALES_STAFF"]).
    /// Nếu để trống, mặc định sẽ gán vai trò USER.
    /// </summary>
    /// <example>["WAREHOUSE_STAFF"]</example>
    public List<string>? Roles { get; set; }
}
