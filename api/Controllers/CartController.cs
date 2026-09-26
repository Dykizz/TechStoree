using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Carts;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý Giỏ hàng của người dùng (Shopping Cart)
/// </summary>
[Route("api/cart")]
[Authorize]
[Tags("Cart")]
public class CartController(ICartService cartService) : BaseApiController
{
    /// <summary>
    /// Lấy thông tin giỏ hàng của người dùng đang đăng nhập
    /// </summary>
    /// <remarks>
    /// Trả về toàn bộ danh sách sản phẩm trong giỏ, tổng số lượng và tổng thành tiền (VNĐ).
    /// Nếu người dùng chưa từng có giỏ hàng, hệ thống sẽ tự động khởi tạo giỏ hàng rỗng.
    /// </remarks>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<CartDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetCart()
    {
        var result = await cartService.GetCartAsync(CurrentUserId);
        return Success(result, "Lấy thông tin giỏ hàng thành công.");
    }

    /// <summary>
    /// Thêm một biến thể sản phẩm vào giỏ hàng
    /// </summary>
    /// <remarks>
    /// - Kiểm tra tính khả dụng của biến thể và sản phẩm cha (đang kinh doanh, còn hàng tồn kho).
    /// - Nếu sản phẩm đã có sẵn trong giỏ, hệ thống sẽ tự động cộng dồn số lượng.
    /// - Kiểm tra tổng số lượng mua không được vượt quá số lượng tồn kho khả dụng.
    /// </remarks>
    /// <param name="dto">Dữ liệu biến thể và số lượng cần thêm</param>
    [HttpPost("items")]
    [ProducesResponseType(typeof(ApiResponse<CartDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AddToCart([FromBody] AddToCartRequestDto dto)
    {
        var result = await cartService.AddToCartAsync(CurrentUserId, dto);
        return Success(result, "Đã thêm sản phẩm vào giỏ hàng thành công.");
    }

    /// <summary>
    /// Cập nhật số lượng của một mặt hàng trong giỏ
    /// </summary>
    /// <remarks>
    /// - Kiểm tra quyền sở hữu: chỉ có thể cập nhật mặt hàng nằm trong giỏ của chính mình.
    /// - Kiểm tra số lượng cập nhật không được vượt quá tồn kho khả dụng.
    /// </remarks>
    /// <param name="id">Mã ID của mặt hàng trong giỏ (CartItemId)</param>
    /// <param name="dto">Số lượng cập nhật mới</param>
    [HttpPut("items/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<CartDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCartItemQuantity(int id, [FromBody] UpdateCartItemRequestDto dto)
    {
        var result = await cartService.UpdateCartItemQuantityAsync(CurrentUserId, id, dto);
        return Success(result, "Cập nhật số lượng mặt hàng thành công.");
    }

    /// <summary>
    /// Xóa một mặt hàng khỏi giỏ hàng
    /// </summary>
    /// <param name="id">Mã ID của mặt hàng trong giỏ (CartItemId)</param>
    [HttpDelete("items/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<CartDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveCartItem(int id)
    {
        var result = await cartService.RemoveCartItemAsync(CurrentUserId, id);
        return Success(result, "Đã xóa mặt hàng khỏi giỏ thành công.");
    }

    /// <summary>
    /// Xóa toàn bộ sản phẩm trong giỏ hàng (Làm trống giỏ hàng)
    /// </summary>
    [HttpDelete("clear")]
    [ProducesResponseType(typeof(ApiResponse<CartDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ClearCart()
    {
        var result = await cartService.ClearCartAsync(CurrentUserId);
        return Success(result, "Đã làm trống giỏ hàng thành công.");
    }
}
