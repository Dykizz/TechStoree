using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Trạng thái của hóa đơn:
/// UNPAID (Chưa trả / Chờ thanh toán COD hoặc chuyển khoản),
/// PAID (Đã trả / Đã thanh toán thành công),
/// CANCELLED (Bị hủy do hủy đơn hoặc hoàn trả)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum InvoiceStatus
{
    UNPAID,
    PAID,
    CANCELLED
}
