using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Products;
using WebBanHang.Api.DTOs.Variants;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class ProductService(AppDbContext context, ICloudinaryService cloudinaryService) : IProductService
{
    public async Task<PagedResult<ProductBaseDto>> GetProductsAsync(ProductQueryFilter filter, bool isAdmin = false)
    {
        var query = context.Products
            .Include(p => p.Category)
            .Include(p => p.Variants)
                .ThenInclude(v => v.Promotions)
            .AsNoTracking();

        if (!isAdmin)
        {
            query = query.Where(p => p.IsActive && (!p.Variants.Any() || p.Variants.Any(v => v.IsActive)));
        }
        else if (filter.IsActive.HasValue)
        {
            query = query.Where(p => p.IsActive == filter.IsActive.Value);
        }

        if (filter.OnSale == true)
        {
            var now = DateTime.UtcNow;
            query = query.Where(p => p.Variants.Any(v => 
                (isAdmin || v.IsActive) && 
                v.Promotions.Any(promo => promo.IsActive && promo.StartDate <= now && promo.EndDate >= now)));
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim().ToLower();
            query = query.Where(p =>
                p.ProductName.ToLower().Contains(search) ||
                (p.Description != null && p.Description.ToLower().Contains(search)) ||
                (p.Category != null && p.Category.CategoryName.ToLower().Contains(search)));
        }

        if (filter.CategoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == filter.CategoryId.Value);
        }

        if (filter.MinPrice.HasValue)
        {
            query = isAdmin
                ? query.Where(p => p.Variants.Any(v => v.Price >= filter.MinPrice.Value))
                : query.Where(p => p.Variants.Any(v => v.IsActive && v.Price >= filter.MinPrice.Value));
        }

        if (filter.MaxPrice.HasValue)
        {
            query = isAdmin
                ? query.Where(p => p.Variants.Any(v => v.Price <= filter.MaxPrice.Value))
                : query.Where(p => p.Variants.Any(v => v.IsActive && v.Price <= filter.MaxPrice.Value));
        }

        query = filter.SortBy?.ToLower() switch
        {
            "name" => filter.IsAscending ? query.OrderBy(p => p.ProductName) : query.OrderByDescending(p => p.ProductName),
            "createdat" => filter.IsAscending ? query.OrderBy(p => p.CreatedAt) : query.OrderByDescending(p => p.CreatedAt),
            "price" => filter.IsAscending 
                ? (isAdmin 
                    ? query.OrderBy(p => p.Variants.Min(v => (decimal?)v.Price) ?? 0)
                    : query.OrderBy(p => p.Variants.Where(v => v.IsActive).Min(v => (decimal?)v.Price) ?? 0))
                : (isAdmin 
                    ? query.OrderByDescending(p => p.Variants.Max(v => (decimal?)v.Price) ?? 0)
                    : query.OrderByDescending(p => p.Variants.Where(v => v.IsActive).Max(v => (decimal?)v.Price) ?? 0)),
            _ => filter.IsAscending ? query.OrderBy(p => p.ProductId) : query.OrderByDescending(p => p.ProductId)
        };

        return await query.ToPagedResultAsync(filter, p => p.ToProductBaseDto(onlyActiveVariants: !isAdmin));
    }

    public async Task<ProductDetailDto> GetProductByIdAsync(int id, bool isAdmin = false)
    {
        var product = await context.Products
            .Include(p => p.Category)
            .Include(p => p.Variants)
                .ThenInclude(v => v.Promotions)
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.ProductId == id)
            ?? throw new KeyNotFoundException($"Không tìm thấy sản phẩm với mã ID: {id}.");

        // Nếu không phải ADMIN mà sản phẩm đã ngừng bán -> 404 Không tìm thấy
        if (!isAdmin && !product.IsActive)
        {
            throw new KeyNotFoundException($"Không tìm thấy sản phẩm với mã ID: {id}.");
        }

        // Lấy chi tiết sản phẩm (Khách chỉ xem các biến thể active)
        return product.ToProductDetailDto(onlyActiveVariants: !isAdmin);
    }

    public async Task<ProductDetailDto> CreateProductAsync(ProductCreateRequestDto dto)
    {
        var categoryExists = await context.Categories.AnyAsync(c => c.CategoryId == dto.CategoryId);
        if (!categoryExists)
        {
            throw new BadRequestException($"Danh mục với mã ID {dto.CategoryId} không tồn tại.");
        }

        var variantAttrs = dto.VariantAttributes ?? new List<string>();
        VariantHelper.ValidateVariantList(variantAttrs, dto.Variants);

        var product = dto.ToEntity();

        try
        {
            context.Products.Add(product);
            await context.SaveChangesAsync();

            // Load Category để trả về DTO hoàn chỉnh
            await context.Entry(product).Reference(p => p.Category).LoadAsync();
            return product.ToProductDetailDto();
        }
        catch (DbUpdateException ex)
        {
            throw new BadRequestException($"Không thể tạo sản phẩm do vi phạm ràng buộc dữ liệu: {ex.InnerException?.Message ?? ex.Message}");
        }
    }

    public async Task<ProductDetailDto> UpdateProductAsync(int id, ProductUpdateRequestDto dto)
    {
        var product = await context.Products
            .Include(p => p.Category)
            .Include(p => p.Variants)
            .FirstOrDefaultAsync(p => p.ProductId == id)
            ?? throw new KeyNotFoundException($"Không tìm thấy sản phẩm với mã ID: {id}.");

        if (product.CategoryId != dto.CategoryId)
        {
            var categoryExists = await context.Categories.AnyAsync(c => c.CategoryId == dto.CategoryId);
            if (!categoryExists)
            {
                throw new BadRequestException($"Danh mục với mã ID {dto.CategoryId} không tồn tại.");
            }
            product.CategoryId = dto.CategoryId;
        }

        var imagesToDelete = new List<string>();

        // Nếu sản phẩm đổi ảnh mới, gom ảnh cũ để xóa sau khi lưu DB thành công
        if (dto.ImageUrl != null && dto.ImageUrl != product.ImageUrl && !string.IsNullOrWhiteSpace(product.ImageUrl))
        {
            imagesToDelete.Add(product.ImageUrl);
        }

        product.ProductName = dto.ProductName;
        product.Description = dto.Description;
        product.ImageUrl = dto.ImageUrl;
        
        // Xử lý cập nhật danh sách thuộc tính động
        if (dto.VariantAttributes != null)
        {
            var oldAttributes = product.VariantAttributes ?? new List<string>();
            bool isAttributesChanged = !new HashSet<string>(oldAttributes, StringComparer.OrdinalIgnoreCase)
                .SetEquals(dto.VariantAttributes);

            // Khi thay đổi cấu trúc thuộc tính mà client không gửi kèm danh sách biến thể mới để đồng bộ
            if (isAttributesChanged && dto.Variants == null && product.Variants.Count > 0)
            {
                throw new BadRequestException(
                    "Khi thay đổi danh sách thuộc tính (VariantAttributes), bạn cần gửi kèm danh sách biến thể (Variants) mới phù hợp với cấu trúc thuộc tính này.");
            }

            product.VariantAttributes = dto.VariantAttributes;
        }

        if (dto.IsActive.HasValue)
        {
            product.IsActive = dto.IsActive.Value;
        }

        // Xử lý đồng bộ danh sách biến thể nếu client gửi kèm trong payload
        if (dto.Variants != null)
        {
            SyncProductVariants(product, dto.Variants, imagesToDelete);
        }

        try
        {
            await context.SaveChangesAsync();
            await context.Entry(product).Reference(p => p.Category).LoadAsync();

            // Xóa ảnh cũ trên Cloudinary sau khi cập nhật CSDL thành công
            foreach (var imgUrl in imagesToDelete)
            {
                try { await cloudinaryService.DeleteMediaAsync(imgUrl); } catch { /* Bỏ qua lỗi cloud để không ảnh hưởng dữ liệu */ }
            }

            return product.ToProductDetailDto();
        }
        catch (DbUpdateException)
        {
            throw new BadRequestException("Không thể cập nhật sản phẩm do vi phạm ràng buộc dữ liệu hoặc một số biến thể đã phát sinh lịch sử giao dịch. " +
                "Vui lòng kiểm tra lại hoặc chuyển trạng thái biến thể sang Tạm ngừng kinh doanh.");
        }
    }

    public async Task<bool> ToggleProductStatusAsync(int id)
    {
        var product = await context.Products.FindAsync(id)
            ?? throw new KeyNotFoundException($"Không tìm thấy sản phẩm với mã ID: {id}.");

        product.IsActive = !product.IsActive;
        await context.SaveChangesAsync();
        return product.IsActive;
    }

    public async Task DeleteProductAsync(int id)
    {
        var product = await context.Products
            .Include(p => p.Variants)
            .FirstOrDefaultAsync(p => p.ProductId == id)
            ?? throw new KeyNotFoundException($"Không tìm thấy sản phẩm với mã ID: {id}.");

        // Thu thập toàn bộ ảnh của sản phẩm và biến thể để dọn dẹp trên Cloudinary
        var imagesToDelete = new List<string>();
        if (!string.IsNullOrWhiteSpace(product.ImageUrl))
        {
            imagesToDelete.Add(product.ImageUrl);
        }
        foreach (var v in product.Variants)
        {
            if (!string.IsNullOrWhiteSpace(v.ImageUrl))
            {
                imagesToDelete.Add(v.ImageUrl);
            }
        }

        try
        {
            context.Products.Remove(product);
            await context.SaveChangesAsync();

            // Xóa ảnh trên Cloudinary sau khi đã xóa thành công khỏi CSDL
            foreach (var imgUrl in imagesToDelete)
            {
                try { await cloudinaryService.DeleteMediaAsync(imgUrl); } catch { /* Bỏ qua lỗi cloud để không ảnh hưởng dữ liệu */ }
            }
        }
        catch (DbUpdateException)
        {
            throw new BadRequestException("Không thể xóa sản phẩm này do đã phát sinh dữ liệu liên quan trong hệ thống (đơn hàng, phiếu nhập kho...). Bạn có thể chuyển trạng thái sản phẩm sang Tạm ngừng kinh doanh.");
        }
    }

    private void SyncProductVariants(Product product, List<ProductVariantUpsertRequestDto> incomingVariants, List<string>? imagesToDelete = null)
    {
        // A. Kiểm tra các VariantId gửi lên phải thuộc về sản phẩm này trong database
        ValidateVariantBelongsToProduct(product, incomingVariants);

        // B. Kiểm tra thuộc tính bắt buộc của biến thể
        var currentAttrs = product.VariantAttributes ?? new List<string>();
        VariantHelper.ValidateVariantList(currentAttrs, incomingVariants);

        var incomingVariantIds = incomingVariants
            .Where(v => v.VariantId.HasValue && v.VariantId.Value > 0)
            .Select(v => v.VariantId!.Value)
            .ToHashSet();

        // C. Xóa các biến thể trong DB không còn nằm trong danh sách gửi lên
        var variantsToRemove = product.Variants
            .Where(v => !incomingVariantIds.Contains(v.VariantId))
            .ToList();

        if (variantsToRemove.Count > 0)
        {
            foreach (var v in variantsToRemove)
            {
                if (!string.IsNullOrWhiteSpace(v.ImageUrl))
                {
                    imagesToDelete?.Add(v.ImageUrl);
                }
                product.Variants.Remove(v);
            }
            context.ProductVariants.RemoveRange(variantsToRemove);
        }

        // D. Cập nhật biến thể cũ & Thêm biến thể mới
        foreach (var vDto in incomingVariants)
        {
            if (vDto.VariantId.HasValue && vDto.VariantId.Value > 0)
            {
                var existingVariant = product.Variants.FirstOrDefault(v => v.VariantId == vDto.VariantId.Value);
                if (existingVariant != null)
                {
                    var newImgUrl = string.IsNullOrWhiteSpace(vDto.ImageUrl) ? null : vDto.ImageUrl.Trim();
                    if (!string.IsNullOrWhiteSpace(existingVariant.ImageUrl) && existingVariant.ImageUrl != newImgUrl)
                    {
                        imagesToDelete?.Add(existingVariant.ImageUrl);
                    }
                    existingVariant.UpdateEntity(vDto);
                }
            }
            else
            {
                product.Variants.Add(vDto.ToEntity(product.ProductId));
            }
        }
    }

    private static void ValidateVariantBelongsToProduct(Product product, List<ProductVariantUpsertRequestDto> incomingVariants)
    {
        var currentDbVariantIds = product.Variants.Select(v => v.VariantId).ToHashSet();
        var invalidVariantIds = incomingVariants
            .Where(v => v.VariantId.HasValue && v.VariantId.Value > 0 && !currentDbVariantIds.Contains(v.VariantId.Value))
            .Select(v => v.VariantId!.Value)
            .ToList();

        if (invalidVariantIds.Count > 0)
        {
            throw new BadRequestException($"Các biến thể sau không tồn tại hoặc không thuộc về sản phẩm này: {string.Join(", ", invalidVariantIds)}.");
        }
    }
}
