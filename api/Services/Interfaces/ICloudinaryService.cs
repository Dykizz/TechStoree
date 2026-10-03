using WebBanHang.Api.DTOs.Media;

namespace WebBanHang.Api.Services.Interfaces;

/// <summary>
/// Dịch vụ quản lý tệp phương tiện và chữ ký số Cloudinary (Media Service)
/// </summary>
public interface ICloudinaryService
{
    /// <summary>
    /// Sinh chữ ký số bảo mật (Signature) cho Frontend (Web/Flutter) tải ảnh trực tiếp lên Cloudinary
    /// </summary>
    /// <param name="request">Yêu cầu cấu hình thư mục, publicId</param>
    /// <returns>Chữ ký số và các tham số xác thực</returns>
    CloudinarySignatureResponseDto GenerateUploadSignature(CloudinarySignatureRequestDto? request = null);

    /// <summary>
    /// Xóa tệp phương tiện trên Cloudinary dựa trên Public ID hoặc URL ảnh
    /// </summary>
    /// <param name="publicIdOrUrl">Public ID hoặc URL đầy đủ của ảnh</param>
    /// <returns>Kết quả xóa từ Cloudinary</returns>
    Task<DeleteMediaResponseDto> DeleteMediaAsync(string publicIdOrUrl);

    /// <summary>
    /// Bóc tách chuỗi Public ID từ đường dẫn URL Cloudinary hoặc trả về chính nó nếu đã là Public ID
    /// </summary>
    /// <param name="publicIdOrUrl">Chuỗi URL hoặc Public ID</param>
    /// <returns>Public ID chuẩn</returns>
    string ExtractPublicId(string publicIdOrUrl);
}
