using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Promotions;

public class PromotionUpsertRequestDto : IValidatableObject
{
    /// <summary>
    /// Tên chương trình khuyến mãi
    /// </summary>
    /// <example>Flash Sale Cuối Tuần</example>
    [Required(ErrorMessage = "Tên chương trình khuyến mãi không được để trống.")]
    [MaxLength(200, ErrorMessage = "Tên chương trình không được vượt quá 200 ký tự.")]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả chi tiết thể lệ chương trình
    /// </summary>
    /// <example>Giảm 10% cho toàn bộ các dòng tai nghe Sony và bàn phím cơ</example>
    public string? Description { get; set; }

    /// <summary>
    /// Loại giảm giá: "PERCENTAGE" (theo %) hoặc "FIXED_AMOUNT" (theo số tiền cố định)
    /// </summary>
    /// <example>PERCENTAGE</example>
    [Required(ErrorMessage = "Loại giảm giá không được để trống.")]
    [RegularExpression("^(PERCENTAGE|FIXED_AMOUNT)$", ErrorMessage = "Loại giảm giá chỉ chấp nhận PERCENTAGE hoặc FIXED_AMOUNT.")]
    public string DiscountType { get; set; } = "PERCENTAGE";

    /// <summary>
    /// Giá trị giảm: VD 10 nếu là 10%, hoặc 500000 nếu là 500,000 VNĐ
    /// </summary>
    /// <example>10</example>
    [Range(0.01, double.MaxValue, ErrorMessage = "Giá trị giảm giá phải lớn hơn 0.")]
    public decimal DiscountValue { get; set; }

    /// <summary>
    /// Thời gian bắt đầu (UTC)
    /// </summary>
    [Required(ErrorMessage = "Thời gian bắt đầu không được để trống.")]
    public DateTime StartDate { get; set; }

    /// <summary>
    /// Thời gian kết thúc (UTC)
    /// </summary>
    [Required(ErrorMessage = "Thời gian kết thúc không được để trống.")]
    public DateTime EndDate { get; set; }

    /// <summary>
    /// Trạng thái kích hoạt
    /// </summary>
    /// <example>true</example>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Danh sách ID các biến thể áp dụng khuyến mãi này (tùy chọn gán ngay khi tạo/sửa)
    /// </summary>
    /// <example>[1, 2, 4]</example>
    public List<int>? VariantIds { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        // 1. Kiểm tra thời gian kết thúc phải sau thời gian bắt đầu
        if (EndDate <= StartDate)
        {
            yield return new ValidationResult(
                "Thời gian kết thúc khuyến mãi phải sau thời gian bắt đầu.",
                [nameof(EndDate), nameof(StartDate)]);
        }

        // 2. Nếu giảm theo phần trăm thì mức giảm không được vượt quá 100%
        if (string.Equals(DiscountType, "PERCENTAGE", StringComparison.OrdinalIgnoreCase) && DiscountValue > 100)
        {
            yield return new ValidationResult(
                "Mức giảm giá theo phần trăm không được vượt quá 100%.",
                [nameof(DiscountValue)]);
        }

        // 3. Kiểm tra danh sách VariantIds nếu có truyền
        if (VariantIds != null && VariantIds.Count > 0)
        {
            if (VariantIds.Any(id => id <= 0))
            {
                yield return new ValidationResult(
                    "Mã ID biến thể phải là số nguyên dương lớn hơn 0.",
                    [nameof(VariantIds)]);
            }

            if (VariantIds.Distinct().Count() != VariantIds.Count)
            {
                yield return new ValidationResult(
                    "Danh sách mã biến thể không được chứa các giá trị trùng lặp.",
                    [nameof(VariantIds)]);
            }
        }
    }
}
