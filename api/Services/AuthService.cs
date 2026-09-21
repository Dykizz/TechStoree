using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Auth;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class AuthService(AppDbContext context, ITokenService tokenService) : IAuthService
{
    public async Task<UserInfoDto> RegisterAsync(RegisterRequestDto dto)
    {
        // 1. Kiểm tra xem username đã tồn tại chưa
        var usernameExists = await context.Users
            .AnyAsync(u => u.Username.ToLower() == dto.Username.Trim().ToLower());
        if (usernameExists)
        {
            throw new BadRequestException("Tên đăng nhập này đã được sử dụng.");
        }

        // 2. Kiểm tra xem email đã tồn tại chưa
        var emailExists = await context.Users
            .AnyAsync(u => u.Email.ToLower() == dto.Email.Trim().ToLower());
        if (emailExists)
        {
            throw new BadRequestException("Địa chỉ email này đã được đăng ký.");
        }

        // 3. Băm mật khẩu bằng BCrypt
        var hashedPassword = BCrypt.Net.BCrypt.HashPassword(dto.Password);

        // 4. Tạo thực thể người dùng mới
        var newUser = new User
        {
            Username = dto.Username.Trim(),
            PasswordHash = hashedPassword,
            Email = dto.Email.Trim().ToLower(),
            FullName = dto.FullName.Trim(),
            Phone = dto.Phone?.Trim(),
            DateOfBirth = dto.DateOfBirth.HasValue ? DateTime.SpecifyKind(dto.DateOfBirth.Value, DateTimeKind.Utc) : null,
            TechInterest = dto.TechInterest?.Trim(),
            Address = dto.Address?.Trim(),
            RoleId = "USER", // Mặc định tài khoản đăng ký là USER
            IsLocked = false,
            CreatedAt = DateTime.UtcNow
        };

        context.Users.Add(newUser);
        await context.SaveChangesAsync();

        return newUser.ToInfoDto();
    }

    public async Task<LoginResponseDto> LoginAsync(LoginRequestDto dto)
    {
        // 1. Tìm tài khoản theo email
        var user = await context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.Trim().ToLower());

        // 2. Kiểm tra tài khoản tồn tại và khớp mật khẩu
        if (user == null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
        {
            throw new BadRequestException("Email hoặc mật khẩu không chính xác.");
        }

        // 3. Kiểm tra xem tài khoản có bị khóa không
        if (user.IsLocked)
        {
            throw new ForbiddenException("Tài khoản của bạn đã bị tạm khóa bởi quản trị viên.");
        }

        // 4. Sinh cặp Access Token và Refresh Token
        var accessToken = tokenService.GenerateToken(user);
        var refreshToken = tokenService.GenerateRefreshToken();

        // 5. Lưu Refresh Token vào CSDL (hạn 7 ngày)
        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
        await context.SaveChangesAsync();

        return new LoginResponseDto
        {
            Token = accessToken,
            RefreshToken = refreshToken,
            User = user.ToDto()
        };
    }

    public async Task<LoginResponseDto> RefreshTokenAsync(string? refreshToken)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            throw new BadRequestException("Refresh token không được để trống.");
        }

        // 1. Tìm tài khoản sở hữu refresh token này
        var user = await context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.RefreshToken == refreshToken);

        // 2. Kiểm tra tính hợp lệ và thời hạn của token
        if (user == null || !user.RefreshTokenExpiryTime.HasValue || user.RefreshTokenExpiryTime.Value <= DateTime.UtcNow)
        {
            throw new UnauthorizedException("Refresh token đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.");
        }

        // 3. Kiểm tra trạng thái tài khoản
        if (user.IsLocked)
        {
            throw new ForbiddenException("Tài khoản của bạn đã bị tạm khóa bởi quản trị viên.");
        }

        // 4. Xoay vòng token (Token Rotation): Hủy token cũ, sinh cặp Access Token & Refresh Token mới
        var newAccessToken = tokenService.GenerateToken(user);
        var newRefreshToken = tokenService.GenerateRefreshToken();

        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
        await context.SaveChangesAsync();

        return new LoginResponseDto
        {
            Token = newAccessToken,
            RefreshToken = newRefreshToken,
            User = user.ToDto()
        };
    }

    public async Task RevokeTokenAsync(int userId)
    {
        var user = await context.Users.FindAsync(userId);
        if (user != null)
        {
            user.RefreshToken = null;
            user.RefreshTokenExpiryTime = null;
            await context.SaveChangesAsync();
        }
    }

    public async Task<UserInfoDto> GetCurrentUserProfileAsync(int userId)
    {
        var user = await context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.UserId == userId);

        if (user == null)
        {
            throw new NotFoundException("Không tìm thấy thông tin tài khoản.");
        }

        return user.ToInfoDto();
    }
}
