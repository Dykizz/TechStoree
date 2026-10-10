using Microsoft.AspNetCore.Authorization;

namespace WebBanHang.Api.Common;

/// <summary>
/// Attribute phân quyền chi tiết (PBAC) dựa trên mã quyền Permission
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true, Inherited = true)]
public class HasPermissionAttribute : AuthorizeAttribute
{
    public const string PolicyPrefix = "Permission:";

    public HasPermissionAttribute(string permission)
    {
        Permission = permission;
        Policy = $"{PolicyPrefix}{permission}";
    }

    public string Permission { get; }
}
