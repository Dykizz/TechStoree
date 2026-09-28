using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Orders;

/// <summary>
/// Yêu cầu hủy đơn hàng
/// </summary>
public class CancelOrderRequestDto
{
    /// <summary>
    /// Lý do hủy đơn hàng
    /// </summary>
    /// <example>Tôi muốn thay đổi địa chỉ nhận hàng / Đổi sang màu khác</example>
    [Required(ErrorMessage = "Vui lòng nhập lý do hủy đơn hàng.")]
    [MaxLength(500, ErrorMessage = "Lý do hủy không được vượt quá 500 ký tự.")]
    public string Reason { get; set; } = string.Empty;
}

/// <summary>
/// DTO cập nhật trạng thái đơn hàng (Dành cho Quản trị viên)
/// </summary>
public class UpdateOrderStatusDto
{
    /// <summary>
    /// Trạng thái mới của đơn hàng: PENDING, CONFIRMED, SHIPPING, DELIVERED, CANCELLED
    /// </summary>
    /// <example>SHIPPING</example>
    [Required(ErrorMessage = "Trạng thái đơn hàng là bắt buộc.")]
    public OrderStatus Status { get; set; }

    /// <summary>
    /// Trạng thái thanh toán mới (tùy chọn: PENDING, PAID, FAILED, REFUNDED)
    /// </summary>
    /// <example>PAID</example>
    public PaymentStatus? PaymentStatus { get; set; }

    /// <summary>
    /// Ghi chú hủy (nếu chuyển sang trạng thái CANCELLED)
    /// </summary>
    /// <example>Hết hàng trong kho nhà cung cấp</example>
    [MaxLength(500)]
    public string? Reason { get; set; }
}
