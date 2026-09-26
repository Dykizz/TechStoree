using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.Models;

public class Supplier
{
    public int SupplierId { get; set; }

    [Required]
    [MaxLength(150)]
    public string SupplierName { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [MaxLength(100)]
    public string? Email { get; set; }

    [MaxLength(255)]
    public string? Address { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? DeletedAt { get; set; }
}
