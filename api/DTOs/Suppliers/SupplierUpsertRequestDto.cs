using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Suppliers;

public class SupplierUpsertRequestDto
{
    /// <summary>
    /// Tên công ty hoặc doanh nghiệp nhà cung cấp
    /// </summary>
    /// <example>Công ty TNHH Logitech Việt Nam</example>
    [Required(ErrorMessage = "Tên nhà cung cấp không được để trống.")]
    [MaxLength(150, ErrorMessage = "Tên nhà cung cấp tối đa 150 ký tự.")]
    public string SupplierName { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại liên hệ
    /// </summary>
    /// <example>02838234567</example>
    [Required(ErrorMessage = "Số điện thoại không được để trống.")]
    [MaxLength(20, ErrorMessage = "Số điện thoại tối đa 20 ký tự.")]
    [Phone(ErrorMessage = "Số điện thoại không đúng định dạng.")]
    public string Phone { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email liên hệ
    /// </summary>
    /// <example>contact@logitech.vn</example>
    [EmailAddress(ErrorMessage = "Email không đúng định dạng.")]
    [MaxLength(100, ErrorMessage = "Email tối đa 100 ký tự.")]
    public string? Email { get; set; }

    /// <summary>
    /// Địa chỉ văn phòng / kho hàng
    /// </summary>
    /// <example>Tòa nhà Bitexco, Q.1, TP.HCM</example>
    [MaxLength(255, ErrorMessage = "Địa chỉ tối đa 255 ký tự.")]
    public string? Address { get; set; }
}
