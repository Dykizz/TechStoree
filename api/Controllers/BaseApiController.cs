using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;

namespace WebBanHang.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public abstract class BaseApiController : ControllerBase
{
    /// <summary>
    /// ID của người dùng đang đăng nhập lấy từ JWT Claim (ClaimTypes.NameIdentifier)
    /// </summary>
    protected int CurrentUserId =>
        int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : 0;

    /// <summary>
    /// Tên đăng nhập (Username) lấy từ JWT Claim (ClaimTypes.Name)
    /// </summary>
    protected string CurrentUsername =>
        User.FindFirst(ClaimTypes.Name)?.Value ?? string.Empty;

    /// <summary>
    /// Vai trò của người dùng: ADMIN, CRM_MANAGER, CUSTOMER (ClaimTypes.Role)
    /// </summary>
    protected string CurrentUserRole =>
        User.FindFirst(ClaimTypes.Role)?.Value ?? string.Empty;

    /// <summary>
    /// Kiểm tra người dùng đã được xác thực qua JWT token hay chưa
    /// </summary>
    protected bool IsAuthenticated =>
        User.Identity?.IsAuthenticated ?? false;

    /// <summary>
    /// Kiểm tra người dùng hiện tại có vai trò ADMIN hay không
    /// </summary>
    protected bool IsAdmin =>
        User.IsInRole("ADMIN") || string.Equals(CurrentUserRole, "ADMIN", StringComparison.OrdinalIgnoreCase);

    /// <summary>
    /// Trả về kết quả thành công HTTP 200 OK kèm dữ liệu được bọc trong ApiResponse
    /// </summary>
    protected IActionResult Success<T>(T data, string message = "Thao tác thành công") =>
        Ok(ApiResponse<T>.SuccessResult(data, message));

    /// <summary>
    /// Trả về kết quả thành công HTTP 200 OK không kèm dữ liệu
    /// </summary>
    protected IActionResult Success(string message = "Thao tác thành công") =>
        Ok(ApiResponse.SuccessResult(message));

    /// <summary>
    /// Trả về kết quả tạo mới thành công HTTP 201 Created kèm dữ liệu
    /// </summary>
    protected IActionResult CreatedSuccess<T>(T data, string message = "Tạo mới thành công") =>
        StatusCode(StatusCodes.Status201Created, ApiResponse<T>.SuccessResult(data, message));
}
