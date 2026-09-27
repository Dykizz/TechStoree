using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("cart_items")]
public class CartItem
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("cart_item_id")]
    public int CartItemId { get; set; }

    [Column("cart_id")]
    public int CartId { get; set; }

    [ForeignKey("CartId")]
    public Cart? Cart { get; set; }

    [Column("variant_id")]
    public int VariantId { get; set; }

    [ForeignKey("VariantId")]
    public ProductVariant? Variant { get; set; }

    [Column("quantity")]
    public int Quantity { get; set; } = 1;

    [Column("added_at")]
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
}
