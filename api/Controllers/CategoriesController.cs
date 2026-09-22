using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.DTOs.Categories;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

public class CategoriesController(ICategoryService categoryService) : BaseApiController
{
    [HttpGet]
    public async Task<IActionResult> GetCategories([FromQuery] string? search)
    {
        var result = await categoryService.GetCategoriesAsync(search);
        return Success(result, "Lấy danh sách danh mục thành công.");
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetCategoryById(int id)
    {
        var result = await categoryService.GetCategoryByIdAsync(id);
        return Success(result, "Lấy thông tin danh mục thành công.");
    }

    [HttpPost]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> CreateCategory([FromBody] CategoryUpsertRequestDto dto)
    {
        var result = await categoryService.CreateCategoryAsync(dto);
        return CreatedSuccess(result, "Thêm mới danh mục thành công.");
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> UpdateCategory(int id, [FromBody] CategoryUpsertRequestDto dto)
    {
        var result = await categoryService.UpdateCategoryAsync(id, dto);
        return Success(result, "Cập nhật danh mục thành công.");
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> DeleteCategory(int id)
    {
        await categoryService.DeleteCategoryAsync(id);
        return Success<object?>(null, "Xóa danh mục thành công.");
    }
}
