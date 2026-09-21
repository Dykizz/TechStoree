using WebBanHang.Api.DTOs.Auth;
using WebBanHang.Api.DTOs.Suppliers;
using WebBanHang.Api.DTOs.Users;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Extensions;

public static class MappingExtensions
{
    public static BasicUserDto ToDto(this User user)
    {
        return new BasicUserDto
        {
            UserId = user.UserId,
            Username = user.Username,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.RoleId
        };
    }

    public static UserInfoDto ToInfoDto(this User user)
    {
        return new UserInfoDto
        {
            UserId = user.UserId,
            Username = user.Username,
            Email = user.Email,
            FullName = user.FullName,
            Phone = user.Phone,
            DateOfBirth = user.DateOfBirth,
            TechInterest = user.TechInterest,
            Address = user.Address,
            Role = user.RoleId,
            IsLocked = user.IsLocked,
            CreatedAt = user.CreatedAt
        };
    }

    public static UserDto ToUserDto(this User user)
    {
        return new UserDto
        {
            UserId = user.UserId,
            Username = user.Username,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            DateOfBirth = user.DateOfBirth,
            TechInterest = user.TechInterest,
            Address = user.Address,
            Role = user.RoleId,
            IsLocked = user.IsLocked,
            CreatedAt = user.CreatedAt
        };
    }

    public static SupplierDto ToSupplierDto(this Supplier supplier)
    {
        return new SupplierDto
        {
            SupplierId = supplier.SupplierId,
            SupplierName = supplier.SupplierName,
            Phone = supplier.Phone,
            Email = supplier.Email,
            Address = supplier.Address,
            CreatedAt = supplier.CreatedAt,
            DeletedAt = supplier.DeletedAt
        };
    }
}

