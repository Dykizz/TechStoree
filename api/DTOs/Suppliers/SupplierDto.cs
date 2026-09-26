namespace WebBanHang.Api.DTOs.Suppliers;

public class SupplierDto
{
    /// <summary>
    /// Mã ID duy nhất của nhà cung cấp
    /// </summary>
    /// <example>1</example>
    public int SupplierId { get; set; }

    /// <summary>
    /// Tên nhà cung cấp
    /// </summary>
    /// <example>Công ty TNHH ASUS Việt Nam</example>
    public string SupplierName { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại
    /// </summary>
    /// <example>18006588</example>
    public string Phone { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ email
    /// </summary>
    /// <example>support@asus.com.vn</example>
    public string? Email { get; set; }

    /// <summary>
    /// Địa chỉ trụ sở
    /// </summary>
    /// <example>Tầng 5, Tòa nhà Viettel, 285 Cách Mạng Tháng 8, Q.10, TP.HCM</example>
    public string? Address { get; set; }

    /// <summary>
    /// Thời điểm khởi tạo đối tác (UTC)
    /// </summary>
    /// <example>2026-01-01T00:00:00Z</example>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Thời điểm bị xóa mềm (null nếu đang hoạt động)
    /// </summary>
    /// <example>null</example>
    public DateTime? DeletedAt { get; set; }

    /// <summary>
    /// Trạng thái đã bị xóa mềm hay chưa
    /// </summary>
    /// <example>false</example>
    public bool IsDeleted => DeletedAt.HasValue;
}
