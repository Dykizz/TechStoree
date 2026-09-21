namespace WebBanHang.Api.DTOs.Auth;

public class UserInfoDto
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? TechInterest { get; set; }
    public string? Address { get; set; }
    public string Role { get; set; } = string.Empty;
    public bool IsLocked { get; set; }
    public DateTime CreatedAt { get; set; }
}
