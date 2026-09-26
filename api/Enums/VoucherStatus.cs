using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Trạng thái thời gian của chiến dịch Voucher:
/// UPCOMING (Sắp diễn ra), ACTIVE (Đang diễn ra), EXPIRED (Đã kết thúc)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum VoucherCampaignStatus
{
    UPCOMING,
    ACTIVE,
    EXPIRED
}

/// <summary>
/// Trạng thái voucher trong ví của khách hàng:
/// USABLE (Khả dụng, chưa dùng và trong hạn), USED (Đã sử dụng), EXPIRED (Đã hết hạn chưa dùng)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum UserVoucherWalletStatus
{
    USABLE,
    USED,
    EXPIRED
}
