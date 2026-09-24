using WebBanHang.Api.DTOs.Variants;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Common;

public static class VariantHelper
{
    /// <summary>
    /// Tạo chữ ký chuẩn hóa từ bộ thuộc tính để so sánh trùng lặp
    /// Các key và value được chuẩn hóa (trim, lowercase) và sắp xếp theo bảng chữ cái.
    /// </summary>
    public static string GetAttributesSignature(IDictionary<string, string>? dict)
    {
        if (dict == null || dict.Count == 0) return string.Empty;

        return string.Join(";", dict
            .OrderBy(kv => kv.Key, StringComparer.OrdinalIgnoreCase)
            .Select(kv => $"{kv.Key.Trim().ToLower()}={kv.Value.Trim().ToLower()}"));
    }

    /// <summary>
    /// Tự động sinh tên biến thể trực quan từ các giá trị thuộc tính (VD: "Đen - 128GB" hoặc "Phiên bản tiêu chuẩn")
    /// </summary>
    public static string GenerateVariantName(IDictionary<string, string>? attributes)
    {
        if (attributes == null || attributes.Count == 0)
        {
            return "Phiên bản tiêu chuẩn";
        }

        var values = attributes.Values
            .Where(v => !string.IsNullOrWhiteSpace(v))
            .Select(v => v.Trim())
            .ToList();

        return values.Count > 0 
            ? string.Join(" - ", values) 
            : "Phiên bản tiêu chuẩn";
    }

    /// <summary>
    /// Kiểm tra tính hợp lệ và sự đầy đủ của các thuộc tính bắt buộc đối với biến thể
    /// </summary>
    public static void ValidateRequiredAttributes(IReadOnlyList<string>? requiredAttributes, IDictionary<string, string>? variantAttributes)
    {
        if (requiredAttributes == null || requiredAttributes.Count == 0) return;

        if (variantAttributes == null || variantAttributes.Count == 0)
        {
            throw new BadRequestException($"Biến thể phải cung cấp đầy đủ các thuộc tính: {string.Join(", ", requiredAttributes)}.");
        }

        var missingKeys = requiredAttributes
            .Where(attr => !variantAttributes.ContainsKey(attr) || string.IsNullOrWhiteSpace(variantAttributes[attr]))
            .ToList();

        if (missingKeys.Count > 0)
        {
            throw new BadRequestException($"Biến thể còn thiếu các thuộc tính bắt buộc: {string.Join(", ", missingKeys)}.");
        }
    }

    /// <summary>
    /// Kiểm tra tính hợp lệ của toàn bộ danh sách biến thể (thuộc tính bắt buộc và không trùng lặp bộ thuộc tính)
    /// </summary>
    public static void ValidateVariantList(IReadOnlyList<string>? requiredAttributes, IEnumerable<ProductVariantUpsertRequestDto> variants)
    {
        var variantSignatures = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var v in variants)
        {
            ValidateRequiredAttributes(requiredAttributes, v.Attributes);

            var sig = GetAttributesSignature(v.Attributes);
            if (!variantSignatures.Add(sig))
            {
                throw new BadRequestException("Phát hiện các biến thể trong danh sách có bộ thuộc tính trùng lặp nhau.");
            }
        }
    }

    /// <summary>
    /// Chuyển đổi DTO biến thể sang thực thể ProductVariant mới
    /// </summary>
    public static ProductVariant ToEntity(this ProductVariantUpsertRequestDto dto, int productId = 0)
    {
        return new ProductVariant
        {
            ProductId = productId,
            VariantName = GenerateVariantName(dto.Attributes),
            Price = dto.Price,
            StockQuantity = 0,
            ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim(),
            Attributes = dto.Attributes != null 
                ? new Dictionary<string, string>(dto.Attributes, StringComparer.OrdinalIgnoreCase) 
                : new Dictionary<string, string>(),
            IsActive = dto.IsActive ?? true,
            CreatedAt = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Cập nhật thông tin của thực thể ProductVariant hiện có từ DTO
    /// </summary>
    public static void UpdateEntity(this ProductVariant entity, ProductVariantUpsertRequestDto dto)
    {
        entity.Price = dto.Price;
        entity.ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim();
        entity.Attributes = dto.Attributes != null 
            ? new Dictionary<string, string>(dto.Attributes, StringComparer.OrdinalIgnoreCase) 
            : new Dictionary<string, string>();
        entity.VariantName = GenerateVariantName(dto.Attributes);

        if (dto.IsActive.HasValue)
        {
            entity.IsActive = dto.IsActive.Value;
        }
    }
}
