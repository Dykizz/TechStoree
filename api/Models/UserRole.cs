using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.Models;

[Table("user_roles")]
public class UserRole
{
    [Column("user_id")]
    public int UserId { get; set; }
    public User? User { get; set; }

    [Column("role_id")]
    [MaxLength(20)]
    public UserRoleType RoleId { get; set; }
    public Role? Role { get; set; }

    [Column("assigned_at")]
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

    [Column("assigned_by_user_id")]
    public int? AssignedByUserId { get; set; }

    [ForeignKey("AssignedByUserId")]
    public User? AssignedByUser { get; set; }
}
