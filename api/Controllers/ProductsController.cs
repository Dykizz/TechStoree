using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Products;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Sản phẩm và Biến thể thương mại (Products and Variants)
/// </summary>
[Tags("Products")]
public class ProductsController(IProductService productService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách sản phẩm có phân trang, tìm kiếm và lọc nâng cao
    /// </summary>
    /// <param name="filter">Bộ lọc danh mục, khoảng giá, từ khóa tìm kiếm và phân trang</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<ProductBaseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProducts([FromQuery] ProductQueryFilter filter)
    {
        var result = await productService.GetProductsAsync(filter, IsAdmin);
        return Success(result, "Lấy danh sách sản phẩm thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một dòng sản phẩm kèm danh sách biến thể
    /// </summary>
    /// <param name="id">Mã ID sản phẩm</param>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProductById(int id)
    {
        var result = await productService.GetProductByIdAsync(id, IsAdmin);
        return Success(result, "Lấy thông tin sản phẩm thành công.");
    }

    /// <summary>
    /// Thêm mới sản phẩm và các biến thể phiên bản (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="dto">Dữ liệu tạo sản phẩm cha và các biến thể ban đầu</param>
    [HttpPost]
    [HasPermission(AppPermissions.Products.Create)]
    [ProducesResponseType(typeof(ApiResponse<ProductDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateProduct([FromBody] ProductCreateRequestDto dto)
    {
        var result = await productService.CreateProductAsync(dto);
        return CreatedSuccess(result, "Thêm mới sản phẩm thành công.");
    }

    /// <summary>
    /// Cập nhật thông tin sản phẩm và các biến thể (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID sản phẩm</param>
    /// <param name="dto">Dữ liệu cập nhật sản phẩm</param>
    [HttpPut("{id:int}")]
    [HasPermission(AppPermissions.Products.Update)]
    [ProducesResponseType(typeof(ApiResponse<ProductDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateProduct(int id, [FromBody] ProductUpdateRequestDto dto)
    {
        var result = await productService.UpdateProductAsync(id, dto);
        return Success(result, "Cập nhật sản phẩm thành công.");
    }

    /// <summary>
    /// Chuyển đổi trạng thái mở bán / ngừng kinh doanh sản phẩm (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID sản phẩm</param>
    [HttpPatch("{id:int}/status")]
    [HasPermission(AppPermissions.Products.Update)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleProductStatus(int id)
    {
        var isActive = await productService.ToggleProductStatusAsync(id);
        var msg = isActive ? "Kích hoạt mở bán sản phẩm thành công." : "Tạm ngừng kinh doanh sản phẩm thành công.";
        return Success(new { isActive }, msg);
    }

    /// <summary>
    /// Xóa một sản phẩm và tất cả các biến thể phụ thuộc (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID sản phẩm</param>
    [HttpDelete("{id:int}")]
    [HasPermission(AppPermissions.Products.Delete)]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        await productService.DeleteProductAsync(id);
        return Success<object?>(null, "Xóa sản phẩm thành công.");
    }
}
