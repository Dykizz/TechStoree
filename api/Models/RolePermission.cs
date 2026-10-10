using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("role_permissions")]
public class RolePermission
{
    [Column("role_id")]
    [MaxLength(50)]
    public string RoleId { get; set; } = string.Empty;
    public Role? Role { get; set; }

    [Column("permission_id")]
    [MaxLength(50)]
    public string PermissionId { get; set; } = string.Empty;
    public Permission? Permission { get; set; }

    [Column("assigned_at")]
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;
}
