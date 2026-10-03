using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Các phân khúc nhóm độ tuổi khách hàng chuẩn hóa trong hệ thống CRM (Barem III.4.1)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum CustomerAgeGroupType
{
    /// <summary>
    /// Khách hàng dưới 18 tuổi (&lt; 18)
    /// </summary>
    UNDER_18,

    /// <summary>
    /// Khách hàng từ 18 đến 24 tuổi
    /// </summary>
    AGE_18_TO_24,

    /// <summary>
    /// Khách hàng từ 25 đến 35 tuổi
    /// </summary>
    AGE_25_TO_35,

    /// <summary>
    /// Khách hàng trên 35 tuổi (&gt; 35)
    /// </summary>
    OVER_35
}

public static class CustomerAgeGroupTypeExtensions
{
    public static string GetDisplayName(this CustomerAgeGroupType group) => group switch
    {
        CustomerAgeGroupType.UNDER_18 => "Dưới 18 tuổi",
        CustomerAgeGroupType.AGE_18_TO_24 => "18 - 24 tuổi",
        CustomerAgeGroupType.AGE_25_TO_35 => "25 - 35 tuổi",
        CustomerAgeGroupType.OVER_35 => "Trên 35 tuổi",
        _ => "Không xác định"
    };

    public static CustomerAgeGroupType FromAge(int age) => age switch
    {
        < 18 => CustomerAgeGroupType.UNDER_18,
        <= 24 => CustomerAgeGroupType.AGE_18_TO_24,
        <= 35 => CustomerAgeGroupType.AGE_25_TO_35,
        _ => CustomerAgeGroupType.OVER_35
    };
}
