using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.PurchaseOrders;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class PurchaseOrderService(AppDbContext context) : IPurchaseOrderService
{
    public async Task<PagedResult<PurchaseOrderBaseDto>> GetPurchaseOrdersAsync(PurchaseOrderQueryFilter filter)
    {
        IQueryable<PurchaseOrder> query = context.PurchaseOrders
            .AsNoTracking()
            .Include(po => po.Supplier)
            .Include(po => po.CreatedByUser)
            .Include(po => po.Items);

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim().ToLower();
            query = query.Where(po =>
                po.PoCode.ToLower().Contains(search) ||
                (po.Supplier != null && po.Supplier.SupplierName.ToLower().Contains(search)) ||
                (po.Note != null && po.Note.ToLower().Contains(search)));
        }

        if (filter.Status.HasValue)
        {
            query = query.Where(po => po.Status == filter.Status.Value);
        }

        if (filter.SupplierId.HasValue)
        {
            query = query.Where(po => po.SupplierId == filter.SupplierId.Value);
        }

        if (filter.FromDate.HasValue)
        {
            var fromUtc = DateTime.SpecifyKind(filter.FromDate.Value.Date, DateTimeKind.Utc);
            query = query.Where(po => po.CreatedAt >= fromUtc);
        }

        if (filter.ToDate.HasValue)
        {
            var nextDayUtc = DateTime.SpecifyKind(filter.ToDate.Value.Date.AddDays(1), DateTimeKind.Utc);
            query = query.Where(po => po.CreatedAt < nextDayUtc);
        }

        query = filter.SortBy?.ToLower() switch
        {
            "code" => filter.IsAscending ? query.OrderBy(po => po.PoCode) : query.OrderByDescending(po => po.PoCode),
            "status" => filter.IsAscending ? query.OrderBy(po => po.Status) : query.OrderByDescending(po => po.Status),
            "totalcost" => filter.IsAscending ? query.OrderBy(po => po.TotalCost) : query.OrderByDescending(po => po.TotalCost),
            _ => filter.IsAscending ? query.OrderBy(po => po.CreatedAt) : query.OrderByDescending(po => po.CreatedAt)
        };

        return await query.ToPagedResultAsync(filter, po => po.ToPurchaseOrderBaseDto());
    }

    public async Task<PurchaseOrderDetailDto> GetPurchaseOrderByIdAsync(int id)
    {
        var po = await context.PurchaseOrders
            .AsNoTracking()
            .Include(po => po.Supplier)
            .Include(po => po.CreatedByUser)
            .Include(po => po.Items)
                .ThenInclude(i => i.Variant)
            .FirstOrDefaultAsync(po => po.PurchaseOrderId == id)
            ?? throw new NotFoundException($"Không tìm thấy phiếu nhập hàng với mã ID: {id}.");

        return po.ToPurchaseOrderDetailDto();
    }

    public async Task<PurchaseOrderDetailDto> CreatePurchaseOrderAsync(int currentUserId, PurchaseOrderCreateRequestDto dto)
    {
        // 1. Kiểm tra tài khoản nhân sự lập phiếu
        var user = await context.Users.FindAsync(currentUserId)
            ?? throw new UnauthorizedException("Không tìm thấy thông tin tài khoản người lập phiếu.");

        if (user.IsLocked)
        {
            throw new ForbiddenException("Tài khoản của bạn đã bị khóa, không thể lập phiếu nhập hàng.");
        }

        // 2. Kiểm tra Nhà cung cấp
        var supplierExists = await context.Suppliers
            .AnyAsync(s => s.SupplierId == dto.SupplierId && s.DeletedAt == null);
        if (!supplierExists)
        {
            throw new NotFoundException($"Không tìm thấy nhà cung cấp với mã ID: {dto.SupplierId}.");
        }

        // 3. Kiểm tra tính hợp lệ của các biến thể
        var variants = await ValidateAndGetVariantsAsync(dto.Items.Select(i => i.VariantId));

        // 4. Sinh mã phiếu tự động: PO-yyyyMMdd-XXX
        var today = DateTime.UtcNow.Date;
        var tomorrow = today.AddDays(1);
        var countToday = await context.PurchaseOrders
            .CountAsync(p => p.CreatedAt >= today && p.CreatedAt < tomorrow);
        var poCode = $"PO-{DateTime.UtcNow:yyyyMMdd}-{(countToday + 1):D3}";

        // 5. Xác định trạng thái tạo mới qua Enum (DRAFT hoặc COMPLETED)
        var isCompleted = dto.Status == PurchaseOrderStatus.COMPLETED;
        var totalCost = dto.Items.Sum(i => i.ImportPrice * i.Quantity);

        using var transaction = await context.Database.BeginTransactionAsync();
        try
        {
            var po = new PurchaseOrder
            {
                PoCode = poCode,
                SupplierId = dto.SupplierId,
                CreatedByUserId = currentUserId,
                TotalCost = totalCost,
                Status = dto.Status,
                Note = dto.Note,
                CreatedAt = DateTime.UtcNow
            };

            var variantMap = variants.ToDictionary(v => v.VariantId);
            foreach (var itemDto in dto.Items)
            {
                po.Items.Add(new PurchaseOrderItem
                {
                    VariantId = itemDto.VariantId,
                    ImportPrice = itemDto.ImportPrice,
                    Quantity = itemDto.Quantity
                });

                // Nếu người dùng chọn tạo phiếu COMPLETED ngay từ đầu -> Cộng dồn tồn kho
                if (isCompleted)
                {
                    var variant = variantMap[itemDto.VariantId];
                    variant.StockQuantity += itemDto.Quantity;
                }
            }

            context.PurchaseOrders.Add(po);
            await context.SaveChangesAsync();
            await transaction.CommitAsync();

            return await GetPurchaseOrderByIdAsync(po.PurchaseOrderId);
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    public async Task<PurchaseOrderDetailDto> UpdatePurchaseOrderAsync(int id, PurchaseOrderUpdateRequestDto dto)
    {
        // 1. Tìm phiếu nhập kèm danh sách chi tiết
        var po = await context.PurchaseOrders
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.PurchaseOrderId == id)
            ?? throw new NotFoundException($"Không tìm thấy phiếu nhập hàng với mã ID: {id}.");

        // 2. Chặn sửa nếu phiếu ĐANG Ở TRẠNG THÁI COMPLETED
        if (po.Status == PurchaseOrderStatus.COMPLETED)
        {
            throw new BadRequestException("Phiếu nhập đã hoàn thành (COMPLETED), không được phép chỉnh sửa.");
        }

        // 3. Kiểm tra Nhà cung cấp
        var supplierExists = await context.Suppliers
            .AnyAsync(s => s.SupplierId == dto.SupplierId && s.DeletedAt == null);
        if (!supplierExists)
        {
            throw new NotFoundException($"Không tìm thấy nhà cung cấp với mã ID: {dto.SupplierId}.");
        }

        // 4. Kiểm tra các biến thể nhập
        var variants = await ValidateAndGetVariantsAsync(dto.Items.Select(i => i.VariantId));
        var variantMap = variants.ToDictionary(v => v.VariantId);

        // 5. Xác định trạng thái mới sau khi update
        var isCompleting = dto.Status == PurchaseOrderStatus.COMPLETED;

        using var transaction = await context.Database.BeginTransactionAsync();
        try
        {
            // Cập nhật thông tin phiếu
            po.SupplierId = dto.SupplierId;
            po.Note = dto.Note;
            po.TotalCost = dto.Items.Sum(i => i.ImportPrice * i.Quantity);

            // Thay thế danh sách chi tiết cũ bằng danh sách mới
            context.PurchaseOrderItems.RemoveRange(po.Items);
            po.Items.Clear();

            foreach (var itemDto in dto.Items)
            {
                po.Items.Add(new PurchaseOrderItem
                {
                    PurchaseOrderId = po.PurchaseOrderId,
                    VariantId = itemDto.VariantId,
                    ImportPrice = itemDto.ImportPrice,
                    Quantity = itemDto.Quantity
                });

                // Nếu người dùng chọn chuyển trạng thái từ DRAFT sang COMPLETED -> Cộng dồn tồn kho
                if (isCompleting)
                {
                    var variant = variantMap[itemDto.VariantId];
                    variant.StockQuantity += itemDto.Quantity;
                }
            }

            po.Status = dto.Status;

            await context.SaveChangesAsync();
            await transaction.CommitAsync();

            return await GetPurchaseOrderByIdAsync(po.PurchaseOrderId);
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    public async Task DeletePurchaseOrderAsync(int id)
    {
        var po = await context.PurchaseOrders
            .FirstOrDefaultAsync(p => p.PurchaseOrderId == id)
            ?? throw new NotFoundException($"Không tìm thấy phiếu nhập hàng với mã ID: {id}.");

        // Chỉ cho phép xóa khi đang là DRAFT
        if (po.Status != PurchaseOrderStatus.DRAFT)
        {
            throw new BadRequestException("Chỉ được phép xóa phiếu nhập ở trạng thái bản nháp (DRAFT). Phiếu đã hoàn thành không thể xóa.");
        }

        context.PurchaseOrders.Remove(po);
        await context.SaveChangesAsync();
    }

    private async Task<List<ProductVariant>> ValidateAndGetVariantsAsync(IEnumerable<int> variantIdList)
    {
        var variantIds = variantIdList.Distinct().ToList();
        var variants = await context.ProductVariants
            .Where(v => variantIds.Contains(v.VariantId))
            .ToListAsync();

        var missingIds = variantIds.Except(variants.Select(v => v.VariantId)).ToList();
        if (missingIds.Count > 0)
        {
            throw new NotFoundException($"Không tìm thấy các biến thể sản phẩm có mã: {string.Join(", ", missingIds)}.");
        }

        var inactiveVariants = variants.Where(v => !v.IsActive).ToList();
        if (inactiveVariants.Count > 0)
        {
            var names = string.Join(", ", inactiveVariants.Select(v => v.VariantName));
            throw new BadRequestException($"Các biến thể sau đã ngưng kinh doanh, không thể nhập hàng: {names}.");
        }

        return variants;
    }
}
