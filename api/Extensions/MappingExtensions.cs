using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Auth;
using WebBanHang.Api.DTOs.Carts;
using WebBanHang.Api.DTOs.Categories;
using WebBanHang.Api.DTOs.Products;
using WebBanHang.Api.DTOs.Promotions;
using WebBanHang.Api.DTOs.PurchaseOrders;
using WebBanHang.Api.DTOs.Suppliers;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.DTOs.Variants;
using WebBanHang.Api.DTOs.Vouchers;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Extensions;

public static class MappingExtensions
{
    // ==========================================
    // USER MAPPINGS
    // ==========================================

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

    // ==========================================
    // SUPPLIER & CATEGORY MAPPINGS
    // ==========================================

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

    // ==========================================
    // HELPER UTILITIES
    // ==========================================

    public static string? GetDisplayImageUrl(this ProductVariant variant) =>
        !string.IsNullOrWhiteSpace(variant.ImageUrl) ? variant.ImageUrl : variant.Product?.ImageUrl;

    public static (decimal promotionalPrice, decimal discountAmount) CalculatePromotionalPrice(
        decimal originalPrice, string discountType, decimal discountValue)
    {
        if (discountType.Equals("PERCENTAGE", StringComparison.OrdinalIgnoreCase))
        {
            var discount = Math.Round(originalPrice * (discountValue / 100m), 0);
            return (Math.Max(0, originalPrice - discount), discount);
        }
        else
        {
            var discount = Math.Min(originalPrice, discountValue);
            return (Math.Max(0, originalPrice - discount), discount);
        }
    }

    public static Promotion? GetActivePromotion(this ProductVariant variant, DateTime? currentTime = null)
    {
        var now = currentTime ?? DateTime.UtcNow;
        return variant.Promotions?
            .FirstOrDefault(p => p.IsActive && p.StartDate <= now && p.EndDate >= now);
    }

    public static VariantPromotionDto? ToVariantPromotionDto(this ProductVariant variant, DateTime? currentTime = null)
    {
        var activePromo = variant.GetActivePromotion(currentTime);
        if (activePromo == null) return null;

        var (calculatedPrice, amount) = CalculatePromotionalPrice(variant.Price, activePromo.DiscountType, activePromo.DiscountValue);
        return new VariantPromotionDto
        {
            HasPromotion = true,
            PromotionId = activePromo.PromotionId,
            PromotionName = activePromo.Name,
            DiscountType = activePromo.DiscountType,
            DiscountValue = activePromo.DiscountValue,
            PromotionalPrice = calculatedPrice,
            DiscountAmount = amount
        };
    }

    // ==========================================
    // PRODUCT & VARIANT MAPPINGS
    // ==========================================

    public static ProductVariantDto ToVariantDto(this ProductVariant variant, DateTime? currentTime = null)
    {
        return new ProductVariantDto
        {
            VariantId = variant.VariantId,
            ProductId = variant.ProductId,
            ProductName = variant.Product?.ProductName ?? string.Empty,
            VariantName = variant.VariantName,
            Price = variant.Price,
            Promotion = variant.ToVariantPromotionDto(currentTime),
            StockQuantity = variant.StockQuantity,
            ImageUrl = variant.GetDisplayImageUrl(),
            Attributes = variant.Attributes != null 
                ? new Dictionary<string, string>(variant.Attributes) 
                : new Dictionary<string, string>(),
            IsActive = variant.IsActive,
            CreatedAt = variant.CreatedAt
        };
    }

