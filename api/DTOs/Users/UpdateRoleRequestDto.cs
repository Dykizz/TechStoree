namespace WebBanHang.Api.DTOs.Users;

public class UpdateRoleRequestDto
{
    /// <summary>
    /// Danh sách các vai trò mới phân quyền cho tài khoản (Ví dụ: ["SALES_STAFF", "WAREHOUSE_STAFF"])
    /// </summary>
    /// <example>["SALES_STAFF", "WAREHOUSE_STAFF"]</example>
    public List<string>? Roles { get; set; }

    /// <summary>
    /// Mã vai trò đơn lẻ (Dành cho tương thích ngược nếu client gửi 1 role duy nhất)
    /// </summary>
    /// <example>ADMIN</example>
    public string? RoleId { get; set; }
}
