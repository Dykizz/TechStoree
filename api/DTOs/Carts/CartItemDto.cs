namespace WebBanHang.Api.DTOs.Carts;

/// <summary>
/// Chi tiết một biến thể sản phẩm nằm trong giỏ hàng
/// </summary>
public class CartItemDto
{
    /// <summary>
    /// Mã ID chi tiết sản phẩm trong giỏ hàng
    /// </summary>
    /// <example>1</example>
    public int CartItemId { get; set; }

    /// <summary>
    /// Mã ID biến thể sản phẩm
    /// </summary>
    /// <example>4</example>
    public int VariantId { get; set; }

    /// <summary>
    /// Mã ID dòng sản phẩm cha
    /// </summary>
    /// <example>3</example>
    public int ProductId { get; set; }

    /// <summary>
    /// Tên dòng sản phẩm cha
    /// </summary>
    /// <example>Tai nghe chụp tai Sony WH-1000XM5</example>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>
    /// Tên phiên bản / biến thể (màu sắc, dung lượng)
    /// </summary>
    /// <example>Màu Đen (Midnight Black)</example>
    public string VariantName { get; set; } = string.Empty;

    /// <summary>
    /// Tên đầy đủ kết hợp giữa dòng sản phẩm cha và phân loại biến thể
    /// </summary>
    /// <example>Tai nghe chụp tai Sony WH-1000XM5 (Màu Đen (Midnight Black))</example>
    public string FullName => string.IsNullOrWhiteSpace(ProductName)
        ? VariantName
        : string.IsNullOrWhiteSpace(VariantName) || VariantName.Equals("Phiên bản tiêu chuẩn", StringComparison.OrdinalIgnoreCase)
            ? ProductName
            : $"{ProductName} ({VariantName})";

    /// <summary>
    /// Đường dẫn hình ảnh đại diện của biến thể hoặc sản phẩm
    /// </summary>
    /// <example>https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png</example>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Đơn giá bán lẻ niêm yết của biến thể (VNĐ)
    /// </summary>
    /// <example>7490000</example>
    public decimal Price { get; set; }

    /// <summary>
    /// Số lượng sản phẩm khách chọn mua trong giỏ
    /// </summary>
    /// <example>1</example>
    public int Quantity { get; set; }

    /// <summary>
    /// Số lượng tồn kho hiện tại của biến thể (để UI kiểm tra còn hàng)
    /// </summary>
    /// <example>25</example>
    public int StockQuantity { get; set; }

    /// <summary>
    /// Thành tiền của dòng sản phẩm (Price * Quantity)
    /// </summary>
    /// <example>7490000</example>
    public decimal TotalPrice => Price * Quantity;
}