    public static T PopulateProductBase<T>(this Product product, T dto, bool onlyActiveVariants = false, DateTime? currentTime = null)
        where T : ProductBaseDto
    {
        var variants = product.Variants;
        if (onlyActiveVariants && variants != null)
        {
            variants = variants.Where(v => v.IsActive).ToList();
        }

        var variantsList = variants?.ToList() ?? new List<ProductVariant>();
        var minPrice = variantsList.Count > 0 ? variantsList.Min(v => v.Price) : 0;
        var maxPrice = variantsList.Count > 0 ? variantsList.Max(v => v.Price) : 0;
        var totalStock = variantsList.Sum(v => v.StockQuantity);

        var now = currentTime ?? DateTime.UtcNow;
        var variantPromos = variantsList
            .Select(v => new { Variant = v, Promo = v.ToVariantPromotionDto(now) })
            .ToList();

        var activePromos = variantPromos.Where(x => x.Promo != null).ToList();

        ProductPromotionSummaryDto? promoSummary = null;
        if (activePromos.Count > 0)
        {
            var firstPromo = activePromos[0].Promo!;
            var calculatedPrices = variantPromos.Select(x => x.Promo?.PromotionalPrice ?? x.Variant.Price).ToList();

            promoSummary = new ProductPromotionSummaryDto
            {
                HasPromotion = true,
                PromotionId = firstPromo.PromotionId,
                PromotionName = firstPromo.PromotionName,
                DiscountType = firstPromo.DiscountType,
                DiscountValue = firstPromo.DiscountValue,
                PromotionalMinPrice = calculatedPrices.Min(),
                PromotionalMaxPrice = calculatedPrices.Max()
            };
        }

        dto.ProductId = product.ProductId;
        dto.ProductName = product.ProductName;
        dto.CategoryId = product.CategoryId;
        dto.CategoryName = product.Category?.CategoryName ?? string.Empty;
        dto.ImageUrl = product.ImageUrl;
        dto.MinPrice = minPrice;
        dto.MaxPrice = maxPrice;
        dto.TotalStock = totalStock;
        dto.IsActive = product.IsActive;
        dto.Promotion = promoSummary;
        dto.CreatedAt = product.CreatedAt;

        return dto;
    }

    public static ProductBaseDto ToProductBaseDto(this Product product, bool onlyActiveVariants = false, DateTime? currentTime = null) =>
        product.PopulateProductBase(new ProductBaseDto(), onlyActiveVariants, currentTime);

