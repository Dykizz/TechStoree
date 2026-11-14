using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Trạng thái tiến trình của đơn đặt hàng:
/// PENDING (Chờ xử lý), CONFIRMED (Đã xác nhận), SHIPPING (Đang vận chuyển), 
/// DELIVERED (Đã giao hàng), CANCELLED (Đã hủy), RETURNED (Hoàn hàng)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum OrderStatus
{
    PENDING,
    CONFIRMED,
    SHIPPING,
    DELIVERED,
    CANCELLED,
    RETURNED
}
