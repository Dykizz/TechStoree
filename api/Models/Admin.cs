using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

/// <summary>
/// Thực thể Quản trị viên - Thực thể định danh phân quyền cấp cao của hệ thống
/// Quan hệ 1 - 1 với User (Table-per-Type specialization)
/// </summary>
[Table("admins")]
public class Admin
{
    [Key]
    [Column("admin_id")]
    public int AdminId { get; set; }

    [ForeignKey(nameof(AdminId))]
    public User User { get; set; } = null!;
}
