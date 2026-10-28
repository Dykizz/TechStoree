using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Invoices;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Services.Interfaces;

public interface IInvoiceService
{
    Task<PagedResult<InvoiceDto>> GetAllInvoicesAsync(InvoiceQueryFilter filter);
    Task<PagedResult<InvoiceDto>> GetMyInvoicesAsync(int userId, InvoiceQueryFilter filter);
    Task<InvoiceDto?> GetInvoiceByIdAsync(int invoiceId, int? userId = null);
    Task<InvoiceDto?> GetInvoiceByOrderIdAsync(int orderId, int? userId = null);
    Task<InvoiceStatisticsDto> GetInvoiceStatisticsAsync();

    /// <summary>
    /// Tự động khởi tạo Hóa đơn từ Đơn hàng khi khách đặt mua
    /// </summary>
    Task<Invoice> CreateInvoiceForOrderAsync(Order order, DateTime now);

    /// <summary>
    /// Đồng bộ trạng thái Hóa đơn theo tiến trình và thanh toán của Đơn hàng
    /// </summary>
    Task SyncInvoiceStatusWithOrderAsync(Order order, DateTime now);
}