    public static ProductDetailDto ToProductDetailDto(this Product product, bool onlyActiveVariants = false, DateTime? currentTime = null)
    {
        var detail = product.PopulateProductBase(new ProductDetailDto(), onlyActiveVariants, currentTime);
        var variants = product.Variants;
        if (onlyActiveVariants && variants != null)
        {
            variants = variants.Where(v => v.IsActive).ToList();
        }

        detail.Description = product.Description;
        detail.VariantAttributes = product.VariantAttributes != null 
            ? new List<string>(product.VariantAttributes) 
            : new List<string>();
        detail.Variants = variants?.Select(v => v.ToVariantDto(currentTime)).ToList() ?? new List<ProductVariantDto>();

        return detail;
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

    // ==========================================
    // PURCHASE ORDER MAPPINGS
    // ==========================================

    public static PurchaseOrderItemDto ToPurchaseOrderItemDto(this PurchaseOrderItem item)
    {
        return new PurchaseOrderItemDto
        {
            PoItemId = item.PoItemId,
            VariantId = item.VariantId,
            ProductId = item.Variant?.ProductId ?? 0,
            ProductName = item.Variant?.Product?.ProductName ?? string.Empty,
            VariantName = item.Variant?.VariantName ?? string.Empty,
            ImportPrice = item.ImportPrice,
            Quantity = item.Quantity
        };
    }

    public static T PopulatePurchaseOrderBase<T>(this PurchaseOrder po, T dto) where T : PurchaseOrderBaseDto
    {
        dto.PurchaseOrderId = po.PurchaseOrderId;
        dto.PoCode = po.PoCode;
        dto.SupplierId = po.SupplierId;
        dto.SupplierName = po.Supplier?.SupplierName ?? string.Empty;
        dto.CreatedByUserId = po.CreatedByUserId;
        dto.CreatedByName = po.CreatedByUser?.FullName ?? po.CreatedByUser?.Username ?? string.Empty;
        dto.TotalCost = po.TotalCost;
        dto.TotalItems = po.Items?.Count ?? 0;
        dto.Status = po.Status;
        dto.Note = po.Note;
        dto.CreatedAt = po.CreatedAt;
        return dto;
    }

    public static PurchaseOrderBaseDto ToPurchaseOrderBaseDto(this PurchaseOrder po) =>
        po.PopulatePurchaseOrderBase(new PurchaseOrderBaseDto());

    public static PurchaseOrderDetailDto ToPurchaseOrderDetailDto(this PurchaseOrder po)
    {
        var detail = po.PopulatePurchaseOrderBase(new PurchaseOrderDetailDto());
        detail.Items = po.Items?.Select(i => i.ToPurchaseOrderItemDto()).ToList() ?? new List<PurchaseOrderItemDto>();
        return detail;
    }

    // ==========================================
    // CART MAPPINGS
    // ==========================================

    public static CartItemDto ToCartItemDto(this CartItem item)
    {
        return new CartItemDto
        {
            CartItemId = item.CartItemId,
            VariantId = item.VariantId,
            ProductId = item.Variant?.ProductId ?? 0,
            ProductName = item.Variant?.Product?.ProductName ?? string.Empty,
            VariantName = item.Variant?.VariantName ?? string.Empty,
            ImageUrl = item.Variant?.GetDisplayImageUrl(),
            Price = item.Variant?.Price ?? 0,
            Quantity = item.Quantity,
            StockQuantity = item.Variant?.StockQuantity ?? 0
        };
    }

    public static CartDto ToCartDto(this Cart cart)
    {
        return new CartDto
        {
            CartId = cart.CartId,
            UserId = cart.UserId,
            UpdatedAt = cart.UpdatedAt,
            Items = cart.Items?
                .OrderByDescending(i => i.AddedAt)
                .Select(i => i.ToCartItemDto())
                .ToList() ?? new List<CartItemDto>()
        };
    }

    // ==========================================
    // PROMOTION MAPPINGS
    // ==========================================

    public static PromotionVariantItemDto ToPromotionVariantItemDto(this ProductVariant v, Promotion p)
    {
        var (promoPrice, discountAmt) = CalculatePromotionalPrice(v.Price, p.DiscountType, p.DiscountValue);
        return new PromotionVariantItemDto
        {
            VariantId = v.VariantId,
            ProductId = v.ProductId,
            ProductName = v.Product?.ProductName ?? string.Empty,
            VariantName = v.VariantName,
            OriginalPrice = v.Price,
            PromotionalPrice = promoPrice,
            DiscountAmount = discountAmt,
            StockQuantity = v.StockQuantity,
            ImageUrl = v.GetDisplayImageUrl(),
            Attributes = v.Attributes ?? new Dictionary<string, string>()
        };
    }

    public static PromotionStatus GetPromotionStatus(this Promotion p, DateTime? currentTime = null)
    {
        var now = currentTime ?? DateTime.UtcNow;
        if (now < p.StartDate) return PromotionStatus.UPCOMING;
        if (now > p.EndDate) return PromotionStatus.EXPIRED;
        return PromotionStatus.ACTIVE;
    }

    public static T PopulatePromotionBase<T>(this Promotion p, T dto, DateTime? currentTime = null, int? variantCount = null)
        where T : PromotionBaseDto
    {
        var now = currentTime ?? DateTime.UtcNow;
        dto.PromotionId = p.PromotionId;
        dto.Name = p.Name;
        dto.Description = p.Description;
        dto.DiscountType = p.DiscountType;
        dto.DiscountValue = p.DiscountValue;
        dto.StartDate = p.StartDate;
        dto.EndDate = p.EndDate;
        dto.IsActive = p.IsActive;
        dto.CreatedAt = p.CreatedAt;
        dto.Status = p.GetPromotionStatus(now);
        dto.VariantCount = variantCount ?? (p.Variants?.Count ?? 0);
        return dto;
    }

    public static PromotionBaseDto ToPromotionBaseDto(this Promotion p, DateTime? currentTime = null, int? variantCount = null) =>
        p.PopulatePromotionBase(new PromotionBaseDto(), currentTime, variantCount);

    public static PromotionDetailDto ToPromotionDetailDto(this Promotion p, DateTime? currentTime = null)
    {
        var detail = p.PopulatePromotionBase(new PromotionDetailDto(), currentTime);
        detail.Variants = p.Variants?.Select(v => v.ToPromotionVariantItemDto(p)).ToList() ?? new List<PromotionVariantItemDto>();
        return detail;
    }

    // ==========================================
    // VOUCHER MAPPINGS
    // ==========================================

    public static VoucherCampaignStatus GetVoucherStatus(this Voucher v, DateTime? currentTime = null)
    {
        var now = currentTime ?? DateTime.UtcNow;
        if (now < v.StartDate) return VoucherCampaignStatus.UPCOMING;
        if (now > v.EndDate) return VoucherCampaignStatus.EXPIRED;
        return VoucherCampaignStatus.ACTIVE;
    }

    public static T PopulateVoucherBase<T>(this Voucher v, T dto, DateTime? currentTime = null)
        where T : VoucherBaseDto
    {
        var now = currentTime ?? DateTime.UtcNow;
        dto.VoucherId = v.VoucherId;
        dto.Code = v.Code;
        dto.Title = v.Title;
        dto.Description = v.Description;
        dto.DiscountType = v.DiscountType;
        dto.DiscountValue = v.DiscountValue;
        dto.MinOrderValue = v.MinOrderValue;
        dto.MaxDiscountAmount = v.MaxDiscountAmount;
        dto.UsageLimit = v.UsageLimit;
        dto.UsedCount = v.UsedCount;
        dto.LimitPerUser = v.LimitPerUser;
        dto.StartDate = v.StartDate;
        dto.EndDate = v.EndDate;
        dto.IsActive = v.IsActive;
        dto.IsPublic = v.IsPublic;
        dto.CreatedAt = v.CreatedAt;
        dto.Status = v.GetVoucherStatus(now);
        return dto;
    }

    public static VoucherBaseDto ToVoucherBaseDto(this Voucher v, DateTime? currentTime = null) =>
        v.PopulateVoucherBase(new VoucherBaseDto(), currentTime);

    public static VoucherDetailDto ToVoucherDetailDto(this Voucher v, DateTime? currentTime = null)
    {
        var detail = v.PopulateVoucherBase(new VoucherDetailDto(), currentTime);
        detail.TotalClaimedCount = v.UserVouchers?.Count ?? 0;
        return detail;
    }

    public static bool IsCurrentlyValid(this Voucher v, DateTime? currentTime = null)
    {
        var now = currentTime ?? DateTime.UtcNow;
        return v.IsActive && v.StartDate <= now && v.EndDate >= now;
    }

    public static bool HasReachedUsageLimit(this Voucher v) =>
        v.UsageLimit.HasValue && v.UsedCount >= v.UsageLimit.Value;

    public static decimal CalculateDiscount(this Voucher voucher, decimal subtotalAmount)
    {
        if (voucher.DiscountType == DiscountType.PERCENTAGE)
        {
            var rawDiscount = Math.Round(subtotalAmount * (voucher.DiscountValue / 100m), 0);
            if (voucher.MaxDiscountAmount.HasValue && voucher.MaxDiscountAmount.Value > 0)
            {
                rawDiscount = Math.Min(rawDiscount, voucher.MaxDiscountAmount.Value);
            }
            return Math.Min(subtotalAmount, rawDiscount);
        }

        return Math.Min(subtotalAmount, voucher.DiscountValue);
    }

    public static UserVoucherItemDto ToUserVoucherItemDto(this UserVoucher uv, DateTime? currentTime = null)
    {
        var now = currentTime ?? DateTime.UtcNow;
        var voucher = uv.Voucher;
        var isUsable = !uv.IsUsed && voucher != null && voucher.IsCurrentlyValid(now);

        return new UserVoucherItemDto
        {
            UserVoucherId = uv.UserVoucherId,
            VoucherId = uv.VoucherId,
            Code = voucher?.Code ?? string.Empty,
            Title = voucher?.Title ?? string.Empty,
            Description = voucher?.Description,
            DiscountType = voucher?.DiscountType ?? DiscountType.PERCENTAGE,
            DiscountValue = voucher?.DiscountValue ?? 0,
            MinOrderValue = voucher?.MinOrderValue ?? 0,
            MaxDiscountAmount = voucher?.MaxDiscountAmount,
            StartDate = voucher?.StartDate ?? DateTime.MinValue,
            EndDate = voucher?.EndDate ?? DateTime.MinValue,
            AssignedType = uv.AssignedType,
            AssignedAt = uv.AssignedAt,
            IsUsed = uv.IsUsed,
            UsedAt = uv.UsedAt,
            OrderId = uv.OrderId,
            IsUsable = isUsable
        };
    }
}
