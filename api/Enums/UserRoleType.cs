using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Các vai trò người dùng (RBAC) chuẩn hóa trong hệ thống Web Bán Hàng / CRM
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum UserRoleType
{
    /// <summary>
    /// Quản trị viên hệ thống (Toàn quyền quản trị)
    /// </summary>
    ADMIN,

    /// <summary>
    /// Khách hàng / Người dùng phổ thông
    /// </summary>
    USER
}

public static class UserRoleTypeExtensions
{
    public const string Admin = nameof(UserRoleType.ADMIN);
    public const string User = nameof(UserRoleType.USER);

    public static string GetRoleName(this UserRoleType role) => role switch
    {
        UserRoleType.ADMIN => "Quản trị viên",
        UserRoleType.USER => "Người dùng",
        _ => "Không xác định"
    };
}
