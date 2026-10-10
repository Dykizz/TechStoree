using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Orders;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Đơn hàng và Checkout thanh toán
/// </summary>
[Route("api/[controller]")]
[Authorize]
[Tags("Orders")]
public class OrdersController(IOrderService orderService) : BaseApiController
{
    /// <summary>
    /// Tính thử chi phí đơn hàng trước khi thanh toán (Preview Checkout)
    /// </summary>
    /// <remarks>
    /// Cho phép khách xem trước danh sách sản phẩm, giá gốc, giá khuyến mãi SP (Promotion),
    /// kiểm tra mã Voucher hợp lệ, số tiền được giảm bill và tổng tiền cuối cùng.
    /// </remarks>
    [HttpPost("preview")]
    [ProducesResponseType(typeof(ApiResponse<CheckoutPreviewDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> PreviewCheckout([FromBody] CheckoutPreviewRequestDto request)
    {
        var result = await orderService.PreviewCheckoutAsync(CurrentUserId, request);
        return Success(result, "Tạm tính chi phí đơn hàng thành công.");
    }

    /// <summary>
    /// Khách hàng thực hiện đặt hàng chính thức (Checkout)
    /// </summary>
    /// <remarks>
    /// - Kiểm tra tồn kho và trừ kho tức thì theo Database Transaction.
    /// - Snapshot toàn bộ thông tin sản phẩm và Promotion (Item-level).
    /// - Snapshot mã Voucher và chiết khấu bill (Order-level), đồng bộ ví UserVoucher.
    /// - Tự động xóa các mặt hàng đã mua khỏi Giỏ hàng.
    /// </remarks>
    [HttpPost("checkout")]
    [ProducesResponseType(typeof(ApiResponse<OrderDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Checkout([FromBody] CreateOrderRequestDto request)
    {
        var result = await orderService.CreateOrderAsync(CurrentUserId, request);
        return CreatedSuccess(result, "Đặt hàng thành công!");
    }

    /// <summary>
    /// Lấy lịch sử danh sách đơn hàng của người dùng đang đăng nhập
    /// </summary>
    [HttpGet("my-orders")]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<OrderBaseDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyOrders([FromQuery] OrderQueryFilter filter)
    {
        var result = await orderService.GetMyOrdersAsync(CurrentUserId, filter);
        return Success(result, "Lấy danh sách đơn hàng của bạn thành công.");
    }

    /// <summary>
    /// Xem chi tiết một đơn hàng theo ID
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<OrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrderById(int id)
    {
        var result = await orderService.GetOrderByIdAsync(id, IsAdmin ? null : CurrentUserId)
            ?? throw new NotFoundException($"Không tìm thấy đơn hàng có mã ID = {id}.");

        return Success(result, "Lấy thông tin chi tiết đơn hàng thành công.");
    }

    /// <summary>
    /// Xem chi tiết một đơn hàng theo Mã đơn (OrderCode)
    /// </summary>
    [HttpGet("code/{orderCode}")]
    [ProducesResponseType(typeof(ApiResponse<OrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrderByCode(string orderCode)
    {
        var result = await orderService.GetOrderByCodeAsync(orderCode, IsAdmin ? null : CurrentUserId)
            ?? throw new NotFoundException($"Không tìm thấy đơn hàng có mã '{orderCode}'.");

        return Success(result, "Lấy thông tin chi tiết đơn hàng thành công.");
    }

    /// <summary>
    /// Hủy đơn hàng (Khách hàng hoặc Quản trị viên)
    /// </summary>
    /// <remarks>
    /// - Chỉ cho phép hủy đơn khi ở trạng thái PENDING (Chờ xử lý) hoặc CONFIRMED (Đã xác nhận).
    /// - Tự động hoàn lại số lượng tồn kho cho các sản phẩm đã mua.
    /// - Tự động mở khóa và trả Voucher về ví khách hàng.
    /// </remarks>
    [HttpPost("{id:int}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<OrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CancelOrder(int id, [FromBody] CancelOrderRequestDto request)
    {
        var result = await orderService.CancelOrderAsync(id, CurrentUserId, request, isAdmin: IsAdmin || HasRole(WebBanHang.Api.Enums.UserRoleTypeExtensions.SalesStaff));
        return Success(result, "Hủy đơn hàng thành công. Tồn kho và Voucher (nếu có) đã được hoàn lại.");
    }

    /// <summary>
    /// [ADMIN / BÁN HÀNG] Tra cứu và quản lý toàn bộ đơn hàng trong hệ thống
    /// </summary>
    [HttpGet("admin/all")]
    [HasPermission(AppPermissions.Orders.View)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<OrderBaseDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetAllOrders([FromQuery] OrderQueryFilter filter)
    {
        var result = await orderService.GetAllOrdersAsync(filter);
        return Success(result, "Lấy danh sách quản lý đơn hàng thành công.");
    }

    /// <summary>
    /// [ADMIN / BÁN HÀNG] Cập nhật trạng thái tiến trình đơn hàng (CONFIRMED, SHIPPING, DELIVERED, CANCELLED)
    /// </summary>
    [HttpPatch("{id:int}/status")]
    [HasPermission(AppPermissions.Orders.UpdateStatus)]
    [ProducesResponseType(typeof(ApiResponse<OrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateOrderStatus(int id, [FromBody] UpdateOrderStatusDto request)
    {
        var result = await orderService.UpdateOrderStatusAsync(id, request, CurrentUserId);
        return Success(result, "Cập nhật trạng thái đơn hàng thành công.");
    }
}
