using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Trạng thái tiến trình của đơn đặt hàng:
/// PENDING (Chờ xác nhận), CONFIRMED (Đã xác nhận), SHIPPING (Đang vận chuyển), 
/// DELIVERED (Đã giao hàng thành công), CANCELLED (Đã hủy đơn)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum OrderStatus
{
    PENDING,
    CONFIRMED,
    SHIPPING,
    DELIVERED,
    CANCELLED
}
