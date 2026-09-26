using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Data;
using WebBanHang.Api.DTOs.Carts;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Extensions;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class CartService(AppDbContext dbContext) : ICartService
{
    public async Task<CartDto> GetCartAsync(int userId)
    {
        var cart = await GetOrCreateCartEntityAsync(userId);
        return cart.ToCartDto();
    }

    public async Task<CartDto> AddToCartAsync(int userId, AddToCartRequestDto dto)
    {
        var variant = await dbContext.ProductVariants
            .Include(v => v.Product)
            .FirstOrDefaultAsync(v => v.VariantId == dto.VariantId)
            ?? throw new NotFoundException($"Không tìm thấy biến thể sản phẩm có mã ID = {dto.VariantId}.");

        if (!variant.IsActive || (variant.Product != null && !variant.Product.IsActive))
        {
            throw new BadRequestException("Biến thể sản phẩm này hiện đang tạm ngưng kinh doanh.");
        }

        if (variant.StockQuantity <= 0)
        {
            throw new BadRequestException("Biến thể sản phẩm này hiện đã hết hàng.");
        }

        var cart = await GetOrCreateCartEntityAsync(userId);
        var existingItem = cart.Items.FirstOrDefault(i => i.VariantId == dto.VariantId);
        var totalDesiredQuantity = (existingItem?.Quantity ?? 0) + dto.Quantity;

        if (totalDesiredQuantity > variant.StockQuantity)
        {
            throw new BadRequestException($"Số lượng yêu cầu ({totalDesiredQuantity}) vượt quá số lượng tồn kho khả dụng ({variant.StockQuantity}).");
        }

        if (existingItem != null)
        {
            existingItem.Quantity = totalDesiredQuantity;
        }
        else
        {
            cart.Items.Add(new CartItem
            {
                VariantId = dto.VariantId,
                Variant = variant,
                Quantity = dto.Quantity,
                AddedAt = DateTime.UtcNow
            });
        }

        cart.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return cart.ToCartDto();
    }

    public async Task<CartDto> UpdateCartItemQuantityAsync(int userId, int cartItemId, UpdateCartItemRequestDto dto)
    {
        var cart = await GetOrCreateCartEntityAsync(userId);
        var cartItem = cart.Items.FirstOrDefault(i => i.CartItemId == cartItemId)
            ?? throw new NotFoundException($"Không tìm thấy mặt hàng có mã ID = {cartItemId} trong giỏ hàng của bạn.");

        var variant = cartItem.Variant!;

        if (!variant.IsActive)
        {
            throw new BadRequestException("Biến thể sản phẩm này hiện đang tạm ngưng kinh doanh.");
        }

        if (dto.Quantity > variant.StockQuantity)
        {
            throw new BadRequestException($"Số lượng yêu cầu ({dto.Quantity}) vượt quá số lượng tồn kho khả dụng ({variant.StockQuantity}).");
        }

        cartItem.Quantity = dto.Quantity;
        cart.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return cart.ToCartDto();
    }

    public async Task<CartDto> RemoveCartItemAsync(int userId, int cartItemId)
    {
        var cart = await GetOrCreateCartEntityAsync(userId);
        var cartItem = cart.Items.FirstOrDefault(i => i.CartItemId == cartItemId)
            ?? throw new NotFoundException($"Không tìm thấy mặt hàng có mã ID = {cartItemId} trong giỏ hàng của bạn.");

        cart.Items.Remove(cartItem);
        dbContext.CartItems.Remove(cartItem);
        cart.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return cart.ToCartDto();
    }

    public async Task<CartDto> ClearCartAsync(int userId)
    {
        var cart = await GetOrCreateCartEntityAsync(userId);
        if (cart.Items.Count > 0)
        {
            dbContext.CartItems.RemoveRange(cart.Items);
            cart.Items.Clear();
            cart.UpdatedAt = DateTime.UtcNow;
            await dbContext.SaveChangesAsync();
        }

        return cart.ToCartDto();
    }

    private async Task<Cart> GetOrCreateCartEntityAsync(int userId)
    {
        var cart = await dbContext.Carts
            .Include(c => c.Items)
                .ThenInclude(i => i.Variant)
                    .ThenInclude(v => v!.Product)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart != null)
        {
            return cart;
        }

        cart = new Cart
        {
            UserId = userId,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        dbContext.Carts.Add(cart);
        await dbContext.SaveChangesAsync();

        return cart;
    }
}
