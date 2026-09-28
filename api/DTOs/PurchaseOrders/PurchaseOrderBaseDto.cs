using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.PurchaseOrders;

public class PurchaseOrderBaseDto
{
    /// <summary>
    /// Mã ID duy nhất của phiếu nhập hàng
    /// </summary>
    /// <example>1</example>
    public int PurchaseOrderId { get; set; }

    /// <summary>
    /// Mã số chứng từ phiếu nhập (sinh tự động: PO-yyyyMMdd-XXX)
    /// </summary>
    /// <example>PO-20260925-001</example>
    public string PoCode { get; set; } = string.Empty;

    /// <summary>
    /// Mã ID của nhà cung cấp đối tác
    /// </summary>
    /// <example>1</example>
    public int SupplierId { get; set; }

    /// <summary>
    /// Tên nhà cung cấp đối tác
    /// </summary>
    /// <example>Công ty TNHH ASUS Việt Nam</example>
    public string SupplierName { get; set; } = string.Empty;

    /// <summary>
    /// Mã ID của nhân sự lập phiếu
    /// </summary>
    /// <example>1</example>
    public int CreatedByUserId { get; set; }

    /// <summary>
    /// Họ tên nhân sự lập phiếu
    /// </summary>
    /// <example>Quản trị viên Hệ thống</example>
    public string CreatedByName { get; set; } = string.Empty;

    /// <summary>
    /// Tổng tiền hàng của phiếu nhập (VNĐ)
    /// </summary>
    /// <example>185000000</example>
    public decimal TotalCost { get; set; }

    /// <summary>
    /// Tổng số lượng mặt hàng (dòng sản phẩm) trong phiếu nhập
    /// </summary>
    /// <example>1</example>
    public int TotalItems { get; set; }

    /// <summary>
    /// Trạng thái phiếu nhập (DRAFT, COMPLETED, CANCELLED)
    /// </summary>
    /// <example>COMPLETED</example>
    public PurchaseOrderStatus Status { get; set; } = PurchaseOrderStatus.DRAFT;

    /// <summary>
    /// Ghi chú nhập hàng
    /// </summary>
    /// <example>Nhập lô hàng laptop ASUS Zenbook 14 đợt 1 tháng 9/2026</example>
    public string? Note { get; set; }

    /// <summary>
    /// Thời điểm tạo phiếu nhập (UTC)
    /// </summary>
    /// <example>2026-09-25T08:30:00Z</example>
    public DateTime CreatedAt { get; set; }
}
