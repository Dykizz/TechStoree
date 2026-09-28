using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.Vouchers;

/// <summary>
/// DTO biểu diễn một voucher nằm trong ví cá nhân của khách hàng
/// </summary>
public class UserVoucherItemDto
{
    public int UserVoucherId { get; set; }

    public int VoucherId { get; set; }

    /// <example>CELLPHONES100K</example>
    public string Code { get; set; } = string.Empty;

    /// <example>Giảm 100K cho đơn từ 2 triệu</example>
    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    /// <example>FIXED_AMOUNT</example>
    public DiscountType DiscountType { get; set; } = DiscountType.PERCENTAGE;

    /// <example>100000</example>
    public decimal DiscountValue { get; set; }

    /// <example>2000000</example>
    public decimal MinOrderValue { get; set; }

    /// <example>500000</example>
    public decimal? MaxDiscountAmount { get; set; }

    public DateTime StartDate { get; set; }

    public DateTime EndDate { get; set; }

    /// <summary>
    /// Nguồn gốc voucher trong ví: CLAIMED, ADMIN_GIFT, SURVEY_REWARD
    /// </summary>
    /// <example>CLAIMED</example>
    public VoucherAssignedType AssignedType { get; set; } = VoucherAssignedType.CLAIMED;

    public DateTime AssignedAt { get; set; }

    public bool IsUsed { get; set; }

    public DateTime? UsedAt { get; set; }

    public int? OrderId { get; set; }

    /// <summary>
    /// Trạng thái voucher có thể dùng được ngay bây giờ hay không (chưa dùng và đang trong thời gian hiệu lực)
    /// </summary>
    /// <example>true</example>
    public bool IsUsable { get; set; }
}

