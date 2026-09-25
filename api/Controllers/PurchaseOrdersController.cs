using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.PurchaseOrders;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

[Route("api/purchase-orders")]
[Authorize(Roles = "ADMIN,CRM_MANAGER")]
public class PurchaseOrdersController(IPurchaseOrderService purchaseOrderService) : BaseApiController
{
    [HttpGet]
    public async Task<IActionResult> GetPurchaseOrders([FromQuery] PurchaseOrderQueryFilter filter)
    {
        var result = await purchaseOrderService.GetPurchaseOrdersAsync(filter);
        return Success(result, "Lấy danh sách phiếu nhập hàng thành công.");
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetPurchaseOrderById(int id)
    {
        var result = await purchaseOrderService.GetPurchaseOrderByIdAsync(id);
        return Success(result, "Lấy chi tiết phiếu nhập hàng thành công.");
    }

    [HttpPost]
    public async Task<IActionResult> CreatePurchaseOrder([FromBody] PurchaseOrderCreateRequestDto dto)
    {
        var result = await purchaseOrderService.CreatePurchaseOrderAsync(CurrentUserId, dto);
        return CreatedSuccess(result, "Tạo phiếu nhập hàng thành công.");
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> UpdatePurchaseOrder(int id, [FromBody] PurchaseOrderUpdateRequestDto dto)
    {
        var result = await purchaseOrderService.UpdatePurchaseOrderAsync(id, dto);
        return Success(result, "Cập nhật phiếu nhập hàng thành công.");
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeletePurchaseOrder(int id)
    {
        await purchaseOrderService.DeletePurchaseOrderAsync(id);
        return Success<object?>(null, "Xóa phiếu nhập hàng thành công.");
    }
}
