using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Reviews;

/// <summary>
/// DTO phản hồi đánh giá của khách hàng từ Admin/Shop
/// </summary>
public class ReplyReviewRequestDto
{
    /// <summary>
    /// Nội dung phản hồi từ cửa hàng
    /// </summary>
    /// <example>Dạ TechStore cảm ơn quý khách đã tin tưởng và ủng hộ sản phẩm của shop ạ!</example>
    [Required(ErrorMessage = "Nội dung phản hồi không được để trống")]
    [MaxLength(1000, ErrorMessage = "Nội dung phản hồi tối đa 1000 ký tự")]
    public string ReplyContent { get; set; } = string.Empty;
}
