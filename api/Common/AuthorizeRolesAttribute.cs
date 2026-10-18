using Microsoft.AspNetCore.Authorization;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.Common;

/// <summary>
/// Custom Authorization Attribute cho phép truyền trực tiếp Enum UserRoleType thay vì gõ Magic Strings
/// Giúp tận dụng gợi ý mã (IntelliSense) và ngăn ngừa lỗi gõ sai tên vai trò khi biên dịch.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true, Inherited = true)]
public class AuthorizeRolesAttribute : AuthorizeAttribute
{
    public AuthorizeRolesAttribute(params UserRoleType[] roles)
    {
        if (roles != null && roles.Length > 0)
        {
            Roles = string.Join(",", roles.Select(r => r.ToString()));
        }
    }
}
