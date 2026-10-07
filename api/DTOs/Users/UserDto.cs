namespace WebBanHang.Api.DTOs.Users;

public class UserDto
{
    /// <summary>
    /// Mã ID duy nhất của người dùng
    /// </summary>
    /// <example>1</example>
    public int UserId { get; set; }

    /// <summary>
    /// Tên tài khoản
    /// </summary>
    /// <example>nguyenvana</example>
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Họ và tên
    /// </summary>
    /// <example>Nguyễn Văn Anh Cập Nhật</example>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email
    /// </summary>
    /// <example>user@example.com</example>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại
    /// </summary>
    /// <example>0988776655</example>
    public string? Phone { get; set; }

    /// <summary>
    /// Ngày sinh
    /// </summary>
    /// <example>2001-08-20T00:00:00Z</example>
    public DateTime? DateOfBirth { get; set; }

    /// <summary>
    /// Tuổi (tính tự động theo năm sinh)
    /// </summary>
    /// <example>25</example>
    public int Age => DateOfBirth.HasValue ? DateTime.UtcNow.Year - DateOfBirth.Value.Year : 0;

    /// <summary>
    /// Sở thích công nghệ
    /// </summary>
    /// <example>Gaming</example>
    public string? TechInterest { get; set; }

    /// <summary>
    /// Địa chỉ cư trú
    /// </summary>
    /// <example>456 Nguyễn Huệ, Q.1, TP.HCM</example>
    public string? Address { get; set; }

    /// <summary>
    /// Danh sách vai trò của người dùng (RBAC)
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

    /// <summary>
    /// Mã ID người dùng / Admin khởi tạo tài khoản này (null nếu tự đăng ký)
    /// </summary>
    /// <example>1</example>
    public int? CreatedByUserId { get; set; }
}
