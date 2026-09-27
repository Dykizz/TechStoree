using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("vouchers")]
public class Voucher
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("voucher_id")]
    public int VoucherId { get; set; }

    /// <summary>
    /// Mã code giảm giá viết hoa, duy nhất trên toàn sàn (VD: CELLPHONES100K, FREESHIP)
    /// </summary>
    [Required]
    [Column("code")]
    [MaxLength(50)]
    public string Code { get; set; } = string.Empty;

    /// <summary>
    /// Tiêu đề hiển thị ngắn gọn (VD: Giảm 100K cho đơn từ 2 triệu)
    /// </summary>
    [Required]
    [Column("title")]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [Column("description")]
    [MaxLength(1000)]
    public string? Description { get; set; }

    /// <summary>
    /// Loại giảm giá: PERCENTAGE (giảm theo %) hoặc FIXED_AMOUNT (giảm số tiền cố định)
    /// </summary>
    [Required]
    [Column("discount_type")]
    [MaxLength(20)]
    public DiscountType DiscountType { get; set; } = DiscountType.PERCENTAGE;

    /// <summary>
    /// Giá trị giảm: VD 10 (10%) hoặc 100000 (100,000 VNĐ)
    /// </summary>
    [Column("discount_value")]
    public decimal DiscountValue { get; set; }

    /// <summary>
    /// Giá trị giỏ hàng tối thiểu để được áp dụng voucher (VNĐ)
    /// </summary>
    [Column("min_order_value")]
    public decimal MinOrderValue { get; set; } = 0;

    /// <summary>
    /// Số tiền giảm tối đa (áp dụng khi DiscountType là PERCENTAGE)
    /// </summary>
    [Column("max_discount_amount")]
    public decimal? MaxDiscountAmount { get; set; }

    /// <summary>
    /// Giới hạn tổng số lượt sử dụng toàn hệ thống (null = không giới hạn)
    /// </summary>
    [Column("usage_limit")]
    public int? UsageLimit { get; set; }

    /// <summary>
    /// Số lượt đã được khách hàng sử dụng thực tế
    /// </summary>
    [Column("used_count")]
    public int UsedCount { get; set; } = 0;

    /// <summary>
    /// Giới hạn số lần sử dụng tối đa của mỗi tài khoản khách hàng
    /// </summary>
    [Column("limit_per_user")]
    public int LimitPerUser { get; set; } = 1;

    [Column("start_date")]
    public DateTime StartDate { get; set; }

    [Column("end_date")]
    public DateTime EndDate { get; set; }

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Hiển thị công khai trên sàn để khách hàng tự do thu thập / lưu vào ví (true).
    /// Nếu false: Voucher ẩn (chỉ tặng qua Khảo sát, sự kiện tri ân, Admin CRM, hoặc nhập mã trực tiếp).
    /// </summary>
    [Column("is_public")]
    public bool IsPublic { get; set; } = true;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation property liên kết danh sách khách hàng đã nhận / sử dụng voucher
    public ICollection<UserVoucher> UserVouchers { get; set; } = new List<UserVoucher>();
}
