using WebBanHang.Api.DTOs.Auth;

namespace WebBanHang.Api.DTOs.Orders;

/// <summary>
/// DTO thông tin cơ bản của đơn hàng (dùng cho danh sách đơn)
/// </summary>
public class OrderBaseDto
{
    /// <summary>
    /// Mã ID định danh đơn hàng trong hệ thống
    /// </summary>
    /// <example>101</example>
    public int OrderId { get; set; }

    /// <summary>
    /// Mã đơn hàng duy nhất hiển thị cho khách và tra cứu (Order Code)
    /// </summary>
    /// <example>ORD-20260926-8A3F</example>
    public string OrderCode { get; set; } = string.Empty;

    /// <summary>
    /// Mã ID người dùng đặt đơn
    /// </summary>
    /// <example>1</example>
    public int UserId { get; set; }

    /// <summary>
    /// Họ và tên người nhận hàng
    /// </summary>
    /// <example>Nguyễn Văn A</example>
    public string ReceiverName { get; set; } = string.Empty;

    /// <summary>
    /// Số điện thoại liên hệ nhận hàng
    /// </summary>
    /// <example>0987654321</example>
    public string ReceiverPhone { get; set; } = string.Empty;

    /// <summary>
    /// Địa chỉ giao hàng chi tiết
    /// </summary>
    /// <example>123 Đường Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh</example>
    public string ShippingAddress { get; set; } = string.Empty;

    /// <summary>
    /// Ghi chú đơn hàng từ khách hàng
    /// </summary>
    /// <example>Giao giờ hành chính, gọi trước khi giao 15 phút</example>
    public string? Notes { get; set; }

    /// <summary>
    /// Trạng thái tiến trình đơn hàng (PENDING, CONFIRMED, SHIPPING, DELIVERED, CANCELLED)
    /// </summary>
    /// <example>CONFIRMED</example>
    public OrderStatus OrderStatus { get; set; }

    /// <summary>
    /// Phương thức thanh toán (COD, VNPAY, BANK_TRANSFER)
    /// </summary>
    /// <example>COD</example>
    public PaymentMethod PaymentMethod { get; set; }

    /// <summary>
    /// Trạng thái thanh toán (PENDING, PAID, FAILED, REFUNDED)
    /// </summary>
    /// <example>PENDING</example>
    public PaymentStatus PaymentStatus { get; set; }

    /// <summary>
    /// Tổng tiền hàng sau khi trừ khuyến mãi SP (Subtotal Amount)
    /// </summary>
    /// <example>34490000</example>
    public decimal SubtotalAmount { get; set; }

    /// <summary>
    /// Mã ID của Voucher đã sử dụng (nếu có)
    /// </summary>
    /// <example>5</example>
    public int? VoucherId { get; set; }

    /// <summary>
    /// Mã Code của Voucher đã áp dụng
    /// </summary>
    /// <example>CELLPHONES100K</example>
    public string? VoucherCode { get; set; }

    /// <summary>
    /// Tiêu đề của Voucher đã áp dụng
    /// </summary>
    /// <example>Giảm 100K cho đơn hàng từ 2 triệu</example>
    public string? VoucherTitle { get; set; }

    /// <summary>
    /// Số tiền được giảm từ Voucher giảm giá hóa đơn
    /// </summary>
    /// <example>100000</example>
    public decimal VoucherDiscountAmount { get; set; }

    /// <summary>
    /// Tổng số tiền thực tế khách cần thanh toán = SubtotalAmount - VoucherDiscountAmount
    /// </summary>
    /// <example>34390000</example>
    public decimal TotalAmount { get; set; }

    /// <summary>
    /// Tổng số loại mặt hàng khác nhau trong đơn
    /// </summary>
    /// <example>1</example>
    public int TotalItems { get; set; }

    /// <summary>
    /// Tổng số lượng tất cả các sản phẩm trong đơn
    /// </summary>
    /// <example>1</example>
    public int TotalQuantity { get; set; }

    /// <summary>
    /// Tổng số tiền khách hàng tiết kiệm được từ đơn này (Promotion + Voucher)
    /// </summary>
    /// <example>5100000</example>
    public decimal TotalSavings { get; set; }

    /// <summary>
    /// Thời điểm khởi tạo đơn hàng (UTC)
    /// </summary>
    /// <example>2026-09-26T14:30:00Z</example>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Thời điểm cập nhật trạng thái đơn hàng gần nhất (UTC)
    /// </summary>
    /// <example>2026-09-26T14:35:00Z</example>
    public DateTime UpdatedAt { get; set; }

    /// <summary>
    /// Mã ID người dùng / nhân viên cập nhật trạng thái gần nhất
    /// </summary>
    /// <example>2</example>
    public int? UpdatedByUserId { get; set; }

