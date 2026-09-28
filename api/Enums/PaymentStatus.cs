using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Trạng thái thanh toán của đơn hàng:
/// PENDING (Chờ thanh toán), PAID (Đã thanh toán), FAILED (Thanh toán thất bại), REFUNDED (Đã hoàn tiền)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum PaymentStatus
{
    PENDING,
    PAID,
    FAILED,
    REFUNDED
}
