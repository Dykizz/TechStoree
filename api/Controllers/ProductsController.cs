using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Products;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

public class ProductsController(IProductService productService) : BaseApiController
{
    [HttpGet]
    public async Task<IActionResult> GetProducts([FromQuery] ProductQueryFilter filter)
    {
        var result = await productService.GetProductsAsync(filter, IsAdmin);
        return Success(result, "Lấy danh sách sản phẩm thành công.");
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetProductById(int id)
    {
        var result = await productService.GetProductByIdAsync(id, IsAdmin);
        return Success(result, "Lấy thông tin sản phẩm thành công.");
    }

    [HttpPost]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> CreateProduct([FromBody] ProductCreateRequestDto dto)
    {
        var result = await productService.CreateProductAsync(dto);
        return CreatedSuccess(result, "Thêm mới sản phẩm thành công.");
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> UpdateProduct(int id, [FromBody] ProductUpdateRequestDto dto)
    {
        var result = await productService.UpdateProductAsync(id, dto);
        return Success(result, "Cập nhật sản phẩm thành công.");
    }

    [HttpPatch("{id:int}/status")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> ToggleProductStatus(int id)
    {
        var isActive = await productService.ToggleProductStatusAsync(id);
        var msg = isActive ? "Kích hoạt mở bán sản phẩm thành công." : "Tạm ngừng kinh doanh sản phẩm thành công.";
        return Success(new { isActive }, msg);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        await productService.DeleteProductAsync(id);
        return Success<object?>(null, "Xóa sản phẩm thành công.");
    }
}
