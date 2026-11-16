using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Users;

namespace WebBanHang.Api.Services.Interfaces;

public interface IUserService
{
    Task<PagedResult<UserDto>> GetUsersAsync(UserQueryFilter filter, int currentUserId);
    Task<UserDto> GetUserByIdAsync(int id);
    Task<UserDto> ToggleLockAsync(int id, ToggleLockRequestDto? dto);
    Task<UserDto> CreateUserAsync(int creatorUserId, CreateUserRequestDto dto);
    Task<UserDto> UpdateRoleAsync(int operatorUserId, int id, UpdateRoleRequestDto dto);
    Task<UserDto> UpdateUserAsync(int operatorUserId, int id, UpdateUserRequestDto dto);
    Task<UserDto> UpdateProfileAsync(int userId, UpdateProfileRequestDto dto);
    Task<PagedResult<UserDto>> GetCustomersAsync(CustomerQueryFilter filter);
    Task<UserDto> GetCustomerByIdAsync(int id);
    Task<UserDto> CreateCustomerAsync(int creatorUserId, CreateCustomerRequestDto dto);
    Task<UserDto> UpdateCustomerAsync(int id, UpdateCustomerRequestDto dto);
    Task<UserDto> ToggleCustomerLockAsync(int id, ToggleLockRequestDto? dto);
    Task<PagedResult<UserDto>> GetEmployeesAsync(EmployeeQueryFilter filter);
    Task<UserDto> GetEmployeeByIdAsync(int id);
    Task<UserDto> CreateEmployeeAsync(int creatorUserId, CreateEmployeeRequestDto dto);
    Task<UserDto> UpdateEmployeeAsync(int id, UpdateEmployeeRequestDto dto);
    Task<UserDto> UpdateEmployeeRolesAsync(int operatorUserId, int id, UpdateRoleRequestDto dto);
    Task<UserDto> ToggleEmployeeLockAsync(int id, ToggleLockRequestDto? dto);
    Task<DemographicsReportDto> GetDemographicsReportAsync();
    List<TechInterestOptionDto> GetTechInterests();
}
