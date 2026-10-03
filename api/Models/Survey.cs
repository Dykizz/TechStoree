using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

/// <summary>
/// Thực thể Chiến dịch khảo sát thị trường và đánh giá mức độ hài lòng khách hàng (CRM Survey)
/// </summary>
[Table("surveys")]
public class Survey
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("survey_id")]
    public int SurveyId { get; set; }

    [Required]
    [MaxLength(255)]
    [Column("title")]
    public string Title { get; set; } = string.Empty;

    [Column("description")]
    public string? Description { get; set; }

    /// <summary>
    /// Mã voucher quà tặng sau khi hoàn thành khảo sát (Tùy chọn - Liên kết phân hệ Khuyến mãi CRM)
    /// </summary>
    [Column("reward_voucher_id")]
    public int? RewardVoucherId { get; set; }

    [ForeignKey("RewardVoucherId")]
    public Voucher? RewardVoucher { get; set; }

    /// <summary>
    /// Trạng thái mở nhận phản hồi (true = Đang hoạt động, false = Đã đóng khảo sát)
    /// </summary>
    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Danh sách câu hỏi trong bài khảo sát
    /// </summary>
    public ICollection<SurveyQuestion> Questions { get; set; } = new List<SurveyQuestion>();

    /// <summary>
    /// Danh sách phát khảo sát tới từng khách hàng mục tiêu
    /// </summary>
    public ICollection<SurveyAssignment> Assignments { get; set; } = new List<SurveyAssignment>();
}
