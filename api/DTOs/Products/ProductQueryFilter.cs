using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Products;

public class ProductQueryFilter : PaginationParams
{
    public int? CategoryId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public bool? IsActive { get; set; }
}
