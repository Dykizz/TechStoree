using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Surveys;

namespace WebBanHang.Api.Services.Interfaces;

public interface ISurveyService
{
    // ==========================================
    // Quản trị viên & CRM Manager
    // ==========================================
    Task<PagedResult<SurveyAdminListDto>> GetAllSurveysAsync(SurveyQueryFilter filter, PaginationParams pagination);
    Task<SurveyAdminDetailDto?> GetSurveyByIdAsync(int surveyId);
    Task<SurveyAdminDetailDto> CreateSurveyAsync(CreateSurveyRequestDto dto);
    Task<SurveyAdminDetailDto> UpdateSurveyAsync(int surveyId, UpdateSurveyRequestDto dto);
    Task<bool> ToggleSurveyActiveAsync(int surveyId);
    Task<bool> DeleteSurveyAsync(int surveyId);
    Task<int> AssignSurveyAsync(int surveyId, AssignSurveyRequestDto dto);
    Task<SurveyStatisticsDto> GetSurveyStatisticsAsync(int surveyId);
    Task<SurveyAdminDetailDto> CloneSurveyAsync(int surveyId);

    // ==========================================
    // Khách hàng (Customer)
    // ==========================================
    Task<IEnumerable<CustomerSurveyListDto>> GetCustomerSurveysAsync(int userId);
    Task<TakeSurveyDto> GetSurveyForTakingAsync(int surveyId, int userId);
    Task<SurveySubmitResponseDto> SubmitSurveyAsync(int surveyId, int userId, SubmitSurveyRequestDto dto);
}
