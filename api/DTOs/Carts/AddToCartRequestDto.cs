using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Carts;

/// <summary>
/// Dữ liệu yêu cầu thêm sản phẩm biến thể vào giỏ hàng
/// </summary>
public class AddToCartRequestDto
{
    /// <summary>
    /// Mã ID biến thể sản phẩm cần thêm vào giỏ
    /// </summary>
    /// <example>4</example>
    [Required(ErrorMessage = "Mã biến thể sản phẩm không được để trống.")]
    [Range(1, int.MaxValue, ErrorMessage = "Mã biến thể sản phẩm không hợp lệ.")]
    public int VariantId { get; set; }

    /// <summary>
    /// Số lượng sản phẩm muốn thêm vào giỏ (mặc định là 1)
    /// </summary>
    /// <example>1</example>
    [Required(ErrorMessage = "Số lượng không được để trống.")]
    [Range(1, 1000, ErrorMessage = "Số lượng mua mỗi lần phải từ 1 đến 1000 sản phẩm.")]
    public int Quantity { get; set; } = 1;
}
