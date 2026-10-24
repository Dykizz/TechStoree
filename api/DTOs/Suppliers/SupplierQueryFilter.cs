using WebBanHang.Api.Common;

namespace WebBanHang.Api.DTOs.Suppliers;

public class SupplierQueryFilter : PaginationParams
{
    /// <summary>
    /// Lọc trạng thái hợp tác: "all" (tất cả), "active" (đang hợp tác IsActive=true, mặc định), "inactive" hoặc "deleted" (ngừng hợp tác IsActive=false)
    /// </summary>
    public string? Status { get; set; }
}
