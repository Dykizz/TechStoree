using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace WebBanHang.Api.Common;

/// <summary>
/// Loại bỏ khối JSON Schema / Example mặc định (ProblemDetails) khỏi các mã lỗi 4xx và 5xx trên Swagger UI.
/// Chỉ giữ lại mô tả trạng thái mã lỗi (Description) giúp giao diện Swagger gọn gàng và tránh gây hiểu nhầm.
/// </summary>
public class RemoveErrorSchemasFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        if (operation.Responses == null) return;

        foreach (var (statusCode, response) in operation.Responses)
        {
            if (int.TryParse(statusCode, out var code) && code >= 400)
            {
                response.Content?.Clear();
            }
        }
    }
}
