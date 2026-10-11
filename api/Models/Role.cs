using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace WebBanHang.Api.Models;

[Table("roles")]
public class Role
{
    [Key]
    [Column("role_id")]
    [MaxLength(50)]
    public string RoleId { get; set; } = string.Empty;

    [Required]
    [Column("role_name")]
    [MaxLength(100)]
    public string RoleName { get; set; } = string.Empty;

    [Column("description")]
    [MaxLength(255)]
    public string? Description { get; set; }

    [Column("is_system")]
    public bool IsSystem { get; set; } = false;

    [JsonIgnore]
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();

    [JsonIgnore]
    public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
}
