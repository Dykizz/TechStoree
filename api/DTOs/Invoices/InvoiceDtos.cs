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

    /// <summary>
    /// Số điện thoại người nhận (lấy qua khóa ngoại từ đơn hàng)
    /// </summary>
    public string ReceiverPhone { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ giao hàng (lấy qua khóa ngoại từ đơn hàng)
    /// </summary>
    public string ShippingAddress { get; set; } = string.Empty;

    /// <summary>
    /// Tiền hàng trước giảm giá (lấy từ đơn hàng)
    /// </summary>
    public decimal SubtotalAmount { get; set; }

    /// <summary>
    /// Số tiền giảm giá voucher (nếu có)
    /// </summary>
    public decimal VoucherDiscountAmount { get; set; }

    /// <summary>
    /// Mã voucher đã áp dụng (nếu có)
    /// </summary>
    public string? VoucherCode { get; set; }

    /// <summary>
    /// Danh sách mặt hàng trong hóa đơn (lấy qua khóa ngoại từ OrderItems)
    /// </summary>
    public List<InvoiceItemDto> Items { get; set; } = [];
}

/// <summary>
/// DTO dòng sản phẩm trong hóa đơn
/// </summary>
public class InvoiceItemDto
{
    public int OrderItemId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string VariantName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }
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
    public decimal? MinAmount { get; set; }
    public decimal? MaxAmount { get; set; }

    /// <summary>
    /// Chuỗi truy vấn tìm kiếm nâng cao hỗ trợ toán tử so sánh (&gt;, &lt;, =, &lt;&gt;) và logic (AND, OR, NOT)
    /// </summary>
    public string? AdvancedQuery { get; set; }
}

/// <summary>
/// DTO số liệu thống kê hóa đơn theo trạng thái và doanh thu thực tế
/// </summary>
public class InvoiceStatisticsDto
{
    public int TotalInvoices { get; set; }
    public int PaidCount { get; set; }
    public int UnpaidCount { get; set; }
    public int CancelledCount { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal UnpaidAmount { get; set; }
    public Dictionary<string, int> StatusCounts { get; set; } = new(StringComparer.OrdinalIgnoreCase);
}

