using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Suppliers;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Nhà cung cấp đối tác (Suppliers)
/// </summary>
[Tags("Suppliers")]
public class SuppliersController(ISupplierService supplierService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách nhà cung cấp có phân trang và tìm kiếm
    /// </summary>
    /// <param name="filter">Tham số phân trang, tìm kiếm và sắp xếp</param>
    [HttpGet]
    [HasPermission(AppPermissions.Suppliers.View)]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<SupplierDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetSuppliers([FromQuery] PaginationParams filter)
    {
        var result = await supplierService.GetSuppliersAsync(filter);
        return Success(result, "Lấy danh sách nhà cung cấp thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một nhà cung cấp theo ID
    /// </summary>
    /// <param name="id">Mã ID nhà cung cấp</param>
    [HttpGet("{id:int}")]
    [HasPermission(AppPermissions.Suppliers.View)]
    [ProducesResponseType(typeof(ApiResponse<SupplierDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetSupplierById(int id)
    {
        var result = await supplierService.GetSupplierByIdAsync(id);
        return Success(result, "Lấy thông tin nhà cung cấp thành công.");
    }

    /// <summary>
    /// Thêm mới nhà cung cấp đối tác
    /// </summary>
    /// <param name="dto">Dữ liệu tạo mới nhà cung cấp</param>
    [HttpPost]
    [HasPermission(AppPermissions.Suppliers.Create)]
    [ProducesResponseType(typeof(ApiResponse<SupplierDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateSupplier([FromBody] SupplierUpsertRequestDto dto)
    {
        var result = await supplierService.CreateSupplierAsync(dto);
        return CreatedSuccess(result, "Thêm mới nhà cung cấp thành công.");
    }

    /// <summary>
    /// Cập nhật thông tin nhà cung cấp đối tác
    /// </summary>
    /// <param name="id">Mã ID nhà cung cấp</param>
    /// <param name="dto">Dữ liệu cập nhật nhà cung cấp</param>
    [HttpPut("{id:int}")]
    [HasPermission(AppPermissions.Suppliers.Update)]
    [ProducesResponseType(typeof(ApiResponse<SupplierDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateSupplier(int id, [FromBody] SupplierUpsertRequestDto dto)
    {
        var result = await supplierService.UpdateSupplierAsync(id, dto);
        return Success(result, "Cập nhật nhà cung cấp thành công.");
    }

    /// <summary>
    /// Xóa mềm một nhà cung cấp đối tác
    /// </summary>
    /// <param name="id">Mã ID nhà cung cấp</param>
    [HttpDelete("{id:int}")]
    [HasPermission(AppPermissions.Suppliers.Delete)]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteSupplier(int id)
    {
        await supplierService.DeleteSupplierAsync(id);
        return Success<object?>(null, "Xóa nhà cung cấp thành công.");
    }
}
