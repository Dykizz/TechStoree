namespace WebBanHang.Api.Common;

/// <summary>
/// Chuẩn hóa mốc thời gian DateTime về UTC khi truy vấn/lưu trữ và sang giờ Việt Nam (+07:00) khi xuất văn bản.
/// </summary>
public static class DateTimeHelper
{
    private static readonly TimeZoneInfo VietnamTimeZone = ResolveVietnamTimeZone();

    /// <summary>
    /// Quy đổi DateTime đầu vào về UTC chuẩn (giữ nguyên instant nếu đã có múi giờ thay vì ghi đè nhãn).
    /// </summary>
    public static DateTime NormalizeToUtc(DateTime value)
    {
        return value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };
    }

    public static DateTime? NormalizeToUtc(DateTime? value)
        => value.HasValue ? NormalizeToUtc(value.Value) : null;

    /// <summary>
    /// Chuẩn hóa mốc bắt đầu bộ lọc (FromDate) về UTC.
    /// </summary>
    public static DateTime NormalizeFilterFromUtc(DateTime fromDate)
        => NormalizeToUtc(fromDate);

    /// <summary>
    /// Chuẩn hóa mốc kết thúc bộ lọc (ToDate) về UTC.
    /// Nếu đầu vào là ngày thuần không kèm múi giờ/giờ (Unspecified tại 00:00:00), mở rộng tới cuối ngày UTC đó.
    /// </summary>
    public static DateTime NormalizeFilterToUtc(DateTime toDate)
    {
        if (toDate.Kind == DateTimeKind.Unspecified && toDate.TimeOfDay == TimeSpan.Zero)
        {
            return DateTime.SpecifyKind(toDate.Date.AddDays(1).AddMicroseconds(-1), DateTimeKind.Utc);
        }

        return NormalizeToUtc(toDate);
    }

    /// <summary>
    /// Quy đổi DateTime UTC (hoặc Unspecified coi là UTC) sang giờ Việt Nam (+07:00) để hiển thị/xuất báo cáo.
    /// </summary>
    public static DateTime ToVietnamTime(DateTime value)
    {
        var utc = NormalizeToUtc(value);
        return TimeZoneInfo.ConvertTimeFromUtc(utc, VietnamTimeZone);
    }

    public static int GetVietnamCurrentYear()
        => ToVietnamTime(DateTime.UtcNow).Year;

    private static TimeZoneInfo ResolveVietnamTimeZone()
    {
        foreach (var id in new[] { "Asia/Ho_Chi_Minh", "SE Asia Standard Time" })
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById(id);
            }
            catch (TimeZoneNotFoundException)
            {
            }
            catch (InvalidTimeZoneException)
            {
            }
        }

        return TimeZoneInfo.CreateCustomTimeZone(
            "ICT",
            TimeSpan.FromHours(7),
            "Indochina Time",
            "Indochina Time");
    }
}

