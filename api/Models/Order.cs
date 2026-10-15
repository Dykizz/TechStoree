using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("orders")]
public class Order
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("order_id")]
    public int OrderId { get; set; }

    /// <summary>
    /// Mã đơn hàng duy nhất trên hệ thống (VD: ORD-20260926-8A3F)
    /// </summary>
    [Required]
    [Column("order_code")]
    [MaxLength(50)]
    public string OrderCode { get; set; } = string.Empty;

    [Required]
    [Column("user_id")]
    public int UserId { get; set; }

    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    // ==========================================
    // SNAPSHOT THÔNG TIN GIAO NHẬN
    // ==========================================

    [Required]
    [Column("receiver_name")]
    [MaxLength(100)]
    public string ReceiverName { get; set; } = string.Empty;

    [Required]
    [Column("receiver_phone")]
    [MaxLength(20)]
    public string ReceiverPhone { get; set; } = string.Empty;

    [Required]
    [Column("shipping_address")]
    [MaxLength(500)]
    public string ShippingAddress { get; set; } = string.Empty;

    [Column("notes")]
    [MaxLength(500)]
    public string? Notes { get; set; }

    // ==========================================
    // TRẠNG THÁI TIẾN TRÌNH & THANH TOÁN (ENUMS)
    // ==========================================

    [Column("order_status")]
    [MaxLength(30)]
    public OrderStatus OrderStatus { get; set; } = OrderStatus.PENDING;

    [Column("payment_method")]
    [MaxLength(30)]
    public PaymentMethod PaymentMethod { get; set; } = PaymentMethod.COD;

    [Column("payment_status")]
    [MaxLength(30)]
    public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.PENDING;

    // ==========================================
    // TÀI CHÍNH & SNAPSHOT VOUCHER (ORDER-LEVEL)
    // ==========================================

    /// <summary>
    /// Tổng tiền hàng trước khi áp Voucher (tính theo UnitPrice của các OrderItems)
    /// </summary>
    [Column("subtotal_amount")]
    public decimal SubtotalAmount { get; set; }

    /// <summary>
    /// Mã ID Voucher áp dụng (null nếu không dùng voucher hoặc voucher gốc bị xóa sau này)
    /// </summary>
    [Column("voucher_id")]
    public int? VoucherId { get; set; }

    [ForeignKey("VoucherId")]
    public Voucher? Voucher { get; set; }

    [Column("voucher_code")]
    [MaxLength(50)]
    public string? VoucherCode { get; set; }

    [Column("voucher_title")]
    [MaxLength(200)]
    public string? VoucherTitle { get; set; }

    [Column("voucher_discount_amount")]
    public decimal VoucherDiscountAmount { get; set; } = 0;

    /// <summary>
    /// Tổng số tiền thực tế khách phải trả = SubtotalAmount - VoucherDiscountAmount
    /// </summary>
    [Column("total_amount")]
    public decimal TotalAmount { get; set; }


    // ==========================================
    // AUDITING & QUẢN LÝ THỜI GIAN / HỦY ĐƠN
    // ==========================================

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_by_user_id")]
    public int? UpdatedByUserId { get; set; }

    [ForeignKey("UpdatedByUserId")]
    public User? UpdatedByUser { get; set; }

    [Column("paid_at")]
    public DateTime? PaidAt { get; set; }

    [Column("cancelled_at")]
    public DateTime? CancelledAt { get; set; }

    [Column("cancellation_reason")]
    [MaxLength(500)]
    public string? CancellationReason { get; set; }

    // Danh sách sản phẩm trong đơn hàng
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
}
