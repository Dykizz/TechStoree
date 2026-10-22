namespace WebBanHang.Api.DTOs.Reviews;

/// <summary>
/// DTO thông tin chi tiết một đánh giá sản phẩm
/// </summary>
public class ReviewDto
{
    /// <summary>
    /// Mã ID của đánh giá
    /// </summary>
    /// <example>1</example>
    public int ReviewId { get; set; }

    /// <summary>
    /// Mã ID người dùng đã đánh giá
    /// </summary>
    /// <example>12</example>
    public int UserId { get; set; }

    /// <summary>
    /// Tên tài khoản người dùng
    /// </summary>
    /// <example>nguyenvana</example>
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Họ và tên đầy đủ của người đánh giá
    /// </summary>
    /// <example>Nguyễn Văn A</example>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Email liên hệ của người đánh giá
    /// </summary>
    /// <example>vana@example.com</example>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại liên hệ
    /// </summary>
    /// <example>0987654321</example>
    public string? Phone { get; set; }

    /// <summary>
    /// Mã ID sản phẩm
    /// </summary>
    /// <example>101</example>
    public int ProductId { get; set; }

    /// <summary>
    /// Tên sản phẩm
    /// </summary>
    /// <example>iPhone 15 Pro Max</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Đường dẫn hình ảnh đại diện của sản phẩm
    /// </summary>
    /// <example>https://res.cloudinary.com/techstore/image/upload/v1/products/iphone15promax.png</example>
    public string? ProductImageUrl { get; set; }

    /// <summary>
    /// Mã ID dòng món hàng trong đơn đặt hàng
    /// </summary>
    /// <example>501</example>
    public int OrderItemId { get; set; }

    /// <summary>
    /// Mã ID đơn hàng
    /// </summary>
    /// <example>205</example>
    public int OrderId { get; set; }

    /// <summary>
    /// Mã code đơn hàng
    /// </summary>
    /// <example>ORD-20261021-9B2F</example>
    public string OrderCode { get; set; } = string.Empty;

    /// <summary>
    /// Mã ID biến thể sản phẩm đã mua
    /// </summary>
    /// <example>305</example>
    public int VariantId { get; set; }

    /// <summary>
    /// Tên phân loại biến thể đã mua lúc đặt hàng
    /// </summary>
    /// <example>Màu Titan Tự Nhiên - 256GB</example>
    public string VariantName { get; set; } = string.Empty;

    /// <summary>
    /// Điểm số sao đánh giá (từ 1.0 đến 5.0, bước nhảy 0.5)
    /// </summary>
    /// <example>4.5</example>
    public decimal Rating { get; set; }

    /// <summary>
    /// Nội dung nhận xét chi tiết của khách hàng
    /// </summary>
    /// <example>Sản phẩm rất đẹp, đóng gói cẩn thận, máy dùng mượt mà và pin rất trâu!</example>
    public string? Comment { get; set; }

    /// <summary>
    /// Danh sách link hình ảnh/video feedback mở hộp
    /// </summary>
    /// <example>["https://res.cloudinary.com/techstore/image/upload/v1/reviews/review_unbox_1.jpg"]</example>
    public List<string> ImageUrls { get; set; } = new();

    /// <summary>
    /// Nội dung phản hồi của cửa hàng / nhân viên CSKH
    /// </summary>
    /// <example>Dạ TechStore cảm ơn quý khách đã tin tưởng và đánh giá tích cực ạ! Chúc quý khách có trải nghiệm tuyệt vời.</example>
    public string? ReplyContent { get; set; }

    /// <summary>
    /// Thời gian cửa hàng phản hồi (định dạng UTC ISO 8601)
    /// </summary>
    /// <example>2026-10-21T10:30:00Z</example>
    public DateTime? RepliedAt { get; set; }

    /// <summary>
    /// Trạng thái ẩn đánh giá (true: đang bị ẩn vì vi phạm tiêu chuẩn, false: hiển thị công khai)
    /// </summary>
    /// <example>false</example>
    public bool IsHidden { get; set; }

    /// <summary>
    /// Thời gian gửi đánh giá (định dạng UTC ISO 8601)
    /// </summary>
    /// <example>2026-10-21T09:15:00Z</example>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Thời gian cập nhật đánh giá lần cuối (nếu có)
    /// </summary>
    /// <example>2026-10-21T10:30:00Z</example>
    public DateTime? UpdatedAt { get; set; }
}
