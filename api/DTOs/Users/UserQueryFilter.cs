using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Users;

public class UserQueryFilter : PaginationParams
{
    public string? Role { get; set; }
    public bool? IsLocked { get; set; }
}
