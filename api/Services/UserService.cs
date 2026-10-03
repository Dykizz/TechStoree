using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class UserService(AppDbContext context) : IUserService
{
    public async Task<PagedResult<UserDto>> GetUsersAsync(UserQueryFilter filter)
    {
        var query = context.Users
            .AsNoTracking()
            .Include(u => u.Role)
            .AsQueryable();

        // 1. Lọc theo vai trò (nếu có)
        if (!string.IsNullOrWhiteSpace(filter.Role))
        {
            var roleLower = filter.Role.Trim().ToLower();
            query = query.Where(u => u.RoleId.ToLower() == roleLower);
        }

        // 2. Lọc theo trạng thái khóa (nếu có)
        if (filter.IsLocked.HasValue)
        {
            query = query.Where(u => u.IsLocked == filter.IsLocked.Value);
        }

        // 3. Tìm kiếm theo từ khóa (username, email, họ tên, số điện thoại)
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim().ToLower();
            query = query.Where(u =>
                u.Username.ToLower().Contains(search) ||
                u.Email.ToLower().Contains(search) ||
                u.FullName.ToLower().Contains(search) ||
                (u.Phone != null && u.Phone.Contains(search)));
        }

        // 4. Sắp xếp mặc định theo thời gian tạo mới nhất
        query = query.OrderByDescending(u => u.CreatedAt);

        // 5. Đếm tổng số bản ghi & lấy dữ liệu phân trang
        var totalItems = await query.CountAsync();
        var users = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        var items = users.Select(u => u.ToUserDto()).ToList();

        return new PagedResult<UserDto>(items, totalItems, filter.Page, filter.PageSize);
    }

    public async Task<UserDto> GetUserByIdAsync(int id)
    {
        var user = await context.Users
            .AsNoTracking()
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.UserId == id);

        if (user == null)
        {
            throw new NotFoundException($"Không tìm thấy người dùng với mã ID = {id}.");
        }

        return user.ToUserDto();
    }

    public async Task<UserDto> ToggleLockAsync(int id, ToggleLockRequestDto? dto)
    {
        var user = await context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.UserId == id);

        if (user == null)
        {
            throw new NotFoundException($"Không tìm thấy người dùng với mã ID = {id}.");
        }

        // Cập nhật trạng thái khóa: nếu client chỉ định IsLocked thì gán, ngược lại tự động đảo chiều (toggle)
        user.IsLocked = dto?.IsLocked ?? !user.IsLocked;

        // Nếu tài khoản bị khóa, lập tức thu hồi Refresh Token để chấm dứt phiên đăng nhập hiện tại
        if (user.IsLocked)
        {
            user.RefreshToken = null;
            user.RefreshTokenExpiryTime = null;
        }

        await context.SaveChangesAsync();
        return user.ToUserDto();
    }

    public async Task<UserDto> UpdateRoleAsync(int id, UpdateRoleRequestDto dto)
    {
        var user = await context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.UserId == id);

        if (user == null)
        {
            throw new NotFoundException($"Không tìm thấy người dùng với mã ID = {id}.");
        }

        var normalizedRoleId = dto.RoleId.Trim().ToUpper();

        // Kiểm tra xem RoleId có tồn tại trong bảng roles không
        var roleExists = await context.Roles.AnyAsync(r => r.RoleId == normalizedRoleId);
        if (!roleExists)
        {
            throw new BadRequestException($"Vai trò '{dto.RoleId}' không hợp lệ trên hệ thống.");
        }

        user.RoleId = normalizedRoleId;
        await context.SaveChangesAsync();

        return user.ToUserDto();
    }

    public async Task<UserDto> UpdateProfileAsync(int userId, UpdateProfileRequestDto dto)
    {
        var user = await context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null)
        {
            throw new NotFoundException("Không tìm thấy thông tin tài khoản người dùng.");
        }

        user.FullName = dto.FullName.Trim();
        user.Phone = dto.Phone?.Trim();
        user.DateOfBirth = dto.DateOfBirth.HasValue
            ? DateTime.SpecifyKind(dto.DateOfBirth.Value, DateTimeKind.Utc)
            : null;
        user.TechInterest = dto.TechInterest?.Trim();
        user.Address = dto.Address?.Trim();

        await context.SaveChangesAsync();
        return user.ToUserDto();
    }

    public List<TechInterestOptionDto> GetTechInterests()
    {
        return Enum.GetValues<TechInterestType>()
            .Select(type =>
            {
                var (displayName, description) = type.GetMetadata();
                return new TechInterestOptionDto
                {
                    Key = type.ToString(),
                    DisplayName = displayName,
                    Description = description
                };
            })
            .ToList();
    }

    public async Task<DemographicsReportDto> GetDemographicsReportAsync()
    {
        // 1. Chỉ lấy nhóm khách hàng (RoleId là USER, loại trừ tài khoản quản trị ADMIN)
        var customers = await context.Users
            .AsNoTracking()
            .Where(u => u.RoleId == UserRoleTypeExtensions.User)
            .Select(u => new
            {
                u.UserId,
                u.DateOfBirth,
                u.TechInterest
            })
            .ToListAsync();

        var totalCustomers = customers.Count;
        var customersWithBirthDate = customers.Count(c => c.DateOfBirth.HasValue);
        var customersWithInterest = customers.Count(c => !string.IsNullOrWhiteSpace(c.TechInterest));

        // 2. Thống kê theo phân khúc độ tuổi chuẩn hóa từ CustomerAgeGroupType Enum
        var ageCounts = Enum.GetValues<CustomerAgeGroupType>()
            .ToDictionary(g => g, _ => 0);
        int unknownAge = 0;

        var now = DateTime.UtcNow;
        foreach (var c in customers)
        {
            if (!c.DateOfBirth.HasValue)
            {
                unknownAge++;
                continue;
            }

            var dob = c.DateOfBirth.Value;
            var age = now.Year - dob.Year;
            if (now.DayOfYear < dob.DayOfYear) age--;

            var group = CustomerAgeGroupTypeExtensions.FromAge(age);
            ageCounts[group]++;
        }

        var ageGroups = ageCounts
            .Select(kv => new AgeGroupReportDto
            {
                GroupKey = kv.Key.ToString(),
                GroupName = kv.Key.GetDisplayName(),
                Count = kv.Value,
                Percentage = totalCustomers > 0 ? Math.Round((double)kv.Value / totalCustomers * 100, 1) : 0
            })
            .ToList();

        if (unknownAge > 0)
        {
            ageGroups.Add(new AgeGroupReportDto
            {
                GroupKey = "UNKNOWN",
                GroupName = "Chưa cập nhật ngày sinh",
                Count = unknownAge,
                Percentage = totalCustomers > 0 ? Math.Round((double)unknownAge / totalCustomers * 100, 1) : 0
            });
        }

        // 3. Thống kê theo phân khúc sở thích công nghệ chuẩn hóa từ TechInterestType Enum
        var interestCounts = Enum.GetValues<TechInterestType>()
            .ToDictionary(type => type, _ => 0);
        int notSetCount = 0;

        foreach (var c in customers)
        {
            if (!string.IsNullOrWhiteSpace(c.TechInterest) &&
                Enum.TryParse<TechInterestType>(c.TechInterest.Trim(), true, out var matchedType))
            {
                interestCounts[matchedType]++;
            }
            else
            {
                notSetCount++;
            }
        }

        var interestGroups = interestCounts
            .Select(kv =>
            {
                var (displayName, _) = kv.Key.GetMetadata();
                return new InterestGroupReportDto
                {
                    Key = kv.Key.ToString(),
                    Name = displayName,
                    Count = kv.Value,
                    Percentage = totalCustomers > 0 ? Math.Round((double)kv.Value / totalCustomers * 100, 1) : 0
                };
            })
            .ToList();

        if (notSetCount > 0)
        {
            interestGroups.Add(new InterestGroupReportDto
            {
                Key = "NOT_SET",
                Name = "Chưa cập nhật sở thích",
                Count = notSetCount,
                Percentage = totalCustomers > 0 ? Math.Round((double)notSetCount / totalCustomers * 100, 1) : 0
            });
        }

        return new DemographicsReportDto
        {
            TotalCustomers = totalCustomers,
            CustomersWithBirthDate = customersWithBirthDate,
            CustomersWithInterest = customersWithInterest,
            AgeGroups = ageGroups,
            Interests = interestGroups
        };
    }
}
