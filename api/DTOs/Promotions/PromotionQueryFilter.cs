using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.Promotions;

/// <summary>
/// Bộ lọc tìm kiếm danh sách chương trình khuyến mãi
/// </summary>
public class PromotionQueryFilter : IValidatableObject
{
    /// <summary>
    /// Lọc theo trạng thái bật/tắt của Quản trị viên (true: đang bật, false: đã tắt)
    /// </summary>
    /// <example>true</example>
    public bool? IsActive { get; set; }

    /// <summary>
    /// Lọc theo trạng thái thời gian: UPCOMING (sắp diễn ra), ACTIVE (đang chạy), EXPIRED (đã kết thúc)
    /// </summary>
    /// <example>ACTIVE</example>
    public PromotionStatus? Status { get; set; }

    /// <summary>
    /// Lọc các khuyến mãi có hiệu lực từ ngày (ISO-8601 hoặc YYYY-MM-DD)
    /// </summary>
    /// <example>2026-09-01T00:00:00Z</example>
    public DateTime? FromDate { get; set; }

    /// <summary>
    /// Lọc các khuyến mãi có hiệu lực đến ngày (ISO-8601 hoặc YYYY-MM-DD)
    /// </summary>
    /// <example>2026-10-31T23:59:59Z</example>
    public DateTime? ToDate { get; set; }

    /// <summary>
    /// Tìm kiếm theo tên hoặc mô tả chương trình khuyến mãi
    /// </summary>
    /// <example>Flash Sale</example>
    public string? Search { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (FromDate.HasValue && ToDate.HasValue && ToDate.Value < FromDate.Value)
        {
            yield return new ValidationResult(
                "Thời gian kết thúc (ToDate) phải lớn hơn hoặc bằng thời gian bắt đầu (FromDate).",
                [nameof(ToDate), nameof(FromDate)]);
        }
    }
}
