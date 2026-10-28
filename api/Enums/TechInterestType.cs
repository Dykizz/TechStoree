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

    /// <summary>
    /// Danh sách các từ khóa đặc trưng nhận diện cho từng phân khúc sở thích (hỗ trợ phân nhóm khảo sát và CRM)
    /// </summary>
    public static List<string> GetKeywords(this TechInterestType type)
    {
        var (displayName, _) = type.GetMetadata();
        var keywords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            type.ToString().ToLowerInvariant(),
            displayName.ToLowerInvariant()
        };

        switch (type)
        {
            case TechInterestType.GAMING:
                keywords.Add("gaming");
                keywords.Add("game");
                keywords.Add("đồ họa");
                break;
            case TechInterestType.OFFICE_STUDY:
                keywords.Add("office_study");
                keywords.Add("văn phòng");
                keywords.Add("học tập");
                keywords.Add("office");
                break;
            case TechInterestType.AUDIO_STUDIO:
                keywords.Add("audio_studio");
                keywords.Add("âm thanh");
                keywords.Add("studio");
                keywords.Add("audio");
                keywords.Add("tai nghe");
                keywords.Add("loa");
                break;
            case TechInterestType.CODING_AI:
                keywords.Add("coding_ai");
                keywords.Add("lập trình");
                keywords.Add("ai");
                keywords.Add("coding");
                keywords.Add("trí tuệ nhân tạo");
                break;
            case TechInterestType.SMARTWATCH_HEALTH:
                keywords.Add("smartwatch_health");
                keywords.Add("smartwatch");
                keywords.Add("sức khỏe");
                keywords.Add("health");
                keywords.Add("đồng hồ");
                break;
            case TechInterestType.PHOTOGRAPHY_VIDEO:
                keywords.Add("photography_video");
                keywords.Add("nhiếp ảnh");
                keywords.Add("quay phim");
                keywords.Add("photography");
                keywords.Add("camera");
                break;
            case TechInterestType.SMARTHOME:
                keywords.Add("smarthome");
                keywords.Add("nhà thông minh");
                keywords.Add("gia dụng");
                break;
            case TechInterestType.OTHER:
                keywords.Add("other");
                keywords.Add("khác");
                break;
        }

        return keywords.Select(k => k.ToLowerInvariant().Trim()).ToList();
    }

    /// <summary>
    /// Nhận diện phân khúc sở thích chuẩn hóa từ chuỗi đầu vào bất kỳ (Enum Key, DisplayName hoặc từ khóa)
    /// </summary>
    public static TechInterestType? ParseInterest(string? input)
    {
        if (string.IsNullOrWhiteSpace(input)) return null;

        var clean = input.Trim();

        // 1. Khớp chính xác theo Enum name (ví dụ: "GAMING", "AUDIO_STUDIO")
        if (Enum.TryParse<TechInterestType>(clean, true, out var exactMatch))
        {
            return exactMatch;
        }

        var lower = clean.ToLowerInvariant();

        // 2. Khớp theo DisplayName hoặc từ khóa trong GetKeywords
        foreach (var type in Enum.GetValues<TechInterestType>())
        {
            var meta = type.GetMetadata();
            if (string.Equals(meta.DisplayName, clean, StringComparison.OrdinalIgnoreCase) ||
                lower.Contains(meta.DisplayName.ToLowerInvariant()))
            {
                return type;
            }

            if (type.GetKeywords().Any(k => lower.Contains(k) || k.Contains(lower)))
            {
                return type;
            }
        }

        return null;
    }

    /// <summary>
    /// Trích xuất danh sách từ khóa tìm kiếm cho chuỗi sở thích bất kỳ dựa theo phân khúc chuẩn của TechInterestType
    /// </summary>
    public static List<string> ResolveSearchKeywords(string? input)
    {
        if (string.IsNullOrWhiteSpace(input)) return [];

        var matchedType = ParseInterest(input);
        if (matchedType.HasValue)
        {
            return matchedType.Value.GetKeywords();
        }

        return [input.Trim().ToLowerInvariant()];
    }
}
