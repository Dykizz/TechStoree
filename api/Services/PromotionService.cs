using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Promotions;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class PromotionService(AppDbContext dbContext) : IPromotionService
{
    public async Task<IEnumerable<PromotionBaseDto>> GetAllPromotionsAsync(PromotionQueryFilter? filter = null)
    {
        var now = DateTime.UtcNow;
        var query = dbContext.Promotions.AsNoTracking();

        if (filter != null)
        {
            // 1. Lọc theo trạng thái kích hoạt do Quản trị viên cấu hình (bật/tắt)
            if (filter.IsActive.HasValue)
            {
                query = query.Where(p => p.IsActive == filter.IsActive.Value);
            }

            // 2. Lọc theo trạng thái thời gian (Enum Status: UPCOMING, ACTIVE, EXPIRED)
            if (filter.Status.HasValue)
            {
                query = filter.Status.Value switch
                {
                    PromotionStatus.UPCOMING => query.Where(p => p.StartDate > now),
                    PromotionStatus.ACTIVE => query.Where(p => p.StartDate <= now && p.EndDate >= now),
                    PromotionStatus.EXPIRED => query.Where(p => p.EndDate < now),
                    _ => query
                };
            }

            // 3. Lọc theo khoảng thời gian có hiệu lực
            if (filter.FromDate.HasValue)
            {
                var fromUtc = DateTimeHelper.NormalizeFilterFromUtc(filter.FromDate.Value);
                query = query.Where(p => p.EndDate >= fromUtc);
            }

            if (filter.ToDate.HasValue)
            {
                var toUtc = DateTimeHelper.NormalizeFilterToUtc(filter.ToDate.Value);
                query = query.Where(p => p.StartDate <= toUtc);
            }

            // 4. Tìm kiếm theo tên hoặc mô tả
            if (!string.IsNullOrWhiteSpace(filter.Search))
            {
                var search = filter.Search.Trim().ToLower();
                query = query.Where(p => p.Name.ToLower().Contains(search) || 
                                        (p.Description != null && p.Description.ToLower().Contains(search)));
            }
        }

        // Tối ưu hiệu năng: Không include Product/Variant vào danh sách, chỉ đếm số lượng biến thể
        var list = await query
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => new
            {
                Promotion = p,
                VariantCount = p.Variants.Count()
            })
            .ToListAsync();

        return list.Select(x => x.Promotion.ToPromotionBaseDto(now, x.VariantCount));
    }

    public async Task<PromotionDetailDto?> GetPromotionByIdAsync(int id)
    {
        // Khi xem chi tiết một khuyến mãi cụ thể mới include đầy đủ biến thể và sản phẩm
        var promotion = await dbContext.Promotions
            .Include(p => p.Variants)
                .ThenInclude(v => v.Product)
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PromotionId == id);

        return promotion?.ToPromotionDetailDto();
    }

    public async Task<PromotionDetailDto> CreatePromotionAsync(PromotionUpsertRequestDto request)
    {
        var promotion = new Promotion
        {
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            DiscountType = request.DiscountType.ToUpperInvariant(),
            DiscountValue = request.DiscountValue,
            StartDate = DateTimeHelper.NormalizeToUtc(request.StartDate),
            EndDate = DateTimeHelper.NormalizeToUtc(request.EndDate),
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };

        if (request.VariantIds != null && request.VariantIds.Count > 0)
        {
            var variants = await dbContext.ProductVariants
                .Where(v => request.VariantIds.Contains(v.VariantId))
                .ToListAsync();

            foreach (var variant in variants)
            {
                promotion.Variants.Add(variant);
            }
        }

        dbContext.Promotions.Add(promotion);
        await dbContext.SaveChangesAsync();

        return (await GetPromotionByIdAsync(promotion.PromotionId))!;
    }

    public async Task<PromotionDetailDto?> UpdatePromotionAsync(int id, PromotionUpsertRequestDto request)
    {
        var promotion = await dbContext.Promotions
            .Include(p => p.Variants)
            .FirstOrDefaultAsync(p => p.PromotionId == id);

        if (promotion == null) return null;

        var now = DateTime.UtcNow;

        // 1. Nếu chiến dịch đã kết thúc (EXPIRED) -> Khóa dữ liệu lịch sử, không cho phép chỉnh sửa
        if (promotion.EndDate < now)
        {
            throw new BadRequestException("Chiến dịch đã kết thúc trong quá khứ, không thể chỉnh sửa. Hãy tạo chiến dịch mới.");
        }

        var newStartDate = DateTimeHelper.NormalizeToUtc(request.StartDate);
        var newEndDate = DateTimeHelper.NormalizeToUtc(request.EndDate);

        // 2. Nếu chiến dịch đang diễn ra (ACTIVE)
        if (promotion.StartDate <= now && promotion.EndDate >= now)
        {
            // Không được thay đổi hoặc dời ngày bắt đầu khi chiến dịch đã/đang chạy
            if (newStartDate != promotion.StartDate)
            {
                throw new BadRequestException("Chiến dịch đang diễn ra không thể thay đổi hoặc dời ngày bắt đầu về tương lai.");
            }

            // Không cho phép đổi loại giảm giá hoặc mức giảm giá khi chiến dịch đang chạy (tránh xung đột giá bán)
            var newDiscountType = request.DiscountType.ToUpperInvariant();
            if (promotion.DiscountType != newDiscountType || promotion.DiscountValue != request.DiscountValue)
            {
                throw new BadRequestException("Không thể thay đổi mức giảm giá khi chiến dịch đang diễn ra. Hãy tắt chiến dịch hiện tại và tạo chiến dịch mới.");
            }
        }

        // Cập nhật thông tin cơ bản
        promotion.Name = request.Name.Trim();
        promotion.Description = request.Description?.Trim();
        promotion.EndDate = newEndDate;
        promotion.IsActive = request.IsActive;

        // Đối với chiến dịch chưa diễn ra (UPCOMING), cho phép cập nhật ngày bắt đầu và mức giảm
        if (now < promotion.StartDate)
        {
            promotion.StartDate = newStartDate;
            promotion.DiscountType = request.DiscountType.ToUpperInvariant();
            promotion.DiscountValue = request.DiscountValue;
        }

        // Cập nhật danh sách biến thể tham gia
        if (request.VariantIds != null)
        {
            promotion.Variants.Clear();
            if (request.VariantIds.Count > 0)
            {
                var variants = await dbContext.ProductVariants
                    .Where(v => request.VariantIds.Contains(v.VariantId))
                    .ToListAsync();
                foreach (var v in variants)
                {
                    promotion.Variants.Add(v);
                }
            }
        }

        await dbContext.SaveChangesAsync();
        return await GetPromotionByIdAsync(id);
    }

    public async Task<bool> DeletePromotionAsync(int id)
    {
        var promotion = await dbContext.Promotions.FindAsync(id);
        if (promotion == null) return false;

        var now = DateTime.UtcNow;

        // Nếu chiến dịch đã hoặc đang diễn ra (StartDate <= now), không được xóa cứng để bảo vệ dữ liệu lịch sử và đối soát
        if (promotion.StartDate <= now)
        {
            throw new BadRequestException("Không thể xóa chiến dịch đã hoặc đang diễn ra. Bạn chỉ có thể tắt hoạt động (IsActive = false).");
        }

        dbContext.Promotions.Remove(promotion);
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool?> ToggleActiveAsync(int id)
    {
        var promotion = await dbContext.Promotions.FindAsync(id);
        if (promotion == null) return null;

        promotion.IsActive = !promotion.IsActive;
        await dbContext.SaveChangesAsync();
        return promotion.IsActive;
    }
}
