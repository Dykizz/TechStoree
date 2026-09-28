using WebBanHang.Api.Common;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.Vouchers;

/// <summary>
/// Bộ lọc danh sách Voucher (Admin)
/// </summary>
public class VoucherQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc theo trạng thái thời gian: UPCOMING, ACTIVE, EXPIRED
    /// </summary>
    /// <example>ACTIVE</example>
    public VoucherCampaignStatus? Status { get; set; }

    /// <summary>
    /// Lọc theo trạng thái bật / tắt kích hoạt do Admin thiết lập
    /// </summary>
    /// <example>true</example>
    public bool? IsActive { get; set; }

    /// <summary>
    /// Lọc theo hiển thị công khai (true) hoặc ẩn (false)
    /// </summary>
    /// <example>true</example>
    public bool? IsPublic { get; set; }

    /// <summary>
    /// Lọc các voucher còn hiệu lực từ ngày này trở đi
    /// </summary>
    public DateTime? FromDate { get; set; }

    /// <summary>
    /// Lọc các voucher có hiệu lực trước ngày này
    /// </summary>
    public DateTime? ToDate { get; set; }
}
