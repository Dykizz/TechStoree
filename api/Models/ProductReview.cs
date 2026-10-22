using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("reviews")]
public class ProductReview
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("review_id")]
    public int ReviewId { get; set; }

    [Required]
    [Column("user_id")]
    public int UserId { get; set; }

    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    [Required]
    [Column("product_id")]
    public int ProductId { get; set; }

    [ForeignKey("ProductId")]
    public Product Product { get; set; } = null!;

    [Required]
    [Column("order_item_id")]
    public int OrderItemId { get; set; }

    [ForeignKey("OrderItemId")]
    public OrderItem OrderItem { get; set; } = null!;

    [Range(1.0, 5.0, ErrorMessage = "Số sao đánh giá phải từ 1.0 đến 5.0")]
    [Column("rating", TypeName = "decimal(2,1)")]
    public decimal Rating { get; set; }

    [MaxLength(1000)]
    [Column("comment")]
    public string? Comment { get; set; }

    [Column("image_urls", TypeName = "jsonb")]
    public List<string> ImageUrls { get; set; } = new();

    [MaxLength(1000)]
    [Column("reply_content")]
    public string? ReplyContent { get; set; }

    [Column("replied_at")]
    public DateTime? RepliedAt { get; set; }

    [Column("is_hidden")]
    public bool IsHidden { get; set; } = false;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime? UpdatedAt { get; set; }

    public void AddReply(string replyContent)
    {
        ReplyContent = replyContent.Trim();
        RepliedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void ClearReply()
    {
        ReplyContent = null;
        RepliedAt = null;
        UpdatedAt = DateTime.UtcNow;
    }

    public void SetVisibility(bool isHidden)
    {
        IsHidden = isHidden;
        UpdatedAt = DateTime.UtcNow;
    }

    public void UpdateContent(decimal rating, string? comment, List<string> imageUrls)
    {
        Rating = rating;
        Comment = comment?.Trim();
        ImageUrls = imageUrls ?? new List<string>();
        UpdatedAt = DateTime.UtcNow;
    }

    public bool IsEditable(int maxDaysAllowed) =>
        (DateTime.UtcNow - CreatedAt).TotalDays <= maxDaysAllowed;
}
