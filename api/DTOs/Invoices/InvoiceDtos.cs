using WebBanHang.Api.Common;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.DTOs.Invoices;

/// <summary>
/// DTO thông tin hóa đơn thanh toán
/// </summary>
public class InvoiceDto
{
    public int InvoiceId { get; set; }

    /// <summary>
    /// Mã hóa đơn (VD: INV-ORD-20261015-8A3F)
    /// </summary>
    public string InvoiceCode { get; set; } = string.Empty;

    public int OrderId { get; set; }

    /// <summary>
    /// Mã đơn hàng liên kết
    /// </summary>
    public string OrderCode { get; set; } = string.Empty;

    public int UserId { get; set; }

    /// <summary>
    /// Tên khách hàng / người nhận
    /// </summary>
    public string CustomerName { get; set; } = string.Empty;

    /// <summary>
    /// Tổng tiền trên hóa đơn
    /// </summary>
    public decimal TotalAmount { get; set; }

    /// <summary>
    /// Trạng thái hóa đơn: UNPAID, PAID, CANCELLED
    /// </summary>
    public InvoiceStatus Status { get; set; }

    /// <summary>
    /// Phương thức thanh toán (COD, VNPAY, BANK_TRANSFER)
    /// </summary>
    public PaymentMethod PaymentMethod { get; set; }

    /// <summary>
    /// Thời điểm thanh toán
    /// </summary>
    public DateTime? PaidAt { get; set; }

    /// <summary>
    /// Thời điểm tạo hóa đơn
    /// </summary>
    public DateTime CreatedAt { get; set; }

    public string? Note { get; set; }
}

/// <summary>
/// Bộ lọc tìm kiếm và phân trang danh sách hóa đơn
/// </summary>
public class InvoiceQueryFilter : PaginationParams
{
    public InvoiceStatus? Status { get; set; }
    public PaymentMethod? PaymentMethod { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
}
