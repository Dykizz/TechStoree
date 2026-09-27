using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Vouchers;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class VoucherService(AppDbContext dbContext) : IVoucherService
{
    public async Task<PagedResult<VoucherBaseDto>> GetAllVouchersAsync(VoucherQueryFilter? filter = null)
    {
        var now = DateTime.UtcNow;
        var query = dbContext.Vouchers.AsNoTracking();

        var pagination = filter ?? new VoucherQueryFilter();

        if (filter != null)
        {
            if (filter.IsActive.HasValue)
            {
                query = query.Where(v => v.IsActive == filter.IsActive.Value);
            }

            if (filter.IsPublic.HasValue)
            {
                query = query.Where(v => v.IsPublic == filter.IsPublic.Value);
            }

            if (filter.Status.HasValue)
            {
                query = filter.Status.Value switch
                {
                    VoucherCampaignStatus.UPCOMING => query.Where(v => v.StartDate > now),
                    VoucherCampaignStatus.ACTIVE => query.Where(v => v.StartDate <= now && v.EndDate >= now),
                    VoucherCampaignStatus.EXPIRED => query.Where(v => v.EndDate < now),
                    _ => query
                };
            }

            if (filter.FromDate.HasValue)
            {
                var fromUtc = DateTime.SpecifyKind(filter.FromDate.Value, DateTimeKind.Utc);
                query = query.Where(v => v.EndDate >= fromUtc);
            }

            if (filter.ToDate.HasValue)
            {
                var rawTo = filter.ToDate.Value;
                var toDateAdjusted = rawTo.TimeOfDay == TimeSpan.Zero ? rawTo.Date.AddDays(1).AddTicks(-1) : rawTo;
                var toUtc = DateTime.SpecifyKind(toDateAdjusted, DateTimeKind.Utc);
                query = query.Where(v => v.StartDate <= toUtc);
            }

            if (!string.IsNullOrWhiteSpace(filter.Search))
            {
                var search = filter.Search.Trim().ToLower();
                query = query.Where(v => v.Code.ToLower().Contains(search) || 
                                         v.Title.ToLower().Contains(search) ||
                                         (v.Description != null && v.Description.ToLower().Contains(search)));
            }
        }

        query = filter?.SortBy?.ToLower() switch
        {
            "code" => filter.IsAscending ? query.OrderBy(v => v.Code) : query.OrderByDescending(v => v.Code),
            "title" => filter.IsAscending ? query.OrderBy(v => v.Title) : query.OrderByDescending(v => v.Title),
            "startdate" => filter.IsAscending ? query.OrderBy(v => v.StartDate) : query.OrderByDescending(v => v.StartDate),
            "enddate" => filter.IsAscending ? query.OrderBy(v => v.EndDate) : query.OrderByDescending(v => v.EndDate),
            "discountvalue" => filter.IsAscending ? query.OrderBy(v => v.DiscountValue) : query.OrderByDescending(v => v.DiscountValue),
            "usedcount" => filter.IsAscending ? query.OrderBy(v => v.UsedCount) : query.OrderByDescending(v => v.UsedCount),
            _ => filter != null && filter.IsAscending ? query.OrderBy(v => v.CreatedAt) : query.OrderByDescending(v => v.CreatedAt)
        };

        return await query.ToPagedResultAsync(pagination, v => v.ToVoucherBaseDto(now));
    }

    public async Task<IEnumerable<VoucherBaseDto>> GetAvailableVouchersAsync()
    {
        var now = DateTime.UtcNow;

        var list = await dbContext.Vouchers
            .AsNoTracking()
            .Where(v => v.IsActive && 
                        v.IsPublic && 
                        v.StartDate <= now && 
                        v.EndDate >= now && 
                        (!v.UsageLimit.HasValue || v.UsedCount < v.UsageLimit.Value))
            .OrderBy(v => v.EndDate)
            .ToListAsync();

        return list.Select(v => v.ToVoucherBaseDto(now));
    }

    public async Task<VoucherDetailDto?> GetVoucherByIdAsync(int id)
    {
        var voucher = await dbContext.Vouchers
            .Include(v => v.UserVouchers)
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.VoucherId == id);

        return voucher?.ToVoucherDetailDto();
    }

    public async Task<VoucherDetailDto> CreateVoucherAsync(VoucherUpsertRequestDto request)
    {
        var code = request.Code.Trim().ToUpperInvariant();

        var codeExists = await dbContext.Vouchers.AnyAsync(v => v.Code == code);
        if (codeExists)
        {
            throw new BadRequestException($"Mã voucher '{code}' đã tồn tại trên hệ thống. Vui lòng chọn mã khác.");
        }

        var voucher = new Voucher
        {
            Code = code,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim(),
            DiscountType = request.DiscountType,
            DiscountValue = request.DiscountValue,
            MinOrderValue = request.MinOrderValue,
            MaxDiscountAmount = request.MaxDiscountAmount,
            UsageLimit = request.UsageLimit,
            LimitPerUser = request.LimitPerUser,
            StartDate = DateTime.SpecifyKind(request.StartDate, DateTimeKind.Utc),
            EndDate = DateTime.SpecifyKind(request.EndDate, DateTimeKind.Utc),
            IsActive = request.IsActive,
            IsPublic = request.IsPublic,
            UsedCount = 0,
            CreatedAt = DateTime.UtcNow
        };

        dbContext.Vouchers.Add(voucher);
        await dbContext.SaveChangesAsync();

        return (await GetVoucherByIdAsync(voucher.VoucherId))!;
    }

    public async Task<VoucherDetailDto?> UpdateVoucherAsync(int id, VoucherUpsertRequestDto request)
    {
        var voucher = await dbContext.Vouchers
            .Include(v => v.UserVouchers)
            .FirstOrDefaultAsync(v => v.VoucherId == id);

        if (voucher == null) return null;

        var now = DateTime.UtcNow;

        // 1. Kiểm tra trạng thái đã kết thúc (EXPIRED) -> Khóa dữ liệu lịch sử
        if (voucher.EndDate < now)
        {
            throw new BadRequestException("Chiến dịch voucher đã kết thúc trong quá khứ, không thể chỉnh sửa. Hãy tạo voucher mới.");
        }

        var newCode = request.Code.Trim().ToUpperInvariant();
        var newStartDate = DateTime.SpecifyKind(request.StartDate, DateTimeKind.Utc);
        var newEndDate = DateTime.SpecifyKind(request.EndDate, DateTimeKind.Utc);

        // 2. Nếu chiến dịch đang diễn ra (ACTIVE) -> Chặn thay đổi các thông số nhạy cảm trước khi truy vấn DB
        if (voucher.StartDate <= now && voucher.EndDate >= now)
        {
            if (newCode != voucher.Code)
            {
                throw new BadRequestException("Không thể thay đổi mã code khi chiến dịch đang diễn ra.");
            }

            if (newStartDate != voucher.StartDate)
            {
                throw new BadRequestException("Chiến dịch đang diễn ra không thể thay đổi hoặc dời ngày bắt đầu.");
            }

            if (voucher.DiscountType != request.DiscountType || voucher.DiscountValue != request.DiscountValue)
            {
                throw new BadRequestException("Không thể thay đổi loại hoặc mức giảm giá khi chiến dịch đang diễn ra. Hãy tạo chiến dịch mới.");
            }
        }

        // 3. Kiểm tra trùng mã code nếu có thay đổi (chỉ xảy ra khi chiến dịch UPCOMING)
        if (newCode != voucher.Code)
        {
            var codeExists = await dbContext.Vouchers.AnyAsync(v => v.Code == newCode && v.VoucherId != id);
            if (codeExists)
            {
                throw new BadRequestException($"Mã voucher '{newCode}' đã được sử dụng bởi chiến dịch khác.");
            }
        }

        // Cập nhật các thông tin cho phép chỉnh sửa
        voucher.Title = request.Title.Trim();
        voucher.Description = request.Description?.Trim();
        voucher.EndDate = newEndDate;
        voucher.MinOrderValue = request.MinOrderValue;
        voucher.MaxDiscountAmount = request.MaxDiscountAmount;
        voucher.UsageLimit = request.UsageLimit;
        voucher.LimitPerUser = request.LimitPerUser;
        voucher.IsActive = request.IsActive;
        voucher.IsPublic = request.IsPublic;

        // Đối với chiến dịch chưa bắt đầu (UPCOMING), cho phép cập nhật toàn diện
        if (now < voucher.StartDate)
        {
            voucher.Code = newCode;
            voucher.StartDate = newStartDate;
            voucher.DiscountType = request.DiscountType;
            voucher.DiscountValue = request.DiscountValue;
        }

        await dbContext.SaveChangesAsync();
        return await GetVoucherByIdAsync(id);
    }

    public async Task<bool?> ToggleActiveAsync(int id)
    {
        var voucher = await dbContext.Vouchers.FindAsync(id);
        if (voucher == null) return null;

        voucher.IsActive = !voucher.IsActive;
        await dbContext.SaveChangesAsync();
        return voucher.IsActive;
    }

    public async Task<bool> DeleteVoucherAsync(int id)
    {
        var voucher = await dbContext.Vouchers.FindAsync(id);
        if (voucher == null) return false;

        var now = DateTime.UtcNow;

        if (voucher.UsedCount > 0)
        {
            throw new BadRequestException("Voucher đã có lượt sử dụng thực tế. Không thể xóa để bảo toàn lịch sử giao dịch. Hãy chuyển trạng thái sang Tắt (IsActive = false).");
        }

        if (voucher.StartDate <= now)
        {
            throw new BadRequestException("Không thể xóa voucher đã hoặc đang diễn ra. Bạn chỉ có thể tắt hoạt động.");
        }

        dbContext.Vouchers.Remove(voucher);
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<ApplyVoucherResponseDto> ApplyVoucherAsync(ApplyVoucherRequestDto request, int? userId = null)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var voucher = await dbContext.Vouchers
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.Code == code);

        if (voucher == null)
        {
            return new ApplyVoucherResponseDto
            {
                IsValid = false,
                Message = $"Mã giảm giá '{code}' không tồn tại trên hệ thống."
            };
        }

        if (!voucher.IsActive)
        {
            return new ApplyVoucherResponseDto
            {
                IsValid = false,
                Message = "Mã giảm giá này hiện đang tạm khóa hoặc đã ngưng áp dụng."
            };
        }

        var now = DateTime.UtcNow;

        if (now < voucher.StartDate)
        {
            return new ApplyVoucherResponseDto
            {
                IsValid = false,
                Message = $"Mã giảm giá chỉ có hiệu lực từ ngày {voucher.StartDate:dd/MM/yyyy HH:mm}."
            };
        }

        if (now > voucher.EndDate)
        {
            return new ApplyVoucherResponseDto
            {
                IsValid = false,
                Message = "Mã giảm giá đã hết hạn sử dụng."
            };
        }

        if (voucher.UsageLimit.HasValue && voucher.UsedCount >= voucher.UsageLimit.Value)
        {
            return new ApplyVoucherResponseDto
            {
                IsValid = false,
                Message = "Mã giảm giá đã hết lượt sử dụng trên hệ thống."
            };
        }

        if (request.SubtotalAmount < voucher.MinOrderValue)
        {
            return new ApplyVoucherResponseDto
            {
                IsValid = false,
                Message = $"Đơn hàng tối thiểu phải từ {voucher.MinOrderValue:N0} VNĐ để áp dụng mã này."
            };
        }

        // Kiểm tra giới hạn số lần dùng của từng tài khoản nếu khách đã đăng nhập
        if (userId.HasValue)
        {
            var userUsageCount = await dbContext.UserVouchers
                .CountAsync(uv => uv.UserId == userId.Value && uv.VoucherId == voucher.VoucherId && uv.IsUsed);

            if (userUsageCount >= voucher.LimitPerUser)
            {
                return new ApplyVoucherResponseDto
                {
                    IsValid = false,
                    Message = $"Bạn đã sử dụng hết giới hạn {voucher.LimitPerUser} lần cho mã giảm giá này."
                };
            }
        }

        // Tính toán số tiền giảm giá qua helper dùng chung
        var discountAmount = voucher.CalculateDiscount(request.SubtotalAmount);
        var finalTotal = Math.Max(0, request.SubtotalAmount - discountAmount);

        return new ApplyVoucherResponseDto
        {
            IsValid = true,
            Message = "Áp dụng mã giảm giá thành công.",
            VoucherId = voucher.VoucherId,
            Code = voucher.Code,
            Title = voucher.Title,
            DiscountType = voucher.DiscountType,
            DiscountValue = voucher.DiscountValue,
            DiscountAmount = discountAmount,
            FinalTotal = finalTotal
        };
    }

    public async Task<IEnumerable<UserVoucherItemDto>> GetMyVouchersAsync(int userId, UserVoucherWalletStatus? status = null)
    {
        var now = DateTime.UtcNow;

        var query = dbContext.UserVouchers
            .Include(uv => uv.Voucher)
            .Where(uv => uv.UserId == userId)
            .AsNoTracking();

        if (status.HasValue)
        {
            query = status.Value switch
            {
                UserVoucherWalletStatus.USABLE => query.Where(uv => !uv.IsUsed && uv.Voucher.IsActive && uv.Voucher.StartDate <= now && uv.Voucher.EndDate >= now),
                UserVoucherWalletStatus.USED => query.Where(uv => uv.IsUsed),
                UserVoucherWalletStatus.EXPIRED => query.Where(uv => !uv.IsUsed && uv.Voucher.EndDate < now),
                _ => query
            };
        }

        var list = await query
            .OrderByDescending(uv => uv.AssignedAt)
            .ToListAsync();

        return list.Select(uv => uv.ToUserVoucherItemDto(now));
    }

    public async Task<UserVoucherItemDto> ClaimVoucherAsync(int voucherId, int userId)
    {
        var voucher = await dbContext.Vouchers.FindAsync(voucherId);
        if (voucher == null)
        {
            throw new KeyNotFoundException($"Không tìm thấy voucher với mã ID: {voucherId}.");
        }

        var now = DateTime.UtcNow;

        if (!voucher.IsCurrentlyValid(now))
        {
            throw new BadRequestException("Voucher này hiện không trong thời gian thu thập hoặc đã hết hạn.");
        }

        if (!voucher.IsPublic)
        {
            throw new BadRequestException("Voucher này không hỗ trợ thu thập trực tiếp. Bạn chỉ có thể nhận qua khảo sát hoặc sự kiện đặc quyền.");
        }

        if (voucher.HasReachedUsageLimit())
        {
            throw new BadRequestException("Voucher đã hết lượt phát hành trên hệ thống.");
        }

        // Kiểm tra xem khách đã lưu bao nhiêu voucher loại này vào ví chưa dùng
        var existingCount = await dbContext.UserVouchers
            .CountAsync(uv => uv.UserId == userId && uv.VoucherId == voucherId && !uv.IsUsed);

        if (existingCount >= voucher.LimitPerUser)
        {
            throw new BadRequestException($"Bạn đã lưu tối đa {voucher.LimitPerUser} lượt khả dụng cho voucher này trong ví.");
        }

        var userVoucher = new UserVoucher
        {
            UserId = userId,
            VoucherId = voucherId,
            AssignedType = VoucherAssignedType.CLAIMED,
            AssignedAt = DateTime.UtcNow,
            IsUsed = false
        };

        dbContext.UserVouchers.Add(userVoucher);
        await dbContext.SaveChangesAsync();

        userVoucher.Voucher = voucher;
        return userVoucher.ToUserVoucherItemDto(now);
    }
}

