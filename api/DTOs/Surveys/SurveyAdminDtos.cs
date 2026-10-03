using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.DTOs.Vouchers;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.DTOs.Surveys;

/// <summary>
/// DTO hiển thị danh sách khảo sát dành cho Admin / CRM Manager (kèm chỉ số tỷ lệ phản hồi)
/// </summary>
public class SurveyAdminListDto
{
    /// <example>1</example>
    public int SurveyId { get; set; }

    /// <example>Thăm dò nhu cầu Tai nghe chống ồn Sony WH-1000XM6</example>
    public string Title { get; set; } = string.Empty;

    /// <example>Khảo sát ý kiến khách hàng về màu sắc, tính năng chống ồn và tầm giá dự kiến của Sony WH-1000XM6</example>
    public string? Description { get; set; }

    /// <example>1</example>
    public int? RewardVoucherId { get; set; }

    /// <example>SONY50K</example>
    public string? RewardVoucherCode { get; set; }

    /// <example>Giảm 50K cho đơn hàng tai nghe</example>
    public string? RewardVoucherTitle { get; set; }

    /// <example>true</example>
    public bool IsActive { get; set; }

    /// <example>2026-10-01T08:00:00Z</example>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Tổng số lượng khách hàng đã được phát bài khảo sát
    /// </summary>
    /// <example>100</example>
    public int TotalAssigned { get; set; }

    /// <summary>
    /// Tổng số lượng khách hàng đã hoàn thành nộp bài
    /// </summary>
    /// <example>45</example>
    public int TotalCompleted { get; set; }

    /// <summary>
    /// Tỷ lệ phản hồi = (TotalCompleted / TotalAssigned) * 100%
    /// </summary>
    /// <example>45.0</example>
    public double ResponseRatePercent =>
        TotalAssigned > 0 ? Math.Round((double)TotalCompleted / TotalAssigned * 100, 1) : 0.0;

    /// <summary>
    /// Cờ đánh dấu đã có khách hàng nộp bài hay chưa (nếu true -> khóa cấu trúc câu hỏi)
    /// </summary>
    /// <example>true</example>
    public bool HasResponses => TotalCompleted > 0;
}

/// <summary>
/// DTO chi tiết bài khảo sát gồm danh sách câu hỏi và các đáp án
/// </summary>
public class SurveyAdminDetailDto : SurveyAdminListDto
{
    public List<SurveyQuestionDetailDto> Questions { get; set; } = new();

    public VoucherBaseDto? RewardVoucher { get; set; }
}

public class SurveyQuestionDetailDto
{
    /// <example>1</example>
    public int QuestionId { get; set; }

    /// <example>Mức giá bạn sẵn sàng chi trả cho Sony WH-1000XM6 là bao nhiêu?</example>
    public string QuestionText { get; set; } = string.Empty;

    /// <example>SINGLE_CHOICE</example>
    public SurveyQuestionType QuestionType { get; set; } = SurveyQuestionType.SINGLE_CHOICE;

    /// <example>true</example>
    public bool IsRequired { get; set; } = true;

    /// <example>1</example>
    public int OrderNum { get; set; } = 1;

    /// <summary>
    /// Tổng số câu trả lời của khách hàng cho câu hỏi này
    /// </summary>
    /// <example>45</example>
    public int TotalAnswers { get; set; }

    /// <summary>
    /// Danh sách các đáp án lựa chọn (kèm số lượt vote và tỉ lệ % cho câu hỏi trắc nghiệm)
    /// </summary>
    public List<SurveyOptionDto> Options { get; set; } = new();

    /// <summary>
    /// Danh sách các câu trả lời tự luận của khách hàng (dành cho câu hỏi TEXT)
    /// </summary>
    public List<TextAnswerDto> TextAnswers { get; set; } = new();
}

public class SurveyOptionDto
{
    /// <example>1</example>
    public int OptionId { get; set; }

