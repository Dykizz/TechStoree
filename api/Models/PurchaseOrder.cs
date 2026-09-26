using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("purchase_orders")]
public class PurchaseOrder
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("purchase_order_id")]
    public int PurchaseOrderId { get; set; }

    [Required]
    [Column("po_code")]
    [MaxLength(30)]
    public string PoCode { get; set; } = string.Empty;

    [Column("supplier_id")]
    public int SupplierId { get; set; }

    [ForeignKey("SupplierId")]
    public Supplier? Supplier { get; set; }

    [Column("created_by_user_id")]
    public int CreatedByUserId { get; set; }

    [ForeignKey("CreatedByUserId")]
    public User? CreatedByUser { get; set; }

    [Column("total_cost", TypeName = "decimal(12,0)")]
    public decimal TotalCost { get; set; }

    [Column("status")]
    [MaxLength(30)]
    public PurchaseOrderStatus Status { get; set; } = PurchaseOrderStatus.DRAFT;

    [Column("note")]
    public string? Note { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<PurchaseOrderItem> Items { get; set; } = new List<PurchaseOrderItem>();
}
