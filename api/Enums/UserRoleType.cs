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
    /// Nhân viên quản lý kho / nhập hàng từ nhà cung cấp
    /// </summary>
    WAREHOUSE_STAFF,

    /// <summary>
    /// Nhân viên bán hàng / xử lý đơn hàng, khuyến mãi
    /// </summary>
    SALES_STAFF,

    /// <summary>
    /// Nhân viên khảo sát &amp; CRM / chăm sóc khách hàng
    /// </summary>
    SURVEY_STAFF,

    /// <summary>
    /// Khách hàng / Người dùng phổ thông
    /// </summary>
    USER
}

public static class UserRoleTypeExtensions
{
    public const string Admin = nameof(UserRoleType.ADMIN);
    public const string WarehouseStaff = nameof(UserRoleType.WAREHOUSE_STAFF);
    public const string SalesStaff = nameof(UserRoleType.SALES_STAFF);
    public const string SurveyStaff = nameof(UserRoleType.SURVEY_STAFF);
    public const string User = nameof(UserRoleType.USER);

    public static string GetRoleName(this UserRoleType role) => role switch
    {
        UserRoleType.ADMIN => "Quản trị viên",
        UserRoleType.WAREHOUSE_STAFF => "Nhân viên quản lý kho",
        UserRoleType.SALES_STAFF => "Nhân viên bán hàng",
        UserRoleType.SURVEY_STAFF => "Nhân viên khảo sát & CRM",
        UserRoleType.USER => "Khách hàng",
        _ => "Không xác định"
    };

    public static string GetRoleName(string roleId) => roleId.ToUpper() switch
    {
        Admin => "Quản trị viên",
        WarehouseStaff => "Nhân viên quản lý kho",
        SalesStaff => "Nhân viên bán hàng",
        SurveyStaff => "Nhân viên khảo sát & CRM",
        User => "Khách hàng",
        _ => roleId
    };
}