    /// <example>Từ 8 đến 10 triệu đồng</example>
    public string OptionText { get; set; } = string.Empty;

    /// <example>1</example>
    public int OrderNum { get; set; } = 1;

    /// <summary>
    /// Số lượng khách hàng lựa chọn đáp án này
    /// </summary>
    /// <example>25</example>
    public int VoteCount { get; set; }

    /// <summary>
    /// Tỷ lệ phần trăm bình chọn (0 - 100%)
    /// </summary>
    /// <example>55.6</example>
    public double Percentage { get; set; }
}

/// <summary>
/// Request tạo mới bài khảo sát động
/// </summary>
public class CreateSurveyRequestDto
{
    /// <example>Thăm dò nhu cầu Tai nghe chống ồn Sony WH-1000XM6</example>
    [Required(ErrorMessage = "Tiêu đề bài khảo sát không được để trống.")]
    [MaxLength(255, ErrorMessage = "Tiêu đề không vượt quá 255 ký tự.")]
    public string Title { get; set; } = string.Empty;

    /// <example>Thu thập ý kiến khách hàng về tính năng và mức giá mong muốn cho thế hệ tai nghe chống ồn mới từ Sony.</example>
    public string? Description { get; set; }

    /// <summary>
    /// Voucher tặng thưởng khi khách nộp bài (tùy chọn)
    /// </summary>
    /// <example>1</example>
    public int? RewardVoucherId { get; set; }

    /// <example>true</example>
    public bool IsActive { get; set; } = true;

    [Required(ErrorMessage = "Bài khảo sát phải có ít nhất 1 câu hỏi.")]
    [MinLength(1, ErrorMessage = "Bài khảo sát phải có ít nhất 1 câu hỏi.")]
    public List<CreateSurveyQuestionDto> Questions { get; set; } = new();
}

public class CreateSurveyQuestionDto
{
    /// <example>Mức giá bạn sẵn sàng chi trả cho Sony WH-1000XM6 là bao nhiêu?</example>
    [Required(ErrorMessage = "Nội dung câu hỏi không được để trống.")]
    public string QuestionText { get; set; } = string.Empty;

    /// <example>SINGLE_CHOICE</example>
    public SurveyQuestionType QuestionType { get; set; } = SurveyQuestionType.SINGLE_CHOICE;

    /// <example>true</example>
    public bool IsRequired { get; set; } = true;

    /// <example>1</example>
    public int OrderNum { get; set; } = 1;

    /// <summary>
    /// Danh sách đáp án (Bắt buộc nếu là SINGLE_CHOICE)
    /// </summary>
    public List<CreateSurveyOptionDto>? Options { get; set; }
}

public class CreateSurveyOptionDto
{
    /// <example>Từ 8 đến 10 triệu đồng</example>
    [Required(ErrorMessage = "Nội dung đáp án không được để trống.")]
    [MaxLength(255, ErrorMessage = "Đáp án không vượt quá 255 ký tự.")]
    public string OptionText { get; set; } = string.Empty;

    /// <example>1</example>
    public int OrderNum { get; set; } = 1;
}

/// <summary>
/// Request cập nhật bài khảo sát (Nếu đã có người làm thì chỉ cho sửa Tiêu đề, Mô tả, IsActive)
/// </summary>
public class UpdateSurveyRequestDto
{
    /// <example>Thăm dò nhu cầu Tai nghe Sony WH-1000XM6 (Cập nhật)</example>
    [Required(ErrorMessage = "Tiêu đề bài khảo sát không được để trống.")]
    [MaxLength(255, ErrorMessage = "Tiêu đề không vượt quá 255 ký tự.")]
    public string Title { get; set; } = string.Empty;

    /// <example>Cập nhật mô tả nội dung chương trình khảo sát thị trường phụ kiện âm thanh.</example>
    public string? Description { get; set; }

    /// <example>1</example>
    public int? RewardVoucherId { get; set; }

