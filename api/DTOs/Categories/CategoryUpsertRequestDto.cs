using System.ComponentModel.DataAnnotations;

namespace WebBanHang.Api.DTOs.Categories;

public class CategoryUpsertRequestDto
{
    [Required(ErrorMessage = "Tên danh mục không được để trống.")]
    [MaxLength(100, ErrorMessage = "Tên danh mục không được vượt quá 100 ký tự.")]
    public string CategoryName { get; set; } = string.Empty;
}
