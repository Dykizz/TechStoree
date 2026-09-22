using WebBanHang.Api.DTOs.Categories;

namespace WebBanHang.Api.Services.Interfaces;

public interface ICategoryService
{
    Task<List<CategoryDto>> GetCategoriesAsync(string? search = null);
    Task<CategoryDto> GetCategoryByIdAsync(int id);
    Task<CategoryDto> CreateCategoryAsync(CategoryUpsertRequestDto dto);
    Task<CategoryDto> UpdateCategoryAsync(int id, CategoryUpsertRequestDto dto);
    Task DeleteCategoryAsync(int id);
}
