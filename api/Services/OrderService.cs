using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Orders;
using WebBanHang.Api.DTOs.Vouchers;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class OrderService(AppDbContext dbContext, IVoucherService voucherService) : IOrderService
{
    public async Task<CheckoutPreviewDto> PreviewCheckoutAsync(int userId, CheckoutPreviewRequestDto request)
    {
        var now = DateTime.UtcNow;

        var cart = await dbContext.Carts
            .AsNoTracking()
            .Include(c => c.Items)
                .ThenInclude(i => i.Variant)
                    .ThenInclude(v => v!.Product)
            .Include(c => c.Items)
                .ThenInclude(i => i.Variant)
                    .ThenInclude(v => v!.Promotions)
            .FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new NotFoundException("Không tìm thấy giỏ hàng của người dùng.");

        var selectedItems = FilterSelectedCartItems(cart.Items, request.CartItemIds);
        if (selectedItems.Count == 0)
        {
            throw new BadRequestException("Giỏ hàng của bạn đang trống hoặc không có sản phẩm nào được chọn.");
        }

        var previewItems = new List<CheckoutItemPreviewDto>(selectedItems.Count);

        foreach (var item in selectedItems)
        {
            var variant = item.Variant
                ?? throw new BadRequestException($"Không tìm thấy thông tin biến thể sản phẩm (Mã {item.VariantId}).");

            var (unitPrice, promoDiscount, promoId, promoName) = CalculateItemPricing(variant, now);

            previewItems.Add(new CheckoutItemPreviewDto
            {
                CartItemId = item.CartItemId,
                VariantId = variant.VariantId,
                ProductId = variant.ProductId,
                ProductName = variant.Product?.ProductName ?? variant.VariantName,
                VariantName = variant.VariantName,
                ImageUrl = variant.GetDisplayImageUrl(),
                OriginalPrice = variant.Price,
                UnitPrice = unitPrice,
                PromotionId = promoId,
                PromotionName = promoName,
                PromotionDiscount = promoDiscount,
                Quantity = item.Quantity,
                StockQuantity = variant.StockQuantity
            });
        }

        decimal subtotal = previewItems.Sum(i => i.TotalPrice);
        decimal voucherDiscount = 0;
        string? voucherCode = null;
        string? voucherTitle = null;
        string? voucherMsg = null;

        if (!string.IsNullOrWhiteSpace(request.VoucherCode))
        {
            var applyResult = await voucherService.ApplyVoucherAsync(new ApplyVoucherRequestDto
            {
                Code = request.VoucherCode,
                SubtotalAmount = subtotal
            }, userId);

            voucherMsg = applyResult.Message;
            if (applyResult.IsValid)
            {
                voucherCode = applyResult.Code;
                voucherTitle = applyResult.Title;
                voucherDiscount = applyResult.DiscountAmount;
            }
        }

        decimal totalAmount = Math.Max(0, subtotal - voucherDiscount);

        return new CheckoutPreviewDto
        {
            Items = previewItems,
            VoucherCode = voucherCode,
            VoucherTitle = voucherTitle,
            VoucherDiscountAmount = voucherDiscount,
            TotalAmount = totalAmount,
            VoucherMessage = voucherMsg
        };
    }

    public async Task<OrderDetailDto> CreateOrderAsync(int userId, CreateOrderRequestDto request)
    {
        var now = DateTime.UtcNow;

        await using var transaction = await dbContext.Database.BeginTransactionAsync();

        // 1. Tải giỏ hàng cùng đầy đủ liên kết để trừ tồn kho và xóa mặt hàng
        var cart = await dbContext.Carts
            .Include(c => c.Items)
                .ThenInclude(i => i.Variant)
                    .ThenInclude(v => v!.Product)
            .Include(c => c.Items)
                .ThenInclude(i => i.Variant)
                    .ThenInclude(v => v!.Promotions)
            .FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new NotFoundException("Không tìm thấy giỏ hàng của bạn.");

        var selectedItems = FilterSelectedCartItems(cart.Items, request.CartItemIds);
        if (selectedItems.Count == 0)
        {
            throw new BadRequestException("Giỏ hàng của bạn đang trống hoặc không có sản phẩm nào được chọn để thanh toán.");
        }

        // 2. Sắp xếp theo VariantId (ngăn chặn Deadlock khi nhiều người cùng mua) & Trừ kho nguyên tử
        var orderedItems = selectedItems.OrderBy(i => i.VariantId).ToList();
        var orderItems = new List<OrderItem>(orderedItems.Count);

        foreach (var item in orderedItems)
        {
            var variant = item.Variant
                ?? throw new BadRequestException($"Không tìm thấy dữ liệu biến thể sản phẩm (Mã {item.VariantId}).");

            if (!variant.IsActive || (variant.Product != null && !variant.Product.IsActive))
            {
                throw new BadRequestException($"Sản phẩm '{variant.Product?.ProductName ?? variant.VariantName}' hiện đang tạm ngừng kinh doanh.");
            }

            // Trừ tồn kho nguyên tử (Atomic Update) - Khóa dòng trực tiếp ở Postgres:
            // Nếu 2 người mua cùng lúc, ai đến trước sẽ trừ trước, người sau thấy StockQuantity không đủ sẽ fail ngay lập tức
            var affectedRows = await dbContext.ProductVariants
                .Where(v => v.VariantId == variant.VariantId && v.StockQuantity >= item.Quantity)
                .ExecuteUpdateAsync(s => s.SetProperty(v => v.StockQuantity, v => v.StockQuantity - item.Quantity));

            if (affectedRows == 0)
            {
                throw new BadRequestException($"Sản phẩm '{variant.Product?.ProductName ?? variant.VariantName}' vừa hết hàng hoặc không đủ số lượng tồn kho để đặt.");
            }

            // Tính giá snapshot theo Promotion đang hoạt động
            var (unitPrice, promoDiscount, promoId, promoName) = CalculateItemPricing(variant, now);

            orderItems.Add(new OrderItem
            {
                VariantId = variant.VariantId,
                ProductName = variant.Product?.ProductName ?? variant.VariantName,
                VariantName = variant.VariantName,
                ImageUrl = variant.GetDisplayImageUrl(),
                OriginalPrice = variant.Price,
                UnitPrice = unitPrice,
                PromotionId = promoId,
                PromotionName = promoName,
                PromotionDiscount = promoDiscount,
                Quantity = item.Quantity,
                TotalPrice = unitPrice * item.Quantity
            });
        }


        // 3. Tính tổng tiền hàng (Subtotal)
        decimal subtotal = orderItems.Sum(oi => oi.TotalPrice);

        // 4. Xử lý Voucher áp dụng toàn bill
        Voucher? voucher = null;
        UserVoucher? userVoucher = null;
        decimal voucherDiscount = 0;

        if (!string.IsNullOrWhiteSpace(request.VoucherCode))
        {
            var cleanCode = request.VoucherCode.Trim().ToUpperInvariant();
            voucher = await dbContext.Vouchers.FirstOrDefaultAsync(v => v.Code == cleanCode)
                ?? throw new BadRequestException($"Mã giảm giá '{cleanCode}' không tồn tại trên hệ thống.");

            ValidateVoucherForCheckout(voucher, subtotal, now);

            // Kiểm tra số lần sử dụng của User
            var userUsageCount = await dbContext.UserVouchers
                .CountAsync(uv => uv.UserId == userId && uv.VoucherId == voucher.VoucherId && uv.IsUsed);

            if (userUsageCount >= voucher.LimitPerUser)
            {
                throw new BadRequestException($"Bạn đã sử dụng hết giới hạn {voucher.LimitPerUser} lần cho mã giảm giá này.");
            }

            // Tính số tiền giảm giá bill
            voucherDiscount = voucher.CalculateDiscount(subtotal);

            // Tìm hoặc thêm vào ví để đánh dấu đã sử dụng
            userVoucher = await dbContext.UserVouchers
                .FirstOrDefaultAsync(uv => uv.UserId == userId && uv.VoucherId == voucher.VoucherId && !uv.IsUsed);

            if (userVoucher == null)
            {
                userVoucher = new UserVoucher
                {
                    UserId = userId,
                    VoucherId = voucher.VoucherId,
                    AssignedType = VoucherAssignedType.CLAIMED,
                    AssignedAt = now
                };
                dbContext.UserVouchers.Add(userVoucher);
            }

            // Cập nhật lượt dùng voucher nguyên tử (Atomic Update chống Race Condition khi voucher sắp hết)
            var voucherUpdated = await dbContext.Vouchers
                .Where(v => v.VoucherId == voucher.VoucherId && (!v.UsageLimit.HasValue || v.UsedCount < v.UsageLimit.Value))
                .ExecuteUpdateAsync(s => s.SetProperty(v => v.UsedCount, v => v.UsedCount + 1));

            if (voucherUpdated == 0)
            {
                throw new BadRequestException("Mã giảm giá đã hết lượt sử dụng trên toàn hệ thống.");
            }

            userVoucher.IsUsed = true;
            userVoucher.UsedAt = now;

        }

        // 5. Tạo đơn hàng mới
        decimal totalAmount = Math.Max(0, subtotal - voucherDiscount);
        string orderCode = $"ORD-{now:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}";

        var order = new Order
        {
            OrderCode = orderCode,
            UserId = userId,
            ReceiverName = request.ReceiverName.Trim(),
            ReceiverPhone = request.ReceiverPhone.Trim(),
            ShippingAddress = request.ShippingAddress.Trim(),
            Notes = request.Notes?.Trim(),
            OrderStatus = OrderStatus.PENDING,
            PaymentMethod = request.PaymentMethod,
            PaymentStatus = PaymentStatus.PENDING,
            SubtotalAmount = subtotal,
            VoucherId = voucher?.VoucherId,
            VoucherCode = voucher?.Code,
            VoucherTitle = voucher?.Title,
            VoucherDiscountAmount = voucherDiscount,
            TotalAmount = totalAmount,
            CreatedAt = now,
            UpdatedAt = now,
            Items = orderItems
        };

        dbContext.Orders.Add(order);
        await dbContext.SaveChangesAsync();

        // Gắn order_id vào user_voucher sau khi đã sinh order.OrderId
        if (userVoucher != null)
        {
            userVoucher.OrderId = order.OrderId;
        }

        // 6. Xóa các món đã mua khỏi giỏ hàng
        foreach (var item in selectedItems)
        {
            cart.Items.Remove(item);
            dbContext.CartItems.Remove(item);
        }

        cart.UpdatedAt = now;
        await dbContext.SaveChangesAsync();

        await transaction.CommitAsync();

        return (await GetOrderByIdAsync(order.OrderId))!;
    }

    public async Task<PagedResult<OrderBaseDto>> GetMyOrdersAsync(int userId, OrderQueryFilter? filter = null)
    {
        var query = dbContext.Orders
            .AsNoTracking()
            .Include(o => o.Items)
            .Where(o => o.UserId == userId);

        query = ApplyOrderFilter(query, filter);
        return await query.ToPagedResultAsync(filter ?? new OrderQueryFilter(), o => o.ToOrderBaseDto());
    }

    public async Task<PagedResult<OrderBaseDto>> GetAllOrdersAsync(OrderQueryFilter? filter = null)
    {
        var query = dbContext.Orders
            .AsNoTracking()
            .Include(o => o.Items)
            .AsQueryable();

        query = ApplyOrderFilter(query, filter);
        return await query.ToPagedResultAsync(filter ?? new OrderQueryFilter(), o => o.ToOrderBaseDto());
    }

    public async Task<OrderDetailDto?> GetOrderByIdAsync(int orderId, int? userId = null)
    {
        var query = BuildOrderDetailQuery().Where(o => o.OrderId == orderId);
        if (userId.HasValue)
        {
            query = query.Where(o => o.UserId == userId.Value);
        }

        var order = await query.FirstOrDefaultAsync();
        return order?.ToOrderDetailDto();
    }

    public async Task<OrderDetailDto?> GetOrderByCodeAsync(string orderCode, int? userId = null)
    {
        var cleanCode = orderCode.Trim();
        var query = BuildOrderDetailQuery().Where(o => o.OrderCode == cleanCode);
        if (userId.HasValue)
        {
            query = query.Where(o => o.UserId == userId.Value);
        }

        var order = await query.FirstOrDefaultAsync();
        return order?.ToOrderDetailDto();
    }

    public async Task<OrderDetailDto> CancelOrderAsync(int orderId, int? userId, CancelOrderRequestDto request, bool isAdmin = false)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync();

        var order = await dbContext.Orders
            .Include(o => o.Items)
                .ThenInclude(i => i.Variant)
            .Include(o => o.Voucher)
            .FirstOrDefaultAsync(o => o.OrderId == orderId)
            ?? throw new NotFoundException($"Không tìm thấy đơn hàng có mã ID = {orderId}.");

        if (!isAdmin && userId.HasValue && order.UserId != userId.Value)
        {
            throw new ForbiddenException("Bạn không có quyền thực hiện thao tác hủy đơn hàng này.");
        }

        if (order.OrderStatus == OrderStatus.CANCELLED)
        {
            throw new BadRequestException("Đơn hàng này đã bị hủy trước đó.");
        }

        if (order.OrderStatus != OrderStatus.PENDING && order.OrderStatus != OrderStatus.CONFIRMED)
        {
            throw new BadRequestException($"Không thể hủy đơn hàng đang ở trạng thái {order.OrderStatus}. Chỉ cho phép hủy khi đơn ở trạng thái Chờ xử lý hoặc Đã xác nhận.");
        }

        var now = DateTime.UtcNow;

        // 1. Hoàn trả tồn kho nguyên tử cho từng biến thể
        foreach (var item in order.Items)
        {
            await dbContext.ProductVariants
                .Where(v => v.VariantId == item.VariantId)
                .ExecuteUpdateAsync(s => s.SetProperty(v => v.StockQuantity, v => v.StockQuantity + item.Quantity));
        }

        // 2. Hoàn trả Voucher vào ví nếu có
        if (order.VoucherId.HasValue)
        {
            var userVoucher = await dbContext.UserVouchers
                .FirstOrDefaultAsync(uv => uv.OrderId == order.OrderId);

            if (userVoucher != null)
            {
                userVoucher.IsUsed = false;
                userVoucher.UsedAt = null;
                userVoucher.OrderId = null;
            }

            await dbContext.Vouchers
                .Where(v => v.VoucherId == order.VoucherId.Value && v.UsedCount > 0)
                .ExecuteUpdateAsync(s => s.SetProperty(v => v.UsedCount, v => v.UsedCount - 1));
        }


        // 3. Cập nhật trạng thái hủy
        order.OrderStatus = OrderStatus.CANCELLED;
        order.CancelledAt = now;
        order.CancellationReason = request.Reason.Trim();
        order.UpdatedAt = now;

        if (order.PaymentStatus == PaymentStatus.PAID)
        {
            order.PaymentStatus = PaymentStatus.REFUNDED;
        }

        await dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        return (await GetOrderByIdAsync(order.OrderId))!;
    }

    public async Task<OrderDetailDto> UpdateOrderStatusAsync(int orderId, UpdateOrderStatusDto request)
    {
        var order = await dbContext.Orders
            .Include(o => o.Items)
                .ThenInclude(i => i.Variant)
            .Include(o => o.Voucher)
            .FirstOrDefaultAsync(o => o.OrderId == orderId)
            ?? throw new NotFoundException($"Không tìm thấy đơn hàng có mã ID = {orderId}.");

        // Không cho phép đổi trạng thái nếu đơn đã bị hủy
        if (order.OrderStatus == OrderStatus.CANCELLED)
        {
            throw new BadRequestException("Không thể cập nhật trạng thái cho đơn hàng đã bị hủy.");
        }

        // Đơn đã giao thành công không được chuyển ngược về trạng thái trước
        if (order.OrderStatus == OrderStatus.DELIVERED && request.Status != OrderStatus.DELIVERED)
        {
            throw new BadRequestException("Đơn hàng đã giao thành công không thể chuyển về trạng thái trước đó.");
        }

        // Nếu chuyển sang CANCELLED, gọi qua nghiệp vụ CancelOrderAsync để hoàn kho và voucher
        if (request.Status == OrderStatus.CANCELLED)
        {
            return await CancelOrderAsync(orderId, null, new CancelOrderRequestDto
            {
                Reason = request.Reason ?? "Quản trị viên hủy đơn hàng"
            }, isAdmin: true);
        }

        var now = DateTime.UtcNow;
        order.OrderStatus = request.Status;
        order.UpdatedAt = now;

        if (request.PaymentStatus.HasValue)
        {
            order.PaymentStatus = request.PaymentStatus.Value;
            if (order.PaymentStatus == PaymentStatus.PAID && !order.PaidAt.HasValue)
            {
                order.PaidAt = now;
            }
        }
        else if (request.Status == OrderStatus.DELIVERED && order.PaymentMethod == PaymentMethod.COD)
        {
            order.PaymentStatus = PaymentStatus.PAID;
            order.PaidAt = now;
        }

        await dbContext.SaveChangesAsync();
        return (await GetOrderByIdAsync(order.OrderId))!;
    }

  
    private static List<CartItem> FilterSelectedCartItems(IEnumerable<CartItem> items, List<int>? selectedIds)
    {
        var enumerable = items.AsEnumerable();
        if (selectedIds != null && selectedIds.Count > 0)
        {
            enumerable = enumerable.Where(i => selectedIds.Contains(i.CartItemId));
        }
        return enumerable.ToList();
    }

    // Tính toán giá bán sau khuyến mãi (Promotion) tại thời điểm chỉ định
    private static (decimal unitPrice, decimal promoDiscount, int? promoId, string? promoName) CalculateItemPricing(ProductVariant variant, DateTime now)
    {
        var activePromo = variant.GetActivePromotion(now);
        if (activePromo == null)
        {
            return (variant.Price, 0, null, null);
        }

        var (calcPrice, disc) = MappingExtensions.CalculatePromotionalPrice(variant.Price, activePromo.DiscountType, activePromo.DiscountValue);
        return (calcPrice, disc, activePromo.PromotionId, activePromo.Name);
    }


    // Kiểm tra tính hợp lệ cơ bản của Voucher khi đặt hàng
    private static void ValidateVoucherForCheckout(Voucher voucher, decimal subtotal, DateTime now)
    {
        if (!voucher.IsActive)
        {
            throw new BadRequestException("Mã giảm giá này hiện đang tạm khóa hoặc đã ngưng áp dụng.");
        }

        if (now < voucher.StartDate)
        {
            throw new BadRequestException($"Mã giảm giá chỉ có hiệu lực từ ngày {voucher.StartDate:dd/MM/yyyy HH:mm}.");
        }

        if (now > voucher.EndDate)
        {
            throw new BadRequestException("Mã giảm giá đã hết hạn sử dụng.");
        }

        if (voucher.UsageLimit.HasValue && voucher.UsedCount >= voucher.UsageLimit.Value)
        {
            throw new BadRequestException("Mã giảm giá đã hết lượt sử dụng trên hệ thống.");
        }

        if (subtotal < voucher.MinOrderValue)
        {
            throw new BadRequestException($"Đơn hàng tối thiểu phải từ {voucher.MinOrderValue:N0} VNĐ để áp dụng mã này.");
        }
    }

    // Áp dụng bộ lọc và sắp xếp đơn hàng dùng chung cho cả Khách hàng và Quản trị viên
    private static IQueryable<Order> ApplyOrderFilter(IQueryable<Order> query, OrderQueryFilter? filter)
    {
        if (filter == null)
        {
            return query.OrderByDescending(o => o.CreatedAt);
        }

        if (filter.Status.HasValue)
        {
            query = query.Where(o => o.OrderStatus == filter.Status.Value);
        }

        if (filter.PaymentStatus.HasValue)
        {
            query = query.Where(o => o.PaymentStatus == filter.PaymentStatus.Value);
        }

        if (filter.PaymentMethod.HasValue)
        {
            query = query.Where(o => o.PaymentMethod == filter.PaymentMethod.Value);
        }

        if (filter.FromDate.HasValue)
        {
            var fromUtc = DateTime.SpecifyKind(filter.FromDate.Value, DateTimeKind.Utc);
            query = query.Where(o => o.CreatedAt >= fromUtc);
        }

        if (filter.ToDate.HasValue)
        {
            var rawTo = filter.ToDate.Value;
            var toAdjusted = rawTo.TimeOfDay == TimeSpan.Zero ? rawTo.Date.AddDays(1).AddTicks(-1) : rawTo;
            var toUtc = DateTime.SpecifyKind(toAdjusted, DateTimeKind.Utc);
            query = query.Where(o => o.CreatedAt <= toUtc);
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim().ToLower();
            query = query.Where(o => o.OrderCode.ToLower().Contains(search) ||
                                     o.ReceiverPhone.Contains(search) ||
                                     o.ReceiverName.ToLower().Contains(search));
        }

        return filter.SortBy?.ToLower() switch
        {
            "ordercode" => filter.IsAscending ? query.OrderBy(o => o.OrderCode) : query.OrderByDescending(o => o.OrderCode),
            "totalamount" => filter.IsAscending ? query.OrderBy(o => o.TotalAmount) : query.OrderByDescending(o => o.TotalAmount),
            "orderstatus" => filter.IsAscending ? query.OrderBy(o => o.OrderStatus) : query.OrderByDescending(o => o.OrderStatus),
            _ => filter.IsAscending ? query.OrderBy(o => o.CreatedAt) : query.OrderByDescending(o => o.CreatedAt)
        };
    }

    /// Truy vấn cơ bản chi tiết đơn hàng (kèm User và Items)
    private IQueryable<Order> BuildOrderDetailQuery() =>
        dbContext.Orders
            .AsNoTracking()
            .Include(o => o.User)
            .Include(o => o.Items);
}
