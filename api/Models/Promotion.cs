using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("promotions")]
public class Promotion
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("promotion_id")]
    public int PromotionId { get; set; }

    [Required]
    [Column("name")]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Column("description")]
    public string? Description { get; set; }

    /// <summary>
    /// Loại giảm giá: "PERCENTAGE" (giảm theo %) hoặc "FIXED_AMOUNT" (giảm số tiền cố định)
    /// </summary>
    [Required]
    [Column("discount_type")]
    [MaxLength(20)]
    public string DiscountType { get; set; } = "PERCENTAGE";

    /// <summary>
    /// Giá trị giảm: VD 10 (10%) hoặc 500000 (500,000 VNĐ)
    /// </summary>
    [Column("discount_value")]
    public decimal DiscountValue { get; set; }

    [Column("start_date")]
    public DateTime StartDate { get; set; }

    [Column("end_date")]
    public DateTime EndDate { get; set; }

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation property nhiều - nhiều trực tiếp tới ProductVariant
    public ICollection<ProductVariant> Variants { get; set; } = new List<ProductVariant>();
}
