using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Users;

namespace WebBanHang.Api.Services.Interfaces;

public interface IUserService
{
    Task<PagedResult<UserDto>> GetUsersAsync(UserQueryFilter filter);
    Task<UserDto> GetUserByIdAsync(int id);
    Task<UserDto> ToggleLockAsync(int id, ToggleLockRequestDto? dto);
    Task<UserDto> UpdateRoleAsync(int id, UpdateRoleRequestDto dto);
    Task<UserDto> UpdateProfileAsync(int userId, UpdateProfileRequestDto dto);
}
