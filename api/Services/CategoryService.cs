using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Categories;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class CategoryService(AppDbContext context) : ICategoryService
{
    public async Task<List<CategoryDto>> GetCategoriesAsync(string? search = null)
    {
        var query = context.Categories.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var normalizedSearch = search.Trim().ToLower();
            query = query.Where(c => c.CategoryName.ToLower().Contains(normalizedSearch));
        }

        var categories = await query
            .OrderBy(c => c.CategoryId)
            .ToListAsync();

        return categories.Select(c => c.ToCategoryDto()).ToList();
    }

    public async Task<CategoryDto> GetCategoryByIdAsync(int id)
    {
        var category = await context.Categories.AsNoTracking()
            .FirstOrDefaultAsync(c => c.CategoryId == id)
            ?? throw new KeyNotFoundException($"Không tìm thấy danh mục với mã ID: {id}.");

        return category.ToCategoryDto();
    }

    public async Task<CategoryDto> CreateCategoryAsync(CategoryUpsertRequestDto dto)
    {
        var normalizedName = dto.CategoryName.Trim();

        // Kiểm tra trùng tên danh mục
        var isExisted = await context.Categories
            .AnyAsync(c => c.CategoryName.ToLower() == normalizedName.ToLower());
        if (isExisted)
        {
            throw new BadRequestException($"Danh mục '{normalizedName}' đã tồn tại trong hệ thống.");
        }

        var category = new Category
        {
            CategoryName = normalizedName,
            CreatedAt = DateTime.UtcNow
        };

        context.Categories.Add(category);
        await context.SaveChangesAsync();

        return category.ToCategoryDto();
    }

    public async Task<CategoryDto> UpdateCategoryAsync(int id, CategoryUpsertRequestDto dto)
    {
        var category = await context.Categories.FindAsync(id)
            ?? throw new KeyNotFoundException($"Không tìm thấy danh mục với mã ID: {id}.");

        var normalizedName = dto.CategoryName.Trim();

        // Kiểm tra trùng tên với danh mục khác
        var isDuplicate = await context.Categories
            .AnyAsync(c => c.CategoryId != id && c.CategoryName.ToLower() == normalizedName.ToLower());
        if (isDuplicate)
        {
            throw new BadRequestException($"Tên danh mục '{normalizedName}' đã được sử dụng bởi danh mục khác.");
        }

        category.CategoryName = normalizedName;
        await context.SaveChangesAsync();

        return category.ToCategoryDto();
    }

    public async Task DeleteCategoryAsync(int id)
    {
        var category = await context.Categories.FindAsync(id)
            ?? throw new KeyNotFoundException($"Không tìm thấy danh mục với mã ID: {id}.");

        // var hasProducts = await context.Products.AnyAsync(p => p.CategoryId == id);
        // if (hasProducts)
        // {
        //     throw new BadRequestException("Không thể xóa danh mục này vì đang có sản phẩm trực thuộc. Vui lòng chuyển hoặc xóa các sản phẩm liên quan trước!");
        // }

        context.Categories.Remove(category);
        await context.SaveChangesAsync();
    }
}
