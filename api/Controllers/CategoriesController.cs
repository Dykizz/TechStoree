using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Categories;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Danh mục Sản phẩm (Categories)
/// </summary>
[Tags("Categories")]
public class CategoriesController(ICategoryService categoryService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách danh mục sản phẩm (Hỗ trợ tìm kiếm theo tên)
    /// </summary>
    /// <param name="search">Từ khóa tìm kiếm tên danh mục</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<CategoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories([FromQuery] string? search)
    {
        var result = await categoryService.GetCategoriesAsync(search);
        return Success(result, "Lấy danh sách danh mục thành công.");
    }

    /// <summary>
    /// Lấy chi tiết thông tin một danh mục sản phẩm theo ID
    /// </summary>
    /// <param name="id">Mã ID danh mục</param>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCategoryById(int id)
    {
        var result = await categoryService.GetCategoryByIdAsync(id);
        return Success(result, "Lấy thông tin danh mục thành công.");
    }

    /// <summary>
    /// Thêm mới một danh mục sản phẩm (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="dto">Dữ liệu tạo danh mục</param>
    [HttpPost]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateCategory([FromBody] CategoryUpsertRequestDto dto)
    {
        var result = await categoryService.CreateCategoryAsync(dto);
        return CreatedSuccess(result, "Thêm mới danh mục thành công.");
    }

    /// <summary>
    /// Cập nhật thông tin danh mục sản phẩm (Yêu cầu quyền ADMIN)
    /// </summary>
    /// <param name="id">Mã ID danh mục cần sửa</param>
    /// <param name="dto">Dữ liệu cập nhật danh mục</param>
    [HttpPut("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCategory(int id, [FromBody] CategoryUpsertRequestDto dto)
    {
        var result = await categoryService.UpdateCategoryAsync(id, dto);
        return Success(result, "Cập nhật danh mục thành công.");
    }

    /// <summary>
    /// Xóa một danh mục sản phẩm (Chặn xóa nếu danh mục đang chứa sản phẩm)
    /// </summary>
    /// <param name="id">Mã ID danh mục cần xóa</param>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteCategory(int id)
    {
        await categoryService.DeleteCategoryAsync(id);
        return Success<object?>(null, "Xóa danh mục thành công.");
    }
}
