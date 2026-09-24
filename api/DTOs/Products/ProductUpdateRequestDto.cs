using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Variants;

namespace WebBanHang.Api.DTOs.Products;

public class ProductUpdateRequestDto : ProductBaseRequestDto, IValidatableObject
{
    // Danh sách biến thể cập nhật (tùy chọn: nếu gửi kèm thì cập nhật đồng bộ toàn bộ biến thể)
    [MinLength(1, ErrorMessage = "Mỗi sản phẩm bắt buộc phải có ít nhất 1 biến thể khi cập nhật danh sách biến thể.")]
    public List<ProductVariantUpsertRequestDto>? Variants { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (Variants == null) yield break;

        // 1. Tự kiểm tra trùng lặp VariantId trong payload gửi lên
        var duplicateVariantIds = Variants
            .Where(v => v.VariantId.HasValue && v.VariantId.Value > 0)
            .GroupBy(v => v.VariantId!.Value)
            .Where(g => g.Count() > 1)
            .Select(g => g.Key)
            .ToList();

        if (duplicateVariantIds.Count > 0)
        {
            yield return new ValidationResult(
                $"Phát hiện mã biến thể bị trùng lặp trong danh sách: {string.Join(", ", duplicateVariantIds)}.",
                [nameof(Variants)]);
        }

        // 2. Tự kiểm tra trùng lặp bộ thuộc tính (attributes signature) giữa các biến thể trong payload
        var variantSignatures = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var v in Variants)
        {
            var sig = VariantHelper.GetAttributesSignature(v.Attributes);
            if (!variantSignatures.Add(sig))
            {
                yield return new ValidationResult(
                    "Phát hiện các biến thể trong danh sách cập nhật có bộ thuộc tính trùng lặp nhau.",
                    [nameof(Variants)]);
                break;
            }
        }
    }
}
