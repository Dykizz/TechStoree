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

            if (qDto.QuestionType == SurveyQuestionType.SINGLE_CHOICE)
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
        }
        else
        {
            // Chưa có ai làm -> Cho phép cập nhật cả thông tin lẫn danh sách câu hỏi
            survey.Title = dto.Title.Trim();
            survey.Description = dto.Description?.Trim();
            survey.RewardVoucherId = dto.RewardVoucherId;
            survey.IsActive = dto.IsActive;

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

                    if (qDto.QuestionType == SurveyQuestionType.SINGLE_CHOICE)
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

        // 1. Lọc danh sách người dùng mục tiêu đang hoạt động
        var usersQuery = context.Users.Where(u => !u.IsLocked);

        switch (dto.TargetType)
        {
            case SurveyTargetType.BY_IDS:
                if (dto.UserIds == null || dto.UserIds.Count == 0)
                {
                    throw new BadRequestException("Vui lòng cung cấp danh sách ID khách hàng nhận bài.");
                }
                usersQuery = usersQuery.Where(u => dto.UserIds.Contains(u.UserId));
                break;

            case SurveyTargetType.BY_INTEREST:
                if (string.IsNullOrWhiteSpace(dto.TechInterest))
                {
                    throw new BadRequestException("Vui lòng chọn sở thích công nghệ mục tiêu.");
                }
                var interestLower = dto.TechInterest.Trim().ToLower();
                usersQuery = usersQuery.Where(u => u.TechInterest != null && u.TechInterest.ToLower().Contains(interestLower));
                break;

            case SurveyTargetType.ALL:
            default:
                // Giao cho toàn bộ khách hàng đang hoạt động
                break;
        }

        // 2. Loại trừ những khách hàng đã được phát bài này từ trước trực tiếp trên SQL (tối ưu hiệu năng, tránh kéo toàn bộ User về RAM)
        usersQuery = usersQuery.Where(u => !context.SurveyAssignments.Any(a => a.SurveyId == surveyId && a.UserId == u.UserId));

        var newUserIdsToAssign = await usersQuery.Select(u => u.UserId).ToListAsync();

        if (newUserIdsToAssign.Count == 0)
        {
            return 0;
        }

        // 3. Chèn bản ghi phát bài hàng loạt
        var newAssignments = newUserIdsToAssign.Select(userId => new SurveyAssignment
        {
            SurveyId = surveyId,
            UserId = userId,
            AssignedAt = DateTime.UtcNow,
            CompletedAt = null
        }).ToList();

        context.SurveyAssignments.AddRange(newAssignments);
        await context.SaveChangesAsync();

        return newAssignments.Count;
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

            var qStat = new QuestionStatisticsDto
            {
                QuestionId = q.QuestionId,
                QuestionText = q.QuestionText,
                QuestionType = q.QuestionType,
                TotalAnswers = qAnswers.Count
            };

            if (q.QuestionType == SurveyQuestionType.SINGLE_CHOICE)
            {
                foreach (var opt in q.Options)
                {
                    int voteCount = qAnswers.Count(ans => ans.SelectedOptionId == opt.OptionId);
                    double percentage = qAnswers.Count > 0 ? Math.Round((double)voteCount / qAnswers.Count * 100, 1) : 0.0;

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

        if (assignment.CompletedAt.HasValue)
        {
            throw new BadRequestException("Bạn đã nộp bài khảo sát này rồi. Mỗi khách hàng chỉ được làm bài 1 lần.");
        }

        var survey = assignment.Survey;

        // Loại bỏ câu trả lời trùng lặp QuestionId nếu client gửi lặp trong danh sách Answers (ngăn Primary Key Violation)
        var distinctAnswers = dto.Answers
            .GroupBy(a => a.QuestionId)
            .Select(g => g.Last())
            .ToList();

        // 1. Kiểm tra validation các câu hỏi REQUIRED
        var requiredQuestions = survey.Questions.Where(q => q.IsRequired).ToList();
        foreach (var reqQ in requiredQuestions)
        {
            var ans = distinctAnswers.FirstOrDefault(a => a.QuestionId == reqQ.QuestionId);
            if (ans == null ||
                (reqQ.QuestionType == SurveyQuestionType.SINGLE_CHOICE && !ans.SelectedOptionId.HasValue) ||
                (reqQ.QuestionType == SurveyQuestionType.TEXT && string.IsNullOrWhiteSpace(ans.TextAnswer)))
            {
                throw new BadRequestException($"Câu hỏi '{reqQ.QuestionText}' là bắt buộc. Vui lòng hoàn thành câu hỏi.");
            }
        }

        // 2. Lưu các câu trả lời vào survey_answers và kiểm tra SelectedOptionId hợp lệ
        foreach (var answerDto in distinctAnswers)
        {
            var question = survey.Questions.FirstOrDefault(q => q.QuestionId == answerDto.QuestionId);
            if (question == null) continue;

            if (question.QuestionType == SurveyQuestionType.SINGLE_CHOICE && answerDto.SelectedOptionId.HasValue)
            {
                // Kiểm tra đáp án được chọn có thuộc danh sách Options của câu hỏi này không
                var validOption = question.Options.Any(o => o.OptionId == answerDto.SelectedOptionId.Value);
                if (!validOption)
                {
                    throw new BadRequestException($"Đáp án được chọn cho câu hỏi '{question.QuestionText}' không hợp lệ.");
                }

                context.SurveyAnswers.Add(new SurveyAnswer
                {
                    AssignmentId = assignment.AssignmentId,
                    QuestionId = question.QuestionId,
                    SelectedOptionId = answerDto.SelectedOptionId,
                    TextAnswer = null
                });
            }
            else if (question.QuestionType == SurveyQuestionType.TEXT && !string.IsNullOrWhiteSpace(answerDto.TextAnswer))
            {
                context.SurveyAnswers.Add(new SurveyAnswer
                {
                    AssignmentId = assignment.AssignmentId,
                    QuestionId = question.QuestionId,
                    SelectedOptionId = null,
                    TextAnswer = answerDto.TextAnswer.Trim()
                });
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
            if (oldQ.QuestionType == SurveyQuestionType.SINGLE_CHOICE)
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
}
