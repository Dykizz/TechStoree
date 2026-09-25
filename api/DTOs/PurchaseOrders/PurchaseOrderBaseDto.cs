using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.PurchaseOrders;

public class PurchaseOrderBaseDto
{
    public int PurchaseOrderId { get; set; }
    public string PoCode { get; set; } = string.Empty;
    public int SupplierId { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public int CreatedByUserId { get; set; }
    public string CreatedByName { get; set; } = string.Empty;
    public decimal TotalCost { get; set; }
    public int TotalItems { get; set; }
    public PurchaseOrderStatus Status { get; set; } = PurchaseOrderStatus.DRAFT;
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
}
