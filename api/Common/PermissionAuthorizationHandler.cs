using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace WebBanHang.Api.Common;

/// <summary>
/// Handler kiểm tra xem người dùng hiện tại có đủ quyền thực thi endpoint hay không
/// </summary>
public class PermissionAuthorizationHandler : AuthorizationHandler<PermissionRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, PermissionRequirement requirement)
    {
        // 1. Quản trị viên tối cao (ADMIN) có toàn quyền trên toàn bộ hệ thống
        if (context.User.IsInRole("ADMIN") ||
            context.User.HasClaim(ClaimTypes.Role, "ADMIN"))
        {
            context.Succeed(requirement);
            return Task.CompletedTask;
        }

        // 2. Kiểm tra danh sách Claim "permission" của người dùng
        var hasPermission = context.User.Claims.Any(c =>
            c.Type == "permission" &&
            string.Equals(c.Value, requirement.Permission, StringComparison.OrdinalIgnoreCase));

        if (hasPermission)
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
