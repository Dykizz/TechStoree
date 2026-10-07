namespace WebBanHang.Api.DTOs.Auth;

public class UserInfoDto
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
    /// Địa chỉ email
    /// </summary>
    /// <example>tai@example.com</example>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Họ và tên
    /// </summary>
    /// <example>Quản trị viên Hệ thống</example>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại
    /// </summary>
    /// <example>0987654321</example>
    public string? Phone { get; set; }

    /// <summary>
    /// Ngày sinh
    /// </summary>
    /// <example>2000-01-15T00:00:00Z</example>
    public DateTime? DateOfBirth { get; set; }

    /// <summary>
    /// Sở thích công nghệ
    /// </summary>
    /// <example>Gaming</example>
    public string? TechInterest { get; set; }

    /// <summary>
    /// Địa chỉ cư trú
    /// </summary>
    /// <example>TP. Hồ Chí Minh</example>
    public string? Address { get; set; }

    /// <summary>
    /// Danh sách vai trò của tài khoản (RBAC)
    /// </summary>
    /// <example>["ADMIN"]</example>
    public List<string> Roles { get; set; } = new();

    /// <summary>
    /// Vai trò chính (Hỗ trợ tương thích ngược cho client cũ)
    /// </summary>
    /// <example>ADMIN</example>
    public string Role => Roles.FirstOrDefault() ?? "USER";

    /// <summary>
    /// Trạng thái khóa tài khoản
    /// </summary>
    /// <example>false</example>
    public bool IsLocked { get; set; }

    /// <summary>
    /// Thời điểm khởi tạo tài khoản (UTC)
    /// </summary>
    /// <example>2026-01-01T00:00:00Z</example>
    public DateTime CreatedAt { get; set; }
}
