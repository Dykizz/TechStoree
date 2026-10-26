using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Surveys;
using WebBanHang.Api.DTOs.Vouchers;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class SurveyService(AppDbContext context, IVoucherService voucherService) : ISurveyService
{
    // =========================================================================
    // PHẦN QUẢN TRỊ VIÊN & CRM MANAGER
    // =========================================================================

    public async Task<PagedResult<SurveyAdminListDto>> GetAllSurveysAsync(SurveyQueryFilter filter, PaginationParams pagination)
    {
        var query = context.Surveys
            .Include(s => s.RewardVoucher)
            .Include(s => s.Assignments)
            .AsNoTracking()
            .AsQueryable();

        // 1. Áp dụng các bộ lọc tìm kiếm
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var searchLower = filter.Search.Trim().ToLower();
            query = query.Where(s => s.Title.ToLower().Contains(searchLower) ||
                                     (s.Description != null && s.Description.ToLower().Contains(searchLower)));
        }

        if (filter.IsActive.HasValue)
        {
            query = query.Where(s => s.IsActive == filter.IsActive.Value);
        }

        if (filter.HasReward.HasValue)
        {
            query = filter.HasReward.Value
                ? query.Where(s => s.RewardVoucherId != null)
                : query.Where(s => s.RewardVoucherId == null);
        }

        // Sắp xếp và phân trang thông qua extension ToPagedResultAsync kết hợp ToAdminListDto
        return await query
            .OrderByDescending(s => s.CreatedAt)
            .ToPagedResultAsync(pagination, s => s.ToAdminListDto());
    }

    public async Task<SurveyAdminDetailDto?> GetSurveyByIdAsync(int surveyId)
    {
        var s = await context.Surveys
            .AsSplitQuery()
            .Include(s => s.RewardVoucher)
            .Include(s => s.Questions.OrderBy(q => q.OrderNum))
                .ThenInclude(q => q.Options.OrderBy(o => o.OrderNum))
            .Include(s => s.Assignments)
                .ThenInclude(a => a.Answers)
            .Include(s => s.Assignments)
                .ThenInclude(a => a.User)
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.SurveyId == surveyId);

        return s?.ToAdminDetailDto();
    }

    public async Task<SurveyAdminDetailDto> CreateSurveyAsync(CreateSurveyRequestDto dto)
    {
        // Kiểm tra Voucher quà tặng nếu có truyền lên
        if (dto.RewardVoucherId.HasValue)
        {
            var voucherExists = await context.Vouchers.AnyAsync(v => v.VoucherId == dto.RewardVoucherId.Value);
            if (!voucherExists)
            {
                throw new BadRequestException($"Mã Voucher phần thưởng ID = {dto.RewardVoucherId.Value} không tồn tại.");
            }
        }

        var survey = new Survey
        {
            Title = dto.Title.Trim(),
            Description = dto.Description?.Trim(),
            RewardVoucherId = dto.RewardVoucherId,
            IsActive = dto.IsActive,
            StartAt = dto.StartAt,
            ExpiredAt = dto.ExpiredAt,
            CreatedAt = DateTime.UtcNow
        };

        int questionIndex = 1;
        foreach (var qDto in dto.Questions)
        {
            var question = new SurveyQuestion
            {
                QuestionText = qDto.QuestionText.Trim(),
                QuestionType = qDto.QuestionType,
                IsRequired = qDto.IsRequired,
                OrderNum = qDto.OrderNum > 0 ? qDto.OrderNum : questionIndex++
            };

            if (qDto.QuestionType == SurveyQuestionType.SINGLE_CHOICE || qDto.QuestionType == SurveyQuestionType.MULTI_CHOICE)
            {
                if (qDto.Options == null || qDto.Options.Count < 2)
                {
                    throw new BadRequestException($"Câu hỏi trắc nghiệm '{qDto.QuestionText}' phải có ít nhất 2 đáp án lựa chọn.");
                }

                int optionIndex = 1;
                foreach (var optDto in qDto.Options)
                {
                    question.Options.Add(new SurveyOption
                    {
                        OptionText = optDto.OptionText.Trim(),
                        OrderNum = optDto.OrderNum > 0 ? optDto.OrderNum : optionIndex++
                    });
                }
            }

            survey.Questions.Add(question);
        }

        context.Surveys.Add(survey);
        await context.SaveChangesAsync();

        return (await GetSurveyByIdAsync(survey.SurveyId))!;
    }

    public async Task<SurveyAdminDetailDto> UpdateSurveyAsync(int surveyId, UpdateSurveyRequestDto dto)
    {
        var survey = await context.Surveys
            .Include(s => s.Questions)
                .ThenInclude(q => q.Options)
            .FirstOrDefaultAsync(s => s.SurveyId == surveyId)
            ?? throw new NotFoundException($"Không tìm thấy bài khảo sát với ID = {surveyId}.");

        // Kiểm tra Voucher quà tặng nếu có truyền lên
        if (dto.RewardVoucherId.HasValue)
        {
            var voucherExists = await context.Vouchers.AnyAsync(v => v.VoucherId == dto.RewardVoucherId.Value);
            if (!voucherExists)
            {
                throw new BadRequestException($"Mã Voucher phần thưởng ID = {dto.RewardVoucherId.Value} không tồn tại.");
            }
        }

        // Kiểm tra xem đã có khách hàng nào nộp bài chưa
        bool hasResponses = await context.SurveyAssignments
            .AnyAsync(a => a.SurveyId == surveyId && a.CompletedAt != null);

        // QUY TẮC TOÀN VẸN: Nếu đã có người nộp bài -> KHÓA CẤU TRÚC CÂU HỎI
        if (hasResponses)
        {
            // Kiểm tra: Chỉ chặn khi Admin thực sự cố tình thay đổi/thêm/bớt câu hỏi hoặc đáp án
            if (dto.Questions != null && IsQuestionsStructureChanged(survey.Questions, dto.Questions))
            {
                throw new BadRequestException(
                    "Bài khảo sát này đã có khách hàng nộp phản hồi. Hệ thống đã khóa cấu trúc câu hỏi " +
                    "để bảo toàn tính toàn vẹn dữ liệu thống kê. Nếu cần thay đổi câu hỏi, vui lòng đóng khảo sát này " +
                    "và sử dụng chức năng 'Nhân bản khảo sát' để tạo phiên bản mới.");
            }

            // Chỉ cho phép cập nhật thông tin chung (bỏ qua questions nếu Frontend gửi kèm câu hỏi cũ)
            survey.Title = dto.Title.Trim();
            survey.Description = dto.Description?.Trim();
            survey.RewardVoucherId = dto.RewardVoucherId;
            survey.IsActive = dto.IsActive;
            survey.StartAt = dto.StartAt;
            survey.ExpiredAt = dto.ExpiredAt;
        }
        else
        {
            // Chưa có ai làm -> Cho phép cập nhật cả thông tin lẫn danh sách câu hỏi
            survey.Title = dto.Title.Trim();
            survey.Description = dto.Description?.Trim();
            survey.RewardVoucherId = dto.RewardVoucherId;
            survey.IsActive = dto.IsActive;
            survey.StartAt = dto.StartAt;
            survey.ExpiredAt = dto.ExpiredAt;

            if (dto.Questions != null)
            {
                // Xóa các câu hỏi và đáp án cũ
                context.SurveyQuestions.RemoveRange(survey.Questions);
                survey.Questions.Clear();

                int questionIndex = 1;
                foreach (var qDto in dto.Questions)
                {
                    var question = new SurveyQuestion
                    {
                        QuestionText = qDto.QuestionText.Trim(),
                        QuestionType = qDto.QuestionType,
                        IsRequired = qDto.IsRequired,
                        OrderNum = qDto.OrderNum > 0 ? qDto.OrderNum : questionIndex++
                    };

                    if (qDto.QuestionType == SurveyQuestionType.SINGLE_CHOICE || qDto.QuestionType == SurveyQuestionType.MULTI_CHOICE)
                    {
                        if (qDto.Options == null || qDto.Options.Count < 2)
                        {
                            throw new BadRequestException($"Câu hỏi trắc nghiệm '{qDto.QuestionText}' phải có ít nhất 2 đáp án lựa chọn.");
                        }

                        int optionIndex = 1;
                        foreach (var optDto in qDto.Options)
                        {
                            question.Options.Add(new SurveyOption
                            {
                                OptionText = optDto.OptionText.Trim(),
                                OrderNum = optDto.OrderNum > 0 ? optDto.OrderNum : optionIndex++
                            });
                        }
                    }

                    survey.Questions.Add(question);
                }
            }
        }

        await context.SaveChangesAsync();
        return (await GetSurveyByIdAsync(survey.SurveyId))!;
    }

    public async Task<bool> ToggleSurveyActiveAsync(int surveyId)
    {
        var survey = await context.Surveys.FindAsync(surveyId)
            ?? throw new NotFoundException($"Không tìm thấy bài khảo sát với ID = {surveyId}.");

        survey.IsActive = !survey.IsActive;
        await context.SaveChangesAsync();
        return survey.IsActive;
    }

    public async Task<bool> DeleteSurveyAsync(int surveyId)
    {
        var survey = await context.Surveys.FindAsync(surveyId)
            ?? throw new NotFoundException($"Không tìm thấy bài khảo sát với ID = {surveyId}.");

        bool hasResponses = await context.SurveyAssignments
            .AnyAsync(a => a.SurveyId == surveyId && a.CompletedAt != null);

        if (hasResponses)
        {
            throw new BadRequestException(
                "Không thể xóa bài khảo sát đã có dữ liệu phản hồi từ khách hàng. " +
                "Bạn có thể chọn Tắt kích hoạt để ngừng nhận thêm câu trả lời.");
        }

        context.Surveys.Remove(survey);
        await context.SaveChangesAsync();
        return true;
    }

    public async Task<int> AssignSurveyAsync(int surveyId, AssignSurveyRequestDto dto)
    {
        var survey = await context.Surveys.FindAsync(surveyId)
            ?? throw new NotFoundException($"Không tìm thấy bài khảo sát với ID = {surveyId}.");

        if (!survey.IsActive)
        {
            throw new BadRequestException("Bài khảo sát đang bị đóng. Vui lòng kích hoạt khảo sát trước khi phát bài.");
        }

        if (survey.ExpiredAt.HasValue && survey.ExpiredAt.Value < DateTime.UtcNow)
        {
            throw new BadRequestException("Bài khảo sát đã hết hạn nhận bài. Vui lòng cập nhật thời hạn trước khi phát.");
        }

        // 1. Lọc danh sách khách hàng mục tiêu đang hoạt động (Chỉ khách hàng có vai trò USER, loại trừ nhân viên & tài khoản bị khóa)
        var allActiveCustomersQuery = context.Users
            .Where(u => !u.IsLocked && u.UserRoles.All(ur => ur.RoleId == UserRoleTypeExtensions.User));

        List<int> targetUserIds;

        switch (dto.TargetType)
        {
            case SurveyTargetType.BY_IDS:
                if (dto.UserIds == null || dto.UserIds.Count == 0)
                {
                    throw new BadRequestException("Vui lòng cung cấp danh sách ID khách hàng nhận bài.");
                }
                targetUserIds = await allActiveCustomersQuery
                    .Where(u => dto.UserIds.Contains(u.UserId))
                    .Select(u => u.UserId)
                    .ToListAsync();
                break;

            case SurveyTargetType.BY_INTEREST:
                if (string.IsNullOrWhiteSpace(dto.TechInterest))
                {
                    throw new BadRequestException("Vui lòng chọn sở thích công nghệ mục tiêu.");
                }
                var interestLower = dto.TechInterest.Trim().ToLower();
                var matchedKeywords = new List<string> { interestLower };
                if (interestLower.Contains("gaming")) matchedKeywords.Add("gaming");
                if (interestLower.Contains("văn phòng") || interestLower.Contains("học tập") || interestLower.Contains("office")) { matchedKeywords.Add("office_study"); matchedKeywords.Add("văn phòng"); }
                if (interestLower.Contains("âm thanh") || interestLower.Contains("studio") || interestLower.Contains("audio")) { matchedKeywords.Add("audio_studio"); matchedKeywords.Add("âm thanh"); }
                if (interestLower.Contains("lập trình") || interestLower.Contains("ai") || interestLower.Contains("coding")) { matchedKeywords.Add("coding_ai"); matchedKeywords.Add("lập trình"); }
                if (interestLower.Contains("smartwatch") || interestLower.Contains("sức khỏe") || interestLower.Contains("health")) { matchedKeywords.Add("smartwatch_health"); matchedKeywords.Add("đồng hồ"); }
                if (interestLower.Contains("nhiếp ảnh") || interestLower.Contains("quay phim") || interestLower.Contains("photography")) { matchedKeywords.Add("photography_video"); matchedKeywords.Add("nhiếp ảnh"); }
                if (interestLower.Contains("smarthome") || interestLower.Contains("nhà thông minh") || interestLower.Contains("gia dụng")) { matchedKeywords.Add("smarthome"); matchedKeywords.Add("nhà thông minh"); }

                targetUserIds = await allActiveCustomersQuery
                    .Where(u => u.Customer != null && u.Customer.TechInterest != null &&
                        matchedKeywords.Any(k => u.Customer.TechInterest.ToLower().Contains(k)))
                    .Select(u => u.UserId)
                    .ToListAsync();
                break;

            case SurveyTargetType.ALL:
            default:
                targetUserIds = await allActiveCustomersQuery
                    .Select(u => u.UserId)
                    .ToListAsync();
                break;
        }

        if (targetUserIds.Count == 0)
        {
            throw new BadRequestException(dto.TargetType == SurveyTargetType.BY_INTEREST
                ? $"Không tìm thấy khách hàng nào có sở thích phù hợp với '{dto.TechInterest}'."
                : "Không tìm thấy khách hàng mục tiêu hợp lệ để phát bài.");
        }

        // 2. Lấy danh sách các phân công hiện có cho bài khảo sát này
        var existingAssignments = await context.SurveyAssignments
            .Where(a => a.SurveyId == surveyId)
            .ToListAsync();

        var existingUserIds = existingAssignments.Select(a => a.UserId).ToHashSet();

        // 3. Nếu là phát CHỈ ĐỊNH (BY_IDS hoặc BY_INTEREST):
        // Những khách hàng KHÔNG nằm trong targetUserIds mà CHƯA LÀM BÀI (CompletedAt == null) sẽ được hủy phân công (Unassign)
        // để đảm bảo bài khảo sát chỉ gửi đúng cho đối tượng được chỉ định.
        if (dto.TargetType == SurveyTargetType.BY_IDS || dto.TargetType == SurveyTargetType.BY_INTEREST)
        {
            var assignmentsToRemove = existingAssignments
                .Where(a => !targetUserIds.Contains(a.UserId) && a.CompletedAt == null)
                .ToList();

            if (assignmentsToRemove.Count > 0)
            {
                context.SurveyAssignments.RemoveRange(assignmentsToRemove);
            }
        }

        // 4. Thêm phân công mới cho những khách hàng trong targetUserIds chưa từng được gán
        var newUserIdsToAssign = targetUserIds
            .Where(userId => !existingUserIds.Contains(userId))
            .ToList();

        if (newUserIdsToAssign.Count > 0)
        {
            var newAssignments = newUserIdsToAssign.Select(userId => new SurveyAssignment
            {
                SurveyId = surveyId,
                UserId = userId,
                AssignedAt = DateTime.UtcNow,
                CompletedAt = null
            }).ToList();

            context.SurveyAssignments.AddRange(newAssignments);
        }

        await context.SaveChangesAsync();

        // 5. Trả về tổng số khách hàng hiện được chỉ định nhận bài khảo sát này
        return targetUserIds.Count;
    }

    public async Task<SurveyStatisticsDto> GetSurveyStatisticsAsync(int surveyId)
    {
        var survey = await context.Surveys
            .AsSplitQuery()
            .Include(s => s.Questions.OrderBy(q => q.OrderNum))
                .ThenInclude(q => q.Options.OrderBy(o => o.OrderNum))
            .Include(s => s.Assignments)
                .ThenInclude(a => a.Answers)
            .Include(s => s.Assignments)
                .ThenInclude(a => a.User)
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.SurveyId == surveyId)
            ?? throw new NotFoundException($"Không tìm thấy bài khảo sát với ID = {surveyId}.");

        var completedAssignments = survey.Assignments.Where(a => a.CompletedAt != null).ToList();
        var allAnswers = completedAssignments.SelectMany(a => a.Answers).ToList();

        var stats = new SurveyStatisticsDto
        {
            SurveyId = survey.SurveyId,
            Title = survey.Title,
            TotalAssigned = survey.Assignments.Count,
            TotalCompleted = completedAssignments.Count,
            Questions = new List<QuestionStatisticsDto>()
        };

        foreach (var q in survey.Questions)
        {
            var qAnswers = allAnswers.Where(ans => ans.QuestionId == q.QuestionId).ToList();

            var respondentCount = qAnswers.Select(ans => ans.AssignmentId).Distinct().Count();

            var qStat = new QuestionStatisticsDto
            {
                QuestionId = q.QuestionId,
                QuestionText = q.QuestionText,
                QuestionType = q.QuestionType,
                TotalAnswers = q.QuestionType == SurveyQuestionType.MULTI_CHOICE ? respondentCount : qAnswers.Count
            };

            if (q.QuestionType == SurveyQuestionType.SINGLE_CHOICE || q.QuestionType == SurveyQuestionType.MULTI_CHOICE)
            {
                int baseCount = q.QuestionType == SurveyQuestionType.MULTI_CHOICE ? respondentCount : qAnswers.Count;

                foreach (var opt in q.Options)
                {
                    int voteCount = qAnswers.Count(ans => ans.SelectedOptionId == opt.OptionId);
                    double percentage = baseCount > 0 ? Math.Round((double)voteCount / baseCount * 100, 1) : 0.0;

                    qStat.OptionStats.Add(new OptionStatisticsDto
                    {
                        OptionId = opt.OptionId,
                        OptionText = opt.OptionText,
                        VoteCount = voteCount,
                        Percentage = percentage
                    });
                }
            }
            else // TEXT
            {
                var textAnswers = completedAssignments
                    .SelectMany(a => a.Answers.Where(ans => ans.QuestionId == q.QuestionId && !string.IsNullOrWhiteSpace(ans.TextAnswer))
                        .Select(ans => new TextAnswerDto
                        {
                            Text = ans.TextAnswer!,
                            CustomerName = a.User != null ? a.User.FullName : "Khách hàng ẩn danh",
                            SubmittedAt = a.CompletedAt ?? a.AssignedAt
                        }))
                    .OrderByDescending(t => t.SubmittedAt)
                    .ToList();

                qStat.TextAnswers = textAnswers;
            }

            stats.Questions.Add(qStat);
        }

        return stats;
    }

    public async Task<SurveyAdminDetailDto> CloneSurveyAsync(int surveyId)
    {
        var original = await context.Surveys
            .Include(s => s.Questions)
                .ThenInclude(q => q.Options)
            .FirstOrDefaultAsync(s => s.SurveyId == surveyId)
            ?? throw new NotFoundException($"Không tìm thấy bài khảo sát với ID = {surveyId}.");

        var clone = new Survey
        {
            Title = $"{original.Title} (Phiên bản mới)",
            Description = original.Description,
            RewardVoucherId = original.RewardVoucherId,
            IsActive = false, // Mặc định ở trạng thái nháp để Quản trị viên tùy chỉnh
            CreatedAt = DateTime.UtcNow
        };

        foreach (var q in original.Questions.OrderBy(q => q.OrderNum))
        {
            var newQ = new SurveyQuestion
            {
                QuestionText = q.QuestionText,
                QuestionType = q.QuestionType,
                IsRequired = q.IsRequired,
                OrderNum = q.OrderNum
            };

            foreach (var opt in q.Options.OrderBy(o => o.OrderNum))
            {
                newQ.Options.Add(new SurveyOption
                {
                    OptionText = opt.OptionText,
                    OrderNum = opt.OrderNum
                });
            }

            clone.Questions.Add(newQ);
        }

        context.Surveys.Add(clone);
        await context.SaveChangesAsync();

        return (await GetSurveyByIdAsync(clone.SurveyId))!;
    }

    // =========================================================================
    // PHẦN KHÁCH HÀNG (CUSTOMER PORTAL)
    // =========================================================================

    public async Task<IEnumerable<CustomerSurveyListDto>> GetCustomerSurveysAsync(int userId)
    {
        var assignments = await context.SurveyAssignments
            .Include(a => a.Survey)
                .ThenInclude(s => s.RewardVoucher)
            .Where(a => a.UserId == userId && a.Survey.IsActive)
            .OrderBy(a => a.CompletedAt.HasValue) // Bài chưa làm lên đầu
            .ThenByDescending(a => a.AssignedAt)
            .AsNoTracking()
            .ToListAsync();

        return assignments.Select(a => a.ToCustomerSurveyListDto());
    }

    public async Task<TakeSurveyDto> GetSurveyForTakingAsync(int surveyId, int userId)
    {
        var assignment = await context.SurveyAssignments
            .Include(a => a.Survey)
                .ThenInclude(s => s.RewardVoucher)
            .Include(a => a.Survey)
                .ThenInclude(s => s.Questions.OrderBy(q => q.OrderNum))
                    .ThenInclude(q => q.Options.OrderBy(o => o.OrderNum))
            .FirstOrDefaultAsync(a => a.SurveyId == surveyId && a.UserId == userId)
            ?? throw new ForbiddenException("Bạn chưa được cấp quyền tham gia bài khảo sát này.");

        if (!assignment.Survey.IsActive)
        {
            throw new BadRequestException("Bài khảo sát này hiện đã đóng nhận câu trả lời.");
        }

        if (assignment.Survey.ExpiredAt.HasValue && assignment.Survey.ExpiredAt.Value < DateTime.UtcNow)
        {
            throw new BadRequestException("Bài khảo sát này đã kết thúc thời gian nhận phản hồi.");
        }

        if (assignment.CompletedAt.HasValue)
        {
            throw new BadRequestException("Bạn đã hoàn thành bài khảo sát này trước đó.");
        }

        return assignment.Survey.ToTakeSurveyDto();
    }

    public async Task<SurveySubmitResponseDto> SubmitSurveyAsync(int surveyId, int userId, SubmitSurveyRequestDto dto)
    {
        var assignment = await context.SurveyAssignments
            .Include(a => a.Survey)
                .ThenInclude(s => s.RewardVoucher)
            .Include(a => a.Survey)
                .ThenInclude(s => s.Questions)
                    .ThenInclude(q => q.Options)
            .FirstOrDefaultAsync(a => a.SurveyId == surveyId && a.UserId == userId)
            ?? throw new ForbiddenException("Bạn không có quyền thực hiện bài khảo sát này.");

        if (!assignment.Survey.IsActive)
        {
            throw new BadRequestException("Bài khảo sát đã dừng nhận phản hồi.");
        }

        if (assignment.Survey.ExpiredAt.HasValue && assignment.Survey.ExpiredAt.Value < DateTime.UtcNow)
        {
            throw new BadRequestException("Bài khảo sát này đã kết thúc thời gian nhận phản hồi.");
        }

        if (assignment.CompletedAt.HasValue)
        {
            throw new BadRequestException("Bạn đã nộp bài khảo sát này rồi. Mỗi khách hàng chỉ được làm bài 1 lần.");
        }

        var survey = assignment.Survey;

        // Gom nhóm câu trả lời theo QuestionId
        var answersByQuestion = dto.Answers
            .GroupBy(a => a.QuestionId)
            .ToDictionary(g => g.Key, g => g.ToList());

        // 1. Kiểm tra validation các câu hỏi REQUIRED
        var requiredQuestions = survey.Questions.Where(q => q.IsRequired);
        foreach (var reqQ in requiredQuestions)
        {
            var isValid = answersByQuestion.TryGetValue(reqQ.QuestionId, out var qAnswers) && reqQ.QuestionType switch
            {
                SurveyQuestionType.TEXT => qAnswers.Any(a => !string.IsNullOrWhiteSpace(a.TextAnswer)),
                _ => qAnswers.Any(a => a.SelectedOptionId.HasValue || a.SelectedOptionIds?.Count > 0)
            };

            if (!isValid)
            {
                throw new BadRequestException($"Câu hỏi '{reqQ.QuestionText}' là bắt buộc. Vui lòng hoàn thành câu hỏi.");
            }
        }

        // 2. Lưu các câu trả lời vào survey_answers và kiểm tra đáp án hợp lệ
        foreach (var (questionId, qAnswers) in answersByQuestion)
        {
            var question = survey.Questions.FirstOrDefault(q => q.QuestionId == questionId);
            if (question == null) continue;

            if (question.QuestionType == SurveyQuestionType.SINGLE_CHOICE)
            {
                var firstAns = qAnswers.LastOrDefault();
                if (firstAns == null) continue;

                int? optionId = firstAns.SelectedOptionId ?? firstAns.SelectedOptionIds?.FirstOrDefault();
                if (optionId.HasValue)
                {
                    var validOption = question.Options.Any(o => o.OptionId == optionId.Value);
                    if (!validOption)
                    {
                        throw new BadRequestException($"Đáp án được chọn cho câu hỏi '{question.QuestionText}' không hợp lệ.");
                    }

                    context.SurveyAnswers.Add(new SurveyAnswer
                    {
                        AssignmentId = assignment.AssignmentId,
                        QuestionId = question.QuestionId,
                        SelectedOptionId = optionId.Value,
                        TextAnswer = null
                    });
                }
            }
            else if (question.QuestionType == SurveyQuestionType.MULTI_CHOICE)
            {
                var selectedOptionIds = new HashSet<int>();
                foreach (var ans in qAnswers)
                {
                    if (ans.SelectedOptionId.HasValue)
                    {
                        selectedOptionIds.Add(ans.SelectedOptionId.Value);
                    }
                    if (ans.SelectedOptionIds != null)
                    {
                        foreach (var optId in ans.SelectedOptionIds)
                        {
                            selectedOptionIds.Add(optId);
                        }
                    }
                }

                foreach (var optId in selectedOptionIds)
                {
                    var validOption = question.Options.Any(o => o.OptionId == optId);
                    if (!validOption)
                    {
                        throw new BadRequestException($"Đáp án được chọn cho câu hỏi '{question.QuestionText}' không hợp lệ.");
                    }

                    context.SurveyAnswers.Add(new SurveyAnswer
                    {
                        AssignmentId = assignment.AssignmentId,
                        QuestionId = question.QuestionId,
                        SelectedOptionId = optId,
                        TextAnswer = null
                    });
                }
            }
            else if (question.QuestionType == SurveyQuestionType.TEXT)
            {
                var textAns = qAnswers.LastOrDefault(a => !string.IsNullOrWhiteSpace(a.TextAnswer));
                if (textAns != null && !string.IsNullOrWhiteSpace(textAns.TextAnswer))
                {
                    context.SurveyAnswers.Add(new SurveyAnswer
                    {
                        AssignmentId = assignment.AssignmentId,
                        QuestionId = question.QuestionId,
                        SelectedOptionId = null,
                        TextAnswer = textAns.TextAnswer.Trim()
                    });
                }
            }
        }

        // 3. Đánh dấu hoàn thành
        assignment.CompletedAt = DateTime.UtcNow;
        await context.SaveChangesAsync();

        // 4. TỰ ĐỘNG THƯỞNG VOUCHER VÀO VÍ CÁ NHÂN (Ủy quyền cho VoucherService xử lý nghiệp vụ)
        SurveyRewardVoucherDto? rewardDto = null;
        if (survey.RewardVoucherId.HasValue)
        {
            var awardedVoucher = await voucherService.AwardVoucherAsync(
                survey.RewardVoucherId.Value, 
                userId, 
                VoucherAssignedType.SURVEY_REWARD);

            if (awardedVoucher != null)
            {
                rewardDto = awardedVoucher.ToRewardDto();
            }
        }

        string message = rewardDto != null
            ? $"Hoàn thành khảo sát thành công! Bạn nhận được Voucher '{rewardDto.Code}' trị giá {(rewardDto.DiscountType == DiscountType.PERCENTAGE ? $"{rewardDto.DiscountValue}%" : $"{rewardDto.DiscountValue:N0}đ")}, đã lưu vào ví của bạn."
            : "Hoàn thành bài khảo sát thành công. Cảm ơn ý kiến đóng góp quý báu của bạn!";

        return new SurveySubmitResponseDto
        {
            Success = true,
            Message = message,
            CompletedAt = assignment.CompletedAt.Value,
            RewardVoucher = rewardDto
        };
    }

    /// <summary>
    /// So sánh danh sách câu hỏi và đáp án gửi lên xem có thực sự thay đổi cấu trúc/nội dung so với bản ghi hiện tại không
    /// </summary>
    private static bool IsQuestionsStructureChanged(ICollection<SurveyQuestion> existingQuestions, List<CreateSurveyQuestionDto> newQuestions)
    {
        // 1. Khác số lượng câu hỏi -> Cấu trúc bị thay đổi
        if (existingQuestions.Count != newQuestions.Count)
        {
            return true;
        }

        var existingList = existingQuestions.OrderBy(q => q.OrderNum).ToList();
        var newList = newQuestions.OrderBy(q => q.OrderNum).ToList();

        for (int i = 0; i < existingList.Count; i++)
        {
            var oldQ = existingList[i];
            var newQ = newList[i];

            // 2. Khác nội dung câu hỏi hoặc khác loại câu hỏi
            if (!string.Equals(oldQ.QuestionText.Trim(), newQ.QuestionText.Trim(), StringComparison.OrdinalIgnoreCase) ||
                oldQ.QuestionType != newQ.QuestionType)
            {
                return true;
            }

            // 3. Nếu là câu hỏi trắc nghiệm -> So sánh các đáp án
            if (oldQ.QuestionType == SurveyQuestionType.SINGLE_CHOICE || oldQ.QuestionType == SurveyQuestionType.MULTI_CHOICE)
            {
                var oldOptions = oldQ.Options.OrderBy(o => o.OrderNum).ToList();
                var newOptions = (newQ.Options ?? new List<CreateSurveyOptionDto>()).OrderBy(o => o.OrderNum).ToList();

                if (oldOptions.Count != newOptions.Count)
                {
                    return true;
                }

                for (int j = 0; j < oldOptions.Count; j++)
                {
                    if (!string.Equals(oldOptions[j].OptionText.Trim(), newOptions[j].OptionText.Trim(), StringComparison.OrdinalIgnoreCase))
                    {
                        return true;
                    }
                }
            }
        }

        // Không có bất kỳ thay đổi nào về cấu trúc hoặc nội dung câu hỏi
        return false;
    }

    public async Task<bool> MarkSurveyNotifiedAsync(int surveyId, int userId)
    {
        var assignment = await context.SurveyAssignments
            .FirstOrDefaultAsync(a => a.SurveyId == surveyId && a.UserId == userId);

        if (assignment == null) return false;

        if (!assignment.IsNotified)
        {
            assignment.IsNotified = true;
            assignment.NotifiedAt = DateTime.UtcNow;
            await context.SaveChangesAsync();
        }

        return true;
    }

    public async Task<(byte[] Bytes, string FileName)> ExportSurveyCsvAsync(int surveyId)
    {
        var survey = await context.Surveys
            .AsSplitQuery()
            .Include(s => s.RewardVoucher)
            .Include(s => s.Questions.OrderBy(q => q.OrderNum))
                .ThenInclude(q => q.Options.OrderBy(o => o.OrderNum))
            .Include(s => s.Assignments)
                .ThenInclude(a => a.User)
            .Include(s => s.Assignments)
                .ThenInclude(a => a.Answers)
                    .ThenInclude(ans => ans.SelectedOption)
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.SurveyId == surveyId)
            ?? throw new NotFoundException($"Không tìm thấy bài khảo sát với ID = {surveyId}.");

        var sb = new System.Text.StringBuilder();

        // Helper escape CSV cell
        string Escape(string? s)
        {
            if (string.IsNullOrEmpty(s)) return "\"\"";
            return $"\"{s.Replace("\"", "\"\"")}\"";
        }

        // PHẦN 1: TỔNG QUAN CHIẾN DỊCH KHẢO SÁT
        sb.AppendLine("=== BÁO CÁO KẾT QUẢ KHẢO SÁT THỊ TRƯỜNG ===");
        sb.AppendLine($"Mã khảo sát,{survey.SurveyId}");
        sb.AppendLine($"Tiêu đề,{Escape(survey.Title)}");
        sb.AppendLine($"Mô tả,{Escape(survey.Description)}");
        sb.AppendLine($"Trạng thái,{(survey.IsActive ? "Đang mở" : "Đã tạm dừng")}");
        sb.AppendLine($"Hạn chót,{(survey.ExpiredAt.HasValue ? survey.ExpiredAt.Value.ToString("dd/MM/yyyy HH:mm:ss") : "Không thời hạn")}");
        sb.AppendLine($"Voucher quà tặng,{Escape(survey.RewardVoucher != null ? $"{survey.RewardVoucher.Code} - {survey.RewardVoucher.Title}" : "Không có")}");
        sb.AppendLine($"Ngày tạo,{survey.CreatedAt:dd/MM/yyyy HH:mm:ss}");

        var totalAssigned = survey.Assignments.Count;
        var completedAssignments = survey.Assignments.Where(a => a.CompletedAt != null).ToList();
        var totalCompleted = completedAssignments.Count;
        var responseRate = totalAssigned > 0 ? Math.Round((double)totalCompleted / totalAssigned * 100, 1) : 0;

        sb.AppendLine($"Tổng số lượng đã phát,{totalAssigned}");
        sb.AppendLine($"Tổng số lượng đã hoàn thành,{totalCompleted}");
        sb.AppendLine($"Tỷ lệ phản hồi,{responseRate}%");
        sb.AppendLine();

        // PHẦN 2: THỐNG KÊ PHÂN BỔ ĐÁP ÁN THEO CÂU HỎI
        sb.AppendLine("=== THỐNG KÊ TỶ LỆ THEO CÂU HỎI ===");
        sb.AppendLine("STT,Nội dung câu hỏi,Loại câu hỏi,Bắt buộc,Phương án / Phân loại,Số lượt chọn,Tỷ lệ (%)");

        var allAnswers = completedAssignments.SelectMany(a => a.Answers).ToList();
        int qIdx = 1;
        foreach (var q in survey.Questions)
        {
            var qAnswers = allAnswers.Where(ans => ans.QuestionId == q.QuestionId).ToList();
            var qRespondents = qAnswers.Select(ans => ans.AssignmentId).Distinct().Count();
            var qTypeStr = q.QuestionType switch
            {
                SurveyQuestionType.SINGLE_CHOICE => "Trắc nghiệm 1 đáp án",
                SurveyQuestionType.MULTI_CHOICE => "Trắc nghiệm nhiều đáp án",
                SurveyQuestionType.TEXT => "Tự luận",
                _ => q.QuestionType.ToString()
            };

            if (q.QuestionType == SurveyQuestionType.TEXT)
            {
                sb.AppendLine($"{qIdx},{Escape(q.QuestionText)},{Escape(qTypeStr)},{(q.IsRequired ? "Có" : "Không")},Ý kiến tự luận,{qAnswers.Count(a => !string.IsNullOrWhiteSpace(a.TextAnswer))},100%");
            }
            else
            {
                foreach (var opt in q.Options)
                {
                    var optVotes = qAnswers.Count(a => a.SelectedOptionId == opt.OptionId);
                    var percent = qRespondents > 0 ? Math.Round((double)optVotes / qRespondents * 100, 1) : 0;
                    sb.AppendLine($"{qIdx},{Escape(q.QuestionText)},{Escape(qTypeStr)},{(q.IsRequired ? "Có" : "Không")},{Escape(opt.OptionText)},{optVotes},{percent}%");
                }
            }
            qIdx++;
        }
        sb.AppendLine();

        // PHẦN 3: BẢNG DỮ LIỆU CHI TIẾT TỪNG PHẢN HỒI CỦA KHÁCH HÀNG
        sb.AppendLine("=== CHI TIẾT CÂU TRẢ LỜI CỦA TỪNG KHÁCH HÀNG ===");
        var headers = new List<string> { "Mã lượt nộp", "Mã KH", "Họ tên / Email", "Thời điểm nộp bài" };
        foreach (var q in survey.Questions)
        {
            headers.Add(Escape($"[C{q.OrderNum}] {q.QuestionText}"));
        }
        sb.AppendLine(string.Join(",", headers));

        foreach (var assign in completedAssignments.OrderByDescending(a => a.CompletedAt))
        {
            var userDisplay = assign.User != null ? (!string.IsNullOrWhiteSpace(assign.User.FullName) ? assign.User.FullName : assign.User.Email) : $"User #{assign.UserId}";
            var row = new List<string>
            {
                assign.AssignmentId.ToString(),
                assign.UserId.ToString(),
                Escape(userDisplay),
                assign.CompletedAt.HasValue ? assign.CompletedAt.Value.ToString("dd/MM/yyyy HH:mm:ss") : ""
            };

            var userAnswers = assign.Answers.ToList();
            foreach (var q in survey.Questions)
            {
                var answersForQ = userAnswers.Where(a => a.QuestionId == q.QuestionId).ToList();
                if (q.QuestionType == SurveyQuestionType.TEXT)
                {
                    var text = string.Join("; ", answersForQ.Select(a => a.TextAnswer).Where(t => !string.IsNullOrWhiteSpace(t)));
                    row.Add(Escape(text));
                }
                else
                {
                    var selectedTexts = answersForQ
                        .Select(a => a.SelectedOption?.OptionText)
                        .Where(t => !string.IsNullOrWhiteSpace(t));
                    row.Add(Escape(string.Join(" | ", selectedTexts)));
                }
            }
            sb.AppendLine(string.Join(",", row));
        }

        // Xuất file UTF-8 kèm BOM để Excel trên Windows hiển thị đúng tiếng Việt không bị lỗi font
        var preamble = System.Text.Encoding.UTF8.GetPreamble();
        var bodyBytes = System.Text.Encoding.UTF8.GetBytes(sb.ToString());
        var fileBytes = new byte[preamble.Length + bodyBytes.Length];
        Buffer.BlockCopy(preamble, 0, fileBytes, 0, preamble.Length);
        Buffer.BlockCopy(bodyBytes, 0, fileBytes, preamble.Length, bodyBytes.Length);

        var safeTitle = string.Concat(survey.Title.Split(System.IO.Path.GetInvalidFileNameChars())).Replace(" ", "_");
        if (safeTitle.Length > 30) safeTitle = safeTitle.Substring(0, 30);
        var fileName = $"KhaoSat_{survey.SurveyId}_{safeTitle}_{DateTime.UtcNow:yyyyMMdd}.csv";

        return (fileBytes, fileName);
    }
}
