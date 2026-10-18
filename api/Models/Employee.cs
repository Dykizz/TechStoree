using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WebBanHang.Api.Enums;

namespace WebBanHang.Api.Models;

/// <summary>
/// Thực thể Nhân viên - Lưu trữ thông tin nhân sự, chế độ làm việc và lương của nhân viên nội bộ
/// Quan hệ 1 - 1 với User (Table-per-Type specialization)
/// </summary>
[Table("employees")]
public class Employee
{
    [Key]
    [Column("employee_id")]
    public int EmployeeId { get; set; }

    [ForeignKey(nameof(EmployeeId))]
    public User User { get; set; } = null!;

    [Required]
    [Column("employee_code")]
    [MaxLength(20)]
    public string EmployeeCode { get; set; } = string.Empty;

    /// <summary>
    /// Hình thức làm việc: FULL_TIME (toàn thời gian) hoặc PART_TIME (bán thời gian theo ca)
    /// </summary>
    [Required]
    [Column("employment_type")]
    [MaxLength(20)]
    public EmploymentType EmploymentType { get; set; } = EmploymentType.FULL_TIME;

    /// <summary>
    /// Lương cơ bản hàng tháng (Áp dụng cho nhân viên Full-time)
    /// </summary>
    [Column("base_salary", TypeName = "decimal(12,0)")]
    public decimal BaseSalary { get; set; } = 0;

    /// <summary>
    /// Tiền công tính theo giờ làm việc (Áp dụng cho nhân viên Part-time)
    /// </summary>
    [Column("hourly_rate", TypeName = "decimal(10,0)")]
    public decimal HourlyRate { get; set; } = 0;
}
