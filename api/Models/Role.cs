using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.Models;

[Table("roles")]
public class Role
{
    [Key]
    [Column("role_id")]
    [MaxLength(20)]
    public UserRoleType RoleId { get; set; }

    [Required]
    [Column("role_name")]
    [MaxLength(50)]
    public string RoleName { get; set; } = string.Empty;

    [JsonIgnore]
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}