    /// <summary>
    /// Tên tài khoản của người dùng / nhân viên cập nhật gần nhất
    /// </summary>
    /// <example>sales_staff_01</example>
    public string? UpdatedByUsername { get; set; }

    /// <summary>
    /// Thời điểm thanh toán thành công (nếu đã thanh toán)
    /// </summary>
    /// <example>null</example>
    public DateTime? PaidAt { get; set; }

    /// <summary>
    /// Thời điểm đơn hàng bị hủy (nếu có)
    /// </summary>
    /// <example>null</example>
    public DateTime? CancelledAt { get; set; }

    /// <summary>
    /// Lý do hủy đơn hàng (nếu bị hủy)
    /// </summary>
    /// <example>null</example>
    public string? CancellationReason { get; set; }
}

/// <summary>
/// DTO chi tiết đầy đủ của đơn hàng kèm danh sách sản phẩm snapshot
/// </summary>
public class OrderDetailDto : OrderBaseDto
{
    /// <summary>
    /// Thông tin tài khoản người đặt hàng
    /// </summary>
    public BasicUserDto? User { get; set; }

    /// <summary>
    /// Danh sách chi tiết các mặt hàng trong đơn hàng (Dữ liệu Snapshot lịch sử)
    /// </summary>
    public List<OrderItemDto> Items { get; set; } = new();
}

/// <summary>
/// DTO chi tiết từng dòng sản phẩm trong đơn hàng (Snapshot tại thời điểm mua)
/// </summary>
public class OrderItemDto
{
    /// <summary>
    /// Mã ID chi tiết dòng đơn hàng
    /// </summary>
    /// <example>201</example>
    public int OrderItemId { get; set; }

    /// <summary>
    /// Mã ID đơn hàng cha
    /// </summary>
    /// <example>101</example>
    public int OrderId { get; set; }

    /// <summary>
    /// Mã ID biến thể sản phẩm tại thời điểm mua
    /// </summary>
    /// <example>1</example>
    public int VariantId { get; set; }

    /// <summary>
    /// Tên sản phẩm đã mua (Snapshot)
    /// </summary>
    /// <example>iPhone 16 Pro Max 256GB</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Tên biến thể / phân loại đã mua (Snapshot)
    /// </summary>
    /// <example>Titan Sa Mạc</example>
    public string VariantName { get; set; } = string.Empty;

    /// <summary>
    /// Tên hiển thị đầy đủ của sản phẩm
    /// </summary>
    /// <example>iPhone 16 Pro Max 256GB (Titan Sa Mạc)</example>
    public string FullName => string.IsNullOrWhiteSpace(ProductName)
        ? VariantName
        : string.IsNullOrWhiteSpace(VariantName) || VariantName.Equals("Phiên bản tiêu chuẩn", StringComparison.OrdinalIgnoreCase)
            ? ProductName
            : $"{ProductName} ({VariantName})";

    /// <summary>
    /// URL hình ảnh đại diện của sản phẩm tại thời điểm mua (Snapshot)
    /// </summary>
    /// <example>https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-16-pro-max.png</example>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Giá niêm yết gốc tại thời điểm mua (Snapshot)
    /// </summary>
    /// <example>39490000</example>
    public decimal OriginalPrice { get; set; }

    /// <summary>
    /// Giá bán thực tế sau khi trừ khuyến mãi SP tại thời điểm mua (Snapshot)
    /// </summary>
    /// <example>34490000</example>
    public decimal UnitPrice { get; set; }

    /// <summary>
    /// Mã ID chương trình Promotion áp dụng cho sản phẩm này (Snapshot)
    /// </summary>
    /// <example>2</example>
    public int? PromotionId { get; set; }

    /// <summary>
    /// Tên chương trình Promotion áp dụng cho sản phẩm này (Snapshot)
    /// </summary>
    /// <example>Flash Sale Mùa Thu 2026</example>
    public string? PromotionName { get; set; }

    /// <summary>
    /// Số tiền khuyến mãi được giảm trên mỗi đơn vị SP (Snapshot)
    /// </summary>
    /// <example>5000000</example>
    public decimal PromotionDiscount { get; set; }

    /// <summary>
    /// Số lượng sản phẩm đã mua
    /// </summary>
    /// <example>1</example>
    public int Quantity { get; set; }

    /// <summary>
    /// Tổng thành tiền của món hàng này = UnitPrice * Quantity (Snapshot)
    /// </summary>
    /// <example>34490000</example>
    public decimal TotalPrice { get; set; }

    /// <summary>
    /// Cho biết sản phẩm này có được hưởng khuyến mãi hay không
    /// </summary>
    /// <example>true</example>
    public bool HasPromotion => PromotionId.HasValue || PromotionDiscount > 0;
}
