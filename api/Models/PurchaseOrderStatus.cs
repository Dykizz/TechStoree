using System.Text.Json.Serialization;

namespace WebBanHang.Api.Models;

/// <summary>
/// Trạng thái của phiếu nhập hàng: DRAFT (Bản nháp), COMPLETED (Đã nhập kho)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum PurchaseOrderStatus
{
    DRAFT,
    COMPLETED
}
