using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Roles;

public class CreateRoleDto
{
    /// <summary>
    /// Mã định danh vai trò tùy chọn (nếu để trống hệ thống sẽ tự sinh GUID)
    /// </summary>
    /// <example>ROLE_CSKH</example>
    [MaxLength(50)]
    public string? RoleId { get; set; }

    /// <summary>
    /// Tên vai trò
    /// </summary>
    /// <example>Nhân viên Chăm sóc Khách hàng</example>
    [Required(ErrorMessage = "Tên vai trò không được để trống")]
    [MaxLength(100, ErrorMessage = "Tên vai trò không vượt quá 100 ký tự")]
    public string RoleName { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả chi tiết vai trò
    /// </summary>
    /// <example>Hỗ trợ tư vấn khách hàng và tra cứu đơn hàng</example>
    [MaxLength(255, ErrorMessage = "Mô tả không vượt quá 255 ký tự")]
    public string? Description { get; set; }

    /// <summary>
    /// Danh sách mã quyền hạn gán cho vai trò khi khởi tạo
    /// </summary>
    /// <example>["Products.View", "Orders.View", "Orders.Update", "Surveys.View"]</example>
    public List<string> Permissions { get; set; } = new();
}

public class UpdateRoleDto
{
    /// <summary>
    /// Tên vai trò
    /// </summary>
    /// <example>Nhân viên CSKH Nâng Cao</example>
    [Required(ErrorMessage = "Tên vai trò không được để trống")]
    [MaxLength(100, ErrorMessage = "Tên vai trò không vượt quá 100 ký tự")]
    public string RoleName { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả chi tiết vai trò
    /// </summary>
    /// <example>Mở rộng quyền xử lý đơn hàng và xem khuyến mãi</example>
    [MaxLength(255, ErrorMessage = "Mô tả không vượt quá 255 ký tự")]
    public string? Description { get; set; }

    /// <summary>
    /// Danh sách mã quyền hạn cập nhật cho vai trò
    /// </summary>
    /// <example>["Products.View", "Orders.View", "Orders.Update", "Promotions.View"]</example>
    public List<string> Permissions { get; set; } = new();
}
