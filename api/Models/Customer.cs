using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

/// <summary>
/// Thực thể Khách hàng - Lưu trữ thông tin nghiệp vụ mua sắm và nhận hàng của người dùng
/// Quan hệ 1 - 1 với User (Table-per-Type specialization)
/// </summary>
[Table("customers")]
public class Customer
{
    [Key]
    [Column("customer_id")]
    public int CustomerId { get; set; }

    [ForeignKey(nameof(CustomerId))]
    public User User { get; set; } = null!;

    [Column("address")]
    [MaxLength(255)]
    public string? Address { get; set; }

    [Column("date_of_birth")]
    public DateTime? DateOfBirth { get; set; }

    [Column("tech_interest")]
    [MaxLength(100)]
    public string? TechInterest { get; set; }
}
