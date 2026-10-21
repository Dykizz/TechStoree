using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Reviews;

/// <summary>
/// Lớp cơ sở dùng chung cho việc tạo mới và cập nhật đánh giá (DRY Principle)
/// </summary>
public abstract class BaseReviewUpsertDto : IValidatableObject
{
    /// <summary>
    /// Số sao đánh giá từ 1.0 đến 5.0 (bước nhảy 0.5: 1.0, 1.5, 2.0, ..., 5.0)
    /// </summary>
    /// <example>5.0</example>
    [Range(1.0, 5.0, ErrorMessage = "Số sao đánh giá phải từ 1.0 đến 5.0")]
    public decimal Rating { get; set; }

    /// <summary>
    /// Nội dung nhận xét chi tiết
    /// </summary>
    /// <example>Sản phẩm rất tốt, đóng gói cẩn thận và giao hàng nhanh chóng!</example>
    [MaxLength(1000, ErrorMessage = "Nội dung đánh giá không được vượt quá 1000 ký tự")]
    public string? Comment { get; set; }

    /// <summary>
    /// Danh sách URL hình ảnh chụp sản phẩm thực tế
    /// </summary>
    /// <example>["https://res.cloudinary.com/techstore/image/upload/v1/reviews/unbox_1.jpg"]</example>
    public List<string> ImageUrls { get; set; } = new();

    public virtual IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        // Kiểm tra bước nhảy 0.5 sao
        if ((Rating * 10) % 5 != 0)
        {
            yield return new ValidationResult(
                "Số sao đánh giá phải có bước nhảy là 0.5 (ví dụ: 1.0, 1.5, 2.0, ..., 5.0).",
                new[] { nameof(Rating) }
            );
        }
    }
}
