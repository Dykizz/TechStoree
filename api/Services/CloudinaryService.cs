using System.Text.RegularExpressions;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using WebBanHang.Api.DTOs.Media;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public partial class CloudinaryService : ICloudinaryService
{
    private readonly Cloudinary? _cloudinary;
    private readonly Account? _account;
    private readonly string _defaultFolder;
    private readonly bool _isConfigured;

    [GeneratedRegex(@"^v\d+$", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex VersionRegex();

    public CloudinaryService()
    {
        // Chỉ lấy cấu hình trực tiếp từ biến môi trường (Environment Variables / file .env)
        var cloudinaryUrl = Environment.GetEnvironmentVariable("CLOUDINARY_URL");
        if (!string.IsNullOrWhiteSpace(cloudinaryUrl))
        {
            try
            {
                _cloudinary = new Cloudinary(cloudinaryUrl);
                _account = _cloudinary.Api.Account;
                _isConfigured = !string.IsNullOrWhiteSpace(_account?.Cloud) &&
                                !string.IsNullOrWhiteSpace(_account?.ApiKey) &&
                                !string.IsNullOrWhiteSpace(_account?.ApiSecret);
            }
            catch
            {
                _cloudinary = null;
                _account = null;
                _isConfigured = false;
            }
        }
        else
        {
            var cloudName = Environment.GetEnvironmentVariable("CLOUDINARY_CLOUD_NAME");
            var apiKey = Environment.GetEnvironmentVariable("CLOUDINARY_API_KEY");
            var apiSecret = Environment.GetEnvironmentVariable("CLOUDINARY_API_SECRET");

            if (!string.IsNullOrWhiteSpace(cloudName) &&
                !string.IsNullOrWhiteSpace(apiKey) &&
                !string.IsNullOrWhiteSpace(apiSecret))
            {
                try
                {
                    _account = new Account(cloudName, apiKey, apiSecret);
                    _cloudinary = new Cloudinary(_account);
                    _isConfigured = true;
                }
                catch
                {
                    _account = null;
                    _cloudinary = null;
                    _isConfigured = false;
                }
            }
            else
            {
                _account = null;
                _cloudinary = null;
                _isConfigured = false;
            }
        }

        _defaultFolder = Environment.GetEnvironmentVariable("CLOUDINARY_DEFAULT_FOLDER") ?? "techstore";
    }

    public CloudinarySignatureResponseDto GenerateUploadSignature(CloudinarySignatureRequestDto? request = null)
    {
        EnsureConfigured();

        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var folder = !string.IsNullOrWhiteSpace(request?.Folder) ? request.Folder.Trim() : _defaultFolder;

        var parameters = new SortedDictionary<string, object>
        {
            { "timestamp", timestamp }
        };

        if (!string.IsNullOrWhiteSpace(folder))
        {
            parameters.Add("folder", folder);
        }

        if (!string.IsNullOrWhiteSpace(request?.PublicId))
        {
            parameters.Add("public_id", request.PublicId.Trim());
        }

        var signature = _cloudinary!.Api.SignParameters(parameters);

        return new CloudinarySignatureResponseDto
        {
            Signature = signature,
            Timestamp = timestamp,
            ApiKey = _account!.ApiKey,
            CloudName = _account!.Cloud,
            Folder = folder,
            PublicId = request?.PublicId?.Trim(),
            UploadUrl = $"https://api.cloudinary.com/v1_1/{_account!.Cloud}/auto/upload"
        };
    }

    public async Task<DeleteMediaResponseDto> DeleteMediaAsync(string publicIdOrUrl)
    {
        if (!_isConfigured || _cloudinary == null)
        {
            return new DeleteMediaResponseDto
            {
                PublicId = publicIdOrUrl,
                Result = "ignored",
                Success = true,
                Message = "Cloudinary chưa được cấu hình, bỏ qua thao tác xóa tệp phương tiện."
            };
        }

        var publicId = ExtractPublicId(publicIdOrUrl);
        if (string.IsNullOrWhiteSpace(publicId))
        {
            return new DeleteMediaResponseDto
            {
                PublicId = string.Empty,
                Result = "ignored",
                Success = true,
                Message = "Tệp không thuộc hệ thống Cloudinary hoặc đường dẫn không hợp lệ, bỏ qua xóa."
            };
        }

        var deletionParams = new DeletionParams(publicId)
        {
            ResourceType = ResourceType.Image,
            Invalidate = true // Xóa cache trên toàn bộ CDN của Cloudinary
        };

        var result = await _cloudinary.DestroyAsync(deletionParams);

        if (result.Error != null)
        {
            return new DeleteMediaResponseDto
            {
                PublicId = publicId,
                Result = result.Error.Message,
                Success = false,
                Message = $"Lỗi từ Cloudinary: {result.Error.Message}"
            };
        }

        var resStr = result.Result ?? "unknown";
        var isSuccess = string.Equals(resStr, "ok", StringComparison.OrdinalIgnoreCase);

        return new DeleteMediaResponseDto
        {
            PublicId = publicId,
            Result = resStr,
            Success = isSuccess,
            Message = isSuccess
                ? "Xóa tệp phương tiện trên Cloudinary thành công."
                : $"Kết quả từ Cloudinary: {resStr} (Tệp không tồn tại hoặc đã bị xóa trước đó)."
        };
    }

    public string ExtractPublicId(string publicIdOrUrl)
    {
        if (string.IsNullOrWhiteSpace(publicIdOrUrl))
        {
            return string.Empty;
        }

        var trimmed = publicIdOrUrl.Trim();

        // Nếu là URL, chỉ xử lý nếu URL là của Cloudinary
        if (trimmed.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            trimmed.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            if (!Uri.TryCreate(trimmed, UriKind.Absolute, out var uri))
            {
                return string.Empty;
            }

            // Nếu URL không thuộc Cloudinary thì bỏ qua
            if (!uri.Host.Contains("cloudinary.com", StringComparison.OrdinalIgnoreCase))
            {
                return string.Empty;
            }

            // Định dạng URL Cloudinary: /<cloud_name>/image/upload/[transformations/][v<version>/]<folder>/<public_id>.<ext>
            var path = uri.AbsolutePath;
            const string uploadMarker = "/upload/";
            var uploadIndex = path.IndexOf(uploadMarker, StringComparison.OrdinalIgnoreCase);
            if (uploadIndex == -1)
            {
                return string.Empty;
            }

            var subPath = path[(uploadIndex + uploadMarker.Length)..];
            var segments = subPath.Split('/', StringSplitOptions.RemoveEmptyEntries);
            if (segments.Length == 0) return string.Empty;

            var startIndex = 0;
            while (startIndex < segments.Length)
            {
                var seg = segments[startIndex];

                // 1. Nếu là phiên bản (e.g. v1727938472)
                if (VersionRegex().IsMatch(seg))
                {
                    startIndex++;
                    break; // Sau mốc version luôn là phần bắt đầu của public_id
                }

                // 2. Nếu là các thông số transformation (e.g. c_fill,w_300,h_200,q_auto,f_auto)
                if (seg.Contains('_') || seg.Contains(','))
                {
                    startIndex++;
                    continue;
                }

                break;
            }

            var remainingSegments = segments.Skip(startIndex).ToArray();
            if (remainingSegments.Length == 0)
            {
                remainingSegments = segments;
            }

            var joined = string.Join('/', remainingSegments);
            var lastDot = joined.LastIndexOf('.');
            return lastDot > 0 ? joined[..lastDot] : joined;
        }

        // Nếu không phải URL thì xem như đã là public_id trực tiếp
        return trimmed;
    }

    private void EnsureConfigured()
    {
        if (!_isConfigured || _cloudinary == null || _account == null)
        {
            throw new BadRequestException("Hệ thống chưa được cấu hình tài khoản Cloudinary (Thiếu CloudName, ApiKey hoặc ApiSecret). Vui lòng cấu hình các biến môi trường CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET (hoặc CLOUDINARY_URL) trong file .env.");
        }
    }
}
