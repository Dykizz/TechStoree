using Microsoft.AspNetCore.Authorization;
using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace WebBanHang.Api.Common;

/// <summary>
/// Tự động đánh dấu biểu tượng ổ khóa (Padlock) và yêu cầu JWT Bearer Token trên Swagger UI
/// cho tất cả các Controller / Action có khai báo attribute [Authorize].
/// </summary>
public class AuthorizeCheckOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var classAuthorizeAttrs = context.MethodInfo.DeclaringType?
            .GetCustomAttributes(true)
            .OfType<AuthorizeAttribute>() ?? Enumerable.Empty<AuthorizeAttribute>();

        var methodAuthorizeAttrs = context.MethodInfo
            .GetCustomAttributes(true)
            .OfType<AuthorizeAttribute>();

        var allAuthorizeAttrs = classAuthorizeAttrs.Concat(methodAuthorizeAttrs).ToList();

        var allowAnonymous = context.MethodInfo
            .GetCustomAttributes(true)
            .OfType<AllowAnonymousAttribute>()
            .Any();

        if (allAuthorizeAttrs.Any() && !allowAnonymous)
        {
            operation.Responses ??= new OpenApiResponses();

            if (!operation.Responses.ContainsKey("401"))
            {
                operation.Responses.Add("401", new OpenApiResponse { Description = "Chưa xác thực (Thiếu hoặc Token không hợp lệ)" });
            }

            if (!operation.Responses.ContainsKey("403"))
            {
                operation.Responses.Add("403", new OpenApiResponse { Description = "Từ chối truy cập (Tài khoản không đủ quyền hạn)" });
            }

            var schemeRef = new OpenApiSecuritySchemeReference("Bearer", context.Document);
            operation.Security = new List<OpenApiSecurityRequirement>
            {
                new OpenApiSecurityRequirement
                {
                    [schemeRef] = new List<string>()
                }
            };

            // Bổ sung thông tin Role cần thiết vào Description nếu có
            var roles = allAuthorizeAttrs
                .Where(a => !string.IsNullOrWhiteSpace(a.Roles))
                .Select(a => a.Roles)
                .Distinct()
                .ToList();

            if (roles.Count > 0)
            {
                var roleInfo = $"\n\n> 🔒 **Yêu cầu quyền:** `{string.Join(", ", roles)}`";
                operation.Description = string.IsNullOrWhiteSpace(operation.Description)
                    ? roleInfo
                    : operation.Description + roleInfo;
            }
        }
    }
}
