using WebBanHang.Api.Common;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.PurchaseOrders;

public class PurchaseOrderQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc phiếu nhập từ ngày (định dạng YYYY-MM-DD hoặc ISO-8601)
    /// </summary>
    /// <example>2026-09-01T00:00:00Z</example>
    public DateTime? FromDate { get; set; }

    /// <summary>
    /// Lọc phiếu nhập đến ngày (định dạng YYYY-MM-DD hoặc ISO-8601)
    /// </summary>
    /// <example>2026-09-30T23:59:59Z</example>
    public DateTime? ToDate { get; set; }

    /// <summary>
    /// Lọc theo trạng thái phiếu: DRAFT (Bản nháp), COMPLETED (Đã nhập kho), CANCELLED (Đã hủy)
    /// </summary>
    /// <example>COMPLETED</example>
    public PurchaseOrderStatus? Status { get; set; }

    /// <summary>
    /// Lọc theo mã ID nhà cung cấp
    /// </summary>
    /// <example>1</example>
    public int? SupplierId { get; set; }
}
