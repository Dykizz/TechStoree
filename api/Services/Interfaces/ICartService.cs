using WebBanHang.Api.DTOs.Carts;

namespace WebBanHang.Api.Services.Interfaces;

public interface ICartService
{
    Task<CartDto> GetCartAsync(int userId);
    Task<CartDto> AddToCartAsync(int userId, AddToCartRequestDto dto);
    Task<CartDto> UpdateCartItemQuantityAsync(int userId, int cartItemId, UpdateCartItemRequestDto dto);
    Task<CartDto> RemoveCartItemAsync(int userId, int cartItemId);
    Task<CartDto> ClearCartAsync(int userId);
}
