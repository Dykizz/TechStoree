using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

/// <summary>
/// Thực thể Câu trả lời của khách hàng trong một bài khảo sát
/// Khóa chính phức hợp (assignment_id, question_id) chuẩn 3NF:
/// Cho phép lưu cả đáp án trắc nghiệm (selected_option_id) lẫn câu trả lời tự luận (text_answer).
/// </summary>
[Table("survey_answers")]
public class SurveyAnswer
{
    [Column("assignment_id")]
    public int AssignmentId { get; set; }

    [ForeignKey("AssignmentId")]
    public SurveyAssignment Assignment { get; set; } = null!;

    [Column("question_id")]
    public int QuestionId { get; set; }

    [ForeignKey("QuestionId")]
    public SurveyQuestion Question { get; set; } = null!;

    /// <summary>
    /// ID đáp án trắc nghiệm được chọn (NULL nếu là câu tự luận)
    /// </summary>
    [Column("selected_option_id")]
    public int? SelectedOptionId { get; set; }

    [ForeignKey("SelectedOptionId")]
    public SurveyOption? SelectedOption { get; set; }

    /// <summary>
    /// Nội dung trả lời tự luận / góp ý (NULL nếu là câu trắc nghiệm)
    /// </summary>
    [Column("text_answer")]
    public string? TextAnswer { get; set; }
}
