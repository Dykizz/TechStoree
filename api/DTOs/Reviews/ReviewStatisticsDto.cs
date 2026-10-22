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
}
