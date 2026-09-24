using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("product_variants")]
public class ProductVariant
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("variant_id")]
    public int VariantId { get; set; }

    [Column("product_id")]
    public int ProductId { get; set; }

    [ForeignKey("ProductId")]
    public Product? Product { get; set; }

    [Required]
    [Column("variant_name")]
    [MaxLength(150)]
    public string VariantName { get; set; } = string.Empty;

    [Column("price")]
    public decimal Price { get; set; }

    [Column("stock_quantity")]
    public int StockQuantity { get; set; } = 0;

    [Column("image_url")]
    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    // Giá trị thuộc tính cụ thể lưu dưới dạng JSONB (VD: {"Dung lượng": "256GB", "Màu sắc": "Titan Sa Mạc"})
    [Column("attributes", TypeName = "jsonb")]
    public Dictionary<string, string> Attributes { get; set; } = new();

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
