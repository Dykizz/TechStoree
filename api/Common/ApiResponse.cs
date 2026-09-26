namespace WebBanHang.Api.Common;

public class ApiResponse<T>
{
    /// <summary>
    /// Trạng thái thành công hay thất bại của yêu cầu
    /// </summary>
    /// <example>true</example>
    public bool Success { get; set; } = true;

    /// <summary>
    /// Thông điệp phản hồi từ hệ thống
    /// </summary>
    /// <example>Thao tác thành công</example>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// Dữ liệu kết quả nghiệp vụ trả về
    /// </summary>
    public T? Data { get; set; }

    /// <summary>
    /// Chi tiết lỗi nếu có
    /// </summary>
    public object? Errors { get; set; }

    /// <summary>
    /// Thời điểm phản hồi (UTC)
    /// </summary>
    /// <example>2026-09-25T08:30:00Z</example>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public static ApiResponse<T> SuccessResult(T data, string message = "Thao tác thành công")
    {
        return new ApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data
        };
    }

    public static ApiResponse<T> FailureResult(string message, object? errors = null)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Message = message,
            Data = default,
            Errors = errors
        };
    }
}

public class ApiResponse : ApiResponse<object>
{
    public static ApiResponse SuccessResult(string message = "Thao tác thành công")
    {
        return new ApiResponse
        {
            Success = true,
            Message = message,
            Data = null
        };
    }

    public static new ApiResponse FailureResult(string message, object? errors = null)
    {
        return new ApiResponse
        {
            Success = false,
            Message = message,
            Data = null,
            Errors = errors
        };
    }
}
