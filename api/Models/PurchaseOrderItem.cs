using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("purchase_order_items")]
public class PurchaseOrderItem
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("po_item_id")]
    public int PoItemId { get; set; }

    [Column("purchase_order_id")]
    public int PurchaseOrderId { get; set; }

    [ForeignKey("PurchaseOrderId")]
    public PurchaseOrder? PurchaseOrder { get; set; }

    [Column("variant_id")]
    public int VariantId { get; set; }

    [ForeignKey("VariantId")]
    public ProductVariant? Variant { get; set; }

    [Column("import_price", TypeName = "decimal(12,0)")]
    public decimal ImportPrice { get; set; }

    [Column("quantity")]
    public int Quantity { get; set; }
}
