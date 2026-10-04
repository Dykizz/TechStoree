using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Surveys;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Khảo sát thị trường và Đánh giá mức độ hài lòng khách hàng (CRM Survey Module)
/// </summary>
[Route("api/surveys")]
[Tags("Surveys")]
public class SurveysController(ISurveyService surveyService) : BaseApiController
{
    // =========================================================================
    // QUẢN TRỊ VIÊN & CRM MANAGER
    // =========================================================================

    /// <summary>
    /// [Admin] Lấy danh sách khảo sát (kèm chỉ số số lượt giao, hoàn thành, tỷ lệ phản hồi %)
    /// </summary>
    /// <param name="filter">Bộ lọc khảo sát theo từ khóa, trạng thái mở/đóng, có voucher thưởng</param>
    /// <param name="pagination">Tham số phân trang (trang hiện tại, số lượng bản ghi mỗi trang)</param>
    [HttpGet("admin")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<SurveyAdminListDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllSurveys([FromQuery] SurveyQueryFilter filter, [FromQuery] PaginationParams pagination)
    {
        var result = await surveyService.GetAllSurveysAsync(filter, pagination);
        return Success(result, "Lấy danh sách bài khảo sát thành công.");
    }

    /// <summary>
    /// [Admin] Lấy chi tiết thông tin bài khảo sát kèm danh sách câu hỏi và đáp án
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát</param>
    [HttpGet("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<SurveyAdminDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetSurveyById([FromRoute] int id)
    {
        var result = await surveyService.GetSurveyByIdAsync(id)
            ?? throw new NotFoundException($"Không tìm thấy bài khảo sát với ID = {id}.");

        return Success(result, "Lấy chi tiết bài khảo sát thành công.");
    }

    /// <summary>
    /// [Admin] Khởi tạo bài khảo sát mới kèm danh sách câu hỏi động và voucher thưởng (tùy chọn)
    /// </summary>
    /// <param name="dto">Dữ liệu tạo mới bài khảo sát kèm danh sách câu hỏi và đáp án</param>
    [HttpPost]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<SurveyAdminDetailDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateSurvey([FromBody] CreateSurveyRequestDto dto)
    {
        var result = await surveyService.CreateSurveyAsync(dto);
        return CreatedSuccess(result, "Khởi tạo bài khảo sát thành công.");
    }

    /// <summary>
    /// [Admin] Cập nhật bài khảo sát (Dùng PATCH. Cho phép cập nhật thông tin chung hoặc câu hỏi khi chưa có phản hồi)
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát cần chỉnh sửa</param>
    /// <param name="dto">Dữ liệu cập nhật thông tin bài khảo sát</param>
    [HttpPatch("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<SurveyAdminDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateSurvey([FromRoute] int id, [FromBody] UpdateSurveyRequestDto dto)
    {
        var result = await surveyService.UpdateSurveyAsync(id, dto);
        return Success(result, "Cập nhật bài khảo sát thành công.");
    }

    /// <summary>
    /// [Admin] Bật / Tắt trạng thái mở nhận phản hồi của bài khảo sát
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát</param>
    [HttpPatch("{id:int}/toggle-active")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ToggleActive([FromRoute] int id)
    {
        var isActive = await surveyService.ToggleSurveyActiveAsync(id);
        return Success(isActive, isActive ? "Đã mở nhận phản hồi khảo sát." : "Đã tạm dừng nhận phản hồi khảo sát.");
    }

    /// <summary>
    /// [Admin] Xóa bài khảo sát (Chỉ cho phép xóa khi chưa có dữ liệu phản hồi)
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát cần xóa</param>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> DeleteSurvey([FromRoute] int id)
    {
        await surveyService.DeleteSurveyAsync(id);
        return Success("Xóa bài khảo sát thành công.");
    }

    /// <summary>
    /// [Admin] Phát bài khảo sát tới nhóm khách hàng mục tiêu (Tất cả, theo danh sách ID, hoặc theo sở thích)
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát cần phát</param>
    /// <param name="dto">Tiêu chí chỉ định nhóm khách hàng nhận bài</param>
    [HttpPost("{id:int}/assign")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<int>), StatusCodes.Status200OK)]
    public async Task<IActionResult> AssignSurvey([FromRoute] int id, [FromBody] AssignSurveyRequestDto dto)
    {
        var count = await surveyService.AssignSurveyAsync(id, dto);
        return Success(count, $"Đã phát bài khảo sát thành công tới {count} khách hàng.");
    }

    /// <summary>
    /// [Admin] Xem báo cáo thống kê kết quả khảo sát (Tỷ lệ %, biểu đồ tròn/cột fl_chart và danh sách góp ý text)
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát cần xem thống kê</param>
    [HttpGet("{id:int}/statistics")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<SurveyStatisticsDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSurveyStatistics([FromRoute] int id)
    {
        var stats = await surveyService.GetSurveyStatisticsAsync(id);
        return Success(stats, "Lấy dữ liệu thống kê khảo sát thành công.");
    }

    /// <summary>
    /// [Admin] Nhân bản bài khảo sát sang một phiên bản mới (Clone Survey)
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát gốc cần nhân bản</param>
    [HttpPost("{id:int}/clone")]
    [Authorize(Roles = "ADMIN")]
    [ProducesResponseType(typeof(ApiResponse<SurveyAdminDetailDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> CloneSurvey([FromRoute] int id)
    {
        var cloned = await surveyService.CloneSurveyAsync(id);
        return CreatedSuccess(cloned, "Nhân bản bài khảo sát thành công.");
    }

    // =========================================================================
    // KHÁCH HÀNG (CUSTOMER PORTAL)
    // =========================================================================

    /// <summary>
    /// [Khách hàng] Lấy danh sách các bài khảo sát được giao cho tài khoản hiện tại (Mục 'Khảo sát của tôi')
    /// </summary>
    [HttpGet("my-surveys")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<CustomerSurveyListDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMySurveys()
    {
        var result = await surveyService.GetCustomerSurveysAsync(CurrentUserId);
        return Success(result, "Lấy danh sách bài khảo sát của bạn thành công.");
    }

    /// <summary>
    /// [Khách hàng] Lấy biểu mẫu câu hỏi để làm bài khảo sát
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát cần làm</param>
    [HttpGet("{id:int}/take")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<TakeSurveyDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetSurveyForTaking([FromRoute] int id)
    {
        var result = await surveyService.GetSurveyForTakingAsync(id, CurrentUserId);
        return Success(result, "Tải biểu mẫu khảo sát thành công.");
    }

    /// <summary>
    /// [Khách hàng] Nộp bài khảo sát (Kiểm tra câu bắt buộc, tự động thưởng voucher vào ví cá nhân nếu có)
    /// </summary>
    /// <param name="id">Mã ID bài khảo sát</param>
    /// <param name="dto">Dữ liệu các câu trả lời khách hàng nộp</param>
    [HttpPost("{id:int}/submit")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<SurveySubmitResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SubmitSurvey([FromRoute] int id, [FromBody] SubmitSurveyRequestDto dto)
    {
        var result = await surveyService.SubmitSurveyAsync(id, CurrentUserId, dto);
        return Success(result, result.Message);
    }
}
