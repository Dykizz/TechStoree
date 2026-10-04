using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.Models;

/// <summary>
/// Thực thể Câu hỏi trong bài khảo sát thăm dò thị trường
/// </summary>
[Table("survey_questions")]
public class SurveyQuestion
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("question_id")]
    public int QuestionId { get; set; }

    [Required]
    [Column("survey_id")]
    public int SurveyId { get; set; }

    [ForeignKey("SurveyId")]
    public Survey Survey { get; set; } = null!;

    [Required]
    [Column("question_text")]
    public string QuestionText { get; set; } = string.Empty;

    /// <summary>
    /// Loại câu hỏi: SINGLE_CHOICE (Trắc nghiệm), TEXT (Tự luận)
    /// </summary>
    [Required]
    [MaxLength(20)]
    [Column("question_type")]
    public SurveyQuestionType QuestionType { get; set; } = SurveyQuestionType.SINGLE_CHOICE;

    /// <summary>
    /// Bắt buộc trả lời (true) hoặc Cho phép bỏ qua (false)
    /// </summary>
    [Column("is_required")]
    public bool IsRequired { get; set; } = true;

    /// <summary>
    /// Thứ tự hiển thị câu hỏi trong bài khảo sát (1, 2, 3...)
    /// </summary>
    [Column("order_num")]
    public int OrderNum { get; set; } = 1;

    /// <summary>
    /// Danh sách đáp án lựa chọn (Chỉ áp dụng với câu hỏi SINGLE_CHOICE)
    /// </summary>
    public ICollection<SurveyOption> Options { get; set; } = new List<SurveyOption>();

    /// <summary>
    /// Các câu trả lời thực tế từ khách hàng
    /// </summary>
    public ICollection<SurveyAnswer> Answers { get; set; } = new List<SurveyAnswer>();
}
