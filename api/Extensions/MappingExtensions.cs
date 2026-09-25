using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Auth;
using WebBanHang.Api.DTOs.Categories;
using WebBanHang.Api.DTOs.Products;
using WebBanHang.Api.DTOs.PurchaseOrders;
using WebBanHang.Api.DTOs.Suppliers;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.DTOs.Variants;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Extensions;

public static class MappingExtensions
{
    public static BasicUserDto ToDto(this User user)
    {
        return new BasicUserDto
        {
            UserId = user.UserId,
            Username = user.Username,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.RoleId
        };
    }

    public static UserInfoDto ToInfoDto(this User user)
    {
        return new UserInfoDto
        {
            UserId = user.UserId,
            Username = user.Username,
            Email = user.Email,
            FullName = user.FullName,
            Phone = user.Phone,
            DateOfBirth = user.DateOfBirth,
            TechInterest = user.TechInterest,
            Address = user.Address,
            Role = user.RoleId,
            IsLocked = user.IsLocked,
            CreatedAt = user.CreatedAt
        };
    }

    public static UserDto ToUserDto(this User user)
    {
        return new UserDto
        {
            UserId = user.UserId,
            Username = user.Username,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            DateOfBirth = user.DateOfBirth,
            TechInterest = user.TechInterest,
            Address = user.Address,
            Role = user.RoleId,
            IsLocked = user.IsLocked,
            CreatedAt = user.CreatedAt
        };
    }

    public static SupplierDto ToSupplierDto(this Supplier supplier)
    {
        return new SupplierDto
        {
            SupplierId = supplier.SupplierId,
            SupplierName = supplier.SupplierName,
            Phone = supplier.Phone,
            Email = supplier.Email,
            Address = supplier.Address,
            CreatedAt = supplier.CreatedAt,
            DeletedAt = supplier.DeletedAt
        };
    }

    public static CategoryDto ToCategoryDto(this Category category)
    {
        return new CategoryDto
        {
            CategoryId = category.CategoryId,
            CategoryName = category.CategoryName,
            CreatedAt = category.CreatedAt
        };
    }

    public static ProductVariantDto ToVariantDto(this ProductVariant variant)
    {
        return new ProductVariantDto
        {
            VariantId = variant.VariantId,
            ProductId = variant.ProductId,
            ProductName = variant.Product?.ProductName ?? string.Empty,
            VariantName = variant.VariantName,
            Price = variant.Price,
            StockQuantity = variant.StockQuantity,
            ImageUrl = variant.ImageUrl ?? variant.Product?.ImageUrl,
            Attributes = variant.Attributes != null 
                ? new Dictionary<string, string>(variant.Attributes) 
                : new Dictionary<string, string>(),
            IsActive = variant.IsActive,
            CreatedAt = variant.CreatedAt
        };
    }

    public static ProductBaseDto ToProductBaseDto(this Product product, bool onlyActiveVariants = false)
    {
        var variants = product.Variants;
        if (onlyActiveVariants && variants != null)
        {
            variants = variants.Where(v => v.IsActive).ToList();
        }

        var minPrice = variants != null && variants.Count > 0 
            ? variants.Min(v => v.Price) 
            : 0;
        var maxPrice = variants != null && variants.Count > 0 
            ? variants.Max(v => v.Price) 
            : 0;
        var totalStock = variants != null 
            ? variants.Sum(v => v.StockQuantity) 
            : 0;

        return new ProductBaseDto
        {
            ProductId = product.ProductId,
            ProductName = product.ProductName,
            CategoryId = product.CategoryId,
            CategoryName = product.Category?.CategoryName ?? string.Empty,
            ImageUrl = product.ImageUrl,
            MinPrice = minPrice,
            MaxPrice = maxPrice,
            TotalStock = totalStock,
            IsActive = product.IsActive,
            CreatedAt = product.CreatedAt
        };
    }

