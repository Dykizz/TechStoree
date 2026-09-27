namespace WebBanHang.Api.DTOs.Orders;

/// <summary>
/// Yêu cầu tính thử chi phí đơn hàng trước khi bấm Đặt hàng
/// </summary>
public class CheckoutPreviewRequestDto
{
    /// <summary>
    /// Danh sách các CartItemId được tích chọn để thanh toán (để trống hoặc null = tính toàn bộ giỏ)
    /// </summary>
    /// <example>[1, 2]</example>
    public List<int>? CartItemIds { get; set; }

    /// <summary>
    /// Mã giảm giá áp dụng (nếu có)
    /// </summary>
    /// <example>CELLPHONES100K</example>
    public string? VoucherCode { get; set; }
}

/// <summary>
/// Kết quả tạm tính đơn hàng trước khi thanh toán
/// </summary>
public class CheckoutPreviewDto
{
    /// <summary>
    /// Danh sách các mặt hàng chuẩn bị đặt
    /// </summary>
    public List<CheckoutItemPreviewDto> Items { get; set; } = new();

    /// <summary>
    /// Tổng số lượng sản phẩm trong đơn hàng
    /// </summary>
    /// <example>1</example>
    public int TotalQuantity => Items.Sum(i => i.Quantity);

    /// <summary>
    /// Tổng tiền hàng niêm yết (chưa áp dụng Promotion và Voucher)
    /// </summary>
    /// <example>39490000</example>
    public decimal OriginalSubtotalAmount => Items.Sum(i => i.OriginalPrice * i.Quantity);

    /// <summary>
    /// Tổng tiền giảm từ Promotion sản phẩm (Flash Sale, giảm giá trực tiếp SP)
    /// </summary>
    /// <example>5000000</example>
    public decimal TotalPromotionDiscount => Items.Sum(i => i.PromotionDiscount * i.Quantity);

    /// <summary>
    /// Tổng tiền hàng sau khi trừ Promotion (Subtotal)
    /// </summary>
    /// <example>34490000</example>
    public decimal SubtotalAmount => Items.Sum(i => i.TotalPrice);

    /// <summary>
    /// Mã Voucher đã áp dụng thành công (nếu có)
    /// </summary>
    /// <example>CELLPHONES100K</example>
    public string? VoucherCode { get; set; }

    /// <summary>
    /// Tên / Tiêu đề của Voucher đã áp dụng
    /// </summary>
    /// <example>Giảm 100K cho đơn hàng từ 2 triệu</example>
    public string? VoucherTitle { get; set; }

    /// <summary>
    /// Số tiền được giảm từ Voucher giảm giá hóa đơn
    /// </summary>
    /// <example>100000</example>
    public decimal VoucherDiscountAmount { get; set; } = 0;

    /// <summary>
    /// Tổng số tiền thực tế khách cần thanh toán = SubtotalAmount - VoucherDiscountAmount
    /// </summary>
    /// <example>34390000</example>
    public decimal TotalAmount { get; set; }

    /// <summary>
    /// Tổng số tiền khách hàng tiết kiệm được (Tổng Promotion SP + Voucher bill)
    /// </summary>
    /// <example>5100000</example>
    public decimal TotalSavings => TotalPromotionDiscount + VoucherDiscountAmount;

    /// <summary>
    /// Thông báo về trạng thái voucher (nếu mã không hợp lệ hoặc hợp lệ)
    /// </summary>
    /// <example>Áp dụng mã giảm giá CELLPHONES100K thành công (-100.000 đ)</example>
    public string? VoucherMessage { get; set; }

    /// <summary>
    /// Cho biết Voucher có được áp dụng thành công hay không
    /// </summary>
    /// <example>true</example>
    public bool IsVoucherApplied => VoucherDiscountAmount > 0 && !string.IsNullOrWhiteSpace(VoucherCode);
}

/// <summary>
/// Chi tiết tạm tính từng mặt hàng trong giỏ chuẩn bị mua
/// </summary>
public class CheckoutItemPreviewDto
{
    /// <summary>
    /// Mã CartItemId tương ứng trong giỏ hàng
    /// </summary>
    /// <example>1</example>
    public int CartItemId { get; set; }

    /// <summary>
    /// Mã biến thể sản phẩm (VariantId)
    /// </summary>
    /// <example>1</example>
    public int VariantId { get; set; }

    /// <summary>
    /// Mã sản phẩm gốc (ProductId)
    /// </summary>
    /// <example>1</example>
    public int ProductId { get; set; }

    /// <summary>
    /// Tên sản phẩm
    /// </summary>
    /// <example>iPhone 16 Pro Max 256GB</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Tên phân loại biến thể (Màu sắc, Dung lượng)
    /// </summary>
    /// <example>Titan Sa Mạc</example>
    public string VariantName { get; set; } = string.Empty;

    /// <summary>
    /// URL hình ảnh đại diện hiển thị của sản phẩm/biến thể
    /// </summary>
    /// <example>https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-16-pro-max.png</example>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Giá niêm yết ban đầu trước khuyến mãi (Original Price)
    /// </summary>
    /// <example>39490000</example>
    public decimal OriginalPrice { get; set; }

    /// <summary>
    /// Giá bán thực tế từng đơn vị sau khi trừ Promotion SP (Unit Price)
    /// </summary>
    /// <example>34490000</example>
    public decimal UnitPrice { get; set; }

    /// <summary>
    /// Mã chương trình khuyến mãi sản phẩm đang áp dụng (nếu có)
    /// </summary>
    /// <example>2</example>
    public int? PromotionId { get; set; }

    /// <summary>
    /// Tên chương trình khuyến mãi SP đang áp dụng
    /// </summary>
    /// <example>Flash Sale Mùa Thu 2026</example>
    public string? PromotionName { get; set; }

    /// <summary>
    /// Số tiền được giảm trên mỗi đơn vị sản phẩm từ Promotion
    /// </summary>
    /// <example>5000000</example>
    public decimal PromotionDiscount { get; set; } = 0;

    /// <summary>
    /// Số lượng khách chọn mua
    /// </summary>
    /// <example>1</example>
    public int Quantity { get; set; }

    /// <summary>
    /// Số lượng tồn kho hiện tại thực tế của sản phẩm
    /// </summary>
    /// <example>50</example>
    public int StockQuantity { get; set; }

    /// <summary>
    /// Trạng thái còn hàng (true nếu StockQuantity >= Quantity)
    /// </summary>
    /// <example>true</example>
    public bool IsInStock => StockQuantity >= Quantity;

    /// <summary>
    /// Tổng thành tiền của món hàng này = UnitPrice * Quantity
    /// </summary>
    /// <example>34490000</example>
    public decimal TotalPrice => UnitPrice * Quantity;
}
