using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Suppliers;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class SupplierService(AppDbContext context) : ISupplierService
{
    public async Task<PagedResult<SupplierDto>> GetSuppliersAsync(PaginationParams filter)
    {
        var query = context.Suppliers.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim().ToLower();
            query = query.Where(s =>
                s.SupplierName.ToLower().Contains(search) ||
                s.Phone.Contains(search) ||
                (s.Email != null && s.Email.ToLower().Contains(search)) ||
                (s.Address != null && s.Address.ToLower().Contains(search)));
        }

        query = filter.SortBy?.ToLower() switch
        {
            "name" => filter.IsAscending ? query.OrderBy(s => s.SupplierName) : query.OrderByDescending(s => s.SupplierName),
            "phone" => filter.IsAscending ? query.OrderBy(s => s.Phone) : query.OrderByDescending(s => s.Phone),
            _ => filter.IsAscending ? query.OrderBy(s => s.SupplierId) : query.OrderByDescending(s => s.SupplierId)
        };

        return await query.ToPagedResultAsync(filter, s => s.ToSupplierDto());
    }

    public async Task<SupplierDto> GetSupplierByIdAsync(int id)
    {
        var supplier = await context.Suppliers.AsNoTracking()
            .FirstOrDefaultAsync(s => s.SupplierId == id)
            ?? throw new KeyNotFoundException($"Không tìm thấy nhà cung cấp với mã ID: {id}.");

        return supplier.ToSupplierDto();
    }

    public async Task<SupplierDto> CreateSupplierAsync(SupplierUpsertRequestDto dto)
    {
        var supplier = new Supplier
        {
            SupplierName = dto.SupplierName.Trim(),
            Phone = dto.Phone.Trim(),
            Email = string.IsNullOrWhiteSpace(dto.Email) ? null : dto.Email.Trim(),
            Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        context.Suppliers.Add(supplier);
        await context.SaveChangesAsync();

        return supplier.ToSupplierDto();
    }

    public async Task<SupplierDto> UpdateSupplierAsync(int id, SupplierUpsertRequestDto dto)
    {
        var supplier = await context.Suppliers.FindAsync(id)
            ?? throw new KeyNotFoundException($"Không tìm thấy nhà cung cấp với mã ID: {id}.");

        supplier.SupplierName = dto.SupplierName.Trim();
        supplier.Phone = dto.Phone.Trim();
        supplier.Email = string.IsNullOrWhiteSpace(dto.Email) ? null : dto.Email.Trim();
        supplier.Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim();

        await context.SaveChangesAsync();

        return supplier.ToSupplierDto();
    }

    public async Task DeleteSupplierAsync(int id)
    {
        var supplier = await context.Suppliers.FindAsync(id)
            ?? throw new KeyNotFoundException($"Không tìm thấy nhà cung cấp với mã ID: {id}.");

        supplier.DeletedAt = DateTime.UtcNow;
        await context.SaveChangesAsync();
    }
}
