using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class UserService(AppDbContext context) : IUserService
{
    public async Task<PagedResult<UserDto>> GetUsersAsync(UserQueryFilter filter)
    {
        var query = context.Users
            .AsNoTracking()
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .AsQueryable();

        // 1. Lọc theo vai trò cụ thể (nếu có)
        if (!string.IsNullOrWhiteSpace(filter.Role))
        {
            var roleFilter = filter.Role.Trim().ToUpper();
            query = query.Where(u => u.UserRoles.Any(ur => ur.RoleId == roleFilter));
        }

        // 1.1 Lọc nhóm cán bộ nhân viên nội bộ vs khách hàng thông thường (nếu có)
        if (filter.IsStaffOnly.HasValue)
        {
            if (filter.IsStaffOnly.Value)
            {
                // Chỉ lấy tài khoản có ít nhất một vai trò khác USER (tức là nhân viên / quản trị)
                query = query.Where(u => u.UserRoles.Any(ur => ur.RoleId != "USER"));
            }
            else
            {
                // Chỉ lấy khách hàng thông thường
                query = query.Where(u => u.UserRoles.All(ur => ur.RoleId == "USER"));
            }
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
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
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
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
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

    public async Task<UserDto> CreateUserAsync(int creatorUserId, CreateUserRequestDto dto)
    {
        // 1. Kiểm tra tên đăng nhập trùng lặp
        var usernameTrimmed = dto.Username.Trim();
        var usernameExists = await context.Users
            .AnyAsync(u => u.Username.ToLower() == usernameTrimmed.ToLower());
        if (usernameExists)
        {
            throw new BadRequestException("Tên đăng nhập này đã được sử dụng.");
        }

        // 2. Kiểm tra email trùng lặp
        var emailTrimmed = dto.Email.Trim().ToLower();
        var emailExists = await context.Users
            .AnyAsync(u => u.Email.ToLower() == emailTrimmed);
        if (emailExists)
        {
            throw new BadRequestException("Địa chỉ email này đã được đăng ký.");
        }

        // 3. Xử lý danh sách vai trò
        var requestedRoles = dto.Roles;

        var roleIds = new List<string>();
        if (requestedRoles != null && requestedRoles.Count > 0)
        {
            var cleanRoles = requestedRoles.Select(r => r.Trim().ToUpper()).Distinct().ToList();
            var existingRoles = await context.Roles
                .Where(r => cleanRoles.Contains(r.RoleId))
                .Select(r => r.RoleId)
                .ToListAsync();

            var invalidRoles = cleanRoles.Except(existingRoles, StringComparer.OrdinalIgnoreCase).ToList();
            if (invalidRoles.Count > 0)
            {
                throw new BadRequestException($"Các vai trò không tồn tại trong hệ thống: {string.Join(", ", invalidRoles)}.");
            }
            roleIds = existingRoles;
        }
        else
        {
            // Mặc định gán vai trò USER nếu không chỉ định vai trò nào
            roleIds.Add("USER");
        }

        // 4. Băm mật khẩu bằng BCrypt
        var hashedPassword = BCrypt.Net.BCrypt.HashPassword(dto.Password);

        // 5. Khởi tạo đối tượng User mới
        var newUser = new User
        {
            Username = usernameTrimmed,
            PasswordHash = hashedPassword,
            Email = emailTrimmed,
            FullName = dto.FullName.Trim(),
            Phone = dto.Phone?.Trim(),
            DateOfBirth = dto.DateOfBirth.HasValue ? DateTime.SpecifyKind(dto.DateOfBirth.Value, DateTimeKind.Utc) : null,
            TechInterest = dto.TechInterest?.Trim(),
            Address = dto.Address?.Trim(),
            IsLocked = false,
            CreatedByUserId = creatorUserId,
            CreatedAt = DateTime.UtcNow
        };

        foreach (var roleId in roleIds.Distinct())
        {
            newUser.UserRoles.Add(new UserRole
            {
                RoleId = roleId,
                AssignedByUserId = creatorUserId,
                AssignedAt = DateTime.UtcNow
            });
        }

        context.Users.Add(newUser);
        await context.SaveChangesAsync();

        return newUser.ToUserDto();
    }

    public async Task<UserDto> UpdateRoleAsync(int operatorUserId, int id, UpdateRoleRequestDto dto)
    {
        var user = await context.Users
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.UserId == id);

        if (user == null)
        {
            throw new NotFoundException($"Không tìm thấy người dùng với mã ID = {id}.");
        }

        // Hỗ trợ cả danh sách Roles mới lẫn RoleId đơn lẻ (tương thích ngược)
        var requestedRoles = (dto.Roles != null && dto.Roles.Count > 0)
            ? dto.Roles
            : (!string.IsNullOrWhiteSpace(dto.RoleId) ? new List<string> { dto.RoleId } : new List<string>());

        if (requestedRoles.Count == 0)
        {
            throw new BadRequestException("Danh sách vai trò không được để trống.");
        }

        var cleanRoles = requestedRoles.Select(r => r.Trim().ToUpper()).Distinct().ToList();
        var existingRoles = await context.Roles
            .Where(r => cleanRoles.Contains(r.RoleId))
            .Select(r => r.RoleId)
            .ToListAsync();

        var invalidRoles = cleanRoles.Except(existingRoles, StringComparer.OrdinalIgnoreCase).ToList();
        if (invalidRoles.Count > 0)
        {
            throw new BadRequestException($"Các vai trò không tồn tại trong hệ thống: {string.Join(", ", invalidRoles)}.");
        }

        // Xóa các vai trò cũ và gán các vai trò mới
        context.UserRoles.RemoveRange(user.UserRoles);
        user.UserRoles.Clear();

        foreach (var roleId in existingRoles)
        {
            user.UserRoles.Add(new UserRole
            {
                UserId = user.UserId,
                RoleId = roleId,
                AssignedByUserId = operatorUserId,
                AssignedAt = DateTime.UtcNow
            });
        }

        await context.SaveChangesAsync();
        return user.ToUserDto();
    }

    public async Task<UserDto> UpdateProfileAsync(int userId, UpdateProfileRequestDto dto)
    {
        var user = await context.Users
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
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
        // 1. Chỉ lấy nhóm khách hàng (sở hữu vai trò USER)
        var customers = await context.Users
            .AsNoTracking()
            .Where(u => u.UserRoles.Any(ur => ur.RoleId == "USER"))
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
