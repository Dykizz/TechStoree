using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Suppliers;

namespace WebBanHang.Api.Services.Interfaces;

public interface ISupplierService
{
    Task<PagedResult<SupplierDto>> GetSuppliersAsync(PaginationParams filter);
    Task<SupplierDto> GetSupplierByIdAsync(int id);
    Task<SupplierDto> CreateSupplierAsync(SupplierUpsertRequestDto dto);
    Task<SupplierDto> UpdateSupplierAsync(int id, SupplierUpsertRequestDto dto);
    Task DeleteSupplierAsync(int id);
}
