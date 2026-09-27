using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.PurchaseOrders;

namespace WebBanHang.Api.Services.Interfaces;

public interface IPurchaseOrderService
{
    Task<PagedResult<PurchaseOrderBaseDto>> GetPurchaseOrdersAsync(PurchaseOrderQueryFilter filter);
    Task<PurchaseOrderDetailDto> GetPurchaseOrderByIdAsync(int id);
    Task<PurchaseOrderDetailDto> CreatePurchaseOrderAsync(int currentUserId, PurchaseOrderCreateRequestDto dto);
    Task<PurchaseOrderDetailDto> UpdatePurchaseOrderAsync(int id, PurchaseOrderUpdateRequestDto dto);
    Task DeletePurchaseOrderAsync(int id);
}
