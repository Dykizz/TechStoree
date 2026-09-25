namespace WebBanHang.Api.DTOs.Carts;

/// <summary>
/// Thông tin giỏ hàng của người dùng kèm danh sách sản phẩm và tổng tiền
/// </summary>
public class CartDto
{
    /// <summary>
    /// Mã ID giỏ hàng
    /// </summary>
    /// <example>1</example>
    public int CartId { get; set; }

    /// <summary>
    /// Mã ID người dùng sở hữu giỏ hàng
    /// </summary>
    /// <example>3</example>
    public int UserId { get; set; }

    /// <summary>
    /// Tổng số lượng mặt hàng (số dòng sản phẩm) trong giỏ
    /// </summary>
    /// <example>2</example>
    public int TotalItems => Items.Count;

    /// <summary>
    /// Tổng số lượng sản phẩm cộng dồn trong giỏ
    /// </summary>
    /// <example>3</example>
    public int TotalQuantity => Items.Sum(i => i.Quantity);

    /// <summary>
    /// Tổng giá trị tiền hàng trong giỏ (VNĐ)
    /// </summary>
    /// <example>32480000</example>
    public decimal TotalAmount => Items.Sum(i => i.TotalPrice);

    /// <summary>
    /// Thời điểm cập nhật giỏ hàng gần nhất
    /// </summary>
    public DateTime UpdatedAt { get; set; }

    /// <summary>
    /// Danh sách chi tiết các mặt hàng trong giỏ
    /// </summary>
    public List<CartItemDto> Items { get; set; } = new();
}
