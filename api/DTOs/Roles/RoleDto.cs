namespace WebBanHang.Api.DTOs.Roles;

public class RoleDto
{
    /// <summary>
    /// Mã định danh vai trò (GUID hoặc mã vai trò hệ thống: ADMIN, WAREHOUSE_STAFF...)
    /// </summary>
    /// <example>7c9e6679-7425-40de-944b-e07fc1f90ae7</example>
    public string RoleId { get; set; } = string.Empty;

    /// <summary>
    /// Tên hiển thị của vai trò
    /// </summary>
    /// <example>Nhân viên Chăm sóc Khách hàng</example>
    public string RoleName { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả chi tiết vai trò
    /// </summary>
    /// <example>Hỗ trợ tư vấn khách hàng và tra cứu đơn hàng</example>
    public string? Description { get; set; }

    /// <summary>
    /// Đánh dấu là vai trò mặc định của hệ thống (không được xóa)
    /// </summary>
    /// <example>false</example>
    public bool IsSystem { get; set; }

    /// <summary>
    /// Số lượng người dùng đang được gán vai trò này
    /// </summary>
    /// <example>3</example>
    public int UserCount { get; set; }

    /// <summary>
    /// Danh sách mã quyền hạn được cấp cho vai trò
    /// </summary>
    /// <example>["Products.View", "Orders.View", "Orders.Update"]</example>
    public List<string> Permissions { get; set; } = new();
}

public class RoleDetailDto : RoleDto
{
    /// <summary>
    /// Chi tiết danh mục các quyền hạn của vai trò
    /// </summary>
    public List<PermissionDto> PermissionDetails { get; set; } = new();
}
