using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

/// <summary>
/// Thực thể Giao bài khảo sát tới từng khách hàng mục tiêu (Targeted Survey Campaign)
/// Cho phép đo lường tỷ lệ phản hồi (Response Rate) và chống gian lận nộp bài lặp lại.
/// </summary>
[Table("survey_assignments")]
public class SurveyAssignment
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("assignment_id")]
    public int AssignmentId { get; set; }

    [Required]
    [Column("survey_id")]
    public int SurveyId { get; set; }

    [ForeignKey("SurveyId")]
    public Survey Survey { get; set; } = null!;

    [Required]
    [Column("user_id")]
    public int UserId { get; set; }

    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    /// <summary>
    /// Thời điểm phát bài khảo sát tới tài khoản khách hàng
    /// </summary>
    [Column("assigned_at")]
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Thời điểm khách hàng hoàn thành nộp bài (NULL = Chưa làm)
    /// </summary>
    [Column("completed_at")]
    public DateTime? CompletedAt { get; set; }

    /// <summary>
    /// Các câu trả lời thuộc lượt nộp bài này
    /// </summary>
    public ICollection<SurveyAnswer> Answers { get; set; } = new List<SurveyAnswer>();
}
