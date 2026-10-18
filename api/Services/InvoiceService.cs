using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Invoices;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class InvoiceService(AppDbContext dbContext) : IInvoiceService
{
    public async Task<PagedResult<InvoiceDto>> GetAllInvoicesAsync(InvoiceQueryFilter filter)
    {
        var query = BuildInvoiceQuery();
        query = ApplyInvoiceFilter(query, filter);
        return await query.ToPagedResultAsync(filter, i => i.ToInvoiceDto());
    }

    public async Task<PagedResult<InvoiceDto>> GetMyInvoicesAsync(int userId, InvoiceQueryFilter filter)
    {
        var query = BuildInvoiceQuery().Where(i => i.UserId == userId);
        query = ApplyInvoiceFilter(query, filter);
        return await query.ToPagedResultAsync(filter, i => i.ToInvoiceDto());
    }

    public async Task<InvoiceDto?> GetInvoiceByIdAsync(int invoiceId, int? userId = null)
    {
        var query = BuildInvoiceQuery().Where(i => i.InvoiceId == invoiceId);
        if (userId.HasValue)
        {
            query = query.Where(i => i.UserId == userId.Value);
        }

        var invoice = await query.FirstOrDefaultAsync();
        return invoice?.ToInvoiceDto();
    }

    public async Task<InvoiceDto?> GetInvoiceByOrderIdAsync(int orderId, int? userId = null)
    {
        var query = BuildInvoiceQuery().Where(i => i.OrderId == orderId);
        if (userId.HasValue)
        {
            query = query.Where(i => i.UserId == userId.Value);
        }

        var invoice = await query.FirstOrDefaultAsync();
        return invoice?.ToInvoiceDto();
    }

    public async Task<Invoice> CreateInvoiceForOrderAsync(Order order, DateTime now)
    {
        var existing = await dbContext.Invoices.FirstOrDefaultAsync(i => i.OrderId == order.OrderId);
        if (existing != null)
        {
            return existing;
        }

        var status = order.PaymentStatus == PaymentStatus.PAID ? InvoiceStatus.PAID : InvoiceStatus.UNPAID;

        var invoice = new Invoice
        {
            InvoiceCode = $"INV-{order.OrderCode}",
            OrderId = order.OrderId,
            UserId = order.UserId,
            TotalAmount = order.TotalAmount,
            Status = status,
            PaymentMethod = order.PaymentMethod,
            PaidAt = order.PaidAt,
            CreatedAt = now
        };

        dbContext.Invoices.Add(invoice);
        return invoice;
    }

    public async Task SyncInvoiceStatusWithOrderAsync(Order order, DateTime now)
    {
        var invoice = await dbContext.Invoices.FirstOrDefaultAsync(i => i.OrderId == order.OrderId);
        if (invoice != null)
        {
            if (order.OrderStatus == OrderStatus.CANCELLED || order.PaymentStatus == PaymentStatus.REFUNDED)
            {
                invoice.Status = InvoiceStatus.CANCELLED;
            }
            else if (order.PaymentStatus == PaymentStatus.PAID)
            {
                invoice.Status = InvoiceStatus.PAID;
                invoice.PaidAt ??= now;
            }
        }
    }

    private IQueryable<Invoice> BuildInvoiceQuery() =>
        dbContext.Invoices
            .AsNoTracking()
            .Include(i => i.Order)
            .Include(i => i.User);

    private static IQueryable<Invoice> ApplyInvoiceFilter(IQueryable<Invoice> query, InvoiceQueryFilter filter)
    {
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim().ToLower();
            query = query.Where(i =>
                i.InvoiceCode.ToLower().Contains(search) ||
                (i.Order != null && (i.Order.OrderCode.ToLower().Contains(search) || i.Order.ReceiverName.ToLower().Contains(search))) ||
                (i.Note != null && i.Note.ToLower().Contains(search)));
        }

        if (filter.Status.HasValue)
        {
            query = query.Where(i => i.Status == filter.Status.Value);
        }

        if (filter.PaymentMethod.HasValue)
        {
            query = query.Where(i => i.PaymentMethod == filter.PaymentMethod.Value);
        }

        if (filter.FromDate.HasValue)
        {
            var fromUtc = DateTime.SpecifyKind(filter.FromDate.Value.Date, DateTimeKind.Utc);
            query = query.Where(i => i.CreatedAt >= fromUtc);
        }

        if (filter.ToDate.HasValue)
        {
            var nextDayUtc = DateTime.SpecifyKind(filter.ToDate.Value.Date.AddDays(1), DateTimeKind.Utc);
            query = query.Where(i => i.CreatedAt < nextDayUtc);
        }

        return filter.SortBy?.ToLower() switch
        {
            "code" or "invoicecode" => filter.IsAscending ? query.OrderBy(i => i.InvoiceCode) : query.OrderByDescending(i => i.InvoiceCode),
            "amount" or "totalamount" => filter.IsAscending ? query.OrderBy(i => i.TotalAmount) : query.OrderByDescending(i => i.TotalAmount),
            "status" => filter.IsAscending ? query.OrderBy(i => i.Status) : query.OrderByDescending(i => i.Status),
            _ => filter.IsAscending ? query.OrderBy(i => i.CreatedAt) : query.OrderByDescending(i => i.CreatedAt)
        };
    }
}
