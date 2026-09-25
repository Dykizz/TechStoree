namespace WebBanHang.Api.DTOs.PurchaseOrders;

public class PurchaseOrderDetailDto : PurchaseOrderBaseDto
{
    /// <summary>
    /// Danh sách chi tiết các mặt hàng kèm theo đơn giá và số lượng nhập
    /// </summary>
    public List<PurchaseOrderItemDto> Items { get; set; } = new();
}

public class PurchaseOrderItemDto
{
    /// <summary>
    /// Mã ID của dòng chi tiết phiếu nhập
    /// </summary>
    /// <example>1</example>
    public int PoItemId { get; set; }

    /// <summary>
    /// Mã ID của biến thể sản phẩm nhập kho
    /// </summary>
    /// <example>1</example>
    public int VariantId { get; set; }

    /// <summary>
    /// Mã ID của dòng sản phẩm cha
    /// </summary>
    /// <example>1</example>
    public int ProductId { get; set; }

    /// <summary>
    /// Tên dòng sản phẩm cha
    /// </summary>
    /// <example>Laptop ASUS Zenbook 14 OLED UX3405</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Tên phân loại biến thể sản phẩm (màu sắc, cấu hình)
    /// </summary>
    /// <example>16GB RAM / 512GB SSD - Xanh</example>
    public string VariantName { get; set; } = string.Empty;

    /// <summary>
    /// Tên đầy đủ kết hợp giữa dòng sản phẩm cha và phân loại biến thể
    /// </summary>
    /// <example>Laptop ASUS Zenbook 14 OLED UX3405 (16GB RAM / 512GB SSD - Xanh)</example>
    public string FullName => string.IsNullOrWhiteSpace(ProductName)
        ? VariantName
        : string.IsNullOrWhiteSpace(VariantName) || VariantName.Equals("Phiên bản tiêu chuẩn", StringComparison.OrdinalIgnoreCase)
            ? ProductName
            : $"{ProductName} ({VariantName})";

    /// <summary>
    /// Đơn giá nhập của biến thể tại thời điểm lập phiếu (VNĐ)
    /// </summary>
    /// <example>18500000</example>
    public decimal ImportPrice { get; set; }

    /// <summary>
    /// Số lượng nhập kho
    /// </summary>
    /// <example>10</example>
    public int Quantity { get; set; }

    /// <summary>
    /// Tổng thành tiền dòng mặt hàng (ImportPrice * Quantity) (VNĐ)
    /// </summary>
    /// <example>185000000</example>
    public decimal TotalPrice => ImportPrice * Quantity;
}
