using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Phân khúc sở thích công nghệ chuẩn của khách hàng trong hệ thống CRM
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum TechInterestType
{
    /// <summary>
    /// Gaming &amp; Đồ họa hiệu năng cao (Laptop Gaming, Chuột, Bàn phím cơ, Màn hình tần số quét cao)
    /// </summary>
    GAMING,

    /// <summary>
    /// Văn phòng &amp; Học tập (Laptop mỏng nhẹ, Chuột công thái học, Bút trình chiếu)
    /// </summary>
    OFFICE_STUDY,

    /// <summary>
    /// Âm thanh &amp; Studio sáng tạo (Tai nghe chống ồn, Loa Bluetooth, Micro thu âm)
    /// </summary>
    AUDIO_STUDIO,

    /// <summary>
    /// Lập trình &amp; Trí tuệ nhân tạo (Workstation, Màn hình kép, Thiết bị AI &amp; Server cá nhân)
    /// </summary>
    CODING_AI,

    /// <summary>
    /// Đồng hồ thông minh &amp; Sức khỏe (Smartwatch, Vòng đeo thông minh, Cân điện tử)
    /// </summary>
    SMARTWATCH_HEALTH,

    /// <summary>
    /// Nhiếp ảnh &amp; Sáng tạo nội dung (Camera, Gimbal, Phụ kiện quay phim, Flycam)
    /// </summary>
    PHOTOGRAPHY_VIDEO,

    /// <summary>
    /// Nhà thông minh SmartHome (Robot hút bụi, Loa trợ lý ảo, Camera, Đèn cảm ứng)
    /// </summary>
    SMARTHOME,

    /// <summary>
    /// Nhu cầu công nghệ khác
    /// </summary>
    OTHER
}

public static class TechInterestTypeExtensions
{
    public static (string DisplayName, string Description) GetMetadata(this TechInterestType type) => type switch
    {
        TechInterestType.GAMING => (
            "Gaming & Đồ họa",
            "Laptop Gaming, Chuột/Bàn phím cơ, Màn hình tần số quét cao"
        ),
        TechInterestType.OFFICE_STUDY => (
            "Văn phòng & Học tập",
            "Laptop mỏng nhẹ, Chuột công thái học, Bút trình chiếu"
        ),
        TechInterestType.AUDIO_STUDIO => (
            "Âm thanh & Studio",
            "Tai nghe chống ồn, Loa Bluetooth, Micro thu âm"
        ),
        TechInterestType.CODING_AI => (
            "Lập trình & Trí tuệ nhân tạo (AI)",
            "Workstation, Màn hình kép, Thiết bị AI & Server cá nhân"
        ),
        TechInterestType.SMARTWATCH_HEALTH => (
            "Đồng hồ thông minh & Sức khỏe",
            "Smartwatch, Vòng đeo thông minh, Cân sức khỏe điện tử"
        ),
        TechInterestType.PHOTOGRAPHY_VIDEO => (
            "Nhiếp ảnh & Quay phim",
            "Camera, Gimbal, Flycam, Đèn livestream & Phụ kiện quay"
        ),
        TechInterestType.SMARTHOME => (
            "Nhà thông minh (SmartHome)",
            "Robot hút bụi, Loa trợ lý ảo, Camera, Đèn cảm ứng"
        ),
        _ => (
            "Nhu cầu khác",
            "Các nhu cầu thiết bị công nghệ phổ thông khác"
        )
    };
}
