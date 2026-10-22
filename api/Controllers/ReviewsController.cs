using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Reviews;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý đánh giá và nhận xét sản phẩm (Reviews)
/// </summary>
[Route("api/[controller]")]
[Tags("Reviews")]
public class ReviewsController(IReviewService reviewService) : BaseApiController
{
    /// <summary>
    /// [PUBLIC] Lấy danh sách đánh giá công khai của một sản phẩm (hiển thị trên trang chi tiết sản phẩm)
    /// </summary>
    /// <param name="productId">Mã ID của sản phẩm</param>
    /// <param name="filter">Bộ lọc số sao, lọc đánh giá có ảnh và phân trang</param>
    [HttpGet("product/{productId:int}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<ReviewDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProductReviews(int productId, [FromQuery] ProductReviewQueryFilter filter)
    {
        var result = await reviewService.GetProductReviewsAsync(productId, filter);
        return Success(result, "Lấy danh sách đánh giá sản phẩm thành công.");
    }

    /// <summary>
    /// [CLIENT] Khách hàng gửi đánh giá cho sản phẩm đã nhận được hàng (DELIVERED)
    /// </summary>
    /// <param name="request">Thông tin đánh giá (OrderItemId, số sao, nội dung, danh sách link ảnh)</param>
    [HttpPost]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ReviewDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CreateReview([FromBody] CreateReviewRequestDto request)
    {
        var result = await reviewService.CreateReviewAsync(CurrentUserId, request);
        return CreatedSuccess(result, "Gửi đánh giá sản phẩm thành công.");
    }

    /// <summary>
    /// [CLIENT] Xem danh sách các đánh giá do chính mình đã viết (Lịch sử đánh giá của tôi)
    /// </summary>
    /// <param name="filter">Phân trang và sắp xếp</param>
    [HttpGet("my-reviews")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<ReviewDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyReviews([FromQuery] PaginationParams filter)
    {
        var result = await reviewService.GetMyReviewsAsync(CurrentUserId, filter);
        return Success(result, "Lấy lịch sử đánh giá của bạn thành công.");
    }

    /// <summary>
    /// [CLIENT] Chỉnh sửa nội dung đánh giá của chính mình (trong vòng 30 ngày kể từ khi tạo)
    /// </summary>
    /// <param name="id">Mã ID của đánh giá</param>
    /// <param name="request">Nội dung chỉnh sửa</param>
    [HttpPut("{id:int}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ReviewDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateMyReview(int id, [FromBody] UpdateReviewRequestDto request)
    {
        var result = await reviewService.UpdateMyReviewAsync(id, CurrentUserId, request);
        return Success(result, "Cập nhật đánh giá thành công.");
    }

    /// <summary>
    /// [CLIENT] Lấy danh sách các món hàng đã nhận nhưng chưa đánh giá (Tab Chờ đánh giá)
    /// </summary>
    /// <param name="filter">Phân trang</param>
    [HttpGet("pending")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<PendingReviewItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetPendingReviewItems([FromQuery] PaginationParams filter)
    {
        var result = await reviewService.GetPendingReviewItemsAsync(CurrentUserId, filter);
        return Success(result, "Lấy danh sách sản phẩm chờ đánh giá thành công.");
    }

    /// <summary>
    /// [ADMIN] Tra cứu và lọc toàn bộ danh sách đánh giá của hệ thống
    /// </summary>
    /// <param name="filter">Bộ lọc đánh giá (sản phẩm, người dùng, số sao, trạng thái phản hồi, ẩn/hiện, từ khóa)</param>
    [HttpGet("admin")]
    [Authorize]
    [HasPermission(AppPermissions.Reviews.View)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<ReviewDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetAdminReviews([FromQuery] AdminReviewQueryFilter filter)
    {
        var result = await reviewService.GetAdminReviewsAsync(filter);
        return Success(result, "Lấy danh sách đánh giá thành công.");
    }

    /// <summary>
    /// [ADMIN] Lấy báo cáo thống kê đánh giá (toàn hệ thống hoặc theo sản phẩm cụ thể)
    /// </summary>
    /// <param name="productId">Mã ID sản phẩm (tùy chọn, để trống nếu lấy toàn sàn)</param>
    [HttpGet("admin/statistics")]
    [Authorize]
    [HasPermission(AppPermissions.Reviews.View)]
    [ProducesResponseType(typeof(ApiResponse<ReviewStatisticsDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetReviewStatistics([FromQuery] int? productId = null)
    {
        var result = await reviewService.GetReviewStatisticsAsync(productId);
        return Success(result, "Lấy báo cáo thống kê đánh giá thành công.");
    }

    /// <summary>
    /// [ADMIN] Lấy thông tin chi tiết một đánh giá theo ID
    /// </summary>
    /// <param name="id">Mã ID của đánh giá</param>
    [HttpGet("{id:int}")]
    [Authorize]
    [HasPermission(AppPermissions.Reviews.View)]
    [ProducesResponseType(typeof(ApiResponse<ReviewDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetReviewById(int id)
    {
        var result = await reviewService.GetReviewByIdAsync(id);
        return Success(result, "Lấy thông tin đánh giá thành công.");
    }

    /// <summary>
    /// [ADMIN / SHOP] Phản hồi hoặc cập nhật nội dung phản hồi cho đánh giá của khách hàng
    /// </summary>
    /// <param name="id">Mã ID của đánh giá</param>
    /// <param name="request">Nội dung phản hồi từ cửa hàng</param>
    [HttpPost("{id:int}/reply")]
    [Authorize]
    [HasPermission(AppPermissions.Reviews.Reply)]
    [ProducesResponseType(typeof(ApiResponse<ReviewDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ReplyReview(int id, [FromBody] ReplyReviewRequestDto request)
    {
        var result = await reviewService.ReplyReviewAsync(id, request);
        return Success(result, "Phản hồi đánh giá của khách hàng thành công.");
    }

    /// <summary>
    /// [ADMIN / SHOP] Xóa nội dung phản hồi của cửa hàng đối với đánh giá
    /// </summary>
    /// <param name="id">Mã ID của đánh giá</param>
    [HttpDelete("{id:int}/reply")]
    [Authorize]
    [HasPermission(AppPermissions.Reviews.Reply)]
    [ProducesResponseType(typeof(ApiResponse<ReviewDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteReply(int id)
    {
        var result = await reviewService.DeleteReplyAsync(id);
        return Success(result, "Xóa phản hồi của cửa hàng thành công.");
    }

    /// <summary>
    /// [ADMIN] Ẩn hoặc Hiện lại đánh giá vi phạm chính sách / spam
    /// </summary>
    /// <param name="id">Mã ID của đánh giá</param>
    /// <param name="isHidden">True: ẩn đánh giá, False: hiển thị lại công khai</param>
    [HttpPatch("{id:int}/visibility")]
    [Authorize]
    [HasPermission(AppPermissions.Reviews.Hide)]
    [ProducesResponseType(typeof(ApiResponse<ReviewDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleVisibility(int id, [FromQuery] bool isHidden)
    {
        var result = await reviewService.ToggleHideReviewAsync(id, isHidden);
        var msg = isHidden ? "Đã ẩn đánh giá khỏi giao diện người dùng." : "Đã kích hoạt hiển thị lại đánh giá.";
        return Success(result, msg);
    }

    /// <summary>
    /// [ADMIN] Xóa hoàn toàn một đánh giá và reset cờ đánh giá cho dòng đơn hàng
    /// </summary>
    /// <param name="id">Mã ID của đánh giá</param>
    [HttpDelete("{id:int}")]
    [Authorize]
    [HasPermission(AppPermissions.Reviews.Delete)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteReview(int id)
    {
        var result = await reviewService.DeleteReviewAsync(id);
        return Success(result, "Xóa đánh giá thành công.");
    }
}
