using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Reviews;

namespace WebBanHang.Api.Services.Interfaces;

public interface IReviewService
{
    /// <summary>
    /// Dành cho Client: Lấy danh sách đánh giá công khai của một sản phẩm (ở trang chi tiết SP)
    /// </summary>
    Task<PagedResult<ReviewDto>> GetProductReviewsAsync(int productId, ProductReviewQueryFilter filter);

    /// <summary>
    /// Dành cho Khách hàng: Gửi đánh giá cho sản phẩm trong đơn hàng đã giao thành công (DELIVERED)
    /// </summary>
    Task<ReviewDto> CreateReviewAsync(int userId, CreateReviewRequestDto request);

    /// <summary>
    /// Dành cho Khách hàng: Xem danh sách các đánh giá do chính mình đã viết (Lịch sử đánh giá)
    /// </summary>
    Task<PagedResult<ReviewDto>> GetMyReviewsAsync(int userId, PaginationParams filter);

    /// <summary>
    /// Dành cho Khách hàng: Chỉnh sửa lại nội dung hoặc số sao đánh giá của mình
    /// </summary>
    Task<ReviewDto> UpdateMyReviewAsync(int reviewId, int userId, UpdateReviewRequestDto request);

    /// <summary>
    /// Dành cho Khách hàng: Lấy danh sách các món hàng đã nhận nhưng chưa đánh giá (Tab Chờ đánh giá)
    /// </summary>
    Task<PagedResult<PendingReviewItemDto>> GetPendingReviewItemsAsync(int userId, PaginationParams filter);

    /// <summary>
    /// Dành cho Quản trị viên: Lấy danh sách đánh giá toàn hệ thống có phân trang và bộ lọc nâng cao
    /// </summary>
    Task<PagedResult<ReviewDto>> GetAdminReviewsAsync(AdminReviewQueryFilter filter);

    /// <summary>
    /// Lấy thông tin chi tiết một đánh giá theo ID
    /// </summary>
    Task<ReviewDto> GetReviewByIdAsync(int reviewId);

    /// <summary>
    /// Dành cho Quản trị viên / Shop: Phản hồi hoặc cập nhật phản hồi đánh giá của khách hàng
    /// </summary>
    Task<ReviewDto> ReplyReviewAsync(int reviewId, ReplyReviewRequestDto request);

    /// <summary>
    /// Dành cho Quản trị viên / Shop: Xóa nội dung phản hồi của cửa hàng
    /// </summary>
    Task<ReviewDto> DeleteReplyAsync(int reviewId);

    /// <summary>
    /// Dành cho Quản trị viên: Ẩn hoặc Hiện đánh giá (dành cho bình luận vi phạm, spam)
    /// </summary>
    Task<ReviewDto> ToggleHideReviewAsync(int reviewId, bool isHidden);

    /// <summary>
    /// Dành cho Quản trị viên: Xóa hẳn một đánh giá và mở lại quyền đánh giá cho khách nếu cần
    /// </summary>
    Task<bool> DeleteReviewAsync(int reviewId);

    /// <summary>
    /// Lấy báo cáo thống kê đánh giá (tổng quan hệ thống hoặc theo từng sản phẩm)
    /// </summary>
    Task<ReviewStatisticsDto> GetReviewStatisticsAsync(int? productId = null);
}
