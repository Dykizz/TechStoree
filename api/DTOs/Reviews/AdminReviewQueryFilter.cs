using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Reviews;

/// <summary>
/// Bộ lọc tra cứu danh sách đánh giá dành cho Quản trị viên
/// </summary>
public class AdminReviewQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc theo ID sản phẩm cụ thể
    /// </summary>
    /// <example>101</example>
    public int? ProductId { get; set; }

    /// <summary>
    /// Lọc theo ID người dùng
    /// </summary>
    /// <example>12</example>
    public int? UserId { get; set; }

    /// <summary>
    /// Lọc theo số sao chính xác (ví dụ 5.0, 4.5, ...)
    /// </summary>
    /// <example>5.0</example>
    public decimal? Rating { get; set; }

    /// <summary>
    /// Lọc số sao tối thiểu
    /// </summary>
    /// <example>3.0</example>
    public decimal? MinRating { get; set; }

    /// <summary>
    /// Lọc số sao tối đa (hữu ích để lọc các đánh giá tiêu cực nhỏ hơn hoặc bằng 2.5 sao)
    /// </summary>
    /// <example>2.5</example>
    public decimal? MaxRating { get; set; }

    /// <summary>
    /// Lọc theo trạng thái đã được Shop phản hồi hay chưa
    /// </summary>
    /// <example>false</example>
    public bool? HasReply { get; set; }

    /// <summary>
    /// Lọc theo trạng thái ẩn/hiện
    /// </summary>
    /// <example>false</example>
    public bool? IsHidden { get; set; }

    /// <summary>
    /// Lọc đánh giá có hình ảnh đính kèm hay không
    /// </summary>
    /// <example>true</example>
    public bool? HasImages { get; set; }

    /// <summary>
    /// Khoảng thời gian gửi đánh giá (Từ ngày, định dạng UTC ISO 8601)
    /// </summary>
    /// <example>2026-10-01T00:00:00Z</example>
    public DateTime? FromDate { get; set; }

    /// <summary>
    /// Khoảng thời gian gửi đánh giá (Đến ngày, định dạng UTC ISO 8601)
    /// </summary>
    /// <example>2026-10-31T23:59:59Z</example>
    public DateTime? ToDate { get; set; }
}
