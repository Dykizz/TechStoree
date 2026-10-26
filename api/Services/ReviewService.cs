using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Reviews;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class ReviewService(AppDbContext dbContext) : IReviewService
{
    private const int MaxReviewEditableDays = 30;

    public async Task<PagedResult<ReviewDto>> GetProductReviewsAsync(int productId, ProductReviewQueryFilter filter)
    {
        var query = dbContext.ProductReviews
            .AsNoTracking()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.OrderItem)
                .ThenInclude(oi => oi.Order)
            .Where(r => r.ProductId == productId && !r.IsHidden)
            .AsQueryable();

        // 1. Lọc theo số sao
        if (filter.Rating.HasValue)
        {
            query = query.Where(r => r.Rating == filter.Rating.Value);
        }

        // 2. Lọc theo có hình ảnh đính kèm
        if (filter.HasImages.HasValue)
        {
            query = filter.HasImages.Value
                ? query.Where(r => r.ImageUrls.Count > 0)
                : query.Where(r => r.ImageUrls.Count == 0);
        }

        // 3. Sắp xếp
        query = (filter.SortBy?.ToLower()) switch
        {
            "rating" => filter.IsAscending
                ? query.OrderBy(r => r.Rating).ThenByDescending(r => r.CreatedAt)
                : query.OrderByDescending(r => r.Rating).ThenByDescending(r => r.CreatedAt),
            _ => filter.IsAscending
                ? query.OrderBy(r => r.CreatedAt)
                : query.OrderByDescending(r => r.CreatedAt)
        };

        // 4. Phân trang
        var totalCount = await query.CountAsync();
        var reviews = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        var dtos = reviews.Select(r => r.ToDto()).ToList();

        return new PagedResult<ReviewDto>(dtos, totalCount, filter.Page, filter.PageSize);
    }

    public async Task<ReviewDto> CreateReviewAsync(int userId, CreateReviewRequestDto request)
    {
        var orderItem = await dbContext.OrderItems
            .Include(oi => oi.Order)
            .Include(oi => oi.Variant)
            .FirstOrDefaultAsync(oi => oi.OrderItemId == request.OrderItemId)
            ?? throw new NotFoundException($"Không tìm thấy sản phẩm trong đơn hàng với mã ID {request.OrderItemId}.");

        await ValidateOrderEligibilityForReviewAsync(orderItem, userId);

        var productId = await ResolveProductIdAsync(orderItem);

        var review = new ProductReview
        {
            UserId = userId,
            ProductId = productId,
            OrderItemId = request.OrderItemId,
            Rating = request.Rating,
            Comment = request.Comment?.Trim(),
            ImageUrls = request.ImageUrls ?? new List<string>(),
            IsHidden = false,
            CreatedAt = DateTime.UtcNow
        };

        orderItem.IsReviewed = true;
        dbContext.ProductReviews.Add(review);
        await dbContext.SaveChangesAsync();

        return await GetReviewByIdAsync(review.ReviewId);
    }

    public async Task<PagedResult<ReviewDto>> GetMyReviewsAsync(int userId, PaginationParams filter)
    {
        var query = dbContext.ProductReviews
            .AsNoTracking()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.OrderItem)
                .ThenInclude(oi => oi.Order)
            .Where(r => r.UserId == userId)
            .AsQueryable();

        query = filter.IsAscending
            ? query.OrderBy(r => r.CreatedAt)
            : query.OrderByDescending(r => r.CreatedAt);

        var totalCount = await query.CountAsync();
        var reviews = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        var dtos = reviews.Select(r => r.ToDto()).ToList();

        return new PagedResult<ReviewDto>(dtos, totalCount, filter.Page, filter.PageSize);
    }

    public async Task<ReviewDto> UpdateMyReviewAsync(int reviewId, int userId, UpdateReviewRequestDto request)
    {
        var review = await FindReviewOrThrowAsync(reviewId);

        if (review.UserId != userId)
        {
            throw new ForbiddenException("Bạn không có quyền chỉnh sửa đánh giá này.");
        }

        if (!review.IsEditable(MaxReviewEditableDays))
        {
            throw new BadRequestException($"Đã quá {MaxReviewEditableDays} ngày kể từ lúc gửi đánh giá, bạn không thể chỉnh sửa nữa.");
        }

        review.UpdateContent(request.Rating, request.Comment, request.ImageUrls);
        await dbContext.SaveChangesAsync();

        return review.ToDto();
    }

    public async Task<PagedResult<PendingReviewItemDto>> GetPendingReviewItemsAsync(int userId, PaginationParams filter)
    {
        var query = dbContext.OrderItems
            .AsNoTracking()
            .Include(oi => oi.Order)
            .Include(oi => oi.Variant)
            .Where(oi => oi.Order.UserId == userId
                         && oi.Order.OrderStatus == OrderStatus.DELIVERED
                         && !oi.IsReviewed);

        var totalCount = await query.CountAsync();
        var items = await query
            .OrderByDescending(oi => oi.Order.CreatedAt)
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .Select(MappingExtensions.AsPendingReviewItemDto)
            .ToListAsync();

        return new PagedResult<PendingReviewItemDto>(items, totalCount, filter.Page, filter.PageSize);
    }

    public async Task<PagedResult<ReviewDto>> GetAdminReviewsAsync(AdminReviewQueryFilter filter)
    {
        var query = dbContext.ProductReviews
            .AsNoTracking()
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.OrderItem)
                .ThenInclude(oi => oi.Order)
            .AsQueryable();

        // 1. Lọc theo sản phẩm và người dùng
        if (filter.ProductId.HasValue)
        {
            query = query.Where(r => r.ProductId == filter.ProductId.Value);
        }

        if (filter.UserId.HasValue)
        {
            query = query.Where(r => r.UserId == filter.UserId.Value);
        }

        // 2. Lọc theo số sao đánh giá
        if (filter.Rating.HasValue)
        {
            query = query.Where(r => r.Rating == filter.Rating.Value);
        }

        if (filter.MinRating.HasValue)
        {
            query = query.Where(r => r.Rating >= filter.MinRating.Value);
        }

        if (filter.MaxRating.HasValue)
        {
            query = query.Where(r => r.Rating <= filter.MaxRating.Value);
        }

        // 3. Lọc theo trạng thái phản hồi của Shop
        if (filter.HasReply.HasValue)
        {
            query = filter.HasReply.Value
                ? query.Where(r => r.ReplyContent != null && r.ReplyContent != string.Empty)
                : query.Where(r => r.ReplyContent == null || r.ReplyContent == string.Empty);
        }

        // 4. Lọc theo trạng thái ẩn/hiện
        if (filter.IsHidden.HasValue)
        {
            query = query.Where(r => r.IsHidden == filter.IsHidden.Value);
        }

        // 5. Lọc theo đánh giá có hình ảnh đính kèm
        if (filter.HasImages.HasValue)
        {
            query = filter.HasImages.Value
                ? query.Where(r => r.ImageUrls.Count > 0)
                : query.Where(r => r.ImageUrls.Count == 0);
        }

        // 6. Lọc theo khoảng thời gian tạo đánh giá
        if (filter.FromDate.HasValue)
        {
            query = query.Where(r => r.CreatedAt >= filter.FromDate.Value);
        }

        if (filter.ToDate.HasValue)
        {
            query = query.Where(r => r.CreatedAt <= filter.ToDate.Value);
        }

        // 7. Lọc theo từ khóa tìm kiếm
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var searchLower = filter.Search.Trim().ToLower();
            query = query.Where(r =>
                (r.Comment != null && r.Comment.ToLower().Contains(searchLower)) ||
                r.User.Username.ToLower().Contains(searchLower) ||
                r.User.FullName.ToLower().Contains(searchLower) ||
                r.Product.ProductName.ToLower().Contains(searchLower)
            );
        }

        // 8. Sắp xếp danh sách
        query = (filter.SortBy?.ToLower()) switch
        {
            "rating" => filter.IsAscending
                ? query.OrderBy(r => r.Rating).ThenByDescending(r => r.CreatedAt)
                : query.OrderByDescending(r => r.Rating).ThenByDescending(r => r.CreatedAt),
            "product" => filter.IsAscending
                ? query.OrderBy(r => r.Product.ProductName)
                : query.OrderByDescending(r => r.Product.ProductName),
            _ => filter.IsAscending
                ? query.OrderBy(r => r.CreatedAt)
                : query.OrderByDescending(r => r.CreatedAt)
        };

        // 9. Phân trang
        var totalCount = await query.CountAsync();
        var reviews = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        var dtos = reviews.Select(r => r.ToDto()).ToList();

        return new PagedResult<ReviewDto>(dtos, totalCount, filter.Page, filter.PageSize);
    }

    public async Task<ReviewDto> GetReviewByIdAsync(int reviewId)
    {
        var review = await FindReviewOrThrowAsync(reviewId, asNoTracking: true);
        return review.ToDto();
    }

    public async Task<ReviewDto> ReplyReviewAsync(int reviewId, ReplyReviewRequestDto request)
    {
        var review = await FindReviewOrThrowAsync(reviewId);
        review.AddReply(request.ReplyContent);
        await dbContext.SaveChangesAsync();

        return review.ToDto();
    }

    public async Task<ReviewDto> DeleteReplyAsync(int reviewId)
    {
        var review = await FindReviewOrThrowAsync(reviewId);
        review.ClearReply();
        await dbContext.SaveChangesAsync();

        return review.ToDto();
    }

    public async Task<ReviewDto> ToggleHideReviewAsync(int reviewId, bool isHidden)
    {
        var review = await FindReviewOrThrowAsync(reviewId);
        review.SetVisibility(isHidden);
        await dbContext.SaveChangesAsync();

        return review.ToDto();
    }

    public async Task<bool> DeleteReviewAsync(int reviewId)
    {
        var review = await dbContext.ProductReviews
            .Include(r => r.OrderItem)
            .FirstOrDefaultAsync(r => r.ReviewId == reviewId)
            ?? throw new NotFoundException($"Không tìm thấy đánh giá với mã ID {reviewId}.");

        if (review.OrderItem != null)
        {
            review.OrderItem.IsReviewed = false;
        }

        dbContext.ProductReviews.Remove(review);
        await dbContext.SaveChangesAsync();

        return true;
    }

    public async Task<ReviewStatisticsDto> GetReviewStatisticsAsync(int? productId = null)
    {
        var query = dbContext.ProductReviews.AsNoTracking().AsQueryable();

        if (productId.HasValue)
        {
            query = query.Where(r => r.ProductId == productId.Value);
        }

        var totalReviews = await query.CountAsync();
        if (totalReviews == 0)
        {
            return new ReviewStatisticsDto
            {
                TotalReviews = 0,
                AverageRating = 0,
                TotalReplied = 0,
                TotalHidden = 0,
                RatingDistribution = new Dictionary<string, int>()
            };
        }

        var avgRating = await query.AverageAsync(r => r.Rating);
        var totalReplied = await query.CountAsync(r => r.ReplyContent != null && r.ReplyContent != string.Empty);
        var totalHidden = await query.CountAsync(r => r.IsHidden);

        var distributionGroups = await query
            .GroupBy(r => r.Rating)
            .Select(g => new { Rating = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Rating)
            .ToListAsync();

        var distributionDict = distributionGroups.ToDictionary(
            g => g.Rating.ToString("0.0"),
            g => g.Count
        );

        var topRatedProducts = new List<ProductRatingRankingDto>();
        var lowestRatedProducts = new List<ProductRatingRankingDto>();

        if (!productId.HasValue)
        {
            var productStats = await dbContext.ProductReviews
                .AsNoTracking()
                .Where(r => !r.IsHidden)
                .GroupBy(r => new { r.ProductId, r.Product.ProductName, r.Product.ImageUrl })
                .Select(g => new ProductRatingRankingDto
                {
                    ProductId = g.Key.ProductId,
                    ProductName = g.Key.ProductName,
                    ProductImageUrl = g.Key.ImageUrl,
                    TotalReviews = g.Count(),
                    AverageRating = Math.Round((decimal)g.Average(r => r.Rating), 1),
                    PositiveReviewCount = g.Count(r => r.Rating >= 4.0m),
                    NegativeReviewCount = g.Count(r => r.Rating <= 2.0m)
                })
                .ToListAsync();

            topRatedProducts = productStats
                .OrderByDescending(p => p.AverageRating)
                .ThenByDescending(p => p.TotalReviews)
                .Take(5)
                .ToList();

            lowestRatedProducts = productStats
                .OrderByDescending(p => p.NegativeReviewCount)
                .ThenBy(p => p.AverageRating)
                .ThenByDescending(p => p.TotalReviews)
                .Take(5)
                .ToList();
        }

        return new ReviewStatisticsDto
        {
            TotalReviews = totalReviews,
            AverageRating = Math.Round(avgRating, 1),
            TotalReplied = totalReplied,
            TotalHidden = totalHidden,
            RatingDistribution = distributionDict,
            TopRatedProducts = topRatedProducts,
            LowestRatedProducts = lowestRatedProducts
        };
    }

    private async Task<ProductReview> FindReviewOrThrowAsync(int reviewId, bool asNoTracking = false)
    {
        var query = asNoTracking ? dbContext.ProductReviews.AsNoTracking() : dbContext.ProductReviews;
        return await query
            .Include(r => r.User)
            .Include(r => r.Product)
            .Include(r => r.OrderItem)
                .ThenInclude(oi => oi.Order)
            .FirstOrDefaultAsync(r => r.ReviewId == reviewId)
            ?? throw new NotFoundException($"Không tìm thấy đánh giá với mã ID {reviewId}.");
    }

    private async Task ValidateOrderEligibilityForReviewAsync(OrderItem orderItem, int userId)
    {
        if (orderItem.Order.UserId != userId)
        {
            throw new ForbiddenException("Bạn không thể đánh giá sản phẩm thuộc đơn hàng của tài khoản khác.");
        }

        if (orderItem.Order.OrderStatus != OrderStatus.DELIVERED)
        {
            throw new BadRequestException("Chỉ có thể đánh giá sản phẩm khi đơn hàng đã được giao thành công.");
        }

        if (orderItem.IsReviewed || await dbContext.ProductReviews.AnyAsync(r => r.OrderItemId == orderItem.OrderItemId))
        {
            throw new BadRequestException("Món hàng này đã được gửi đánh giá trước đó.");
        }
    }

    private async Task<int> ResolveProductIdAsync(OrderItem orderItem)
    {
        var productId = orderItem.Variant?.ProductId
            ?? await dbContext.ProductVariants
                .Where(v => v.VariantId == orderItem.VariantId)
                .Select(v => v.ProductId)
                .FirstOrDefaultAsync();

        if (productId == 0)
        {
            throw new BadRequestException("Không xác định được sản phẩm tương ứng với món hàng này.");
        }

        return productId;
    }
}
