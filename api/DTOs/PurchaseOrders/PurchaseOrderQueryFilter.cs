using WebBanHang.Api.Common;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.PurchaseOrders;

public class PurchaseOrderQueryFilter : PaginationParams
{
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public PurchaseOrderStatus? Status { get; set; }
    public int? SupplierId { get; set; }
}