    /// <example>true</example>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Danh sách câu hỏi mới (Chỉ áp dụng khi khảo sát CHƯA có ai nộp bài)
    /// </summary>
    public List<CreateSurveyQuestionDto>? Questions { get; set; }
}

/// <summary>
/// Request phát bài khảo sát tới nhóm khách hàng mục tiêu
/// </summary>
public class AssignSurveyRequestDto
{
    /// <summary>
    /// Hình thức nhắm mục tiêu: ALL (Tất cả KH), BY_IDS (Theo danh sách ID), BY_INTEREST (Theo sở thích công nghệ)
    /// </summary>
    /// <example>BY_INTEREST</example>
    [Required(ErrorMessage = "Vui lòng chọn hình thức nhắm mục tiêu.")]
    public SurveyTargetType TargetType { get; set; } = SurveyTargetType.ALL;

    /// <summary>
    /// Danh sách UserId nhận bài nếu TargetType = BY_IDS
    /// </summary>
    public List<int>? UserIds { get; set; }

    /// <summary>
    /// Sở thích công nghệ nếu TargetType = BY_INTEREST (Gaming, Văn phòng/Học tập, Âm thanh/Studio, SmartHome)
    /// </summary>
    /// <example>Âm thanh/Studio</example>
    public string? TechInterest { get; set; }
}

/// <summary>
/// DTO Thống kê kết quả khảo sát phục vụ vẽ biểu đồ tròn/cột trên Flutter Desktop
/// </summary>
public class SurveyStatisticsDto
{
    /// <example>1</example>
    public int SurveyId { get; set; }

    /// <example>Thăm dò nhu cầu Tai nghe chống ồn Sony WH-1000XM6</example>
    public string Title { get; set; } = string.Empty;

    /// <example>100</example>
    public int TotalAssigned { get; set; }

    /// <example>45</example>
    public int TotalCompleted { get; set; }

    /// <example>45.0</example>
    public double ResponseRatePercent =>
        TotalAssigned > 0 ? Math.Round((double)TotalCompleted / TotalAssigned * 100, 1) : 0.0;

    public List<QuestionStatisticsDto> Questions { get; set; } = new();
}

public class QuestionStatisticsDto
{
    /// <example>1</example>
    public int QuestionId { get; set; }

    /// <example>Mức giá bạn sẵn sàng chi trả cho Sony WH-1000XM6 là bao nhiêu?</example>
    public string QuestionText { get; set; } = string.Empty;

    /// <example>SINGLE_CHOICE</example>
    public SurveyQuestionType QuestionType { get; set; }

    /// <example>45</example>
    public int TotalAnswers { get; set; }

    /// <summary>
    /// Thống kê tỷ lệ các đáp án (Dành cho câu SINGLE_CHOICE để vẽ PieChart / BarChart)
    /// </summary>
    public List<OptionStatisticsDto> OptionStats { get; set; } = new();

    /// <summary>
    /// Danh sách các câu trả lời tự luận (Dành cho câu TEXT)
    /// </summary>
    public List<TextAnswerDto> TextAnswers { get; set; } = new();
}

public class OptionStatisticsDto
{
    /// <example>1</example>
    public int OptionId { get; set; }

    /// <example>Từ 8 đến 10 triệu đồng</example>
    public string OptionText { get; set; } = string.Empty;

    /// <example>25</example>
    public int VoteCount { get; set; }

    /// <summary>
    /// Tỷ lệ phần trăm bình chọn (0 - 100%)
    /// </summary>
    /// <example>55.6</example>
    public double Percentage { get; set; }
}

public class TextAnswerDto
{
    /// <example>Hy vọng tai nghe có thêm tính năng kết nối đa điểm mượt mà hơn và đệm tai thoáng khí hơn.</example>
    public string Text { get; set; } = string.Empty;

    /// <example>Nguyễn Văn A</example>
    public string CustomerName { get; set; } = string.Empty;

    /// <example>2026-10-02T14:30:00Z</example>
    public DateTime SubmittedAt { get; set; }
}
