using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("user_vouchers")]
public class UserVoucher
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("user_voucher_id")]
    public int UserVoucherId { get; set; }

    [Required]
    [Column("user_id")]
    public int UserId { get; set; }

    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    [Required]
    [Column("voucher_id")]
    public int VoucherId { get; set; }

    [ForeignKey("VoucherId")]
    public Voucher Voucher { get; set; } = null!;

    /// <summary>
    /// Hình thức cấp voucher: CLAIMED, ADMIN_GIFT, SURVEY_REWARD
    /// </summary>
    [Required]
    [Column("assigned_type")]
    [MaxLength(50)]
    public VoucherAssignedType AssignedType { get; set; } = VoucherAssignedType.CLAIMED;

    /// <summary>
    /// Thời điểm voucher được đưa vào ví của khách
    /// </summary>
    [Column("assigned_at")]
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Trạng thái đã sử dụng hay chưa
    /// </summary>
    [Column("is_used")]
    public bool IsUsed { get; set; } = false;

    /// <summary>
    /// Thời điểm khách hàng dùng voucher thanh toán đơn hàng
    /// </summary>
    [Column("used_at")]
    public DateTime? UsedAt { get; set; }

    /// <summary>
    /// Mã đơn hàng áp dụng voucher này (nếu có)
    /// </summary>
    [Column("order_id")]
    public int? OrderId { get; set; }
}
