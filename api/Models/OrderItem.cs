using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("order_items")]
public class OrderItem
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("order_item_id")]
    public int OrderItemId { get; set; }

    [Required]
    [Column("order_id")]
    public int OrderId { get; set; }

    [ForeignKey("OrderId")]
    public Order Order { get; set; } = null!;

    [Required]
    [Column("variant_id")]
    public int VariantId { get; set; }

    [ForeignKey("VariantId")]
    public ProductVariant Variant { get; set; } = null!;

    // ==========================================
    // SNAPSHOT THÔNG TIN SẢN PHẨM LÚC MUA
    // ==========================================

    [Required]
    [Column("product_name")]
    [MaxLength(200)]
    public string ProductName { get; set; } = string.Empty;

    [Required]
    [Column("variant_name")]
    [MaxLength(150)]
    public string VariantName { get; set; } = string.Empty;

    [Column("image_url")]
    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    // ==========================================
    // SNAPSHOT GIÁ & PROMOTION (ITEM-LEVEL)
    // ==========================================

    /// <summary>
    /// Giá niêm yết gốc tại thời điểm mua (trước khi giảm giá)
    /// </summary>
    [Column("original_price")]
    public decimal OriginalPrice { get; set; }

    /// <summary>
    /// Đơn giá bán thực tế sau khi đã áp dụng Promotion sản phẩm
    /// </summary>
    [Column("unit_price")]
    public decimal UnitPrice { get; set; }

    /// <summary>
    /// Mã ID Promotion sản phẩm (null nếu không có khuyến mãi lúc mua)
    /// </summary>
    [Column("promotion_id")]
    public int? PromotionId { get; set; }

    [ForeignKey("PromotionId")]
    public Promotion? Promotion { get; set; }

    /// <summary>
    /// Tên chương trình khuyến mãi (VD: Flash Sale Tháng 9 - Giảm 3 Triệu)
    /// </summary>
    [Column("promotion_name")]
    [MaxLength(200)]
    public string? PromotionName { get; set; }

    /// <summary>
    /// Số tiền được giảm trên mỗi sản phẩm từ Promotion (OriginalPrice - UnitPrice)
    /// </summary>
    [Column("promotion_discount")]
    public decimal PromotionDiscount { get; set; } = 0;

    [Column("quantity")]
    public int Quantity { get; set; }

    /// <summary>
    /// Thành tiền của dòng hàng = UnitPrice * Quantity
    /// </summary>
    [Column("total_price")]
    public decimal TotalPrice { get; set; }
}
