using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Orders;

/// <summary>
/// Bộ lọc tra cứu danh sách đơn hàng
/// </summary>
public class OrderQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc theo trạng thái đơn hàng (PENDING, CONFIRMED, SHIPPING, DELIVERED, CANCELLED)
    /// </summary>
    /// <example>CONFIRMED</example>
    public OrderStatus? Status { get; set; }

    /// <summary>
    /// Lọc theo trạng thái thanh toán (PENDING, PAID, FAILED, REFUNDED)
    /// </summary>
    /// <example>PENDING</example>
    public PaymentStatus? PaymentStatus { get; set; }

    /// <summary>
    /// Lọc theo phương thức thanh toán (COD, VNPAY, BANK_TRANSFER)
    /// </summary>
    /// <example>COD</example>
    public PaymentMethod? PaymentMethod { get; set; }

    /// <summary>
    /// Lọc theo khoảng thời gian đặt hàng (Từ ngày, định dạng UTC ISO 8601)
    /// </summary>
    /// <example>2026-09-01T00:00:00Z</example>
    public DateTime? FromDate { get; set; }

    /// <summary>
    /// Lọc theo khoảng thời gian đặt hàng (Đến ngày, định dạng UTC ISO 8601)
    /// </summary>
    /// <example>2026-09-30T23:59:59Z</example>
    public DateTime? ToDate { get; set; }

    /// <summary>
    /// Lọc theo giá trị đơn hàng tối thiểu (VNĐ)
    /// </summary>
    /// <example>500000</example>
    public decimal? MinAmount { get; set; }

    /// <summary>
    /// Lọc theo giá trị đơn hàng tối đa (VNĐ)
    /// </summary>
    /// <example>20000000</example>
    public decimal? MaxAmount { get; set; }
}
