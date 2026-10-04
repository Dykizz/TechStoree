using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Hình thức nhắm mục tiêu phát bài khảo sát CRM:
/// ALL (Tất cả khách hàng), BY_IDS (Theo danh sách ID chỉ định), BY_INTEREST (Theo phân khúc sở thích công nghệ)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum SurveyTargetType
{
    /// <summary>
    /// Phát bài khảo sát cho toàn bộ khách hàng đang hoạt động trên hệ thống
    /// </summary>
    ALL,

    /// <summary>
    /// Phát bài khảo sát cho danh sách tài khoản khách hàng chỉ định (dựa trên UserIds)
    /// </summary>
    BY_IDS,

    /// <summary>
    /// Phát bài khảo sát theo phân khúc sở thích công nghệ (Gaming, Văn phòng/Học tập, Âm thanh/Studio, SmartHome)
    /// </summary>
    BY_INTEREST
}
