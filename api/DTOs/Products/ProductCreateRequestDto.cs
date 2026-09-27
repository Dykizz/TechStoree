using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Variants;

namespace WebBanHang.Api.DTOs.Products;

public class ProductCreateRequestDto : ProductBaseRequestDto, IValidatableObject
{
    /// <summary>
    /// Danh sách các biến thể của sản phẩm (bắt buộc ít nhất 1 biến thể, không truyền VariantId khi tạo mới)
    /// </summary>
    [Required(ErrorMessage = "Danh sách biến thể không được để trống.")]
    [MinLength(1, ErrorMessage = "Mỗi sản phẩm bắt buộc phải có ít nhất 1 biến thể.")]
    public List<ProductVariantUpsertRequestDto> Variants { get; set; } = new();

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        // 1. Kiểm tra không được gửi VariantId khi tạo mới sản phẩm
        var hasVariantId = Variants.Any(v => v.VariantId.HasValue && v.VariantId.Value > 0);
        if (hasVariantId)
        {
            yield return new ValidationResult(
                "Không được truyền mã biến thể (VariantId) khi tạo mới sản phẩm.",
                [nameof(Variants)]);
        }

        // 2. Tự kiểm tra trùng lặp bộ thuộc tính giữa các biến thể trong danh sách tạo mới
        var variantSignatures = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var v in Variants)
        {
            var sig = VariantHelper.GetAttributesSignature(v.Attributes);
            if (!variantSignatures.Add(sig))
            {
                yield return new ValidationResult(
                    "Phát hiện các biến thể trong danh sách tạo mới có bộ thuộc tính trùng lặp nhau.",
                    [nameof(Variants)]);
                break;
            }
        }
    }
}
