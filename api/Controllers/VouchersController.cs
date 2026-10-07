using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Vouchers;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Voucher giảm giá hóa đơn (Mã giảm giá bill, ví cá nhân và phân phối CRM)
/// </summary>
[Route("api/vouchers")]
[Tags("Vouchers")]
public class VouchersController(IVoucherService voucherService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách tất cả các voucher toàn sàn (Dành cho Quản trị viên, hỗ trợ tìm kiếm và lọc trạng thái)
    /// </summary>
    /// <param name="filter">Bộ lọc: status (UPCOMING, ACTIVE, EXPIRED), isActive, fromDate, toDate, search</param>
    [HttpGet]
    [AuthorizeRoles(UserRoleType.ADMIN, UserRoleType.SALES_STAFF)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<VoucherBaseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllVouchers([FromQuery] VoucherQueryFilter filter)
    {
        var result = await voucherService.GetAllVouchersAsync(filter);
        return Success(result, "Lấy danh sách voucher thành công.");
    }

    /// <summary>
    /// Lấy danh sách các voucher công khai đang có hiệu lực để khách hàng thu thập hoặc áp dụng
    /// </summary>
    [HttpGet("available")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<VoucherBaseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAvailableVouchers()
    {
        var result = await voucherService.GetAvailableVouchersAsync();
        return Success(result, "Lấy danh sách voucher khả dụng thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một voucher theo ID
    /// </summary>
    /// <param name="id">Mã ID voucher</param>
    [HttpGet("{id:int}")]
    [AuthorizeRoles(UserRoleType.ADMIN, UserRoleType.SALES_STAFF)]
    [ProducesResponseType(typeof(ApiResponse<VoucherDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVoucherById([FromRoute] int id)
    {
        var result = await voucherService.GetVoucherByIdAsync(id)
            ?? throw new NotFoundException($"Không tìm thấy voucher với mã ID = {id}.");

        return Success(result, "Lấy chi tiết voucher thành công.");
    }

    /// <summary>
    /// Tạo mới một chiến dịch voucher (Yêu cầu quyền ADMIN)
    /// </summary>
    [HttpPost]
    [AuthorizeRoles(UserRoleType.ADMIN, UserRoleType.SALES_STAFF)]
    [ProducesResponseType(typeof(ApiResponse<VoucherDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateVoucher([FromBody] VoucherUpsertRequestDto request)
    {
        var result = await voucherService.CreateVoucherAsync(request);
        return CreatedSuccess(result, "Tạo mới voucher thành công.");
    }

    /// <summary>
    /// Cập nhật chiến dịch voucher có kiểm soát vòng đời (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID voucher cần sửa</param>
    /// <param name="request">Thông tin cập nhật</param>
    [HttpPut("{id:int}")]
    [AuthorizeRoles(UserRoleType.ADMIN, UserRoleType.SALES_STAFF)]
    [ProducesResponseType(typeof(ApiResponse<VoucherDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateVoucher([FromRoute] int id, [FromBody] VoucherUpsertRequestDto request)
    {
        var result = await voucherService.UpdateVoucherAsync(id, request)
            ?? throw new NotFoundException($"Không tìm thấy voucher với mã ID = {id}.");

        return Success(result, "Cập nhật voucher thành công.");
    }

    /// <summary>
    /// Bật hoặc Tắt kích hoạt nhanh voucher (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID voucher</param>
    [HttpPatch("{id:int}/toggle-active")]
    [AuthorizeRoles(UserRoleType.ADMIN, UserRoleType.SALES_STAFF)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleActive([FromRoute] int id)
    {
        var newStatus = await voucherService.ToggleActiveAsync(id)
            ?? throw new NotFoundException($"Không tìm thấy voucher với mã ID = {id}.");

        var statusMessage = newStatus ? "Kích hoạt voucher thành công." : "Tạm ngưng kích hoạt voucher thành công.";
        return Success(new { isActive = newStatus }, statusMessage);
    }

    /// <summary>
    /// Xóa voucher chưa diễn ra (Yêu cầu quyền ADMIN, chặn xóa nếu voucher đã hoặc đang diễn ra hoặc đã có lượt dùng)
    /// </summary>
    /// <param name="id">Mã ID voucher cần xóa</param>
    [HttpDelete("{id:int}")]
    [AuthorizeRoles(UserRoleType.ADMIN, UserRoleType.SALES_STAFF)]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteVoucher([FromRoute] int id)
    {
        var deleted = await voucherService.DeleteVoucherAsync(id);
        if (!deleted)
        {
            throw new NotFoundException($"Không tìm thấy voucher có mã ID = {id}.");
        }

        return Success<object?>(null, "Xóa voucher thành công.");
    }

    /// <summary>
    /// Kiểm tra và tính toán giảm giá khi áp dụng mã voucher cho giỏ hàng
    /// </summary>
    /// <param name="request">Mã voucher và tổng tiền đơn hàng trước giảm</param>
    [HttpPost("apply")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<ApplyVoucherResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ApplyVoucherResponseDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ApplyVoucher([FromBody] ApplyVoucherRequestDto request)
    {
        int? userId = IsAuthenticated ? CurrentUserId : null;
        var result = await voucherService.ApplyVoucherAsync(request, userId);

        if (!result.IsValid)
        {
            return BadRequest(new ApiResponse<ApplyVoucherResponseDto>
            {
                Success = false,
                Message = result.Message,
                Data = result
            });
        }

        return Success(result, result.Message);
    }

    /// <summary>
    /// Lấy danh sách voucher trong Ví cá nhân của khách hàng đang đăng nhập
    /// </summary>
    /// <param name="status">Lọc theo trạng thái: USABLE (Có thể dùng ngay), USED (Đã dùng), EXPIRED (Hết hạn)</param>
    [HttpGet("my-wallet")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<UserVoucherItemDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyWallet([FromQuery] UserVoucherWalletStatus? status)
    {
        var result = await voucherService.GetMyVouchersAsync(CurrentUserId, status);
        return Success(result, "Lấy danh sách voucher trong ví thành công.");
    }

    /// <summary>
    /// Khách hàng thu thập / lưu một voucher công khai vào ví cá nhân
    /// </summary>
    /// <param name="id">Mã ID voucher muốn lưu</param>
    [HttpPost("{id:int}/claim")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<UserVoucherItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ClaimVoucher([FromRoute] int id)
    {
        var result = await voucherService.ClaimVoucherAsync(id, CurrentUserId);
        return Success(result, "Đã lưu voucher vào ví thành công.");
    }
}
