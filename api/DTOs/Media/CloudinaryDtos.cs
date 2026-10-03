using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Media;

/// <summary>
/// Yêu cầu sinh chữ ký tải ảnh trực tiếp lên Cloudinary (Direct Signed Upload)
/// </summary>
public class CloudinarySignatureRequestDto
{
    /// <summary>
    /// Thư mục lưu trữ trên Cloudinary (Mặc định: techstore)
    /// </summary>
    /// <example>techstore/products</example>
    public string? Folder { get; set; }

    /// <summary>
    /// Tùy chọn định danh public_id cụ thể (nếu để trống Cloudinary sẽ tự sinh chuỗi ngẫu nhiên)
    /// </summary>
    /// <example>asus-zenbook-14</example>
    public string? PublicId { get; set; }
}

/// <summary>
/// Dữ liệu chữ ký và thông số xác thực trả về cho Frontend (Web/Flutter)
/// </summary>
public class CloudinarySignatureResponseDto
{
    /// <summary>
    /// Chữ ký số mã hóa bảo mật (SHA-1 / SHA-256)
    /// </summary>
    /// <example>3a8b4f1c9d2e7a5b6c8d1e3f4a5b6c7d8e9f0a1b</example>
    public string Signature { get; set; } = string.Empty;

    /// <summary>
    /// Mốc thời gian Unix timestamp tính bằng giây
    /// </summary>
    /// <example>1727938472</example>
    public long Timestamp { get; set; }

    /// <summary>
    /// API Key công khai của Cloudinary
    /// </summary>
    /// <example>123456789012345</example>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>
    /// Tên Cloud Name của Cloudinary
    /// </summary>
    /// <example>techstore-demo</example>
    public string CloudName { get; set; } = string.Empty;

    /// <summary>
    /// Thư mục đã ký
    /// </summary>
    /// <example>techstore/products</example>
    public string? Folder { get; set; }

    /// <summary>
    /// Public ID đã ký (nếu có)
    /// </summary>
    public string? PublicId { get; set; }

    /// <summary>
    /// Đường dẫn API trực tiếp để Frontend gửi POST multipart/form-data
    /// </summary>
    /// <example>https://api.cloudinary.com/v1_1/techstore-demo/auto/upload</example>
    public string UploadUrl { get; set; } = string.Empty;
}

/// <summary>
/// Yêu cầu xóa tệp tin đa phương tiện trên Cloudinary
/// </summary>
public class DeleteMediaRequestDto
{
    /// <summary>
    /// Public ID hoặc Đường dẫn URL đầy đủ của ảnh trên Cloudinary
    /// </summary>
    /// <example>https://res.cloudinary.com/demo/image/upload/v1727938472/techstore/products/sample123.jpg</example>
    [Required(ErrorMessage = "Public ID hoặc URL của tệp phương tiện không được để trống.")]
    public string PublicIdOrUrl { get; set; } = string.Empty;
}

/// <summary>
/// Kết quả xóa tệp tin trên Cloudinary
/// </summary>
public class DeleteMediaResponseDto
{
    /// <summary>
    /// Public ID đã được bóc tách và gửi lệnh xóa
    /// </summary>
    /// <example>techstore/products/sample123</example>
    public string PublicId { get; set; } = string.Empty;

    /// <summary>
    /// Kết quả từ Cloudinary: "ok", "not found"
    /// </summary>
    /// <example>ok</example>
    public string Result { get; set; } = string.Empty;

    /// <summary>
    /// Trạng thái xóa thành công
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Thông điệp kết quả
    /// </summary>
    /// <example>Xóa tệp phương tiện trên Cloudinary thành công.</example>
    public string Message { get; set; } = string.Empty;
}
