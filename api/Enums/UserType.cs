using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Loại thực thể người dùng chuẩn hóa trong hệ thống:
/// CUSTOMER: Khách hàng mua sắm (bảng customers)
/// EMPLOYEE: Cán bộ nhân viên nội bộ (bảng employees)
/// ADMIN: Quản trị viên hệ thống (bảng admins)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum UserType
{
    CUSTOMER,
    EMPLOYEE,
    ADMIN
}
