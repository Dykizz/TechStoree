using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.PurchaseOrders;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Nhập hàng từ Nhà cung cấp (Purchase Orders)
/// </summary>
[Route("api/purchase-orders")]
[Tags("Purchase Orders")]
public class PurchaseOrdersController(IPurchaseOrderService purchaseOrderService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách phiếu nhập hàng có phân trang và bộ lọc nâng cao
    /// </summary>
    /// <param name="filter">Bộ lọc theo ngày, trạng thái, nhà cung cấp, tìm kiếm và phân trang</param>
    [HttpGet]
    [HasPermission(AppPermissions.PurchaseOrders.View)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<PurchaseOrderBaseDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetPurchaseOrders([FromQuery] PurchaseOrderQueryFilter filter)
    {
        var result = await purchaseOrderService.GetPurchaseOrdersAsync(filter);
        return Success(result, "Lấy danh sách phiếu nhập hàng thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một phiếu nhập hàng kèm danh sách mặt hàng
    /// </summary>
    /// <param name="id">Mã ID của phiếu nhập</param>
    [HttpGet("{id:int}")]
    [HasPermission(AppPermissions.PurchaseOrders.View)]
    [ProducesResponseType(typeof(ApiResponse<PurchaseOrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPurchaseOrderById(int id)
    {
        var result = await purchaseOrderService.GetPurchaseOrderByIdAsync(id);
        return Success(result, "Lấy chi tiết phiếu nhập hàng thành công.");
    }

    /// <summary>
    /// Tạo mới phiếu nhập hàng (Chọn lưu DRAFT hoặc nhập kho ngay COMPLETED)
    /// </summary>
    /// <param name="dto">Thông tin phiếu nhập và danh sách biến thể sản phẩm</param>
    [HttpPost]
    [HasPermission(AppPermissions.PurchaseOrders.Create)]
    [ProducesResponseType(typeof(ApiResponse<PurchaseOrderDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CreatePurchaseOrder([FromBody] PurchaseOrderCreateRequestDto dto)
    {
        var result = await purchaseOrderService.CreatePurchaseOrderAsync(CurrentUserId, dto);
        return CreatedSuccess(result, "Tạo phiếu nhập hàng thành công.");
    }

    /// <summary>
    /// Cập nhật phiếu nhập hàng (Chỉ cho phép khi phiếu ở trạng thái DRAFT)
    /// </summary>
    /// <param name="id">Mã ID của phiếu nhập</param>
    /// <param name="dto">Dữ liệu cập nhật</param>
    [HttpPut("{id:int}")]
    [HasPermission(AppPermissions.PurchaseOrders.Update)]
    [ProducesResponseType(typeof(ApiResponse<PurchaseOrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdatePurchaseOrder(int id, [FromBody] PurchaseOrderUpdateRequestDto dto)
    {
        var result = await purchaseOrderService.UpdatePurchaseOrderAsync(id, dto);
        return Success(result, "Cập nhật phiếu nhập hàng thành công.");
    }

    /// <summary>
    /// Xóa phiếu nhập hàng (Chỉ cho phép xóa phiếu ở trạng thái DRAFT)
    /// </summary>
    /// <param name="id">Mã ID của phiếu nhập</param>
    [HttpDelete("{id:int}")]
    [HasPermission(AppPermissions.PurchaseOrders.Update)]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeletePurchaseOrder(int id)
    {
        await purchaseOrderService.DeletePurchaseOrderAsync(id);
        return Success<object?>(null, "Xóa phiếu nhập hàng thành công.");
    }
}
