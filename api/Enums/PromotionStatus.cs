using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Trạng thái thời gian của chương trình khuyến mãi:
/// UPCOMING (Sắp diễn ra), ACTIVE (Đang diễn ra), EXPIRED (Đã kết thúc)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum PromotionStatus
{
    UPCOMING,
    ACTIVE,
    EXPIRED
}
