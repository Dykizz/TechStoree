using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.Vouchers;

/// <summary>
/// Request DTO tạo mới hoặc cập nhật Voucher (Admin)
/// </summary>
public class VoucherUpsertRequestDto : IValidatableObject
{
    /// <summary>
    /// Mã code giảm giá viết hoa, không dấu (VD: CELLPHONES100K)
    /// </summary>
    /// <example>CELLPHONES100K</example>
    [Required(ErrorMessage = "Mã voucher không được để trống.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Mã voucher phải từ 3 đến 50 ký tự.")]
    [RegularExpression(@"^[A-Za-z0-9_-]+$", ErrorMessage = "Mã voucher chỉ được chứa chữ cái, số, gạch ngang và gạch dưới.")]
    public string Code { get; set; } = string.Empty;

    /// <summary>
    /// Tiêu đề voucher
    /// </summary>
    /// <example>Giảm 100K cho đơn hàng từ 2 triệu</example>
    [Required(ErrorMessage = "Tiêu đề voucher không được để trống.")]
    [StringLength(200, ErrorMessage = "Tiêu đề không được vượt quá 200 ký tự.")]
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// Thể lệ / Điều khoản chi tiết
    /// </summary>
    /// <example>Áp dụng cho mọi đơn hàng điện thoại, phụ kiện tại hệ thống CellphoneS.</example>
    [StringLength(1000, ErrorMessage = "Mô tả không được vượt quá 1000 ký tự.")]
    public string? Description { get; set; }

    /// <summary>
    /// Loại giảm giá: PERCENTAGE (theo %) hoặc FIXED_AMOUNT (theo số tiền cố định)
    /// </summary>
    /// <example>FIXED_AMOUNT</example>
    [Required(ErrorMessage = "Loại giảm giá không được để trống.")]
    public DiscountType DiscountType { get; set; } = DiscountType.PERCENTAGE;

    /// <summary>
    /// Mức giảm: Nếu là PERCENTAGE thì từ 1 đến 100 (%), nếu là FIXED_AMOUNT thì số tiền > 0
    /// </summary>
    /// <example>100000</example>
    [Required(ErrorMessage = "Mức giảm giá không được để trống.")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Mức giảm giá phải lớn hơn 0.")]
    public decimal DiscountValue { get; set; }

    /// <summary>
    /// Giá trị giỏ hàng tối thiểu để được áp dụng (VNĐ, mặc định 0)
    /// </summary>
    /// <example>2000000</example>
    [Range(0, double.MaxValue, ErrorMessage = "Giá trị đơn hàng tối thiểu không thể âm.")]
    public decimal MinOrderValue { get; set; } = 0;

    /// <summary>
    /// Mức giảm tối đa (VNĐ, áp dụng khi DiscountType là PERCENTAGE)
    /// </summary>
    /// <example>500000</example>
    [Range(0, double.MaxValue, ErrorMessage = "Mức giảm tối đa không thể âm.")]
    public decimal? MaxDiscountAmount { get; set; }

    /// <summary>
    /// Giới hạn tổng số lượt sử dụng toàn hệ thống (null = không giới hạn)
    /// </summary>
    /// <example>500</example>
    [Range(1, int.MaxValue, ErrorMessage = "Giới hạn lượt sử dụng phải lớn hơn 0.")]
    public int? UsageLimit { get; set; }

    /// <summary>
    /// Giới hạn số lần dùng của mỗi tài khoản (mặc định 1)
    /// </summary>
    /// <example>1</example>
    [Range(1, 100, ErrorMessage = "Giới hạn mỗi khách hàng phải từ 1 đến 100 lần.")]
    public int LimitPerUser { get; set; } = 1;

    /// <summary>
    /// Thời gian bắt đầu hiệu lực (UTC)
    /// </summary>
    /// <example>2026-10-01T00:00:00Z</example>
    [Required(ErrorMessage = "Thời gian bắt đầu không được để trống.")]
    public DateTime StartDate { get; set; }

    /// <summary>
    /// Thời gian kết thúc hiệu lực (UTC)
    /// </summary>
    /// <example>2026-10-15T23:59:59Z</example>
    [Required(ErrorMessage = "Thời gian kết thúc không được để trống.")]
    public DateTime EndDate { get; set; }

    /// <summary>
    /// Trạng thái kích hoạt
    /// </summary>
    /// <example>true</example>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Hiển thị công khai (true = công khai trên sàn; false = voucher ẩn/khảo sát/quà tặng riêng)
    /// </summary>
    /// <example>true</example>
    public bool IsPublic { get; set; } = true;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (StartDate >= EndDate)
        {
            yield return new ValidationResult(
                "Thời gian kết thúc phải lớn hơn thời gian bắt đầu.",
                [nameof(EndDate)]);
        }

        if (DiscountType == DiscountType.PERCENTAGE && DiscountValue > 100)
        {
            yield return new ValidationResult(
                "Mức giảm giá theo phần trăm không được vượt quá 100%.",
                [nameof(DiscountValue)]);
        }
    }
}
