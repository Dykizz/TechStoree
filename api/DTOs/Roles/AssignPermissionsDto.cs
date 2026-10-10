using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Roles;

public class AssignPermissionsDto
{
    /// <summary>
    /// Danh sách các mã quyền hạn cần gán cho vai trò
    /// </summary>
    /// <example>["Products.View", "Products.Create", "Orders.View"]</example>
    [Required(ErrorMessage = "Danh sách quyền không được để trống")]
    public List<string> Permissions { get; set; } = new();
}
