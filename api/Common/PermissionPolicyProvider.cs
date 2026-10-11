using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Options;

namespace WebBanHang.Api.Common;

/// <summary>
/// Tự động sinh AuthorizationPolicy tương ứng khi endpoint dùng attribute [HasPermission(...)]
/// </summary>
public class PermissionPolicyProvider(IOptions<AuthorizationOptions> options) : DefaultAuthorizationPolicyProvider(options)
{
    public override async Task<AuthorizationPolicy?> GetPolicyAsync(string policyName)
    {
        if (policyName.StartsWith(HasPermissionAttribute.PolicyPrefix, StringComparison.OrdinalIgnoreCase))
        {
            var permission = policyName[HasPermissionAttribute.PolicyPrefix.Length..];
            var policy = new AuthorizationPolicyBuilder();
            policy.AddRequirements(new PermissionRequirement(permission));
            return policy.Build();
        }

        return await base.GetPolicyAsync(policyName);
    }
}
