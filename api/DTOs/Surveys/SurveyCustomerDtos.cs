using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.DTOs.Surveys;

/// <summary>
/// DTO hiển thị danh sách bài khảo sát trong mục 'Khảo sát của tôi' của khách hàng
/// </summary>
public class CustomerSurveyListDto
{
    /// <example>1</example>
    public int SurveyId { get; set; }

    /// <example>Thăm dò nhu cầu Tai nghe chống ồn Sony WH-1000XM6</example>
    public string Title { get; set; } = string.Empty;

    /// <example>Khảo sát ý kiến khách hàng để chuẩn bị phân phối sản phẩm mới.</example>
    public string? Description { get; set; }

    /// <summary>
    /// Thông tin phần thưởng (nếu có)
    /// </summary>
    /// <example>Voucher Giảm 50K Phụ kiện Âm thanh</example>
    public string? RewardVoucherTitle { get; set; }

    /// <example>50000</example>
    public decimal? RewardVoucherDiscount { get; set; }

    /// <example>FIXED_AMOUNT</example>
    public DiscountType? RewardVoucherDiscountType { get; set; }

    /// <summary>
    /// Trạng thái: true = Đã nộp, false = Chưa thực hiện
    /// </summary>
    /// <example>false</example>
    public bool IsCompleted { get; set; }

    /// <example>2026-10-01T08:00:00Z</example>
    public DateTime AssignedAt { get; set; }

    /// <example>null</example>
    public DateTime? CompletedAt { get; set; }
}

/// <summary>
/// DTO tải biểu mẫu câu hỏi để khách hàng làm bài khảo sát
/// </summary>
public class TakeSurveyDto
{
    /// <example>1</example>
    public int SurveyId { get; set; }

    /// <example>Thăm dò nhu cầu Tai nghe chống ồn Sony WH-1000XM6</example>
    public string Title { get; set; } = string.Empty;

    /// <example>Khảo sát ý kiến khách hàng để chuẩn bị phân phối sản phẩm mới.</example>
    public string? Description { get; set; }

    /// <example>Voucher Giảm 50K Phụ kiện Âm thanh</example>
    public string? RewardVoucherTitle { get; set; }

    public List<TakeQuestionDto> Questions { get; set; } = new();
}

public class TakeQuestionDto
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

    public List<TakeOptionDto> Options { get; set; } = new();
}

public class TakeOptionDto
{
    /// <example>1</example>
    public int OptionId { get; set; }

    /// <example>Từ 8 đến 10 triệu đồng</example>
    public string OptionText { get; set; } = string.Empty;

    /// <example>1</example>
    public int OrderNum { get; set; } = 1;
}

/// <summary>
/// Request nộp bài khảo sát từ khách hàng
/// </summary>
public class SubmitSurveyRequestDto
{
    [Required(ErrorMessage = "Danh sách câu trả lời không được để trống.")]
    public List<SubmitAnswerDto> Answers { get; set; } = new();
}

public class SubmitAnswerDto
{
    /// <summary>
    /// Mã ID câu hỏi cần trả lời
    /// </summary>
    /// <example>1</example>
    [Required(ErrorMessage = "Mã câu hỏi không được để trống.")]
    public int QuestionId { get; set; }

    /// <summary>
    /// ID đáp án trắc nghiệm được chọn (nếu câu hỏi là SINGLE_CHOICE)
    /// </summary>
    /// <example>2</example>
    public int? SelectedOptionId { get; set; }

    /// <summary>
    /// Nội dung trả lời tự luận (nếu câu hỏi là TEXT)
    /// </summary>
    /// <example>Tôi mong muốn tai nghe có thêm màu bạc Titan và chống nước chuẩn IPX4.</example>
    public string? TextAnswer { get; set; }
}

/// <summary>
/// Phản hồi sau khi khách hàng nộp bài thành công (kèm voucher quà tặng vào ví nếu có)
/// </summary>
public class SurveySubmitResponseDto
{
    /// <example>true</example>
    public bool Success { get; set; } = true;

    /// <example>Hoàn thành khảo sát thành công! Bạn nhận được Voucher 'SONY50K' trị giá 50,000đ, đã lưu vào ví của bạn.</example>
    public string Message { get; set; } = "Nộp bài khảo sát thành công.";

    /// <example>2026-10-03T10:30:00Z</example>
    public DateTime CompletedAt { get; set; }

    /// <summary>
    /// Thông tin voucher quà tặng đã được cộng trực tiếp vào ví user_vouchers
    /// </summary>
    public SurveyRewardVoucherDto? RewardVoucher { get; set; }
}

public class SurveyRewardVoucherDto
{
    /// <example>1</example>
    public int VoucherId { get; set; }

    /// <example>SONY50K</example>
    public string Code { get; set; } = string.Empty;

    /// <example>Voucher Giảm 50K Phụ kiện Âm thanh</example>
    public string Title { get; set; } = string.Empty;

    /// <example>FIXED_AMOUNT</example>
    public DiscountType DiscountType { get; set; }

    /// <example>50000</example>
    public decimal DiscountValue { get; set; }

    /// <example>500000</example>
    public decimal MinOrderValue { get; set; }

    /// <example>2026-12-31T23:59:59Z</example>
    public DateTime EndDate { get; set; }
}
