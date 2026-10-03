using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Media;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Tệp Đa phương tiện và Chữ ký số Cloudinary (Media / Upload)
/// </summary>
[Tags("Media")]
public class MediaController(ICloudinaryService cloudinaryService) : BaseApiController
{
    /// <summary>
    /// Lấy chữ ký số Cloudinary (Signature) để Frontend (Web/Flutter) tải ảnh trực tiếp
    /// </summary>
    /// <param name="request">Thông tin cấu hình thư mục (mặc định: techstore), public_id</param>
    /// <returns>Chữ ký số, timestamp, uploadUrl, apiKey</returns>
    [Authorize]
    [HttpPost("signature")]
    [ProducesResponseType(typeof(ApiResponse<CloudinarySignatureResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public IActionResult GenerateSignature([FromBody] CloudinarySignatureRequestDto? request)
    {
        var result = cloudinaryService.GenerateUploadSignature(request);
        return Success(result, "Sinh chữ ký tải ảnh Cloudinary thành công.");
    }
}
