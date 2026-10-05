using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

/// <summary>
/// Thực thể Đáp án trắc nghiệm cho câu hỏi khảo sát
/// </summary>
[Table("survey_options")]
public class SurveyOption
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("option_id")]
    public int OptionId { get; set; }

    [Required]
    [Column("question_id")]
    public int QuestionId { get; set; }

    [ForeignKey("QuestionId")]
    public SurveyQuestion Question { get; set; } = null!;

    [Required]
    [MaxLength(255)]
    [Column("option_text")]
    public string OptionText { get; set; } = string.Empty;

    /// <summary>
    /// Thứ tự hiển thị đáp án (A: 1, B: 2, C: 3...)
    /// </summary>
    [Column("order_num")]
    public int OrderNum { get; set; } = 1;

    /// <summary>
    /// Các câu trả lời chọn đáp án này
    /// </summary>
    public ICollection<SurveyAnswer> Answers { get; set; } = new List<SurveyAnswer>();
}
