using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Reviews;

/// <summary>
/// Yêu cầu gửi đánh giá sản phẩm mới từ khách hàng
/// </summary>
public class CreateReviewRequestDto : BaseReviewUpsertDto
{
    /// <summary>
    /// Mã ID của dòng món hàng đã mua trong đơn hàng thành công (DELIVERED)
    /// </summary>
    /// <example>501</example>
    [Required(ErrorMessage = "Mã chi tiết đơn hàng (OrderItemId) là bắt buộc")]
    public int OrderItemId { get; set; }
}
