using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Users;
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
}
