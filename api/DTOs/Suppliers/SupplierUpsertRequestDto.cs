using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Suppliers;

public class SupplierUpsertRequestDto
{
    [Required(ErrorMessage = "Tên nhà cung cấp không được để trống.")]
    [MaxLength(150, ErrorMessage = "Tên nhà cung cấp tối đa 150 ký tự.")]
    public string SupplierName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Số điện thoại không được để trống.")]
    [MaxLength(20, ErrorMessage = "Số điện thoại tối đa 20 ký tự.")]
    [Phone(ErrorMessage = "Số điện thoại không đúng định dạng.")]
    public string Phone { get; set; } = string.Empty;

    [EmailAddress(ErrorMessage = "Email không đúng định dạng.")]
    [MaxLength(100, ErrorMessage = "Email tối đa 100 ký tự.")]
    public string? Email { get; set; }

    [MaxLength(255, ErrorMessage = "Địa chỉ tối đa 255 ký tự.")]
    public string? Address { get; set; }
}
