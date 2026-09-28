using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Orders;

/// <summary>
/// Yêu cầu đặt hàng từ giỏ hàng
/// </summary>
public class CreateOrderRequestDto
{
    /// <summary>
    /// Danh sách các CartItemId được tích chọn để thanh toán (null hoặc rỗng = thanh toán toàn bộ giỏ hàng)
    /// </summary>
    public List<int>? CartItemIds { get; set; }

    /// <summary>
    /// Mã giảm giá bill áp dụng (tùy chọn)
    /// </summary>
    /// <example>CELLPHONES100K</example>
    public string? VoucherCode { get; set; }

    /// <summary>
    /// Họ và tên người nhận hàng
    /// </summary>
    /// <example>Nguyễn Văn A</example>
    [Required(ErrorMessage = "Họ và tên người nhận là bắt buộc.")]
    [MaxLength(100, ErrorMessage = "Tên người nhận không được vượt quá 100 ký tự.")]
    public string ReceiverName { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại liên hệ nhận hàng
    /// </summary>
    /// <example>0987654321</example>
    [Required(ErrorMessage = "Số điện thoại người nhận là bắt buộc.")]
    [MaxLength(20, ErrorMessage = "Số điện thoại không được vượt quá 20 ký tự.")]
    [Phone(ErrorMessage = "Số điện thoại không hợp lệ.")]
    public string ReceiverPhone { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ chi tiết nhận hàng (Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành phố)
    /// </summary>
    /// <example>123 Đường Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh</example>
    [Required(ErrorMessage = "Địa chỉ nhận hàng là bắt buộc.")]
    [MaxLength(500, ErrorMessage = "Địa chỉ nhận hàng không được vượt quá 500 ký tự.")]
    public string ShippingAddress { get; set; } = string.Empty;

    /// <summary>
    /// Ghi chú đơn hàng cho shipper hoặc shop
    /// </summary>
    /// <example>Giao hàng trong giờ hành chính, gọi trước khi giao</example>
    [MaxLength(500, ErrorMessage = "Ghi chú không được vượt quá 500 ký tự.")]
    public string? Notes { get; set; }

    /// <summary>
    /// Phương thức thanh toán: COD, VNPAY, BANK_TRANSFER
    /// </summary>
    /// <example>COD</example>
    public PaymentMethod PaymentMethod { get; set; } = PaymentMethod.COD;
}
