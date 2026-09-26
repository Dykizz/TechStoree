using System.Text.Json.Serialization;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.Vouchers;

/// <summary>
/// DTO tóm tắt thông tin voucher (dùng cho danh sách phân trang phía Admin và Client)
/// </summary>
public class VoucherBaseDto
{
    public int VoucherId { get; set; }

    /// <example>CELLPHONES100K</example>
    public string Code { get; set; } = string.Empty;

    /// <example>Giảm 100K cho đơn hàng từ 2 triệu</example>
    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    /// <summary>
    /// Loại giảm giá: PERCENTAGE hoặc FIXED_AMOUNT
    /// </summary>
    /// <example>FIXED_AMOUNT</example>
    public DiscountType DiscountType { get; set; } = DiscountType.PERCENTAGE;

    /// <example>100000</example>
    public decimal DiscountValue { get; set; }

    /// <example>2000000</example>
    public decimal MinOrderValue { get; set; }

    /// <example>500000</example>
    public decimal? MaxDiscountAmount { get; set; }

    /// <summary>
    /// Tổng lượt sử dụng tối đa của toàn sàn (null = không giới hạn)
    /// </summary>
    /// <example>500</example>
    public int? UsageLimit { get; set; }

    /// <summary>
    /// Số lượt đã được khách hàng sử dụng thực tế
    /// </summary>
    /// <example>12</example>
    public int UsedCount { get; set; }

    /// <summary>
    /// Giới hạn số lần dùng tối đa của mỗi tài khoản
    /// </summary>
    /// <example>1</example>
    public int LimitPerUser { get; set; } = 1;

    public DateTime StartDate { get; set; }

    public DateTime EndDate { get; set; }

    public bool IsActive { get; set; }
    
    /// <summary>
    /// Hiển thị công khai (true = công khai trên sàn; false = voucher ẩn/khảo sát/quà tặng riêng)
    /// </summary>
    /// <example>true</example>
    public bool IsPublic { get; set; } = true;

    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Trạng thái thời gian: UPCOMING, ACTIVE, EXPIRED
    /// </summary>
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public VoucherCampaignStatus Status { get; set; }
}

/// <summary>
/// DTO chi tiết voucher (kèm thống kê số lượng đã được lưu vào ví)
/// </summary>
public class VoucherDetailDto : VoucherBaseDto
{
    /// <summary>
    /// Tổng số khách hàng đã thu thập / được tặng voucher này vào ví
    /// </summary>
    public int TotalClaimedCount { get; set; }
}
