using System.Text.Json.Serialization;

namespace WebBanHang.Api.Enums;

/// <summary>
/// Loại câu hỏi trong bài khảo sát thăm dò thị trường CRM:
/// SINGLE_CHOICE (Trắc nghiệm 1 đáp án), TEXT (Tự luận / Đóng góp ý kiến)
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum SurveyQuestionType
{
    /// <summary>
    /// Trắc nghiệm lựa chọn 1 đáp án (Radio Group - Hỗ trợ vẽ biểu đồ tròn/cột % trên Dashboard CRM)
    /// </summary>
    SINGLE_CHOICE,

    /// <summary>
    /// Câu hỏi tự luận điền chữ (Textarea - Hỗ trợ thu thập ý kiến, phản hồi chi tiết từ khách hàng)
    /// </summary>
    TEXT
}
