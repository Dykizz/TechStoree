using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Hình thức làm việc của nhân viên trong doanh nghiệp:
/// FULL_TIME: Nhân viên chính thức làm việc toàn thời gian (hưởng lương cơ bản hàng tháng)
/// PART_TIME: Nhân viên làm việc bán thời gian theo ca (tính công theo mức giờ)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum EmploymentType
{
    FULL_TIME,
    PART_TIME
}
