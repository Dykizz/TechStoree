namespace WebBanHang.Api.DTOs.Surveys;

/// <summary>
/// Bộ lọc tra cứu danh sách khảo sát phía Admin
/// </summary>
public class SurveyQueryFilter
{
    /// <summary>
    /// Từ khóa tìm kiếm theo tiêu đề hoặc mô tả bài khảo sát
    /// </summary>
    /// <example>Sony</example>
    public string? Search { get; set; }

    /// <summary>
    /// Lọc theo trạng thái hoạt động (true = đang mở nhận phản hồi, false = đã đóng, null = tất cả)
    /// </summary>
    /// <example>true</example>
    public bool? IsActive { get; set; }

    /// <summary>
    /// Lọc khảo sát có voucher thưởng hay không
    /// </summary>
    /// <example>true</example>
    public bool? HasReward { get; set; }
}
