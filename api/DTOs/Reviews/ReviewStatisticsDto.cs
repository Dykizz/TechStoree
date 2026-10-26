namespace WebBanHang.Api.DTOs.Reviews;

/// <summary>
/// DTO thống kê tổng quan đánh giá
/// </summary>
public class ReviewStatisticsDto
{
    /// <summary>
    /// Tổng số lượt đánh giá
    /// </summary>
    /// <example>128</example>
    public int TotalReviews { get; set; }

    /// <summary>
    /// Điểm đánh giá trung bình
    /// </summary>
    /// <example>4.8</example>
    public decimal AverageRating { get; set; }

    /// <summary>
    /// Tổng số đánh giá đã được Shop phản hồi
    /// </summary>
    /// <example>115</example>
    public int TotalReplied { get; set; }

    /// <summary>
    /// Tổng số đánh giá đang bị ẩn
    /// </summary>
    /// <example>2</example>
    public int TotalHidden { get; set; }

    /// <summary>
    /// Phân bố số lượng đánh giá theo từng mức sao (ví dụ: "5.0": 90, "4.5": 20, ...)
    /// </summary>
    /// <example>{"5.0": 90, "4.5": 20, "4.0": 10, "3.5": 5, "3.0": 2, "2.0": 1}</example>
    public Dictionary<string, int> RatingDistribution { get; set; } = new();

    /// <summary>
    /// Top 5 sản phẩm đánh giá tốt nhất
    /// </summary>
    public List<ProductRatingRankingDto> TopRatedProducts { get; set; } = new();

    /// <summary>
    /// Top 5 sản phẩm đánh giá tiêu cực nhất / cần lưu ý
    /// </summary>
    public List<ProductRatingRankingDto> LowestRatedProducts { get; set; } = new();
}

/// <summary>
/// DTO xếp hạng đánh giá của một sản phẩm
/// </summary>
public class ProductRatingRankingDto
{
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? ProductImageUrl { get; set; }
    public decimal AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public int PositiveReviewCount { get; set; }
    public int NegativeReviewCount { get; set; }
}
