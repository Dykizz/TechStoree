using System.Net;
using System.Text.Json;
using WebBanHang.Api.Common;
using WebBanHang.Api.Exceptions;

namespace WebBanHang.Api.Middlewares;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger, IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var statusCode = HttpStatusCode.InternalServerError;
        string message = "Đã xảy ra lỗi trên hệ thống máy chủ.";
        object? errors = null;

        switch (exception)
        {
            case AppException appEx:
                statusCode = appEx.StatusCode;
                message = appEx.Message;
                errors = appEx.Errors;
                _logger.LogWarning("Ngoại lệ nghiệp vụ [{StatusCode}]: {Message}", (int)statusCode, message);
                break;

            case KeyNotFoundException keyEx:
                statusCode = HttpStatusCode.NotFound;
                message = keyEx.Message.Length > 0 ? keyEx.Message : "Không tìm thấy tài nguyên yêu cầu.";
                _logger.LogWarning("Không tìm thấy: {Message}", message);
                break;

            case UnauthorizedAccessException:
                statusCode = HttpStatusCode.Unauthorized;
                message = "Bạn không có quyền truy cập tài nguyên này.";
                _logger.LogWarning("Truy cập trái phép: {Path}", context.Request.Path);
                break;

            default:
                _logger.LogError(exception, "Lỗi chưa được xử lý (Unhandled Exception): {Message}", exception.Message);
                if (_env.IsDevelopment())
                {
                    message = exception.Message;
                    errors = new
                    {
                        exceptionType = exception.GetType().Name,
                        stackTrace = exception.StackTrace
                    };
                }
                else
                {
                    message = "Đã có lỗi hệ thống phát sinh. Vui lòng liên hệ quản trị viên.";
                }
                break;
        }

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)statusCode;

        var response = ApiResponse.FailureResult(message, errors);
        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        var json = JsonSerializer.Serialize(response, jsonOptions);
        await context.Response.WriteAsync(json);
    }
}
