using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Invoices;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Hóa đơn thanh toán (Invoices)
/// </summary>
[Route("api/[controller]")]
[Authorize]
[Tags("Invoices")]
public class InvoicesController(IInvoiceService invoiceService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách hóa đơn của người dùng đang đăng nhập
    /// </summary>
    [HttpGet("my-invoices")]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<InvoiceDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyInvoices([FromQuery] InvoiceQueryFilter filter)
    {
        var result = await invoiceService.GetMyInvoicesAsync(CurrentUserId, filter);
        return Success(result, "Lấy danh sách hóa đơn của bạn thành công.");
    }

    /// <summary>
    /// [ADMIN / BÁN HÀNG] Tra cứu toàn bộ danh sách hóa đơn trong hệ thống
    /// </summary>
    [HttpGet("admin/all")]
    [HasPermission(AppPermissions.Invoices.View)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<InvoiceDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetAllInvoices([FromQuery] InvoiceQueryFilter filter)
    {
        var result = await invoiceService.GetAllInvoicesAsync(filter);
        return Success(result, "Lấy danh sách quản lý hóa đơn thành công.");
    }

    /// <summary>
    /// Xem chi tiết một hóa đơn theo ID
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<InvoiceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetInvoiceById(int id)
    {
        var result = await invoiceService.GetInvoiceByIdAsync(id, IsAdmin ? null : CurrentUserId)
            ?? throw new NotFoundException($"Không tìm thấy hóa đơn có mã ID = {id}.");

        return Success(result, "Lấy thông tin chi tiết hóa đơn thành công.");
    }

    /// <summary>
    /// Tra cứu hóa đơn theo mã đơn hàng (OrderId)
    /// </summary>
    [HttpGet("by-order/{orderId:int}")]
    [ProducesResponseType(typeof(ApiResponse<InvoiceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetInvoiceByOrderId(int orderId)
    {
        var result = await invoiceService.GetInvoiceByOrderIdAsync(orderId, IsAdmin ? null : CurrentUserId)
            ?? throw new NotFoundException($"Không tìm thấy hóa đơn cho đơn hàng ID = {orderId}.");

        return Success(result, "Lấy thông tin hóa đơn của đơn hàng thành công.");
    }
}
