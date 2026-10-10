using Microsoft.AspNetCore.Authorization;

namespace WebBanHang.Api.Common;

public class PermissionRequirement(string permission) : IAuthorizationRequirement
{
    public string Permission { get; } = permission;
}
