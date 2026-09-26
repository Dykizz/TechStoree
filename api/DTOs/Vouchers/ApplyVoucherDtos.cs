using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.Vouchers;

/// <summary>
/// Request áp dụng voucher tại giỏ hàng
/// </summary>
public class ApplyVoucherRequestDto
{
    /// <summary>
    /// Mã code giảm giá do khách nhập hoặc chọn từ ví
    /// </summary>
    /// <example>CELLPHONES100K</example>
    [Required(ErrorMessage = "Mã voucher không được để trống.")]
    public string Code { get; set; } = string.Empty;

    /// <summary>
    /// Tổng tiền hàng trước khi áp voucher (VNĐ)
    /// </summary>
    /// <example>2500000</example>
    [Required(ErrorMessage = "Tổng giá trị đơn hàng không được để trống.")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Tổng giá trị đơn hàng phải lớn hơn 0.")]
    public decimal SubtotalAmount { get; set; }
}

/// <summary>
/// Kết quả áp dụng voucher trả về cho giỏ hàng
/// </summary>
public class ApplyVoucherResponseDto
{
    /// <summary>
    /// Cho biết mã có hợp lệ và được áp dụng thành công hay không
    /// </summary>
    /// <example>true</example>
    public bool IsValid { get; set; } = true;

    /// <example>Áp dụng mã giảm giá thành công.</example>
    public string Message { get; set; } = string.Empty;

    /// <example>1</example>
    public int VoucherId { get; set; }

    /// <example>CELLPHONES100K</example>
    public string Code { get; set; } = string.Empty;

    /// <example>Giảm 100K cho đơn từ 2 triệu</example>
    public string Title { get; set; } = string.Empty;

    /// <example>FIXED_AMOUNT</example>
    public DiscountType DiscountType { get; set; } = DiscountType.PERCENTAGE;

    /// <example>100000</example>
    public decimal DiscountValue { get; set; }

    /// <summary>
    /// Số tiền được giảm giá thực tế (VNĐ)
    /// </summary>
    /// <example>100000</example>
    public decimal DiscountAmount { get; set; }

    /// <summary>
    /// Tổng tiền thanh toán cuối cùng sau khi trừ khuyến mãi voucher
    /// </summary>
    /// <example>2400000</example>
    public decimal FinalTotal { get; set; }
}
