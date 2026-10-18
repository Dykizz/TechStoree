using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace WebBanHang.Api.Models;

[Table("permissions")]
public class Permission
{
    [Key]
    [Column("permission_id")]
    [MaxLength(50)]
    public string PermissionId { get; set; } = string.Empty;

    [Required]
    [Column("permission_name")]
    [MaxLength(100)]
    public string PermissionName { get; set; } = string.Empty;

    [Required]
    [Column("module")]
    [MaxLength(50)]
    public string Module { get; set; } = string.Empty;

    [Column("description")]
    [MaxLength(255)]
    public string? Description { get; set; }

    [JsonIgnore]
    public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
}
