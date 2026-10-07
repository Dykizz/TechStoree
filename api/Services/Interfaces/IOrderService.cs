using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Orders;

namespace WebBanHang.Api.Services.Interfaces;

public interface IOrderService
{
    /// <summary>
    /// Tạm tính giá trị đơn hàng, khuyến mãi sản phẩm và voucher trước khi khách đặt hàng
    /// </summary>
    Task<CheckoutPreviewDto> PreviewCheckoutAsync(int userId, CheckoutPreviewRequestDto request);

    /// <summary>
    /// Khách hàng thực hiện checkout đặt hàng từ giỏ hàng
    /// </summary>
    Task<OrderDetailDto> CreateOrderAsync(int userId, CreateOrderRequestDto request);

    /// <summary>
    /// Lấy danh sách lịch sử đơn hàng của tài khoản đang đăng nhập
    /// </summary>
    Task<PagedResult<OrderBaseDto>> GetMyOrdersAsync(int userId, OrderQueryFilter? filter = null);

    /// <summary>
    /// Lấy thông tin chi tiết một đơn hàng theo ID (kiểm tra quyền sở hữu nếu là khách hàng)
    /// </summary>
    Task<OrderDetailDto?> GetOrderByIdAsync(int orderId, int? userId = null);

    /// <summary>
    /// Lấy thông tin chi tiết một đơn hàng theo mã Code (VD: ORD-20260926-8A3F)
    /// </summary>
    Task<OrderDetailDto?> GetOrderByCodeAsync(string orderCode, int? userId = null);

    /// <summary>
    /// Dành cho Quản trị viên: Lấy danh sách toàn bộ đơn hàng trong hệ thống (có lọc và phân trang)
    /// </summary>
    Task<PagedResult<OrderBaseDto>> GetAllOrdersAsync(OrderQueryFilter? filter = null);

    /// <summary>
    /// Hủy đơn hàng (tự động hoàn kho và trả lại Voucher về ví nếu có)
    /// </summary>
    Task<OrderDetailDto> CancelOrderAsync(int orderId, int? userId, CancelOrderRequestDto request, bool isAdmin = false);

    /// <summary>
    /// Dành cho Quản trị viên / Nhân viên bán hàng: Cập nhật trạng thái tiến trình đơn hàng (CONFIRMED, SHIPPING, DELIVERED, ...)
    /// </summary>
    Task<OrderDetailDto> UpdateOrderStatusAsync(int orderId, UpdateOrderStatusDto request, int? updatedByUserId = null);
}
