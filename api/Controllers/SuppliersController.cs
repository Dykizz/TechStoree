using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Suppliers;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

[Authorize(Roles = "ADMIN")]
public class SuppliersController(ISupplierService supplierService) : BaseApiController
{
    [HttpGet]
    public async Task<IActionResult> GetSuppliers([FromQuery] PaginationParams filter)
    {
        var result = await supplierService.GetSuppliersAsync(filter);
        return Success(result, "Lấy danh sách nhà cung cấp thành công.");
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetSupplierById(int id)
    {
        var result = await supplierService.GetSupplierByIdAsync(id);
        return Success(result, "Lấy thông tin nhà cung cấp thành công.");
    }

    [HttpPost]
    public async Task<IActionResult> CreateSupplier([FromBody] SupplierUpsertRequestDto dto)
    {
        var result = await supplierService.CreateSupplierAsync(dto);
        return CreatedSuccess(result, "Thêm mới nhà cung cấp thành công.");
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> UpdateSupplier(int id, [FromBody] SupplierUpsertRequestDto dto)
    {
        var result = await supplierService.UpdateSupplierAsync(id, dto);
        return Success(result, "Cập nhật nhà cung cấp thành công.");
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeleteSupplier(int id)
    {
        await supplierService.DeleteSupplierAsync(id);
        return Success<object?>(null, "Xóa nhà cung cấp thành công.");
    }
}
