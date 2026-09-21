using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Users;

public class UpdateRoleRequestDto
{
    [Required(ErrorMessage = "RoleId không được để trống.")]
    public string RoleId { get; set; } = string.Empty;
}
