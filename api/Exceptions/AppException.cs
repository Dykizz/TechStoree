using System.Net;

namespace WebBanHang.Api.Exceptions;

public class AppException : Exception
{
    public HttpStatusCode StatusCode { get; }
    public object? Errors { get; }

    public AppException(string message, HttpStatusCode statusCode = HttpStatusCode.BadRequest, object? errors = null) 
        : base(message)
    {
        StatusCode = statusCode;
        Errors = errors;
    }
}

public class NotFoundException : AppException
{
    public NotFoundException(string message) 
        : base(message, HttpStatusCode.NotFound)
    {
    }
}

public class BadRequestException : AppException
{
    public BadRequestException(string message, object? errors = null) 
        : base(message, HttpStatusCode.BadRequest, errors)
    {
    }
}

public class UnauthorizedException : AppException
{
    public UnauthorizedException(string message = "Bạn chưa đăng nhập hoặc phiên làm việc đã hết hạn.") 
        : base(message, HttpStatusCode.Unauthorized)
    {
    }
}

public class ForbiddenException : AppException
{
    public ForbiddenException(string message = "Bạn không có quyền thực hiện thao tác này.") 
        : base(message, HttpStatusCode.Forbidden)
    {
    }
}

public class ConflictException : AppException
{
    public ConflictException(string message) 
        : base(message, HttpStatusCode.Conflict)
    {
    }
}
