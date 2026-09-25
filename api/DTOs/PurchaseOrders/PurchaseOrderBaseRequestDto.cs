using System.ComponentModel.DataAnnotations;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.DTOs.PurchaseOrders;

public abstract class PurchaseOrderBaseRequestDto : IValidatableObject
{
    [Required(ErrorMessage = "Nhà cung cấp không được để trống.")]
    [Range(1, int.MaxValue, ErrorMessage = "Mã nhà cung cấp không hợp lệ.")]
    public int SupplierId { get; set; }

    public PurchaseOrderStatus Status { get; set; } = PurchaseOrderStatus.DRAFT;

    private string? _note;

    [MaxLength(1000, ErrorMessage = "Ghi chú phiếu nhập không được vượt quá 1000 ký tự.")]
    public string? Note
    {
        get => _note;
        set => _note = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    [Required(ErrorMessage = "Danh sách mặt hàng nhập kho không được để trống.")]
    [MinLength(1, ErrorMessage = "Phiếu nhập bắt buộc phải có ít nhất 1 mặt hàng.")]
    public List<PurchaseOrderItemCreateRequestDto> Items { get; set; } = new();

    public virtual IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        // 1. Kiểm tra trạng thái enum hợp lệ
        if (!Enum.IsDefined(typeof(PurchaseOrderStatus), Status))
        {
            yield return new ValidationResult(
                "Trạng thái phiếu nhập không hợp lệ.",
                [nameof(Status)]);
        }

        // 2. Kiểm tra danh sách mặt hàng không được null hoặc rỗng
        if (Items == null || Items.Count == 0)
        {
            yield return new ValidationResult(
                "Phiếu nhập bắt buộc phải có ít nhất 1 mặt hàng.",
                [nameof(Items)]);
            yield break;
        }

        // 3. Tự kiểm tra trùng lặp biến thể sản phẩm trong danh sách mặt hàng
        var seenVariantIds = new HashSet<int>();
        foreach (var item in Items)
        {
            if (item.VariantId > 0 && !seenVariantIds.Add(item.VariantId))
            {
                yield return new ValidationResult(
                    $"Phát hiện biến thể (VariantId = {item.VariantId}) bị trùng lặp trong phiếu nhập. Vui lòng cộng gộp số lượng vào cùng một dòng.",
                    [nameof(Items)]);
                break;
            }
        }
    }
}
