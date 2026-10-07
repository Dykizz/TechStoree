namespace WebBanHang.Api.DTOs.Auth;

public class BasicUserDto
{
    /// <summary>
    /// Mã ID duy nhất của người dùng
    /// </summary>
    /// <example>1</example>
    public int UserId { get; set; }

    /// <summary>
    /// Tên đăng nhập
    /// </summary>
    /// <example>admin</example>
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Họ và tên
    /// </summary>
    /// <example>Quản trị viên Hệ thống</example>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email
    /// </summary>
    /// <example>tai@example.com</example>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Danh sách các vai trò của người dùng (RBAC)
    /// </summary>
    /// <example>["ADMIN"]</example>
    public List<string> Roles { get; set; } = new();

    /// <summary>
    /// Vai trò chính (Hỗ trợ tương thích ngược cho client cũ)
    /// </summary>
    /// <example>ADMIN</example>
    public string Role => Roles.FirstOrDefault() ?? "USER";
}