    public static ProductDetailDto ToProductDetailDto(this Product product, bool onlyActiveVariants = false)
    {
        var variants = product.Variants;
        if (onlyActiveVariants && variants != null)
        {
            variants = variants.Where(v => v.IsActive).ToList();
        }

        var variantsDto = variants?.Select(v => v.ToVariantDto()).ToList() ?? new List<ProductVariantDto>();
        var minPrice = variantsDto.Count > 0 ? variantsDto.Min(v => v.Price) : 0;
        var maxPrice = variantsDto.Count > 0 ? variantsDto.Max(v => v.Price) : 0;
        var totalStock = variantsDto.Sum(v => v.StockQuantity);

        return new ProductDetailDto
        {
            ProductId = product.ProductId,
            ProductName = product.ProductName,
            CategoryId = product.CategoryId,
            CategoryName = product.Category?.CategoryName ?? string.Empty,
            ImageUrl = product.ImageUrl,
            MinPrice = minPrice,
            MaxPrice = maxPrice,
            TotalStock = totalStock,
            IsActive = product.IsActive,
            Description = product.Description,
            VariantAttributes = product.VariantAttributes != null 
                ? new List<string>(product.VariantAttributes) 
                : new List<string>(),
            Variants = variantsDto,
            CreatedAt = product.CreatedAt
        };
    }

    public static Product ToEntity(this ProductCreateRequestDto dto)
    {
        var product = new Product
        {
            ProductName = dto.ProductName,
            CategoryId = dto.CategoryId,
            Description = dto.Description,
            ImageUrl = dto.ImageUrl,
            VariantAttributes = dto.VariantAttributes != null
                ? new List<string>(dto.VariantAttributes)
                : new List<string>(),
            IsActive = dto.IsActive ?? true,
            CreatedAt = DateTime.UtcNow
        };

        foreach (var v in dto.Variants)
        {
            product.Variants.Add(v.ToEntity());
        }

        return product;
    }

    public static PurchaseOrderItemDto ToPurchaseOrderItemDto(this PurchaseOrderItem item)
    {
        return new PurchaseOrderItemDto
        {
            PoItemId = item.PoItemId,
            VariantId = item.VariantId,
            VariantName = item.Variant?.VariantName ?? string.Empty,
            ImportPrice = item.ImportPrice,
            Quantity = item.Quantity
        };
    }

    public static PurchaseOrderBaseDto ToPurchaseOrderBaseDto(this PurchaseOrder po)
    {
        return new PurchaseOrderBaseDto
        {
            PurchaseOrderId = po.PurchaseOrderId,
            PoCode = po.PoCode,
            SupplierId = po.SupplierId,
            SupplierName = po.Supplier?.SupplierName ?? string.Empty,
            CreatedByUserId = po.CreatedByUserId,
            CreatedByName = po.CreatedByUser?.FullName ?? po.CreatedByUser?.Username ?? string.Empty,
            TotalCost = po.TotalCost,
            TotalItems = po.Items?.Count ?? 0,
            Status = po.Status,
            Note = po.Note,
            CreatedAt = po.CreatedAt
        };
    }

    public static PurchaseOrderDetailDto ToPurchaseOrderDetailDto(this PurchaseOrder po)
    {
        return new PurchaseOrderDetailDto
        {
            PurchaseOrderId = po.PurchaseOrderId,
            PoCode = po.PoCode,
            SupplierId = po.SupplierId,
            SupplierName = po.Supplier?.SupplierName ?? string.Empty,
            CreatedByUserId = po.CreatedByUserId,
            CreatedByName = po.CreatedByUser?.FullName ?? po.CreatedByUser?.Username ?? string.Empty,
            TotalCost = po.TotalCost,
            TotalItems = po.Items?.Count ?? 0,
            Status = po.Status,
            Note = po.Note,
            CreatedAt = po.CreatedAt,
            Items = po.Items?.Select(i => i.ToPurchaseOrderItemDto()).ToList() ?? new List<PurchaseOrderItemDto>()
        };
    }
}



