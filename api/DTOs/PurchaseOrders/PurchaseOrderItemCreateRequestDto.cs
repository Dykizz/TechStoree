using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.PurchaseOrders;

public class PurchaseOrderItemCreateRequestDto
{
    /// <summary>
    /// Mã ID của biến thể sản phẩm cần nhập thêm vào kho
    /// </summary>
    /// <example>1</example>
    [Required(ErrorMessage = "Mã biến thể sản phẩm không được để trống.")]
    [Range(1, int.MaxValue, ErrorMessage = "Mã biến thể sản phẩm không hợp lệ.")]
    public int VariantId { get; set; }

    /// <summary>
    /// Đơn giá nhập của biến thể tại thời điểm lập phiếu (VNĐ)
    /// </summary>
    /// <example>18500000</example>
    [Required(ErrorMessage = "Đơn giá nhập không được để trống.")]
    [Range(0, (double)decimal.MaxValue, ErrorMessage = "Đơn giá nhập không được nhỏ hơn 0.")]
    public decimal ImportPrice { get; set; }

    /// <summary>
    /// Số lượng nhập kho
    /// </summary>
    /// <example>10</example>
    [Required(ErrorMessage = "Số lượng nhập không được để trống.")]
    [Range(1, 100_000, ErrorMessage = "Số lượng nhập mỗi dòng phải từ 1 đến 100,000.")]
    public int Quantity { get; set; }
}
