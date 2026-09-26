using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Carts;

/// <summary>
/// Dữ liệu yêu cầu cập nhật số lượng của một mặt hàng trong giỏ
/// </summary>
public class UpdateCartItemRequestDto
{
    /// <summary>
    /// Số lượng sản phẩm mới trong giỏ
    /// </summary>
    /// <example>2</example>
    [Required(ErrorMessage = "Số lượng không được để trống.")]
    [Range(1, 1000, ErrorMessage = "Số lượng trong giỏ hàng phải từ 1 đến 1000 sản phẩm.")]
    public int Quantity { get; set; }
}
