namespace WebBanHang.Api.DTOs.Users;

public class ToggleLockRequestDto
{
    /// <summary>
    /// Trạng thái khóa tài khoản: true (khóa), false (mở khóa), hoặc null/để trống (hệ thống tự động đảo trạng thái)
    /// </summary>
    /// <example>true</example>
    public bool? IsLocked { get; set; }
}
