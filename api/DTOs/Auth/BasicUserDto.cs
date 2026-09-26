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
    /// Vai trò người dùng (ADMIN hoặc USER)
    /// </summary>
    /// <example>ADMIN</example>
    public string Role { get; set; } = string.Empty;
}
