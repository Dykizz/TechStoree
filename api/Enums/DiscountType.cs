using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Loại hình giảm giá áp dụng cho Voucher và Khuyến mãi
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum DiscountType
{
    /// <summary>
    /// Giảm theo tỷ lệ phần trăm (%)
    /// </summary>
    PERCENTAGE,

    /// <summary>
    /// Giảm theo số tiền cố định (VNĐ)
    /// </summary>
    FIXED_AMOUNT
}
