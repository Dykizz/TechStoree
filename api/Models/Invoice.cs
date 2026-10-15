using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.Models;

[Table("invoices")]
public class Invoice
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("invoice_id")]
    public int InvoiceId { get; set; }

    /// <summary>
    /// Mã hóa đơn duy nhất (VD: INV-ORD-20261015-8A3F)
    /// </summary>
    [Required]
    [Column("invoice_code")]
    [MaxLength(50)]
    public string InvoiceCode { get; set; } = string.Empty;

    [Required]
    [Column("order_id")]
    public int OrderId { get; set; }

    [ForeignKey("OrderId")]
    public Order Order { get; set; } = null!;

    [Required]
    [Column("user_id")]
    public int UserId { get; set; }

    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    /// <summary>
    /// Tổng số tiền trên hóa đơn (lấy từ đơn hàng)
    /// </summary>
    [Column("total_amount")]
    public decimal TotalAmount { get; set; }

    /// <summary>
    /// Trạng thái hóa đơn: UNPAID (Chưa trả), PAID (Đã trả), CANCELLED (Bị hủy)
    /// </summary>
    [Column("status")]
    [MaxLength(30)]
    public InvoiceStatus Status { get; set; } = InvoiceStatus.UNPAID;

    /// <summary>
    /// Phương thức thanh toán (COD, VNPAY, BANK_TRANSFER)
    /// </summary>
    [Column("payment_method")]
    [MaxLength(30)]
    public PaymentMethod PaymentMethod { get; set; } = PaymentMethod.COD;

    /// <summary>
    /// Thời điểm thanh toán thành công (nếu đã thanh toán)
    /// </summary>
    [Column("paid_at")]
    public DateTime? PaidAt { get; set; }

    /// <summary>
    /// Thời điểm lập hóa đơn
    /// </summary>
    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Ghi chú trên hóa đơn
    /// </summary>
    [Column("note")]
    [MaxLength(500)]
    public string? Note { get; set; }
}
