using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Users;

public class UpdateRoleRequestDto
{
    /// <summary>
    /// Mã vai trò mới phân quyền cho tài khoản (ADMIN hoặc USER)
    /// </summary>
    /// <example>ADMIN</example>
    [Required(ErrorMessage = "RoleId không được để trống.")]
    public string RoleId { get; set; } = string.Empty;
}
