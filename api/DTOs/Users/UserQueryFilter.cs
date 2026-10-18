using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Users;

public class UserQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc người dùng theo vai trò: ADMIN, WAREHOUSE_STAFF, SALES_STAFF, SURVEY_STAFF, USER
    /// </summary>
    /// <example>ADMIN</example>
    public string? Role { get; set; }

    /// <summary>
    /// Lọc danh sách nhân sự nội bộ (true: chỉ nhân viên, false: chỉ khách hàng, null: tất cả)
    /// </summary>
    /// <example>true</example>
    public bool? IsStaffOnly { get; set; }

    /// <summary>
    /// Lọc theo trạng thái tài khoản: true (bị khóa), false (đang hoạt động)
    /// </summary>
    /// <example>false</example>
    public bool? IsLocked { get; set; }
}
