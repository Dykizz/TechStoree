using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Hình thức cấp voucher vào ví người dùng:
/// CLAIMED (Khách tự lưu), ADMIN_GIFT (Quản trị viên tặng), SURVEY_REWARD (Thưởng hoàn thành khảo sát CRM)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum VoucherAssignedType
{
    /// <summary>
    /// Khách hàng chủ động thu thập / lưu voucher từ sàn
    /// </summary>
    CLAIMED,

    /// <summary>
    /// Được Quản trị viên / Hệ thống CRM gửi tặng riêng
    /// </summary>
    ADMIN_GIFT,

    /// <summary>
    /// Phần thưởng sau khi hoàn thành bài khảo sát ý kiến khách hàng
    /// </summary>
    SURVEY_REWARD
}
