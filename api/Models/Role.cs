using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace WebBanHang.Api.Models;

[Table("roles")]
public class Role
{
    [Key]
    [Column("role_id")]
    [MaxLength(20)]
    public string RoleId { get; set; } = string.Empty; // "ADMIN", "USER"

    [Required]
    [Column("role_name")]
    [MaxLength(50)]
    public string RoleName { get; set; } = string.Empty;

    [JsonIgnore]
    public ICollection<User> Users { get; set; } = new List<User>();
}
