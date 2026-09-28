using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Users;

public class UserQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc người dùng theo vai trò: ADMIN hoặc USER
    /// </summary>
    /// <example>ADMIN</example>
    public string? Role { get; set; }

    /// <summary>
    /// Lọc theo trạng thái tài khoản: true (bị khóa), false (đang hoạt động)
    /// </summary>
    /// <example>false</example>
    public bool? IsLocked { get; set; }
}
