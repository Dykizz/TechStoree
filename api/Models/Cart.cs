using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebBanHang.Api.Models;

[Table("carts")]
public class Cart
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("cart_id")]
    public int CartId { get; set; }

    [Column("user_id")]
    public int UserId { get; set; }

    [ForeignKey("UserId")]
    public User? User { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<CartItem> Items { get; set; } = new List<CartItem>();
}
