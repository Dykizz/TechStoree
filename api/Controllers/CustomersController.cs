using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý hồ sơ Khách hàng và nhân khẩu học (CRM Customers)
/// </summary>
[Tags("Customers")]
public class CustomersController(IUserService userService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách khách hàng có phân trang và bộ lọc (trạng thái khóa, sở thích công nghệ, từ khóa)
    /// </summary>
    /// <param name="filter">Bộ lọc danh sách khách hàng</param>
    [HttpGet]
    [HasPermission(AppPermissions.Customers.View)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<UserDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetCustomers([FromQuery] CustomerQueryFilter filter)
    {
        var result = await userService.GetCustomersAsync(filter);
        return Success(result, "Lấy danh sách khách hàng thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một khách hàng theo ID
    /// </summary>
    /// <param name="id">Mã ID khách hàng</param>
    [HttpGet("{id:int}")]
    [HasPermission(AppPermissions.Customers.View)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCustomerById(int id)
    {
        var result = await userService.GetCustomerByIdAsync(id);
        return Success(result, "Lấy thông tin khách hàng thành công.");
    }

    /// <summary>
    /// [Admin / CRM] Báo cáo phân tích nhân khẩu học khách hàng (Độ tuổi và Sở thích công nghệ)
    /// </summary>
    [HttpGet("demographics")]
    [HasPermission(AppPermissions.Customers.View)]
    [ProducesResponseType(typeof(ApiResponse<DemographicsReportDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetDemographicsReport()
    {
        var result = await userService.GetDemographicsReportAsync();
        return Success(result, "Lấy báo cáo phân tích nhân khẩu học khách hàng thành công.");
    }

    /// <summary>
    /// Tạo mới tài khoản khách hàng (luôn gán vai trò USER)
    /// </summary>
    /// <param name="dto">Thông tin tài khoản khách hàng</param>
    [HttpPost]
    [HasPermission(AppPermissions.Customers.Create)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerRequestDto dto)
    {
        var result = await userService.CreateCustomerAsync(CurrentUserId, dto);
        return CreatedSuccess(result, "Tạo mới tài khoản khách hàng thành công.");
    }

    /// <summary>
    /// Cập nhật thông tin hồ sơ khách hàng
    /// </summary>
    /// <param name="id">Mã ID khách hàng</param>
    /// <param name="dto">Dữ liệu cập nhật khách hàng</param>
    [HttpPut("{id:int}")]
    [HasPermission(AppPermissions.Customers.Update)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCustomer(int id, [FromBody] UpdateCustomerRequestDto dto)
    {
        var result = await userService.UpdateCustomerAsync(id, dto);
        return Success(result, "Cập nhật thông tin khách hàng thành công.");
    }

    /// <summary>
    /// Khóa hoặc Mở khóa tài khoản khách hàng
    /// </summary>
    /// <param name="id">Mã ID khách hàng</param>
    /// <param name="dto">Trạng thái khóa cụ thể (hoặc để trống để toggle đảo ngược)</param>
    [HttpPatch("{id:int}/toggle-lock")]
    [HasPermission(AppPermissions.Customers.Lock)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleLock(int id, [FromBody(EmptyBodyBehavior = Microsoft.AspNetCore.Mvc.ModelBinding.EmptyBodyBehavior.Allow)] ToggleLockRequestDto? dto = null)
    {
        if (id == CurrentUserId)
        {
            throw new BadRequestException("Bạn không thể tự khóa tài khoản của chính mình.");
        }

        var result = await userService.ToggleCustomerLockAsync(id, dto);
        var message = result.IsLocked ? "Đã khóa tài khoản khách hàng thành công." : "Đã mở khóa tài khoản khách hàng thành công.";
        return Success(result, message);
    }
}
