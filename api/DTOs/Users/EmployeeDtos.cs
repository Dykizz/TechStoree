using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Common;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.DTOs.Users;

/// <summary>
/// Bộ lọc truy vấn danh sách nhân viên nội bộ.
/// </summary>
public class EmployeeQueryFilter : PaginationParams
{
    public string? Role { get; set; }
    public bool? IsLocked { get; set; }
    public EmploymentType? EmploymentType { get; set; }
}

/// <summary>
/// Dữ liệu tạo mới tài khoản nhân viên nội bộ.
/// </summary>
public class CreateEmployeeRequestDto
{
    [Required(ErrorMessage = "Tên đăng nhập không được để trống.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Tên đăng nhập phải từ 3 đến 50 ký tự.")]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email không được để trống.")]
    [EmailAddress(ErrorMessage = "Định dạng email không hợp lệ.")]
    [MaxLength(100)]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu không được để trống.")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự.")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "Họ và tên không được để trống.")]
    [MaxLength(100)]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(15)]
    public string? Phone { get; set; }

    [MaxLength(20, ErrorMessage = "Mã nhân viên tối đa 20 ký tự.")]
    public string? EmployeeCode { get; set; }

    public EmploymentType? EmploymentType { get; set; }

    [Range(0, 1000000000, ErrorMessage = "Lương cơ bản không hợp lệ.")]
    public decimal? BaseSalary { get; set; }

    [Range(0, 10000000, ErrorMessage = "Tiền công theo giờ không hợp lệ.")]
    public decimal? HourlyRate { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn ít nhất một vai trò cho nhân viên.")]
    [MinLength(1, ErrorMessage = "Vui lòng chọn ít nhất một vai trò cho nhân viên.")]
    public List<string> Roles { get; set; } = [];
}

/// <summary>
/// Dữ liệu cập nhật thông tin nhân viên (không bao gồm đổi vai trò hay trạng thái khóa).
/// </summary>
public class UpdateEmployeeRequestDto
{
    [Required(ErrorMessage = "Họ và tên không được để trống.")]
    [MaxLength(100, ErrorMessage = "Họ và tên tối đa 100 ký tự.")]
    public string FullName { get; set; } = string.Empty;

    [EmailAddress(ErrorMessage = "Định dạng email không hợp lệ.")]
    [MaxLength(100, ErrorMessage = "Email tối đa 100 ký tự.")]
    public string? Email { get; set; }

    [MaxLength(15, ErrorMessage = "Số điện thoại tối đa 15 ký tự.")]
    public string? Phone { get; set; }

    [StringLength(100, MinimumLength = 6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự.")]
    public string? Password { get; set; }

    [MaxLength(20, ErrorMessage = "Mã nhân viên tối đa 20 ký tự.")]
    public string? EmployeeCode { get; set; }

    public EmploymentType? EmploymentType { get; set; }

    [Range(0, 1000000000, ErrorMessage = "Lương cơ bản không hợp lệ.")]
    public decimal? BaseSalary { get; set; }

    [Range(0, 10000000, ErrorMessage = "Tiền công theo giờ không hợp lệ.")]
    public decimal? HourlyRate { get; set; }
}
