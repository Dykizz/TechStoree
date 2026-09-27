using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Phương thức thanh toán của đơn hàng:
/// COD (Thanh toán khi nhận hàng), VNPAY (Cổng VNPAY), BANK_TRANSFER (Chuyển khoản ngân hàng)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum PaymentMethod
{
    COD,
    VNPAY,
    BANK_TRANSFER
}
