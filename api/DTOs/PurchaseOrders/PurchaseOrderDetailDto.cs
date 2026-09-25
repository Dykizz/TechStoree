namespace WebBanHang.Api.DTOs.PurchaseOrders;

public class PurchaseOrderDetailDto : PurchaseOrderBaseDto
{
    public List<PurchaseOrderItemDto> Items { get; set; } = new();
}

public class PurchaseOrderItemDto
{
    public int PoItemId { get; set; }
    public int VariantId { get; set; }
    public string VariantName { get; set; } = string.Empty;
    public decimal ImportPrice { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice => ImportPrice * Quantity;
}
